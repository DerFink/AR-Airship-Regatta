# 2026-11-11 15:55 – Prüft auch die Übersetzungsdateien in res://i18n/
# 2026-11-11 00:25 – Erstversion: prüft, ob alle Zeichen der Oberflächentexte in der eingebauten Schrift (bzw. der CJK-Ersatzschrift) vorhanden sind – sonst erscheinen auf dem Handy Kästchen
# Aufruf: godot --headless --path . -s tools/check_glyphs.gd
extends SceneTree

func _initialize() -> void:
	var base := ThemeDB.fallback_font
	var cjk: Font = load("res://fonts/cjk_tc_subset.otf")
	var missing := {}
	for dir in ["res://", "res://ui/", "res://i18n/"]:
		for f in DirAccess.get_files_at(dir):
			if not (f.ends_with(".gd") or f.ends_with(".txt")): continue
			var txt := FileAccess.get_file_as_string(dir + f)
			for line in txt.split("\n"):
				if line.strip_edges().begins_with("#"): continue
				for i in line.length():
					var c := line.unicode_at(i)
					if c < 128: continue
					if base.has_char(c) or (cjk and cjk.has_char(c)): continue
					missing[String.chr(c)] = missing.get(String.chr(c), "") + (f + " ") if not (f in missing.get(String.chr(c), "")) else missing.get(String.chr(c), "")
	for k in missing:
		print("FEHLT U+%04X  %s  in %s" % [k.unicode_at(0), k, missing[k]])
	print("Fertig: %d fehlende Zeichen" % missing.size())
	quit()
