# 2026-11-11 12:00 – Flight Controller: Bausteine an/aus, Signalfluss-Bild, Export als Teensy-Sketch (.ino, dRehmFlight)
# 2026-11-11 11:00 – Antrieb: Schubrichtung als Vektor (x vorn, y rechts, z unten), im Paar gespiegelt
# 2026-11-11 10:10 – Eigene Massen: je Leitwerksflosse, je Canard, Flugcontroller; Ausschlag bis 80°
# 2026-11-11 01:35 – Reiter Hülle · Leitwerk · Antrieb · Flight Controller · Optik; Flight Controller: Teensy an/aus und Regler (PID) einstellen; Optik: Material und Farbe von Hülle und Leitwerk getrennt
# 2026-11-11 00:40 – Turm entfernt (als Canard bauen); Schwere in % des Auftriebs (0 % = aerostatisch ausgeglichen); Nutzlast (Masse, Lage, Winkel); Antrieb: Teensy (+10 g) und Akku (Zellen, Kapazität, Masse); Motorpaare bleiben symmetrisch zur Längsachse; Paar wird gemeinsam entfernt
# 2026-11-07 21:40 – Achsneigung der Schwenkmotoren −60…60° (negativ = Schub schwenkt radial wie bei Chewie)
# 2026-11-07 21:10 – open_model_choice(): Modellliste aufklappen (Menüpunkt „Modell wählen“)
# 2026-10-28 00:15 – Modellwahl meldet model_applied (PID-Vorgaben übernehmen)
# 2026-10-27 23:49 – Reiter Hülle: Turm an/aus mit Lage, Länge, Höhe; Turm zählt nicht als Canard
# 2026-10-27 23:28 – Modellauswahl fest in der rechten Spalte; Schalter Elastisches Leitwerk für jede Bauart; neue Motorpaare seitlich unten (135°/225°)
# 2026-10-27 16:07 – Reiter Hülle: Massen (Hülle, Elektronik, Restmasse-Anzeige, Lage mit Automatik); Antrieb: Masse je Gondel
# 2026-10-27 15:12 – Umbau nach freigegebenem Entwurf: vier Reiter (Hülle, Leitwerk, Antrieb, Gestaltung); Leitwerk als symmetrische Anordnung (+, ×, Y, λ, gleichmäßig 1–8 Flossen; Klappe/Pendel; Fläche in cm², Streckung, Pfeilung, V-Winkel; Höhen-/Seitenleitwerk getrennt); Canards separat; Heckansicht; Hinweis und Knopf „Ansicht“ für Drehen/Zoomen; große Regler
# 2026-10-27 14:36 – Schwenkbereich der Motoren im Editor bis 120° (Chewie: 110°)
# 2026-10-27 12:24 – Rechte Spalte und Validator-Banner per eigener Layout-Funktion platziert (lagen teils außerhalb des Bildes)
# 2026-10-27 12:22 – Fix: Vollbild-Anker mit set_anchors_and_offsets_preset (vorher blieb die Fläche 0 px groß → Knüppel und Menüs landeten oben links)
# 2026-10-27 11:08 – Reiter „Technik“ und „Gestaltung“; Motor-Editor wirkt auf das ganze Motorpaar; Knopf „Teilen“; Signal ui_action für ruhige Töne; Modellauswahl inkl. Sammlung
# 2026-10-27 10:42 – Erstversion: Baukasten nach freigegebenem Entwurf
# =============================================================================
# BuilderPanel.gd
# -----------------------------------------------------------------------------
#   ┌ [Hülle][Leitwerk][Antrieb][Gestaltung] ┐  1 Finger drehen ·   ┌Kennwerte┐
#   │  Inhalt des Reiters (scrollbar)        │  2 Finger zoomen     │  …      │
#   │  große Regler mit − / +                │      (3D-Modell)     │ [Teilen]│
#   │                                        │ (λ) [ Validator ]    │ [Fertig]│
#   └────────────────────────────────────────┘                     └─────────┘
#
# Technische Änderungen → ship.rebuild_mass_properties() → Leitwerk wird aus
# ship.tail neu erzeugt, alle Teile neu platziert, Darstellung und Validator
# laufen neu. Gestaltungs-Änderungen malen nur die Hüllentextur neu.
# Drehen/Zoomen der Ansicht übernimmt main.gd (Gesten in der freien Mitte).
# =============================================================================
class_name BuilderPanel
extends Control

signal closed
signal share_requested
signal view_reset_requested
signal pid_requested              ## Regler (PID) einstellen – aus dem Reiter Flight Controller
## Für ruhige Töne: "add", "select", "remove", "ok", "warn"
signal ui_action(kind: String)

const LABEL_W := 120

var ship: AirshipPhysics
var visual: AirshipVisual

var _preset: OptionButton
var _tail_box: VBoxContainer
var _canard_list: ItemList
var _canard_editor: VBoxContainer
var _parts_list: ItemList          ## Motoren (Reiter Antrieb)
var _editor_box: VBoxContainer     ## Motor-Editor
var _look_box: VBoxContainer
var _stats: Label
var _banner: PanelContainer
var _hint: Label
var _view_btn: Button
var _preview: TailPreview
var _hull_rows := {}
var _teensy_check: CheckBox       ## Teensy-Flugcontroller eingebaut
var _flow_win: PanelContainer     ## Fenster Signalfluss
var _flow: FlowDiagram
var _ino_info: Label              ## Ergebnis des .ino-Exports
var _cells_row: Control           ## Akku-Zellen (Stepper)
var _ballast_auto: CheckBox        ## Restmasse automatisch austrimmen
var _mass_info: Label              ## Anzeige Akku + Ballast / Übergewicht
var _last_level := -1
var _file_dialog: FileDialog
var _left: PanelContainer
var _right: PanelContainer


func setup(airship: AirshipPhysics, airship_visual: AirshipVisual) -> void:
	ship = airship
	visual = airship_visual


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE      # Mitte bleibt frei für Drehen/Zoomen

	# ===================== linke Seitenleiste mit Reitern =====================
	_left = UITheme.make_panel(UITheme.size("panel_side_width"))
	add_child(_left)
	var tabs := TabContainer.new()
	tabs.add_theme_font_size_override("font_size", 15)          # fünf Reiter passen nebeneinander
	_left.add_child(tabs)
	tabs.add_child(_scroll_page("Hülle", _build_hull_page))
	tabs.add_child(_scroll_page("Leitwerk", _build_tail_page))
	tabs.add_child(_scroll_page("Antrieb", _build_drive_page))
	tabs.add_child(_scroll_page("Flight Controller", _build_fc_page))
	tabs.add_child(_scroll_page("Optik", _build_look_page))
	tabs.current_tab = 1
	tabs.tab_changed.connect(func(_i): ui_action.emit("select"))

	# ===================== rechte Spalte: Kennwerte ==========================
	_right = UITheme.make_panel(200)
	add_child(_right)
	var rcol := UITheme.make_vbox("sm")
	_right.add_child(rcol)
	# Modellauswahl immer sichtbar (nicht in einem Reiter versteckt)
	rcol.add_child(UITheme.make_title("Luftschiff"))
	_preset = OptionButton.new()
	_preset.custom_minimum_size = Vector2(200, UITheme.size("control_height"))
	_preset.fit_to_longest_item = false
	_preset.clip_text = true
	_preset.item_selected.connect(_on_preset)
	rcol.add_child(_preset)
	reload_model_list()
	rcol.add_child(UITheme.make_title("Kennwerte"))
	_stats = UITheme.make_label("")
	_stats.add_theme_font_size_override("font_size", UITheme.font_size("caption"))
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

	# ===================== Mitte: Hinweis, Ansicht, Heckansicht, Banner =====
	_hint = UITheme.make_label("1 Finger drehen · 2 Finger zoomen", "MutedLabel")
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_view_btn = UITheme.make_pill("Ansicht zurücksetzen", true)
	_view_btn.pressed.connect(func(): view_reset_requested.emit())
	add_child(_view_btn)
	_preview = TailPreview.new()
	_preview.ship = ship
	_preview.custom_minimum_size = Vector2(120, 120)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preview)
	_banner = UITheme.make_banner(420)
	add_child(_banner)

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
	resized.connect(_layout)
	_layout.call_deferred()
	_refresh()


## Rechte Spalte, Hinweis, Knopf, Heckansicht und Banner aus der aktuellen
## Größe platzieren (robuster als Anker).
func _layout() -> void:
	var m := float(UITheme.space("lg"))
	_left.position = Vector2(m, m)
	_left.size = Vector2(UITheme.size("panel_side_width"), size.y - 2.0 * m)
	_right.size = Vector2(_right.get_combined_minimum_size().x, size.y - 2.0 * m)
	_right.position = Vector2(size.x - _right.size.x - m, m)
	var cx0 := _left.position.x + _left.size.x + m        # freie Mitte links
	var cx1 := _right.position.x - m                       # freie Mitte rechts
	_view_btn.size = _view_btn.get_combined_minimum_size()
	_view_btn.position = Vector2(cx1 - _view_btn.size.x, m)
	_hint.size = _hint.get_combined_minimum_size()
	_hint.position = Vector2(cx0, m + _view_btn.size.y + 4.0)      # unter dem Knopf (schmale Mitte)
	_preview.size = _preview.custom_minimum_size
	_preview.position = Vector2(cx0, size.y - _preview.size.y - m)
	_banner.size = _banner.get_combined_minimum_size()
	var bx0 := cx0 + _preview.size.x + m
	if cx1 - bx0 >= _banner.size.x:
		# unten neben der Heckansicht
		_banner.position = Vector2(clampf((cx0 + cx1 - _banner.size.x) * 0.5, bx0, cx1 - _banner.size.x), size.y - _banner.size.y - m)
	else:
		# zu schmal: über der Heckansicht, mittig in der freien Fläche
		_banner.position = Vector2(maxf(cx0, (cx0 + cx1 - _banner.size.x) * 0.5), size.y - _preview.size.y - _banner.size.y - 2.0 * m)


## Freie Mitte zwischen linker und rechter Spalte (für das Zentrieren des
## Luftschiffs in der 3D-Ansicht): x = linker Rand, y = rechter Rand.
func free_span() -> Vector2:
	if _left == null or _right == null:
		return Vector2(0, size.x)
	return Vector2(_left.position.x + _left.size.x, _right.position.x)


func _on_visibility() -> void:
	if visible:
		reload_model_list()
		_sync_from_ship()


## Seite eines Reiters: scrollbar, mit Token-Abständen.
func _scroll_page(title: String, builder: Callable) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := UITheme.make_vbox("md")
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	builder.call(col)
	return sc


# =============================================================================
# Reiter „Hülle“
# =============================================================================
func _build_hull_page(col: VBoxContainer) -> void:
	col.add_child(UITheme.make_title("Hülle"))
	_hull_rows.vol = UITheme.make_slider_row("Volumen", 0.05, 5.0, 0.01, ship.hull.volume_m3,
		func(v): ship.hull.volume_m3 = v, "%.2f m³")
	_hull_rows.ld = UITheme.make_slider_row("Schlankheit L/D", 3.0, 9.0, 0.1, ship.hull.length_to_diameter,
		func(v): ship.hull.length_to_diameter = v, "%.1f")
	_hull_rows.m = UITheme.make_slider_row("Dickste Stelle", 0.30, 0.50, 0.01, ship.hull.m,
		func(v): ship.hull.m = v, "%.2f")
	_hull_rows.cp = UITheme.make_slider_row("Völligkeit", 0.55, 0.72, 0.005, ship.hull.cp,
		func(v): ship.hull.cp = v, "%.3f")
	for k in ["vol", "ld", "m", "cp"]:
		col.add_child(_hull_rows[k])

	# --- Massen: Hülle, Elektronik und die unten angeklebte Restmasse ------
	# Motormassen stehen im Reiter Antrieb (je Motorgondel mit Servo).
	col.add_child(UITheme.make_title("Massen"))
	_hull_rows.hm = UITheme.make_slider_row("Hülle mit Nähten", 10.0, 2000.0, 1.0, ship.hull_mass_kg * 1000.0,
		func(v): ship.hull_mass_kg = v / 1000.0; _changed(), "%d g")
	_hull_rows.el = UITheme.make_slider_row("Elektronik (FC, RX, BEC)", 0.0, 1000.0, 1.0, ship.electronics_mass_kg * 1000.0,
		func(v): ship.electronics_mass_kg = v / 1000.0; _changed(), "%d g")
	col.add_child(_hull_rows.hm)
	col.add_child(_hull_rows.el)
	# Schwere: um wie viel % das Schiff schwerer ist als sein Auftrieb (0 % = schwebt genau)
	_hull_rows.tw = UITheme.make_slider_row("Schwere (0 % = aerostatisch ausgeglichen)", 0.0, 10.0, 0.1, _heaviness_pct(),
		func(v): ship.trim_heaviness_n = v / 100.0 * _buoyancy_n(); _changed(), "%.1f %%")
	col.add_child(_hull_rows.tw)
	_mass_info = UITheme.make_label("", "MutedLabel")
	_mass_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_mass_info)
	_ballast_auto = CheckBox.new()
	_ballast_auto.text = "Restmasse automatisch unter den Auftriebspunkt"
	_ballast_auto.button_pressed = ship.ballast_auto_x
	_ballast_auto.toggled.connect(func(on): ship.ballast_auto_x = on; _changed())
	col.add_child(_ballast_auto)
	# Von Hand verschieben schaltet die Automatik ab
	_hull_rows.bx = UITheme.make_slider_row("Lage der Restmasse (0 Nase · 1 Heck)", 0.05, 0.95, 0.01, ship.ballast_x,
		_on_ballast_x, "%.2f")
	col.add_child(_hull_rows.bx)

	# --- Nutzlast: frei platzierbare Masse außen an der Hülle ----------------
	col.add_child(UITheme.make_title("Nutzlast"))
	_hull_rows.pl = UITheme.make_slider_row("Masse", 0.0, 500.0, 1.0, ship.payload_mass_kg * 1000.0,
		func(v): ship.payload_mass_kg = v / 1000.0; _changed(), "%d g")
	_hull_rows.px = UITheme.make_slider_row("Lage (0 Nase · 1 Heck)", 0.0, 1.0, 0.01, ship.payload_x,
		func(v): ship.payload_x = v; _changed(), "%.2f")
	_hull_rows.pa = UITheme.make_slider_row("Winkel (0° oben · 180° unten)", 0.0, 359.0, 1.0, ship.payload_angle_deg,
		func(v): ship.payload_angle_deg = v; _changed(), "%d°")
	for k in ["pl", "px", "pa"]:
		col.add_child(_hull_rows[k])


## Modellliste aufklappen (Menüpunkt „Modell wählen“ in der Flugansicht).
func open_model_choice() -> void:
	if _preset:
		_preset.show_popup()


## Auswahlliste neu füllen (Presets + Sammlung + eigene Modelle).
func reload_model_list() -> void:
	if _preset == null:
		return
	_preset.clear()
	_preset.add_item("Modell wählen …")
	for p in AirshipPresets.list():
		_preset.add_item(p.name)


# =============================================================================
# Reiter „Leitwerk“ – symmetrische Anordnung + freie Canards
# =============================================================================
func _build_tail_page(col: VBoxContainer) -> void:
	_tail_box = UITheme.make_vbox("md")
	col.add_child(_tail_box)
	col.add_child(UITheme.make_title("Canards (Bug)"))
	var add := UITheme.make_button("+ Canard")
	add.pressed.connect(_add_canard)
	col.add_child(add)
	_canard_list = ItemList.new()
	_canard_list.custom_minimum_size.y = 90
	_canard_list.auto_height = true
	_canard_list.item_selected.connect(func(i): ui_action.emit("select"); _edit_canard(i))
	col.add_child(_canard_list)
	_canard_editor = UITheme.make_vbox("sm")
	col.add_child(_canard_editor)
	_fill_tail_page()


## Leitwerk-Seite neu aufbauen (nur bei Struktur-Änderungen, damit ein
## gerade gezogener Regler nicht verschwindet).
func _fill_tail_page() -> void:
	for c in _tail_box.get_children(): c.queue_free()
	var t := ship.tail
	_tail_box.add_child(UITheme.make_title("Leitwerk"))
	if t == null:
		var info := UITheme.make_label("Dieses Modell hat einzeln gesetzte Flossen (älterer Modell-String).", "MutedLabel")
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tail_box.add_child(info)
		var mk := UITheme.make_button("Symmetrisches Leitwerk anlegen")
		mk.pressed.connect(_create_tail)
		_tail_box.add_child(mk)
		return

	_tail_box.add_child(UITheme.make_label("Anordnung (von hinten gesehen)", "MutedLabel"))
	_tail_box.add_child(UITheme.make_choice_row(TailConfig.LAYOUT_NAMES, t.layout,
		func(i): t.layout = i; _tail_changed(true)))
	if t.layout == TailConfig.Layout.EVEN:
		_tail_box.add_child(UITheme.make_stepper("Anzahl (1–8)", 1, 8, t.count,
			func(v): t.count = v; _tail_changed(false), LABEL_W))
		_tail_box.add_child(UITheme.make_slider_row("Drehung", 0.0, 359.0, 1.0, t.rotation_deg,
			func(v): t.rotation_deg = v; _tail_changed(false), "%d°"))
	elif t.layout == TailConfig.Layout.Y or t.layout == TailConfig.Layout.LAMBDA:
		_tail_box.add_child(UITheme.make_slider_row("V-Winkel (gegen waagrecht)", 0.0, 85.0, 1.0, t.v_angle_deg,
			func(v): t.v_angle_deg = v; _tail_changed(false), "%d°"))

	_tail_box.add_child(UITheme.make_label("Bauart", "MutedLabel"))
	var kind_idx := 1 if t.kind == ControlSurface.Kind.ALL_MOVING else 0
	_tail_box.add_child(UITheme.make_choice_row(["Ruderklappe", "Pendel"], kind_idx,
		func(i): t.kind = ControlSurface.Kind.ALL_MOVING if i == 1 else ControlSurface.Kind.FLAP; _tail_changed(true)))

	var split := CheckBox.new()
	split.text = "Höhen- und Seitenleitwerk getrennt"
	split.button_pressed = t.split_hv
	split.toggled.connect(func(on):
		t.split_hv = on
		if on: t.area_h_m2 = t.area_m2; t.area_v_m2 = t.area_m2
		_tail_changed(true))
	_tail_box.add_child(split)
	if t.split_hv:
		_tail_box.add_child(UITheme.make_slider_row("Fläche Höhenleitwerk (je Flosse)", 20.0, 3000.0, 1.0,
			t.area_h_m2 * 1e4, func(v): t.area_h_m2 = v / 1e4; _tail_changed(false), "%d cm²"))
		_tail_box.add_child(UITheme.make_slider_row("Fläche Seitenleitwerk (je Flosse)", 20.0, 3000.0, 1.0,
			t.area_v_m2 * 1e4, func(v): t.area_v_m2 = v / 1e4; _tail_changed(false), "%d cm²"))
	else:
		_tail_box.add_child(UITheme.make_slider_row("Fläche je Flosse", 20.0, 3000.0, 1.0,
			t.area_m2 * 1e4, func(v): t.area_m2 = v / 1e4; _tail_changed(false), "%d cm²"))
	_tail_box.add_child(UITheme.make_slider_row("Streckung", 0.3, 6.0, 0.1, t.aspect_ratio,
		func(v): t.aspect_ratio = v; _tail_changed(false), "%.1f"))
	_tail_box.add_child(UITheme.make_slider_row("Pfeilung (Endtiefe/Wurzeltiefe)", 0.2, 1.0, 0.05, t.taper,
		func(v): t.taper = v; _tail_changed(false), "%.2f"))
	_tail_box.add_child(UITheme.make_slider_row("Position am Heck", 0.5, 1.0, 0.01, t.hull_x,
		func(v): t.hull_x = v; _tail_changed(false), "%.2f"))
	_tail_box.add_child(UITheme.make_slider_row("Ausschlag max", 0.0, 80.0, 1.0, t.max_deflection_deg,
		func(v): t.max_deflection_deg = v; _tail_changed(false), "%d°"))
	# Eigene Masse je Flosse (mit Servo) – sitzt im Flächenschwerpunkt der Flosse
	_tail_box.add_child(UITheme.make_slider_row("Masse je Flosse (mit Servo)", 0.0, 200.0, 1.0, ship.fin_mass_kg * 1000.0,
		func(v): ship.fin_mass_kg = v / 1000.0; _changed(), "%d g"))
	# Elastisches Leitwerk für beide Bauarten schaltbar (aus = starre Flossen)
	var flex := CheckBox.new()
	flex.text = "Elastisches Leitwerk (Pseudo-Flex) – aus = starr"
	flex.button_pressed = t.pseudo_flex
	flex.toggled.connect(func(on): t.pseudo_flex = on; _tail_changed(false))
	_tail_box.add_child(flex)


func _tail_changed(rebuild_page: bool) -> void:
	_changed()
	if rebuild_page:
		ui_action.emit("select")
		_fill_tail_page()


## Altes Modell: freie Leitwerksflossen durch ein symmetrisches Leitwerk ersetzen.
func _create_tail() -> void:
	var keep: Array[ControlSurface] = []
	for s in ship.surfaces:
		if s.kind == ControlSurface.Kind.CANARD:
			keep.append(s)
	ship.surfaces = keep
	ship.tail = TailConfig.new()
	ui_action.emit("add")
	_changed()
	_fill_tail_page()


func _canards() -> Array[ControlSurface]:
	var out: Array[ControlSurface] = []
	for s in ship.surfaces:
		if not s.tail_member and not s.sail_member:
			out.append(s)
	return out


func _add_canard() -> void:
	var c := AirshipPresets.make_fin("Canard %d" % (_canards().size() + 1), 0.18, 90.0, 0.03, ControlSurface.Kind.CANARD)
	ship.surfaces.append(c)
	_changed()
	ui_action.emit("add")
	var idx := _canards().size() - 1
	_canard_list.select(idx)
	_edit_canard(idx)


func _edit_canard(i: int) -> void:
	for c in _canard_editor.get_children(): c.queue_free()
	var list := _canards()
	if i < 0 or i >= list.size():
		return
	var s: ControlSurface = list[i]
	_canard_editor.add_child(UITheme.make_slider_row("Position", 0.0, 0.5, 0.01, s.hull_x,
		func(v): s.hull_x = v; _changed(), "%.2f"))
	_canard_editor.add_child(UITheme.make_slider_row("Winkel", 0.0, 359.0, 1.0, s.hull_angle_deg,
		func(v): s.hull_angle_deg = v; _changed(), "%d°"))
	_canard_editor.add_child(UITheme.make_slider_row("Fläche", 20.0, 2000.0, 1.0, s.area_m2 * 1e4,
		func(v): s.area_m2 = v / 1e4; _changed(), "%d cm²"))
	_canard_editor.add_child(UITheme.make_slider_row("Masse (mit Servo)", 0.0, 200.0, 1.0, s.mass_kg * 1000.0,
		func(v): s.mass_kg = v / 1000.0; _changed(), "%d g"))
	var del := UITheme.make_button("Canard entfernen")
	del.pressed.connect(func():
		ship.surfaces.erase(s)
		for c in _canard_editor.get_children(): c.queue_free()
		_changed()
		ui_action.emit("remove"))
	_canard_editor.add_child(del)


# =============================================================================
# Reiter „Antrieb“ – Motorpaare
# =============================================================================
func _build_drive_page(col: VBoxContainer) -> void:
	# --- Akku (Teil der Restmasse unten an der Hülle) ---
	col.add_child(UITheme.make_title("Akku"))
	_cells_row = UITheme.make_stepper("Zellen (S)", 1, 12, ship.battery_cells,
		func(v): ship.battery_cells = int(v); _changed(), LABEL_W)
	col.add_child(_cells_row)
	_hull_rows.bmah = UITheme.make_slider_row("Kapazität", 100.0, 5000.0, 10.0, ship.battery_mah,
		func(v): ship.battery_mah = v; _changed(), "%d mAh")
	_hull_rows.bm = UITheme.make_slider_row("Masse", 1.0, 1000.0, 1.0, ship.battery_mass_kg * 1000.0,
		func(v): ship.battery_mass_kg = v / 1000.0; _changed(), "%d g")
	col.add_child(_hull_rows.bmah)
	col.add_child(_hull_rows.bm)
	col.add_child(UITheme.make_title("Motoren"))
	var add := UITheme.make_button("+ Motorpaar")
	add.pressed.connect(_add_motor_pair)
	col.add_child(add)
	_parts_list = ItemList.new()
	_parts_list.custom_minimum_size.y = 90
	_parts_list.auto_height = true
	_parts_list.item_selected.connect(func(i): ui_action.emit("select"); _on_part_selected(i))
	col.add_child(_parts_list)
	_editor_box = UITheme.make_vbox("sm")
	col.add_child(_editor_box)


# =============================================================================
# Reiter „Flight Controller“
# =============================================================================
func _build_fc_page(col: VBoxContainer) -> void:
	col.add_child(UITheme.make_title("Flight Controller"))
	_teensy_check = CheckBox.new()
	_teensy_check.text = "Teensy-Flugcontroller eingebaut"
	_teensy_check.button_pressed = ship.fc_teensy
	_teensy_check.toggled.connect(func(on): ship.fc_teensy = on; _changed())
	col.add_child(_teensy_check)
	_hull_rows.tm = UITheme.make_slider_row("Masse Flugcontroller", 0.0, 100.0, 1.0, ship.teensy_mass_kg * 1000.0,
		func(v): ship.teensy_mass_kg = v / 1000.0; _changed(), "%d g")
	col.add_child(_hull_rows.tm)
	var note := UITheme.make_label("Ohne Flugcontroller gibt es nur „Direkt“: Knüppel gehen ohne Regler auf Ruder und Schwenker. Das Gas bleibt immer beim Piloten.", "MutedLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)
	col.add_child(UITheme.make_title("Regler (PID)"))
	var b := UITheme.make_button("Regler einstellen")
	b.pressed.connect(func(): ui_action.emit("select"); pid_requested.emit())
	col.add_child(b)
	# --- Bausteine: an/aus; feste Sicherheits-Bausteine sind immer an ---
	col.add_child(UITheme.make_title("Bausteine"))
	var fc := ModelCodec._find_fc(ship)
	for blk in FcBlocks.BLOCKS:
		var cb := CheckBox.new()
		cb.text = blk.name + ("  (fest)" if blk.get("fixed", false) else ("  (geplant)" if blk.get("planned", false) else ""))
		cb.tooltip_text = blk.desc
		cb.button_pressed = FcBlocks.is_on(blk.id) or blk.get("fixed", false)
		cb.disabled = blk.get("fixed", false) or blk.get("planned", false) or fc == null
		var bid: String = blk.id
		cb.toggled.connect(func(on):
			FcBlocks.set_on(fc, bid, on)
			ui_action.emit("select")
			if _flow: _flow.queue_redraw())
		col.add_child(cb)
		var d := UITheme.make_label(blk.desc, "MutedLabel")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(d)
	var bf := UITheme.make_button("Signalfluss anzeigen")
	bf.pressed.connect(_show_flow)
	col.add_child(bf)
	# --- Export als Teensy-Sketch (dRehmFlight, Vorlage Chewie BETA 1.4) ---
	col.add_child(UITheme.make_title("Teensy-Sketch"))
	var be := UITheme.make_button("Als .ino exportieren")
	be.pressed.connect(_export_ino)
	col.add_child(be)
	_ino_info = UITheme.make_label("", "MutedLabel")
	_ino_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_ino_info)


## Signalflussbild als Fenster über dem Baukasten.
func _show_flow() -> void:
	if _flow_win == null:
		_flow_win = PanelContainer.new()
		_flow_win.add_theme_stylebox_override("panel", UITheme.box(Color("101720"), Color("2c3746"), -1, 12))
		var v := UITheme.make_vbox("sm")
		var head := UITheme.make_hbox("sm")
		var t := UITheme.make_title("Signalfluss des Reglers")
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(t)
		var close := UITheme.make_button("Schließen")
		close.pressed.connect(func(): _flow_win.visible = false)
		head.add_child(close)
		v.add_child(head)
		_flow = FlowDiagram.new()
		_flow.ship = ship
		_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(_flow)
		_flow_win.add_child(v)
		add_child(_flow_win)
	_flow_win.visible = true
	_flow_win.position = Vector2(size.x * 0.08, size.y * 0.06)
	_flow_win.size = Vector2(size.x * 0.84, size.y * 0.88)
	_flow.queue_redraw()


## Reglerwerte als Teensy-Sketch speichern (Browser: Download).
func _export_ino() -> void:
	var fc := ModelCodec._find_fc(ship)
	if fc == null:
		return
	var warn := InoExport.check(ship)
	var r := InoExport.build(fc, ship.model_name)
	if r.text == "":
		_ino_info.text = "Vorlage nicht gefunden."
		return
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_").left(13)
	var fname := "%s_dRehmFlight_%s.ino" % [ship.model_name.replace(" ", "_").replace("(", "").replace(")", ""), stamp]
	var where := InoExport.save(r.text, fname)
	_ino_info.text = "%s\n%d Werte geändert%s%s" % [where, r.changed.size(),
		("\nNicht gefunden: " + ", ".join(r.missing)) if not r.missing.is_empty() else "", ("\n" + warn) if warn != "" else ""]
	ui_action.emit("ok")


func _add_motor_pair() -> void:
	var pid := "paar%d" % (ship.motors.size() / 2 + 1)
	# Neue Paare sitzen seitlich unten (45° unter der Waagrechten) – wie Chewie
	var r := AirshipPresets.make_motor("Motor rechts (%s)" % pid, 0.25, 135.0, 1.2, 60.0, 45.0)
	var l := AirshipPresets.make_motor("Motor links (%s)" % pid, 0.25, 225.0, 1.2, 60.0, 45.0)
	r.pair_id = pid; l.pair_id = pid
	r.spin_dir = 1; l.spin_dir = -1                 # gegenläufig
	ship.motors.append(r)
	ship.motors.append(l)
	_changed()
	ui_action.emit("add")


## Alle Motoren desselben Paares (oder nur dieser, wenn ohne pair_id).
func _pair_of(mo: VectorMotor) -> Array[VectorMotor]:
	var out: Array[VectorMotor] = []
	for m in ship.motors:
		if m == mo or (mo.pair_id != "" and m.pair_id == mo.pair_id):
			out.append(m)
	return out


func _clear_editor() -> void:
	if _editor_box:
		for c in _editor_box.get_children(): c.queue_free()


## Editor für Motor i (Index in ship.motors).
func _on_part_selected(i: int) -> void:
	_clear_editor()
	if i < 0 or i >= ship.motors.size():
		return
	var mo: VectorMotor = ship.motors[i]
	var pair := _pair_of(mo)
	_editor_box.add_child(UITheme.make_title(mo.display_name))
	# Lage: Paare bleiben immer spiegelbildlich zur Längsachse (Partner: gleiche
	# Längslage, Winkel 360° − Winkel). Einzelmotoren sitzen oben oder unten.
	_editor_box.add_child(UITheme.make_label("Lage (Paar spiegelbildlich)" if pair.size() > 1 else "Lage", "MutedLabel"))
	_editor_box.add_child(UITheme.make_slider_row("Position", 0.0, 1.0, 0.01, mo.hull_x,
		func(v):
			for m in pair: m.hull_x = v
			_changed(), "%.2f"))
	if pair.size() > 1:
		_editor_box.add_child(UITheme.make_slider_row("Winkel", 0.0, 359.0, 1.0, mo.hull_angle_deg,
			func(v):
				mo.hull_angle_deg = v
				for m in pair:
					if m != mo: m.hull_angle_deg = fposmod(360.0 - v, 360.0)
				_changed(), "%d°"))
	else:
		_editor_box.add_child(UITheme.make_choice_row(["oben", "unten"], 0 if absf(mo.hull_angle_deg) < 90.0 or mo.hull_angle_deg > 270.0 else 1,
			func(k): mo.hull_angle_deg = 0.0 if k == 0 else 180.0; _changed()))
	_editor_box.add_child(UITheme.make_label(
		"Für das Paar (%d Motoren)" % pair.size() if pair.size() > 1 else "Antrieb", "MutedLabel"))
	var set_all := func(prop: String, v, relayout: bool):
		for m in pair: m.set(prop, v)
		if relayout: _changed()
	_editor_box.add_child(UITheme.make_slider_row("Masse je Gondel (mit Servo)", 0.0, 300.0, 1.0, mo.mass_kg * 1000.0,
		func(v): set_all.call("mass_kg", v / 1000.0, true), "%d g"))
	# Schubrichtung als Vektor (x vorn, y rechts, z unten); der Partner im Paar
	# bekommt y gespiegelt, damit das Paar symmetrisch bleibt
	_editor_box.add_child(UITheme.make_label("Schubrichtung (x vorn · y rechts · z unten)", "MutedLabel"))
	var ud := mo.user_dir()
	for ci in 3:
		var comp := ci
		_editor_box.add_child(UITheme.make_slider_row(["x", "y", "z"][ci], -1.0, 1.0, 0.05, [ud.x, ud.y, ud.z][ci],
			func(v):
				var u := mo.user_dir()
				u[comp] = v
				mo.set_user_dir(u)
				for m in pair:
					if m != mo: m.set_user_dir(Vector3(u.x, -u.y, u.z))
				_changed(), "%.2f"))
	_editor_box.add_child(UITheme.make_slider_row("Schub vor", 0.1, 20.0, 0.1, mo.max_thrust_n,
		func(v): set_all.call("max_thrust_n", v, true), "%.1f N"))
	var rev := CheckBox.new()
	rev.text = "Rückwärtsschub erlaubt"
	rev.button_pressed = mo.reverse_allowed
	rev.toggled.connect(func(on): set_all.call("reverse_allowed", on, true))
	_editor_box.add_child(rev)
	_editor_box.add_child(UITheme.make_slider_row("Wirkung rückwärts (normal ≈ 0,55 · 3D ≈ 0,95)", 0.1, 1.0, 0.05,
		mo.reverse_efficiency, func(v): set_all.call("reverse_efficiency", v, false), "%.2f"))
	_editor_box.add_child(UITheme.make_slider_row("Schwenk max", 0.0, 120.0, 1.0, mo.max_swivel_deg,
		func(v): set_all.call("max_swivel_deg", v, false), "%d°"))
	# Negativ = Schub schwenkt radial zur Hüllenmitte (Chewie), positiv = entlang der Hülle (rollt stark)
	_editor_box.add_child(UITheme.make_slider_row("Achsneigung (Pigleg, − = radial)", -60.0, 60.0, 1.0, mo.swivel_tilt_deg,
		func(v): set_all.call("swivel_tilt_deg", v, true), "%d°"))
	_editor_box.add_child(UITheme.make_label("Propeller", "MutedLabel"))
	_editor_box.add_child(UITheme.make_slider_row("Durchmesser", 2.0, 15.0, 0.5, mo.prop_diameter_in,
		func(v): set_all.call("prop_diameter_in", v, false), "%.1f\""))
	_editor_box.add_child(UITheme.make_slider_row("Steigung", 1.0, 10.0, 0.1, mo.prop_pitch_in,
		func(v): set_all.call("prop_pitch_in", v, false), "%.1f\""))
	_editor_box.add_child(UITheme.make_stepper("Blätter", 2, 6, mo.prop_blades,
		func(v): set_all.call("prop_blades", v, false), LABEL_W))
	_editor_box.add_child(UITheme.make_slider_row("Drehzahl max", 3000.0, 40000.0, 500.0, mo.max_rpm,
		func(v): set_all.call("max_rpm", v, false), "%d U/min"))
	_editor_box.add_child(UITheme.make_label("Drehrichtung (nur dieser Motor)", "MutedLabel"))
	_editor_box.add_child(UITheme.make_choice_row(["CW", "CCW"], 0 if mo.spin_dir > 0 else 1,
		func(k): mo.spin_dir = 1 if k == 0 else -1))
	var del := UITheme.make_button("Motorpaar entfernen" if pair.size() > 1 else "Motor entfernen")
	del.pressed.connect(func():
		for m in pair: ship.motors.erase(m)
		_clear_editor()
		_changed()
		ui_action.emit("remove"))
	_editor_box.add_child(del)


# =============================================================================
# Reiter „Optik“
# =============================================================================
const HULL_SWATCHES := ["dfe5ea", "e5534b", "3d8bfd", "2b2f36", "e0a43a", "3fb27f"]
const TEXT_SWATCHES := ["1b2128", "ffffff", "e5534b", "3d8bfd"]

func _build_look_page(col: VBoxContainer) -> void:
	_look_box = col
	_fill_look_page()


func _fill_look_page() -> void:
	for c in _look_box.get_children(): c.queue_free()
	var l := ship.livery
	# Hülle: Material, bei „Farbe“ zusätzlich die Farbe
	_look_box.add_child(UITheme.make_title("Hülle"))
	_look_box.add_child(_choice_grid(Livery.HULL_MATERIAL_NAMES, maxi(Livery.HULL_MATERIALS.find(l.material), 0),
		func(k): l.material = Livery.HULL_MATERIALS[k]; _fill_look_page.call_deferred()))
	if l.material == "farbe":
		_look_box.add_child(_swatch_row(HULL_SWATCHES, l.hull_color, func(c): l.hull_color = c))
	# Leitwerk: eigenes Material und eigene Farbe
	_look_box.add_child(UITheme.make_title("Leitwerk"))
	_look_box.add_child(_choice_grid(Livery.FIN_MATERIAL_NAMES, maxi(Livery.FIN_MATERIALS.find(l.fin_material), 0),
		func(k): l.fin_material = Livery.FIN_MATERIALS[k]; _fill_look_page.call_deferred()))
	if l.fin_material == "farbe":
		_look_box.add_child(_swatch_row(HULL_SWATCHES, l.fin_color, func(c): l.fin_color = c))

	_look_box.add_child(UITheme.make_title("Schriftzug"))
	var te := LineEdit.new()
	te.placeholder_text = "CHEWIE"
	te.text = l.text
	te.max_length = 24
	te.custom_minimum_size.y = UITheme.size("control_height")
	te.text_changed.connect(func(t): l.text = t)
	_look_box.add_child(te)
	_look_box.add_child(_swatch_row(TEXT_SWATCHES, l.text_color, func(c): l.text_color = c))
	_look_box.add_child(UITheme.make_slider_row("Schriftgröße", 0.1, 0.6, 0.01, l.text_size,
		func(v): l.text_size = v, "%.2f"))
	_look_box.add_child(UITheme.make_slider_row("Lage (Nase → Heck)", 0.1, 0.9, 0.01, l.text_pos,
		func(v): l.text_pos = v, "%.2f"))

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
	_look_box.add_child(UITheme.make_slider_row("Logogröße", 0.1, 0.8, 0.01, l.logo_size,
		func(v): l.logo_size = v, "%.2f"))
	_look_box.add_child(UITheme.make_slider_row("Logolage (Nase → Heck)", 0.05, 0.9, 0.01, l.logo_pos,
		func(v): l.logo_pos = v, "%.2f"))
	var both := CheckBox.new()
	both.text = "Beidseitig"
	both.button_pressed = l.both_sides
	both.toggled.connect(func(on): l.both_sides = on)
	_look_box.add_child(both)


## Farbfelder + freie Farbwahl; on_pick(Color) beim Antippen.
## Auswahl in zwei Spalten (passt in die schmale Seitenleiste). on_pick(index).
func _choice_grid(labels: Array, selected: int, on_pick: Callable) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", UITheme.space("xs"))
	g.add_theme_constant_override("v_separation", UITheme.space("xs"))
	var grp := UITheme.make_toggle_group()
	for i in labels.size():
		var b := UITheme.make_pill(labels[i], true)
		b.toggle_mode = true
		b.button_group = grp
		b.button_pressed = i == selected
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		b.pressed.connect(func(): on_pick.call(idx))
		g.add_child(b)
	return g


func _swatch_row(hexes: Array, current: Color, on_pick: Callable) -> HBoxContainer:
	var row := UITheme.make_hbox("xs")
	var d := float(UITheme.size("control_height"))
	for hx in hexes:
		var c := Color(hx)
		var b := Button.new()
		b.custom_minimum_size = Vector2(d, d)
		b.focus_mode = Control.FOCUS_NONE
		var sel := c.is_equal_approx(current)
		b.add_theme_stylebox_override("normal", UITheme.box(c, UITheme.color("accent") if sel else UITheme.color("border_strong"), UITheme.radius("sm"), 0))
		b.add_theme_stylebox_override("hover", UITheme.box(c, UITheme.color("accent"), UITheme.radius("sm"), 0))
		b.add_theme_stylebox_override("pressed", UITheme.box(c, UITheme.color("accent"), UITheme.radius("sm"), 0))
		b.pressed.connect(func(): on_pick.call(c); ui_action.emit("select"); _fill_look_page())
		row.add_child(b)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(d, d)
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
# Anzeige aktualisieren: Listen, Kennwerte, Validator, Heckansicht
# =============================================================================
func _refresh() -> void:
	if not is_inside_tree() or _parts_list == null:
		return
	var sel := _parts_list.get_selected_items()
	_parts_list.clear()
	for mo in ship.motors:
		_parts_list.add_item("%s  ·  %.1f N%s" % [mo.display_name, mo.max_thrust_n, "  ⇄" if mo.reverse_allowed else ""])
	if sel.size() > 0 and sel[0] < _parts_list.item_count:
		_parts_list.select(sel[0])
	var csel := _canard_list.get_selected_items()
	_canard_list.clear()
	for c in _canards():
		_canard_list.add_item("%s  ·  %d cm²" % [c.display_name, roundi(c.area_m2 * 1e4)])
	if csel.size() > 0 and csel[0] < _canard_list.item_count:
		_canard_list.select(csel[0])

	var r := TailValidator.validate(ship.hull, ship.surfaces, ship.cg_offset)
	var h := ship.hull
	_stats.text = "%s\n%.2f × %.2f m\nV_T Nick %.2f\nV_T Gier %.2f\nStab. Nick %.2f\nStab. Gier %.2f\nMasse %.0f g (ohne Helium)" % [
		ship.model_name, h.length_m, h.diameter_m, r.vt_pitch, r.vt_yaw, r.ratio_pitch, r.ratio_yaw,
		ship.structure_mass_kg * 1000.0]
	_update_mass_info()
	var level := "success"
	if r.level == TailValidator.Level.UNSTABLE: level = "danger"
	elif r.level == TailValidator.Level.MARGINAL: level = "warning"
	UITheme.set_banner(_banner, r.message + ("  " + r.detail if r.detail != "" else ""), level)
	if r.level == TailValidator.Level.UNSTABLE and _last_level != r.level and _last_level != -1:
		ui_action.emit("warn")                        # leiser Hinweiston beim Kippen ins Instabile
	_last_level = r.level
	if visual:
		visual.set_validation_level(r.level)
	_preview.queue_redraw()
	_layout.call_deferred()


func _changed() -> void:
	ship.rebuild_mass_properties()     # erzeugt Leitwerk, platziert, löst config_changed → _refresh aus


## Regler auf das aktuelle Modell setzen (nach Modellwechsel/Import).
func _sync_from_ship() -> void:
	var vals := {"vol": ship.hull.volume_m3, "ld": ship.hull.length_to_diameter,
		"m": ship.hull.m, "cp": ship.hull.cp, "hm": ship.hull_mass_kg * 1000.0,
		"el": ship.electronics_mass_kg * 1000.0, "bx": ship.ballast_x, "tw": _heaviness_pct(),
		"pl": ship.payload_mass_kg * 1000.0, "px": ship.payload_x, "pa": ship.payload_angle_deg,
		"bmah": ship.battery_mah, "bm": ship.battery_mass_kg * 1000.0, "tm": ship.teensy_mass_kg * 1000.0}
	var fmts := {"vol": "%.2f m³", "ld": "%.1f", "m": "%.2f", "cp": "%.3f", "hm": "%d g", "el": "%d g", "bx": "%.2f",
		"tw": "%.1f %%", "pl": "%d g", "px": "%.2f", "pa": "%d°", "bmah": "%d mAh", "bm": "%d g", "tm": "%d g"}
	_teensy_check.set_pressed_no_signal(ship.fc_teensy)
	(_cells_row.get_meta("out") as Label).text = str(ship.battery_cells)
	_ballast_auto.set_pressed_no_signal(ship.ballast_auto_x)
	for k in vals:
		(_hull_rows[k].get_meta("slider") as HSlider).set_value_no_signal(vals[k])
		(_hull_rows[k].get_meta("out") as Label).text = fmts[k] % vals[k]
	_clear_editor()
	for c in _canard_editor.get_children(): c.queue_free()
	_fill_tail_page()
	_fill_look_page()
	_refresh()


## Auftrieb der Hülle in N (ρ_Luft · V · g) – Bezug für die Schwere in %.
func _buoyancy_n() -> float:
	return ship.air_density * ship.hull.volume_m3 * ship.gravity_mps2


## Aktuelle Schwere in % des Auftriebs.
func _heaviness_pct() -> float:
	return ship.trim_heaviness_n / maxf(_buoyancy_n(), 1e-6) * 100.0


## Regler „Lage der Restmasse“: Wert übernehmen, Automatik abschalten.
func _on_ballast_x(v: float) -> void:
	ship.ballast_x = v
	if ship.ballast_auto_x:
		ship.ballast_auto_x = false
		_ballast_auto.set_pressed_no_signal(false)
	_changed()


## Massenanzeige im Reiter Hülle: Restmasse aus dem Auftrieb, Schwerpunkt,
## Warnung bei Übergewicht; Lage-Regler folgt der Automatik.
func _update_mass_info() -> void:
	if _mass_info == null:
		return
	var cg := ship.cg_offset
	if ship.overweight:
		_mass_info.text = "Zu schwer: Hülle, Motoren und Elektronik wiegen mehr, als der Auftrieb trägt."
		_mass_info.add_theme_color_override("font_color", UITheme.color("danger"))
	else:
		_mass_info.text = "Akku %d g + Ballast %d g (aus dem Auftrieb) · unten an der Hülle\nSchwerpunkt %d cm unter der Achse · Gesamt %d g ohne Helium" % [
			roundi(ship.battery_mass_kg * 1000.0), roundi(maxf(ship.ballast_kg, 0.0) * 1000.0), roundi(-cg.y * 100.0), roundi(ship.structure_mass_kg * 1000.0)]
		_mass_info.remove_theme_color_override("font_color")
		if ship.ballast_kg < 0.0:
			_mass_info.text = "Akku zu schwer: %d g mehr, als der Auftrieb trägt (Rest nur %d g)." % [
				roundi(-ship.ballast_kg * 1000.0), roundi(ship.rest_mass_kg * 1000.0)]
			_mass_info.add_theme_color_override("font_color", UITheme.color("danger"))
	var bx: HSlider = _hull_rows.bx.get_meta("slider")
	bx.set_value_no_signal(ship.ballast_x)
	(_hull_rows.bx.get_meta("out") as Label).text = "%.2f" % ship.ballast_x


func _on_preset(idx: int) -> void:
	if idx <= 0:
		return
	AirshipPresets.list()[idx - 1].build.call(ship)
	ship.model_applied.emit()          # Flugcontroller übernimmt die PID-Vorgaben des Modells
	_preset.select(0)
	ui_action.emit("ok")
	_sync_from_ship()


# =============================================================================
# Heckansicht: zeigt die Anordnung der Flossen (von hinten)
# =============================================================================
class TailPreview:
	extends Control
	var ship: AirshipPhysics

	func _draw() -> void:
		if ship == null:
			return
		var c := size * 0.5
		draw_circle(c, size.x * 0.48, Color(UITheme.color("surface"), 0.85))
		var r := size.x * 0.16
		draw_circle(c, r, UITheme.color("surface_alt"))
		draw_arc(c, r, 0.0, TAU, 32, UITheme.color("text_muted"), 1.5, true)
		var max_span := 0.001
		for s in ship.surfaces:
			if s.tail_member: max_span = maxf(max_span, s.span_m())
		for s in ship.surfaces:
			if not s.tail_member:
				continue
			var a := deg_to_rad(s.hull_angle_deg)
			var d := Vector2(sin(a), -cos(a))           # Bildschirm: y nach unten
			var l := size.x * 0.30 * s.span_m() / max_span
			draw_line(c + d * r, c + d * (r + l), UITheme.color("accent"), 5.0, true)
		var f := get_theme_default_font()
		var txt := "Heckansicht"
		var fs := UITheme.font_size("caption") - 2
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(c.x - w * 0.5, size.y - 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.color("text_muted"))
