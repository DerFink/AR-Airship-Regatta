# 2026-11-12 12:00 – Leeres Feld möglich (allow_empty: leer = Vorschlag)
# 2026-11-12 11:30 – Erstversion: Zahlenfeld mit −/+ für den Baukasten (statt Schieberegler; Regler bleiben nur für Lagen)
# =============================================================================
# NumberField.gd
# -----------------------------------------------------------------------------
# Eine Zeile zum Eingeben einer Zahl:
#
#   Beschriftung ………………………  [−] [   0,25 ] [+]  m³
#
# - Feld antippen → Ziffernblock (Handy) bzw. Tastatur; Komma oder Punkt als
#   Dezimalzeichen, übernommen mit Enter oder beim Verlassen des Feldes.
# - −/+ ändern um einen Schritt (step).
# - Werte außerhalb min … max werden auf die Grenze gesetzt; max_v = INF heißt
#   „ohne Obergrenze“ (z. B. Volumen).
# - Anzeige im Format fmt („%.2f m³“, „%d g“ …): die Zahl steht im Feld, der
#   Rest (Einheit) dahinter; Dezimalzeichen nach Sprache (I18n.dec).
# Für den Baukasten hat das Feld dieselben Metadaten wie make_slider_row:
# set_value_no_signal() setzt den Wert von außen, ohne on_change auszulösen.
# =============================================================================
class_name NumberField
extends HBoxContainer

signal value_changed(v: float)

var min_v := 0.0
var max_v := INF
var step := 1.0
var value := 0.0
var num_fmt := "%.2f"                 ## nur der Zahlenteil des Formats („%.2f“)
## Leeres Feld erlaubt (z. B. „eigenes Gewicht“: leer = Vorschlag verwenden).
## Leer meldet value_changed(-1); −/+ beginnen dann bei empty_base.
var allow_empty := false
var empty := false
var empty_base := 0.0
var _edit: LineEdit
var _unit: Label


## label: Beschriftung, fmt: Format mit Einheit („%.2f m³“).
func setup(label: String, min_value: float, max_value: float, step_value: float, start: float, fmt: String) -> void:
	min_v = min_value; max_v = max_value; step = step_value
	add_theme_constant_override("separation", UITheme.space("xs"))
	var l := UITheme.make_label(label, "MutedLabel")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	add_child(l)
	add_child(UITheme._step_button("−", func(): _apply((empty_base if empty else value) - step, true)))
	_edit = LineEdit.new()
	_edit.custom_minimum_size = Vector2(96, UITheme.size("control_height"))
	_edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	_edit.select_all_on_focus = true
	_edit.text_submitted.connect(func(_t): _from_text(); _edit.release_focus())
	_edit.focus_exited.connect(_from_text)
	add_child(_edit)
	add_child(UITheme._step_button("+", func(): _apply((empty_base if empty else value) + step, true)))
	_unit = UITheme.make_label("")
	_unit.custom_minimum_size.x = 44
	add_child(_unit)
	# Knöpfe und Feld bleiben normal hoch, auch wenn die Beschriftung umbricht
	for c in get_children():
		if c != l: (c as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_format(fmt)
	value = start
	_show()


## Format (und damit die Einheit) ändern, z. B. „%.1f cm“ statt „%.1f"“.
func set_format(fmt: String) -> void:
	var re := RegEx.new()
	re.compile("%[-+0-9.]*[dfs]")
	var m := re.search(fmt)
	num_fmt = m.get_string() if m else "%.2f"
	var unit := fmt.replace(num_fmt, "").replace("%%", "%").strip_edges() if m else ""
	_unit.text = I18n.t(unit) if unit != "" else ""
	_show()


## Wert von außen setzen, ohne value_changed auszulösen (Modellwechsel).
func set_value_no_signal(v: float) -> void:
	empty = allow_empty and v < 0.0
	if not empty:
		value = clampf(v, min_v, max_v)
	_show()


## Feld leeren (nur mit allow_empty): meldet value_changed(-1).
func clear() -> void:
	if not allow_empty: return
	empty = true
	_show()
	value_changed.emit(-1.0)


## Grenzen ändern (z. B. beim Umschalten der Einheit).
func set_range(min_value: float, max_value: float, step_value: float) -> void:
	min_v = min_value; max_v = max_value; step = step_value


func _apply(v: float, emit := true) -> void:
	v = clampf(v, min_v, max_v)
	value = v
	empty = false
	_show()
	if emit:
		value_changed.emit(v)


## Eingetippten Text übernehmen (Komma oder Punkt); Unsinn → alter Wert.
func _from_text() -> void:
	var t := _edit.text.strip_edges().replace(",", ".").replace(" ", "")
	if allow_empty and t == "":
		if not empty: clear()
		return
	if t.is_valid_float():
		var v := float(t)
		if empty or not is_equal_approx(v, value):
			_apply(v)
			return
	_show()


func _show() -> void:
	if _edit:
		_edit.text = "" if empty else I18n.dec(num_fmt % value)
