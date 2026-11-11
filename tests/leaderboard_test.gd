# 2026-11-11 20:35 – Erstversion: Bestenliste quartalsweise (Umzug nach „Best Forever“, 10 Beste), Sortierung nach gewerteter Zeit, models.json passt zu den Standardmodellen
extends SceneTree

func _initialize() -> void:
	var ok := true
	# Sicherung der echten Datei
	var had := FileAccess.file_exists(Leaderboard.PATH)
	var keep := FileAccess.get_file_as_string(Leaderboard.PATH) if had else ""
	# Testdaten: 12 Einträge aus einem vergangenen Quartal + 2 aus dem laufenden
	var old := []
	for i in 12:
		old.append({"total": 20.0 + i, "score": 14.0 + i, "laps": [7, 7, 6.0 + i], "name": "Alt%d" % i,
			"model": "Chewie", "date": "2025-08-01", "platform": "PC · Sender", "quarter": "2025Q3"})
	var cur := Leaderboard.current_quarter()
	old.append({"total": 30.0, "score": 20.0, "laps": [10, 10, 10.0], "name": "Neu1", "model": "Chewie", "date": "x", "platform": "", "quarter": cur})
	old.append({"total": 18.0, "score": 13.0, "laps": [6, 6, 6.0], "name": "Neu2", "model": "Chewie", "date": "x", "platform": "", "quarter": cur})
	var f := FileAccess.open(Leaderboard.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"name": "", "lists": {"cup": old}, "forever": {}}))
	f.close()
	var e := Leaderboard.entries("cup")
	if e.size() != 2 or e[0].name != "Neu2":
		print("FEHLER laufendes Quartal: ", e.size()); ok = false
	var fv := Leaderboard.forever("cup")
	if fv.size() != 1 or fv[0].quarter != "2025Q3" or fv[0].entries.size() != 10 or fv[0].entries[0].name != "Alt0":
		print("FEHLER Best Forever: ", fv); ok = false
	# Eintragen sortiert nach gewerteter Zeit
	var place := Leaderboard.add("cup", 25.0, PackedFloat32Array([8, 8, 9]), "Mitte", "Chewie", 15.0, "Handy · Touch")
	if place != 2:
		print("FEHLER Platz ", place); ok = false
	# Datei wiederherstellen
	if had:
		var w := FileAccess.open(Leaderboard.PATH, FileAccess.WRITE); w.store_string(keep); w.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Leaderboard.PATH))
	# models.json (Server) muss die Fingerabdrücke der Standardmodelle enthalten
	var models = JSON.parse_string(FileAccess.get_file_as_string("res://server/rc-airship/models.json"))
	for entry in AirshipPresets.list():
		if entry.source == "Eigene": continue
		var s := AirshipPhysics.new()
		entry.build.call(s)
		var fp := ModelCodec.fingerprint(s)
		s.free()
		if not (models is Dictionary and models.has(fp)):
			print("FEHLER models.json veraltet für ", entry.name, " – tools/export_server_models.gd ausführen"); ok = false
	print("leaderboard_test: ", "OK" if ok else "FEHLER")
	if not ok: push_error("SCRIPT ERROR: leaderboard_test")
	print("ENDE")
	quit(0 if ok else 1)
