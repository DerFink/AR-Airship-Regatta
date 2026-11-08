# 2026-11-08 17:15 – Bildschirmknüppel bewegen sich mit den Senderknüppeln
# 2026-11-08 15:40 – Hinweis beim Verbinden: SF oben = scharf
# 2026-11-08 15:25 – Schalter SH (Kanal 7) setzt zurück
# 2026-11-08 14:30 – Sender per USB (Taranis als Joystick): Knüppel, SF = Arming, SC = Modus; Sender getrennt → Motoren aus
# 2026-11-07 23:55 – Knopf „Zurücksetzen“ wieder oben rechts (vor „Armed“ und „Menü“)
# 2026-11-07 21:10 – Oben rechts nur noch „Armed“ und „Menü“; Bau, Strecke, PID, AR, Zurücksetzen, Modellwahl, Bestenliste und Version im Menü (MainMenu); Modusschalter in der oberen Reihe
# 2026-11-07 20:45 – Modusschalter mit 3 Stellungen Direkt / Mode 2 / Mode 3 (wie Kanal 13); Banner mit Kurzbeschreibung beim Umschalten
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
#   ┌ 12,4 km/h │ α 6° │ Runde │ Direkt│Mode 2│Mode 3      Armed │ ☰ Menü ┐
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
signal model_requested
signal leaderboard_requested

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
var _banner: PanelContainer
var _banner_timer := 0.0
var _tl: HBoxContainer
var _tr: HBoxContainer
var _menu: MainMenu                       ## Menü (Modell, Bau, Strecke, …, Version)
var _joy: JoystickInput                   ## Sender per USB (Taranis); steuert statt der Bildschirmknüppel
var _ar_on := false                       ## AR an? (für die Anzeige im Menü)
## Liefert {"model": Name, "course": Titel} fürs Menü (setzt main.gd)
var menu_info: Callable


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

	# --- Modusschalter oben Mitte (3 Stellungen wie Kanal 13 am Teensy) -----
	# Beim Umschalten erklärt ein kurzes Banner, was die Knüppel jetzt tun.
	_mode_box = UITheme.make_hbox("xs")
	add_child(_mode_box)
	var grp := UITheme.make_toggle_group()
	for md in [FlightController.Mode.DIRECT, FlightController.Mode.MODE2, FlightController.Mode.MODE3]:
		var b := UITheme.make_pill(FlightController.MODE_NAMES[md], true)
		b.toggle_mode = true
		b.button_group = grp
		b.pressed.connect(func():
			if fc:
				fc.mode = md
				show_notice(FlightController.MODE_HINTS[md], "info", 3.0))
		_mode_box.add_child(b)
		_mode_btns[md] = b

	# --- Oben rechts: nur „Armed“ und „Menü“ (Armen bleibt immer direkt erreichbar) ---
	_tr = UITheme.make_hbox("xs")
	var tr := _tr
	add_child(tr)
	_btn_arm = UITheme.make_pill("Disarmed", true)
	_btn_arm.toggle_mode = true
	_btn_arm.toggled.connect(_on_arm_toggled)
	var b_menu := UITheme.make_pill("Menü", true)   # ohne Symbol: die Standardschrift hat kein ☰
	b_menu.pressed.connect(func(): _menu.show_menu())
	# „Zurücksetzen“ wieder direkt erreichbar (Wunsch Nutzer) – auch weiter im Menü
	var b_reset := UITheme.make_pill("Zurücksetzen", true)
	b_reset.pressed.connect(func(): reset_requested.emit())
	for b in [b_reset, _btn_arm, b_menu]: tr.add_child(b)

	# --- Knüppel ------------------------------------------------------------
	stick_left = TouchStick.new()
	stick_right = TouchStick.new()
	for s in [stick_left, stick_right]:
		add_child(s)
	_refresh_stick_captions()

	# --- Hinweis-Banner unten mittig ---------------------------------------
	_banner = UITheme.make_banner(360)
	add_child(_banner)

	# --- Sender per USB (Taranis/EdgeTX als Joystick) -------------------------
	_joy = JoystickInput.new()
	add_child(_joy)
	_joy.connected.connect(func(n): show_notice("Sender verbunden: %s – SF oben = scharf, SC = Modus" % n, "info", 4.0))
	_joy.disconnected.connect(func():
		if fc: fc.armed = false                     # Failsafe: Sender weg → Motoren aus
		show_notice("Sender getrennt – Motoren aus", "warning", 4.0))
	_joy.arm_switched.connect(func(on):
		if fc: fc.armed = on)
	_joy.reset_switched.connect(func(): reset_requested.emit())   # SH oben = Zurücksetzen
	_joy.mode_switched.connect(func(m):
		if fc and int(fc.mode) != m:
			fc.mode = m
			show_notice(FlightController.MODE_HINTS[m], "info", 3.0))

	# --- Menü (über allem; Einträge melden sich als Signale der Flugansicht) ---
	_menu = MainMenu.new()
	add_child(_menu)
	_menu.info_source = func():
		var d: Dictionary = menu_info.call() if menu_info.is_valid() else {}
		d["ar"] = _ar_on
		return d
	_menu.model_requested.connect(func(): model_requested.emit())
	_menu.builder_requested.connect(func(): builder_requested.emit())
	_menu.course_requested.connect(func(): course_requested.emit())
	_menu.leaderboard_requested.connect(func(): leaderboard_requested.emit())
	_menu.pid_requested.connect(func(): pid_requested.emit())
	_menu.ar_requested.connect(func(): ar_requested.emit())
	_menu.reset_requested.connect(func(): reset_requested.emit())
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
	_ar_on = active


func _on_arm_toggled(on: bool) -> void:
	if fc:
		fc.armed = on
	_btn_arm.text = "Armed" if on else "Disarmed"


func _process(dt: float) -> void:
	# Knüppel → Flugcontroller
	if fc:
		if _joy and _joy.active():
			fc.set_sticks(_joy.left, _joy.right)      # Sender angeschlossen: er steuert
			stick_left.show_external(_joy.left)       # Bildschirmknüppel zeigen die Senderknüppel
			stick_right.show_external(_joy.right)
		else:
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
