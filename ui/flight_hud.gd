# 2026-10-27 12:55 – Knopf „Zurücksetzen“ oben rechts (vor „Motoren“)
# 2026-10-27 12:24 – Eigene Layout-Funktion: Telemetrie, Menüs, Knüppel und Hinweis werden aus der Bildschirmgröße platziert (Knüppel lagen sonst außerhalb des Bildes)
# 2026-10-27 12:22 – Fix: Vollbild-Anker mit set_anchors_and_offsets_preset (vorher blieb die Fläche 0 px groß → Knüppel und Menüs landeten oben links)
# 2026-10-27 10:42 – Erstversion: Flugansicht nach freigegebenem Entwurf (Telemetrie oben links, Menüs oben rechts, zwei Knüppel, Hinweis unten mittig) + Motor-Schalter (Failsafe-Armen)
# =============================================================================
# FlightHUD.gd
# -----------------------------------------------------------------------------
# Oberfläche während des Fliegens (Querformat):
#
#   ┌ 12,4 km/h │ α 6° │ FC: Mode 2           Motoren │ Bau │ PID │ AR ┐
#   │                                                                   │
#   │  ( Gas )               [Hinweis-Banner]              ( Nick·Gier )│
#   └───────────────────────────────────────────────────────────────────┘
#
# Alle Elemente entstehen über UITheme – keine eigenen Farben/Größen hier.
# =============================================================================
class_name FlightHUD
extends Control

signal builder_requested
signal pid_requested
signal ar_requested
signal reset_requested

var fc: FlightController
var ship: AirshipPhysics

var stick_left: TouchStick
var stick_right: TouchStick
var _pill_speed: Button
var _pill_alpha: Button
var _pill_mode: Button
var _btn_arm: Button
var _btn_ar: Button
var _banner: PanelContainer
var _banner_timer := 0.0
var _tl: HBoxContainer
var _tr: HBoxContainer


func setup(controller: FlightController, airship: AirshipPhysics) -> void:
	fc = controller
	ship = airship


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := UITheme.space("lg")

	# --- Telemetrie oben links ---------------------------------------------
	_tl = UITheme.make_hbox("xs")
	var tl := _tl
	add_child(tl)
	_pill_speed = UITheme.make_pill("0,0 km/h")
	_pill_alpha = UITheme.make_pill("α 0°")
	_pill_mode = UITheme.make_pill("FC: Mode 1")
	for p in [_pill_speed, _pill_alpha, _pill_mode]: tl.add_child(p)

	# --- Menüs oben rechts --------------------------------------------------
	_tr = UITheme.make_hbox("xs")
	var tr := _tr
	add_child(tr)
	_btn_arm = UITheme.make_pill("Motoren aus", true)
	_btn_arm.toggle_mode = true
	_btn_arm.toggled.connect(_on_arm_toggled)
	var b_reset := UITheme.make_pill("Zurücksetzen", true)
	b_reset.pressed.connect(func(): reset_requested.emit())
	var b_build := UITheme.make_pill("Bau", true)
	b_build.pressed.connect(func(): builder_requested.emit())
	var b_pid := UITheme.make_pill("PID", true)
	b_pid.pressed.connect(func(): pid_requested.emit())
	_btn_ar = UITheme.make_pill("AR", true)
	_btn_ar.toggle_mode = true
	_btn_ar.pressed.connect(func(): ar_requested.emit())
	for b in [b_reset, _btn_arm, b_build, b_pid, _btn_ar]: tr.add_child(b)

	# --- Knüppel ------------------------------------------------------------
	stick_left = TouchStick.new()
	stick_right = TouchStick.new()
	for s in [stick_left, stick_right]:
		add_child(s)
	_refresh_stick_captions()

	# --- Hinweis-Banner unten mittig ---------------------------------------
	_banner = UITheme.make_banner(360)
	add_child(_banner)
	resized.connect(_layout)
	_layout.call_deferred()


# =============================================================================
# Platzierung (bei jeder Größenänderung und jedem Frame – billig):
# Positionen werden direkt aus der aktuellen Bildschirmgröße berechnet,
# statt sich auf Godot-Anker zu verlassen, deren Mindestgrößen beim Aufbau
# noch nicht feststehen.
# =============================================================================
func _layout() -> void:
	var m := float(UITheme.space("lg"))
	var sz := size
	_tl.size = _tl.get_combined_minimum_size()
	_tl.position = Vector2(m, m)
	_tr.size = _tr.get_combined_minimum_size()
	_tr.position = Vector2(sz.x - _tr.size.x - m, m)
	for s in [stick_left, stick_right]:
		s.size = s.custom_minimum_size
	var sy := sz.y - stick_left.size.y - m
	stick_left.position = Vector2(m * 3.0, sy)
	stick_right.position = Vector2(sz.x - stick_right.size.x - m * 3.0, sy)
	_banner.size = _banner.get_combined_minimum_size()
	_banner.position = Vector2((sz.x - _banner.size.x) * 0.5, sz.y - _banner.size.y - m * 2.0)


## Knüppel-Beschriftung nach aktuellem Stick-Mode (Gier immer rechts).
func _refresh_stick_captions() -> void:
	if fc == null:
		stick_left.caption = "Gas"
		stick_right.caption = "Nick · Gier"
		return
	var labels := fc.stick_labels()
	stick_left.caption = labels[0]
	stick_right.caption = labels[1]


## Kurzer Hinweis, verschwindet nach `seconds` von selbst.
func show_notice(text: String, level := "warning", seconds := 3.0) -> void:
	UITheme.set_banner(_banner, text, level)
	_banner_timer = seconds


func set_ar_active(active: bool) -> void:
	_btn_ar.set_pressed_no_signal(active)


func _on_arm_toggled(on: bool) -> void:
	if fc:
		fc.armed = on
	_btn_arm.text = "Motoren an" if on else "Motoren aus"


func _process(dt: float) -> void:
	# Knüppel → Flugcontroller
	if fc:
		fc.set_sticks(stick_left.value, stick_right.value)
		# Failsafe kann von außen entwaffnen (App im Hintergrund) → Schalter nachziehen
		if _btn_arm.button_pressed != fc.armed:
			_btn_arm.set_pressed_no_signal(fc.armed)
			_btn_arm.text = "Motoren an" if fc.armed else "Motoren aus"
		_pill_mode.text = "FC: Mode %d" % (int(fc.mode) + 1)
	if ship:
		_pill_speed.text = ("%.1f km/h" % (ship.airspeed * 3.6)).replace(".", ",")
		_pill_alpha.text = "α %d°" % roundi(ship.alpha_deg)
	_layout()                                         # Texte ändern Breiten
	# Banner ausblenden
	if _banner_timer > 0.0:
		_banner_timer -= dt
		if _banner_timer <= 0.0:
			UITheme.set_banner(_banner, "")
