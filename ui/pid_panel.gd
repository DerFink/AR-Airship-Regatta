# 2026-10-29 01:13 – Einstellungen Nick-Schutz (aktiv, Ruhe ±, Max ±, Schutz-Stärke) statt Test-Anschlag
# 2026-10-28 08:51 – Schalter „Nick begrenzen“ mit Grenzwert (Test)
# 2026-10-28 07:53 – Regler Leitwerk-Stärke und Motorschwenk-Stärke statt Mischungsauswahl
# 2026-10-28 00:15 – Mode 4 Luftschiff im Modus-Menü
# 2026-10-27 15:10 – Wertanzeige über row.get_meta("out") (Regler haben jetzt −/+-Knöpfe)
# 2026-10-27 12:22 – Fix: Vollbild-Anker mit set_anchors_and_offsets_preset (vorher blieb die Fläche 0 px groß → Knüppel und Menüs landeten oben links)
# 2026-10-27 10:42 – Regler und Modus-Knöpfe werden beim Öffnen und bei jedem Moduswechsel mit dem Flugcontroller abgeglichen (vorher nur beim Start)
# 2026-10-27 10:42 – Erstversion: PID-Submenü nach freigegebenem Entwurf (links Modus-Wahl wie 3-Stufen-Schalter, Mitte Achse + Regler aus FlightController.UI_PARAMS + Mischung, rechts Live-Sprungantwort)
# =============================================================================
# PIDPanel.gd
# -----------------------------------------------------------------------------
#   ┌ Flugcontroller ┐ ┌ [Roll][Nick][Gier]       ┐ ┌ Sprungantwort ┐
#   │ Mode 1 direkt  │ │ P ───●──── 0,90          │ │  ╱‾‾╲__        │
#   │ Mode 2 geregelt│ │ I ─●────── 0,10          │ │ ─────────      │
#   │ Mode 3 o. Vekt.│ │ D ──●───── 0,30          │ │                │
#   │ Stick-Mode 1/2 │ │ Mischung / Ausschlag     │ │      [Fertig]  │
#   └────────────────┘ └──────────────────────────┘ └────────────────┘
# Die Regler werden aus FlightController.UI_PARAMS erzeugt – kommt dort ein
# Parameter dazu, erscheint er hier automatisch.
# =============================================================================
class_name PIDPanel
extends Control

signal closed

var fc: FlightController
var _axis := FlightController.Axis.PITCH
var _gain_box: VBoxContainer
var _strength_box: VBoxContainer   ## Regler Leitwerk-/Schwenk-Stärke
var _plot: StepPlot
var _mode_buttons: Array[Button] = []


func setup(controller: FlightController) -> void:
	fc = controller


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UITheme.space("lg")
	var bg := ColorRect.new()                       # abgedunkelter Hintergrund
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var row := UITheme.make_hbox("md")
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, m)

	# ===================== links: Modus =====================================
	var left := UITheme.make_panel(220)
	row.add_child(left)
	var lcol := UITheme.make_vbox("sm")
	left.add_child(lcol)
	lcol.add_child(UITheme.make_title("Flugcontroller"))
	var g := UITheme.make_toggle_group()
	var names := ["Mode 1 direkt", "Mode 2 geregelt", "Mode 3 ohne Vektor", "Mode 4 Luftschiff"]
	for i in names.size():
		var b := UITheme.make_button(names[i], true)
		b.button_group = g
		b.button_pressed = int(fc.mode) == i
		b.pressed.connect(func(): fc.mode = i)        # Regler baut _on_mode_changed neu
		lcol.add_child(b)
		_mode_buttons.append(b)
	lcol.add_child(UITheme.make_label("Stick-Belegung", "MutedLabel"))
	var sm := OptionButton.new()
	sm.custom_minimum_size.y = UITheme.size("control_height")
	sm.add_item("Mode 2: links Gas")
	sm.add_item("Mode 1: links Nick")
	sm.select(0 if fc.stick_mode == 2 else 1)
	sm.item_selected.connect(func(k): fc.stick_mode = 2 if k == 0 else 1; fc.save_settings())
	lcol.add_child(sm)
	lcol.add_child(UITheme.make_label("Gier liegt immer rechts.", "MutedLabel"))

	# Nick-Schutz (nur Geregelt/Luftschiff, nie Direkt)
	lcol.add_child(UITheme.make_label("Nick-Schutz", "MutedLabel"))
	var prot := CheckBox.new()
	prot.text = "aktiv"
	prot.button_pressed = fc.pitch_protect_on
	prot.toggled.connect(func(on): fc.pitch_protect_on = on; fc.save_settings())
	lcol.add_child(prot)
	lcol.add_child(UITheme.make_slider_row("Ruhe ±", 1.0, 20.0, 1.0, fc.pitch_rest_deg,
		func(v): fc.pitch_rest_deg = v; fc.save_settings(), "%d°", 80))
	lcol.add_child(UITheme.make_slider_row("Max ±", 10.0, 60.0, 1.0, fc.pitch_max_deg,
		func(v): fc.pitch_max_deg = v; fc.save_settings(), "%d°", 80))
	lcol.add_child(UITheme.make_slider_row("Schutz", 0.0, 30.0, 0.5, fc.protect_gain,
		func(v): fc.protect_gain = v; fc.save_settings(), "%.1f", 80))

	# ===================== Mitte: Achse + Regler ============================
	var mid := UITheme.make_panel()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 2.0
	row.add_child(mid)
	var mcol := UITheme.make_vbox("sm")
	mid.add_child(mcol)
	var axes := UITheme.make_hbox("xs")
	mcol.add_child(axes)
	var ag := UITheme.make_toggle_group()
	var axis_defs := [["Roll", FlightController.Axis.ROLL], ["Nick", FlightController.Axis.PITCH],
		["Gier", FlightController.Axis.YAW]]
	for a in axis_defs:
		var b := UITheme.make_button(a[0], true)
		b.button_group = ag
		b.button_pressed = a[1] == _axis
		b.pressed.connect(func(): _axis = a[1]; _build_gains(); _plot.clear())
		axes.add_child(b)
	_gain_box = UITheme.make_vbox("xs")
	mcol.add_child(_gain_box)

	# Stärke von Leitwerk und Schwenkmotoren – getrennt, unabhängig von der Fahrt
	mcol.add_child(UITheme.make_label("Mischer-Stärke (gilt für alle Achsen)", "MutedLabel"))
	_strength_box = UITheme.make_vbox("xs")
	mcol.add_child(_strength_box)
	_build_strength()

	# ===================== rechts: Sprungantwort ============================
	var right := UITheme.make_panel(260)
	row.add_child(right)
	var rcol := UITheme.make_vbox("sm")
	right.add_child(rcol)
	rcol.add_child(UITheme.make_title("Sprungantwort"))
	_plot = StepPlot.new()
	_plot.custom_minimum_size = Vector2(230, 150)
	_plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(_plot)
	rcol.add_child(UITheme.make_label("grau: Soll · blau: Ist", "MutedLabel"))
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	rcol.add_child(done)

	fc.loop_sample.connect(_on_sample)
	fc.mode_changed.connect(_on_mode_changed)
	visibility_changed.connect(_sync)
	_build_gains()


## Beim Öffnen und bei Moduswechsel von außen (z. B. später ein Schalter
## in der Flugansicht) Anzeige mit dem Flugcontroller abgleichen.
func _sync() -> void:
	if not visible:
		return
	for i in _mode_buttons.size():
		_mode_buttons[i].set_pressed_no_signal(int(fc.mode) == i)
	_build_gains()
	_build_strength()
	_plot.clear()


func _on_mode_changed(_m: int) -> void:
	_sync()


## Prozentanzeige für den Ausschlag-Regler (Wert 0..1 → 0..100 %).
func _fix_percent(row: Control) -> void:
	var s: HSlider = row.get_meta("slider")
	var out: Label = row.get_meta("out")
	var upd := func(v: float): out.text = "%d %%" % roundi(v * 100.0)
	s.value_changed.connect(upd)
	upd.call(s.value)


## Regler für die Stärke von Leitwerk und Schwenkmotoren (0–100 %) neu aufbauen
## (z. B. nachdem ein Modell eigene Vorgaben mitgebracht hat).
func _build_strength() -> void:
	for c in _strength_box.get_children(): c.queue_free()
	_strength_box.add_child(UITheme.make_slider_row("Leitwerk", 0.0, 1.0, 0.05, fc.tail_gain,
		func(v): fc.tail_gain = v; fc.save_settings(), "%.2f", 120))
	_fix_percent(_strength_box.get_child(_strength_box.get_child_count() - 1))
	_strength_box.add_child(UITheme.make_slider_row("Motorschwenk", 0.0, 1.0, 0.05, fc.vec_gain,
		func(v): fc.vec_gain = v; fc.save_settings(), "%.2f", 120))
	_fix_percent(_strength_box.get_child(_strength_box.get_child_count() - 1))


# Regler für die gewählte Achse im aktuellen Modus neu aufbauen
func _build_gains() -> void:
	for c in _gain_box.get_children(): c.queue_free()
	if fc.mode == FlightController.Mode.DIRECT:
		_gain_box.add_child(UITheme.make_label("Mode 1: Knüppel wirken direkt, kein Regler aktiv.", "MutedLabel"))
		return
	var mode := fc.mode
	var axis := _axis
	for p in FlightController.UI_PARAMS:
		var term: String = p.term
		_gain_box.add_child(UITheme.make_slider_row(p.label, p.min, p.max, p.step,
			fc.get_param(mode, axis, term),
			func(v): fc.set_param(mode, axis, term, v), "%.2f", 90))


func _on_sample(axis: int, setpoint: float, measurement: float) -> void:
	if visible and axis == _axis:
		_plot.push(setpoint, measurement)


# =============================================================================
# Kleiner Live-Plot (Soll/Ist der letzten ~4 s)
# =============================================================================
class StepPlot:
	extends Control
	const N := 240
	var _sp: PackedFloat32Array = PackedFloat32Array()
	var _pv: PackedFloat32Array = PackedFloat32Array()

	func clear() -> void:
		_sp.clear(); _pv.clear(); queue_redraw()

	func push(sp: float, pv: float) -> void:
		_sp.append(sp); _pv.append(pv)
		if _sp.size() > N:
			_sp.remove_at(0); _pv.remove_at(0)
		queue_redraw()

	func _draw() -> void:
		draw_style_box(UITheme.box(UITheme.color("surface_alt"), UITheme.color("border"), UITheme.radius("md"), 0), Rect2(Vector2.ZERO, size))
		var mid := size.y * 0.5
		draw_line(Vector2(0, mid), Vector2(size.x, mid), UITheme.color("border_strong"), 1.0)
		if _sp.size() < 2:
			return
		var span := 0.2                               # ± Skala (rad), wächst mit
		for i in _sp.size(): span = maxf(span, maxf(absf(_sp[i]), absf(_pv[i])) * 1.2)
		var pts_sp := PackedVector2Array()
		var pts_pv := PackedVector2Array()
		for i in _sp.size():
			var x := size.x * i / float(N - 1)
			pts_sp.append(Vector2(x, mid - _sp[i] / span * mid))
			pts_pv.append(Vector2(x, mid - _pv[i] / span * mid))
		draw_polyline(pts_sp, UITheme.color("plot_setpoint"), 1.5, true)
		draw_polyline(pts_pv, UITheme.color("plot_measure"), 2.0, true)
