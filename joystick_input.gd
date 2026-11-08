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
#   CH5  Schalter SF  oben = nicht scharf, unten = scharf (Arming)
#   CH6  Schalter SC  oben = Mode 1 (Direkt), Mitte = Mode 2, unten = Mode 3
#   CH7  Schalter SH  oben = zurücksetzen (wirkt im Moment des Umlegens nach oben, einmal)
# Läuft eine Richtung verkehrt, im Sender beim Kanal die Gewichtung auf −100 % stellen.
#
# Sicherheit:
#   - Scharf wird nur beim UMSCHALTEN von SF nach unten (steht SF beim Einstecken
#     schon unten, bleibt alles aus, bis SF einmal oben war).
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

var device := -1                    ## Godot-Gerätenummer, −1 = kein Sender
var left := Vector2.ZERO            ## wie der linke Bildschirmknüppel (x = Rolle, y = Gas)
var right := Vector2.ZERO           ## wie der rechte Bildschirmknüppel (x = Gier, y = Nick)
var _arm_state := -1                ## −1 = unbekannt, 0 = oben, 1 = unten
var _arm_seen_off := false          ## SF war seit dem Einstecken mindestens einmal oben
var _mode_state := -1
var _reset_state := -1              ## −1 = unbekannt, 1 = oben, 0 = unten


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)
	_pick_device()


## true, solange ein Sender angeschlossen ist (dann steuert er statt der Bildschirmknüppel)
func active() -> bool:
	return device >= 0


func _on_joy_changed(_dev: int, _connected: bool) -> void:
	_pick_device()


## Ersten angeschlossenen Joystick nehmen.
func _pick_device() -> void:
	var pads := Input.get_connected_joypads()
	var old := device
	device = pads[0] if pads.size() > 0 else -1
	if device == old:
		return
	_arm_state = -1; _arm_seen_off = false; _mode_state = -1; _reset_state = -1
	left = Vector2.ZERO; right = Vector2.ZERO
	if device >= 0:
		connected.emit(Input.get_joy_name(device))
	else:
		disconnected.emit()                          # Failsafe: Motoren aus (macht die Flugansicht)


func _process(_dt: float) -> void:
	if device < 0:
		return
	var yaw := Input.get_joy_axis(device, AXIS_YAW)
	var pitch := Input.get_joy_axis(device, AXIS_PITCH) * (-1.0 if INVERT_PITCH else 1.0)
	var thr := Input.get_joy_axis(device, AXIS_THROTTLE) * (-1.0 if INVERT_THROTTLE else 1.0)
	var roll := Input.get_joy_axis(device, AXIS_ROLL)
	left = Vector2(_dz(roll), _dz(thr))                # Gas: Mitte = Stopp
	right = Vector2(_dz(yaw), _dz(pitch))

	# Schalter SF: unten (Kanal > +50 %) = scharf
	var a := 1 if Input.get_joy_axis(device, AXIS_ARM) > 0.5 else 0
	if a != _arm_state:
		var first := _arm_state < 0
		_arm_state = a
		if a == 0:
			_arm_seen_off = true
			if not first: arm_switched.emit(false)
		elif _arm_seen_off:
			arm_switched.emit(true)                  # nur nach echtem Umlegen von oben nach unten
	# Schalter SC: oben / Mitte / unten
	var mv := Input.get_joy_axis(device, AXIS_MODE)
	var m := 0 if mv < -0.5 else (2 if mv > 0.5 else 1)
	if m != _mode_state:
		_mode_state = m
		mode_switched.emit(m)
	# Schalter SH: Zurücksetzen nur beim Umlegen nach oben (Kanal < −50 %), nicht
	# dauernd und nicht beim Einstecken, wenn SH schon oben steht
	var rs := 1 if Input.get_joy_axis(device, AXIS_RESET) < -0.5 else 0
	if rs != _reset_state:
		if _reset_state == 0 and rs == 1:
			reset_switched.emit()
		_reset_state = rs


## Kleine Totzone um die Mitte (Knüppel-Rauschen)
static func _dz(v: float) -> float:
	return 0.0 if absf(v) < 0.02 else clampf(v, -1.0, 1.0)
