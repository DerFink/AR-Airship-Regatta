# 2026-11-11 19:40 – Quartalsweise: 100 Plätze je Strecke und Quartal; zum Quartalsende kommen die 10 Besten in „Best Forever“, der Rest wird gelöscht; Einträge mit Plattform („PC · Sender“ …) und Quartal
# 2026-11-11 18:30 – Sortierung nach gewerteter Zeit (F7B: Gesamtzeit × Boxfaktor); Feld "score" je Eintrag, alte Einträge zählen mit der Gesamtzeit
# 2026-11-09 13:40 – Ungültige Einträge (Zeit 0 oder keine 3 Runden) werden nicht gespeichert und nicht angezeigt; clear(): Liste einer Strecke löschen
# 2026-10-29 00:19 – Erstversion: Bestenliste je Strecke (Wertung über 3 Runden, Einzelrunden gespeichert), Top 10, Name wird gemerkt; Datei user://bestenliste.json
# =============================================================================
# Leaderboard.gd  (Bestenliste auf diesem Gerät – die Online-Liste liegt auf
# flinkfink.de, siehe LeaderboardOnline und server/rc-airship/)
# -----------------------------------------------------------------------------
# Eine Liste je Strecke („cup“, „frei_25.0“, „wiese_200.0“) und Quartal:
#   lists[strecke]            – laufendes Quartal, bis 100 Einträge
#   forever[strecke][quartal] – vergangene Quartale, je die 10 Besten
# Sortiert wird nach der GEWERTETEN Zeit (F7B) – so haben auch kleine,
# langsamere Luftschiffe eine Chance. Jeder Eintrag:
#   {total, score, laps[3], name, model, date "JJJJ-MM-TT", platform, quarter}
# Beim Laden wird geprüft, ob ein Quartal vorbei ist (Umzug nach „Forever“).
# =============================================================================
class_name Leaderboard
extends RefCounted

const PATH := "user://bestenliste.json"
const MAX_ENTRIES := 100          ## Plätze je Strecke und Quartal
const FOREVER_KEEP := 10          ## so viele kommen je Quartal in „Best Forever“
const MAX_NAME := 20


## Laufendes Quartal, z. B. "2026Q4" (Systemzeit, UTC).
static func current_quarter() -> String:
	var d := Time.get_datetime_dict_from_system(true)
	return "%dQ%d" % [d.year, (int(d.month) - 1) / 3 + 1]


## Tage bis zum Quartalsende (für „noch … Tage“).
static func days_left() -> int:
	var d := Time.get_datetime_dict_from_system(true)
	var q := (int(d.month) - 1) / 3 + 1
	var y := int(d.year)
	var end_month := q * 3 + 1
	if end_month > 12:
		end_month = 1; y += 1
	var end_unix := Time.get_unix_time_from_datetime_dict({"year": y, "month": end_month, "day": 1, "hour": 0, "minute": 0, "second": 0})
	return int(ceil((end_unix - Time.get_unix_time_from_system()) / 86400.0))


## Ganze Datei lesen: {"name", "lists": {strecke: [...]}, "forever": {strecke: {quartal: [...]}}}.
## Ist ein Quartal vorbei, werden dessen 10 Beste nach „forever“ verschoben.
static func _load() -> Dictionary:
	var data := {"name": "", "lists": {}, "forever": {}}
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				data.name = str(parsed.get("name", ""))
				if parsed.get("lists") is Dictionary: data.lists = parsed.lists
				if parsed.get("forever") is Dictionary: data.forever = parsed.forever
	if _roll_over(data):
		_save(data)
	return data


## Vergangene Quartale aus den laufenden Listen nach „forever“ verschieben.
## Alte Einträge ohne Quartal zählen zum Quartal ihres Datums.
static func _roll_over(data: Dictionary) -> bool:
	var cur := current_quarter()
	var changed := false
	for course in data.lists.keys():
		var keep := []
		var past := {}
		for e in data.lists[course]:
			if not e is Dictionary: continue
			var q := str(e.get("quarter", _quarter_of_date(str(e.get("date", "")))))
			e["quarter"] = q
			if q == cur: keep.append(e)
			else:
				past[q] = past.get(q, []) + [e]
				changed = true
		data.lists[course] = keep
		for q in past:
			var lst: Array = past[q]
			lst.sort_custom(func(a, b): return score_of(a) < score_of(b))
			if not data.forever.has(course): data.forever[course] = {}
			var old: Array = data.forever[course].get(q, [])
			var merged := old + lst
			merged.sort_custom(func(a, b): return score_of(a) < score_of(b))
			data.forever[course][q] = merged.slice(0, FOREVER_KEEP)
	return changed


static func _quarter_of_date(date: String) -> String:
	if date.length() < 7: return current_quarter()
	return "%sQ%d" % [date.substr(0, 4), (int(date.substr(5, 2)) - 1) / 3 + 1]


static func _save(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


## Gewertete Zeit eines Eintrags (alte Einträge: Gesamtzeit).
static func score_of(e: Dictionary) -> float:
	return float(e.get("score", e.get("total", 0.0)))


## Einträge einer Strecke im laufenden Quartal, beste gewertete Zeit zuerst.
static func entries(course_key: String) -> Array:
	var lst = _load().lists.get(course_key, [])
	if not lst is Array:
		return []
	# nur gültige Rennen (Zeit > 0) – fängt alte, fehlerhafte Einträge ab
	var ok: Array = lst.filter(func(e): return e is Dictionary and float(e.get("total", 0.0)) > 0.0)
	ok.sort_custom(func(a, b): return score_of(a) < score_of(b))
	return ok


## „Best Forever“: [{quarter, entries}] – neuestes vergangenes Quartal zuerst.
static func forever(course_key: String) -> Array:
	var f: Dictionary = _load().forever.get(course_key, {})
	var qs := f.keys()
	qs.sort()
	qs.reverse()
	var out := []
	for q in qs:
		out.append({"quarter": q, "entries": f[q]})
	return out


## Zuletzt verwendeter Name (Vorbelegung des Eingabefelds).
static func last_name() -> String:
	return _load().name


## Schafft es diese gewertete Zeit in die 100? Rückgabe: Platz (1…100) oder 0.
static func rank_for(course_key: String, score: float) -> int:
	var lst := entries(course_key)
	var place := 1
	for e in lst:
		if score_of(e) <= score:
			place += 1
	return place if place <= MAX_ENTRIES else 0


## Rennen eintragen; Rückgabe: Platz (1…100) oder 0, wenn nicht unter den 100.
static func add(course_key: String, total: float, laps: PackedFloat32Array, name: String, model: String,
		score := -1.0, platform := "") -> int:
	if total <= 0.0 or laps.size() < 3:
		return 0                                  # kein vollständiges Rennen → nicht speichern
	if score <= 0.0:
		score = total
	var data := _load()
	var clean := name.strip_edges().left(MAX_NAME)
	if clean == "":
		clean = "Pilot"
	data.name = clean
	var lst: Array = (data.lists.get(course_key, []) as Array).filter(func(e): return float(e.get("total", 0.0)) > 0.0)
	var lap_list := []
	for t in laps: lap_list.append(snappedf(t, 0.01))
	var entry := {"total": snappedf(total, 0.01), "score": snappedf(score, 0.01), "laps": lap_list, "name": clean,
		"model": model.left(40), "date": Time.get_date_string_from_system(), "platform": platform,
		"quarter": current_quarter()}
	lst.append(entry)
	lst.sort_custom(func(a, b): return score_of(a) < score_of(b))
	lst = lst.slice(0, MAX_ENTRIES)
	data.lists[course_key] = lst
	_save(data)
	return lst.find(entry) + 1


## Bestenliste einer Strecke löschen (Knopf „Liste löschen“). Der gemerkte Name bleibt.
static func clear(course_key: String) -> void:
	var data := _load()
	data.lists.erase(course_key)
	_save(data)
