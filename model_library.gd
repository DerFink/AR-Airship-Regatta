# 2026-11-11 15:00 – Angaben zum Modell: Kommentarzeile „# Autor: … | Team: … | Beschreibung: …“ direkt über dem Modell-String wird gelesen (meta) und in „Modell & Bau“ angezeigt
# 2026-10-27 11:08 – Erstversion: Modellsammlung aus Textdateien – Admin-Sammlung (res://models/sammlung.txt) und eigene Modelle (user://meine_modelle.txt); Speichern eigener Modelle
# =============================================================================
# ModelLibrary.gd
# -----------------------------------------------------------------------------
# So kommen eingesandte Modelle in die Auswahlliste:
#   1. Ein Nutzer baut sein Luftschiff und schickt dir den Modell-String
#      (Baukasten → Teilen → Kopieren), dazu ggf. sein Logo als PNG.
#   2. Du als Admin fügst den String als neue Zeile in
#      res://models/sammlung.txt ein (Zeilen mit # sind Kommentare) und legst
#      das Logo unter seinem Dateinamen nach res://models/logos/.
#   3. Optional direkt darüber eine Zeile mit Angaben (erscheint in der Detailansicht):
#        # Autor: Max Muster | Team: LTA Club | Beschreibung: Leichtes Hallenschiff …
#   4. Beim nächsten Build steht das Modell in jeder App in der Auswahl.
# Eigene Modelle speichert die App zusätzlich lokal in user://meine_modelle.txt.
# =============================================================================
class_name ModelLibrary
extends RefCounted

const ADMIN_FILE := "res://models/sammlung.txt"
const USER_FILE := "user://meine_modelle.txt"


## Alle gültigen Einträge: [{name, code, source}] – erst Sammlung, dann eigene.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pair in [[ADMIN_FILE, "Sammlung"], [USER_FILE, "Eigene"]]:
		if not FileAccess.file_exists(pair[0]):
			continue
		var meta := {}
		for line in FileAccess.get_file_as_string(pair[0]).split("\n"):
			var t := line.strip_edges()
			if t == "":
				continue
			if t.begins_with("#"):
				var m := parse_meta(t)
				if not m.is_empty(): meta = m        # gilt für den nächsten Modell-String
				continue
			var r := ModelCodec.decode(t)
			if r.ok:
				out.append({"name": r.name, "code": t, "source": pair[1],
					"meta": meta if not meta.is_empty() else {"author": "", "team": "", "desc": ""}})
			meta = {}
	return out


## Angabenzeile lesen: „# Autor: … | Team: … | Beschreibung: …“ (Reihenfolge
## beliebig, Teile dürfen fehlen; auch „Author/Description“). Sonst leer.
static func parse_meta(line: String) -> Dictionary:
	var body := line.trim_prefix("#").strip_edges()
	if body.begins_with("#"):
		return {}                                    # „# # Autor: …“ = Beispiel in der Erklärung, kein Eintrag
	var out := {"author": "", "team": "", "desc": ""}
	var found := false
	for part in body.split("|"):
		var kv := part.split(":", true, 1)
		if kv.size() != 2: continue
		var k := kv[0].strip_edges().to_lower()
		var v := kv[1].strip_edges().left(300)
		if k in ["autor", "author"]: out.author = v; found = true
		elif k == "team": out.team = v; found = true
		elif k in ["beschreibung", "description", "desc"]: out.desc = v; found = true
	return out if found else {}


## Eigenes Modell lokal speichern (gleicher Name ersetzt den alten Eintrag).
static func save_own(code: String) -> bool:
	var r := ModelCodec.decode(code)
	if not r.ok:
		return false
	var lines: PackedStringArray = []
	if FileAccess.file_exists(USER_FILE):
		for line in FileAccess.get_file_as_string(USER_FILE).split("\n"):
			var t := line.strip_edges()
			if t == "":
				continue
			var old := ModelCodec.decode(t)
			if old.ok and old.name == r.name:
				continue
			lines.append(t)
	lines.append(code)
	var f := FileAccess.open(USER_FILE, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string("\n".join(lines) + "\n")
	return true
