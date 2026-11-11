# 2026-11-11 16:30 – Erstversion: Rennanzeige rechts oben – Rundenzeiten untereinander, Gesamtzeit und gewertete Zeit nach der F7B-Formel
# =============================================================================
# RacePanel.gd
# -----------------------------------------------------------------------------
#   ┌──────────────────────────────┐
#   │ Runde 3 / 3                  │   Titel (im Ziel: „Ziel“)
#   │ Runde 1             0:18,4   │   fertige Runden (beste grün)
#   │ Runde 2             0:16,9   │
#   │ Runde 3             0:09,7 … │   laufende Runde (gelb)
#   │ ───────────────────────────  │
#   │ Gesamt              0:45,0   │
#   │ Gewertet            0:35,6   │   = Gesamt × V_Box^(1/3) (F7B)
#   │ = Gesamt × V_Box^(1/3) (Box …)    │
#   └──────────────────────────────┘
# Wird vor dem Start ausgeblendet; bleibt nach dem Ziel stehen, bis
# zurückgesetzt wird.
# =============================================================================
class_name RacePanel
extends PanelContainer

var course: Course
var box_m := Vector3.ZERO           ## Boxmaß über alles (Länge, Breite, Höhe) in m
var _title: Label
var _grid: GridContainer
var _total: Label
var _scored: Label
var _formula: Label
var _rows: Array = []               ## [Name-Label, Zeit-Label] je Runde


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UITheme.box(Color(UITheme.color("surface"), 0.85), UITheme.color("border"), -1, UITheme.space("md")))
	var v := UITheme.make_vbox("xs")
	add_child(v)
	_title = UITheme.make_label("")
	_title.add_theme_font_size_override("font_size", UITheme.font_size("title"))
	v.add_child(_title)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", UITheme.space("lg"))
	v.add_child(_grid)
	for i in Course.LAPS:
		var n := UITheme.make_label(I18n.t("Runde %d") % (i + 1), "MutedLabel")
		var t := UITheme.make_label("")
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(n); _grid.add_child(t)
		_rows.append([n, t])
	v.add_child(HSeparator.new())
	var g2 := GridContainer.new()
	g2.columns = 2
	g2.add_theme_constant_override("h_separation", UITheme.space("lg"))
	v.add_child(g2)
	g2.add_child(UITheme.make_label("Gesamt", "MutedLabel"))
	_total = UITheme.make_label("")
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g2.add_child(_total)
	g2.add_child(UITheme.make_label("Gewertet", "MutedLabel"))
	_scored = UITheme.make_label("")
	_scored.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_scored.add_theme_font_size_override("font_size", UITheme.font_size("title"))
	_scored.add_theme_color_override("font_color", UITheme.color("accent"))
	g2.add_child(_scored)
	_formula = UITheme.make_label("", "MutedLabel")
	_formula.add_theme_font_size_override("font_size", UITheme.font_size("caption"))
	v.add_child(_formula)


## Jeden Physikschritt von der Flugansicht aufgerufen.
func refresh() -> void:
	if course == null:
		return
	visible = course.race != Course.Race.WAIT
	if not visible:
		return
	var done := course.race == Course.Race.DONE
	_title.text = I18n.t("Ziel") if done else I18n.t("Runde %d / %d") % [course.lap, Course.LAPS]
	# beste fertige Runde (grün)
	var best := -1
	for i in course.lap_times.size():
		if best < 0 or course.lap_times[i] < course.lap_times[best]:
			best = i
	for i in _rows.size():
		var t: Label = _rows[i][1]
		var c := UITheme.color("text")
		if i < course.lap_times.size():
			t.text = Course.format_time(course.lap_times[i])
			if i == best and course.lap_times.size() > 1: c = UITheme.color("success")
		elif i == course.lap_times.size() and not done:
			t.text = Course.format_time(course.current_lap_time()) + " …"
			c = UITheme.color("warning")
		else:
			t.text = "–"
			c = UITheme.color("text_muted")
		t.add_theme_color_override("font_color", c)
	_total.text = Course.format_time(course.time_s)
	if box_m.x > 0.0:
		_scored.text = Course.format_time(Course.scored_time(course.time_s, box_m))
		_formula.text = I18n.dec(I18n.t("= Gesamt × V_Box^(1/3) (Box %.2f × %.2f × %.2f m)") % [box_m.x, box_m.y, box_m.z])
	else:
		_scored.text = "–"
		_formula.text = ""
