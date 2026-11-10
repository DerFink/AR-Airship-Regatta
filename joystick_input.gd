# 2026-11-11 14:00 – Kanalzuordnung einstellbar (Funktion → Kanal 1…8, wird mit der Kalibrierung gespeichert) und Anlernen per Bewegung; Belegung geht auf Wunsch in den .ino-Export
# 2026-11-09 14:20 – Kalibrierung je Kanal (Min/Mitte/Max, Richtung umkehren), gespeichert in user://sender_kalibrierung.cfg; während der Kalibrierung keine Schalter-Signale
# 2026-11-08 17:15 – Sender automatisch unter mehreren Geräten finden (Name FrSky/Taranis/EdgeTX oder ausgelenkte Schalterkanäle), alle 0,5 s neu prüfen
# 2026-11-08 15:40 – Arming andersherum: SF oben = scharf, SF unten = aus
# 2026-11-08 15:25 – Schalter SH auf Kanal 7: nach oben umlegen = Zurücksetzen
# 2026-11-08 14:30 – Erstversion: Taranis (EdgeTX, USB-Joystick) als Fernsteuerung: Knüppel wie am Handy, SF = Arming (unten scharf), SC = Modus (oben Mode 1 / Mitte Mode 2 / unten Mode 3)
# =============================================================================
# JoystickInput.gd
# -----------------------------------------------------------------------------
# Liest einen per USB angeschlossenen Sender (EdgeTX „USB Joystick (HID)“,
# klassischer Modus: Kanal 1…8 → Joystick-Achse 0…7). Funktioniert am PC im
# Browser und am Android-Handy (USB-OTG-Adapter) gleich.
#
# Erwartete Kanalbelegung im Sender (eigenes Modell „Simulator“ in EdgeTX):
#   CH1  Seite   (rechter Knüppel links/rechts)   → Gier
#   CH2  Höhe    (rechter Knüppel hoch/runter)    → Nick
#   CH3  Gas     (linker Knüppel hoch/runter)     → Gas (Mitte = Stopp, wie am echten Chewie)
#   CH4  linker Knüppel links/rechts              → Rolle in Mode 1
#   CH5  Schalter SF  oben = scharf, unten = nicht scharf (Arming)
#   CH6  Schalter SC  oben = Mode 1 (Direkt), Mitte = Mode 2, unten = Mode 3
#   CH7  Schalter SH  oben = zurücksetzen (wirkt im Moment des Umlegens nach oben, einmal)
# Läuft eine Richtung verkehrt, im Sender beim Kanal die Gewichtung auf −100 % stellen.
#
# Sicherheit:
#   - Scharf wird nur beim UMSCHALTEN von SF nach oben (steht SF beim Einstecken
#     schon oben, bleibt alles aus, bis SF einmal unten war).
#   - Wird der Sender abgezogen, gehen die Motoren sofort aus.
# =============================================================================
class_name JoystickInput
extends Node

## Sender angeschlossen bzw. abgezogen (Name des Geräts)
signal connected(device_name: String)
signal disconnected
## Schalter SF umgelegt: true = scharf
signal arm_switched(armed: bool)
## Schalter SC umgelegt: 0 = Mode 1 (Direkt), 1 = Mode 2, 2 = Mode 3
signal mode_switched(mode: int)
## Schalter SH nach oben gelegt: Luftschiff zurücksetzen (an den Start)
signal reset_switched

# Achsen (Kanal − 1) im klassischen EdgeTX-Joystick-Modus
const AXIS_YAW := 0        ## CH1 Seite
const AXIS_PITCH := 1      ## CH2 Höhe
const AXIS_THROTTLE := 2   ## CH3 Gas
const AXIS_ROLL := 3       ## CH4 linker Knüppel links/rechts
const AXIS_ARM := 4        ## CH5 Schalter SF
const AXIS_MODE := 5       ## CH6 Schalter SC
const AXIS_RESET := 6      ## CH7 Schalter SH (oben = zurücksetzen)
## EdgeTX gibt +100 % als +1 aus (Höhe und Gas hoch = +100 %), das passt direkt
## zu den Bildschirmknüppeln (hoch = +). Bei true wird die Achse umgedreht.
const INVERT_PITCH := false
const INVERT_THROTTLE := false

## Anzahl ausgewerteter Kanäle (CH1…CH8, klassischer EdgeTX-Joystick)
const CHANNELS := 8
## Funktionen und ihre Standard-Kanäle (1-basiert) – Belegung des Simulator-Modells
const FUNCS := ["yaw", "pitch", "thr", "roll", "arm", "mode", "reset"]
const FUNC_NAMES := {"yaw": "Gier (Seite)", "pitch": "Nick (Höhe)", "thr": "Gas", "roll": "Rolle (linker Knüppel)",
	"arm": "Armed / Motorfreigabe", "mode": "Modus-Schalter", "reset": "Zurücksetzen (nur Simulator)"}
const DEFAULT_MAP := {"yaw": 1, "pitch": 2, "thr": 3, "roll": 4, "arm": 5, "mode": 6, "reset": 7}
## Aktuelle Zuordnung Funktion → Kanal (1-basiert)
static var fmap := DEFAULT_MAP.duplicate()


## Achse (0-basiert) einer Funktion
static func axis(fn: String) -> int:
	return int(fmap.get(fn, DEFAULT_MAP[fn])) - 1
const CAL_PATH := "user://sender_kalibrierung.cfg"
## Kalibrierung je Kanal (Index = Kanal − 1), Rohwerte wie vom Sender gemeldet:
##   min / center / max  → werden auf −1 / 0 / +1 umgerechnet
##   inv                 → Richtung umkehren (nach der Umrechnung)
## Werkseinstellung: −1 / 0 / +1, nicht umgekehrt (= unverändert wie bisher).
var cal: Array = []
## true, solange das Kalibrierfenster offen ist: Knüppel werden weiter gelesen
## (für die Anzeige), Schalter lösen aber nichts aus (kein Scharfschalten,
## kein Moduswechsel, kein Zurücksetzen).
var calibrating := false:
	set(v):
		calibrating = v
		if not v:
			# Nach dem Kalibrieren Schalter neu einlesen. Sicherheit: steht SF dann
			# schon oben, wird NICHT scharf geschaltet – erst nach unten und wieder hoch.
			_arm_state = -1; _arm_seen_off = false; _mode_state = -1; _reset_state = -1

var device := -1                    ## Godot-Gerätenummer, −1 = kein Sender
var left := Vector2.ZERO            ## wie der linke Bildschirmknüppel (x = Rolle, y = Gas)
var right := Vector2.ZERO           ## wie der rechte Bildschirmknüppel (x = Gier, y = Nick)
var _arm_state := -1                ## −1 = unbekannt, 0 = oben, 1 = unten
var _arm_seen_off := false          ## SF war seit dem Einstecken mindestens einmal oben
var _mode_state := -1
var _reset_state := -1              ## −1 = unbekannt, 1 = oben, 0 = unten


func _ready() -> void:
	cal = default_cal()
	load_cal()
	Input.joy_connection_changed.connect(_on_joy_changed)
	_pick_device()


## true, solange ein Sender angeschlossen ist (dann steuert er statt der Bildschirmknüppel)
func active() -> bool:
	return device >= 0


func _on_joy_changed(_dev: int, _connected: bool) -> void:
	_pick_device()


## Sender unter den angeschlossenen Geräten suchen. Am PC hängen oft weitere
## „Joysticks“ (Headsets, Tastaturen mit Zusatztasten, virtuelle Controller) –
## deshalb zuerst nach dem Namen (FrSky/Taranis/EdgeTX/OpenTX), sonst das Gerät
## mit den meisten ausgelenkten Achsen (am Sender stehen die Schalterkanäle
## SF/SC/SH immer am Anschlag, ein unbenutztes Gerät meldet 0).
func _pick_device() -> void:
	var pads := Input.get_connected_joypads()
	var old := device
	device = -1
	var best := -1.0
	for d in pads:
		var n := Input.get_joy_name(d).to_lower()
		var score := 0.0
		for key in ["frsky", "taranis", "edgetx", "opentx", "radiomaster", "jumper"]:
			if key in n:
				score += 100.0
		for ax in 8:
			score += absf(Input.get_joy_axis(d, ax))
		if score > best:
			best = score
			device = d
	if device == old:
		return
	_arm_state = -1; _arm_seen_off = false; _mode_state = -1; _reset_state = -1
	left = Vector2.ZERO; right = Vector2.ZERO
	if device >= 0:
		connected.emit(Input.get_joy_name(device))
	else:
		disconnected.emit()                          # Failsafe: Motoren aus (macht die Flugansicht)


var _rescan_t := 0.0

func _process(dt: float) -> void:
	# Alle 0,5 s neu wählen: der Browser meldet Geräte erst nach der ersten Bewegung,
	# und das zuerst gemeldete Gerät ist nicht unbedingt der Sender
	_rescan_t -= dt
	if _rescan_t <= 0.0:
		_rescan_t = 0.5
		_pick_device()
	if device < 0:
		return
	# Alle Kanäle über die Kalibrierung (Min/Mitte/Max, Umkehr) auf −1…+1
	var yaw := value(axis("yaw"))
	var pitch := value(axis("pitch")) * (-1.0 if INVERT_PITCH else 1.0)
	var thr := value(axis("thr")) * (-1.0 if INVERT_THROTTLE else 1.0)
	var roll := value(axis("roll"))
	left = Vector2(_dz(roll), _dz(thr))                # Gas: Mitte = Stopp
	right = Vector2(_dz(yaw), _dz(pitch))

	if calibrating:
		return                                       # Kalibrierung: Schalter lösen nichts aus
	# Schalter SF: oben (Kanal < −50 %) = scharf, unten = aus (Wunsch Nutzer 08.11.2026)
	var a := 1 if value(axis("arm")) < -0.5 else 0
	if a != _arm_state:
		var first := _arm_state < 0
		_arm_state = a
		if a == 0:
			_arm_seen_off = true
			if not first: arm_switched.emit(false)
		elif _arm_seen_off:
			arm_switched.emit(true)                  # nur nach echtem Umlegen von unten nach oben
	# Schalter SC: oben / Mitte / unten
	var mv := value(axis("mode"))
	var m := 0 if mv < -0.5 else (2 if mv > 0.5 else 1)
	if m != _mode_state:
		_mode_state = m
		mode_switched.emit(m)
	# Schalter SH: Zurücksetzen nur beim Umlegen nach oben (Kanal < −50 %), nicht
	# dauernd und nicht beim Einstecken, wenn SH schon oben steht
	var rs := 1 if value(axis("reset")) < -0.5 else 0
	if rs != _reset_state:
		if _reset_state == 0 and rs == 1:
			reset_switched.emit()
		_reset_state = rs


## Kleine Totzone um die Mitte (Knüppel-Rauschen)
static func _dz(v: float) -> float:
	return 0.0 if absf(v) < 0.02 else clampf(v, -1.0, 1.0)



# =============================================================================
# Kalibrierung
# =============================================================================

## Werkseinstellung: Rohwert = Wert (−1 / 0 / +1), keine Umkehr.
static func default_cal() -> Array:
	var c := []
	for i in CHANNELS:
		c.append({"min": -1.0, "center": 0.0, "max": 1.0, "inv": false})
	return c


## Rohwert eines Kanals (0 = CH1), wie ihn der Sender meldet.
func raw(ch: int) -> float:
	return Input.get_joy_axis(device, ch) if device >= 0 else 0.0


## Zuordnung für den .ino-Export: Funktion → [Kanal, umgekehrt]
## (Rolle, Gas, Nick, Gier, Motorfreigabe, Modus; „Zurücksetzen“ gibt es im Teensy nicht)
static func channels_for_ino(cal_list: Array = []) -> Dictionary:
	if cal_list.is_empty():                       # gespeicherte Kalibrierung lesen
		cal_list = default_cal()
		var f := ConfigFile.new()
		if f.load(CAL_PATH) == OK:
			for i in CHANNELS:
				cal_list[i].inv = bool(f.get_value("ch%d" % (i + 1), "inv", false))
			for fn in FUNCS:
				fmap[fn] = clampi(int(f.get_value("zuordnung", fn, fmap[fn])), 1, CHANNELS)
	var out := {}
	for fn in ["thr", "pitch", "yaw", "roll", "arm", "mode"]:
		var ch: int = int(fmap[fn])
		var inv: bool = cal_list[ch - 1].inv if ch - 1 < cal_list.size() else false
		out[fn] = [ch, inv]
	return out


## Kalibrierter Wert eines Kanals (−1…+1) mit den gespeicherten Werten.
func value(ch: int) -> float:
	return apply_cal(raw(ch), cal[ch])


## Rohwert mit einem Kalibriersatz {min, center, max, inv} umrechnen:
## Mitte → 0, Min → −1, Max → +1 (beide Hälften getrennt, so passt auch eine
## Mitte, die nicht genau zwischen den Anschlägen liegt).
static func apply_cal(v: float, c: Dictionary) -> float:
	var lo: float = c.min
	var mid: float = c.center
	var hi: float = c.max
	var out := 0.0
	if v >= mid:
		out = (v - mid) / maxf(hi - mid, 0.05)
	else:
		out = (v - mid) / maxf(mid - lo, 0.05)
	out = clampf(out, -1.0, 1.0)
	return -out if c.inv else out


func save_cal() -> void:
	var f := ConfigFile.new()
	for fn in FUNCS:
		f.set_value("zuordnung", fn, int(fmap[fn]))
	for i in CHANNELS:
		for k in ["min", "center", "max", "inv"]:
			f.set_value("ch%d" % (i + 1), k, cal[i][k])
	f.save(CAL_PATH)


func load_cal() -> void:
	var f := ConfigFile.new()
	if f.load(CAL_PATH) != OK:
		return
	for fn in FUNCS:
		fmap[fn] = clampi(int(f.get_value("zuordnung", fn, DEFAULT_MAP[fn])), 1, CHANNELS)
	for i in CHANNELS:
		var sec := "ch%d" % (i + 1)
		if not f.has_section(sec):
			continue                                 # alte Datei mit nur 7 Kanälen
		for k in ["min", "center", "max", "inv"]:
			cal[i][k] = f.get_value(sec, k, cal[i][k])
