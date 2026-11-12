# 2026-11-12 11:00 – Kopfzeile: ▶ Weiterfliegen (nur bei begonnenem Flug) · Startseite · Bestenliste · Sender kalibrieren; Knopf „Dieses Luftschiff fliegen“ mit Rückfrage „Der begonnene Flug wird beendet“ (Verwerfen/Bestätigen); Rennfaktor (F7B) hinter jedem Modellnamen
# 2026-11-11 17:45 – Modellbeschreibung und Kenndaten übersetzt (Dezimalzeichen je Sprache)
# 2026-11-11 01:40 – Knopf „Sender kalibrieren“ hier (statt Startseite)
# 2026-11-11 00:10 – Location-Zeile „Halle FN · Pylonabstand …“; Knopf „Bestenliste“ (zeigen und zurücksetzen wie gehabt)
# 2026-11-10 20:40 – Erstversion: „Modell & Bau“ nach freigegebenem Entwurf – links scrollbare Location-Liste mit Bildern und Pylonabstand (Zahlenfeld), Mitte scrollbare Modellliste mit Vorschau aus den Modelldaten und Karte „Eigenbau“, rechts Details (großes Bild, Autor, Team, Beschreibung, Kennwerte) mit Fliegen / Bearbeiten / Exportieren und Hinweis zum Einsenden an den Admin
# =============================================================================
# ModelHub.gd
# -----------------------------------------------------------------------------
#   ┌ Modell & Bau ── [▶ Weiterfliegen] [Startseite] [Bestenliste] [Sender kalibrieren] ┐
#   │ Location          │ Modell              │ [großes Vorschaubild]             │
#   │ ┌──────────────┐  │ ┌───────────────┐   │ Chewie                            │
#   │ │ Bild  Halle  │  │ │ Chewie ×0,72  │   │ Autor · Team                      │
#   │ │ Bild  Wiese  │  │ │ Bild  Albacore│   │ Beschreibung …                    │
#   │ │ (scrollt)    │  │ │ ＋ Eigenbau    │   │ L · Ø · L/D · Motoren             │
#   │ └──────────────┘  │ └───────────────┘   │ [Dieses Luftschiff fliegen] [Bearbeiten] [Export.] │
#   │ Pylonabstand [18] │                     │ Hinweis: an den Admin schicken     │
#   └─────────────────────────────────────────────────────────────────────────────┘
# Hinter jedem Modellnamen steht der Rennfaktor (F7B): die Zahl, mit der die
# gemessene Zeit malgenommen wird (∛(L·B·H·π/6), Boxmaß in m).
# „Weiterfliegen“ gibt es nur, wenn schon ein Flug begonnen wurde. Wird dann
# ein anderes Luftschiff gewählt, fragt ein Fenster, ob der Flug enden soll.
# =============================================================================
class_name ModelHub
extends Control

signal closed                     ## Weiterfliegen (zurück in den begonnenen Flug)
signal home_requested             ## Startseite
signal fly_requested              ## Modell gewählt → fliegen
signal edit_requested             ## Baukasten mit dem gewählten Modell öffnen
signal export_requested           ## Teilen/Export-Fenster öffnen
signal location_changed           ## Location oder Abstand geändert → Schiff an den Start
signal calibrate_requested        ## Sender kalibrieren
signal leaderboard_requested      ## Bestenliste der aktuellen Location/Strecke zeigen

const CONTACT := "erich.fink ät aerarium.de"

var ship: AirshipPhysics
var course: Course
var _panel: PanelContainer
var _loc_list: VBoxContainer
var _mod_list: VBoxContainer
var _dist_edit: LineEdit
var _detail_img: TextureRect
var _detail_name: Label
var _detail_meta: Label
var _detail_desc: Label
var _detail_data: Label
var _selected := -1               ## Index in AirshipPresets.list(); -1 = aktuelles Modell
## Wurde schon ein Flug begonnen? (setzt main.gd beim Wechsel in die Flugansicht)
var flight_begun := false
var _b_back: Button               ## „Weiterfliegen“ (nur sichtbar bei begonnenem Flug)
var _confirm: Control             ## Rückfrage „Der begonnene Flug wird beendet“
var _confirm_text: Label
var _probe: Node3D                ## unsichtbarer Platz zum Ausmessen der Modelle (Rennfaktor)


func setup(s: AirshipPhysics, c: Course) -> void:
	ship = s
	course = c


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.14, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := UITheme.make_vbox("md")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24; root.offset_right = -24; root.offset_top = 18; root.offset_bottom = -18
	add_child(root)
	# Kopfzeile
	var head := UITheme.make_hbox("sm")
	var title := UITheme.make_title("Modell & Bau")
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	# Reihenfolge: Weiterfliegen (Hauptknopf) · Startseite · Bestenliste · Sender kalibrieren
	_b_back = UITheme.make_primary_button("▶  " + tr("Weiterfliegen"))
	_b_back.pressed.connect(func(): closed.emit())
	head.add_child(_b_back)
	var b_home := UITheme.make_button("Startseite")
	b_home.pressed.connect(func(): home_requested.emit())
	head.add_child(b_home)
	var b_lead := UITheme.make_button("Bestenliste")
	b_lead.pressed.connect(func(): leaderboard_requested.emit())
	head.add_child(b_lead)
	var b_cal := UITheme.make_button("Sender kalibrieren")
	b_cal.pressed.connect(func(): calibrate_requested.emit())
	head.add_child(b_cal)
	root.add_child(head)
	# Drei Spalten
	var cols := UITheme.make_hbox("lg")
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	# --- Location ---
	var lcol := UITheme.make_vbox("sm")
	lcol.custom_minimum_size.x = 300
	lcol.add_child(UITheme.make_title("Location"))
	_loc_list = UITheme.make_vbox("sm")
	lcol.add_child(_scroll(_loc_list))
	var drow := UITheme.make_hbox("sm")
	drow.add_child(UITheme.make_label("Pylonabstand"))
	_dist_edit = LineEdit.new()
	_dist_edit.custom_minimum_size.x = 80
	_dist_edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dist_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	_dist_edit.text_submitted.connect(func(_t): _apply_distance())
	_dist_edit.focus_exited.connect(_apply_distance)
	drow.add_child(_dist_edit)
	drow.add_child(UITheme.make_label("m", "MutedLabel"))
	lcol.add_child(drow)
	cols.add_child(lcol)
	# --- Modell ---
	var mcol := UITheme.make_vbox("sm")
	mcol.custom_minimum_size.x = 380
	mcol.add_child(UITheme.make_title("Modell"))
	_mod_list = UITheme.make_vbox("sm")
	mcol.add_child(_scroll(_mod_list))
	cols.add_child(mcol)
	# --- Details ---
	var dcol := UITheme.make_vbox("sm")
	dcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var imgbox := PanelContainer.new()
	imgbox.add_theme_stylebox_override("panel", UITheme.box(Color("223044")))
	_detail_img = TextureRect.new()
	_detail_img.custom_minimum_size = Vector2(300, 150)
	_detail_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imgbox.add_child(_detail_img)
	dcol.add_child(imgbox)
	_detail_name = UITheme.make_title("")
	_detail_name.add_theme_font_size_override("font_size", 24)
	_detail_meta = UITheme.make_label("", "MutedLabel")
	_detail_desc = UITheme.make_label("")
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_data = UITheme.make_label("", "MutedLabel")
	_detail_data.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for c in [_detail_name, _detail_meta, _detail_desc, _detail_data]:
		dcol.add_child(c)
	var brow := UITheme.make_hbox("sm")
	var b_fly := UITheme.make_primary_button(tr("Dieses Luftschiff fliegen"))
	b_fly.pressed.connect(_on_fly)
	var b_edit := UITheme.make_button("Bearbeiten")
	b_edit.pressed.connect(func(): _apply_selected(); edit_requested.emit())
	var b_exp := UITheme.make_button("Exportieren")
	b_exp.pressed.connect(func(): _apply_selected(); export_requested.emit())
	for b in [b_fly, b_edit, b_exp]:
		brow.add_child(b)
	dcol.add_child(brow)
	var note := UITheme.make_label("Export: Modell als Datei speichern. Schick sie an den Admin – geprüfte Modelle werden als Standardmodell für alle aufgenommen.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("ffcf9a"))
	dcol.add_child(note)
	var contact := UITheme.make_label("%s: %s" % [tr("Kontakt"), CONTACT], "MutedLabel")
	dcol.add_child(contact)
	cols.add_child(dcol)
	_probe = Node3D.new()
	_probe.visible = false
	add_child(_probe)
	_build_confirm()
	visibility_changed.connect(func(): if visible: _fill())


func _scroll(content: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	return sc


## Listen aufbauen (beim Öffnen).
func _fill() -> void:
	_selected = -1
	_b_back.visible = flight_begun
	_confirm.visible = false
	for c in _loc_list.get_children(): c.queue_free()
	for c in _mod_list.get_children(): c.queue_free()
	# Locations
	for li in Course.LOCATION_NAMES.size():
		# Pylonabstand der jeweiligen Location (Halle: Cup-Strecke bzw. eigener Abstand)
		var dist := course.meadow_distance if li == 1 else (Course.CUP_DISTANCE if course.preset == 0 else course.free_distance)
		var sub := ("%s · " % tr("Halle FN") if li == 0 else "") + "%s %d m" % [tr("Pylonabstand"), roundi(dist)]
		var it := _item(_location_thumb(li), Course.LOCATION_NAMES[li], sub, course.location == li)
		var idx := li
		it.pressed.connect(func():
			course.set_location(idx)
			location_changed.emit()
			_fill())
		_loc_list.add_child(it)
	_dist_edit.text = "%d" % roundi(course.distance())
	# Modelle
	var models := AirshipPresets.list()
	for i in models.size():
		var e: Dictionary = models[i]
		var tex := ShipPreview.texture_for_build(e.name, e.build, 220)
		var meta := AirshipPresets.meta(e.name)
		var sub: String = meta.get("team", "")
		var it := _item(tex, "%s   ×%s" % [e.name, _factor_text(race_factor_of(e.build))], sub, e.name == ship.model_name)
		var idx := i
		it.pressed.connect(func(): _select(idx))
		_mod_list.add_child(it)
	var own := _item(null, "Eigenbau", "Neues Modell oder Kopie bearbeiten", false)
	own.pressed.connect(func(): edit_requested.emit())
	_mod_list.add_child(own)
	_show_detail(ship.model_name, ShipPreview.texture(ship, 700), ship)


## Listeneintrag: Bild links, Name und Zeile darunter rechts; ausgewählt = blau umrandet.
func _item(tex: Texture2D, title: String, sub: String, on: bool) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = on
	b.custom_minimum_size = Vector2(0, 84)
	b.focus_mode = Control.FOCUS_NONE
	var col := Color("2f7de1") if on else Color("2c3746")
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UITheme.box(Color("1d2632") if st != "hover" else Color("243040"), col, -1, 8))
	var h := UITheme.make_hbox("sm")
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8; h.offset_top = 6; h.offset_right = -8; h.offset_bottom = -6
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(120, 64)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.texture = tex
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex == null:
		var plus := UITheme.make_label("＋")
		plus.add_theme_font_size_override("font_size", 34)
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus.custom_minimum_size = Vector2(120, 64)
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(plus)
	else:
		h.add_child(img)
	var v := UITheme.make_vbox("xs")
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UITheme.make_label(title)
	var s := UITheme.make_label(sub, "MutedLabel")
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for c in [t, s]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(c)
	h.add_child(v)
	b.add_child(h)
	return b


## Modell in der Liste antippen: nur anzeigen (übernommen wird mit „Fliegen“/„Bearbeiten“).
func _select(i: int) -> void:
	_selected = i
	var e: Dictionary = AirshipPresets.list()[i]
	var s := AirshipPhysics.new()
	e.build.call(s)
	_show_detail(e.name, ShipPreview.texture(s, 700), s)
	s.free()
	for k in _mod_list.get_child_count():
		var b := _mod_list.get_child(k) as Button
		var on := k == i
		b.button_pressed = on
		var col := Color("2f7de1") if on else Color("2c3746")
		for st in ["normal", "pressed"]:
			b.add_theme_stylebox_override(st, UITheme.box(Color("1d2632"), col, -1, 8))


func _show_detail(name: String, tex: Texture2D, s: AirshipPhysics) -> void:
	_detail_img.texture = tex
	_detail_name.text = name
	var meta := AirshipPresets.meta(name)
	var parts := []
	if meta.author != "": parts.append("%s: %s" % [tr("Autor"), meta.author])
	if meta.team != "": parts.append("%s: %s" % [tr("Team"), meta.team])
	_detail_meta.text = " · ".join(parts)
	_detail_desc.text = I18n.t(meta.desc)   # Beschreibungen der Standardmodelle sind übersetzt
	var h := s.hull
	_detail_data.text = I18n.dec(I18n.t("L %.2f m · Ø %.2f m · L/D %.1f · %.2f m³ · %d Flossen · %d Motoren") % [
		h.length_m, h.diameter_m, h.length_to_diameter, h.volume_m3, s.surfaces.size(), s.motors.size()])
	# Rennfaktor auch beim Namen in der Detailansicht
	var e_build := Callable()
	for e in AirshipPresets.list():
		if e.name == name: e_build = e.build
	if e_build.is_valid():
		_detail_name.text = "%s   ×%s" % [name, _factor_text(race_factor_of(e_build))]


## Ausgewähltes Modell auf das Luftschiff übernehmen.
func _apply_selected() -> void:
	if _selected < 0:
		return
	var e: Dictionary = AirshipPresets.list()[_selected]
	e.build.call(ship)
	ship.model_applied.emit()
	_selected = -1


## „Dieses Luftschiff fliegen“: läuft schon ein Flug mit einem anderen
## Luftschiff, erst nachfragen; mit demselben geht es im Flug weiter.
func _on_fly() -> void:
	var name: String = ship.model_name if _selected < 0 else AirshipPresets.list()[_selected].name
	if flight_begun and name == ship.model_name:
		closed.emit()                              # dasselbe Luftschiff: weiterfliegen
		return
	if flight_begun:
		_confirm_text.text = I18n.t("Du fliegst gerade „%s“.\nMit „%s“ neu an den Start?") % [ship.model_name, name]
		_confirm.visible = true
		return
	_fly_now()


func _fly_now() -> void:
	_confirm.visible = false
	_apply_selected()
	fly_requested.emit()


## Rückfrage-Fenster (abgedunkelter Hintergrund, Verwerfen / Bestätigen).
func _build_confirm() -> void:
	_confirm = ColorRect.new()
	(_confirm as ColorRect).color = Color(0, 0, 0, 0.6)
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.visible = false
	add_child(_confirm)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(center)
	var panel := UITheme.make_panel(480)
	center.add_child(panel)
	var v := UITheme.make_vbox("md")
	panel.add_child(v)
	var t := UITheme.make_title("Der begonnene Flug wird beendet")
	t.add_theme_font_size_override("font_size", 24)
	v.add_child(t)
	_confirm_text = UITheme.make_label("")
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_confirm_text)
	var row := UITheme.make_hbox("md")
	var b_no := UITheme.make_button("Verwerfen")
	b_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_no.pressed.connect(func(): _confirm.visible = false)
	var b_yes := UITheme.make_primary_button(tr("Bestätigen"))
	b_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_yes.pressed.connect(_fly_now)
	row.add_child(b_no)
	row.add_child(b_yes)
	v.add_child(row)


## Rennfaktor eines Modells (F7B): ∛(L·B·H·π/6) aus dem Boxmaß aller sichtbaren
## Teile. Das Modell wird dazu kurz unsichtbar aufgebaut und ausgemessen.
func race_factor_of(build: Callable) -> float:
	var s := AirshipPhysics.new()
	s.freeze = true
	build.call(s)
	var vis := AirshipVisual.new()
	s.add_child(vis)
	_probe.add_child(s)
	var a := vis.local_aabb()
	_probe.remove_child(s)
	s.queue_free()
	return Course.race_factor(Vector3(a.size.z, a.size.x, a.size.y))


static func _factor_text(f: float) -> String:
	return I18n.dec("%.2f" % f)


func _apply_distance() -> void:
	var t := _dist_edit.text.strip_edges().replace(",", ".")
	if t.is_valid_float() and absf(float(t) - course.distance()) > 0.01:
		course.set_distance(float(t))
		location_changed.emit()
	_dist_edit.text = "%d" % roundi(course.distance())


## Kleines Bild je Location (als SVG gezeichnet – keine Bilddateien nötig).
static func _location_thumb(li: int) -> Texture2D:
	var svg := ""
	if li == 0:
		# Halle: Glasdach, Band mit Horizont-Wandbildern, Galerien, Säulen, dunkler Boden
		svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="240" height="128">'
			+ '<rect width="240" height="128" fill="#eef1f3"/>'
			+ '<rect width="240" height="26" fill="#a9cdeb"/>'
			+ '<path d="M0 26H240M40 0V26M80 0V26M120 0V26M160 0V26M200 0V26" stroke="#c99a5b" stroke-width="3"/>'
			+ '<g><rect x="6" y="30" width="52" height="14" fill="#3b4fb0"/><rect x="64" y="30" width="52" height="14" fill="#3b4fb0"/><rect x="122" y="30" width="52" height="14" fill="#3b4fb0"/><rect x="180" y="30" width="52" height="14" fill="#3b4fb0"/>'
			+ '<path d="M6 37H58M64 37H116M122 37H174M180 37H232" stroke="#f3d9a0" stroke-width="2"/></g>'
			+ '<path d="M0 58H240M0 72H240" stroke="#9aa1a8" stroke-width="2"/>'
			+ '<rect y="76" width="240" height="14" fill="#8fa5b5"/>'
			+ '<g fill="#ffffff"><rect x="20" y="44" width="8" height="46"/><rect x="80" y="44" width="8" height="46"/><rect x="140" y="44" width="8" height="46"/><rect x="200" y="44" width="8" height="46"/></g>'
			+ '<rect y="90" width="240" height="38" fill="#2e353c"/><path d="M30 112H210" stroke="#fff" stroke-width="1.5"/>'
			+ '<rect x="50" y="94" width="4" height="18" fill="#e4572e"/><rect x="186" y="94" width="4" height="18" fill="#e4572e"/></svg>')
	else:
		svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="240" height="128">'
			+ '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fc3ee"/><stop offset="1" stop-color="#d6ecfb"/></linearGradient></defs>'
			+ '<rect width="240" height="64" fill="url(#s)"/><rect y="64" width="240" height="64" fill="#5f9a3e"/>'
			+ '<rect x="40" y="70" width="4" height="22" fill="#e4572e"/><rect x="196" y="66" width="3" height="14" fill="#e4572e"/>'
			+ '<path d="M44 84L196 76" stroke="#ffffff" stroke-width="1.5" stroke-dasharray="5 4"/></svg>')
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	return ImageTexture.create_from_image(img)
