# 2026-11-14 22:00 – Einwilligung (Fassung + Text), Geräte-Kennung beim Eintragen, eigene Einträge löschen, Besucherzähler, Links zu Impressum/Datenschutz
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
#                          (nur mit Einwilligung; Geräte-Kennung wird angehängt)
#   delete_mine(cb)      → {"ok", "deleted"}  alle Online-Einträge dieses Geräts löschen
#   hit()                → Besucherzähler +1 (nur Tag und Plattform)
# =============================================================================
class_name LeaderboardOnline
extends Node

## Adresse der Schnittstelle (Strato, Unterordner rc-airship)
const API_URL := "https://flinkfink.de/rc-airship/api.php"
const TIMEOUT_S := 6.0
## Impressum und Datenschutz (auf derselben Seite wie die Schnittstelle)
const IMPRESSUM_URL := "https://flinkfink.de/rc-airship/impressum.html"
const DATENSCHUTZ_URL := "https://flinkfink.de/rc-airship/datenschutz.html"
## Fassung des Einwilligungstextes. Bei JEDER inhaltlichen Änderung des Textes
## erhöhen – und in server/rc-airship/lib.php (CONSENT_VERSION) gleich setzen.
const CONSENT_VERSION := 1
## Einwilligungstext (wie mit dem Betreiber abgestimmt)
const CONSENT_TEXT := "Deine Zeit online eintragen? Gespeichert werden der Pilotenname, den du frei wählst, Luftschiff, Rundenzeiten, Datum und App-Version für 2 Jahre auf flinkfink.de. Für alle sichtbar in der Online-Bestenliste. Unter 16 bitte nur mit Erlaubnis der Eltern."

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
	e["device"] = AppSettings.device()          # zum späteren Selbstlöschen
	e["consent"] = AppSettings.online_consent   # Server prüft die Fassung
	_request(API_URL, HTTPClient.METHOD_POST, JSON.stringify(e), cb)


## Widerruf: alle Online-Einträge dieses Geräts löschen.
func delete_mine(cb: Callable) -> void:
	_request(API_URL, HTTPClient.METHOD_POST, JSON.stringify({"action": "delete_device", "device": AppSettings.device()}), cb)


## Besucherzähler: einmal je Start der App bzw. der Browser-Version. Übertragen
## wird nur die Plattform; der Server speichert Tag, Plattform und Anzahl.
func hit() -> void:
	if DisplayServer.get_name() == "headless":
		return                                      # Tests und Werkzeuge zählen nicht
	var pf := "pc"
	match OS.get_name():
		"Android": pf = "android"
		"iOS": pf = "ios"
		"Web": pf = "web"
	_request(API_URL, HTTPClient.METHOD_POST, JSON.stringify({"action": "hit", "platform": pf}), Callable())


## Darf diese Zeit online eingetragen werden? (Schalter an und Einwilligung in der aktuellen Fassung)
static func may_submit() -> bool:
	return AppSettings.online_on and AppSettings.online_consent == CONSENT_VERSION


## Muss vor dem Eintragen noch gefragt werden?
static func needs_consent() -> bool:
	return AppSettings.online_on and AppSettings.online_consent != CONSENT_VERSION


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
