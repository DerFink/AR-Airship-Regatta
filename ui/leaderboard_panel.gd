# 2026-11-11 18:30 – Platz und Liste nach gewerteter Zeit (F7B), gemessene Zeit daneben
# 2026-11-11 17:45 – Texte mit Zahlen übersetzt
# 2026-11-09 13:40 – Ergebnis wird beim Zieleinlauf festgehalten (vorher: SH setzte zugleich das Rennen zurück → Eintrag mit 0 s); Knopf „Liste löschen“ mit Rückfrage
# 2026-11-08 17:40 – Nach dem Ziel mit dem Sender bedienbar: rechter Knüppel wählt Eintragen/Nicht eintragen, SH bestätigt (ohne Wahl nicht gespeichert)
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
## Bedienung mit dem Sender: liefert den rechten Knüppel links/rechts (−1…1)
var stick_source: Callable
var _choice := 0                   ## 0 = nichts gewählt, 1 = Eintragen, 2 = Nicht eintragen
var _btn_ok: Button
var _btn_no: Button
## Ergebnis beim Zieleinlauf festgehalten – das Rennen kann danach schon
## zurückgesetzt sein (Schalter SH bestätigt UND setzt zurück)
var _res_total := 0.0
var _res_score := 0.0                ## gewertete Zeit (F7B) des letzten Rennens
var box_m := Vector3.ZERO             ## Boxmaß des Schiffs (setzt main.gd)
var _res_laps := PackedFloat32Array()


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
	_res_total = course.time_s
	_res_score = Course.scored_time(_res_total, box_m) if box_m.x > 0.0 else _res_total
	_res_laps = PackedFloat32Array(course.lap_times)
	for c in _box.get_children(): c.queue_free()
	var place := Leaderboard.rank_for(course.course_key(), _res_score)
	_box.add_child(UITheme.make_title(I18n.t("Ziel · %s · Platz %d") % [Course.format_time(_res_score), place]))
	_box.add_child(UITheme.make_label(I18n.t("gewertet · gemessen %s") % Course.format_time(_res_total), "MutedLabel"))
	_box.add_child(UITheme.make_label(I18n.t("%s · Runden %s") % [course.title(), _laps_text(_res_laps)], "MutedLabel"))
	_box.add_child(UITheme.make_label("Name", "MutedLabel"))
	_name_edit = LineEdit.new()
	_name_edit.text = Leaderboard.last_name()
	_name_edit.max_length = Leaderboard.MAX_NAME
	_name_edit.custom_minimum_size.y = UITheme.size("control_height")
	_name_edit.placeholder_text = "Dein Name"
	_box.add_child(_name_edit)
	var row := UITheme.make_hbox("sm")
	var ok := UITheme.make_button("◀ Eintragen")
	ok.pressed.connect(_on_enter)
	var no := UITheme.make_button("Nicht eintragen ▶")
	no.pressed.connect(func(): _pending = false; closed.emit())
	for b in [ok, no]:
		b.toggle_mode = true                     # „gedrückt“ = mit dem Knüppel markiert
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	_btn_ok = ok
	_btn_no = no
	_choice = 0
	_box.add_child(row)
	var hint := UITheme.make_label("Sender: rechter Knüppel links/rechts = wählen · Schalter SH = bestätigen (ohne Wahl: nicht gespeichert)", "MutedLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(hint)
	_layout.call_deferred()


## Rechter Senderknüppel wählt (links = Eintragen, rechts = Nicht eintragen).
func _process(_dt: float) -> void:
	if not visible or not _pending or not stick_source.is_valid() or _btn_ok == null:
		return
	var x: float = stick_source.call()
	if x < -0.5: _choice = 1
	elif x > 0.5: _choice = 2
	_btn_ok.set_pressed_no_signal(_choice == 1)
	_btn_no.set_pressed_no_signal(_choice == 2)


## Schalter SH: Ergebnis-Fenster → gewählte Aktion (ohne Wahl: nicht speichern,
## schließen); Liste → schließen.
func confirm_by_switch() -> void:
	if _pending and _choice == 1:
		_on_enter()                              # speichern, danach Liste zeigen
	else:
		_pending = false
		closed.emit()


func _on_enter() -> void:
	Leaderboard.add(course.course_key(), _res_total, _res_laps, _name_edit.text, ship.model_name, _res_score)
	_pending = false
	_fill_list()


func _fill_list() -> void:
	for c in _box.get_children(): c.queue_free()
	_box.add_child(UITheme.make_title(I18n.t("Bestenliste · %s") % course.title()))
	_box.add_child(UITheme.make_label("Gewertete Zeit nach F7B (Gesamtzeit × Boxfaktor) · 3 Runden", "MutedLabel"))
	var lst := Leaderboard.entries(course.course_key())
	if lst.is_empty():
		_box.add_child(UITheme.make_label("Noch keine Einträge – flieg 3 Runden!"))
	for i in lst.size():
		var e: Dictionary = lst[i]
		var top := UITheme.make_label(I18n.t("%d.  %s  ·  gemessen %s   (Runden %s)") % [i + 1, Course.format_time(Leaderboard.score_of(e)),
			Course.format_time(float(e.get("total", 0.0))), _laps_text(e.get("laps", []))])
		_box.add_child(top)
		var sub := UITheme.make_label("     %s · %s · %s" % [e.get("name", ""), e.get("model", ""), e.get("date", "")], "MutedLabel")
		_box.add_child(sub)
	var row := UITheme.make_hbox("sm")
	# „Liste löschen“: erst antippen → Rückfrage im Knopf, zweites Antippen löscht
	var clr := UITheme.make_button("Liste löschen")
	clr.disabled = lst.is_empty()
	clr.pressed.connect(func():
		if clr.text == "Liste löschen":
			clr.text = "Wirklich löschen?"
		else:
			Leaderboard.clear(course.course_key())
			_fill_list())
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	for b in [clr, done]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	_box.add_child(row)
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
