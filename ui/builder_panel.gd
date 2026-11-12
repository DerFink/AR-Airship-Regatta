# 2026-11-12 22:30 – Kleinere Schrift (compact_theme); Anzahl Flossen immer wählbar (andere Zahl → Anordnung „gleichmäßig“)
# 2026-11-13 03:10 – Flossen einzeln einstellen (Bauart fest/Klappe/Pendel, Fläche, Streckung, Pfeilung, Klappentiefe, Ausschlag; symmetrisch); Restmasse in den Kennwerten
# 2026-11-12 23:10 – Reiter „Steuerung“ (statt Flight Controller): ① Mischer (Tabelle von Hand, Vorschlag aus Einbaulage) ② FC einbauen ③ Regler ④ Bausteine (Untermenü); ohne FC ausgegraut; Teensy-Sketch nur noch unter „Admin“; Leitwerk 2–10 Flossen, Klappentiefe; Motor „schwenkbar“ + Abstand zur Hülle; Akku an eigener Stelle; Name + Kurzbeschreibung; beginnt bei der Hülle
# 2026-11-12 20:45 – Knopf „Zurücksetzen“ (zwischen Einstellungen und Teilen) mit Auswahl: Luftschiff, Regler, Sender, Knüppelbelegung + Strecke
# 2026-11-12 12:50 – Zahlenfelder statt Schieberegler (Regler nur noch für Lagen); Volumen ohne Obergrenze; Hüllenmasse berechnet (Folie g/m² + 7 %); Flossen/Canards: Gewichtsvorschlag Depron + Pauschale, eigenes Gewicht überschreibt (Vorschlag ausgegraut); Propeller in Zoll/cm/mm ab 2 cm; Rennfaktor F7B bei den Kennwerten; Schrift/Logo auch aufs Leitwerk; Logo laden im Browser über die Dateiauswahl des Geräts, am Handy aus Download/Bilder
# 2026-11-11 19:45 – Bug-/Hecklastigkeit: Ansicht pendelt auf den Hängewinkel, roter Hinweis ab 2°; Stabilitätsmaß und Leitwerkswarnung nur im Reiter Leitwerk, Kennwerte rechts nur Maße und Masse
# 2026-11-11 17:50 – Knopf „⚙ Einstellungen“ über „Teilen“
# 2026-11-11 17:45 – Alle Texte übersetzt (I18n.t), Kennwerte und Profilangaben mit Dezimalzeichen je Sprache, Sketch-Hinweise übersetzt (Kopfzeile im Sketch bleibt Deutsch)
# 2026-11-11 08:25 – Profil-Kennwerte bei 3 und 9 m/s mit Reynoldszahl
# 2026-11-11 07:40 – Leitwerk und Canards: Profil (Brettchen/NACA 00xx) mit Dicke, Kennwerte und Gewichts-Schätzung; „Endgewicht“ je Flosse/Canard
# 2026-11-11 14:20 – .ino-Export: Mischer aus dem Modell (an/aus), Kanalzuordnung des Senders (an/aus), Hinweise zur Ausgangsbelegung
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
signal settings_requested          ## ⚙ → Einstellungen
## „Zurücksetzen“: opts = {"ship", "fc", "sender", "sticks"} (je true/false), main.gd führt aus
signal reset_requested(opts: Dictionary)
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
var _trim_banner: PanelContainer          ## rot: „Hecklastig“ / „Buglastig“ (Schwerpunkt nicht unter dem Auftriebspunkt)
var _tabs: TabContainer
const TAB_TAIL := 1                       ## Reiter „Leitwerk“: nur dort Stabilitätsmaß und Leitwerkswarnung
const TRIM_WARN_DEG := 2.0                ## ab diesem Hängewinkel gilt das Schiff als bug-/hecklastig
var _hint: Label
var _view_btn: Button
var _preview: TailPreview
var _hull_rows := {}
var _teensy_check: CheckBox       ## FC einbauen (Teensy 4.0)
var _b_pid: Button                ## „Regler einstellen“ (ausgegraut ohne FC)
var _b_blocks: Button             ## „Bausteine einstellen“ (ausgegraut ohne FC)
var _flow_win: PanelContainer     ## Fenster Signalfluss
var _flow: FlowDiagram
var _ino_info: Label              ## Ergebnis des .ino-Exports
var _ino_mixer: CheckBox          ## Mischer parametrisch erzeugen
var _ino_ch: CheckBox             ## Kanalzuordnung des Senders übernehmen
var _cells_row: Control           ## Akku-Zellen (Stepper)
var _ballast_auto: CheckBox        ## Restmasse automatisch austrimmen
var _mass_info: Label              ## Anzeige Akku + Ballast / Übergewicht
var _hull_mass_lbl: Label          ## „Hülle 79 g · Oberfläche … × 27 g/m² + 7 %“
var _fin_mass_lbl: Label           ## Vorschlag Flossengewicht (ausgegraut, wenn von Hand)
var _canard_mass_lbl: Label        ## Vorschlag Canardgewicht
var _canard_sel: ControlSurface    ## gerade bearbeiteter Canard
## Einheit der Propellerangaben: 0 = Zoll, 1 = cm, 2 = mm (gilt für Durchmesser und Steigung)
static var prop_unit := 0
const PROP_UNITS := ["Zoll", "cm", "mm"]
const PROP_FACTOR := [1.0, 2.54, 25.4]
var _last_level := -1
var _file_dialog: FileDialog
var _factor_lbl: Label                ## „Rennfaktor F7B ×0,72“ unter den Kennwerten
var _name_edit: LineEdit              ## Name des Modells (Reiter Hülle)
var _desc_edit: TextEdit              ## Kurzbeschreibung (bis 100 Zeichen)
var _desc_count: Label                ## „62 / 100“
var _bat_own: CheckBox                ## „Akku an eigener Stelle“
var _bat_x: Control                   ## Regler „Lage Akku“
var _reset_dlg: Control               ## Fenster „Zurücksetzen“ (Auswahl mit Häkchen)
var _reset_checks := {}               ## "ship"/"fc"/"sender"/"sticks" → CheckBox
var _reset_ship_lbl: Label            ## Beschriftung „Dieses Luftschiff („Chewie“)“
var _left: PanelContainer
var _right: PanelContainer


func setup(airship: AirshipPhysics, airship_visual: AirshipVisual) -> void:
	ship = airship
	visual = airship_visual


func _ready() -> void:
	theme = UITheme.compact_theme()                     # kleinere Schrift im Baukasten (Wunsch 12.11.2026)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE      # Mitte bleibt frei für Drehen/Zoomen

	# ===================== linke Seitenleiste mit Reitern =====================
	_left = UITheme.make_panel(UITheme.size("panel_side_width"))
	add_child(_left)
	var tabs := TabContainer.new()
	tabs.add_theme_font_size_override("font_size", 14)          # fünf Reiter passen nebeneinander
	tabs.clip_tabs = false                                      # alle Reiter immer sichtbar (Seitenleiste wird breit genug)
	_left.add_child(tabs)
	tabs.add_child(_scroll_page("Hülle", _build_hull_page))
	tabs.add_child(_scroll_page("Leitwerk", _build_tail_page))
	tabs.add_child(_scroll_page("Antrieb", _build_drive_page))
	tabs.add_child(_scroll_page("Steuerung", _build_fc_page))
	tabs.add_child(_scroll_page("Optik", _build_look_page))
	tabs.current_tab = 0                                       # Baukasten beginnt bei der Hülle
	_tabs = tabs
	tabs.tab_changed.connect(func(_i):
		ui_action.emit("select")
		_banner.visible = tabs.current_tab == TAB_TAIL    # Stabilität nur im Reiter Leitwerk
		_layout.call_deferred())

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
	# Rennfaktor (F7B): Zahl, mit der die gemessene Zeit malgenommen wird
	_factor_lbl = UITheme.make_label("")
	_factor_lbl.add_theme_font_size_override("font_size", UITheme.font_size("caption"))
	_factor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcol.add_child(_factor_lbl)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(spacer)
	var b_set := UITheme.make_button("Einstellungen")
	b_set.icon = load("res://textures/zahnrad.svg")
	b_set.add_theme_constant_override("icon_max_width", 24)
	b_set.pressed.connect(func(): settings_requested.emit())
	rcol.add_child(b_set)
	# Zurücksetzen: Auswahl, was wieder wie ab Werk sein soll (Fenster _reset_dlg)
	var b_reset := UITheme.make_button("Zurücksetzen")
	b_reset.pressed.connect(_open_reset)
	rcol.add_child(b_reset)
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
	_trim_banner = UITheme.make_banner(420)
	_trim_banner.visible = false
	add_child(_trim_banner)

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
	_trim_banner.size = _trim_banner.get_combined_minimum_size()
	_trim_banner.position = Vector2((cx0 + cx1 - _trim_banner.size.x) * 0.5, _hint.position.y + _hint.size.y + m)
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
		_tabs.current_tab = 0                                  # immer mit der Hülle beginnen


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
	# --- Name und Kurzbeschreibung des Modells ---
	col.add_child(UITheme.make_title("Luftschiff"))
	col.add_child(UITheme.make_label("Name", "MutedLabel"))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 40
	_name_edit.custom_minimum_size.y = UITheme.size("control_height")
	_name_edit.text_changed.connect(func(t): ship.model_name = t; _refresh())
	col.add_child(_name_edit)
	col.add_child(UITheme.make_label("Kurzbeschreibung (bis 100 Zeichen)", "MutedLabel"))
	_desc_edit = TextEdit.new()
	_desc_edit.custom_minimum_size.y = 72
	_desc_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_desc_count = UITheme.make_label("0 / 100", "MutedLabel")
	_desc_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_desc_edit.text_changed.connect(func():
		var t := _desc_edit.text.replace("\n", " ")
		if t.length() > 100:                       # höchstens 100 Zeichen
			t = t.left(100)
			_desc_edit.text = t
			_desc_edit.set_caret_column(t.length())
		ship.model_description = t
		_desc_count.text = "%d / 100" % t.length())
	col.add_child(_desc_edit)
	col.add_child(_desc_count)
	col.add_child(UITheme.make_title("Hülle"))
	# Zahlenfelder; Schieberegler nur für Lagen (hier: Dickste Stelle)
	_hull_rows.vol = UITheme.make_number_row("Volumen", 0.01, INF, 0.01, ship.hull.volume_m3,
		func(v): ship.hull.volume_m3 = v, "%.2f m³")
	_hull_rows.ld = UITheme.make_number_row("Schlankheit L/D", 3.0, 9.0, 0.1, ship.hull.length_to_diameter,
		func(v): ship.hull.length_to_diameter = v, "%.1f")
	_hull_rows.m = UITheme.make_slider_row("Dickste Stelle", 0.30, 0.50, 0.01, ship.hull.m,
		func(v): ship.hull.m = v, "%.2f")
	_hull_rows.cp = UITheme.make_number_row("Völligkeit", 0.55, 0.72, 0.005, ship.hull.cp,
		func(v): ship.hull.cp = v, "%.3f")
	for k in ["vol", "ld", "m", "cp"]:
		col.add_child(_hull_rows[k])

	# --- Massen: Hülle, Elektronik und die unten angeklebte Restmasse ------
	# Motormassen stehen im Reiter Antrieb (je Motorgondel mit Servo).
	col.add_child(UITheme.make_title("Massen"))
	# Hülle: berechnet aus Oberfläche × Folie (Standard 27 g/m²) + 7 % (Nähte, Ränder, Ventil)
	_hull_rows.hf = UITheme.make_number_row("Hüllenfolie (Flächengewicht)", 1.0, 1000.0, 1.0, ship.hull_film_kg_m2 * 1000.0,
		func(v): ship.hull_film_kg_m2 = v / 1000.0; _changed(), "%d g/m²")
	col.add_child(_hull_rows.hf)
	_hull_mass_lbl = UITheme.make_label("")
	_hull_mass_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_hull_mass_lbl)
	_hull_rows.el = UITheme.make_number_row("Elektronik (FC, RX, BEC)", 0.0, 1000.0, 1.0, ship.electronics_mass_kg * 1000.0,
		func(v): ship.electronics_mass_kg = v / 1000.0; _changed(), "%d g")
	col.add_child(_hull_rows.el)
	# Schwere: um wie viel % das Schiff schwerer ist als sein Auftrieb (0 % = schwebt genau)
	_hull_rows.tw = UITheme.make_number_row("Schwere (0 % = aerostatisch ausgeglichen)", 0.0, 10.0, 0.1, _heaviness_pct(),
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
	_hull_rows.pl = UITheme.make_number_row("Masse", 0.0, 50000.0, 1.0, ship.payload_mass_kg * 1000.0,
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
	# Anzahl Flossen immer wählbar: bei +, ×, Y, λ ist sie durch die Anordnung
	# fest – eine andere Zahl stellt auf „gleichmäßig“ um
	_tail_box.add_child(UITheme.make_stepper("Anzahl Flossen (2–10)", 2, 10, t.angles().size(),
		func(v):
			if t.layout != TailConfig.Layout.EVEN:
				t.layout = TailConfig.Layout.EVEN
			t.count = v
			_tail_changed(true), LABEL_W))
	if t.layout == TailConfig.Layout.EVEN:
		_tail_box.add_child(UITheme.make_slider_row("Drehung", 0.0, 359.0, 1.0, t.rotation_deg,
			func(v): t.rotation_deg = v; _tail_changed(false), "%d°"))
	elif t.layout == TailConfig.Layout.Y or t.layout == TailConfig.Layout.LAMBDA:
		_tail_box.add_child(UITheme.make_number_row("V-Winkel (gegen waagrecht)", 0.0, 85.0, 1.0, t.v_angle_deg,
			func(v): t.v_angle_deg = v; _tail_changed(false), "%d°"))

	# Flossen einzeln (z. B. λ mit kleiner fester Finne oben) oder alle gleich
	var ind := CheckBox.new()
	ind.text = "Flossen einzeln einstellen"
	ind.button_pressed = t.individual
	ind.toggled.connect(func(on):
		t.individual = on
		if on:
			t.fin_cfg = []
			t.ensure_fin_cfg()                        # Start: die gemeinsamen Werte
		_tail_changed(true))
	_tail_box.add_child(ind)
	if t.individual:
		_fin_blocks(t)
	else:
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
			_tail_box.add_child(UITheme.make_number_row("Fläche Höhenleitwerk (je Flosse)", 5.0, 100000.0, 1.0,
				t.area_h_m2 * 1e4, func(v): t.area_h_m2 = v / 1e4; _tail_changed(false), "%d cm²"))
			_tail_box.add_child(UITheme.make_number_row("Fläche Seitenleitwerk (je Flosse)", 5.0, 100000.0, 1.0,
				t.area_v_m2 * 1e4, func(v): t.area_v_m2 = v / 1e4; _tail_changed(false), "%d cm²"))
		else:
			_tail_box.add_child(UITheme.make_number_row("Fläche je Flosse", 5.0, 100000.0, 1.0,
				t.area_m2 * 1e4, func(v): t.area_m2 = v / 1e4; _tail_changed(false), "%d cm²"))
		_tail_box.add_child(UITheme.make_number_row("Streckung", 0.3, 6.0, 0.1, t.aspect_ratio,
			func(v): t.aspect_ratio = v; _tail_changed(false), "%.1f"))
		_tail_box.add_child(UITheme.make_number_row("Pfeilung (Endtiefe/Wurzeltiefe)", 0.2, 1.0, 0.05, t.taper,
			func(v): t.taper = v; _tail_changed(false), "%.2f"))
	_tail_box.add_child(UITheme.make_slider_row("Position am Heck", 0.5, 1.0, 0.01, t.hull_x,
		func(v): t.hull_x = v; _tail_changed(false), "%.2f"))
	if not t.individual:
		if t.kind == ControlSurface.Kind.FLAP:
			# Klappentiefe: nur der hintere Teil der Flosse dreht (wirkt schwächer als ein Pendelruder)
			_tail_box.add_child(UITheme.make_number_row("Klappentiefe (Anteil der Flossentiefe)", 10.0, 60.0, 1.0, t.flap_chord_ratio * 100.0,
				func(v): t.flap_chord_ratio = v / 100.0; _tail_changed(false), "%d %%"))
		_tail_box.add_child(UITheme.make_number_row("Ausschlag max", 0.0, 80.0, 1.0, t.max_deflection_deg,
			func(v): t.max_deflection_deg = v; _tail_changed(false), "%d°"))
	# Profil der Flossen (Platte oder NACA 00xx) mit Dicke und Gewichts-Schätzung
	_profile_block(_tail_box, t, t.area_m2, t.aspect_ratio, func(): _tail_changed(false), _fill_tail_page)
	# Gewicht je Flosse: Vorschlag (Depron + Pauschale) oder von Hand eingetragen
	_fin_mass_lbl = UITheme.make_label("")
	_fin_mass_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tail_box.add_child(_fin_mass_lbl)
	var own := UITheme.make_number_row("Eigenes Gewicht je Flosse (leer = Vorschlag)", 0.0, 1000.0, 1.0,
		-1.0 if ship.fin_mass_auto else ship.fin_mass_kg * 1000.0,
		func(v):
			ship.fin_mass_auto = v < 0.0
			if v >= 0.0: ship.fin_mass_kg = v / 1000.0
			_changed(), "%d g")
	own.allow_empty = true
	own.set_value_no_signal(-1.0 if ship.fin_mass_auto else ship.fin_mass_kg * 1000.0)
	own.empty_base = roundf(_tail_suggest_kg() * 1000.0)
	_tail_box.add_child(own)
	_update_fin_mass_info()
	# Elastisches Leitwerk für beide Bauarten schaltbar (aus = starre Flossen)
	var flex := CheckBox.new()
	flex.text = "Elastisches Leitwerk (Pseudo-Flex) – aus = starr"
	flex.button_pressed = t.pseudo_flex
	flex.toggled.connect(func(on): t.pseudo_flex = on; _tail_changed(false))
	_tail_box.add_child(flex)


## Je Flosse: Bauart (fest/Klappe/Pendel), Fläche, Streckung, Pfeilung,
## Klappentiefe und Ausschlag. „symmetrisch“: die Gegenflosse ändert sich mit.
func _fin_blocks(t: TailConfig) -> void:
	t.ensure_fin_cfg()
	var sym := CheckBox.new()
	sym.text = "symmetrisch (Gegenflosse ändert sich mit)"
	sym.button_pressed = t.symmetric
	sym.toggled.connect(func(on): t.symmetric = on; _tail_changed(false))
	_tail_box.add_child(sym)
	var al := t.angles()
	for i in al.size():
		var c: Dictionary = t.fin_cfg[i]
		var fi := i
		var setv := func(key: String, v, rebuild: bool):
			c[key] = v
			var j := t.mirror_of(fi) if t.symmetric else -1
			if j >= 0: t.fin_cfg[j][key] = v
			_tail_changed(rebuild)
		var head := UITheme.make_title(I18n.t(TailConfig.fin_name(al[i])))
		head.add_theme_font_size_override("font_size", 17)
		_tail_box.add_child(head)
		_tail_box.add_child(UITheme.make_choice_row(["fest", "Klappe", "Pendel"], int(c.get("kind", 1)),
			func(k): setv.call("kind", k, true)))
		_tail_box.add_child(UITheme.make_number_row("Fläche", 5.0, 100000.0, 1.0, float(c.area) * 1e4,
			func(v): setv.call("area", v / 1e4, false), "%d cm²"))
		_tail_box.add_child(UITheme.make_number_row("Streckung", 0.3, 6.0, 0.1, float(c.ar),
			func(v): setv.call("ar", v, false), "%.1f"))
		_tail_box.add_child(UITheme.make_number_row("Pfeilung (Endtiefe/Wurzeltiefe)", 0.2, 1.0, 0.05, float(c.tp),
			func(v): setv.call("tp", v, false), "%.2f"))
		if int(c.get("kind", 1)) == 1:
			_tail_box.add_child(UITheme.make_number_row("Klappentiefe (Anteil der Flossentiefe)", 10.0, 60.0, 1.0, float(c.flap) * 100.0,
				func(v): setv.call("flap", v / 100.0, false), "%d %%"))
		if int(c.get("kind", 1)) != 0:
			_tail_box.add_child(UITheme.make_number_row("Ausschlag max", 0.0, 80.0, 1.0, float(c.defl),
				func(v): setv.call("defl", v, false), "%d°"))


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
	_canard_editor.add_child(UITheme.make_number_row("Fläche", 5.0, 100000.0, 1.0, s.area_m2 * 1e4,
		func(v): s.area_m2 = v / 1e4; _changed(), "%d cm²"))
	_profile_block(_canard_editor, s, s.area_m2, s.aspect_ratio, func(): _changed(), func(): _edit_canard(i))
	# Gewicht: Vorschlag (Depron + Pauschale) oder von Hand eingetragen
	_canard_sel = s
	_canard_mass_lbl = UITheme.make_label("")
	_canard_mass_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_canard_editor.add_child(_canard_mass_lbl)
	var own := UITheme.make_number_row("Eigenes Gewicht (leer = Vorschlag)", 0.0, 1000.0, 1.0, s.mass_kg * 1000.0,
		func(v):
			s.mass_auto = v < 0.0
			if v >= 0.0: s.mass_kg = v / 1000.0
			_changed(), "%d g")
	own.allow_empty = true
	own.set_value_no_signal(-1.0 if s.mass_auto else s.mass_kg * 1000.0)
	own.empty_base = roundf(s.suggested_mass_kg() * 1000.0)
	_canard_editor.add_child(own)
	_update_fin_mass_info()
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
	_hull_rows.bmah = UITheme.make_number_row("Kapazität", 10.0, 100000.0, 10.0, ship.battery_mah,
		func(v): ship.battery_mah = v; _changed(), "%d mAh")
	_hull_rows.bm = UITheme.make_number_row("Masse", 1.0, 50000.0, 1.0, ship.battery_mass_kg * 1000.0,
		func(v): ship.battery_mass_kg = v / 1000.0; _changed(), "%d g")
	col.add_child(_hull_rows.bmah)
	col.add_child(_hull_rows.bm)
	# Akku an eigener Stelle (sonst sitzt er in der Restmasse, die das Schiff austrimmt)
	_bat_own = CheckBox.new()
	_bat_own.text = "Akku an eigener Stelle"
	_bat_own.button_pressed = ship.battery_own_x
	col.add_child(_bat_own)
	_bat_x = UITheme.make_slider_row("Lage Akku (0 Nase · 1 Heck)", 0.05, 0.95, 0.01, ship.battery_x,
		func(v): ship.battery_x = v; _changed(), "%.2f")
	_bat_x.visible = ship.battery_own_x
	col.add_child(_bat_x)
	_bat_own.toggled.connect(func(on):
		ship.battery_own_x = on
		_bat_x.visible = on
		_changed())
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
	# Aufbau von oben nach unten (Wunsch 12.11.2026):
	#   ① Mischer (geht immer, auch ohne Teensy)
	#   ② FC einbauen (Teensy 4.0) + Masse
	#   ③ Regler (PID)      – ausgegraut ohne FC
	#   ④ Bausteine         – ausgegraut ohne FC, eigenes Untermenü
	#   Admin: Teensy-Sketch (.ino)
	# --- ① Mischer ---
	col.add_child(UITheme.make_title("Mischer"))
	col.add_child(_note("Legt fest, welche Ruder und Schwenker bei Nick, Gier und Roll ausschlagen – ohne Regler, direkt vom Knüppel. So fliegen die meisten Luftschiffe, ein Flugcontroller ist dafür nicht nötig."))
	var bm := UITheme.make_button("Mischer einstellen")
	bm.pressed.connect(func(): ui_action.emit("select"); _show_mixer())
	col.add_child(bm)
	# --- ② FC einbauen ---
	col.add_child(UITheme.make_title("FC einbauen"))
	_teensy_check = CheckBox.new()
	_teensy_check.text = "FC einbauen (Teensy 4.0)"
	_teensy_check.button_pressed = ship.fc_teensy
	_teensy_check.toggled.connect(func(on): ship.fc_teensy = on; _update_fc_enabled(); _changed())
	col.add_child(_teensy_check)
	col.add_child(_note("Ein Teensy 4.0 mit Lagesensor ist leicht, schnell und einfach einzubauen. Er hält das Luftschiff in der Lage und dämpft Pendeln. Eine passende .ino-Datei für deinen Teensy erstellt der Admin auf Anfrage aus dem Simulator."))
	_hull_rows.tm = UITheme.make_number_row("Masse Flugcontroller", 0.0, 100.0, 1.0, ship.teensy_mass_kg * 1000.0,
		func(v): ship.teensy_mass_kg = v / 1000.0; _changed(), "%d g")
	col.add_child(_hull_rows.tm)
	# --- ③ Regler (PID) ---
	col.add_child(UITheme.make_title("Regler (PID)"))
	col.add_child(_note("Der Regler vergleicht die gewünschte mit der gemessenen Lage oder Drehrate und steuert nach: P reagiert sofort, I gleicht bleibende Abweichungen aus, D dämpft schnelle Bewegungen."))
	_b_pid = UITheme.make_button("Regler einstellen")
	_b_pid.pressed.connect(func(): ui_action.emit("select"); pid_requested.emit())
	col.add_child(_b_pid)
	# --- ④ Bausteine ---
	col.add_child(UITheme.make_title("Bausteine"))
	col.add_child(_note("Zusatzfunktionen des Flugcontrollers, einzeln an- und abschaltbar (z. B. Knüppel-Vorsteuerung, Nick-Schutz, Rollausgleich)."))
	_b_blocks = UITheme.make_button("Bausteine einstellen")
	_b_blocks.pressed.connect(func(): ui_action.emit("select"); _show_blocks())
	col.add_child(_b_blocks)
	# --- Admin: Teensy-Sketch ---
	col.add_child(UITheme.make_title("Admin"))
	col.add_child(_note("Nur für den Admin: Teensy-Sketch (.ino) aus diesem Modell erzeugen."))
	var ba := UITheme.make_button("Teensy-Sketch erzeugen")
	ba.pressed.connect(func(): ui_action.emit("select"); _show_ino())
	col.add_child(ba)
	_update_fc_enabled()


## Hinweistext (grau, umbrechend) für die Steuerung.
func _note(text: String) -> Label:
	var l := UITheme.make_label(text, "MutedLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Ohne eingebauten FC: Masse, Regler und Bausteine ausgegraut.
func _update_fc_enabled() -> void:
	var on := ship.fc_teensy
	if _b_pid: _b_pid.disabled = not on
	if _b_blocks: _b_blocks.disabled = not on
	if _hull_rows.has("tm"):
		_hull_rows.tm.modulate.a = 1.0 if on else 0.4
		_hull_rows.tm.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
		for c in _hull_rows.tm.get_children():
			if c is Button: c.disabled = not on
			if c is LineEdit: c.editable = on


## Fenster über dem Baukasten (wie Signalfluss): Titel, Schließen, Inhalt.
func _window(title: String, close_text := "Fertig") -> Dictionary:
	var win := PanelContainer.new()
	win.add_theme_stylebox_override("panel", UITheme.box(Color("101720"), Color("2c3746"), -1, 12))
	var v := UITheme.make_vbox("sm")
	var head := UITheme.make_hbox("sm")
	var t := UITheme.make_title(title)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	v.add_child(head)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := UITheme.make_vbox("sm")
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	v.add_child(sc)
	var close := UITheme.make_primary_button(tr(close_text))
	close.pressed.connect(func(): win.queue_free())
	head.add_child(close)
	win.add_child(v)
	add_child(win)
	win.position = Vector2(size.x * 0.08, size.y * 0.06)
	win.size = Vector2(size.x * 0.84, size.y * 0.88)
	return {"win": win, "head": head, "body": body}


# =============================================================================
# Mischer einstellen
#   ┌ Mischer · Chewie ─────────── [Vorschlag aus Einbaulage] [Fertig] ┐
#   │ [✓] Mischer von Hand verwenden                                    │
#   │ Ausgang                    Nick     Gier     Roll                 │
#   │ Leitwerk oben (±25°)      [  0 %]  [100 %]  [  0 %]               │
#   │ …                                                                 │
#   └───────────────────────────────────────────────────────────────────┘
# Werte −200 … +200 % (über 100 % = früher am Anschlag). Gilt im Modus Direkt
# und ohne Flugcontroller; Gas bleibt beim Piloten.
# =============================================================================
func _show_mixer() -> void:
	var fc := ModelCodec._find_fc(ship)
	if fc == null:
		return
	var outs := FlightController.mix_outputs(ship)
	if not fc.manual_mix_valid():
		ship.mix_table = fc.suggest_mix()               # Bauteile geändert: Vorschlag als Start
	var w := _window(I18n.t("Mischer · %s") % ship.model_name)
	var body: VBoxContainer = w.body
	var sugg := UITheme.make_button("Vorschlag aus Einbaulage")
	w.head.add_child(sugg)
	w.head.move_child(sugg, 1)
	var use := CheckBox.new()
	use.text = "Mischer von Hand verwenden (aus = Mischer nach Einbaulage)"
	use.button_pressed = ship.mix_manual
	use.toggled.connect(func(on): ship.mix_manual = on; ui_action.emit("select"))
	body.add_child(use)
	body.add_child(_note("Prozent des Vollausschlags je Knüppel. Gilt im Modus Direkt und ohne Flugcontroller. Das Gas bleibt immer beim Piloten, kein Differenzschub."))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", UITheme.space("md"))
	grid.add_theme_constant_override("v_separation", UITheme.space("xs"))
	body.add_child(grid)
	for h in ["Ausgang", "Nick", "Gier", "Roll"]:
		var hl := UITheme.make_label(h, "MutedLabel")
		grid.add_child(hl)
	var edits := {}
	for o in outs:
		var name_l := UITheme.make_label("%s (±%d°)" % [I18n.t(o.name), roundi(o.max_deg)])
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_l)
		var row: Array = ship.mix_table.get(o.key, [0.0, 0.0, 0.0])
		for ax in 3:
			var le := LineEdit.new()
			le.custom_minimum_size = Vector2(96, UITheme.size("control_height"))
			le.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
			le.select_all_on_focus = true
			le.text = "%d %%" % roundi(row[ax])
			var key: String = o.key
			var axis := ax
			var commit := func():
				var t := le.text.replace("%", "").replace(",", ".").strip_edges()
				if t.is_valid_float():
					var arr: Array = ship.mix_table.get(key, [0.0, 0.0, 0.0]).duplicate()
					arr[axis] = clampf(float(t), -200.0, 200.0)
					ship.mix_table[key] = arr
				le.text = "%d %%" % roundi(ship.mix_table.get(key, [0, 0, 0])[axis])
			le.text_submitted.connect(func(_t): commit.call(); le.release_focus())
			le.focus_exited.connect(commit)
			grid.add_child(le)
			edits["%s/%d" % [key, ax]] = le
	if outs.is_empty():
		body.add_child(_note("Keine Ruder oder schwenkbaren Motoren vorhanden."))
	sugg.pressed.connect(func():
		ship.mix_table = fc.suggest_mix()
		for k in edits:
			var parts: PackedStringArray = k.split("/")
			edits[k].text = "%d %%" % roundi(ship.mix_table[parts[0]][int(parts[1])])
		ui_action.emit("ok"))


# =============================================================================
# Bausteine einstellen (Untermenü) – an/aus; feste Sicherheits-Bausteine sind immer an
# =============================================================================
func _show_blocks() -> void:
	var w := _window(tr("Bausteine"))
	var body: VBoxContainer = w.body
	var fc := ModelCodec._find_fc(ship)
	for blk in FcBlocks.BLOCKS:
		var cb := CheckBox.new()
		cb.text = I18n.t(blk.name) + (I18n.t("  (fest)") if blk.get("fixed", false) else (I18n.t("  (geplant)") if blk.get("planned", false) else ""))
		cb.tooltip_text = blk.desc
		cb.button_pressed = FcBlocks.is_on(blk.id) or blk.get("fixed", false)
		cb.disabled = blk.get("fixed", false) or blk.get("planned", false) or fc == null
		var bid: String = blk.id
		cb.toggled.connect(func(on):
			FcBlocks.set_on(fc, bid, on)
			ui_action.emit("select")
			if _flow: _flow.queue_redraw())
		body.add_child(cb)
		body.add_child(_note(blk.desc))
	var bf := UITheme.make_button("Signalfluss anzeigen")
	bf.pressed.connect(_show_flow)
	body.add_child(bf)


# =============================================================================
# Admin: Teensy-Sketch (dRehmFlight, Vorlage Chewie BETA 1.4)
# =============================================================================
func _show_ino() -> void:
	var w := _window(tr("Teensy-Sketch erzeugen"))
	var body: VBoxContainer = w.body
	body.add_child(_note("Nur für den Admin: erzeugt die .ino für den Teensy aus diesem Modell. Vor dem ersten Flug immer eine Bodenprobe ohne Propeller machen."))
	_ino_mixer = CheckBox.new()
	_ino_mixer.text = "Mischer aus Leitwerk und Antrieb des Modells erzeugen"
	_ino_mixer.button_pressed = true
	body.add_child(_ino_mixer)
	_ino_ch = CheckBox.new()
	_ino_ch.text = "Kanalzuordnung des Senders übernehmen (Sender kalibrieren)"
	_ino_ch.button_pressed = false
	body.add_child(_ino_ch)
	var be := UITheme.make_button("Als .ino exportieren")
	be.pressed.connect(_export_ino)
	body.add_child(be)
	_ino_info = UITheme.make_label("", "MutedLabel")
	_ino_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_ino_info)


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
	var warn := InoExport.check(ship, fc)
	var opts := {"mixer": _ino_mixer.button_pressed}
	if _ino_ch.button_pressed:
		opts["channels"] = JoystickInput.channels_for_ino()
	var r := InoExport.build(fc, ship.model_name, opts)
	if r.text == "":
		_ino_info.text = I18n.t("Vorlage nicht gefunden.")
		return
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_").left(13)
	var fname := "%s_dRehmFlight_%s.ino" % [ship.model_name.replace(" ", "_").replace("(", "").replace(")", ""), stamp]
	var where := InoExport.save(r.text, fname)
	_ino_info.text = I18n.t("%s\n%d Werte geändert\n%s%s%s") % [where, r.changed.size(), "\n".join((r.notes as Array).map(func(n): return InoExport.note_ui(n))),
		(I18n.t("\nNicht gefunden: ") + ", ".join(r.missing)) if not r.missing.is_empty() else "", ("\n" + warn) if warn != "" else ""]
	ui_action.emit("ok")


func _add_motor_pair() -> void:
	var pid := "paar%d" % (ship.motors.size() / 2 + 1)
	# Neue Paare sitzen seitlich unten (45° unter der Waagrechten) – wie Chewie
	var r := AirshipPresets.make_motor("Motor rechts (%s)" % pid, 0.25, 135.0, 1.2, 60.0, 45.0)
	var l := AirshipPresets.make_motor("Motor links (%s)" % pid, 0.25, 225.0, 1.2, 60.0, 45.0)
	r.swivel_enabled = false                      # neue Motoren sind fest – Schwenken erst per Haken
	l.swivel_enabled = false
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
		I18n.t("Für das Paar (%d Motoren)") % pair.size() if pair.size() > 1 else "Antrieb", "MutedLabel"))
	var set_all := func(prop: String, v, relayout: bool):
		for m in pair: m.set(prop, v)
		if relayout: _changed()
	_editor_box.add_child(UITheme.make_number_row("Abstand zur Hülle (Gondelmitte)", 0.0, 500.0, 0.5, mo.standoff_m * 100.0,
		func(v): set_all.call("standoff_m", v / 100.0, true), "%.1f cm"))
	_editor_box.add_child(UITheme.make_number_row("Masse je Gondel (mit Servo)", 0.0, 10000.0, 1.0, mo.mass_kg * 1000.0,
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
	_editor_box.add_child(UITheme.make_number_row("Schub vor", 0.01, 1000.0, 0.1, mo.max_thrust_n,
		func(v): set_all.call("max_thrust_n", v, true), "%.1f N"))
	var rev := CheckBox.new()
	rev.text = "Rückwärtsschub erlaubt"
	rev.button_pressed = mo.reverse_allowed
	rev.toggled.connect(func(on): set_all.call("reverse_allowed", on, true))
	_editor_box.add_child(rev)
	_editor_box.add_child(UITheme.make_number_row("Wirkung rückwärts (normal ≈ 0,55 · 3D ≈ 0,95)", 0.1, 1.0, 0.05,
		mo.reverse_efficiency, func(v): set_all.call("reverse_efficiency", v, false), "%.2f"))
	# Schwenken nur mit Haken; erst dann gibt es Schwenkweg und Achsneigung
	var swc := CheckBox.new()
	swc.text = "Motor schwenkbar"
	swc.button_pressed = mo.swivel_enabled
	var sel_i := i
	swc.toggled.connect(func(on):
		set_all.call("swivel_enabled", on, true)
		_on_part_selected.call_deferred(sel_i))
	_editor_box.add_child(swc)
	if mo.swivel_enabled:
		_editor_box.add_child(UITheme.make_number_row("Schwenk max", 0.0, 120.0, 1.0, mo.max_swivel_deg,
			func(v): set_all.call("max_swivel_deg", v, false), "%d°"))
		# Negativ = Schub schwenkt radial zur Hüllenmitte (Chewie), positiv = entlang der Hülle (rollt stark)
		_editor_box.add_child(UITheme.make_number_row("Achsneigung (Pigleg, − = radial)", -60.0, 60.0, 1.0, mo.swivel_tilt_deg,
			func(v): set_all.call("swivel_tilt_deg", v, true), "%d°"))
	# Propeller in Zoll, cm oder mm (gespeichert wird in Zoll); kleinster Durchmesser 2 cm
	_editor_box.add_child(UITheme.make_label("Propeller", "MutedLabel"))
	var mi := i
	_editor_box.add_child(UITheme.make_choice_row(PROP_UNITS, prop_unit,
		func(k): prop_unit = k; _on_part_selected.call_deferred(mi)))
	var f: float = PROP_FACTOR[prop_unit]
	var pfmt: String = ["%.1f\"", "%.1f cm", "%d mm"][prop_unit]
	var pstep: float = [0.1, 0.1, 1.0][prop_unit]
	_editor_box.add_child(UITheme.make_number_row("Durchmesser", 2.0 / 2.54 * f, 40.0 / 2.54 * f, pstep, mo.prop_diameter_in * f,
		func(v): set_all.call("prop_diameter_in", v / f, false), pfmt))
	_editor_box.add_child(UITheme.make_number_row("Steigung", 0.2 * f, 20.0 * f, pstep, mo.prop_pitch_in * f,
		func(v): set_all.call("prop_pitch_in", v / f, false), pfmt))
	_editor_box.add_child(UITheme.make_stepper("Blätter", 2, 6, mo.prop_blades,
		func(v): set_all.call("prop_blades", v, false), LABEL_W))
	_editor_box.add_child(UITheme.make_number_row("Drehzahl max", 500.0, 200000.0, 500.0, mo.max_rpm,
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
	var tf := CheckBox.new()
	tf.text = "Auch auf dem Leitwerk (eher waagrechte Flossen)"
	tf.button_pressed = l.text_on_fins
	tf.toggled.connect(func(on): l.text_on_fins = on)
	_look_box.add_child(tf)
	_look_box.add_child(_swatch_row(TEXT_SWATCHES, l.text_color, func(c): l.text_color = c))
	_look_box.add_child(UITheme.make_slider_row("Schriftgröße", 0.1, 0.6, 0.01, l.text_size,
		func(v): l.text_size = v, "%.2f"))
	_look_box.add_child(UITheme.make_slider_row("Lage (Nase → Heck)", 0.1, 0.9, 0.01, l.text_pos,
		func(v): l.text_pos = v, "%.2f"))

	_look_box.add_child(UITheme.make_title("Logo"))
	var lrow := UITheme.make_hbox("xs")
	var load_b := UITheme.make_button("Logo laden")
	load_b.pressed.connect(_open_logo_picker)
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
		info.text = I18n.t("Logo „%s“ fehlt – bitte die mitgeschickte Bilddatei laden.") % l.logo_ref
		info.add_theme_color_override("font_color", UITheme.color("warning"))
	else:
		info.text = I18n.t("Datei: %s – beim Teilen separat mitschicken.") % l.logo_ref
	_look_box.add_child(info)
	var lf := CheckBox.new()
	lf.text = "Auch auf dem Leitwerk (Flossen mit senkrechtem Anteil)"
	lf.button_pressed = l.logo_on_fins
	lf.toggled.connect(func(on): l.logo_on_fins = on)
	_look_box.add_child(lf)
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
## Profil-Auswahl für Leitwerk (TailConfig) oder Canard (ControlSurface) – beide
## haben profile_naca, naca_thickness, plate_thickness_mm. on_change wendet die
## Änderung an, refill baut den Abschnitt neu (Platte: mm, NACA: %).
func _profile_block(box: Control, obj: Object, area: float, ar: float, on_change: Callable, refill: Callable) -> void:
	box.add_child(UITheme.make_label("Profil", "MutedLabel"))
	box.add_child(_choice_grid(["Brettchen (Platte)", "NACA 00xx"], 1 if obj.get("profile_naca") else 0,
		func(k):
			obj.set("profile_naca", k == 1)
			on_change.call()
			refill.call_deferred()))
	if obj.get("profile_naca"):
		box.add_child(UITheme.make_number_row("Dicke (NACA 00xx)", 4.0, 30.0, 1.0, float(obj.get("naca_thickness")) * 100.0,
			func(v): obj.set("naca_thickness", v / 100.0); on_change.call(), "%d %%"))
	else:
		box.add_child(UITheme.make_number_row("Dicke der Platte", 0.5, 20.0, 0.5, float(obj.get("plate_thickness_mm")),
			func(v): obj.set("plate_thickness_mm", v); on_change.call(), "%.1f mm"))
	# Kennwerte des Profils (das Gewicht steht beim Vorschlag weiter unten)
	var cs := ControlSurface.new()
	cs.area_m2 = area; cs.aspect_ratio = ar
	cs.profile_naca = obj.get("profile_naca"); cs.naca_thickness = obj.get("naca_thickness"); cs.plate_thickness_mm = obj.get("plate_thickness_mm")
	# Kennwerte bei langsamer (3 m/s) und schneller (9 m/s) Fahrt – Re = v·c/ν
	var p3 := cs.profile_params(cs.reynolds(3.0))
	var p9 := cs.profile_params(cs.reynolds(9.0))
	var info := UITheme.make_label(I18n.dec(I18n.t("%s · Tiefe %d mm\n3 m/s: Re %d 000, Abriss ≈ %d°, cd0 %.3f\n9 m/s: Re %d 000, Abriss ≈ %d°, cd0 %.3f") % [
		cs.profile_name(), roundi(cs.mean_chord() * 1000.0),
		roundi(cs.reynolds(3.0) / 1000.0), roundi(p3.stall_deg), p3.cd0,
		roundi(cs.reynolds(9.0) / 1000.0), roundi(p9.stall_deg), p9.cd0]), "MutedLabel")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)


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


## „Logo laden“: im Browser die Dateiauswahl des Rechners/Handys (über
## JavaScript), am Handy (Android) nach Erlaubnis den Ordner Download/Bilder,
## sonst die Dateiauswahl des Systems.
var _web_cb: JavaScriptObject          ## Rückruf aus dem Browser (muss bestehen bleiben)
func _open_logo_picker() -> void:
	if OS.has_feature("web"):
		_web_cb = JavaScriptBridge.create_callback(_on_web_logo)
		JavaScriptBridge.get_interface("window").rcaLogoCb = _web_cb
		JavaScriptBridge.eval("""(function(){
			var i = document.createElement('input'); i.type = 'file'; i.accept = 'image/png,image/jpeg,image/webp';
			i.onchange = function(){ var f = i.files[0]; if (!f) return; var r = new FileReader();
				r.onload = function(){ window.rcaLogoCb(r.result.split(',')[1]); }; r.readAsDataURL(f); };
			i.click(); })();""", true)
		return
	if OS.has_feature("android"):
		OS.request_permissions()                       # Bilder lesen (READ_MEDIA_IMAGES / Speicher)
		for d in ["/storage/emulated/0/Download", "/storage/emulated/0/Pictures"]:
			if DirAccess.dir_exists_absolute(d):
				_file_dialog.current_dir = d
				break
	_file_dialog.popup_centered_ratio(0.8)


## Browser: Bildinhalt kommt als Base64 an.
func _on_web_logo(args: Array) -> void:
	var ref := Livery.import_logo_bytes(Marshalls.base64_to_raw(str(args[0]))) if args.size() > 0 else ""
	_logo_loaded(ref)


func _on_logo_file(path: String) -> void:
	_logo_loaded(Livery.import_logo_file(path))


func _logo_loaded(ref: String) -> void:
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
		_canard_list.add_item(I18n.t("%s  ·  %d cm²") % [c.display_name, roundi(c.area_m2 * 1e4)])
	if csel.size() > 0 and csel[0] < _canard_list.item_count:
		_canard_list.select(csel[0])

	var r := TailValidator.validate(ship.hull, ship.surfaces, ship.cg_offset)
	var h := ship.hull
	# Modellname getrennt, damit Punkte im Namen nicht zu Kommas werden
	# Kennwerte rechts: nur Maße und Masse (Stabilität steht im Reiter Leitwerk)
	_stats.text = ship.model_name + "\n" + I18n.dec(I18n.t("%.2f × %.2f m\nMasse %.0f g (ohne Helium)") % [
		h.length_m, h.diameter_m, ship.structure_mass_kg * 1000.0])
	# Restmasse (was zum Austrimmen bleibt): Akku + Ballast
	if ship.battery_own_x:
		_stats.text += "\n" + I18n.t("Restmasse %d g (Ballast) · Akku %d g eigene Stelle") % [
			roundi(maxf(ship.ballast_kg, 0.0) * 1000.0), roundi(ship.battery_mass_kg * 1000.0)]
	else:
		_stats.text += "\n" + I18n.t("Restmasse %d g = Akku %d g + Ballast %d g") % [
			roundi(ship.rest_mass_kg * 1000.0), roundi(ship.battery_mass_kg * 1000.0), roundi(maxf(ship.ballast_kg, 0.0) * 1000.0)]
	_update_mass_info()
	_update_fin_mass_info()
	_update_factor.call_deferred()      # erst nach dem Neuaufbau des 3D-Modells messen
	var level := "success"
	if r.level == TailValidator.Level.UNSTABLE: level = "danger"
	elif r.level == TailValidator.Level.MARGINAL: level = "warning"
	UITheme.set_banner(_banner, I18n.t(r.message) + ("  " + r.detail if r.detail != "" else "")
		+ "\n" + I18n.dec(I18n.t("V_T Nick %.2f · Gier %.2f · Stabilität Nick %.2f · Gier %.2f") % [r.vt_pitch, r.vt_yaw, r.ratio_pitch, r.ratio_yaw]), level)
	_banner.visible = _tabs.current_tab == TAB_TAIL
	if r.level == TailValidator.Level.UNSTABLE and _last_level != r.level and _last_level != -1:
		ui_action.emit("warn")                        # leiser Hinweiston beim Kippen ins Instabile
	_last_level = r.level
	if visual:
		visual.set_validation_level(r.level)
	_preview.queue_redraw()
	_layout.call_deferred()


# =============================================================================
# Fenster „Zurücksetzen“
# =============================================================================
#   ┌ Zurücksetzen ────────────────────────────────────────────┐
#   │ Was soll wieder wie ab Werk sein?                         │
#   │ [✓] Dieses Luftschiff („Chewie“)   Hülle, Leitwerk, …     │
#   │ [✓] Regler                         PID, Bausteine, Angle  │
#   │ [ ] Sender                         Kalibrierung, Zuordnung│
#   │ [ ] Knüppelbelegung und Strecke    Mode 4 · Hugo Eckener  │
#   │ Bleibt erhalten: Bestenliste, eigene Modelle, Sprache …   │
#   │              [Abbrechen]  [Zurücksetzen]                  │
#   └───────────────────────────────────────────────────────────┘
func _open_reset() -> void:
	if _reset_dlg == null:
		_build_reset_dlg()
	_reset_ship_lbl.text = I18n.t("Dieses Luftschiff („%s“)") % ship.model_name
	for k in _reset_checks:
		_reset_checks[k].button_pressed = k == "ship" or k == "fc"     # Vorauswahl
	_reset_dlg.visible = true


func _build_reset_dlg() -> void:
	_reset_dlg = ColorRect.new()
	(_reset_dlg as ColorRect).color = Color(0, 0, 0, 0.6)
	_reset_dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_dlg.visible = false
	add_child(_reset_dlg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_dlg.add_child(center)
	var panel := UITheme.make_panel(600)
	center.add_child(panel)
	var v := UITheme.make_vbox("sm")
	panel.add_child(v)
	v.add_child(UITheme.make_title("Zurücksetzen"))
	v.add_child(UITheme.make_label("Was soll wieder wie ab Werk sein?", "MutedLabel"))
	var items := [
		["ship", "", "Hülle, Leitwerk, Antrieb, Massen und Optik wie das Standardmodell. Bei eigenen Modellen: letzter gespeicherter Stand."],
		["fc", "Regler", "PID-Werte des Modells, Bausteine alle an, Flugmodus Angle"],
		["sender", "Sender", "Kalibrierung, Umkehr und Kanalzuordnung – danach neu kalibrieren"],
		["sticks", "Knüppelbelegung und Strecke", "Mode 4 (Gas links) · FN Hugo Eckener Cup"]]
	for it in items:
		var row := UITheme.make_hbox("sm")
		var cb := CheckBox.new()
		cb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(cb)
		var col := UITheme.make_vbox("xs")
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t := UITheme.make_label(it[1])
		if it[0] == "ship": _reset_ship_lbl = t
		col.add_child(t)
		var d := UITheme.make_label(it[2], "MutedLabel")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", UITheme.font_size("caption"))
		col.add_child(d)
		row.add_child(col)
		# ganze Zeile antippbar
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		t.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: cb.button_pressed = not cb.button_pressed)
		_reset_checks[it[0]] = cb
		v.add_child(row)
	var keep := UITheme.make_label("Bleibt erhalten: Bestenliste, eigene Modelle, Sprache, Lautstärke", "MutedLabel")
	keep.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keep.add_theme_font_size_override("font_size", UITheme.font_size("caption"))
	v.add_child(keep)
	var btns := UITheme.make_hbox("md")
	var b_no := UITheme.make_button("Abbrechen")
	b_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_no.pressed.connect(func(): _reset_dlg.visible = false)
	var b_yes := UITheme.make_primary_button(tr("Zurücksetzen"))
	b_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_yes.pressed.connect(func():
		var opts := {}
		for k in _reset_checks: opts[k] = _reset_checks[k].button_pressed
		_reset_dlg.visible = false
		reset_requested.emit(opts))
	btns.add_child(b_no)
	btns.add_child(b_yes)
	v.add_child(btns)


## Rennfaktor aus dem Boxmaß des sichtbaren Modells (wie vor dem Rennen gemessen).
func _update_factor() -> void:
	if visual == null or _factor_lbl == null:
		return
	var a := visual.local_aabb()
	var f := Course.race_factor(Vector3(a.size.z, a.size.x, a.size.y))
	_factor_lbl.text = I18n.dec(I18n.t("Rennfaktor F7B ×%.2f\ngewertet = gemessen × %.2f") % [f, f])


func _changed() -> void:
	ship.rebuild_mass_properties()     # erzeugt Leitwerk, platziert, löst config_changed → _refresh aus


## Regler auf das aktuelle Modell setzen (nach Modellwechsel/Import).
func _sync_from_ship() -> void:
	if _bat_own:
		_bat_own.set_pressed_no_signal(ship.battery_own_x)
		_bat_x.visible = ship.battery_own_x
		UITheme.set_row_value(_bat_x, ship.battery_x, "%.2f")
	if _name_edit and _name_edit.text != ship.model_name:
		_name_edit.text = ship.model_name
	if _desc_edit and _desc_edit.text != ship.model_description:
		_desc_edit.text = ship.model_description
		_desc_count.text = "%d / 100" % ship.model_description.length()
	var vals := {"vol": ship.hull.volume_m3, "ld": ship.hull.length_to_diameter,
		"m": ship.hull.m, "cp": ship.hull.cp, "hf": ship.hull_film_kg_m2 * 1000.0,
		"el": ship.electronics_mass_kg * 1000.0, "bx": ship.ballast_x, "tw": _heaviness_pct(),
		"pl": ship.payload_mass_kg * 1000.0, "px": ship.payload_x, "pa": ship.payload_angle_deg,
		"bmah": ship.battery_mah, "bm": ship.battery_mass_kg * 1000.0, "tm": ship.teensy_mass_kg * 1000.0}
	var fmts := {"vol": "%.2f m³", "ld": "%.1f", "m": "%.2f", "cp": "%.3f", "hf": "%d g/m²", "el": "%d g", "bx": "%.2f",
		"tw": "%.1f %%", "pl": "%d g", "px": "%.2f", "pa": "%d°", "bmah": "%d mAh", "bm": "%d g", "tm": "%d g"}
	_teensy_check.set_pressed_no_signal(ship.fc_teensy)
	_update_fc_enabled()
	(_cells_row.get_meta("out") as Label).text = str(ship.battery_cells)
	_ballast_auto.set_pressed_no_signal(ship.ballast_auto_x)
	for k in vals:
		UITheme.set_row_value(_hull_rows[k], vals[k], fmts[k])
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
## Vorschläge für das Flossen-/Canardgewicht anzeigen: „Vorschlag je Flosse
## 12 g = Depron … + Pauschale …“; ausgegraut, wenn von Hand eingetragen.
func _update_fin_mass_info() -> void:
	if _fin_mass_lbl and is_instance_valid(_fin_mass_lbl):
		var fins := ship.surfaces.filter(func(x): return x.tail_member)
		if fins.size() > 0:
			_fin_mass_lbl.text = _suggest_text(fins[0], "Vorschlag je Flosse: %d g", not ship.fin_mass_auto)
			_style_suggest(_fin_mass_lbl, not ship.fin_mass_auto)
	if _canard_mass_lbl and is_instance_valid(_canard_mass_lbl) and _canard_sel and is_instance_valid(_canard_sel):
		_canard_mass_lbl.text = _suggest_text(_canard_sel, "Vorschlag: %d g", not _canard_sel.mass_auto)
		_style_suggest(_canard_mass_lbl, not _canard_sel.mass_auto)


## Text für den Gewichtsvorschlag einer Fläche (Depron + Pauschale).
func _suggest_text(sf: ControlSurface, head: String, unused: bool) -> String:
	var t := I18n.t(head) % roundi(sf.suggested_mass_kg() * 1000.0)
	if unused:
		t += "  " + I18n.t("(nicht verwendet)")
	var dep := sf.depron_mass_kg() * 1000.0
	var line := (I18n.t("Depron 2 × %d cm² × 120 g/m² = %.1f g") if sf.profile_naca else I18n.t("Depron %d cm² × 120 g/m² = %.1f g")) % [
		roundi(sf.area_m2 * 1e4), dep]
	line += "\n" + I18n.t("+ Servo, Anlenkung, Versteifung %.1f g") % (sf.fitting_mass_kg() * 1000.0)
	return I18n.dec(t + "\n" + line)


## Vorschlag normal (wird verwendet) oder ausgegraut (eigenes Gewicht gilt).
func _style_suggest(l: Label, unused: bool) -> void:
	if unused:
		l.add_theme_color_override("font_color", Color("6b7480"))   # deutlich grauer als normale Hinweise
	else:
		l.remove_theme_color_override("font_color")


## Vorgeschlagenes Gewicht einer Leitwerksflosse (kg) – für −/+ im leeren Feld.
func _tail_suggest_kg() -> float:
	for x in ship.surfaces:
		if x.tail_member:
			return x.suggested_mass_kg()
	return 0.01


func _update_mass_info() -> void:
	if _mass_info == null:
		return
	if _hull_mass_lbl:
		_hull_mass_lbl.text = I18n.dec(I18n.t("Hülle %d g = Oberfläche %.2f m² × %d g/m² + 7 %% (Nähte 2 %%, Ränder und Ventil 5 %%)") % [
			roundi(ship.hull_mass_kg * 1000.0), ship.hull.surface_m2(), roundi(ship.hull_film_kg_m2 * 1000.0)])
	var cg := ship.cg_offset
	if ship.overweight:
		_mass_info.text = "Zu schwer: Hülle, Motoren und Elektronik wiegen mehr, als der Auftrieb trägt."
		_mass_info.add_theme_color_override("font_color", UITheme.color("danger"))
	else:
		_mass_info.text = I18n.t("Akku %d g + Ballast %d g (aus dem Auftrieb) · unten an der Hülle\nSchwerpunkt %d cm unter der Achse · Gesamt %d g ohne Helium") % [
			roundi(ship.battery_mass_kg * 1000.0), roundi(maxf(ship.ballast_kg, 0.0) * 1000.0), roundi(-cg.y * 100.0), roundi(ship.structure_mass_kg * 1000.0)]
		_mass_info.remove_theme_color_override("font_color")
		if ship.ballast_kg < 0.0:
			_mass_info.text = I18n.t("Akku zu schwer: %d g mehr, als der Auftrieb trägt (Rest nur %d g).") % [
				roundi(-ship.ballast_kg * 1000.0), roundi(ship.rest_mass_kg * 1000.0)]
			_mass_info.add_theme_color_override("font_color", UITheme.color("danger"))
	_update_trim()
	var bx: HSlider = _hull_rows.bx.get_meta("slider")
	bx.set_value_no_signal(ship.ballast_x)
	(_hull_rows.bx.get_meta("out") as Label).text = "%.2f" % ship.ballast_x


## Bug-/Hecklastigkeit: Winkel, unter dem das Schiff hängt (Schwerpunkt genau
## unter dem Auftriebspunkt). Die 3D-Ansicht pendelt langsam dorthin, ab
## TRIM_WARN_DEG erscheint ein roter Hinweis.
func _update_trim() -> void:
	var cg := ship.cg_offset                          # Körpersystem: +z = hinten, +y = oben
	var deg := 0.0
	if cg.y < -0.001:
		deg = rad_to_deg(atan2(cg.z, -cg.y))          # > 0: Schwerpunkt hinten → Heck sinkt, Nase hoch
	if visual:
		visual.trim_target_deg = deg
	if absf(deg) < TRIM_WARN_DEG or ship.overweight:
		_trim_banner.visible = false
		return
	var cm := roundi(absf(cg.z) * 100.0)
	var txt: String
	if deg > 0.0:
		txt = I18n.t("Hecklastig (Nase %+d°)") % roundi(deg) + "\n" + I18n.t("Schwerpunkt %d cm hinter dem Auftriebspunkt") % cm
	else:
		txt = I18n.t("Buglastig (Nase %+d°)") % roundi(deg) + "\n" + I18n.t("Schwerpunkt %d cm vor dem Auftriebspunkt") % cm
	UITheme.set_banner(_trim_banner, txt, "danger")
	_trim_banner.visible = true
	_layout.call_deferred()


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
		var txt := I18n.t("Heckansicht")
		var fs := UITheme.font_size("caption") - 2
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(c.x - w * 0.5, size.y - 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.color("text_muted"))
