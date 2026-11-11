# 2026-11-11 17:45 – Update-Meldungen übersetzt
# 2026-11-08 18:15 – Browser-Version: „Nach Update suchen“ lädt die neue Seite (ar-<Build>.html, jeder Build mit eigenen Dateinamen – kein Zwischenspeicher-Problem)
# 2026-11-07 21:10 – Erstversion: Update-Suche über die GitHub-Releases (neuester „Android-Build N“ gegen BuildInfo.BUILD); neuere APK wird im Browser heruntergeladen
# =============================================================================
# Updater.gd
# -----------------------------------------------------------------------------
# Fragt bei GitHub nach dem neuesten Release:
#   GET https://api.github.com/repos/<REPO>/releases/latest
#   → tag_name "android-build-N", assets[0].browser_download_url (die APK)
# Ist N größer als die eigene Build-Nummer, öffnet die App den Download-Link
# im Browser. Android lädt die APK herunter; Antippen der Download-Meldung
# startet die Installation (Android verlangt diese Bestätigung immer, und für
# eine App außerhalb des Play Stores einmalig die Erlaubnis „Apps aus
# unbekannten Quellen installieren“ für den Browser).
#
# Ein Einbau-Installer direkt aus der App bräuchte ein Android-Plugin (Java);
# der Weg über den Browser kommt ohne zusätzliche Bibliothek aus.
# =============================================================================
class_name Updater
extends Node

## text = Meldung für den Nutzer, done = Suche beendet
signal status(text: String, done: bool)

const API := "https://api.github.com/repos/%s/releases/latest"
const TAG_PREFIX := "android-build-"

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_done)


## Suche starten (Ergebnis kommt über das Signal status).
func check() -> void:
	status.emit("Suche nach Updates …", false)
	# GitHub verlangt einen User-Agent; keine persönlichen Daten
	var err := _http.request(API % BuildInfo.REPO, ["User-Agent: AR-Airship-Regatta", "Accept: application/vnd.github+json"])
	if err != OK:
		status.emit(I18n.t("Update-Suche nicht möglich (Fehler %d).") % err, true)


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		status.emit("Keine Verbindung zu GitHub – Internet prüfen.", true)
		return
	if code != 200:
		status.emit(I18n.t("GitHub antwortet mit Fehler %d – später nochmal versuchen.") % code, true)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		status.emit("Antwort von GitHub nicht lesbar.", true)
		return
	var res := parse_release(data)
	if res.build <= 0:
		status.emit("Kein Android-Build gefunden.", true)
		return
	if res.build <= BuildInfo.BUILD:
		status.emit(I18n.t("Du hast die neueste Version (Build %d).") % BuildInfo.BUILD, true)
		return
	if OS.has_feature("web"):
		_web_switch(res.build)                   # Browser: neue Seite laden statt APK
		return
	if res.url == "":
		status.emit(I18n.t("Build %d ist da, aber ohne APK – später nochmal versuchen.") % res.build, true)
		return
	status.emit(I18n.t("Neuer Build %d gefunden. Der Download startet im Browser – danach die Download-Meldung antippen und „Installieren“ wählen. Deine Einstellungen bleiben erhalten.") % res.build, true)
	OS.shell_open(res.url)


# =============================================================================
# Browser-Version: Jeder Build liegt unter eigenem Namen (ar-<Build>.html, .pck,
# .wasm …), daher kann kein Zwischenspeicher alte Dateien liefern. Erst prüfen,
# ob die neue Seite schon veröffentlicht ist (die Veröffentlichung läuft nach
# dem Android-Release), dann dorthin wechseln.
# =============================================================================
var _web_target := 0

func _web_switch(build: int) -> void:
	_web_target = build
	var base := str(JavaScriptBridge.eval("location.origin + location.pathname.replace(/[^/]*$/, '')"))
	var probe := HTTPRequest.new()
	probe.timeout = 15.0
	add_child(probe)
	probe.request_completed.connect(func(result: int, code: int, _h, _b):
		probe.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			status.emit(I18n.t("Neuer Build %d gefunden – Seite wird neu geladen …") % build, true)
			JavaScriptBridge.eval("location.href = 'ar-%d.html'" % build)
		else:
			status.emit(I18n.t("Build %d wird gerade veröffentlicht – in 2–3 Minuten noch einmal suchen.") % build, true))
	probe.request(base + "ar-%d.html" % build)


## Release-Antwort auswerten: Build-Nummer aus dem Tag und Download-Adresse der APK.
## Statisch, damit der Test sie ohne Netz prüfen kann.
static func parse_release(data: Dictionary) -> Dictionary:
	var tag: String = str(data.get("tag_name", ""))
	var build := 0
	if tag.begins_with(TAG_PREFIX):
		build = tag.trim_prefix(TAG_PREFIX).to_int()
	var url := ""
	for a in data.get("assets", []):
		if a is Dictionary and str(a.get("name", "")).ends_with(".apk"):
			url = str(a.get("browser_download_url", ""))
			break
	return {"build": build, "url": url}
