# 2026-10-29 07:45 – Modusschalter mit 4 Stellungen (Gedämpft)
# 2026-10-29 00:19 – Modusschalter rückt in die zweite Reihe, wenn oben kein Platz ist
# 2026-10-28 08:51 – Zeile unter der Rundenanzeige: nächster Kontrollpunkt und Rundenzeiten
# 2026-10-28 08:14 – Knopf „Strecke“ und Rundenanzeige (Runde/Zeit) oben links
# 2026-10-28 00:15 – Modusschalter oben Mitte: Direkt / Geregelt / Luftschiff (ersetzt die Anzeige „FC: Mode n“)
# 2026-10-27 13:03 – Motor-Schalter heißt jetzt wie bei FPV-Drohnen: „Disarmed“ / „Armed“
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
signal course_requested

var fc: FlightController
var ship: AirshipPhysics

var stick_left: TouchStick
var stick_right: TouchStick
var _pill_speed: Button
var _pill_alpha: Button
var _pill_race: Button                    ## Runde / Zeit
var _laps: Label                          ## Rundenzeiten unter der Telemetrie
var _mode_box: HBoxContainer             ## Modusschalter oben Mitte
var _mode_btns := {}                      ## Mode → Button
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
	_pill_race = UITheme.make_pill("Start: vorderen Pylon passieren")
	for p in [_pill_speed, _pill_alpha, _pill_race]: tl.add_child(p)
	_laps = UITheme.make_label("", "MutedLabel")
	_laps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_laps)

	# --- Modusschalter oben Mitte (3 Stellungen wie Kanal 13) ----------------
	# „Geregelt ohne Vektor“ bleibt im PID-Menü wählbar; ist er aktiv, ist hier
	# keine Stellung markiert.
	_mode_box = UITheme.make_hbox("xs")
	add_child(_mode_box)
	var grp := UITheme.make_toggle_group()
	for md in [FlightController.Mode.DIRECT, FlightController.Mode.STABILIZED, FlightController.Mode.AIRSHIP, FlightController.Mode.DAMPED]:
		var b := UITheme.make_pill(FlightController.MODE_NAMES[md], true)
		b.toggle_mode = true
		b.button_group = grp
		b.pressed.connect(func(): if fc: fc.mode = md)
		_mode_box.add_child(b)
		_mode_btns[md] = b

	# --- Menüs oben rechts --------------------------------------------------
	_tr = UITheme.make_hbox("xs")
	var tr := _tr
	add_child(tr)
	_btn_arm = UITheme.make_pill("Disarmed", true)
	_btn_arm.toggle_mode = true
	_btn_arm.toggled.connect(_on_arm_toggled)
	var b_reset := UITheme.make_pill("Zurücksetzen", true)
	b_reset.pressed.connect(func(): reset_requested.emit())
	var b_build := UITheme.make_pill("Bau", true)
	b_build.pressed.connect(func(): builder_requested.emit())
	var b_course := UITheme.make_pill("Strecke", true)
	b_course.pressed.connect(func(): course_requested.emit())
	var b_pid := UITheme.make_pill("PID", true)
	b_pid.pressed.connect(func(): pid_requested.emit())
	_btn_ar = UITheme.make_pill("AR", true)
	_btn_ar.toggle_mode = true
	_btn_ar.pressed.connect(func(): ar_requested.emit())
	for b in [b_reset, _btn_arm, b_course, b_build, b_pid, _btn_ar]: tr.add_child(b)

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
	_laps.size = _laps.get_combined_minimum_size()
	_laps.position = Vector2(m, _tl.position.y + _tl.size.y + m * 0.5)
	# Schalter mittig zwischen Telemetrie und Menüs
	_mode_box.size = _mode_box.get_combined_minimum_size()
	var free0 := _tl.position.x + _tl.size.x + m
	var free1 := _tr.position.x - m
	if free1 - free0 >= _mode_box.size.x:
		_mode_box.position = Vector2((free0 + free1 - _mode_box.size.x) * 0.5, m)
	else:
		# zu schmal (Handy): Schalter in die zweite Reihe unter die Menüknöpfe
		_mode_box.position = Vector2(sz.x - _mode_box.size.x - m, _tr.position.y + _tr.size.y + m * 0.5)
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


## Rundenanzeige (Runde, Zeit, nächster Punkt) und Rundenzeiten – kommt
## jeden Physikschritt von der Strecke.
func set_race_text(text: String, laps := "") -> void:
	if _pill_race.text != text:
		_pill_race.text = text
	if _laps.text != laps:
		_laps.text = laps


func set_ar_active(active: bool) -> void:
	_btn_ar.set_pressed_no_signal(active)


func _on_arm_toggled(on: bool) -> void:
	if fc:
		fc.armed = on
	_btn_arm.text = "Armed" if on else "Disarmed"


func _process(dt: float) -> void:
	# Knüppel → Flugcontroller
	if fc:
		fc.set_sticks(stick_left.value, stick_right.value)
		# Failsafe kann von außen entwaffnen (App im Hintergrund) → Schalter nachziehen
		if _btn_arm.button_pressed != fc.armed:
			_btn_arm.set_pressed_no_signal(fc.armed)
			_btn_arm.text = "Armed" if fc.armed else "Disarmed"
		for mm in _mode_btns:                         # Stellung nachziehen (auch nach PID-Menü)
			var on: bool = int(fc.mode) == int(mm)
			if _mode_btns[mm].button_pressed != on:
				_mode_btns[mm].set_pressed_no_signal(on)
	if ship:
		_pill_speed.text = ("%.1f km/h" % (ship.airspeed * 3.6)).replace(".", ",")
		_pill_alpha.text = "α %d°" % roundi(ship.alpha_deg)
	_layout()                                         # Texte ändern Breiten
	# Banner ausblenden
	if _banner_timer > 0.0:
		_banner_timer -= dt
		if _banner_timer <= 0.0:
			UITheme.set_banner(_banner, "")
