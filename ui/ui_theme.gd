# 2026-10-29 00:19 – Größere Knöpfe (PillButton: Schrift 19, Mindesthöhe 52); Reiter-Schrift größer
# 2026-10-27 15:10 – Größere Bedienelemente fürs Handy: dicke Slider-Spur, großer Griff, −/+-Knöpfe an jedem Regler; neue Bausteine make_stepper() und make_choice_row(); größere Schrift und Seitenleiste
# 2026-10-27 12:25 – make_banner(width): feste Textbreite, damit der Zeilenumbruch nicht jedes Wort einzeln umbricht
# 2026-10-27 11:08 – Stile für Reiter (TabContainer), Textfeld (TextEdit) und Kontrollkästchen ergänzt
# 2026-10-27 10:42 – Erstversion: zentrales Design-System (Tokens aus theme_tokens.json mit eingebauten Standardwerten), Godot-Theme-Erzeugung, einheitliche Bausteine (Panel, Pill, Knopf, Slider-Zeile, Banner, Abschnittstitel)
# =============================================================================
# UITheme.gd
# -----------------------------------------------------------------------------
# EINE Stelle für das gesamte Aussehen der App.
#
#   1. Design-Tokens   – Farben, Radien, Abstände, Schriftgrößen, Maße.
#                        Stehen in res://ui/theme_tokens.json und können dort
#                        ohne Programmieren angepasst werden. Fehlt die Datei
#                        oder ein Eintrag, gelten die DEFAULTS unten.
#   2. Godot-Theme     – build_theme() erzeugt daraus ein Theme, das an den
#                        obersten UI-Knoten gehängt wird. Alle Buttons, Slider,
#                        Labels usw. erben es automatisch.
#   3. Bausteine       – make_panel(), make_pill(), make_slider_row() …
#                        Jede Ansicht baut ihre Elemente NUR über diese
#                        Funktionen. So bleibt alles einheitlich, und eine
#                        Optimierung an einer Stelle wirkt überall.
# =============================================================================
class_name UITheme
extends RefCounted

const TOKEN_FILE := "res://ui/theme_tokens.json"

## Eingebaute Standardwerte (identisch mit theme_tokens.json).
const DEFAULTS := {
	"color": {
		"backdrop": "#0b0f14b3", "surface": "#161c23e6", "surface_alt": "#222a33",
		"border": "#ffffff1f", "border_strong": "#ffffff40",
		"text": "#e9eef3", "text_muted": "#9aa7b4",
		"accent": "#3d8bfd", "accent_bg": "#3d8bfd33",
		"success": "#3fb27f",
		"warning": "#e0a43a", "warning_bg": "#e0a43a33",
		"danger": "#e5534b", "danger_bg": "#e5534b33",
		"stick_ring": "#ffffff55", "stick_knob": "#ffffffbb",
		"plot_setpoint": "#9aa7b4", "plot_measure": "#3d8bfd",
	},
	"radius": {"sm": 6, "md": 10, "lg": 16},
	"space": {"xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24},
	"font": {"caption": 16, "body": 19, "title": 22},
	"size": {"control_height": 52, "stick_diameter": 240, "panel_side_width": 400},
}

static var _tokens: Dictionary = {}
static var _theme: Theme


# =============================================================================
# Token-Zugriff
# =============================================================================

## Alle Tokens (beim ersten Aufruf aus der JSON-Datei geladen und mit den
## Standardwerten zusammengeführt).
static func tokens() -> Dictionary:
	if _tokens.is_empty():
		_tokens = DEFAULTS.duplicate(true)
		if FileAccess.file_exists(TOKEN_FILE):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(TOKEN_FILE))
			if parsed is Dictionary:
				_merge(_tokens, parsed)
	return _tokens


## Tokens neu laden (z. B. nach Bearbeiten der JSON-Datei im laufenden Spiel).
static func reload() -> void:
	_tokens = {}
	_theme = null


static func _merge(base: Dictionary, over: Dictionary) -> void:
	for k in over:
		if base.has(k) and base[k] is Dictionary and over[k] is Dictionary:
			_merge(base[k], over[k])
		elif not str(k).begins_with("_"):
			base[k] = over[k]


static func color(name: String) -> Color:
	return Color.from_string(str(tokens().color.get(name, "#ff00ff")), Color.MAGENTA)

static func radius(name: String) -> int:
	return int(tokens().radius.get(name, 8))

static func space(name: String) -> int:
	return int(tokens().space.get(name, 8))

static func font_size(name: String) -> int:
	return int(tokens().font.get(name, 16))

static func size(name: String) -> int:
	return int(tokens().size.get(name, 48))


# =============================================================================
# StyleBox-Fabrik: jede Fläche der App entsteht hier
# =============================================================================
static func box(bg: Color, border := Color(0, 0, 0, 0), r := -1, pad := -1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius("md") if r < 0 else r)
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(1)
	var p := space("md") if pad < 0 else pad
	sb.content_margin_left = p
	sb.content_margin_right = p
	sb.content_margin_top = p * 0.6
	sb.content_margin_bottom = p * 0.6
	sb.anti_aliasing = true
	return sb


# =============================================================================
# Godot-Theme aus den Tokens
# =============================================================================
static func build_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = font_size("body")

	# Texte
	for type in ["Label", "Button", "CheckBox", "OptionButton", "LineEdit", "ItemList"]:
		t.set_color("font_color", type, color("text"))
	t.set_color("font_color", "MutedLabel", color("text_muted"))
	t.set_type_variation("MutedLabel", "Label")
	t.set_font_size("font_size", "MutedLabel", font_size("caption"))
	t.set_type_variation("TitleLabel", "Label")
	t.set_font_size("font_size", "TitleLabel", font_size("title"))

	# Flächen
	t.set_stylebox("panel", "PanelContainer", box(color("surface"), color("border"), radius("lg"), space("lg")))
	t.set_stylebox("panel", "Panel", box(color("surface"), color("border"), radius("lg")))

	# Knöpfe: normal / gedrückt / ausgewählt (toggle) / Fokus
	var h := size("control_height")
	t.set_constant("h_separation", "Button", space("sm"))
	t.set_stylebox("normal", "Button", box(color("surface_alt"), color("border_strong"), radius("md")))
	t.set_stylebox("hover", "Button", box(color("surface_alt").lightened(0.08), color("border_strong"), radius("md")))
	t.set_stylebox("pressed", "Button", box(color("accent_bg"), color("accent"), radius("md")))
	t.set_stylebox("hover_pressed", "Button", box(color("accent_bg"), color("accent"), radius("md")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", box(color("surface"), color("border"), radius("md")))
	t.set_color("font_pressed_color", "Button", color("accent"))
	t.set_color("font_hover_pressed_color", "Button", color("accent"))
	t.set_color("font_disabled_color", "Button", color("text_muted"))

	# Pill = kleine Info-Kachel (Telemetrie, Schalter in der Flugansicht)
	t.set_type_variation("Pill", "Button")
	t.set_font_size("font_size", "Pill", font_size("caption"))
	for st in ["normal", "hover", "disabled"]:
		t.set_stylebox(st, "Pill", box(color("surface"), color("border_strong"), radius("sm"), space("sm")))
	for st in ["pressed", "hover_pressed"]:
		t.set_stylebox(st, "Pill", box(color("accent_bg"), color("accent"), radius("sm"), space("sm")))

	# PillButton = antippbare Pill (Schalter/Knöpfe in der Flugansicht):
	# größere Schrift und mehr Innenabstand – am Handy gut zu treffen
	t.set_type_variation("PillButton", "Button")
	t.set_font_size("font_size", "PillButton", font_size("body"))
	for st in ["normal", "hover", "disabled"]:
		t.set_stylebox(st, "PillButton", box(color("surface"), color("border_strong"), radius("md"), space("md")))
	for st in ["pressed", "hover_pressed"]:
		t.set_stylebox(st, "PillButton", box(color("accent_bg"), color("accent"), radius("md"), space("md")))

	# Schieberegler
	# dicke Spur und großer Griff – am Handy gut zu treffen
	var track := box(color("surface_alt"), color("border"), 5, 0)
	track.content_margin_top = 5; track.content_margin_bottom = 5
	var fill := box(color("accent"), Color(0, 0, 0, 0), 5, 0)
	fill.content_margin_top = 5; fill.content_margin_bottom = 5
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _circle_icon(34, color("accent")))
	t.set_icon("grabber_highlight", "HSlider", _circle_icon(38, color("accent").lightened(0.15)))

	# Listen / Auswahl
	t.set_stylebox("panel", "ItemList", box(color("surface_alt"), color("border"), radius("md"), space("sm")))
	t.set_stylebox("selected", "ItemList", box(color("accent_bg"), color("accent"), radius("sm"), space("xs")))
	t.set_stylebox("selected_focus", "ItemList", box(color("accent_bg"), color("accent"), radius("sm"), space("xs")))
	t.set_stylebox("normal", "OptionButton", box(color("surface_alt"), color("border_strong"), radius("md")))
	t.set_stylebox("normal", "LineEdit", box(color("surface_alt"), color("border_strong"), radius("md")))

	# Reiter (Baukasten: Technik / Gestaltung) – sehen aus wie die Pill-Schalter
	t.set_stylebox("tab_selected", "TabContainer", box(color("accent_bg"), color("accent"), radius("sm"), space("md")))
	t.set_stylebox("tab_unselected", "TabContainer", box(color("surface_alt"), color("border_strong"), radius("sm"), space("md")))
	t.set_stylebox("tab_hovered", "TabContainer", box(color("surface_alt").lightened(0.08), color("border_strong"), radius("sm"), space("md")))
	t.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	t.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())
	t.set_color("font_selected_color", "TabContainer", color("accent"))
	t.set_color("font_unselected_color", "TabContainer", color("text_muted"))
	t.set_color("font_hovered_color", "TabContainer", color("text"))
	t.set_constant("side_margin", "TabContainer", 0)
	t.set_font_size("font_size", "TabContainer", font_size("body"))
	t.set_stylebox("normal", "TextEdit", box(color("surface_alt"), color("border_strong"), radius("md")))
	t.set_color("font_color", "TextEdit", color("text"))
	t.set_color("font_color", "CheckBox", color("text"))

	# Mindesthöhe für Touch-Ziele
	t.set_constant("minimum_character_width", "LineEdit", 4)
	_theme = t
	_min_height = h
	return t

static var _min_height := 48


## Runder Schieberegler-Knopf, zur Laufzeit gezeichnet (keine Bilddatei nötig).
static func _circle_icon(d: int, c: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d * 0.5
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(c, clampf(r - dist, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# =============================================================================
# Bausteine – jede Ansicht nutzt ausschließlich diese Fabriken
# =============================================================================

## Seitenleiste / Karte mit Innenabstand.
static func make_panel(min_width := 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = min_width
	return p


## Senkrechter Stapel mit Token-Abstand.
static func make_vbox(gap := "sm") -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", space(gap))
	return v

static func make_hbox(gap := "sm") -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", space(gap))
	return h


static func make_label(text: String, variant := "") -> Label:
	var l := Label.new()
	l.text = text
	if variant != "":
		l.theme_type_variation = variant
	return l


## Abschnittstitel in Seitenleisten.
static func make_title(text: String) -> Label:
	return make_label(text, "TitleLabel")


## Normaler Knopf mit Touch-tauglicher Mindesthöhe. toggle = Umschalter.
static func make_button(text: String, toggle := false, icon_text := "") -> Button:
	var b := Button.new()
	b.text = (icon_text + "  " if icon_text != "" else "") + text
	b.toggle_mode = toggle
	b.custom_minimum_size.y = _min_height
	b.focus_mode = Control.FOCUS_NONE
	return b


## Kleine Kachel (Telemetrie-Anzeige oder Menüschalter in der Flugansicht).
static func make_pill(text: String, clickable := false) -> Button:
	var b := Button.new()
	b.theme_type_variation = "PillButton" if clickable else "Pill"
	b.text = text
	if clickable:                                  # Mindestgröße für den Finger
		b.custom_minimum_size = Vector2(64, size("control_height"))
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	return b


## Gruppe gegenseitig ausschließender Umschalter (z. B. Modus-Wahl).
static func make_toggle_group() -> ButtonGroup:
	var g := ButtonGroup.new()
	g.allow_unpress = false
	return g


# -----------------------------------------------------------------------------
# Slider-Zeile:  Beschriftung | Schieberegler | Wert
# on_change(value) wird bei jeder Änderung aufgerufen. fmt formatiert die
# Wertanzeige (z. B. "%.2f m³").
# -----------------------------------------------------------------------------
static func make_slider_row(label: String, min_v: float, max_v: float, step: float,
		value: float, on_change: Callable, fmt := "%.2f", _label_width := 110) -> VBoxContainer:
	# Zwei Zeilen, damit der Regler am Handy die ganze Breite bekommt:
	#   Beschriftung ………………… Wert
	#   [−] ─────────●───────── [+]
	# −/+ ändern um einen Schritt (feine Werte), der Griff ist groß.
	var box := make_vbox("xs")
	var top := make_hbox("sm")
	var l := make_label(label, "MutedLabel")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(l)
	var out := make_label(fmt % value)
	out.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(out)
	box.add_child(top)
	var row := make_hbox("sm")
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(120, _min_height)
	s.focus_mode = Control.FOCUS_NONE
	row.add_child(_step_button("−", func(): s.value = s.value - step))
	row.add_child(s)
	row.add_child(_step_button("+", func(): s.value = s.value + step))
	box.add_child(row)
	s.value_changed.connect(func(v: float):
		out.text = fmt % v
		on_change.call(v))
	box.set_meta("slider", s)          # für späteres Setzen von außen
	box.set_meta("out", out)           # Wertanzeige
	return box


## Kleiner quadratischer −/+-Knopf mit Touch-tauglicher Größe.
static func _step_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(_min_height * 0.85, _min_height * 0.85)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	return b


## Zahl mit −/+ (z. B. Flossenanzahl). on_change(int) bei jeder Änderung.
static func make_stepper(label: String, min_v: int, max_v: int, value: int,
		on_change: Callable, label_width := 110) -> HBoxContainer:
	var row := make_hbox("xs")
	var l := make_label(label, "MutedLabel")
	l.custom_minimum_size.x = label_width
	row.add_child(l)
	var out := make_label(str(value))
	out.custom_minimum_size.x = 40
	out.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var set_v := func(v: int):
		v = clampi(v, min_v, max_v)
		out.text = str(v)
		on_change.call(v)
	row.add_child(_step_button("−", func(): set_v.call(int(out.text) - 1)))
	row.add_child(out)
	row.add_child(_step_button("+", func(): set_v.call(int(out.text) + 1)))
	row.set_meta("out", out)
	return row


## Reihe von Umschaltern (genau einer aktiv). on_pick(index).
static func make_choice_row(labels: Array, selected: int, on_pick: Callable) -> HBoxContainer:
	var row := make_hbox("xs")
	var g := make_toggle_group()
	for i in labels.size():
		var b := make_button(str(labels[i]), true)
		b.button_group = g
		b.button_pressed = i == selected
		b.custom_minimum_size.x = _min_height
		b.pressed.connect(func(): on_pick.call(i))
		row.add_child(b)
	return row


# -----------------------------------------------------------------------------
# Hinweis-Banner (Warnung / Fehler / Info). set_banner() ändert Text & Stil.
# -----------------------------------------------------------------------------
## width = feste Breite des Banners; der Text bricht innerhalb dieser Breite um
## (ohne feste Breite würde der Umbruch jedes Wort in eine eigene Zeile setzen).
static func make_banner(width := 360) -> PanelContainer:
	var p := PanelContainer.new()
	var l := make_label("")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width - 2 * space("sm")
	l.add_theme_font_size_override("font_size", font_size("caption"))   # Hinweise kompakt
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_banner(p, "", "info")
	return p


## level: "info", "success", "warning", "danger"
static func set_banner(p: PanelContainer, text: String, level := "info") -> void:
	var l: Label = p.get_child(0)
	l.text = text
	p.visible = text != ""
	var fg := color("text")
	var bg := color("surface")
	match level:
		"success": fg = color("success"); bg = Color(color("success"), 0.2)
		"warning": fg = color("warning"); bg = color("warning_bg")
		"danger": fg = color("danger"); bg = color("danger_bg")
	l.add_theme_color_override("font_color", fg)
	p.add_theme_stylebox_override("panel", box(bg, Color(fg, 0.5), radius("md"), space("sm")))
