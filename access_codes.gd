# 2026-11-17 18:30 – Erstversion: Zugangscodes – Code auf dem Gerät, Rolle (Gruppe/Admin), private Modelle auf dem Gerät, beim Start auffrischen
# =============================================================================
# AccessCodes.gd
# -----------------------------------------------------------------------------
# Der Admin legt in admin.php Zugangscodes an (je Code: Gruppe/Notiz, Rolle,
# private Modelle). In der App: Einstellungen → Zugang → Code eingeben.
#   - Der Server (api.php?action=unlock) liefert Rolle und Modelle.
#   - Code, Rolle und Modelle bleiben auf dem Gerät (user://zugang.cfg,
#     Modelle in user://private_modelle.txt) – fliegen geht auch ohne Netz.
#   - Bei jedem Start mit Internet wird neu geladen; ist der Code gesperrt
#     oder gelöscht, verschwinden Code und private Modelle vom Gerät.
#   - Ohne Code weiß die App nichts von privaten Modellen.
# Rolle "admin": alle privaten Modelle und die Admin-Bereiche der App
# (z. B. „Teensy-Sketch erzeugen“). Rolle "gruppe": die Modelle der Gruppe.
# Private Modelle zählen nie für die Bestenliste (siehe AirshipPresets).
# Gespeichert werden keine Namen und keine E-Mail-Adressen.
# =============================================================================
class_name AccessCodes
extends RefCounted

const FILE := "user://zugang.cfg"
## Private Modelle als Textdatei im gleichen Format wie die Sammlung
## (Angabenzeile „# Autor: … | Team: … | Beschreibung: …“ + Modell-String)
const MODELS_FILE := "user://private_modelle.txt"

static var code := ""            ## eingegebener Code (XXXX-XXXX-XXXX), leer = keiner
static var role := ""            ## "gruppe" oder "admin"
static var group := ""           ## Gruppe/Notiz des Codes (Anzeige)
static var model_count := 0
static var updated := ""         ## wann zuletzt vom Server geladen (Anzeige)
static var _loaded := false


## Gespeicherten Zugang lesen (einmal beim ersten Zugriff).
static func load_saved() -> void:
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(FILE) != OK:
		return
	code = str(cfg.get_value("zugang", "code", ""))
	role = str(cfg.get_value("zugang", "rolle", ""))
	group = str(cfg.get_value("zugang", "gruppe", ""))
	model_count = int(cfg.get_value("zugang", "modelle", 0))
	updated = str(cfg.get_value("zugang", "geladen", ""))


static func _ensure() -> void:
	if not _loaded:
		load_saved()


static func has_code() -> bool:
	_ensure()
	return code != ""


static func is_admin() -> bool:
	_ensure()
	return code != "" and role == "admin"


## Eingabe vereinheitlichen wie der Server: Großbuchstaben, Bindestriche neu.
static func normalize(s: String) -> String:
	var c := ""
	for ch in s.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			c += ch
	if c.length() != 12:
		return ""
	return "%s-%s-%s" % [c.substr(0, 4), c.substr(4, 4), c.substr(8, 4)]


## Antwort des Servers übernehmen und auf dem Gerät speichern.
static func store(c: String, res: Dictionary) -> void:
	code = c
	role = str(res.get("role", "gruppe"))
	group = str(res.get("group", ""))
	var lines: PackedStringArray = ["# Private Modelle (Zugangscode) – wird beim Start der App neu geladen"]
	var n := 0
	for m in res.get("models", []):
		if not (m is Dictionary): continue
		var meta := str(m.get("meta", ""))
		var grp := str(m.get("group", ""))
		# Gruppe als „Team“ zeigen, wenn die Angabenzeile keins nennt
		if meta == "" and grp != "":
			meta = "# Team: " + grp
		elif meta != "" and grp != "" and not ("Team:" in meta or "team:" in meta):
			meta += " | Team: " + grp
		if meta != "": lines.append(meta.replace("\n", " "))
		lines.append(str(m.get("model", "")).strip_edges())
		n += 1
	model_count = n
	updated = Time.get_datetime_string_from_system(false, true).left(16)
	var f := FileAccess.open(MODELS_FILE, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	_save_cfg()


## Code und private Modelle vom Gerät entfernen.
static func clear() -> void:
	code = ""
	role = ""
	group = ""
	model_count = 0
	updated = ""
	if FileAccess.file_exists(MODELS_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MODELS_FILE))
	if FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))


static func _save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("zugang", "code", code)
	cfg.set_value("zugang", "rolle", role)
	cfg.set_value("zugang", "gruppe", group)
	cfg.set_value("zugang", "modelle", model_count)
	cfg.set_value("zugang", "geladen", updated)
	cfg.save(FILE)


## Code beim Server prüfen und Modelle holen. cb(ok: bool, msg: String)
## msg: Text für die Anzeige (übersetzt). Bei „falscher Code“ wird ein
## vorhandener Zugang entfernt (gesperrt/gelöscht), bei Netzfehlern nicht.
static func unlock(online: LeaderboardOnline, raw: String, cb: Callable) -> void:
	var c := normalize(raw)
	if c == "":
		cb.call(false, I18n.t("Der Code hat 12 Zeichen, z. B. ABCD-EFGH-JKLM."))
		return
	online.unlock(c, func(res: Dictionary):
		if res.get("ok", false):
			store(c, res)
			cb.call(true, "")
		elif str(res.get("error", "")) == "code":
			if c == code: clear()                      # gesperrt oder gelöscht → weg vom Gerät
			cb.call(false, I18n.t("Code unbekannt oder gesperrt."))
		elif str(res.get("error", "")) == "locked":
			cb.call(false, I18n.t("Zu viele Fehlversuche – bitte in 15 Minuten erneut versuchen."))
		else:
			cb.call(false, I18n.t("Keine Verbindung – bitte später nochmal versuchen.")))


## Beim Start: vorhandenen Zugang still auffrischen (ohne Netz bleibt alles, wie es ist).
static func refresh(online: LeaderboardOnline, done: Callable = Callable()) -> void:
	if not has_code() or DisplayServer.get_name() == "headless":
		return
	unlock(online, code, func(_ok: bool, _msg: String):
		if done.is_valid(): done.call())
