# 2026-11-11 18:45 – Flugmodi heißen jetzt Direkt · Angle · Horizon (wie bei Drohnen; im Teensy weiter Mode 1/2/3)
# 2026-11-11 11:40 – Erstversion: Regler-Bausteine – jeder Baustein steht für einen Teil des Teensy-Reglers und lässt sich an/aus schalten (aus = seine Werte auf 0, die alten Werte werden gemerkt); feste Sicherheits-Bausteine (Gas nur Pilot, Failsafe, Motorfreigabe) sind nicht abschaltbar
# =============================================================================
# FcBlocks.gd
# -----------------------------------------------------------------------------
# Die Bausteine wirken über die vorhandenen Reglerwerte – dadurch gilt ein
# abgeschalteter Baustein im Simulator UND im exportierten .ino gleich:
#   Baustein aus  → alle seine Werte = 0 (alte Werte in user://bausteine.cfg)
#   Baustein an   → gemerkte Werte zurück
# Das Signalflussbild (FlowDiagram) baut sich aus diesen Zuständen auf.
# =============================================================================
class_name FcBlocks
extends RefCounted

const SAVE_PATH := "user://bausteine.cfg"

## id, Name, Kurzbeschreibung, Werte [Achse|"gen", Schlüssel], fest (nicht abschaltbar), Spalte im Bild
const BLOCKS := [
	{"id": "mix", "name": "Mischer nach Einbauwinkel", "desc": "verteilt Nick, Gier und Roll nach dem Einbauwinkel auf jede Flosse und jeden Schwenker", "vals": [], "fixed": true},
	{"id": "ff", "name": "Knüppel-Vorsteuerung", "desc": "Knüppel geht direkt (ohne Regler) anteilig auf Ruder und Schwenker – schnelle Reaktion",
		"vals": [["gen", "stick_pitch_motor"], ["gen", "stick_pitch_tail"], ["yaw", "stick_yaw_motor"], ["yaw", "stick_yaw_tail"], ["yaw", "stick_yaw_motor_m3"], ["yaw", "stick_yaw_tail_m3"]]},
	{"id": "pitch", "name": "Nick-Lageregler (PID)", "desc": "hält den Nickwinkel auf dem Sollwert des Knüppels (Angle/Horizon)",
		"vals": [["pitch", "Kp"], ["pitch", "Ki"], ["pitch", "Kd"]]},
	{"id": "roll", "name": "Rolllagen-Ausgleich (PID)", "desc": "richtet das Schiff um die Längsachse auf",
		"vals": [["roll", "Kp"], ["roll", "Ki"], ["roll", "Kd"]]},
	{"id": "roll_mot", "name": "Roll über Motorschwenker", "desc": "Schwenker gegenläufig für den Rollausgleich",
		"vals": [["gen", "motor_roll_gain"]]},
	{"id": "rate", "name": "Nick-Rate (Horizon)", "desc": "Höhenknüppel gibt eine Nick-Drehrate vor statt eines Winkels", "vals": [], "fixed": true},
	{"id": "yaw_pid", "name": "Gier-PID (Horizon)", "desc": "I- und D-Anteil des Gier-Drehratenreglers (P bleibt)",
		"vals": [["yaw", "Ki_yaw_m3"], ["yaw", "Kd_yaw_m3"]]},
	{"id": "protect", "name": "Nick-Schutz", "desc": "nimmt die Vorsteuerung über dem maximalen Nickwinkel zurück",
		"vals": [["gen", "pitch_protect_band_deg"]]},
	{"id": "swv_back", "name": "Schwenk-Rücknahme", "desc": "weniger Gier-Schwenk bei viel Schub (gegen Rollen)",
		"vals": [["gen", "yaw_swivel_full_lever"]]},
	{"id": "expo", "name": "Expo (Seitenknüppel)", "desc": "feinfühlig um die Mitte, Vollausschlag unverändert",
		"vals": [["gen", "yaw_expo"]]},
	{"id": "alt", "name": "Höhe halten", "desc": "geplant – noch nicht im Regler", "vals": [], "planned": true},
	{"id": "thr", "name": "Gas nur vom Piloten", "desc": "der Regler verändert den Schub nie", "vals": [], "fixed": true, "safety": true},
	{"id": "fs", "name": "Failsafe", "desc": "Sender weg → Motoren aus", "vals": [], "fixed": true, "safety": true},
	{"id": "arm", "name": "Motorfreigabe (Kanal 14)", "desc": "Motoren laufen nur mit Freigabeschalter", "vals": [], "fixed": true, "safety": true},
]

## gemerkte Werte abgeschalteter Bausteine: id → {"achse/schlüssel": Wert}
static var _off := {}
static var _loaded := false


static func _load() -> void:
	if _loaded: return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for id in cfg.get_sections():
			var d := {}
			for k in cfg.get_section_keys(id):
				d[k] = float(cfg.get_value(id, k))
			_off[id] = d


static func _save() -> void:
	var cfg := ConfigFile.new()
	for id in _off:
		for k in _off[id]:
			cfg.set_value(id, k, _off[id][k])
	cfg.save(SAVE_PATH)


static func is_on(id: String) -> bool:
	_load()
	for b in BLOCKS:
		if b.id == id and b.get("planned", false):
			return false
	return not _off.has(id)


static func _val(fc: FlightController, v: Array) -> float:
	if v[0] == "gen": return float(fc.get(v[1]))
	return float(fc.params[_axis(v[0])][v[1]])


static func _put(fc: FlightController, v: Array, x: float) -> void:
	if v[0] == "gen": fc.set(v[1], x)
	else: fc.params[_axis(v[0])][v[1]] = x


static func _axis(name: String) -> int:
	return {"pitch": FlightController.Axis.PITCH, "roll": FlightController.Axis.ROLL, "yaw": FlightController.Axis.YAW}[name]


## Baustein an/aus schalten (wirkt sofort auf den Flugcontroller).
static func set_on(fc: FlightController, id: String, on: bool) -> void:
	_load()
	var blk: Dictionary = {}
	for b in BLOCKS:
		if b.id == id: blk = b
	if blk.is_empty() or blk.get("fixed", false) or blk.get("planned", false):
		return
	if on and _off.has(id):
		for key in _off[id]:
			var p: PackedStringArray = (key as String).split("/")
			_put(fc, [p[0], p[1]], _off[id][key])
		_off.erase(id)
	elif not on and not _off.has(id):
		var d := {}
		for v in blk.vals:
			d["%s/%s" % [v[0], v[1]]] = _val(fc, v)
			_put(fc, v, 0.0)
		_off[id] = d
	_save()
	fc._reset_integrators()
	fc.save_settings()


## Alle Bausteine wieder an (z. B. nach „Alle Einstellungen zurücksetzen“ –
## dann stimmen die gemerkten Werte nicht mehr; sie werden verworfen).
static func clear() -> void:
	_load()
	_off.clear()
	_save()
