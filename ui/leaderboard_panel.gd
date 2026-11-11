# 2026-11-11 20:00 – Neu nach freigegebenem Entwurf: echte Tabelle (eine Zeile je Pilot, Spaltenüberschrift bleibt oben, Zeilen abwechselnd hinterlegt), 100 Plätze mit Scrollen, neuer Eintrag: Liste scrollt hin und die Zeile blinkt; Reiter Aktuell (Quartal) / Best Forever (je Quartal die 3 Besten, aufklappbar 10) / So funktioniert's; Online-Liste von flinkfink.de, ohne Netz die Liste des Geräts
# 2026-11-11 19:20 – „Fertig“ auch oben in der Liste; Tippen aufs Spielfeld schließt die Liste
# 2026-11-11 18:30 – Platz und Liste nach gewerteter Zeit (F7B), gemessene Zeit daneben
# 2026-11-09 13:40 – Ergebnis wird beim Zieleinlauf festgehalten; Knopf „Liste löschen“ mit Rückfrage
# 2026-11-08 17:40 – Nach dem Ziel mit dem Sender bedienbar: rechter Knüppel wählt Eintragen/Nicht eintragen, SH bestätigt
# 2026-10-29 00:19 – Erstversion
# =============================================================================
# LeaderboardPanel.gd
# -----------------------------------------------------------------------------
#   ┌ Bestenliste ─────────────────────────────────────────────── [Fertig] ┐
#   │ [Aktuell (2026Q4 · noch 51 Tage)] [Best Forever] [So funktioniert's]  │
#   │ online · flinkfink.de                                                 │
#   │ Rang │ Name  │ Luffi  │ gemessen │ Runden        │ gewertet │ Datum   │ gespielt mit │  ← bleibt oben
#   │  1   │ Erich │ Chewie │  0:16,0  │ 5,3·5,3·5,4   │  0:11,5  │ 11.11.26│ PC · Sender  │  ← scrollt
#   │  2   │ …                                                              │
#   └───────────────────────────────────────────────────────────────────────┘
# Nach dem Ziel zuerst: Ergebnis + Name eintragen (auch mit dem Sender).
# Gewertet wird nach F7B (Gesamtzeit × Boxfaktor); nur unveränderte Modelle.
# =============================================================================
class_name LeaderboardPanel
extends Control

signal closed

## Spalten: [Überschrift, Breite in px, rechtsbündig]
const COLS := [["Rang", 56, true], ["Name", 180, false], ["Luffi", 150, false], ["gemessen", 96, true],
	["Runden", 190, true], ["gewertet", 104, true], ["Datum", 96, true], ["gespielt mit", 190, false]]
const ROW_H := 34
const COL_GAP := 12                     ## Abstand zwischen den Spalten

var course: Course
var ship: AirshipPhysics
var online: LeaderboardOnline            ## Online-Liste (setzt main.gd)
var box_m := Vector3.ZERO                ## Boxmaß des Schiffs (setzt main.gd)
var fingerprint_source: Callable         ## liefert den Fingerabdruck des Modells (für die Online-Wertung)
var platform_source: Callable            ## liefert z. B. "PC · Sender"
## Bedienung mit dem Sender: liefert den rechten Knüppel links/rechts (−1…1)
var stick_source: Callable

var _panel: PanelContainer
var _box: VBoxContainer
var _name_edit: LineEdit
var _pending := false              ## true = Ergebnis wartet aufs Eintragen
var _choice := 0                   ## 0 = nichts gewählt, 1 = Eintragen, 2 = Nicht eintragen
var _btn_ok: Button
var _btn_no: Button
## Ergebnis beim Zieleinlauf festgehalten (das Rennen kann danach schon zurückgesetzt sein)
var _res_total := 0.0
var _res_score := 0.0
var _res_laps := PackedFloat32Array()
var _tab := 0                      ## 0 Aktuell · 1 Best Forever · 2 So funktioniert's
var _rows_cur: Array = []          ## angezeigte Einträge (online oder Gerät)
var _is_online := false
var _quarter := ""
var _days := 0
var _highlight := {}               ## neuer Eintrag: {"id": …} (online) oder {"name", "score"} (Gerät)
var _bold: FontVariation


func setup(c: Course, s: AirshipPhysics) -> void:
	course = c
	ship = s


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Tippen neben das Fenster schließt die Liste – nicht während der Namenseingabe
	bg.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and not _pending:
			closed.emit())
	add_child(bg)
	_panel = UITheme.make_panel(0)
	add_child(_panel)
	_box = UITheme.make_vbox("sm")
	_panel.add_child(_box)
	_bold = FontVariation.new()
	_bold.base_font = get_theme_default_font()
	_bold.variation_embolden = 0.9
	resized.connect(_layout)


# =============================================================================
# Liste
# =============================================================================
## Liste der aktuellen Strecke zeigen (erst die des Geräts, dann – sobald da – online).
func show_list() -> void:
	_pending = false
	_load_local()
	_fill_list()
	_fetch_online()


func _load_local() -> void:
	_rows_cur = Leaderboard.entries(course.course_key())
	for i in _rows_cur.size():
		_rows_cur[i]["rank"] = i + 1
	_is_online = false
	_quarter = Leaderboard.current_quarter()
	_days = Leaderboard.days_left()


func _fetch_online() -> void:
	if online == null:
		return
	online.list(course.course_key(), func(r: Dictionary):
		if r.get("ok", false) and visible:
			_rows_cur = r.entries
			_is_online = true
			_quarter = str(r.get("quarter", _quarter))
			_days = int(r.get("days_left", _days))
			if not _pending and _tab == 0:
				_fill_list())


## Inhalt sofort entfernen (nicht erst am Bildende), damit die Fenstergröße stimmt.
func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func _fill_list() -> void:
	_clear()
	# Kopfzeile: Titel links, „Fertig“ rechts
	var head := UITheme.make_hbox("sm")
	var title := UITheme.make_title("Bestenliste")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var done := UITheme.make_button("Fertig")
	done.pressed.connect(func(): closed.emit())
	head.add_child(done)
	_box.add_child(head)
	# Reiter
	var tabs := UITheme.make_hbox("xs")
	var names := [I18n.t("Aktuell (%s · noch %d Tage)") % [_quarter, _days], tr("Best Forever"), tr("So funktioniert's")]
	var grp := ButtonGroup.new()
	for i in 3:
		var b := UITheme.make_button(names[i], true)
		b.button_group = grp
		b.button_pressed = i == _tab
		b.pressed.connect(func(): _tab = i; _fill_list(); if i == 1: _fetch_forever())
		tabs.add_child(b)
	_box.add_child(tabs)
	var src := UITheme.make_label("online · flinkfink.de" if _is_online else "Liste auf diesem Gerät (offline)", "MutedLabel")
	_box.add_child(src)
	match _tab:
		0: _fill_current()
		1: _fill_forever(_forever_cache)
		2: _fill_info()
	_layout.call_deferred()


## Reiter „Aktuell“: Tabelle mit fester Überschrift, darunter scrollen.
func _fill_current() -> void:
	_box.add_child(_table_header())
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(_table_width(), minf(ROW_H * 10.5, size.y * 0.55))
	_box.add_child(sc)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	sc.add_child(rows)
	if _rows_cur.is_empty():
		rows.add_child(UITheme.make_label("Noch keine Einträge – flieg 3 Runden!"))
	var hl_row: Control = null
	for i in _rows_cur.size():
		var e: Dictionary = _rows_cur[i]
		var row := _table_row(e, i)
		rows.add_child(row)
		if _is_highlight(e):
			hl_row = row
	if hl_row:
		_blink.call_deferred(sc, hl_row)
	# „Liste löschen“ nur für die Liste auf dem Gerät (online löscht der Admin)
	if not _is_online and not _rows_cur.is_empty():
		var clr := UITheme.make_button("Liste löschen")
		clr.size_flags_horizontal = Control.SIZE_SHRINK_END
		clr.pressed.connect(func():
			if clr.text == tr("Liste löschen"):
				clr.text = tr("Wirklich löschen?")
			else:
				Leaderboard.clear(course.course_key())
				show_list())
		_box.add_child(clr)


func _table_width() -> float:
	var w := 0.0
	for c in COLS: w += float(c[1]) + COL_GAP
	return w + 16.0


## Überschriftenzeile (bleibt oben stehen, weil sie außerhalb des Scrollbereichs liegt).
func _table_header() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(UITheme.color("surface_alt"), Color(0, 0, 0, 0), 4, 6))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", COL_GAP)
	p.add_child(hb)
	for c in COLS:
		var l := _cell(tr(c[0]), c[1], c[2])
		l.add_theme_color_override("font_color", UITheme.color("text_muted"))
		l.add_theme_font_size_override("font_size", UITheme.font_size("caption"))
		hb.add_child(l)
	return p


## Eine Tabellenzeile; jede zweite leicht hinterlegt, damit die Zuordnung klar ist.
func _table_row(e: Dictionary, i: int) -> PanelContainer:
	var p := PanelContainer.new()
	var bg := Color(1, 1, 1, 0.06) if i % 2 == 1 else Color(0, 0, 0, 0)
	p.add_theme_stylebox_override("panel", UITheme.box(bg, Color(0, 0, 0, 0), 2, 6))
	p.custom_minimum_size.y = ROW_H
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", COL_GAP)
	p.add_child(hb)
	var laps: Array = e.get("laps", [])
	var vals := ["%d" % int(e.get("rank", i + 1)), str(e.get("name", "")), str(e.get("model", "")),
		Course.format_time(float(e.get("total", 0.0))), _laps_text(laps),
		Course.format_time(Leaderboard.score_of(e)), _short_date(str(e.get("date", ""))), _platform_text(str(e.get("platform", "")))]
	for k in COLS.size():
		var l := _cell(vals[k], COLS[k][1], COLS[k][2])
		if k == 3 or k == 5:
			l.add_theme_font_override("font", _bold)               # Zeiten fett
		if k == 5:
			l.add_theme_color_override("font_color", UITheme.color("accent"))
		if k == 4 or k == 6 or k == 7:
			l.add_theme_color_override("font_color", UITheme.color("text_muted"))
		hb.add_child(l)
	return p


func _cell(text: String, w: int, right: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(w, 0)
	l.clip_text = true                                             # alles bleibt in einer Zeile
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _is_highlight(e: Dictionary) -> bool:
	if _highlight.is_empty():
		return false
	if _highlight.has("id"):
		return int(e.get("id", -1)) == int(_highlight.id)
	return str(e.get("name", "")) == str(_highlight.get("name", "")) and is_equal_approx(Leaderboard.score_of(e), float(_highlight.get("score", -1.0)))


## Neuer Eintrag: hinscrollen und die Zeile ein paar Mal gelb aufblinken lassen.
func _blink(sc: ScrollContainer, row: Control) -> void:
	await get_tree().process_frame
	sc.ensure_control_visible(row)
	var hl := ColorRect.new()
	hl.color = Color(UITheme.color("warning"), 0.0)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(hl)
	row.move_child(hl, 0)
	var tw := create_tween()
	for k in 4:
		tw.tween_property(hl, "color:a", 0.45, 0.25)
		tw.tween_property(hl, "color:a", 0.08, 0.25)
	tw.tween_property(hl, "color:a", 0.25, 0.3)              # bleibt leicht markiert


# =============================================================================
# Best Forever
# =============================================================================
var _forever_cache: Array = []

func _fetch_forever() -> void:
	_forever_cache = Leaderboard.forever(course.course_key())
	_fill_list()
	if online:
		online.forever(course.course_key(), func(r: Dictionary):
			if r.get("ok", false):
				_forever_cache = r.quarters
				if _tab == 1 and visible and not _pending:
					_fill_list())


## Je vergangenem Quartal: die 3 Besten in einer Zeile, aufklappbar auf 10.
func _fill_forever(list: Array) -> void:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(_table_width(), minf(ROW_H * 11.5, size.y * 0.6))
	_box.add_child(sc)
	var v := UITheme.make_vbox("sm")
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	if list.is_empty():
		v.add_child(UITheme.make_label("Noch kein Quartal abgeschlossen – die 10 Besten jedes Quartals landen hier.", "MutedLabel"))
	for q in list:
		var entries: Array = q.get("entries", [])
		var top3 := []
		for k in mini(3, entries.size()):
			top3.append("%d. %s %s" % [k + 1, entries[k].get("name", ""), Course.format_time(Leaderboard.score_of(entries[k]))])
		var btn := UITheme.make_button("▸  %s   %s" % [_quarter_text(str(q.get("quarter", ""))), "  ·  ".join(top3)], true)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(btn)
		var detail := VBoxContainer.new()
		detail.add_theme_constant_override("separation", 0)
		detail.visible = false
		detail.add_child(_table_header())
		for k in entries.size():
			var e: Dictionary = entries[k]
			e["rank"] = k + 1
			detail.add_child(_table_row(e, k))
		v.add_child(detail)
		btn.toggled.connect(func(on: bool):
			detail.visible = on
			btn.text = ("▾" if on else "▸") + btn.text.substr(1))


static func _quarter_text(q: String) -> String:
	# "2026Q3" → "Q3 2026"
	return "%s %s" % [q.substr(4), q.substr(0, 4)] if q.length() == 6 else q


func _fill_info() -> void:
	var t := UITheme.make_label("So funktioniert die Bestenliste:\n• Gewertet werden 3 Runden. Die gewertete Zeit ist die gemessene Zeit × Boxfaktor nach dem F7B-Reglement – so haben auch kleine, langsamere Luftschiffe eine Chance (Formel unter „Über den Simulator“).\n• Nur unveränderte Modelle aus der Auswahl werden gewertet.\n• Die Liste hat 100 Plätze und gilt für ein Quartal. Am Quartalsende wird sie geleert; die 10 Besten kommen in „Best Forever“.\n• In „Best Forever“ steht jedes vergangene Quartal mit den 3 Besten – antippen zeigt die 10 Besten.\n• „gespielt mit“ zeigt Gerät und Steuerung (PC, Handy, Browser · Sender, Touch, Tastatur).\n• Online-Liste: flinkfink.de. Ohne Verbindung zeigt die App die Liste dieses Geräts.")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(_table_width(), 0)
	_box.add_child(t)


# =============================================================================
# Ergebnis nach dem Ziel
# =============================================================================
func show_result() -> void:
	_pending = true
	_highlight = {}
	_res_total = course.time_s
	_res_score = Course.scored_time(_res_total, box_m) if box_m.x > 0.0 else _res_total
	_res_laps = PackedFloat32Array(course.lap_times)
	_clear()
	var place := Leaderboard.rank_for(course.course_key(), _res_score)
	_box.add_child(UITheme.make_title(I18n.t("Ziel · gewertet %s · Platz %d") % [Course.format_time(_res_score), place]))
	_box.add_child(UITheme.make_label(I18n.t("gemessen %s · Runden %s") % [Course.format_time(_res_total), _laps_text(_res_laps)], "MutedLabel"))
	_box.add_child(UITheme.make_label("Name", "MutedLabel"))
	_name_edit = LineEdit.new()
	_name_edit.text = Leaderboard.last_name()
	_name_edit.max_length = Leaderboard.MAX_NAME
	_name_edit.custom_minimum_size = Vector2(420, UITheme.size("control_height"))
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
	hint.custom_minimum_size.x = 420
	_box.add_child(hint)
	_layout.call_deferred()


## Rechter Senderknüppel wählt (links = Eintragen, rechts = Nicht eintragen).
func _process(_dt: float) -> void:
	if not visible or not _pending or not stick_source.is_valid() or _btn_ok == null or not is_instance_valid(_btn_ok):
		return
	var x: float = stick_source.call()
	if x < -0.5: _choice = 1
	elif x > 0.5: _choice = 2
	_btn_ok.set_pressed_no_signal(_choice == 1)
	_btn_no.set_pressed_no_signal(_choice == 2)


## Schalter SH: Ergebnis-Fenster → gewählte Aktion (ohne Wahl: nicht speichern); Liste → schließen.
func confirm_by_switch() -> void:
	if _pending and _choice == 1:
		_on_enter()
	else:
		_pending = false
		closed.emit()


## Eintragen: auf dem Gerät speichern und – bei unverändertem Modell – online.
## Danach die Liste zeigen, zum Eintrag scrollen und ihn aufblinken lassen.
func _on_enter() -> void:
	var platform: String = platform_source.call() if platform_source.is_valid() else ""
	var name := _name_edit.text
	Leaderboard.add(course.course_key(), _res_total, _res_laps, name, ship.model_name, _res_score, platform)
	var clean := name.strip_edges().left(Leaderboard.MAX_NAME)
	_highlight = {"name": clean if clean != "" else "Pilot", "score": snappedf(_res_score, 0.01)}
	_pending = false
	_tab = 0
	_load_local()
	_fill_list()
	if online and fingerprint_source.is_valid():
		var laps := []
		for t in _res_laps: laps.append(snappedf(t, 0.01))
		online.submit({"course": course.course_key(), "name": name, "fp": fingerprint_source.call(),
			"total": snappedf(_res_total, 0.01), "laps": laps, "platform": platform,
			"version": BuildInfo.VERSION}, func(r: Dictionary):
				if r.get("ok", false):
					_highlight = {"id": int(r.id)}
				_fetch_online())


static func _laps_text(laps) -> String:
	var parts: Array[String] = []
	for t in laps: parts.append(I18n.dec("%.1f" % float(t)))
	return " · ".join(parts)


## "2026-11-11" → "11.11.26"
static func _short_date(d: String) -> String:
	if d.length() < 10: return d
	return "%s.%s.%s" % [d.substr(8, 2), d.substr(5, 2), d.substr(2, 2)]


## "PC · Sender" → in der gewählten Sprache
static func _platform_text(p: String) -> String:
	var parts := []
	for s in p.split(" · ", false):
		parts.append(I18n.t(s))
	return " · ".join(parts)


## Feld mittig, höchstens 92 % der Bildschirmhöhe; zu breit (Handy) → verkleinern.
func _layout() -> void:
	_panel.size = Vector2.ZERO
	var want := _panel.get_combined_minimum_size()
	_panel.size = want
	var k := minf(1.0, minf((size.x - 16.0) / want.x, (size.y - 16.0) / want.y))
	_panel.scale = Vector2(k, k)
	_panel.position = (size - want * k) * 0.5
