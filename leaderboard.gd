# 2026-10-29 00:19 – Erstversion: Bestenliste je Strecke (Wertung über 3 Runden, Einzelrunden gespeichert), Top 10, Name wird gemerkt; Datei user://bestenliste.json
# =============================================================================
# Leaderboard.gd
# -----------------------------------------------------------------------------
# Speichert die besten Rennen (3 Runden, nur vollständig geflogene) auf dem
# Gerät. Eine Liste je Strecke:
#   "cup"        – FN Hugo Eckener Cup
#   "frei_25.0"  – freie Strecke mit 25 m Pylonabstand
# Jeder Eintrag: Gesamtzeit, die drei Rundenzeiten, Name, Luftschiff, Datum.
# Das Dateiformat ist schlichtes JSON – später kann die Liste (wie die
# Modell-Strings) geteilt werden.
# =============================================================================
class_name Leaderboard
extends RefCounted

const PATH := "user://bestenliste.json"
const MAX_ENTRIES := 10
const MAX_NAME := 20


## Ganze Datei lesen: {"name": letzter Name, "lists": {strecke: [Einträge]}}
static func _load() -> Dictionary:
	var data := {"name": "", "lists": {}}
	if not FileAccess.file_exists(PATH):
		return data
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return data
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data.name = str(parsed.get("name", ""))
		if parsed.get("lists") is Dictionary:
			data.lists = parsed.lists
	return data


static func _save(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


## Einträge einer Strecke, schnellste zuerst.
static func entries(course_key: String) -> Array:
	var lst = _load().lists.get(course_key, [])
	return lst if lst is Array else []


## Zuletzt verwendeter Name (Vorbelegung des Eingabefelds).
static func last_name() -> String:
	return _load().name


## Schafft es diese Gesamtzeit in die Top 10? Rückgabe: Platz (1…10) oder 0.
static func rank_for(course_key: String, total: float) -> int:
	var lst := entries(course_key)
	var place := 1
	for e in lst:
		if float(e.get("total", 0.0)) <= total:
			place += 1
	return place if place <= MAX_ENTRIES else 0


## Rennen eintragen; Rückgabe: Platz (1…10) oder 0, wenn nicht in den Top 10.
static func add(course_key: String, total: float, laps: PackedFloat32Array, name: String, model: String) -> int:
	var data := _load()
	var clean := name.strip_edges().left(MAX_NAME)
	if clean == "":
		clean = "Pilot"
	data.name = clean
	var lst: Array = data.lists.get(course_key, [])
	var lap_list := []
	for t in laps: lap_list.append(snappedf(t, 0.01))
	lst.append({"total": snappedf(total, 0.01), "laps": lap_list, "name": clean,
		"model": model.left(40), "date": Time.get_date_string_from_system()})
	lst.sort_custom(func(a, b): return float(a.total) < float(b.total))
	lst = lst.slice(0, MAX_ENTRIES)
	data.lists[course_key] = lst
	_save(data)
	for i in lst.size():
		if lst[i].name == clean and is_equal_approx(float(lst[i].total), snappedf(total, 0.01)):
			return i + 1
	return 0
