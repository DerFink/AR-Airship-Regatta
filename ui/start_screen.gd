# 2026-11-11 17:45 – Neuer Aufbau nach freigegebenem Entwurf: App-Icon als Logo, Titel groß und fett, Luftschiff fliegt im Hintergrund im Kreis (orange gestrichelte Bahn), keine Pylone; „Fliegen“ fett mit blauem Rand; neu „Bestenliste“; „⚙ Einstellungen“ und „Nach Update suchen“ als Knöpfe; „Support“ (ohne Farbe) öffnet ein Fenster mit PayPal-QR-Code
# 2026-11-11 01:40 – „Sender kalibrieren“ wandert nach „Modell & Bau“
# 2026-11-10 22:35 – Angaben auch beim ersten Anzeigen füllen
# 2026-11-10 20:20 – Erstversion: Startseite nach freigegebenem Entwurf – Titel „RC Airship Regatta“, Knöpfe Fliegen / Modell & Bau / Über den Simulator / Buy me a beer, oben rechts Senderstatus und Sprachwahl mit Flaggen, unten Version, Update-Suche, Sender kalibrieren, Einstellungen; im Hintergrund das aktuelle Luftschiff vor dem Horizont der Hallen-Wandbilder
# =============================================================================
# StartScreen.gd
# -----------------------------------------------------------------------------
#   ┌────────────────────────────────────────────────────────────────┐
#   │ [Icon] RC Airship                     ● Sender  [Flagge Sprache▾]│
#   │        Regatta                                                 │
#   │ [ Fliegen · Chewie · Halle    ]       ╭ ─ ─ ─ ─ ─ ─ ─╮         │
#   │ [ Modell & Bau · Chewie       ]      │  Luftschiff →  │        │
#   │ [ Bestenliste                 ]       ╰ ─ ─ ─ ─ ─ ─ ─╯         │
#   │ [ Über den Simulator          ]   (fliegt im Kreis, orange      │
#   │ [⚙ Einstellungen][⟳ Update    ]    gestrichelte Bahn)          │
#   │ [ Support                     ]                                │
#   │ Version …  (Update-Status)                                     │
#   └────────────────────────────────────────────────────────────────┘
# Jeder Knopf meldet sich per Signal; main.gd schaltet die Ansichten um.
# =============================================================================
class_name StartScreen
extends Control

signal fly_requested
signal build_requested
signal about_requested
signal calibrate_requested
signal settings_requested
signal leaderboard_requested


## Liefert {"model": Name, "location": Text, "joy": Gerätename oder ""} (setzt main.gd)
var info_source: Callable
## Liefert die Vorschau des aktuellen Luftschiffs (Texture2D) – setzt main.gd
var preview_source: Callable

var _bg: TextureRect
var _ship: TextureRect
var _orbit: Orbit                     ## Luftschiff, das im Hintergrund im Kreis fliegt
var _logo: TextureRect
var _support: SupportPopup
var _title: VBoxContainer
var _menu: VBoxContainer
var _btn_fly: Button
var _btn_build: Button
var _top: HBoxContainer
var _joy_chip: Button
var _lang_btn: MenuButton
var _foot_l: HBoxContainer
var _foot_r: HBoxContainer
var _ver: Label
var _status: Label
var _updater: Updater
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# --- Hintergrund: Horizont wie die Wandbilder der Halle ---
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.38, 0.52, 0.57, 0.64, 1.0])
	g.colors = PackedColorArray([Color("0e1a3a"), Color("2b3a8f"), Color("7a5ab8"), Color("f3d9a0"), Color("3550a8"), Color("141c4a")])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	_bg = TextureRect.new()
	_bg.texture = gt
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	# Luftschiff fliegt im Hintergrund auf einer orange gestrichelten Kreisbahn
	_orbit = Orbit.new()
	_orbit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_orbit)

	# --- Titel ---
	# App-Icon als Logo links neben dem Namen
	_logo = TextureRect.new()
	_logo.texture = load("res://icon.svg")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_logo.custom_minimum_size = Vector2(124, 124)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)
	_title = UITheme.make_vbox("xs")
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t1 := UITheme.make_label("RC Airship\nRegatta")
	t1.add_theme_font_size_override("font_size", 64)
	t1.add_theme_constant_override("line_spacing", -12)
	# fett und mit Schatten, damit der Name vor dem Himmel klar lesbar ist
	t1.add_theme_font_override("font", _bold_font())
	t1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t1.add_theme_constant_override("shadow_offset_x", 2)
	t1.add_theme_constant_override("shadow_offset_y", 3)
	t1.add_theme_constant_override("shadow_outline_size", 6)
	var t2 := UITheme.make_label("Rennluftschiff-Simulator · Open Source")
	t2.add_theme_color_override("font_color", Color("d7defa"))
	_title.add_child(t1)
	_title.add_child(t2)
	add_child(_title)

	# --- Menüknöpfe ---
	_menu = UITheme.make_vbox("sm")
	add_child(_menu)
	# „Fliegen“ ist der erste Anlaufpunkt: fett, blauer Rand (keine Signalfarbe)
	_btn_fly = _big_button("Fliegen", Color(0.05, 0.07, 0.16, 0.85), Color.WHITE, UITheme.color("accent"))
	_btn_fly.add_theme_font_override("font", _bold_font())
	_btn_fly.add_theme_font_size_override("font_size", 24)
	_btn_fly.pressed.connect(func(): fly_requested.emit())
	_btn_build = _big_button("Modell & Bau")
	_btn_build.pressed.connect(func(): build_requested.emit())
	var b_lead := _big_button("Bestenliste")
	b_lead.pressed.connect(func(): leaderboard_requested.emit())
	var b_about := _big_button("Über den Simulator")
	b_about.pressed.connect(func(): about_requested.emit())
	for b in [_btn_fly, _btn_build, b_lead, b_about]:
		_menu.add_child(b)
	# zwei halbbreite Knöpfe: Einstellungen und Update-Suche
	var row := UITheme.make_hbox("sm")
	var b_set := _big_button("Einstellungen")
	b_set.icon = load("res://textures/zahnrad.svg")          # Zahnrad, gut sichtbar
	b_set.add_theme_constant_override("icon_max_width", 30)
	b_set.custom_minimum_size = Vector2(0, 58)
	b_set.add_theme_font_size_override("font_size", 19)
	b_set.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_set.pressed.connect(func(): settings_requested.emit())
	var b_upd := _big_button("Nach Update suchen")
	b_upd.icon = load("res://textures/update.svg")
	b_upd.add_theme_constant_override("icon_max_width", 26)
	b_upd.custom_minimum_size = Vector2(0, 58)
	b_upd.add_theme_font_size_override("font_size", 19)
	b_upd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_upd.pressed.connect(func(): _updater.check())
	row.add_child(b_set)
	row.add_child(b_upd)
	_menu.add_child(row)
	var b_sup := _big_button("Support")
	b_sup.pressed.connect(func(): _support.open())
	_menu.add_child(b_sup)
	_hint = UITheme.make_label("")
	_hint.add_theme_color_override("font_color", Color("ffe3a3"))
	_menu.add_child(_hint)

	# --- oben rechts: Sender und Sprache ---
	_top = UITheme.make_hbox("sm")
	add_child(_top)
	_joy_chip = UITheme.make_pill("")
	_top.add_child(_joy_chip)
	_lang_btn = MenuButton.new()
	_lang_btn.flat = false
	_lang_btn.focus_mode = Control.FOCUS_NONE
	_lang_btn.custom_minimum_size.y = UITheme.size("control_height")
	_lang_btn.expand_icon = false
	var pm := _lang_btn.get_popup()
	for i in I18n.LANGS.size():
		var code: String = I18n.LANGS[i]
		pm.add_icon_item(I18n.flag(code, 30), I18n.LANG_NAMES[code], i)
	pm.id_pressed.connect(func(id: int):
		I18n.set_language(I18n.LANGS[id])
		_refresh())
	_top.add_child(_lang_btn)

	# --- Fußzeile ---
	_foot_l = UITheme.make_hbox("sm")
	add_child(_foot_l)
	_ver = UITheme.make_label(BuildInfo.text(), "MutedLabel")
	_foot_l.add_child(_ver)
	_status = UITheme.make_label("", "MutedLabel")
	_foot_l.add_child(_status)
	_updater = Updater.new()
	add_child(_updater)
	_updater.status.connect(func(text: String, _done: bool): _status.text = text)
	_foot_r = UITheme.make_hbox("sm")          # (frei; Einstellungen sind jetzt im Menü)
	add_child(_foot_r)
	_support = SupportPopup.new()
	add_child(_support)

	resized.connect(_layout)
	visibility_changed.connect(func(): if visible: _refresh())
	_refresh.call_deferred()                 # erste Anzeige (Startseite ist von Anfang an sichtbar)


## Großer Menüknopf mit eigener Farbe.
func _big_button(text: String, bg := Color(0.05, 0.07, 0.16, 0.72), fg := Color.WHITE, border := Color(1, 1, 1, 0.13)) -> Button:
	var b := UITheme.make_button(text)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(320, 58)
	b.add_theme_font_size_override("font_size", 22)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := UITheme.box(bg if st != "hover" else bg.lightened(0.12), border, -1, UITheme.space("md"))
		if border.a > 0.5:
			sb.set_border_width_all(2)                    # kräftiger Rand für „Fliegen“
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	return b


## Angaben aktualisieren (Modell, Location, Sender, Sprache, Vorschau).
func _refresh() -> void:
	var info: Dictionary = info_source.call() if info_source.is_valid() else {}
	_btn_fly.text = "%s  ·  %s · %s" % [tr("Fliegen"), info.get("model", ""), info.get("location", "")]
	_btn_build.text = "%s    ·  %s" % [tr("Modell & Bau"), info.get("model", "")]
	var joy: String = info.get("joy", "")
	_joy_chip.text = ("● " + tr("Sender verbunden")) if joy != "" else tr("Kein Sender")
	_joy_chip.tooltip_text = joy
	_lang_btn.icon = I18n.flag(I18n.current, 30)
	_lang_btn.text = I18n.LANG_NAMES[I18n.current] + " ▼"
	if preview_source.is_valid():
		_orbit.ship_tex = preview_source.call()
	_layout.call_deferred()


func _process(_dt: float) -> void:
	if visible and Engine.get_process_frames() % 30 == 0:
		var info: Dictionary = info_source.call() if info_source.is_valid() else {}
		var joy: String = info.get("joy", "")
		var t := ("● " + tr("Sender verbunden")) if joy != "" else tr("Kein Sender")
		if _joy_chip.text != t:
			_joy_chip.text = t


## Fette Variante der Standardschrift (für Titel und „Fliegen“).
func _bold_font() -> Font:
	var fv := FontVariation.new()
	fv.base_font = get_theme_default_font()
	fv.variation_embolden = 0.9
	return fv


## Alles aus der aktuellen Bildschirmgröße platzieren.
func _layout() -> void:
	var m := 40.0
	var sz := size
	_logo.size = _logo.custom_minimum_size
	_logo.position = Vector2(m, m * 0.7)
	_title.size = _title.get_combined_minimum_size()
	_title.position = Vector2(_logo.position.x + _logo.size.x + 22.0, m * 0.6)
	var head_bottom := maxf(_logo.position.y + _logo.size.y, _title.position.y + _title.size.y)
	_menu.position = Vector2(m, head_bottom + 20.0)
	_menu.size = _menu.get_combined_minimum_size()
	_top.size = _top.get_combined_minimum_size()
	_top.position = Vector2(sz.x - _top.size.x - m * 0.6, m * 0.6)
	_foot_l.size = _foot_l.get_combined_minimum_size()
	_foot_l.position = Vector2(m, sz.y - _foot_l.size.y - 12.0)
	_foot_r.size = _foot_r.get_combined_minimum_size()
	_foot_r.position = Vector2(sz.x - _foot_r.size.x - m * 0.6, sz.y - _foot_r.size.y - 12.0)
	# Kreisbahn rechts neben dem Menü, um den Horizont herum
	var left := _menu.position.x + _menu.size.x + 30.0
	_orbit.position = Vector2(left, head_bottom * 0.6)
	_orbit.size = Vector2(maxf(sz.x - left - m, 200.0), maxf(sz.y - _orbit.position.y - 60.0, 160.0))


# =============================================================================
# Luftschiff auf einer Kreisbahn (von schräg oben gesehen = Ellipse). Hinten
# kleiner und etwas blasser, vorn groß; die Vorschau wird gespiegelt, wenn das
# Schiff nach links fliegt. Eine Runde dauert LAP_S Sekunden.
# =============================================================================
class Orbit extends Control:
	const LAP_S := 18.0
	const ORANGE := Color("ff7a3c")
	var ship_tex: Texture2D:
		set(v):
			ship_tex = v
			_region = Rect2()
	var _t := 0.0
	var _region := Rect2()        ## Teil der Vorschau, in dem wirklich das Schiff ist (ohne leeren Rand)

	## Leeren (durchsichtigen) Rand der Vorschau einmal ermitteln, damit das
	## Schiff genau auf der Bahn sitzt.
	func _ship_region() -> Rect2:
		if _region.size.x > 0.0 or ship_tex == null:
			return _region
		var img := ship_tex.get_image()
		if img == null:
			return Rect2(Vector2.ZERO, ship_tex.get_size())
		var used := img.get_used_rect()
		_region = Rect2(used) if used.size.x > 4 else Rect2(Vector2.ZERO, ship_tex.get_size())
		return _region

	func _process(dt: float) -> void:
		if is_visible_in_tree():
			_t = fmod(_t + dt / LAP_S, 1.0)
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var rx := size.x * 0.42
		var ry := size.y * 0.30
		# gestrichelte Bahn in kräftigem Orange
		var n := 72
		for i in n:
			if i % 2 == 1:
				continue
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			draw_line(c + Vector2(cos(a0) * rx, sin(a0) * ry), c + Vector2(cos(a1) * rx, sin(a1) * ry), ORANGE, 4.0, true)
		if ship_tex == null:
			return
		# Lage auf der Bahn; sin(a) > 0 = vorn (unten im Bild)
		var a := TAU * _t
		var p := c + Vector2(cos(a) * rx, sin(a) * ry)
		var depth := (sin(a) + 1.0) * 0.5                 # 0 hinten … 1 vorn
		var w := size.x * lerpf(0.20, 0.36, depth)
		var reg := _ship_region()
		var h := w * reg.size.y / maxf(reg.size.x, 1.0)
		var going_left := sin(a) > 0.0                    # vorn fliegt es nach links (gegen den Uhrzeigersinn von oben)
		var rect := Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h))
		rect.position.x = clampf(rect.position.x, 0.0, size.x - w)   # nie über den Rand hinaus
		var col := Color(1, 1, 1, lerpf(0.7, 1.0, depth))
		if not going_left:
			# Die Vorschau zeigt die Nase links → beim Flug nach rechts waagrecht spiegeln
			# (Zeichenebene an der rechten Kante umklappen)
			draw_set_transform(Vector2(rect.position.x + w, 0.0), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect_region(ship_tex, Rect2(Vector2(0.0, rect.position.y), rect.size), reg, col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect_region(ship_tex, rect, reg, col)
