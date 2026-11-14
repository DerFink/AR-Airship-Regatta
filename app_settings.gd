# 2026-11-14 22:00 – Online-Bestenliste: Schalter „eintragen“, Fassung der Einwilligung, zufällige Geräte-Kennung (zum Selbstlöschen)
# 2026-11-14 11:20 – Versteckter Schalter show_test_models (Testmodelle wie Chewie27 zeigen), gespeichert unter [entwicklung]
# 2026-11-12 10:40 – Einstellung „Platzen an/aus“ entfernt (Grundregel, immer an)
# 2026-11-12 10:05 – Grenzgeschwindigkeit fürs Platzen entfernt (jetzt fest 20 km/h in AirshipPhysics)
# 2026-11-11 14:40 – Platzen beim Aufprall an/aus und Grenzgeschwindigkeit
# 2026-11-11 16:30 – Erstversion: Einstellungen der App (Musik und Motorklang an/aus und Lautstärke, Bodenspur an/aus) – gespeichert in user://einstellungen.cfg, wirken über eigene Audio-Busse
# =============================================================================
# AppSettings.gd
# -----------------------------------------------------------------------------
# Audio-Busse (unter „Master“):
#   Musik    – Werkstatt-Musik (Startseite, Modell & Bau, Baukasten, Grundlagen)
#   Motoren  – Propellerklang (PropSynth / PropSound)
#   Klick    – leiser Bedienklick
# Lautstärke 0…1 wird in dB umgerechnet; „aus“ schaltet den Bus stumm.
# =============================================================================
class_name AppSettings
extends RefCounted

const PATH := "user://einstellungen.cfg"
const BUSES := ["Musik", "Motoren", "Klick"]

static var music_on := true
static var music_vol := 0.7
static var motor_on := true
static var motor_vol := 1.0
static var track_on := true
## Testmodelle (z. B. Chewie27) in der Modellauswahl zeigen – versteckt,
## eingeschaltet durch 7× Tippen auf die Versionsnummer in den Einstellungen
static var show_test_models := false
## Online-Bestenliste: Zeiten online eintragen (aus = nur auf dem Gerät)
static var online_on := true
## Fassung des Einwilligungstextes, der zugestimmt wurde (0 = keine Einwilligung)
static var online_consent := 0
## Zufällige Geräte-Kennung (32 Hex-Zeichen) – nur damit man die eigenen
## Online-Einträge später selbst löschen kann; verrät nichts über die Person
static var device_id := ""
static var _loaded := false
## wird bei jeder Änderung aufgerufen (z. B. Spur ein-/ausblenden)
static var on_change: Array[Callable] = []


static func load_all() -> void:
	if _loaded: return
	_loaded = true
	_ensure_buses()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		music_on = bool(cfg.get_value("ton", "musik_an", music_on))
		music_vol = clampf(float(cfg.get_value("ton", "musik_laut", music_vol)), 0.0, 1.0)
		motor_on = bool(cfg.get_value("ton", "motor_an", motor_on))
		motor_vol = clampf(float(cfg.get_value("ton", "motor_laut", motor_vol)), 0.0, 1.0)
		track_on = bool(cfg.get_value("anzeige", "spur_an", track_on))
		show_test_models = bool(cfg.get_value("entwicklung", "testmodelle", show_test_models))
		online_on = bool(cfg.get_value("online", "eintragen", online_on))
		online_consent = int(cfg.get_value("online", "einwilligung", online_consent))
		device_id = str(cfg.get_value("online", "geraet", device_id))
	apply()


## Geräte-Kennung; wird beim ersten Bedarf zufällig erzeugt und gespeichert.
static func device() -> String:
	load_all()
	if device_id.length() != 32:
		device_id = Crypto.new().generate_random_bytes(16).hex_encode()
		save()
	return device_id


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ton", "musik_an", music_on)
	cfg.set_value("ton", "musik_laut", music_vol)
	cfg.set_value("ton", "motor_an", motor_on)
	cfg.set_value("ton", "motor_laut", motor_vol)
	cfg.set_value("anzeige", "spur_an", track_on)
	cfg.set_value("entwicklung", "testmodelle", show_test_models)
	cfg.set_value("online", "eintragen", online_on)
	cfg.set_value("online", "einwilligung", online_consent)
	cfg.set_value("online", "geraet", device_id)
	cfg.save(PATH)
	apply()


## Busse stellen und Beobachter informieren.
static func apply() -> void:
	_ensure_buses()
	_set_bus("Musik", music_on, music_vol)
	_set_bus("Motoren", motor_on, motor_vol)
	for c in on_change:
		if c.is_valid(): c.call()


static func _set_bus(name: String, on: bool, vol: float) -> void:
	var i := AudioServer.get_bus_index(name)
	if i < 0: return
	AudioServer.set_bus_mute(i, not on or vol <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(vol, 0.001)))


## Busse einmal anlegen (falls im Projekt keine Bus-Datei liegt).
static func _ensure_buses() -> void:
	for b in BUSES:
		if AudioServer.get_bus_index(b) >= 0: continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, b)
		AudioServer.set_bus_send(i, "Master")
