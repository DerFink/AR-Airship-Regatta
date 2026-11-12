# 2026-11-13 00:50 – Modusknöpfe aus den Flugmodi des Piloten (1–5, frei benannt), Tasten 1–5, Modus-Kanal in N Bereiche
# 2026-11-11 20:05 – Zählt, womit gesteuert wird (Sender/Tastatur/Touch) für „gespielt mit“ in der Bestenliste
# 2026-11-11 17:50 – Knopf ⚙ (Einstellungen) neben „Menü“
# 2026-11-11 16:35 – Rundenzeiten rechts oben (RacePanel) mit Gesamtzeit und gewerteter Zeit (F7B); oben links nur noch nächster Kontrollpunkt
# 2026-11-11 16:00 – Knopf „Autopilot“ heißt „Demo“
# 2026-11-11 15:20 – Sender und Tastatur liefern Funktionen, Anzeige auf den Knüppeln nach Stickmode 1–4
# 2026-11-11 17:45 – Knüppel-Beschriftung, Akku- und Fahrtanzeige übersetzt (Dezimalzeichen je Sprache); bei Sprachwechsel neu beschriftet
# 2026-11-11 00:00 – Knopf „Perspektive“ immer gleich beschriftet (gewählte Sicht kurz als Hinweis); ohne Teensy nur „Direkt“; Tastatursteuerung
# 2026-11-10 21:45 – Neue Knopfreihe oben (alles in einer Reihe): Modi · Autopilot · Perspektive (Pilot am Start → Hinterher → Hinterher + Lage) · Zurücksetzen · Armed · Menü; „Menü“ öffnet direkt „Modell & Bau“; Reglerwahl, Location- und Demo-Knöpfe sowie das alte Menü entfernt; Kalibrierfenster per open_calibration()
# 2026-11-10 14:20 – Knöpfe „Halle | Wiese“ (Location) in der Knopfreihe; Akku-Anzeige links unter den Rundenzeiten (Spannung, Ladezustand, Strom, Restzeit)
# 2026-11-09 14:20 – Fenster „Sender kalibrieren“ (aus dem Menü); solange offen: Motoren aus, Knüppel wirken nicht
# 2026-11-09 10:20 – Neben dem Modusschalter: Reglerwahl „Teensy | Sim-optimiert“ und Knopf „Demo“ (während der Demo „Demo stoppen“)
# 2026-11-09 10:00 – Demo-Flug: Menüeintrag, Knüppel werden während der Demo nicht an den Regler gegeben
# 2026-11-08 18:00 – Menü zeigt das verbundene Sendergerät
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
#   ┌ Direkt│Mode 2│Mode 3 · Autopilot · Perspektive · Zurücksetzen · Armed · Menü ┐
#   │ 12,4 km/h │ α 6° │ Runde   (Telemetrie, rückt nach oben links, wenn Platz)  │
#   │                                                                   │
#   │  ( Gas )               [Hinweis-Banner]              ( Nick·Gier )│
#   └───────────────────────────────────────────────────────────────────┘
#
# Alle Elemente entstehen über UITheme – keine eigenen Farben/Größen hier.
# =============================================================================
class_name FlightHUD
extends Control

signal reset_requested
signal hub_requested               ## „Menü“ → Modell & Bau
signal settings_requested          ## ⚙ → Einstellungen
signal autopilot_requested         ## Autopilot an/aus
signal perspective_changed(index: int)
## Autopilot fliegt gerade (Knöpfe zeigen „Autopilot stoppen“, Knüppel ruhen)
var autopilot_active := false
## Kamera: 0 = Pilot am Start, 1 = Hinterher, 2 = Hinterher + Lage
var perspective := 0
const PERSPECTIVES := ["Pilot am Start", "Hinterher", "Hinterher + Lage"]

var fc: FlightController
var ship: AirshipPhysics

var stick_left: TouchStick
var stick_right: TouchStick
var _pill_speed: Button
var _pill_alpha: Button
var _pill_race: Button                    ## Runde / Zeit
var _laps: Label                          ## Hinweis unter der Telemetrie (vor dem Start)
## Womit wurde gesteuert? (Bildzahl je Eingabe, für „gespielt mit“ in der Bestenliste)
var input_frames := {"Sender": 0, "Tastatur": 0, "Touch": 0}
var race_panel: RacePanel                 ## Rundenzeiten, Gesamt- und gewertete Zeit (rechts oben)
var _mode_box: HBoxContainer
var _mode_btn_box: HBoxContainer            ## Knöpfe der Flugmodi (1–5)             ## Modusschalter oben Mitte
var _mode_btns := {}                      ## Mode → Button
var _btn_arm: Button
var _btn_auto: Button                     ## Autopilot
var _btn_persp: Button                    ## Perspektive (ein Knopf, wechselt reihum)
## Tastatur: W/S Gas (bleibt stehen, X = Gas Mitte), Pfeile Nick/Gier (federn
## zurück), Leertaste Armed, R Zurücksetzen, 1/2/3 Modus, A Autopilot,
## P Perspektive, M Menü
var _kb_throttle := 0.0
var _kb_pitch := 0.0
var _kb_yaw := 0.0
var _kb_used := false                     ## Tastatur hat zuletzt gesteuert
var _calib: CalibrationPanel              ## Fenster „Sender kalibrieren“
## Von main.gd gesetzt: Strecke (für die Location-Anzeige) und Akku-Modell
var course: Course
var battery: Battery
var _batt_box: PanelContainer             ## Akku-Anzeige (dunkle Kachel, auf hellem Grund lesbar)
var _batt_top: Label
var _batt_bar_bg: ColorRect
var _batt_bar: ColorRect
var _batt_bottom: Label
var _banner: PanelContainer
var _banner_timer := 0.0
var _tl: HBoxContainer
var _tr: HBoxContainer
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
	# Rennanzeige rechts oben (unter den Knöpfen, über dem rechten Knüppel)
	race_panel = RacePanel.new()
	race_panel.visible = false
	add_child(race_panel)

	# --- Modusschalter oben Mitte (3 Stellungen wie Kanal 13 am Teensy) -----
	# Beim Umschalten erklärt ein kurzes Banner, was die Knüppel jetzt tun.
	_mode_box = UITheme.make_hbox("xs")
	add_child(_mode_box)
	# Ein Knopf je Flugmodus des Piloten (1–5, Namen aus dem Reglermenü)
	_mode_btn_box = UITheme.make_hbox("xs")
	_mode_box.add_child(_mode_btn_box)
	_rebuild_mode_buttons()
	if fc:
		fc.modes_changed.connect(_rebuild_mode_buttons)

	# --- Gleich daneben: Autopilot und Perspektive (alle Knöpfe in einer Reihe) ---
	var gap := Control.new()                   # kleiner Abstand zwischen den Gruppen
	gap.custom_minimum_size.x = UITheme.space("md")
	_mode_box.add_child(gap)
	_btn_auto = UITheme.make_pill("Demo", true)
	_btn_auto.pressed.connect(func(): autopilot_requested.emit())
	_mode_box.add_child(_btn_auto)
	_btn_persp = UITheme.make_pill("", true)
	_btn_persp.text = "Perspektive"           # Text bleibt immer gleich (Wunsch Nutzer)
	_btn_persp.pressed.connect(func():
		perspective = (perspective + 1) % PERSPECTIVES.size()
		show_notice(PERSPECTIVES[perspective], "info", 1.5)    # kurz zeigen, welche Sicht jetzt gilt
		perspective_changed.emit(perspective))
	_mode_box.add_child(_btn_persp)
	var gap2 := Control.new()
	gap2.custom_minimum_size.x = UITheme.space("md")
	_mode_box.add_child(gap2)

	# --- Akku-Anzeige (links unter den Rundenzeiten) ---
	_batt_box = PanelContainer.new()
	_batt_box.add_theme_stylebox_override("panel", UITheme.box(Color(0.08, 0.11, 0.15, 0.82), Color(0, 0, 0, 0), -1, UITheme.space("sm")))
	_batt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bv := UITheme.make_vbox("xs")
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_batt_box.add_child(bv)
	_batt_top = UITheme.make_label("Akku")
	_batt_bar_bg = ColorRect.new()
	_batt_bar_bg.color = Color(0.2, 0.22, 0.27, 0.85)
	_batt_bar_bg.custom_minimum_size = Vector2(220, 10)
	_batt_bar = ColorRect.new()
	_batt_bar.size = Vector2(220, 10)
	_batt_bar_bg.add_child(_batt_bar)
	_batt_bottom = UITheme.make_label("")
	_batt_bottom.modulate = Color(0.8, 0.85, 0.9)
	for c in [_batt_top, _batt_bar_bg, _batt_bottom]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(c)
	add_child(_batt_box)

	# --- Rechts in derselben Reihe: Zurücksetzen, Armed, Menü (→ Modell & Bau) ---
	_tr = UITheme.make_hbox("xs")
	var tr_box := _tr
	_mode_box.add_child(tr_box)
	_btn_arm = UITheme.make_pill("Disarmed", true)
	_btn_arm.toggle_mode = true
	_btn_arm.toggled.connect(_on_arm_toggled)
	var b_menu := UITheme.make_pill("Menü", true)
	b_menu.pressed.connect(func(): hub_requested.emit())
	var b_reset := UITheme.make_pill("Zurücksetzen", true)
	b_reset.pressed.connect(func(): reset_requested.emit())
	var b_set := UITheme.make_pill("", true)           # Einstellungen (Musik, Motorklang, Spur, Platzen …)
	b_set.icon = load("res://textures/zahnrad.svg")    # Zahnrad (die Schrift hat kein ⚙)
	b_set.expand_icon = false
	b_set.add_theme_constant_override("icon_max_width", 26)
	b_set.pressed.connect(func(): settings_requested.emit())
	for b in [b_reset, _btn_arm, b_set, b_menu]: tr_box.add_child(b)

	# --- Knüppel ------------------------------------------------------------
	stick_left = TouchStick.new()
	stick_right = TouchStick.new()
	for s in [stick_left, stick_right]:
		add_child(s)
	_refresh_stick_captions()
	if fc:
		fc.stick_mode_changed.connect(_refresh_stick_captions)

	# --- Hinweis-Banner unten mittig ---------------------------------------
	_banner = UITheme.make_banner(360)
	add_child(_banner)

	# --- Sender per USB (Taranis/EdgeTX als Joystick) -------------------------
	_joy = JoystickInput.new()
	add_child(_joy)
	_joy.connected.connect(func(n): show_notice(tr("Sender verbunden") + I18n.t(": %s – SF = Armed, SC = Mode") % n, "info", 4.0))
	_joy.disconnected.connect(func():
		if fc: fc.armed = false                     # Failsafe: Sender weg → Motoren aus
		show_notice("Sender getrennt – Motoren aus", "warning", 4.0))
	_joy.arm_switched.connect(func(on):
		if fc: fc.armed = on)
	_joy.reset_switched.connect(func(): reset_requested.emit())   # SH oben = Zurücksetzen
	_joy.mode_switched.connect(func(m):
		if fc and fc.mode_index != m and m < fc.modes.size():
			fc.mode_index = m
			show_notice(fc.mode_hint(m), "info", 3.0))

	# Fenster „Sender kalibrieren“ (über allem; geöffnet von der Startseite)
	_calib = CalibrationPanel.new()
	_calib.joy = _joy
	_calib.fc = fc
	add_child(_calib)
	# Tastenkürzel grau auf den Knöpfen (nur wo es eine Tastatur gibt)
	if has_keyboard():
		for pair in [[_btn_auto, "A"], [_btn_persp, "P"],
				[b_reset, "R"], [_btn_arm, "Space"], [b_menu, "M"]]:
			_key_hint(pair[0], pair[1])
	resized.connect(_layout)
	_layout.call_deferred()


## Modusknöpfe neu aufbauen (Anzahl/Namen im Reglermenü geändert).
func _rebuild_mode_buttons() -> void:
	for c in _mode_btn_box.get_children():
		_mode_btn_box.remove_child(c)
		c.queue_free()
	_mode_btns.clear()
	if fc == null:
		return
	var grp := UITheme.make_toggle_group()
	for i in fc.modes.size():
		var b := UITheme.make_pill(str(fc.modes[i].get("name", "Modus %d" % (i + 1))), true)
		b.toggle_mode = true
		b.button_group = grp
		var idx := i
		b.pressed.connect(func():
			if fc:
				fc.mode_index = idx
				show_notice(fc.mode_hint(idx), "info", 3.0))
		_mode_btn_box.add_child(b)
		_mode_btns[i] = b
		if has_keyboard() and i < 5:
			_key_hint(b, str(i + 1))


# =============================================================================
# Platzierung (bei jeder Größenänderung und jedem Frame – billig):
# Positionen werden direkt aus der aktuellen Bildschirmgröße berechnet,
# statt sich auf Godot-Anker zu verlassen, deren Mindestgrößen beim Aufbau
# noch nicht feststehen.
# =============================================================================
func _layout() -> void:
	var m := float(UITheme.space("lg"))
	var sz := size
	# Knopfreihe oben rechtsbündig (bei schmalen Bildschirmen so weit links wie nötig)
	_mode_box.size = _mode_box.get_combined_minimum_size()
	_mode_box.position = Vector2(maxf(m, sz.x - _mode_box.size.x - m), m)
	# Telemetrie links daneben, wenn Platz ist – sonst in die zweite Reihe
	_tl.size = _tl.get_combined_minimum_size()
	if _mode_box.position.x - m >= _tl.size.x + m:
		_tl.position = Vector2(m, m)
	else:
		_tl.position = Vector2(m, _mode_box.position.y + _mode_box.size.y + m * 0.5)
	_laps.size = _laps.get_combined_minimum_size()
	_laps.position = Vector2(m, _tl.position.y + _tl.size.y + m * 0.5)
	race_panel.size = race_panel.get_combined_minimum_size()
	race_panel.position = Vector2(sz.x - race_panel.size.x - m, _mode_box.position.y + _mode_box.size.y + m * 0.5)
	_batt_box.size = _batt_box.get_combined_minimum_size()
	_batt_box.position = Vector2(m, _laps.position.y + _laps.size.y + m * 0.5)
	for st in [stick_left, stick_right]:
		st.size = st.custom_minimum_size
	var sy := sz.y - stick_left.size.y - m
	stick_left.position = Vector2(m * 3.0, sy)
	stick_right.position = Vector2(sz.x - stick_right.size.x - m * 3.0, sy)
	_banner.size = _banner.get_combined_minimum_size()
	_banner.position = Vector2((sz.x - _banner.size.x) * 0.5, sz.y - _banner.size.y - m * 2.0)


## Gibt es (vermutlich) eine Tastatur? Am PC und im Browser am PC ja,
## auf Handy/Tablet (auch im Browser) nein.
static func has_keyboard() -> bool:
	return not (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))


## Tastenkürzel klein und grau rechts im Knopf; der Knopf wird dafür breiter.
func _key_hint(b: Button, key: String) -> void:
	var l := Label.new()
	l.text = key
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.62, 0.66, 0.72))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.add_child(l)
	var w := l.get_combined_minimum_size().x + 6.0
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var sb := b.get_theme_stylebox(st)
		if sb:
			sb = sb.duplicate()
			sb.content_margin_right = maxf(sb.content_margin_right, 0.0) + w
			b.add_theme_stylebox_override(st, sb)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	l.offset_left = -w - 2.0
	l.offset_right = -6.0


## Fenster „Sender kalibrieren“ öffnen (Motoren aus, bevor geknüppelt wird).
func open_calibration() -> void:
	if fc: fc.armed = false
	_calib.show_panel()


## Sprache gewechselt → Knüppel-Beschriftung neu (sie wird beim Setzen übersetzt).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and stick_left != null:
		_refresh_stick_captions()


## Knüppel-Beschriftung nach aktuellem Stick-Mode (Gier immer rechts).
func _refresh_stick_captions() -> void:
	if fc == null:
		stick_left.caption = I18n.t("Gas")
		stick_right.caption = I18n.t("Nick · Gier")
		return
	var labels := fc.stick_labels()
	# Beschriftung schon hier übersetzen – die Tasten kommen danach dazu
	stick_left.caption = I18n.t(labels[0])
	stick_right.caption = I18n.t(labels[1])
	if has_keyboard():                               # Tasten dazuschreiben
		# Tasten je Funktion; Rolle hat keine Taste
		var keys := {"thr": "W/S", "pitch": "↑↓", "yaw": "←→", "roll": ""}
		var lay: Array = FlightController.STICK_LAYOUT.get(fc.stick_mode, FlightController.STICK_LAYOUT[4])
		var kl: String = (keys[lay[1]] + " " + keys[lay[0]]).strip_edges()
		var kr: String = (keys[lay[3]] + " " + keys[lay[2]]).strip_edges()
		stick_left.caption += "  (%s)" % kl
		stick_right.caption += "  (%s)" % kr


## Akku-Anzeige: oben Zellen und Spannung, Balken = Ladezustand (grün → gelb →
## rot), unten Prozent, Strom und geschätzte Restflugzeit.
func _update_battery() -> void:
	if battery == null:
		_batt_box.visible = false
		return
	_batt_box.visible = true
	var pct := battery.soc * 100.0
	_batt_top.text = I18n.dec(I18n.t("Akku %dS · %.2f V") % [battery.cells, battery.voltage])
	var w := _batt_bar_bg.custom_minimum_size.x
	_batt_bar.size = Vector2(w * battery.soc, _batt_bar_bg.custom_minimum_size.y)
	_batt_bar.color = Color(0.25, 0.75, 0.42) if battery.soc > 0.3 else (Color(0.95, 0.75, 0.2) if battery.soc > 0.1 else Color(0.9, 0.3, 0.25))
	var rest := battery.remaining_s()
	var rest_txt := "–" if rest == INF or rest > 5999.0 else "%d:%02d min" % [int(rest) / 60, int(rest) % 60]
	_batt_bottom.text = I18n.dec(I18n.t("%d %% · %.1f A · Rest ≈ %s") % [roundi(pct), battery.current, rest_txt])
	if battery.soc <= 0.0:
		_batt_bottom.text = tr("Akku leer")


## Kurzer Hinweis, verschwindet nach `seconds` von selbst.
func show_notice(text: String, level := "warning", seconds := 3.0) -> void:
	UITheme.set_banner(_banner, text, level)
	_banner_timer = seconds


## Meistgenutzte Steuerung seit dem letzten Zurücksetzen ("Sender", "Tastatur", "Touch").
func dominant_input() -> String:
	var best := "Touch"
	for k in input_frames:
		if input_frames[k] > input_frames[best]: best = k
	return best


## Rundenanzeige (Runde, Zeit, nächster Punkt) und Rundenzeiten – kommt
## jeden Physikschritt von der Strecke.
func set_race_text(text: String, laps := "") -> void:
	if _pill_race.text != text:
		_pill_race.text = text
	if _laps.text != laps:
		_laps.text = laps
	if race_panel:
		var was := race_panel.visible
		race_panel.refresh()
		if race_panel.visible != was:
			_layout.call_deferred()             # Größe/Lage neu, sobald die Anzeige erscheint


## Tastatursteuerung: liefert true, solange die Tastatur steuert.
## Gas hält seine Stellung wie ein ratschender Gasknüppel, Nick und Gier laufen
## beim Drücken in ≈ 0,25 s auf Vollausschlag und federn beim Loslassen zurück.
func _keyboard(dt: float) -> bool:
	var up := Input.is_physical_key_pressed(KEY_UP)
	var dn := Input.is_physical_key_pressed(KEY_DOWN)
	var lf := Input.is_physical_key_pressed(KEY_LEFT)
	var rt := Input.is_physical_key_pressed(KEY_RIGHT)
	var w := Input.is_physical_key_pressed(KEY_W)
	var sk := Input.is_physical_key_pressed(KEY_S)
	if Input.is_physical_key_pressed(KEY_X):
		_kb_throttle = 0.0
	if w: _kb_throttle = minf(_kb_throttle + 0.8 * dt, 1.0)
	if sk: _kb_throttle = maxf(_kb_throttle - 0.8 * dt, -1.0)
	var tp := (1.0 if up else 0.0) - (1.0 if dn else 0.0)      # Pfeil hoch = Knüppel vor = Nase runter
	var ty := (1.0 if rt else 0.0) - (1.0 if lf else 0.0)
	_kb_pitch = move_toward(_kb_pitch, tp, dt * 4.0)
	_kb_yaw = move_toward(_kb_yaw, ty, dt * 4.0)
	if up or dn or lf or rt or w or sk:
		_kb_used = true
	# Bildschirmknüppel angefasst → Tastatur gibt ab
	for st in [stick_left, stick_right]:
		if st._finger >= 0 or st._mouse_down:
			_kb_used = false
	if not _kb_used:
		return false
	# Tasten liefern Funktionen; der Stickmode legt fest, welcher Knüppel sie zeigt
	var ks := fc.set_stick_functions(_kb_throttle, _kb_pitch, _kb_yaw)
	stick_left.show_external(ks[0])
	stick_right.show_external(ks[1])
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_SPACE:
			_btn_arm.button_pressed = not _btn_arm.button_pressed
		KEY_R:
			reset_requested.emit()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			var md: int = event.physical_keycode - KEY_1
			if _mode_btns.has(md) and not _mode_btns[md].disabled:
				_mode_btns[md].emit_signal("pressed")
		KEY_P:
			_btn_persp.emit_signal("pressed")
		KEY_A:
			autopilot_requested.emit()
		KEY_M:
			hub_requested.emit()
		_:
			return
	get_viewport().set_input_as_handled()


func _on_arm_toggled(on: bool) -> void:
	if fc:
		fc.armed = on
	_btn_arm.text = tr("Armed") if on else tr("Disarmed")


func _process(dt: float) -> void:
	# Knüppel → Flugcontroller
	if fc:
		if _calib and _calib.visible:
			fc.armed = false                          # Kalibrieren: Motoren aus, Knüppel wirken nicht
			fc.set_sticks(Vector2.ZERO, Vector2.ZERO)
		elif autopilot_active:
			pass                                      # Autopilot steuert über die Knüppel
		elif _keyboard(dt):
			input_frames.Tastatur += 1                # Tastatur steuert (Bildschirmknüppel zeigen sie)
		elif _joy and _joy.active():
			# Sender angeschlossen: er liefert Funktionen, der Stickmode legt fest,
			# auf welchem Bildschirmknüppel sie angezeigt werden
			input_frames.Sender += 1
			var js := fc.set_stick_functions(_joy.f_thr, _joy.f_pitch, _joy.f_yaw, _joy.f_roll)
			stick_left.show_external(js[0])
			stick_right.show_external(js[1])
		else:
			if stick_left.value != Vector2.ZERO or stick_right.value != Vector2.ZERO:
				input_frames.Touch += 1
			fc.set_sticks(stick_left.value, stick_right.value)
		# Failsafe kann von außen entwaffnen (App im Hintergrund) → Schalter nachziehen
		if _btn_arm.button_pressed != fc.armed:
			_btn_arm.set_pressed_no_signal(fc.armed)
			_btn_arm.text = tr("Armed") if fc.armed else tr("Disarmed")
		var teensy: bool = ship == null or ship.fc_teensy
		if _joy: _joy.mode_count = fc.modes.size()
		for mm in _mode_btns:                         # Stellung nachziehen (auch nach PID-Menü)
			if mm >= fc.modes.size(): continue
			# ohne FC (Baukasten) nur Modi der Art „Direkt“
			var is_direct: bool = str(fc.modes[mm].get("art", "")) == "direkt"
			_mode_btns[mm].disabled = not teensy and not is_direct
			var on: bool = fc.mode_index == mm
			if _mode_btns[mm].button_pressed != on:
				_mode_btns[mm].set_pressed_no_signal(on)
	_update_battery()
	var atxt := tr("Demo stoppen") if autopilot_active else tr("Demo")
	if _btn_auto.text != atxt:
		_btn_auto.text = atxt
	if ship:
		_pill_speed.text = I18n.dec(I18n.t("%.1f km/h") % (ship.airspeed * 3.6))
		_pill_alpha.text = "α %d°" % roundi(ship.alpha_deg)
	_layout()                                         # Texte ändern Breiten
	# Banner ausblenden
	if _banner_timer > 0.0:
		_banner_timer -= dt
		if _banner_timer <= 0.0:
			UITheme.set_banner(_banner, "")
