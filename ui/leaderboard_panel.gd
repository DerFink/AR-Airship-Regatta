# 2026-10-29 00:19 – Erstversion: Bestenliste anzeigen (Platz, Gesamtzeit, Einzelrunden, Name, Luftschiff, Datum) und nach dem Ziel Namen eintragen
# =============================================================================
# LeaderboardPanel.gd
# -----------------------------------------------------------------------------
#   Liste:                                     Eintragen (nach dem Ziel):
#   ┌ Bestenliste · FN Hugo Eckener Cup ┐      ┌ Ziel · 1:08,2 · Platz 1 ─────┐
#   │ 1  1:08,2  R 22,9 · 22,8 · 22,5   │      │ Runden 22,9 · 22,8 · 22,5     │
#   │    Erich · Chewie · 2026-10-29    │      │ Name [Erich          ]        │
#   │ 2  …                              │      │ [Eintragen]  [Nicht eintragen]│
#   │                         [Fertig]  │      └───────────────────────────────┘
#   └───────────────────────────────────┘
# Gewertet wird die Gesamtzeit über 3 Runden; nur vollständige Rennen.
# =============================================================================
class_name LeaderboardPanel
extends Control

signal closed

var course: Course
var ship: AirshipPhysics
var _panel: PanelContainer
var _box: VBoxContainer
var _name_edit: LineEdit
var _pending := false              ## true = Ergebnis wartet aufs Eintragen


func setup(c: Course, s: AirshipPhysics) -> void:
	course = c
	ship = s


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = UITheme.make_panel(640)
	add_child(_panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(sc)
	_box = UITheme.make_vbox("md")
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_box)
	resized.connect(_layout)


## Liste der aktuellen Strecke zeigen.
func show_list() -> void:
	_pending = false
	_fill_list()


## Nach dem Ziel: Ergebnis zeigen und Namen abfragen (nur wenn Top 10).
func show_result() -> void:
	_pending = true
	for c in _box.get_children(): c.queue_free()
	var place := Leaderboard.rank_for(course.course_key(), course.time_s)
	_box.add_child(UITheme.make_title("Ziel · %s · Platz %d" % [Course.format_time(course.time_s), place]))
	_box.add_child(UITheme.make_label("%s · Runden %s" % [course.title(), _laps_text(course.lap_times)], "MutedLabel"))
	_box.add_child(UITheme.make_label("Name", "MutedLabel"))
	_name_edit = LineEdit.new()
	_name_edit.text = Leaderboard.last_name()
	_name_edit.max_length = Leaderboard.MAX_NAME
	_name_edit.custom_minimum_size.y = UITheme.size("control_height")
	_name_edit.placeholder_text = "Dein Name"
	_box.add_child(_name_edit)
	var row := UITheme.make_hbox("sm")
	var ok := UITheme.make_button("Eintragen")
	ok.pressed.connect(_on_enter)
	var no := UITheme.make_button("Nicht eintragen")
	no.pressed.connect(func(): _pending = false; closed.emit())
	row.add_child(ok)
	row.add_child(no)
	_box.add_child(row)
	_layout.call_deferred()


func _on_enter() -> void:
	Leaderboard.add(course.course_key(), course.time_s, course.lap_times, _name_edit.text, ship.model_name)
	_pending = false
	_fill_list()


func _fill_list() -> void:
	for c in _box.get_children(): c.queue_free()
	_box.add_child(UITheme.make_title("Bestenliste · %s" % course.title()))
	_box.add_child(UITheme.make_label("Wertung über 3 Runden · nur vollständige Rennen", "MutedLabel"))
	var lst := Leaderboard.entries(course.course_key())
	if lst.is_empty():
		_box.add_child(UITheme.make_label("Noch keine Einträge – flieg 3 Runden!"))
	for i in lst.size():
		var e: Dictionary = lst[i]
		var top := UITheme.make_label("%d.  %s   (Runden %s)" % [i + 1, Course.format_time(float(e.get("total", 0.0))), _laps_text(e.get("laps", []))])
		_box.add_child(top)
		var sub := UITheme.make_label("     %s · %s · %s" % [e.get("name", ""), e.get("model", ""), e.get("date", "")], "MutedLabel")
		_box.add_child(sub)
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	_box.add_child(done)
	_layout.call_deferred()


static func _laps_text(laps) -> String:
	var parts: Array[String] = []
	for t in laps: parts.append(Course.format_time(float(t)))
	return " · ".join(parts)


## Feld mittig, höchstens 90 % der Bildhöhe (dann scrollen).
func _layout() -> void:
	var want := _box.get_combined_minimum_size() + Vector2(32, 32)
	_panel.size = Vector2(maxf(640.0, want.x), minf(want.y, size.y * 0.9))
	_panel.position = (size - _panel.size) * 0.5
