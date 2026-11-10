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
	apply()


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ton", "musik_an", music_on)
	cfg.set_value("ton", "musik_laut", music_vol)
	cfg.set_value("ton", "motor_an", motor_on)
	cfg.set_value("ton", "motor_laut", motor_vol)
	cfg.set_value("anzeige", "spur_an", track_on)
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
