# 2026-11-13 01:20 – Neu aufgebaut nach freigegebenem Entwurf: links die Flugmodi (Anzahl 1–5 als Zahl, Name, Art Direkt / PID teilweise / PID alle Achsen bzw. Vorlage Angle/Horizon, Achsen mit Lage oder Drehrate, Rollausgleich je Modus), Mitte nur die Werte des gewählten Modus (Direkt: Mischtabelle), rechts Sprungantwort mit Auslöser, Zeitachse und Kennwerten; Knopf „Signalfluss“
# 2026-11-11 18:45 – Flugmodi heißen jetzt Direkt · Angle · Horizon (wie bei Drohnen; im Teensy weiter Mode 1/2/3)
# 2026-11-11 15:20 – Stickmode 1–4 (gleiche Einstellung wie beim Sender-Kalibrieren)
# 2026-11-07 23:00 – Mischer-Werte aus FlightController.MIX_PARAMS (Namen wie im Teensy-Code)
# 2026-10-27 10:42 – Erstversion: PID-Submenü nach freigegebenem Entwurf
# =============================================================================
# PIDPanel.gd  („Regler einstellen“)
# -----------------------------------------------------------------------------
#   ┌ Flugmodi ──────────────┐ ┌ Werte · Rennen ─────────────┐ ┌ Sprungantwort ───┐
#   │ Anzahl Modi [−][2][+]  │ │ PID:  Nick (Lage)           │ │ [Nick][Gier][Roll]│
#   │ [1 · Direkt]           │ │       Kp [ ] Ki [ ] Kd [ ]  │ │ Sprung [15] °     │
#   │ [2 · Rennen]           │ │       max [30] °            │ │ [▶ Sprung auslösen]│
#   │ Name [Rennen]          │ │ Direkt: Mischtabelle        │ │  ╱‾‾╲__  (Zeit s) │
#   │ Art: Direkt · PID …    │ │ Angle/Horizon: Teensy-Werte │ │ Anstieg · Über-   │
#   │ Achsen: geregelt, Lage │ │                             │ │ schwingen · …     │
#   │ [✓] Rollausgleich      │ │                             │ │ [Signalfluss]     │
#   │ Stick-Belegung …       │ │                             │ │ [Fertig]          │
#   └────────────────────────┘ └─────────────────────────────┘ └──────────────────┘
# Gewählt ist immer ein Modus – er ist zugleich der aktive Flugmodus, die Mitte
# zeigt nur seine Werte. Alles wird sofort gespeichert.
# =============================================================================
class_name PIDPanel
extends Control

signal closed
## „Alles zurücksetzen“ bestätigt → main.gd setzt Flugcontroller, Strecke und Schiff zurück
signal reset_all_requested

var fc: FlightController
var _axis := FlightController.Axis.PITCH      ## Achse der Teensy-Werte (Angle/Horizon)
var _step_axis := FlightController.Axis.PITCH ## Achse der Sprungantwort
var _step_amount := 15.0
var _left_box: VBoxContainer
var _mid_box: VBoxContainer
var _plot: StepPlot
var _metrics: Label
var _step_field: NumberField
var _flow_win: Control


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

	# ===================== links: Flugmodi ===================================
	var left := UITheme.make_panel(330)
	row.add_child(left)
	_left_box = _scroll_col(left)

	# ===================== Mitte: Werte des gewählten Modus ===================
	var mid := UITheme.make_panel()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 2.0
	row.add_child(mid)
	_mid_box = _scroll_col(mid)

	# ===================== rechts: Sprungantwort ============================
	var right := UITheme.make_panel(300)
	row.add_child(right)
	var rcol := _scroll_col(right)
	rcol.add_child(UITheme.make_title("Sprungantwort"))
	var axes := UITheme.make_hbox("xs")
	var ag := UITheme.make_toggle_group()
	for a in [["Nick", FlightController.Axis.PITCH], ["Gier", FlightController.Axis.YAW], ["Roll", FlightController.Axis.ROLL]]:
		var b := UITheme.make_button(a[0], true)
		b.button_group = ag
		b.button_pressed = a[1] == _step_axis
		var ax: int = a[1]
		b.pressed.connect(func():
			_step_axis = ax
			_step_amount = 30.0 if ax == FlightController.Axis.YAW else 15.0
			_step_field.set_format("%d °/s" if ax == FlightController.Axis.YAW else "%d °")
			_step_field.set_value_no_signal(_step_amount)
			_plot.clear())
		axes.add_child(b)
	rcol.add_child(axes)
	_step_field = UITheme.make_number_row("Sprung", 1.0, 180.0, 1.0, _step_amount, func(v): _step_amount = v, "%d °")
	rcol.add_child(_step_field)
	var trig := UITheme.make_primary_button("▶  " + tr("Sprung auslösen"))
	trig.pressed.connect(_on_trigger)
	rcol.add_child(trig)
	rcol.add_child(_note("Am besten im Flug auslösen – ohne Fahrt wirken die Ruder kaum. Der Sprung dauert 3 s."))
	_plot = StepPlot.new()
	_plot.custom_minimum_size = Vector2(260, 170)
	rcol.add_child(_plot)
	rcol.add_child(UITheme.make_label("grau: Soll · blau: Ist", "MutedLabel"))
	_metrics = UITheme.make_label("", "MutedLabel")
	_metrics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcol.add_child(_metrics)
	var flow := UITheme.make_button("Signalfluss")
	flow.pressed.connect(_show_flow)
	rcol.add_child(flow)
	var done := UITheme.make_primary_button(tr("Fertig"))
	done.pressed.connect(func(): closed.emit())
	rcol.add_child(done)

	fc.loop_sample.connect(_on_sample)
	fc.mode_index_changed.connect(func(_i): _sync())
	fc.modes_changed.connect(_sync)
	visibility_changed.connect(_sync)
	_sync()


## Beim Öffnen und bei Moduswechsel: alles neu anzeigen.
func _sync() -> void:
	if not visible or _left_box == null:
		return
	_clear(_left_box)
	_fill_left()
	_clear(_mid_box)
	_fill_mid()
	_plot.clear()
	_metrics.text = ""


static func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


## Aktiver Modus (Dictionary in fc.modes).
func _cur() -> Dictionary:
	return fc.modes[fc.mode_index]


## Änderung am Modus speichern; rebuild = Spalten neu aufbauen.
func _changed(rebuild := true) -> void:
	fc.mode_index = fc.mode_index                # Regelart nachziehen (Art geändert)
	fc.save_settings()
	fc.modes_changed.emit()
	if rebuild:
		_sync()


static func _note(text: String) -> Label:
	var l := UITheme.make_label(text, "MutedLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# =============================================================================
# Linke Spalte: Flugmodi
# =============================================================================
func _fill_left() -> void:
	_left_box.add_child(UITheme.make_title("Flugmodi"))
	var cnt := UITheme.make_number_row("Anzahl Modi", 1.0, float(FlightController.MAX_MODES), 1.0, fc.modes.size(),
		func(v): fc.set_mode_count(int(v)), "%d")
	_left_box.add_child(cnt)
	if fc.modes.size() >= 4:
		_left_box.add_child(_note("Für 4–5 Modi braucht der Sender einen Mehrstufen-Schalter oder einen Drehregler auf dem Modus-Kanal (manche Piloten legen die Moduswahl auf einen Drehregler). Der Kanal wird in gleich große Bereiche geteilt."))
	var g := UITheme.make_toggle_group()
	for i in fc.modes.size():
		var md: Dictionary = fc.modes[i]
		var b := UITheme.make_button("%d · %s   (%s)" % [i + 1, md.get("name", ""), _art_text(md)], true)
		b.button_group = g
		b.button_pressed = i == fc.mode_index
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		b.pressed.connect(func(): fc.mode_index = idx)
		_left_box.add_child(b)

	var m := _cur()
	_left_box.add_child(UITheme.make_title(I18n.t("Modus %d") % (fc.mode_index + 1)))
	_left_box.add_child(UITheme.make_label("Name", "MutedLabel"))
	var name_edit := LineEdit.new()
	name_edit.max_length = 20
	name_edit.text = str(m.get("name", ""))
	name_edit.custom_minimum_size.y = UITheme.size("control_height")
	name_edit.text_submitted.connect(func(t): m["name"] = t; _changed())
	name_edit.focus_exited.connect(func():
		if name_edit.text != str(m.get("name", "")):
			m["name"] = name_edit.text
			_changed(false))
	_left_box.add_child(name_edit)

	# --- Art ---
	_left_box.add_child(UITheme.make_label("Art", "MutedLabel"))
	var art := str(m.get("art", "direkt"))
	var all_on := art == "pid" and _all_axes_on(m)
	var sel: int = {"direkt": 0, "pid": 2 if all_on else 1, "angle": 3, "horizon": 4}[art]
	var grid := GridContainer.new()
	grid.columns = 2
	var ag := UITheme.make_toggle_group()
	var choices := [["Direkt", 0], ["PID teilweise", 1], ["PID alle Achsen", 2], ["Vorlage Angle", 3], ["Vorlage Horizon", 4]]
	for c in choices:
		var b := UITheme.make_button(c[0], true)
		b.button_group = ag
		b.button_pressed = c[1] == sel
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var k: int = c[1]
		b.pressed.connect(func(): _set_art(m, k))
		grid.add_child(b)
	_left_box.add_child(grid)
	if art == "angle" or art == "horizon":
		_left_box.add_child(_note("Vorlage: Regler wie im Teensy des echten Chewie (Nick und Roll in der Lage geregelt, Gier als Drehrate)." if art == "horizon" else "Vorlage: Regler wie im Teensy des echten Chewie (Nick und Roll in der Lage geregelt, Gier direkt)."))

	# --- Achsen (nur PID) ---
	if art == "pid":
		var ax: Dictionary = m.get("axes", FlightController.default_axes())
		m["axes"] = ax
		var tg := GridContainer.new()
		tg.columns = 3
		tg.add_theme_constant_override("h_separation", UITheme.space("sm"))
		for h in ["Achse", "geregelt", "regelt"]:
			tg.add_child(UITheme.make_label(h, "MutedLabel"))
		for k in ["pitch", "yaw", "roll"]:
			var a: Dictionary = ax[k]
			tg.add_child(UITheme.make_label({"pitch": "Nick", "yaw": "Gier", "roll": "Roll"}[k]))
			var cb := CheckBox.new()
			cb.button_pressed = bool(a.get("on", false))
			cb.toggled.connect(func(on): a["on"] = on; _changed())
			tg.add_child(cb)
			if not bool(a.get("on", false)):
				tg.add_child(UITheme.make_label("direkt (Mischer)", "MutedLabel"))
			elif k == "yaw":
				tg.add_child(UITheme.make_label("Drehrate", "MutedLabel"))      # Gier nur als Drehrate
			else:
				var kinds := UITheme.make_choice_row(["Lage", "Drehrate"], 0 if str(a.get("kind", "angle")) == "angle" else 1,
					func(i):
						a["kind"] = "angle" if i == 0 else "rate"
						a["max"] = 30.0 if i == 0 else 90.0
						_changed())
				tg.add_child(kinds)
		_left_box.add_child(tg)

	# --- Rollausgleich ---
	var rc := CheckBox.new()
	rc.text = "Rollausgleich (Höhe und Seite)"
	rc.button_pressed = bool(m.get("roll_comp", false))
	rc.toggled.connect(func(on): m["roll_comp"] = on; _changed(false))
	_left_box.add_child(rc)
	_left_box.add_child(_note("Höhen- und Seitenbefehle werden mit dem Rollwinkel umgerechnet: bei 0° wie gewohnt, bei 90° Rollen übernimmt das Höhenleitwerk die Seite und das Seitenleitwerk die Höhe – sonst nickt das Schiff in engen, schnellen Kurven. Braucht den Lagesensor (IMU MPU-6050)."))

	# --- Stick-Belegung und Zurücksetzen ---
	_left_box.add_child(UITheme.make_label("Stick-Belegung", "MutedLabel"))
	var sm := OptionButton.new()
	sm.custom_minimum_size.y = UITheme.size("control_height")
	for k in [1, 2, 3, 4]:
		sm.add_item(FlightController.stick_mode_text(k), k)
	sm.select(sm.get_item_index(fc.stick_mode))
	sm.item_selected.connect(func(k): fc.stick_mode = sm.get_item_id(k); fc.save_settings(); fc.stick_mode_changed.emit())
	_left_box.add_child(sm)
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
	_left_box.add_child(_note("Regler, Flugmodi, Mischer, Nick-Sollwert, Stick-Mode und Strecke. Bestenliste und eigene Modelle bleiben."))


static func _all_axes_on(m: Dictionary) -> bool:
	var ax: Dictionary = m.get("axes", {})
	for k in ["pitch", "yaw", "roll"]:
		if not bool((ax.get(k, {}) as Dictionary).get("on", false)):
			return false
	return true


## Kurzbezeichnung der Art für die Modusliste.
static func _art_text(m: Dictionary) -> String:
	match str(m.get("art", "direkt")):
		"direkt": return I18n.t("Direkt")
		"angle": return "Angle"
		"horizon": return "Horizon"
	return I18n.t("PID alle Achsen") if _all_axes_on(m) else I18n.t("PID teilweise")


## Art wählen: 0 Direkt, 1 PID teilweise, 2 PID alle Achsen, 3 Angle, 4 Horizon.
func _set_art(m: Dictionary, k: int) -> void:
	match k:
		0: m["art"] = "direkt"
		1, 2:
			var was_pid := str(m.get("art", "")) == "pid"
			m["art"] = "pid"
			if not was_pid or not m.get("axes") is Dictionary:
				m["axes"] = FlightController.default_axes(k == 2)
			else:
				var ax: Dictionary = m.axes
				if k == 2:
					for a in ax: ax[a]["on"] = true
				else:
					ax["roll"]["on"] = false               # teilweise: Roll direkt
		3: m["art"] = "angle"
		4: m["art"] = "horizon"
	_changed()


# =============================================================================
# Mitte: nur die Werte des gewählten Modus
# =============================================================================
func _fill_mid() -> void:
	var m := _cur()
	var art := str(m.get("art", "direkt"))
	_mid_box.add_child(UITheme.make_title(I18n.t("Werte · %s") % m.get("name", "")))
	match art:
		"direkt": _fill_direct(m)
		"pid": _fill_pid(m)
		_: _fill_teensy(art)


## Direkt: Mischtabelle (eigene des Modus oder die aus „Mischer einstellen“).
func _fill_direct(m: Dictionary) -> void:
	var ship := fc.airship
	var own := m.get("mix") is Dictionary
	var cb := CheckBox.new()
	cb.text = "Eigene Mischtabelle für diesen Modus (aus = wie „Mischer einstellen“)"
	cb.button_pressed = own
	cb.toggled.connect(func(on):
		if on:
			m["mix"] = (ship.mix_table.duplicate(true) if fc.manual_mix_valid() and ship.mix_manual else fc.suggest_mix())
		else:
			m.erase("mix")
		_changed())
	_mid_box.add_child(cb)
	var tbl: Dictionary
	if own and fc._table_valid(m.mix):
		tbl = m.mix
	elif own:
		m["mix"] = fc.suggest_mix()                 # Bauteile geändert: neu vorschlagen
		tbl = m.mix
	elif ship.mix_manual and fc.manual_mix_valid():
		tbl = ship.mix_table
	else:
		tbl = fc.suggest_mix()
	if own:
		var sg := UITheme.make_button("Vorschlag aus Einbaulage")
		sg.pressed.connect(func(): m["mix"] = fc.suggest_mix(); _changed())
		_mid_box.add_child(sg)
	else:
		_mid_box.add_child(_note("Zeigt die Tabelle aus „Mischer einstellen“ (Baukasten → Steuerung) bzw. den Vorschlag aus der Einbaulage."))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", UITheme.space("sm"))
	for h in ["Ausgang", "Nick", "Gier", "Roll"]:
		grid.add_child(UITheme.make_label(h, "MutedLabel"))
	for o in FlightController.mix_outputs(ship):
		var nl := UITheme.make_label("%s (±%d°)" % [I18n.t(o.name), roundi(o.max_deg)])
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grid.add_child(nl)
		var row: Array = tbl.get(o.key, [0.0, 0.0, 0.0])
		for axn in 3:
			var le := LineEdit.new()
			le.custom_minimum_size = Vector2(84, UITheme.size("control_height"))
			le.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
			le.text = "%d %%" % roundi(row[axn])
			le.editable = own
			var key: String = o.key
			var ai := axn
			var commit := func():
				var t := le.text.replace("%", "").replace(",", ".").strip_edges()
				if own and t.is_valid_float():
					var arr: Array = (m.mix as Dictionary).get(key, [0.0, 0.0, 0.0]).duplicate()
					arr[ai] = clampf(float(t), -200.0, 200.0)
					m.mix[key] = arr
					fc.save_settings()
				le.text = "%d %%" % roundi((m.mix if own else tbl).get(key, [0, 0, 0])[ai])
			le.text_submitted.connect(func(_t): commit.call(); le.release_focus())
			le.focus_exited.connect(commit)
			grid.add_child(le)
	_mid_box.add_child(grid)
	_mid_box.add_child(UITheme.make_title("Knüppel"))
	_mid_box.add_child(UITheme.make_slider_row("Expo Seitenknüppel (Gier)", 0.0, 1.0, 0.05, fc.yaw_expo,
		func(v): fc.yaw_expo = v; fc.save_settings(), "%.2f", 120))


## PID: je geregelter Achse Kp, Ki, Kd und Höchstwert.
func _fill_pid(m: Dictionary) -> void:
	var ax: Dictionary = m.get("axes", FlightController.default_axes())
	var any := false
	for k in ["pitch", "yaw", "roll"]:
		var a: Dictionary = ax[k]
		if not bool(a.get("on", false)):
			continue
		any = true
		var angle: bool = str(a.get("kind", "rate")) == "angle" and k != "yaw"
		var axn: String = I18n.t({"pitch": "Nick", "yaw": "Gier", "roll": "Roll"}[k])
		_mid_box.add_child(UITheme.make_title("%s (%s)" % [axn, I18n.t("Lage") if angle else I18n.t("Drehrate")]))
		for term in [["Kp", 0.0, 10.0, 0.01], ["Ki", 0.0, 10.0, 0.01], ["Kd", 0.0, 5.0, 0.005]]:
			var t: String = term[0]
			_mid_box.add_child(UITheme.make_number_row(t, term[1], term[2], term[3], float(a.get(t, 0.0)),
				func(v): a[t] = v; fc.save_settings(), "%.3f"))
		var mx_lbl := "Sollwinkel bei vollem Knüppel" if angle else "Sollrate bei vollem Knüppel"
		_mid_box.add_child(UITheme.make_number_row(mx_lbl, 1.0, 720.0, 1.0, float(a.get("max", 30.0)),
			func(v): a["max"] = v; fc.save_settings(), "%d °" if angle else "%d °/s"))
	if not any:
		_mid_box.add_child(_note("Keine Achse geregelt – dieser Modus wirkt wie Direkt."))
	_mid_box.add_child(_note("Nicht geregelte Achsen gehen direkt über den Mischer (Baukasten → Steuerung → Mischer einstellen). Ausgang = 0,01 · (Kp·Fehler + Ki·∫Fehler − Kd·D), ±1 = Vollausschlag."))
	_mid_box.add_child(UITheme.make_slider_row("Expo Seitenknüppel (Gier)", 0.0, 1.0, 0.05, fc.yaw_expo,
		func(v): fc.yaw_expo = v; fc.save_settings(), "%.2f", 120))


## Vorlage Angle/Horizon: Werte wie im Teensy-Code (bisheriges Menü).
func _fill_teensy(art: String) -> void:
	var axes := UITheme.make_hbox("xs")
	var ag := UITheme.make_toggle_group()
	for a in [["Nick", FlightController.Axis.PITCH], ["Roll", FlightController.Axis.ROLL], ["Gier", FlightController.Axis.YAW]]:
		var b := UITheme.make_button(a[0], true)
		b.button_group = ag
		b.button_pressed = a[1] == _axis
		var axv: int = a[1]
		b.pressed.connect(func(): _axis = axv; _clear(_mid_box); _fill_mid())
		axes.add_child(b)
	_mid_box.add_child(axes)
	for p in FlightController.UI_PARAMS[_axis]:
		var term: String = p.term
		var fmt: String = p.get("fmt", "%d" if p.step >= 1.0 else "%.2f")
		var axis := _axis
		_mid_box.add_child(UITheme.make_slider_row(p.label, p.min, p.max, p.step, fc.get_param(axis, term),
			func(v): fc.set_param(axis, term, v), fmt, 120))
	_mid_box.add_child(UITheme.make_title("Nick-Sollwert"))
	_mid_box.add_child(UITheme.make_slider_row("Max ±", 10.0, 60.0, 1.0, fc.pitch_max_deg,
		func(v): fc.pitch_max_deg = v; fc.save_settings(), "%d°", 120))
	if art == "horizon":
		_mid_box.add_child(UITheme.make_slider_row("Horizon Nickrate", 5.0, 120.0, 1.0, fc.pitch_rate_dps,
			func(v): fc.pitch_rate_dps = v; fc.save_settings(), "%d °/s", 120))
		_mid_box.add_child(UITheme.make_slider_row("Horizon Rückkehr", 1.0, 90.0, 1.0, fc.pitch_return_dps,
			func(v): fc.pitch_return_dps = v; fc.save_settings(), "%d °/s", 120))
		_mid_box.add_child(UITheme.make_slider_row("Horizon Vorlauf max", 1.0, 45.0, 1.0, fc.pitch_lead_deg,
			func(v): fc.pitch_lead_deg = v; fc.save_settings(), "%d°", 120))
	_mid_box.add_child(UITheme.make_title("Mischer"))
	for p in FlightController.MIX_PARAMS:
		var field: String = p[0]
		_mid_box.add_child(UITheme.make_slider_row(p[1], p[2], p[3], p[4], fc.get(field),
			func(v): fc.set(field, v); fc.save_settings(), p[5], 120))


# =============================================================================
# Rechts: Sprung auslösen und Kennwerte
# =============================================================================
func _on_trigger() -> void:
	var sp := fc.airship.airspeed if fc.airship else 0.0
	fc.trigger_step(_step_axis, _step_amount, 3.0)
	_plot.mark_trigger(sp)
	_metrics.text = I18n.dec(I18n.t("Sprung bei %.1f km/h …") % (sp * 3.6))


func _on_sample(axis: int, setpoint: float, measurement: float) -> void:
	if visible and axis == _step_axis:
		_plot.push(setpoint, measurement)
		var res := _plot.metrics()
		if not res.is_empty():
			var unit := "°/s" if _step_axis == FlightController.Axis.YAW else "°"
			_metrics.text = I18n.dec(I18n.t("Sprung %d %s bei %.1f km/h\nAnstieg (10–90 %%) %s · Überschwingen %d %%\neingeschwungen (±10 %%) nach %s") % [
				roundi(_step_amount), unit, res.speed * 3.6,
				("%.2f s" % res.rise) if res.rise >= 0.0 else "–", roundi(res.overshoot * 100.0),
				("%.2f s" % res.settle) if res.settle >= 0.0 else I18n.t("noch nicht")])


# =============================================================================
# Signalfluss (interaktiv) als Fenster über dem Menü
# =============================================================================
func _show_flow() -> void:
	if _flow_win and is_instance_valid(_flow_win):
		_flow_win.queue_free()
	var win := PanelContainer.new()
	win.add_theme_stylebox_override("panel", UITheme.box(Color("101720"), Color("2c3746"), -1, 12))
	var flow := SignalFlow.new()
	flow.fc = fc
	flow.closed.connect(func(): win.queue_free())
	win.add_child(flow)
	add_child(win)
	win.position = Vector2(size.x * 0.04, size.y * 0.04)
	win.size = Vector2(size.x * 0.92, size.y * 0.92)
	_flow_win = win


# =============================================================================
# Live-Plot: Soll/Ist der letzten 5 s mit Zeitachse; nach dem Auslösen Kennwerte
# =============================================================================
class StepPlot:
	extends Control
	const N := 300                       ## 5 s bei 60 Messungen je Sekunde
	const HZ := 60.0
	var _sp: PackedFloat32Array = PackedFloat32Array()
	var _pv: PackedFloat32Array = PackedFloat32Array()
	var _trig := -1                      ## Index des Auslösens (wandert mit nach links)
	var _speed := 0.0

	func clear() -> void:
		_sp.clear(); _pv.clear(); _trig = -1; queue_redraw()

	func mark_trigger(speed: float) -> void:
		_trig = _sp.size()
		_speed = speed

	func push(sp: float, pv: float) -> void:
		_sp.append(sp); _pv.append(pv)
		if _sp.size() > N:
			_sp.remove_at(0); _pv.remove_at(0)
			if _trig >= 0:
				_trig -= 1
		queue_redraw()

	## Kennwerte der Antwort seit dem Auslösen: Anstiegszeit 10–90 %, Überschwingen,
	## Einschwingzeit (±10 % des Sprungs); {} solange nichts ausgelöst wurde.
	func metrics() -> Dictionary:
		if _trig < 1 or _trig >= _sp.size() - 2:
			return {}
		var y0 := _pv[_trig - 1]
		var target := _sp[mini(_trig + 1, _sp.size() - 1)] - _sp[_trig - 1]
		if absf(target) < 1e-4:
			return {}
		var t10 := -1.0
		var t90 := -1.0
		var peak := 0.0
		var settle := -1.0
		var last_out := -1
		for i in range(_trig, _sp.size()):
			var r := (_pv[i] - y0) / target            # 0 … 1 = Sprung erreicht
			var t := (i - _trig) / HZ
			if t10 < 0.0 and r >= 0.1: t10 = t
			if t90 < 0.0 and r >= 0.9: t90 = t
			peak = maxf(peak, r)
			if absf(r - 1.0) > 0.1: last_out = i
		if last_out < _sp.size() - 1 and _sp.size() - _trig > 30:
			settle = (last_out + 1 - _trig) / HZ
		return {"rise": (t90 - t10) if t10 >= 0.0 and t90 >= 0.0 else -1.0,
			"overshoot": maxf(peak - 1.0, 0.0), "settle": settle, "speed": _speed}

	func _draw() -> void:
		draw_style_box(UITheme.box(UITheme.color("surface_alt"), UITheme.color("border"), UITheme.radius("md"), 0), Rect2(Vector2.ZERO, size))
		var font := get_theme_default_font()
		var bottom := size.y - 16.0
		var mid := bottom * 0.5
		# Zeitachse: Linien je Sekunde, rechts = jetzt
		for sec in 6:
			var x := size.x - sec * HZ * size.x / float(N - 1)
			draw_line(Vector2(x, 0), Vector2(x, bottom), Color(1, 1, 1, 0.06), 1.0)
			draw_string(font, Vector2(x - 14, size.y - 3), "-%d s" % sec if sec > 0 else "0 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UITheme.color("text_muted"))
		draw_line(Vector2(0, mid), Vector2(size.x, mid), UITheme.color("border_strong"), 1.0)
		if _sp.size() < 2:
			return
		var span := 0.2                               # ± Skala (rad), wächst mit
		for i in _sp.size(): span = maxf(span, maxf(absf(_sp[i]), absf(_pv[i])) * 1.2)
		var x0 := size.x - (_sp.size() - 1) * size.x / float(N - 1)
		if _trig >= 0:
			var xt := x0 + _trig * size.x / float(N - 1)
			draw_line(Vector2(xt, 0), Vector2(xt, bottom), UITheme.color("warning"), 1.0)
		var pts_sp := PackedVector2Array()
		var pts_pv := PackedVector2Array()
		for i in _sp.size():
			var x := x0 + i * size.x / float(N - 1)
			pts_sp.append(Vector2(x, mid - _sp[i] / span * mid))
			pts_pv.append(Vector2(x, mid - _pv[i] / span * mid))
		draw_polyline(pts_sp, UITheme.color("plot_setpoint"), 1.5, true)
		draw_polyline(pts_pv, UITheme.color("plot_measure"), 2.0, true)
