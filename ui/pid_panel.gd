# 2026-10-29 03:38 – Knopf „Alle Einstellungen zurücksetzen“ mit Rückfrage; linke Spalte wird beim Öffnen neu aufgebaut
# 2026-10-29 02:25 – Regler „Motorschwenk Gier“ getrennt von Nick/Roll
# 2026-10-29 01:44 – Für den Kaskadenregler neu aufgebaut: Modi Direkt/Geregelt/Luftschiff, Werte je Achse aus FlightController.UI_PARAMS (Winkel P, Rate P/I/D, max. Rate, Vorsteuerung, Rolldämpfung), Nick-Sollwert, Mischer (Leitwerk, Motorschwenk, Schwenk fürs Nicken, Gas-Anpassung); Spalten scrollbar
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
#   ┌ Flugcontroller ┐ ┌ [Nick][Roll][Gier]          ┐ ┌ Sprungantwort ┐
#   │ Direkt         │ │ Winkel P ──●──────  3,0      │ │  ╱‾‾╲__        │
#   │ Geregelt       │ │ Rate P   ─●───────  1,5      │ │ ─────────      │
#   │ Luftschiff     │ │ Rate I / D / max. °/s …      │ │                │
#   │ Stick-Mode     │ │ Mischer: Leitwerk, Schwenk,  │ │      [Fertig]  │
#   │ Nick-Sollwert  │ │ Schwenk fürs Nicken, Gas-Anp.│ │                │
#   └────────────────┘ └──────────────────────────────┘ └────────────────┘
# Die Regler je Achse kommen aus FlightController.UI_PARAMS – kommt dort ein
# Parameter dazu, erscheint er hier automatisch. Alle Werte gelten für
# Geregelt und Luftschiff gemeinsam und werden sofort gespeichert.
# =============================================================================
class_name PIDPanel
extends Control

signal closed
## „Alles zurücksetzen“ bestätigt → main.gd setzt Flugcontroller, Strecke und Schiff zurück
signal reset_all_requested

var fc: FlightController
var _axis := FlightController.Axis.PITCH
var _gain_box: VBoxContainer       ## Regler der gewählten Achse
var _left_box: VBoxContainer       ## Modus, Stick-Mode, Nick-Sollwert
var _mix_box: VBoxContainer        ## Mischer-Einstellungen
var _plot: StepPlot
var _mode_buttons: Array[Button] = []


func setup(controller: FlightController) -> void:
	fc = controller


## Scrollbare Spalte in einem Panel (am Handy ist die Höhe knapp).
func _scroll_col(panel: PanelContainer) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var col := UITheme.make_vbox("sm")
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	return col


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

	# ===================== links: Modus, Stick, Nick-Sollwert ================
	var left := UITheme.make_panel(260)
	row.add_child(left)
	_left_box = _scroll_col(left)
	_fill_left()

	# ===================== Mitte: Achse + Regler + Mischer ===================
	var mid := UITheme.make_panel()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 2.0
	row.add_child(mid)
	var mcol := _scroll_col(mid)
	var axes := UITheme.make_hbox("xs")
	mcol.add_child(axes)
	var ag := UITheme.make_toggle_group()
	var axis_defs := [["Nick", FlightController.Axis.PITCH], ["Roll", FlightController.Axis.ROLL],
		["Gier", FlightController.Axis.YAW]]
	for a in axis_defs:
		var b := UITheme.make_button(a[0], true)
		b.button_group = ag
		b.button_pressed = a[1] == _axis
		b.pressed.connect(func(): _axis = a[1]; _build_gains(); _plot.clear())
		axes.add_child(b)
	_gain_box = UITheme.make_vbox("xs")
	mcol.add_child(_gain_box)
	mcol.add_child(UITheme.make_title("Mischer"))
	_mix_box = UITheme.make_vbox("xs")
	mcol.add_child(_mix_box)

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
	fc.mode_changed.connect(func(_m): _sync())
	visibility_changed.connect(_sync)
	_build_gains()
	_build_mix()


## Beim Öffnen und bei Moduswechsel/Modellwechsel: alles neu anzeigen.
func _sync() -> void:
	if not visible:
		return
	for c in _left_box.get_children(): c.queue_free()
	_mode_buttons.clear()
	_fill_left()
	for i in _mode_buttons.size():
		_mode_buttons[i].set_pressed_no_signal(int(fc.mode) == i)
	_build_gains()
	_build_mix()
	_plot.clear()


## Linke Spalte: Modus, Stick-Belegung, Nick-Sollwert.
func _fill_left() -> void:
	_left_box.add_child(UITheme.make_title("Flugcontroller"))
	var g := UITheme.make_toggle_group()
	for i in FlightController.MODE_NAMES.size():
		var b := UITheme.make_button(FlightController.MODE_NAMES[i], true)
		b.button_group = g
		b.button_pressed = int(fc.mode) == i
		b.pressed.connect(func(): fc.mode = i)
		_left_box.add_child(b)
		_mode_buttons.append(b)
	_left_box.add_child(UITheme.make_label("Luftschiff = Roll frei (nur gedämpft)", "MutedLabel"))
	_left_box.add_child(UITheme.make_label("Stick-Belegung", "MutedLabel"))
	var sm := OptionButton.new()
	sm.custom_minimum_size.y = UITheme.size("control_height")
	sm.add_item("Mode 2: links Gas")
	sm.add_item("Mode 1: links Nick")
	sm.select(0 if fc.stick_mode == 2 else 1)
	sm.item_selected.connect(func(k): fc.stick_mode = 2 if k == 0 else 1; fc.save_settings())
	_left_box.add_child(sm)
	_left_box.add_child(UITheme.make_title("Nick-Sollwert"))
	var prot := CheckBox.new()
	prot.text = "Ruheband aktiv"
	prot.button_pressed = fc.pitch_protect_on
	prot.toggled.connect(func(on): fc.pitch_protect_on = on; fc.save_settings())
	_left_box.add_child(prot)
	_left_box.add_child(UITheme.make_slider_row("Ruhe ±", 1.0, 20.0, 1.0, fc.pitch_rest_deg,
		func(v): fc.pitch_rest_deg = v; fc.save_settings(), "%d°", 80))
	_left_box.add_child(UITheme.make_slider_row("Max ±", 10.0, 60.0, 1.0, fc.pitch_max_deg,
		func(v): fc.pitch_max_deg = v; fc.save_settings(), "%d°", 80))
	_left_box.add_child(UITheme.make_slider_row("Rückzug außerhalb", 0.0, 20.0, 0.5, fc.protect_gain,
		func(v): fc.protect_gain = v; fc.save_settings(), "%.1f", 80))

	# Alles auf Werkseinstellung – mit Rückfrage (zweites Tippen bestätigt)
	_left_box.add_child(UITheme.make_title("Zurücksetzen"))
	var rst := UITheme.make_button("Alle Einstellungen zurücksetzen")
	rst.pressed.connect(func():
		if rst.has_meta("armed"):
			rst.remove_meta("armed")
			rst.text = "Alle Einstellungen zurücksetzen"
			reset_all_requested.emit()
		else:
			rst.set_meta("armed", true)
			rst.text = "Wirklich? Nochmal tippen")
	_left_box.add_child(rst)
	var rinfo := UITheme.make_label("Regler, Mischer, Nick-Sollwert, Stick-Mode und Strecke. Bestenliste und eigene Modelle bleiben.", "MutedLabel")
	rinfo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_left_box.add_child(rinfo)


## Prozentanzeige für einen Regler (Wert 0..1 → 0..100 %).
func _fix_percent(row: Control) -> void:
	var s: HSlider = row.get_meta("slider")
	var out: Label = row.get_meta("out")
	var upd := func(v: float): out.text = "%d %%" % roundi(v * 100.0)
	s.value_changed.connect(upd)
	upd.call(s.value)


## Mischer-Einstellungen (gelten für alle Achsen).
func _build_mix() -> void:
	for c in _mix_box.get_children(): c.queue_free()
	_mix_box.add_child(UITheme.make_slider_row("Leitwerk", 0.0, 1.0, 0.05, fc.tail_gain,
		func(v): fc.tail_gain = v; fc.save_settings(), "%.2f", 120))
	_fix_percent(_mix_box.get_child(_mix_box.get_child_count() - 1))
	_mix_box.add_child(UITheme.make_slider_row("Motorschwenk Nick/Roll", 0.0, 1.0, 0.05, fc.vec_gain,
		func(v): fc.vec_gain = v; fc.save_settings(), "%.2f", 120))
	_fix_percent(_mix_box.get_child(_mix_box.get_child_count() - 1))
	_mix_box.add_child(UITheme.make_slider_row("Motorschwenk Gier", 0.0, 1.0, 0.05, fc.vec_yaw_gain,
		func(v): fc.vec_yaw_gain = v; fc.save_settings(), "%.2f", 120))
	_fix_percent(_mix_box.get_child(_mix_box.get_child_count() - 1))
	_mix_box.add_child(UITheme.make_slider_row("Schwenk fürs Nicken max", 0.0, 120.0, 1.0, fc.swivel_pitch_max_deg,
		func(v): fc.swivel_pitch_max_deg = v; fc.save_settings(), "%d°", 120))
	var ts := CheckBox.new()
	ts.text = "Gas-Anpassung (mehr Gas → kleinere Ausschläge)"
	ts.button_pressed = fc.throttle_scaling
	ts.toggled.connect(func(on): fc.throttle_scaling = on; fc.save_settings())
	_mix_box.add_child(ts)


# Regler für die gewählte Achse neu aufbauen
func _build_gains() -> void:
	for c in _gain_box.get_children(): c.queue_free()
	if fc.mode == FlightController.Mode.DIRECT:
		_gain_box.add_child(UITheme.make_label("Direkt: Knüppel wirken ungeregelt (Werte gelten für Geregelt/Luftschiff).", "MutedLabel"))
	var axis := _axis
	for p in FlightController.UI_PARAMS[axis]:
		var term: String = p.term
		var fmt := "%d" if p.step >= 1.0 else "%.2f"
		_gain_box.add_child(UITheme.make_slider_row(p.label, p.min, p.max, p.step,
			fc.get_param(axis, term),
			func(v): fc.set_param(axis, term, v), fmt, 120))


func _on_sample(axis: int, setpoint: float, measurement: float) -> void:
	if visible and axis == _axis:
		_plot.push(setpoint, measurement)


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
