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
## Kanalnamen (Index = Kanal − 1) und ob es ein Knüppel ist
const NAMES := ["Seite", "Höhe", "Gas", "Rolle", "SF Scharf", "SC Modus", "SH Zurücks."]

var joy: JoystickInput

var _panel: PanelContainer
var _dev: Label
var _left: StickField
var _right: StickField
var _rows: Array = []                ## je Kanal {values: Label, status: Label, inv: Button}
var _switches: Label
var _work: Array = []                ## Arbeitskopie der Kalibrierung (wird erst beim Speichern übernommen)
var _cap: Array = []                 ## erfasster Rohbereich je Kanal {min, max}


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
	var how := UITheme.make_label("1. Beide Knüppel einmal ganz im Kreis an alle Anschläge, alle Schalter durchschalten.  "
		+ "2. Knüppel loslassen, Gas in die Mitte → „Mitte übernehmen“.  "
		+ "3. Läuft ein Punkt verkehrt herum: Kanal auf „umgekehrt“.  4. „Speichern“.")
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size.x = 1060
	box.add_child(how)

	# --- Mitte: Knüppelfelder links, Kanalliste rechts ------------------------
	var mid := UITheme.make_hbox("lg")
	box.add_child(mid)
	_left = StickField.new()
	_left.title = "Linker Knüppel"; _left.x_label = "CH4 Rolle"; _left.y_label = "CH3 Gas"
	_right = StickField.new()
	_right.title = "Rechter Knüppel"; _right.x_label = "CH1 Seite"; _right.y_label = "CH2 Höhe"
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
		var name_l := UITheme.make_label("CH%d %s" % [i + 1, NAMES[i]])
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


## Ist ein Kanal weit genug bewegt worden?
func _captured(i: int) -> bool:
	if i < 4:
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
		if i >= 4:
			c.center = (c.min + c.max) * 0.5
	c.center = clampf(c.center, c.min + 0.05, c.max - 0.05)   # Mitte muss innerhalb liegen
	return c


func _process(_dt: float) -> void:
	if not visible or joy == null:
		return
	var on := joy.active()
	_dev.text = ("● %s · Motoren aus" % Input.get_joy_name(joy.device)) if on else "Kein Sender angeschlossen"
	# Erfassung: jeder Rohwert erweitert den Bereich seines Kanals
	for i in JoystickInput.CHANNELS:
		var r := joy.raw(i)
		_cap[i].min = minf(_cap[i].min, r)
		_cap[i].max = maxf(_cap[i].max, r)
		var c := _effective(i)
		var ok := _captured(i)
		_rows[i].values.text = "%d / %s / %d %%" % [roundi(c.min * 100.0),
			("%d" % roundi(c.center * 100.0)) if i < 4 else "–", roundi(c.max * 100.0)]
		_rows[i].status.text = "✓" if ok else "noch bewegen"
		_rows[i].status.modulate = UITheme.color("success") if ok else UITheme.color("warning")
	# Knüppelfelder (Rohwerte; bei Umkehr gespiegelt, damit man die Richtung sieht)
	_fill_field(_left, JoystickInput.AXIS_ROLL, JoystickInput.AXIS_THROTTLE)
	_fill_field(_right, JoystickInput.AXIS_YAW, JoystickInput.AXIS_PITCH)
	# Schalterstellungen im Klartext (mit der Arbeitskopie umgerechnet)
	var sf := JoystickInput.apply_cal(joy.raw(JoystickInput.AXIS_ARM), _effective(JoystickInput.AXIS_ARM))
	var sc := JoystickInput.apply_cal(joy.raw(JoystickInput.AXIS_MODE), _effective(JoystickInput.AXIS_MODE))
	var sh := JoystickInput.apply_cal(joy.raw(JoystickInput.AXIS_RESET), _effective(JoystickInput.AXIS_RESET))
	_switches.text = "SF: %s     SC: %s     SH: %s" % [
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


## „Mitte übernehmen“: jetzige Knüppelstellung (CH1–CH4) als Mitte merken.
func _on_center() -> void:
	for i in 4:
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
		draw_string(font, Vector2(SIDE, 22), title, HORIZONTAL_ALIGNMENT_CENTER, S, fs, UITheme.color("text"))
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
		draw_string(font, Vector2(SIDE, TOP + S + 22), x_label, HORIZONTAL_ALIGNMENT_CENTER, S, cs, muted)
		draw_set_transform(Vector2(18, TOP + S * 0.5), -PI * 0.5)
		draw_string(font, Vector2(-S * 0.5, 0), y_label, HORIZONTAL_ALIGNMENT_CENTER, S, cs, muted)
		draw_set_transform(Vector2.ZERO)
