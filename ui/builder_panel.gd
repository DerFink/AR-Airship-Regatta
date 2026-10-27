# 2026-10-27 11:08 – Reiter „Technik“ und „Gestaltung“ (Farbe, Schriftzug, Logo nach freigegebenem Entwurf); Motor-Editor wirkt auf das ganze Motorpaar (Rückwärtsschub, Wirkungsgrad rückwärts, Propeller, Drehzahl, Drehrichtung); Knopf „Teilen“; Signal ui_action für ruhige Töne; Modellauswahl inkl. Sammlung
# 2026-10-27 10:42 – Erstversion: Baukasten nach freigegebenem Entwurf (links Hülle + Bauteil-Palette + Bauteil-Editor, Mitte freie Sicht auf das Modell, rechts Kennwerte, unten Validator-Banner); Preset-Auswahl
# =============================================================================
# BuilderPanel.gd
# -----------------------------------------------------------------------------
#   ┌ [Technik][Gestaltung]      ┐                       ┌ Kennwerte ┐
#   │ Technik:   Modell, Hülle,  │    (3D-Vorschau,      │ 2,30×0,46 │
#   │            Bauteile, Editor│     Kamera seitlich)  │ Stab 1,13 │
#   │ Gestaltung: Farbe, Schrift,│                       │ [Teilen]  │
#   │            Logo            │ [ Validator-Banner ]  │ [Fertig]  │
#   └────────────────────────────┘                       └───────────┘
#
# Jede technische Änderung → ship.rebuild_mass_properties() → Bauteile neu
# am Rumpf platziert, Darstellung neu, Validator läuft erneut.
# Gestaltungs-Änderungen malen nur die Hüllentextur neu.
# =============================================================================
class_name BuilderPanel
extends Control

signal closed
signal share_requested
## Für ruhige Töne: "add", "select", "remove", "ok", "warn"
signal ui_action(kind: String)

var ship: AirshipPhysics
var visual: AirshipVisual

var _preset: OptionButton
var _parts_list: ItemList
var _editor_box: VBoxContainer
var _look_box: VBoxContainer
var _stats: Label
var _banner: PanelContainer
var _hull_rows := {}           ## Name → Slider-Zeile (zum Nachziehen nach Modellwechsel)
var _last_level := -1
var _file_dialog: FileDialog


func setup(airship: AirshipPhysics, airship_visual: AirshipVisual) -> void:
	ship = airship
	visual = airship_visual


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE      # Mitte bleibt durchlässig
	var m := UITheme.space("lg")

	# ===================== linke Seitenleiste mit Reitern =====================
	var left := UITheme.make_panel(UITheme.size("panel_side_width"))
	add_child(left)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, m)
	var tabs := TabContainer.new()
	left.add_child(tabs)
	tabs.add_child(_scroll_page("Technik", _build_tech_page))
	tabs.add_child(_scroll_page("Gestaltung", _build_look_page))
	tabs.tab_changed.connect(func(_i): ui_action.emit("select"))

	# ===================== rechte Spalte: Kennwerte ==========================
	var right := UITheme.make_panel(190)
	add_child(right)
	right.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE, Control.PRESET_MODE_MINSIZE, m)
	var rcol := UITheme.make_vbox("sm")
	right.add_child(rcol)
	rcol.add_child(UITheme.make_title("Kennwerte"))
	_stats = UITheme.make_label("")
	rcol.add_child(_stats)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(spacer)
	var share := UITheme.make_button("Teilen")
	share.pressed.connect(func(): ui_action.emit("select"); share_requested.emit())
	rcol.add_child(share)
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	rcol.add_child(done)

	# ===================== Validator-Banner unten mittig =====================
	_banner = UITheme.make_banner()
	add_child(_banner)
	_banner.custom_minimum_size.x = 420
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, m)

	# Dateiauswahl für das Logo (nutzt den Systemdialog, wo verfügbar)
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Bilder"])
	_file_dialog.use_native_dialog = true
	_file_dialog.file_selected.connect(_on_logo_file)
	add_child(_file_dialog)

	ship.config_changed.connect(_refresh)
	visibility_changed.connect(_on_visibility)
	_refresh()


## Beim Öffnen: Modellliste (evtl. neu gespeicherte) und Regler auffrischen.
func _on_visibility() -> void:
	if visible:
		reload_model_list()
		_sync_from_ship()


## Seite eines Reiters: scrollbar, mit Token-Abständen.
func _scroll_page(title: String, builder: Callable) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := UITheme.make_vbox("sm")
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	builder.call(col)
	return sc


# =============================================================================
# Reiter „Technik“
# =============================================================================
func _build_tech_page(col: VBoxContainer) -> void:
	col.add_child(UITheme.make_title("Modell"))
	_preset = OptionButton.new()
	_preset.custom_minimum_size.y = UITheme.size("control_height")
	_preset.item_selected.connect(_on_preset)
	col.add_child(_preset)
	reload_model_list()

	col.add_child(UITheme.make_title("Hülle"))
	_hull_rows.vol = UITheme.make_slider_row("Volumen", 0.05, 5.0, 0.01, ship.hull.volume_m3,
		func(v): ship.hull.volume_m3 = v, "%.2f m³", 90)
	_hull_rows.ld = UITheme.make_slider_row("L/D", 3.0, 9.0, 0.1, ship.hull.length_to_diameter,
		func(v): ship.hull.length_to_diameter = v, "%.1f", 90)
	_hull_rows.m = UITheme.make_slider_row("Dicke Stelle", 0.30, 0.50, 0.01, ship.hull.m,
		func(v): ship.hull.m = v, "%.2f", 90)
	_hull_rows.cp = UITheme.make_slider_row("Völligkeit", 0.55, 0.72, 0.005, ship.hull.cp,
		func(v): ship.hull.cp = v, "%.3f", 90)
	for k in ["vol", "ld", "m", "cp"]:
		col.add_child(_hull_rows[k])

	col.add_child(UITheme.make_title("Bauteile"))
	var pal := GridContainer.new()
	pal.columns = 2
	pal.add_theme_constant_override("h_separation", UITheme.space("xs"))
	pal.add_theme_constant_override("v_separation", UITheme.space("xs"))
	col.add_child(pal)
	var add_defs := [
		["+ Ruder", func(): _add_fin(ControlSurface.Kind.FLAP)],
		["+ Pendel", func(): _add_fin(ControlSurface.Kind.ALL_MOVING)],
		["+ Canard", func(): _add_fin(ControlSurface.Kind.CANARD)],
		["+ Motorpaar", _add_motor_pair],
	]
	for d in add_defs:
		var b := UITheme.make_button(d[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(d[1])
		pal.add_child(b)

	_parts_list = ItemList.new()
	_parts_list.custom_minimum_size.y = 150
	_parts_list.item_selected.connect(func(i): ui_action.emit("select"); _on_part_selected(i))
	col.add_child(_parts_list)

	_editor_box = UITheme.make_vbox("xs")
	col.add_child(_editor_box)


## Auswahlliste neu füllen (Presets + Sammlung + eigene Modelle).
func reload_model_list() -> void:
	if _preset == null:
		return
	_preset.clear()
	_preset.add_item("Modell wählen …")
	for p in AirshipPresets.list():
		_preset.add_item(p.name)


# =============================================================================
# Reiter „Gestaltung“
# =============================================================================
const HULL_SWATCHES := ["dfe5ea", "e5534b", "3d8bfd", "2b2f36", "e0a43a", "3fb27f"]
const TEXT_SWATCHES := ["1b2128", "ffffff", "e5534b", "3d8bfd"]

func _build_look_page(col: VBoxContainer) -> void:
	_look_box = col
	_fill_look_page()


func _fill_look_page() -> void:
	for c in _look_box.get_children(): c.queue_free()
	var l := ship.livery
	_look_box.add_child(UITheme.make_title("Hüllenfarbe"))
	_look_box.add_child(_swatch_row(HULL_SWATCHES, l.hull_color, func(c): l.hull_color = c))

	_look_box.add_child(UITheme.make_title("Schriftzug"))
	var te := LineEdit.new()
	te.placeholder_text = "CHEWIE"
	te.text = l.text
	te.max_length = 24
	te.custom_minimum_size.y = UITheme.size("control_height")
	te.text_changed.connect(func(t): l.text = t)
	_look_box.add_child(te)
	_look_box.add_child(_swatch_row(TEXT_SWATCHES, l.text_color, func(c): l.text_color = c))
	_look_box.add_child(UITheme.make_slider_row("Größe", 0.1, 0.6, 0.01, l.text_size,
		func(v): l.text_size = v, "%.2f", 90))
	_look_box.add_child(UITheme.make_slider_row("Lage", 0.1, 0.9, 0.01, l.text_pos,
		func(v): l.text_pos = v, "%.2f", 90))

	_look_box.add_child(UITheme.make_title("Logo"))
	var lrow := UITheme.make_hbox("xs")
	var load_b := UITheme.make_button("Logo laden")
	load_b.pressed.connect(func(): _file_dialog.popup_centered_ratio(0.8))
	lrow.add_child(load_b)
	var rem := UITheme.make_button("Entfernen")
	rem.pressed.connect(func(): l.logo_ref = ""; ui_action.emit("remove"); _fill_look_page())
	lrow.add_child(rem)
	_look_box.add_child(lrow)
	var info := UITheme.make_label("", "MutedLabel")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if l.logo_ref == "":
		info.text = "Kein Logo. PNG mit transparentem Hintergrund wirkt am besten."
	elif l.logo_missing():
		info.text = "Logo „%s“ fehlt – bitte die mitgeschickte Bilddatei laden." % l.logo_ref
		info.add_theme_color_override("font_color", UITheme.color("warning"))
	else:
		info.text = "Datei: %s – beim Teilen separat mitschicken." % l.logo_ref
	_look_box.add_child(info)
	_look_box.add_child(UITheme.make_slider_row("Größe", 0.1, 0.8, 0.01, l.logo_size,
		func(v): l.logo_size = v, "%.2f", 90))
	_look_box.add_child(UITheme.make_slider_row("Lage", 0.05, 0.9, 0.01, l.logo_pos,
		func(v): l.logo_pos = v, "%.2f", 90))
	var both := CheckBox.new()
	both.text = "Beidseitig"
	both.button_pressed = l.both_sides
	both.toggled.connect(func(on): l.both_sides = on)
	_look_box.add_child(both)


## Farbfelder + freie Farbwahl; on_pick(Color) beim Antippen.
func _swatch_row(hexes: Array, current: Color, on_pick: Callable) -> HBoxContainer:
	var row := UITheme.make_hbox("xs")
	for hx in hexes:
		var c := Color(hx)
		var b := Button.new()
		b.custom_minimum_size = Vector2(34, 34)
		b.focus_mode = Control.FOCUS_NONE
		var sel := c.is_equal_approx(current)
		b.add_theme_stylebox_override("normal", UITheme.box(c, UITheme.color("accent") if sel else UITheme.color("border_strong"), UITheme.radius("sm"), 0))
		b.add_theme_stylebox_override("hover", UITheme.box(c, UITheme.color("accent"), UITheme.radius("sm"), 0))
		b.add_theme_stylebox_override("pressed", UITheme.box(c, UITheme.color("accent"), UITheme.radius("sm"), 0))
		b.pressed.connect(func(): on_pick.call(c); ui_action.emit("select"); _fill_look_page())
		row.add_child(b)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(34, 34)
	picker.color = current
	picker.edit_alpha = false
	picker.color_changed.connect(func(c): on_pick.call(c))
	row.add_child(picker)
	return row


func _on_logo_file(path: String) -> void:
	var ref := Livery.import_logo_file(path)
	if ref == "":
		UITheme.set_banner(_banner, "Bild ließ sich nicht laden. PNG oder JPG wählen.", "warning")
		ui_action.emit("warn")
		return
	ship.livery.logo_ref = ref
	ui_action.emit("ok")
	_fill_look_page()


# =============================================================================
# Anzeige aktualisieren: Teileliste, Kennwerte, Validator
# =============================================================================
func _refresh() -> void:
	if not is_inside_tree() or _parts_list == null:
		return
	var sel := _parts_list.get_selected_items()
	_parts_list.clear()
	for s in ship.surfaces:
		_parts_list.add_item("%s  ·  %.2f m²" % [s.display_name, s.area_m2])
	for mo in ship.motors:
		_parts_list.add_item("%s  ·  %.1f N%s" % [mo.display_name, mo.max_thrust_n, "  ↺" if mo.reverse_allowed else ""])
	if sel.size() > 0 and sel[0] < _parts_list.item_count:
		_parts_list.select(sel[0])

	var r := TailValidator.validate(ship.hull, ship.surfaces, ship.cg_offset)
	var h := ship.hull
	_stats.text = "%s\n%.2f × %.2f m\nV_T Nick %.2f\nV_T Gier %.2f\nStab. Nick %.2f\nStab. Gier %.2f\nMasse %.0f g" % [
		ship.model_name, h.length_m, h.diameter_m, r.vt_pitch, r.vt_yaw, r.ratio_pitch, r.ratio_yaw,
		ship.total_mass * 1000.0]
	var level := "success"
	if r.level == TailValidator.Level.UNSTABLE: level = "danger"
	elif r.level == TailValidator.Level.MARGINAL: level = "warning"
	UITheme.set_banner(_banner, r.message + ("  " + r.detail if r.detail != "" else ""), level)
	if r.level == TailValidator.Level.UNSTABLE and _last_level != r.level and _last_level != -1:
		ui_action.emit("warn")                        # leiser Hinweiston beim Kippen ins Instabile
	_last_level = r.level
	if visual:
		visual.set_validation_level(r.level)


func _changed() -> void:
	ship.rebuild_mass_properties()     # platziert, löst config_changed → _refresh aus


## Regler auf das aktuelle Modell setzen (nach Modellwechsel/Import).
func _sync_from_ship() -> void:
	var vals := {"vol": ship.hull.volume_m3, "ld": ship.hull.length_to_diameter,
		"m": ship.hull.m, "cp": ship.hull.cp}
	for k in vals:
		(_hull_rows[k].get_meta("slider") as HSlider).set_value_no_signal(vals[k])
		(_hull_rows[k].get_child(2) as Label).text = ("%.3f" if k == "cp" else "%.2f") % vals[k]
	_clear_editor()
	_fill_look_page()
	_refresh()


# =============================================================================
# Modelle und Bauteile hinzufügen / entfernen
# =============================================================================
func _on_preset(idx: int) -> void:
	if idx <= 0:
		return
	AirshipPresets.list()[idx - 1].build.call(ship)
	_preset.select(0)
	ui_action.emit("ok")
	_sync_from_ship()


func _add_fin(kind: ControlSurface.Kind) -> void:
	var names := {ControlSurface.Kind.FLAP: "Ruder", ControlSurface.Kind.ALL_MOVING: "Pendelruder",
		ControlSurface.Kind.CANARD: "Canard"}
	var x := 0.18 if kind == ControlSurface.Kind.CANARD else 0.90
	var area := 0.03 if kind == ControlSurface.Kind.CANARD else 0.08
	var s := AirshipPresets.make_fin("%s %d" % [names[kind], ship.surfaces.size() + 1], x, 90.0, area, kind)
	ship.surfaces.append(s)
	_changed()
	ui_action.emit("add")
	_parts_list.select(ship.surfaces.size() - 1)
	_on_part_selected(ship.surfaces.size() - 1)


func _add_motor_pair() -> void:
	var pid := "paar%d" % (ship.motors.size() / 2 + 1)
	var r := AirshipPresets.make_motor("Motor rechts (%s)" % pid, 0.25, 90.0, 1.2, 60.0, 0.0)
	var l := AirshipPresets.make_motor("Motor links (%s)" % pid, 0.25, 270.0, 1.2, 60.0, 0.0)
	r.pair_id = pid; l.pair_id = pid
	r.spin_dir = 1; l.spin_dir = -1                 # gegenläufig
	ship.motors.append(r)
	ship.motors.append(l)
	_changed()
	ui_action.emit("add")


func _remove_selected(is_motor: bool, idx: int) -> void:
	if is_motor: ship.motors.remove_at(idx)
	else: ship.surfaces.remove_at(idx)
	_clear_editor()
	_changed()
	ui_action.emit("remove")


## Alle Motoren desselben Paares (oder nur dieser, wenn ohne pair_id).
func _pair_of(mo: VectorMotor) -> Array[VectorMotor]:
	var out: Array[VectorMotor] = []
	for m in ship.motors:
		if m == mo or (mo.pair_id != "" and m.pair_id == mo.pair_id):
			out.append(m)
	return out


# =============================================================================
# Bauteil-Editor (erscheint unter der Liste für das gewählte Teil)
# =============================================================================
func _clear_editor() -> void:
	if _editor_box:
		for c in _editor_box.get_children(): c.queue_free()


func _on_part_selected(i: int) -> void:
	_clear_editor()
	var n_fin := ship.surfaces.size()
	var is_motor := i >= n_fin
	_editor_box.add_child(UITheme.make_title("Bauteil"))
	if not is_motor:
		var s: ControlSurface = ship.surfaces[i]
		var kind := OptionButton.new()
		for t in ["Ruderklappe", "Pendelruder", "Canard"]: kind.add_item(t)
		kind.select(s.kind)
		kind.item_selected.connect(func(k): s.kind = k; _changed())
		_editor_box.add_child(kind)
		_editor_box.add_child(UITheme.make_slider_row("Position", 0.0, 1.0, 0.01, s.hull_x,
			func(v): s.hull_x = v; _changed(), "%.2f", 90))
		_editor_box.add_child(UITheme.make_slider_row("Winkel", 0.0, 359.0, 1.0, s.hull_angle_deg,
			func(v): s.hull_angle_deg = v; _changed(), "%d°", 90))
		_editor_box.add_child(UITheme.make_slider_row("Fläche", 0.005, 0.5, 0.005, s.area_m2,
			func(v): s.area_m2 = v; _changed(), "%.3f m²", 90))
		_editor_box.add_child(UITheme.make_slider_row("Ausschlag", 0.0, 45.0, 1.0, s.max_deflection_deg,
			func(v): s.max_deflection_deg = v, "%d°", 90))
		var flex := CheckBox.new()
		flex.text = "Pseudo-Flex (Depron)"
		flex.button_pressed = s.pseudo_flex
		flex.toggled.connect(func(on): s.pseudo_flex = on)
		_editor_box.add_child(flex)
	else:
		var mo: VectorMotor = ship.motors[i - n_fin]
		var pair := _pair_of(mo)
		# Lage gilt nur für diesen Motor (links/rechts unterscheiden sich im Winkel)
		_editor_box.add_child(UITheme.make_label("Lage (nur dieser Motor)", "MutedLabel"))
		_editor_box.add_child(UITheme.make_slider_row("Position", 0.0, 1.0, 0.01, mo.hull_x,
			func(v): mo.hull_x = v; _changed(), "%.2f", 90))
		_editor_box.add_child(UITheme.make_slider_row("Winkel", 0.0, 359.0, 1.0, mo.hull_angle_deg,
			func(v): mo.hull_angle_deg = v; _changed(), "%d°", 90))
		# Alles Weitere gilt für das ganze Paar
		_editor_box.add_child(UITheme.make_label(
			"Für das Paar (%d Motoren)" % pair.size() if pair.size() > 1 else "Antrieb", "MutedLabel"))
		var set_all := func(prop: String, v, relayout: bool):
			for m in pair: m.set(prop, v)
			if relayout: _changed()
		_editor_box.add_child(UITheme.make_slider_row("Schub vor", 0.1, 10.0, 0.1, mo.max_thrust_n,
			func(v): set_all.call("max_thrust_n", v, true), "%.1f N", 90))
		var rev := CheckBox.new()
		rev.text = "Rückwärtsschub erlaubt"
		rev.button_pressed = mo.reverse_allowed
		rev.toggled.connect(func(on): set_all.call("reverse_allowed", on, true))
		_editor_box.add_child(rev)
		var eff_row := UITheme.make_slider_row("Wirkung rückw.", 0.1, 1.0, 0.05, mo.reverse_efficiency,
			func(v): set_all.call("reverse_efficiency", v, false), "%.2f", 90)
		_editor_box.add_child(eff_row)
		var hint := UITheme.make_label("Normaler Propeller ≈ 0,55 · 3D-Propeller ≈ 0,95", "MutedLabel")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_editor_box.add_child(hint)
		_editor_box.add_child(UITheme.make_slider_row("Schwenk max", 0.0, 90.0, 1.0, mo.max_swivel_deg,
			func(v): set_all.call("max_swivel_deg", v, false), "%d°", 90))
		_editor_box.add_child(UITheme.make_slider_row("Achsneigung", 0.0, 60.0, 1.0, mo.swivel_tilt_deg,
			func(v): set_all.call("swivel_tilt_deg", v, true), "%d°", 90))
		_editor_box.add_child(UITheme.make_label("Propeller (Klang)", "MutedLabel"))
		_editor_box.add_child(UITheme.make_slider_row("Durchmesser", 2.0, 15.0, 0.5, mo.prop_diameter_in,
			func(v): set_all.call("prop_diameter_in", v, false), "%.1f\"", 90))
		_editor_box.add_child(UITheme.make_slider_row("Blätter", 2.0, 6.0, 1.0, mo.prop_blades,
			func(v): set_all.call("prop_blades", int(v), false), "%d", 90))
		_editor_box.add_child(UITheme.make_slider_row("Drehzahl max", 3000.0, 40000.0, 500.0, mo.max_rpm,
			func(v): set_all.call("max_rpm", v, false), "%d U/min", 90))
		var dir := OptionButton.new()
		dir.add_item("Rechtsdrehend (CW)")
		dir.add_item("Linksdrehend (CCW)")
		dir.select(0 if mo.spin_dir > 0 else 1)
		dir.item_selected.connect(func(k): mo.spin_dir = 1 if k == 0 else -1)
		_editor_box.add_child(UITheme.make_label("Drehrichtung (nur dieser Motor)", "MutedLabel"))
		_editor_box.add_child(dir)
	var del := UITheme.make_button("Bauteil entfernen")
	del.pressed.connect(func(): _remove_selected(is_motor, i - n_fin if is_motor else i))
	_editor_box.add_child(del)
