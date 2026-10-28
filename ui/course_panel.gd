# 2026-10-28 08:14 – Erstversion: Einstellfeld „Strecke“ (FN Hugo Eckener Cup 18 m oder frei mit Pylonabstand 5–50 m)
# =============================================================================
# CoursePanel.gd
# -----------------------------------------------------------------------------
#   ┌ Strecke ─────────────────────────────────────┐
#   │ [FN Hugo Eckener Cup (18 m)] [Frei]          │
#   │ Pylonabstand ───────●──────────────── 25 m   │
#   │ Feld 32 × 20 m · 3 Runden, fliegender Start  │
#   │                                     [Fertig] │
#   └──────────────────────────────────────────────┘
# Jede Änderung baut die Strecke neu auf und stellt das Schiff an den Start.
# =============================================================================
class_name CoursePanel
extends Control

signal closed
## Strecke wurde geändert → Schiff an den Start, Rennen zurücksetzen
signal course_changed

var course: Course
var _box: VBoxContainer
var _panel: PanelContainer


func setup(c: Course) -> void:
	course = c


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


## Inhalt neu aufbauen (Regler zeigen immer den aktuellen Stand).
func _fill() -> void:
	for c in _box.get_children(): c.queue_free()
	_box.add_child(UITheme.make_title("Strecke"))
	_box.add_child(UITheme.make_choice_row(["%s (%d m)" % [Course.CUP_NAME, roundi(Course.CUP_DISTANCE)], "Frei"],
		course.preset, func(i): course.set_course(i, course.free_distance); course_changed.emit(); _fill()))
	# Regler gilt für „Frei“; wer ihn bewegt, schaltet automatisch auf „Frei“
	_box.add_child(UITheme.make_slider_row("Pylonabstand (frei)", Course.MIN_DISTANCE, Course.MAX_DISTANCE, 0.5,
		course.free_distance, _on_distance, "%.1f m"))
	var d := course.distance()
	var info := UITheme.make_label("Feld %d × %d m · %d Runden, fliegender Start am vorderen Pylon" % [
		roundi(d + 2.0 * Course.FIELD_MARGIN), roundi(Course.FIELD_WIDTH), Course.LAPS], "MutedLabel")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(info)
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	_box.add_child(done)
	_layout.call_deferred()


func _on_distance(v: float) -> void:
	var switched := course.preset != 1
	course.set_course(1, v)
	course_changed.emit()
	if switched:
		_fill.call_deferred()              # Auswahl auf „Frei“ umstellen


## Feld mittig platzieren.
func _layout() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = (size - _panel.size) * 0.5
