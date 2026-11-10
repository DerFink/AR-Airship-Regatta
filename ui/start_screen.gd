# 2026-11-11 01:40 – „Sender kalibrieren“ wandert nach „Modell & Bau“
# 2026-11-10 22:35 – Angaben auch beim ersten Anzeigen füllen
# 2026-11-10 20:20 – Erstversion: Startseite nach freigegebenem Entwurf – Titel „RC Airship Regatta“, Knöpfe Fliegen / Modell & Bau / Über den Simulator / Buy me a beer, oben rechts Senderstatus und Sprachwahl mit Flaggen, unten Version, Update-Suche, Sender kalibrieren, Einstellungen; im Hintergrund das aktuelle Luftschiff vor dem Horizont der Hallen-Wandbilder
# =============================================================================
# StartScreen.gd
# -----------------------------------------------------------------------------
#   ┌────────────────────────────────────────────────────────────────┐
#   │ RC Airship                           ● Sender   [Flagge Sprache▾]│
#   │ Regatta                                                        │
#   │ [ Fliegen      Chewie · Halle ]          ════ Luftschiff ════  │
#   │ [ Modell & Bau         Chewie ]   ▌                         ▌  │
#   │ [ Über den Simulator          ]                                │
#   │ [ Buy me a beer               ]                                │
#   │ Version … · Nach Update suchen      Sender kalibrieren · Einst. │
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

## Spendenseite für „Buy me a beer“ (noch leer → Hinweis statt Link)
const BEER_URL := ""

## Liefert {"model": Name, "location": Text, "joy": Gerätename oder ""} (setzt main.gd)
var info_source: Callable
## Liefert die Vorschau des aktuellen Luftschiffs (Texture2D) – setzt main.gd
var preview_source: Callable

var _bg: TextureRect
var _ship: TextureRect
var _pylons: Array[ColorRect] = []
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
	# Zwei Pylone und das Luftschiff
	for i in 2:
		var p := ColorRect.new()
		p.color = Color("ff7a3c")
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_pylons.append(p)
	_ship = TextureRect.new()
	_ship.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ship.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ship.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ship)

	# --- Titel ---
	_title = UITheme.make_vbox("xs")
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t1 := UITheme.make_label("RC Airship\nRegatta")
	t1.add_theme_font_size_override("font_size", 54)
	t1.add_theme_constant_override("line_spacing", -10)
	var t2 := UITheme.make_label("Rennluftschiff-Simulator · Open Source")
	t2.add_theme_color_override("font_color", Color("d7defa"))
	_title.add_child(t1)
	_title.add_child(t2)
	add_child(_title)

	# --- Menüknöpfe ---
	_menu = UITheme.make_vbox("sm")
	add_child(_menu)
	_btn_fly = _big_button("Fliegen", Color("ff7a3c"), Color.WHITE)
	_btn_fly.pressed.connect(func(): fly_requested.emit())
	_btn_build = _big_button("Modell & Bau")
	_btn_build.pressed.connect(func(): build_requested.emit())
	var b_about := _big_button("Über den Simulator")
	b_about.pressed.connect(func(): about_requested.emit())
	var b_beer := _big_button("Buy me a beer", Color("f5c542"), Color("2a1e00"))
	b_beer.pressed.connect(_on_beer)
	for b in [_btn_fly, _btn_build, b_about, b_beer]:
		_menu.add_child(b)
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
	var b_upd := UITheme.make_button("Nach Update suchen")
	b_upd.flat = true
	b_upd.pressed.connect(func(): _updater.check())
	_foot_l.add_child(b_upd)
	_status = UITheme.make_label("", "MutedLabel")
	_foot_l.add_child(_status)
	_updater = Updater.new()
	add_child(_updater)
	_updater.status.connect(func(text: String, _done: bool): _status.text = text)
	_foot_r = UITheme.make_hbox("sm")
	add_child(_foot_r)
	var b_set := UITheme.make_button("Einstellungen")
	b_set.flat = true
	b_set.pressed.connect(func(): settings_requested.emit())
	_foot_r.add_child(b_set)

	resized.connect(_layout)
	visibility_changed.connect(func(): if visible: _refresh())
	_refresh.call_deferred()                 # erste Anzeige (Startseite ist von Anfang an sichtbar)


## Großer Menüknopf mit eigener Farbe.
func _big_button(text: String, bg := Color(0.05, 0.07, 0.16, 0.72), fg := Color.WHITE) -> Button:
	var b := UITheme.make_button(text)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(320, 58)
	b.add_theme_font_size_override("font_size", 22)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := UITheme.box(bg if st != "hover" else bg.lightened(0.12), Color(1, 1, 1, 0.13), -1, UITheme.space("md"))
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	return b


## Angaben aktualisieren (Modell, Location, Sender, Sprache, Vorschau).
func _refresh() -> void:
	var info: Dictionary = info_source.call() if info_source.is_valid() else {}
	_btn_fly.text = "%s    ·  %s · %s" % [tr("Fliegen"), info.get("model", ""), info.get("location", "")]
	_btn_build.text = "%s    ·  %s" % [tr("Modell & Bau"), info.get("model", "")]
	var joy: String = info.get("joy", "")
	_joy_chip.text = ("● " + tr("Sender verbunden")) if joy != "" else tr("Kein Sender")
	_joy_chip.tooltip_text = joy
	_lang_btn.icon = I18n.flag(I18n.current, 30)
	_lang_btn.text = I18n.LANG_NAMES[I18n.current] + " ▼"
	if preview_source.is_valid():
		_ship.texture = preview_source.call()
	_layout.call_deferred()


func _process(_dt: float) -> void:
	if visible and Engine.get_process_frames() % 30 == 0:
		var info: Dictionary = info_source.call() if info_source.is_valid() else {}
		var joy: String = info.get("joy", "")
		var t := ("● " + tr("Sender verbunden")) if joy != "" else tr("Kein Sender")
		if _joy_chip.text != t:
			_joy_chip.text = t


func _on_beer() -> void:
	if BEER_URL != "":
		OS.shell_open(BEER_URL)
	else:
		_hint.text = "Danke! Der Spendenlink folgt."


## Alles aus der aktuellen Bildschirmgröße platzieren.
func _layout() -> void:
	var m := 40.0
	var sz := size
	_title.position = Vector2(m, m * 0.8)
	_title.size = _title.get_combined_minimum_size()
	_menu.position = Vector2(m, _title.position.y + _title.size.y + 24.0)
	_menu.size = _menu.get_combined_minimum_size()
	_top.size = _top.get_combined_minimum_size()
	_top.position = Vector2(sz.x - _top.size.x - m * 0.6, m * 0.6)
	_foot_l.size = _foot_l.get_combined_minimum_size()
	_foot_l.position = Vector2(m, sz.y - _foot_l.size.y - 12.0)
	_foot_r.size = _foot_r.get_combined_minimum_size()
	_foot_r.position = Vector2(sz.x - _foot_r.size.x - m * 0.6, sz.y - _foot_r.size.y - 12.0)
	# Luftschiff rechts neben dem Menü auf Horizonthöhe, zwei Pylone davor/dahinter
	var left := _menu.position.x + _menu.size.x + 30.0
	var w := maxf(sz.x - left - m, 200.0)
	_ship.size = Vector2(w, w * 0.32)
	_ship.position = Vector2(left, sz.y * 0.555 - _ship.size.y * 0.5)
	_pylons[0].size = Vector2(12, sz.y * 0.26)
	_pylons[0].position = Vector2(left - 6.0, sz.y * 0.52)
	_pylons[1].size = Vector2(9, sz.y * 0.17)
	_pylons[1].position = Vector2(sz.x - m - 20.0, sz.y * 0.48)
