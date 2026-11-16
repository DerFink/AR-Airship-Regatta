# 2026-11-17 01:05 – Marke „Start“ nur beim Rennstart (nicht bei manuellem Start mitten im Rennen); Dateiname Cup/Wiese100m/Frei50m
# 2026-11-17 00:40 – Erstversion: Aufnahmeknopf (nur Browser) – Rennen als Film mitschneiden, Marken für Start/Runden/Ziel, nach dem Ziel Schneidefenster
# =============================================================================
# RaceRecorder.gd  (Kind der Flugansicht; die eigentliche Aufnahme macht
# web/ar-recorder.js im Browser, hier nur Bedienung und Ablauf)
# -----------------------------------------------------------------------------
#   Knopf „●“ oben rechts in der Flugansicht:
#     antippen  → Aufnahme starten  („● REC 0:31“, rot)
#     nochmal   → Aufnahme beenden, Schneidefenster öffnet sich
#   Einstellungen: „Aufnahme beim Rennstart automatisch“ (AppSettings.rec_auto)
#                  „Ton mit aufnehmen“ (AppSettings.rec_audio)
#   Automatisch: läuft eine Aufnahme, endet sie 3 s nach dem Ziel von selbst.
#   Marken: Start, Runde 1 … , Ziel – im Schneidefenster als gelbe Striche,
#   die blauen Griffe rasten dort ein.
# Nur im Browser verfügbar (MediaRecorder); in der App ist der Knopf unsichtbar.
# =============================================================================
class_name RaceRecorder
extends RefCounted

## Knopf in der oberen Reihe der Flugansicht
var button: Button
var course: Course
var ship: AirshipPhysics

var _available := false
var _recording := false
var _last_race := -1
var _last_lap := 0
var _stop_in := -1.0           ## s bis zum automatischen Ende nach dem Ziel


func _init(c: Course, s: AirshipPhysics) -> void:
	course = c
	ship = s
	button = UITheme.make_pill("●", true)
	button.tooltip_text = I18n.t("Rennen als Film aufnehmen (Browser)")
	button.pressed.connect(toggle)
	_available = OS.has_feature("web") and bool(_js("!!(window.arRec && arRec.supported())"))
	button.visible = _available
	if _available:
		_js("arRec.setTexts(%s)" % JSON.stringify(JSON.stringify({
			"title": I18n.t("Aufnahme"), "discard": I18n.t("Verwerfen"), "saveAll": I18n.t("Ganz speichern"),
			"cut": I18n.t("Zuschneiden & speichern"), "cutting": I18n.t("Schneide …"), "section": I18n.t("Ausschnitt"),
			"help": I18n.t("Anfang und Ende mit den blauen Griffen setzen (rasten an Start, Runden und Ziel ein). Zuschneiden spielt den Ausschnitt einmal ab und nimmt ihn neu auf – das dauert so lange wie der Ausschnitt."),
			"file": I18n.t("Datei")})))


static func _js(code: String):
	if not OS.has_feature("web"):
		return null
	return JavaScriptBridge.eval(code, true)


func is_recording() -> bool:
	return _recording


## Knopf: starten bzw. beenden (mit Schneidefenster).
func toggle() -> void:
	if not _available:
		return
	if _recording:
		stop(true)
	else:
		start()


func start() -> void:
	if _recording or not _available:
		return
	var mime = _js("arRec.start(%s)" % ("true" if AppSettings.rec_audio else "false"))
	_recording = str(mime) != "" and mime != null
	_stop_in = -1.0


func stop(open_editor: bool) -> void:
	if not _recording:
		return
	_recording = false
	_stop_in = -1.0
	_js("arRec.stop(%s, %s)" % [JSON.stringify(_file_name()), "true" if open_editor else "false"])


## Dateiname: Modell_Strecke_Zeit, z. B. Chewie_Cup_0-35-6
func _file_name() -> String:
	var where := "Cup"
	if course.location == 1:
		where = "Wiese%dm" % int(course.meadow_distance)
	elif course.preset != 0:
		where = "Frei%dm" % int(course.free_distance)
	var t := ""
	if course.race == Course.Race.DONE:
		t = "_" + Course.format_time(course.time_s).replace(":", "-").replace(",", "-").replace(".", "-")
	return "%s_%s%s" % [ship.model_name if ship.model_name != "" else "Luftschiff", where, t]


## Marke für das Schneidefenster setzen (Text wird übersetzt)
func _mark(label: String) -> void:
	_js("arRec.mark(%s)" % JSON.stringify(label))


## Jedes Bild aus der Flugansicht: Rennzustand beobachten, Knopf beschriften.
func update(dt: float) -> void:
	if not _available:
		return
	var race := int(course.race)
	if race != _last_race:
		if race == Course.Race.RUN:
			if AppSettings.rec_auto and not _recording:
				start()
			if _recording:
				_mark(I18n.t("Start"))
			_last_lap = 1
		elif race == Course.Race.DONE and _recording:
			_mark(I18n.t("Ziel"))
			_stop_in = 3.0                       # noch 3 s nach dem Ziel aufnehmen
		_last_race = race
	if race == Course.Race.RUN and course.lap > _last_lap:
		if _recording:
			_mark(I18n.t("Runde %d") % (course.lap - 1))
		_last_lap = course.lap
	if _stop_in >= 0.0:
		_stop_in -= dt
		if _stop_in < 0.0:
			stop(true)
	# Beschriftung: „●“ oder „● REC 0:31“
	if _recording:
		var s := float(_js("arRec.elapsed()"))
		button.text = "● REC %d:%02d" % [int(s) / 60, int(s) % 60]
		button.add_theme_color_override("font_color", Color("ff5a5f"))
	else:
		button.text = "●"
		button.remove_theme_color_override("font_color")
