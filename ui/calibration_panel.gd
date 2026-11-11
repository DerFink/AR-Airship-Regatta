# 2026-11-11 16:00 – Knöpfe ohne Fokus – Sender-Schalter drückten über die Joypad-Navigation versehentlich „Mode 1“
# 2026-11-11 15:30 – Stickmode 1–4 wählbar (Standard Mode 4); Knüppelfelder zeigen die Funktionen nach dem Stickmode
# 2026-11-11 17:45 – Anleitung als ein Text (übersetzbar); Knüppelfelder-Beschriftung übersetzt
# 2026-11-11 14:10 – Kanalzuordnung: je Funktion Kanal wählen oder „Anlernen“ (Knüppel/Schalter bewegen → Kanal wird erkannt); Kanalnamen folgen der Zuordnung; 8 Kanäle
# 2026-11-09 14:10 – Auch Sender mit kleinem Ausschlag (z. B. nur ±60 %) werden erfasst: Knüppel gelten als bewegt, sobald sie je Seite ≥ 30 % über die Mitte hinaus waren; der erreichte Anschlag wird zu 100 %
# 2026-11-09 14:20 – Erstversion: Fenster „Sender kalibrieren“ nach freigegebenem Entwurf (beide Knüppelfelder, Kanalliste mit Min/Mitte/Max, Status und Richtungsumkehr, Schalterstellungen; Motoren aus, solange offen)
# =============================================================================
# CalibrationPanel.gd
# -----------------------------------------------------------------------------
#   ┌ Sender kalibrieren ─────────────────────── ● Taranis · Motoren aus ┐
#   │ 1. Knüppel im Kreis an alle Anschläge, Schalter durchschalten …    │
#   │  Linker Knüppel   Rechter Knüppel   CH1 Seite  -98/2/100 ✓ [normal]│
#   │  ┌─────────┐      ┌─────────┐       CH2 Höhe   …             …     │
#   │  │    +  ● │      │  +      │       …                              │
#   │  └─────────┘      └─────────┘       SF: oben · scharf  SC: …       │
#   │      [Werkseinstellung] [Abbrechen] [Mitte übernehmen] [Speichern] │
#   └────────────────────────────────────────────────────────────────────┘
# Ablauf: Beim Öffnen beginnt die Erfassung neu (Min/Max = jetzige Stellung).
# Jede Knüppel-/Schalterbewegung erweitert den Bereich. „Mitte übernehmen“
# merkt die jetzige Stellung der Knüppel als Mitte. „Speichern“ übernimmt alles
# in JoystickInput (dauerhaft). Kanäle, die nicht weit genug bewegt wurden,
# behalten ihre bisherigen Anschläge – so kann man auch nur die Richtung
# eines Kanals umdrehen, ohne alles neu zu knüppeln.
# =============================================================================
class_name CalibrationPanel
extends Control

signal closed

## Ab wann ein Kanal als erfasst gilt. Der erreichte Anschlag wird dann zu
## ±100 % – auch wenn der Sender selbst nur z. B. ±60 % ausgibt.
const STICK_SIDE_OK := 0.3          ## Knüppel: je Seite mindestens 30 % über die Mitte hinaus
const SWITCH_RANGE_OK := 0.5        ## Schalter: mindestens zwei Stellungen (max − min)
## Kurzname je Funktion (Kanalliste)
const SHORT := {"yaw": "Seite", "pitch": "Höhe", "thr": "Gas", "roll": "Rolle", "arm": "Armed", "mode": "Modus", "reset": "Zurücks."}
const STICKS := ["yaw", "pitch", "thr", "roll"]

var joy: JoystickInput
var fc: FlightController                 ## für den Stickmode (Mode 1–4)
var _mode_btns := {}                     ## Stickmode → Knopf

var _panel: PanelContainer
var _dev: Label
var _left: StickField
var _right: StickField
var _rows: Array = []                ## je Kanal {values: Label, status: Label, inv: Button}
var _switches: Label
var _work: Array = []                ## Arbeitskopie der Kalibrierung (wird erst beim Speichern übernommen)
var _cap: Array = []                 ## erfasster Rohbereich je Kanal {min, max}
var _wmap := {}                      ## Arbeitskopie der Zuordnung Funktion → Kanal
var _map_opts := {}                  ## Funktion → OptionButton
var _learn := ""                     ## Funktion, die gerade angelernt wird ("" = keine)
var _learn_base: Array = []          ## Rohwerte beim Start des Anlernens
var _learn_btns := {}
var _names: Array = []               ## Kanalname-Labels


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = UITheme.make_panel(1100)
	add_child(_panel)
	var box := UITheme.make_vbox("sm")
	_panel.add_child(box)

	# --- Kopfzeile: Titel links, Gerät rechts -------------------------------
	var head := UITheme.make_hbox("sm")
	var title := UITheme.make_title("Sender kalibrieren")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_dev = UITheme.make_label("", "MutedLabel")
	head.add_child(_dev)
	box.add_child(head)

	# --- Anleitung ------------------------------------------------------------
	var how := UITheme.make_label("1. Beide Knüppel einmal ganz im Kreis an alle Anschläge, alle Schalter durchschalten.  2. Knüppel loslassen, Gas in die Mitte → „Mitte übernehmen“.  3. Läuft ein Punkt verkehrt herum: Kanal auf „umgekehrt“.  4. „Speichern“.")
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size.x = 1060
	box.add_child(how)

	# --- Stickmode (Mode 1–4 nach heli-planet-Nomenklatur), Standard Mode 4 ---
	box.add_child(UITheme.make_label("Stickmode (gilt für Sender-Anzeige, Bildschirmknüppel und Tastatur)", "MutedLabel"))
	var modes := UITheme.make_hbox("xs")
	var grp := ButtonGroup.new()
	for m in [1, 2, 3, 4]:
		# dreizeilig („Mode 4“ / „links …“ / „rechts …“), damit das Fenster nicht breiter wird
		var b := UITheme.make_button(FlightController.stick_mode_text(m).replace(" · ", "\n"), true)
		b.button_group = grp
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _set_stick_mode(m))
		modes.add_child(b)
		_mode_btns[m] = b
	box.add_child(modes)

	# --- Mitte: Knüppelfelder links, Kanalliste rechts ------------------------
	var mid := UITheme.make_hbox("lg")
	box.add_child(mid)
	_left = StickField.new()
	_left.title = "Linker Knüppel"; _left.x_label = "Rolle"; _left.y_label = "Gas"
	_right = StickField.new()
	_right.title = "Rechter Knüppel"; _right.x_label = "Seite"; _right.y_label = "Höhe"
	mid.add_child(_left)
	mid.add_child(_right)

	var right_box := UITheme.make_vbox("xs")
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(right_box)
	right_box.add_child(UITheme.make_label("Kanal · Min / Mitte / Max · Status · Richtung (antippen)", "MutedLabel"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", UITheme.space("md"))
	grid.add_theme_constant_override("v_separation", 2)
	right_box.add_child(grid)
	for i in JoystickInput.CHANNELS:
		var name_l := UITheme.make_label("CH%d" % (i + 1))
		_names.append(name_l)
		name_l.custom_minimum_size.x = 150
		var val_l := UITheme.make_label("", "MutedLabel")
		val_l.custom_minimum_size.x = 150
		var st_l := UITheme.make_label("")
		st_l.custom_minimum_size.x = 130
		var inv := UITheme.make_button("normal", true)
		inv.custom_minimum_size = Vector2(130, 40)
		var ch := i
		inv.toggled.connect(func(on: bool):
			_work[ch].inv = on
			inv.text = "umgekehrt" if on else "normal")
		for c in [name_l, val_l, st_l, inv]: grid.add_child(c)
		_rows.append({"values": val_l, "status": st_l, "inv": inv})
	_switches = UITheme.make_label("")
	right_box.add_child(_switches)

	# --- Kanalzuordnung: Funktion → Kanal, mit Anlernen ---------------------------
	box.add_child(UITheme.make_label("Kanalzuordnung (gilt auch für den Teensy-Export): Kanal wählen oder „Anlernen“ drücken und den Knüppel/Schalter bewegen", "MutedLabel"))
	var mgrid := GridContainer.new()
	mgrid.columns = 6
	mgrid.add_theme_constant_override("h_separation", UITheme.space("sm"))
	mgrid.add_theme_constant_override("v_separation", 2)
	box.add_child(mgrid)
	for fn in JoystickInput.FUNCS:
		var l := UITheme.make_label(JoystickInput.FUNC_NAMES[fn])
		l.custom_minimum_size.x = 230
		var ob := OptionButton.new()
		for c in JoystickInput.CHANNELS:
			ob.add_item("CH%d" % (c + 1), c + 1)
		var f: String = fn
		ob.item_selected.connect(func(idx: int): _wmap[f] = idx + 1)
		var lb := UITheme.make_button("Anlernen")
		lb.pressed.connect(func(): _start_learn(f))
		_map_opts[fn] = ob
		_learn_btns[fn] = lb
		for c in [l, ob, lb]: mgrid.add_child(c)

	# --- Legende und Knöpfe -----------------------------------------------------
	box.add_child(UITheme.make_label("Knüppelfelder: blau = erfasster Bereich · weißes Kreuz = Mitte · gelber Punkt = jetzige Stellung (mit Umkehr)", "MutedLabel"))
	var btns := UITheme.make_hbox("sm")
	btns.alignment = BoxContainer.ALIGNMENT_END
	var b_def := UITheme.make_button("Werkseinstellung")
	b_def.pressed.connect(_on_defaults)
	var b_cancel := UITheme.make_button("Abbrechen")
	b_cancel.pressed.connect(func(): hide_panel())
	var b_mid := UITheme.make_button("Mitte übernehmen")
	b_mid.pressed.connect(_on_center)
	var b_save := UITheme.make_button("Speichern")
	b_save.pressed.connect(_on_save)
	for b in [b_def, b_cancel, b_mid, b_save]: btns.add_child(b)
	box.add_child(btns)

	resized.connect(_layout)
	visible = false


## Fenster öffnen: Arbeitskopie anlegen, Erfassung neu beginnen.
func show_panel() -> void:
	_work = joy.cal.duplicate(true)
	_wmap = JoystickInput.fmap.duplicate()
	_learn = ""
	_no_focus(self)
	_sync_stick_mode()
	for fn in _map_opts:
		_map_opts[fn].select(int(_wmap[fn]) - 1)
		_learn_btns[fn].text = "Anlernen"
	_cap = []
	for i in JoystickInput.CHANNELS:
		var r := joy.raw(i)
		_cap.append({"min": r, "max": r})
		_rows[i].inv.set_pressed_no_signal(bool(_work[i].inv))
		_rows[i].inv.text = "umgekehrt" if _work[i].inv else "normal"
	joy.calibrating = true                       # Schalter lösen nichts aus
	visible = true
	_layout.call_deferred()


func hide_panel() -> void:
	if not visible:
		return
	visible = false
	joy.calibrating = false
	closed.emit()


## Liegt auf Kanal i (0-basiert) ein Knüppel? (nach der Arbeits-Zuordnung)
func _is_stick(i: int) -> bool:
	for fn in STICKS:
		if int(_wmap.get(fn, 0)) - 1 == i:
			return true
	return false


## Anlernen: Rohwerte merken; der erste Kanal, der sich deutlich bewegt, wird zugeordnet.
func _start_learn(fn: String) -> void:
	_learn = fn
	_learn_base = []
	for i in JoystickInput.CHANNELS:
		_learn_base.append(joy.raw(i))
	for f in _learn_btns:
		_learn_btns[f].text = "bewegen …" if f == fn else "Anlernen"


## Ist ein Kanal weit genug bewegt worden?
func _captured(i: int) -> bool:
	if _is_stick(i):
		var mid: float = _work[i].center
		return _cap[i].max - mid >= STICK_SIDE_OK and mid - _cap[i].min >= STICK_SIDE_OK
	return _cap[i].max - _cap[i].min >= SWITCH_RANGE_OK


## Kalibriersatz eines Kanals für Anzeige und Speichern: erfasster Bereich,
## sonst die bisherigen Anschläge; Schalter: Mitte zwischen den Anschlägen.
func _effective(i: int) -> Dictionary:
	var c: Dictionary = _work[i].duplicate()
	if _captured(i):
		c.min = _cap[i].min
		c.max = _cap[i].max
		if not _is_stick(i):
			c.center = (c.min + c.max) * 0.5
	c.center = clampf(c.center, c.min + 0.05, c.max - 0.05)   # Mitte muss innerhalb liegen
	return c


func _process(_dt: float) -> void:
	if not visible or joy == null:
		return
	var on := joy.active()
	_dev.text = (I18n.t("● %s · Motoren aus") % Input.get_joy_name(joy.device)) if on else "Kein Sender angeschlossen"
	# Anlernen: erster Kanal mit deutlicher Bewegung (> 60 %) gehört zur Funktion
	if _learn != "":
		for i in JoystickInput.CHANNELS:
			if absf(joy.raw(i) - _learn_base[i]) > 0.6:
				_wmap[_learn] = i + 1
				_map_opts[_learn].select(i)
				_learn_btns[_learn].text = "Anlernen"
				_learn = ""
				break
	# Kanalnamen nach der Zuordnung
	for i in JoystickInput.CHANNELS:
		var nm := []
		for fn in JoystickInput.FUNCS:
			if int(_wmap.get(fn, 0)) - 1 == i: nm.append(SHORT[fn])
		var t := I18n.t("CH%d %s") % [i + 1, " + ".join(nm) if not nm.is_empty() else "frei"]
		if _names[i].text != t: _names[i].text = t
	# Erfassung: jeder Rohwert erweitert den Bereich seines Kanals
	for i in JoystickInput.CHANNELS:
		var r := joy.raw(i)
		_cap[i].min = minf(_cap[i].min, r)
		_cap[i].max = maxf(_cap[i].max, r)
		var c := _effective(i)
		var ok := _captured(i)
		_rows[i].values.text = "%d / %s / %d %%" % [roundi(c.min * 100.0),
			("%d" % roundi(c.center * 100.0)) if _is_stick(i) else "–", roundi(c.max * 100.0)]
		_rows[i].status.text = "✓" if ok else "noch bewegen"
		_rows[i].status.modulate = UITheme.color("success") if ok else UITheme.color("warning")
	# Knüppelfelder (Rohwerte; bei Umkehr gespiegelt, damit man die Richtung sieht)
	var lay: Array = _stick_layout()
	_fill_field(_left, _wax(lay[0]), _wax(lay[1]))
	_fill_field(_right, _wax(lay[2]), _wax(lay[3]))
	# Schalterstellungen im Klartext (mit der Arbeitskopie umgerechnet)
	var sf := JoystickInput.apply_cal(joy.raw(_wax("arm")), _effective(_wax("arm")))
	var sc := JoystickInput.apply_cal(joy.raw(_wax("mode")), _effective(_wax("mode")))
	var sh := JoystickInput.apply_cal(joy.raw(_wax("reset")), _effective(_wax("reset")))
	_switches.text = I18n.t("SF: %s     SC: %s     SH: %s") % [
		"oben · scharf" if sf < -0.5 else "unten · aus",
		"oben · Direkt" if sc < -0.5 else ("unten · Mode 3" if sc > 0.5 else "Mitte · Mode 2"),
		"oben" if sh < -0.5 else "unten"]


## Ein Knüppelfeld mit Bereich, Mitte und jetziger Stellung füllen.
func _fill_field(f: StickField, cx: int, cy: int) -> void:
	var ex := _effective(cx)
	var ey := _effective(cy)
	var sx := -1.0 if _work[cx].inv else 1.0
	var sy := -1.0 if _work[cy].inv else 1.0
	f.range_x = Vector2(minf(_cap[cx].min * sx, _cap[cx].max * sx), maxf(_cap[cx].min * sx, _cap[cx].max * sx))
	f.range_y = Vector2(minf(_cap[cy].min * sy, _cap[cy].max * sy), maxf(_cap[cy].min * sy, _cap[cy].max * sy))
	f.center = Vector2(ex.center * sx, ey.center * sy)
	f.cur = Vector2(joy.raw(cx) * sx, joy.raw(cy) * sy)
	f.queue_redraw()


## Achse (0-basiert) einer Funktion nach der Arbeits-Zuordnung
func _wax(fn: String) -> int:
	return int(_wmap.get(fn, JoystickInput.DEFAULT_MAP[fn])) - 1


## „Mitte übernehmen“: jetzige Stellung der Knüppel-Kanäle als Mitte merken.
func _on_center() -> void:
	for i in JoystickInput.CHANNELS:
		if _is_stick(i):
			_work[i].center = joy.raw(i)


## „Werkseinstellung“: −1 / 0 / +1, nichts umgekehrt; Erfassung neu beginnen.
func _on_defaults() -> void:
	_work = JoystickInput.default_cal()
	for i in JoystickInput.CHANNELS:
		var r := joy.raw(i)
		_cap[i] = {"min": r, "max": r}
		_rows[i].inv.set_pressed_no_signal(false)
		_rows[i].inv.text = "normal"


## „Speichern“: Arbeitskopie (mit erfassten Bereichen) übernehmen und sichern.
func _on_save() -> void:
	for i in JoystickInput.CHANNELS:
		joy.cal[i] = _effective(i)
	JoystickInput.fmap = _wmap.duplicate()
	joy.save_cal()
	hide_panel()


func _layout() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	# Passt das Fenster nicht auf den Bildschirm (Handy), wird es verkleinert
	var k := minf(1.0, minf((size.x - 16.0) / _panel.size.x, (size.y - 16.0) / _panel.size.y))
	_panel.scale = Vector2(k, k)
	_panel.position = (size - _panel.size * k) * 0.5


# =============================================================================
# StickField – ein Knüppelweg als Quadrat (−1…+1 in beiden Richtungen)
# =============================================================================
## Kein Knopf in diesem Fenster darf den Tastatur-/Joypad-Fokus bekommen:
## Godot steuert die Oberfläche sonst auch mit dem Sender (Knüppel = Pfeile,
## Schalter = „Bestätigen“) – beim Durchschalten aller Schalter wurde so z. B.
## „Mode 1“ gedrückt.
func _no_focus(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).focus_mode = Control.FOCUS_NONE
		_no_focus(c)


## aktuelle Knüppelbelegung [links x, links y, rechts x, rechts y]
func _stick_layout() -> Array:
	var m := fc.stick_mode if fc else FlightController.STICK_MODE_DEFAULT
	return FlightController.STICK_LAYOUT.get(m, FlightController.STICK_LAYOUT[FlightController.STICK_MODE_DEFAULT])


func _set_stick_mode(m: int) -> void:
	if fc:
		fc.stick_mode = m
		fc.save_settings()
		fc.stick_mode_changed.emit()
	_sync_stick_mode()


## Knöpfe und Beschriftung der Knüppelfelder nach dem Stickmode
func _sync_stick_mode() -> void:
	var m := fc.stick_mode if fc else FlightController.STICK_MODE_DEFAULT
	for k in _mode_btns:
		_mode_btns[k].set_pressed_no_signal(k == m)
	var lay := _stick_layout()
	var names := FlightController.FN_NAMES
	_left.x_label = names[lay[0]]; _left.y_label = names[lay[1]]
	_right.x_label = names[lay[2]]; _right.y_label = names[lay[3]]
	_left.queue_redraw(); _right.queue_redraw()


class StickField extends Control:
	var title := ""
	var x_label := ""
	var y_label := ""
	var range_x := Vector2.ZERO          ## erfasster Bereich (min, max)
	var range_y := Vector2.ZERO
	var center := Vector2.ZERO
	var cur := Vector2.ZERO
	const S := 200.0                     ## Kantenlänge des Feldes (px)
	const TOP := 34.0                    ## Platz für den Titel
	const SIDE := 26.0                   ## Platz links für die Hochachsen-Beschriftung

	func _init() -> void:
		custom_minimum_size = Vector2(S + SIDE, S + TOP + 28.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Wert (−1…+1) → Bildpunkt im Feld (y nach oben positiv)
	func _pt(v: Vector2) -> Vector2:
		return Vector2(SIDE + (clampf(v.x, -1, 1) + 1.0) * 0.5 * S, TOP + (1.0 - (clampf(v.y, -1, 1) + 1.0) * 0.5) * S)

	func _draw() -> void:
		var font := get_theme_default_font()
		var fs := UITheme.font_size("body")
		var cs := UITheme.font_size("caption")
		var muted := UITheme.color("text_muted")
		draw_string(font, Vector2(SIDE, 22), I18n.t(title), HORIZONTAL_ALIGNMENT_CENTER, S, fs, UITheme.color("text"))
		# Hintergrund und Achsen
		draw_rect(Rect2(SIDE, TOP, S, S), UITheme.color("surface_alt"))
		draw_line(Vector2(SIDE + S * 0.5, TOP), Vector2(SIDE + S * 0.5, TOP + S), Color(1, 1, 1, 0.15))
		draw_line(Vector2(SIDE, TOP + S * 0.5), Vector2(SIDE + S, TOP + S * 0.5), Color(1, 1, 1, 0.15))
		# Erfasster Bereich (blau)
		var a := _pt(Vector2(range_x.x, range_y.y))
		var b := _pt(Vector2(range_x.y, range_y.x))
		var acc := UITheme.color("accent")
		draw_rect(Rect2(a, b - a), Color(acc.r, acc.g, acc.b, 0.35))
		# Mitte (weißes Kreuz)
		var c := _pt(center)
		draw_line(c - Vector2(8, 0), c + Vector2(8, 0), Color.WHITE, 2.0)
		draw_line(c - Vector2(0, 8), c + Vector2(0, 8), Color.WHITE, 2.0)
		# Jetzige Stellung (gelber Punkt)
		draw_circle(_pt(cur), 8.0, Color("ffd166"))
		# Beschriftung der Achsen
		draw_string(font, Vector2(SIDE, TOP + S + 22), I18n.t(x_label), HORIZONTAL_ALIGNMENT_CENTER, S, cs, muted)
		draw_set_transform(Vector2(18, TOP + S * 0.5), -PI * 0.5)
		draw_string(font, Vector2(-S * 0.5, 0), I18n.t(y_label), HORIZONTAL_ALIGNMENT_CENTER, S, cs, muted)
		draw_set_transform(Vector2.ZERO)
