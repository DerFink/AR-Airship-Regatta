# 2026-11-11 19:45 – Erstversion: Online-Bestenliste auf flinkfink.de (Liste, Best Forever, Eintragen) – ohne Verbindung arbeitet die App mit der Liste auf dem Gerät weiter
# =============================================================================
# LeaderboardOnline.gd
# -----------------------------------------------------------------------------
# Spricht server/rc-airship/api.php an. Jede Anfrage ruft ihren Rückruf mit
# dem Ergebnis (Dictionary) auf – bei Fehler/ohne Netz mit {} (dann zeigt die
# Bestenliste die Liste dieses Geräts).
#   list(course, cb)     → {"ok", "quarter", "days_left", "entries": [...]}
#   forever(course, cb)  → {"ok", "quarters": [{"quarter", "entries"}]}
#   submit(entry, cb)    → {"ok", "id", "rank", "score", "listed"}
# =============================================================================
class_name LeaderboardOnline
extends Node

## Adresse der Schnittstelle (Strato, Unterordner rc-airship)
const API_URL := "https://flinkfink.de/rc-airship/api.php"
const TIMEOUT_S := 6.0

## false, solange die letzte Anfrage gescheitert ist (für den Hinweis „offline“)
var reachable := true


func list(course: String, cb: Callable) -> void:
	_get_api("?action=list&course=" + course.uri_encode(), cb)


func forever(course: String, cb: Callable) -> void:
	_get_api("?action=forever&course=" + course.uri_encode(), cb)


## entry: {"course","name","fp","total","laps":[3],"platform","version"}
func submit(entry: Dictionary, cb: Callable) -> void:
	var e := entry.duplicate()
	e["action"] = "submit"
	_request(API_URL, HTTPClient.METHOD_POST, JSON.stringify(e), cb)


func _get_api(query: String, cb: Callable) -> void:
	_request(API_URL + query, HTTPClient.METHOD_GET, "", cb)


## Eine Anfrage mit eigenem HTTPRequest-Knoten (wird danach gelöscht).
func _request(url: String, method: int, body: String, cb: Callable) -> void:
	var rq := HTTPRequest.new()
	rq.timeout = TIMEOUT_S
	add_child(rq)
	rq.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, data: PackedByteArray):
		rq.queue_free()
		var parsed = null
		if result == HTTPRequest.RESULT_SUCCESS:
			parsed = JSON.parse_string(data.get_string_from_utf8())
		var ok := parsed is Dictionary and (code < 500)
		reachable = ok
		if cb.is_valid():
			cb.call(parsed if ok else {}))
	var err := rq.request(url, ["Content-Type: application/json"], method, body)
	if err != OK:
		rq.queue_free()
		reachable = false
		if cb.is_valid():
			cb.call({})
