# 2026-11-10 14:30 – Location „Halle | Wiese“; Pylonabstand als Zahlenfeld (kein Schieberegler, 5–500 m); Akku (Zellen, Kapazität) als Zahlenfelder
# 2026-10-29 00:19 – Knopf „Bestenliste“
# 2026-10-28 08:14 – Erstversion: Einstellfeld „Strecke“ (FN Hugo Eckener Cup 18 m oder frei mit Pylonabstand 5–50 m)
# =============================================================================
# CoursePanel.gd
# -----------------------------------------------------------------------------
#   ┌ Strecke ─────────────────────────────────────┐
#   │ Location  [Halle] [Wiese]                     │
#   │ [FN Hugo Eckener Cup (18 m)] [Frei]  (Halle)  │
#   │ Pylonabstand [  18 ] m                        │
#   │ Feld 25 × 20 m · 3 Runden, fliegender Start   │
#   │ Akku  Zellen [4]  Kapazität [300] mAh         │
#   │ [Bestenliste]                       [Fertig]  │
#   └──────────────────────────────────────────────┘
# Zahlenfelder: Zahl eintippen, mit Enter oder beim Verlassen des Feldes wird
# sie übernommen (ungültige Eingaben werden auf den erlaubten Bereich begrenzt).
# Jede Änderung der Strecke baut sie neu auf und stellt das Schiff an den Start.
# =============================================================================
class_name CoursePanel
extends Control

signal closed
## Strecke wurde geändert → Schiff an den Start, Rennen zurücksetzen
signal course_changed
## Bestenliste der aktuellen Strecke öffnen
signal leaderboard_requested

var course: Course
var battery: Battery
var _box: VBoxContainer
var _panel: PanelContainer


func setup(c: Course, b: Battery = null) -> void:
	course = c
	battery = b


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()                       # abgedunkelter Hintergrund
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = UITheme.make_panel(560)
	add_child(_panel)
	_box = UITheme.make_vbox("md")
	_panel.add_child(_box)
	visibility_changed.connect(func(): if visible: _fill())
	resized.connect(_layout)
	_fill()


## Inhalt neu aufbauen (Felder zeigen immer den aktuellen Stand).
func _fill() -> void:
	for c in _box.get_children():
		_box.remove_child(c)                         # sofort raus, damit die Größe stimmt
		c.queue_free()
	_box.add_child(UITheme.make_title("Strecke"))
	# Location
	var loc_row := UITheme.make_hbox("sm")
	loc_row.add_child(UITheme.make_label("Location"))
	loc_row.add_child(UITheme.make_choice_row(Course.LOCATION_NAMES, course.location, func(i):
		course.set_location(i); course_changed.emit(); _fill.call_deferred()))
	_box.add_child(loc_row)
	# Halle: Cup oder frei
	if course.location == 0:
		_box.add_child(UITheme.make_choice_row(["%s (%d m)" % [Course.CUP_NAME, roundi(Course.CUP_DISTANCE)], "Frei"],
			course.preset, func(i): course.set_course(i, course.free_distance); course_changed.emit(); _fill.call_deferred()))
	# Pylonabstand als Zahl (Halle: tippen schaltet auf „Frei“)
	var drow := UITheme.make_hbox("sm")
	drow.add_child(UITheme.make_label("Pylonabstand"))
	drow.add_child(_number_field(course.distance(), 0, func(v: float):
		course.set_distance(v); course_changed.emit(); _fill.call_deferred()))
	drow.add_child(UITheme.make_label("m  (%d–%d)" % [roundi(Course.MIN_DISTANCE), roundi(Course.MAX_DISTANCE)], "MutedLabel"))
	_box.add_child(drow)
	var d := course.distance()
	var info_txt := "Feld %d × %d m · %d Runden, fliegender Start am vorderen Pylon" % [
		roundi(d + 2.0 * Course.FIELD_MARGIN), roundi(Course.FIELD_WIDTH), Course.LAPS]
	info_txt += " · Halle: Wände 10 m hinter der Linie, Decke 25 m" if course.location == 0 else " · Wiese: keine Begrenzung"
	var info := UITheme.make_label(info_txt, "MutedLabel")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 500
	_box.add_child(info)
	# Akku
	if battery:
		var brow := UITheme.make_hbox("sm")
		brow.add_child(UITheme.make_label("Akku  Zellen"))
		brow.add_child(_number_field(battery.cells, 0, func(v: float):
			battery.set_pack(int(v), battery.capacity_mah); _fill.call_deferred()))
		brow.add_child(UITheme.make_label("Kapazität"))
		brow.add_child(_number_field(battery.capacity_mah, 0, func(v: float):
			battery.set_pack(battery.cells, v); _fill.call_deferred()))
		brow.add_child(UITheme.make_label("mAh", "MutedLabel"))
		_box.add_child(brow)
	var row := UITheme.make_hbox("sm")
	var lb := UITheme.make_button("Bestenliste")
	lb.pressed.connect(func(): leaderboard_requested.emit())
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	for b in [lb, done]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	_box.add_child(row)
	_layout.call_deferred()


## Zahlenfeld: zeigt den Wert, übernimmt eine eingetippte Zahl mit Enter oder
## beim Verlassen. Komma und Punkt sind beide erlaubt.
func _number_field(value: float, decimals: int, on_set: Callable) -> LineEdit:
	var e := LineEdit.new()
	e.text = ("%." + str(decimals) + "f") % value
	e.custom_minimum_size.x = 90
	e.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	e.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL   # Handy: Zahlentastatur
	var apply := func():
		var t := e.text.strip_edges().replace(",", ".")
		if t.is_valid_float() and absf(float(t) - value) > 0.0001:
			on_set.call(float(t))
		else:
			e.text = ("%." + str(decimals) + "f") % value     # ungültig → alten Wert zeigen
	e.text_submitted.connect(func(_t): apply.call())
	e.focus_exited.connect(func(): apply.call())
	return e


## Feld mittig platzieren.
func _layout() -> void:
	_panel.reset_size()
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = (size - _panel.size) * 0.5
