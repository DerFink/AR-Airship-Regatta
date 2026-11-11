# 2026-11-11 15:40 – Texte in eigene Dateien i18n/about_<sprache>.txt ausgelagert, jetzt in allen 8 Sprachen; Abschnitt „Mit KI erstellt“ mit Hinweis, dass KI Fehler machen kann
# 2026-11-11 08:40 – Physik: Abschnitt „Profilierte Flossen und Reynoldszahl“ (DE/EN)
# 2026-11-11 01:30 – Quelle Johannes Eissing (Gertler Shape Generator)
# 2026-11-11 00:20 – Formeln ohne Zeichen, die die Handy-Schrift nicht hat (ₐ → _a, ω̇ → dω/dt)
# 2026-11-10 21:10 – Erstversion: „Grundlagen des Simulators“ mit Reitern Physik, Luftschiff-Modell, Regler (PID), Akku, Über / Lizenz (Texte Deutsch und Englisch; andere Sprachen zeigen den englischen Text)
# =============================================================================
# AboutPanel.gd
# -----------------------------------------------------------------------------
#   ┌ Grundlagen des Simulators ─────────────────────────────── [Schließen] ┐
#   │ [Physik] [Luftschiff-Modell] [Regler (PID)] [Akku] [Über / Lizenz]     │
#   │ ┌──────────────────────────────────────────────────────────────────┐ │
#   │ │ Text mit Formeln (scrollt)                                       │ │
#   │ └──────────────────────────────────────────────────────────────────┘ │
#   └────────────────────────────────────────────────────────────────────────┘
# Die Texte stehen in i18n/about_<sprache>.txt als BBCode (RichTextLabel). Sie beschreiben, was der
# Simulator wirklich rechnet (airship_physics.gd, flight_controller.gd,
# battery.gd) – bei Änderungen dort bitte in allen Sprachdateien nachziehen.
# =============================================================================
class_name AboutPanel
extends Control

signal closed

const CONTACT := "erich.fink ät aerarium.de"
const TABS := ["Physik", "Luftschiff-Modell", "Regler (PID)", "Akku", "Über / Lizenz"]

var _text: RichTextLabel
var _tab_btns: Array[Button] = []
var _tab := 0


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
	var title := UITheme.make_title("Grundlagen des Simulators")
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var b_close := UITheme.make_button("Schließen")
	b_close.pressed.connect(func(): closed.emit())
	head.add_child(b_close)
	root.add_child(head)
	# Reiter
	var tabs := UITheme.make_hbox("xs")
	var grp := UITheme.make_toggle_group()
	for i in TABS.size():
		var b := UITheme.make_pill(TABS[i], true)
		b.toggle_mode = true
		b.button_group = grp
		var idx := i
		b.pressed.connect(func(): _show(idx))
		tabs.add_child(b)
		_tab_btns.append(b)
	root.add_child(tabs)
	# Text
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.box(Color("161d27"), Color("2c3746"), -1, 16))
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.selection_enabled = false
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 19)
	box.add_child(_text)
	root.add_child(box)
	visibility_changed.connect(func(): if visible: _show(_tab))
	_show(0)


## Reiter i in der gewählten Sprache anzeigen.
func _show(i: int) -> void:
	_tab = i
	for k in _tab_btns.size():
		_tab_btns[k].set_pressed_no_signal(k == i)
	var texts := load_texts(I18n.current)
	var t: String = texts[i] if i < texts.size() else ""
	_text.text = t.replace("{CONTACT}", CONTACT).replace("{VERSION}", BuildInfo.text())
	_text.scroll_to_line(0)


## Texte einer Sprache aus res://i18n/about_<sprache>.txt (Reiter durch @@@
## getrennt). Fehlt die Datei, wird Englisch genommen, dann Deutsch.
static func load_texts(lang: String) -> PackedStringArray:
	for code in [lang, "en", "de"]:
		var path := "res://i18n/about_%s.txt" % code
		if not FileAccess.file_exists(path):
			continue
		var raw := FileAccess.get_file_as_string(path)
		if raw == "":
			continue
		var keep := PackedStringArray()
		for line in raw.split("\n"):
			if not line.begins_with("#"):
				keep.append(line)
		var parts := "\n".join(keep).split("\n@@@\n")
		for k in parts.size():
			parts[k] = parts[k].strip_edges()
		return parts
	return PackedStringArray()
