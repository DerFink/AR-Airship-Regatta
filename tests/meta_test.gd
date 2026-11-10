# 2026-11-11 15:05 – Erstversion: Angabenzeile über einem Modell-String (Sammlung/Eigene) wird gelesen und in meta() geliefert
extends SceneTree
func _initialize() -> void:
	print(ModelLibrary.parse_meta("# Autor: Max Muster | Team: LTA Club | Beschreibung: Leichtes Hallenschiff"))
	print(ModelLibrary.parse_meta("#   # Autor: Beispiel | Team: X"))
	print(ModelLibrary.parse_meta("# eingesandt am 10.11."))
	# eigene Datei mit Angabenzeile + String
	var s := AirshipPhysics.new()
	AirshipPresets.chewie(s)
	s.model_name = "Testschiff"
	var code := ModelCodec.encode(s)
	var backup := FileAccess.get_file_as_string(ModelLibrary.USER_FILE) if FileAccess.file_exists(ModelLibrary.USER_FILE) else ""
	var f := FileAccess.open(ModelLibrary.USER_FILE, FileAccess.WRITE)
	f.store_string(backup + "\n# Autor: Max Muster | Team: LTA Club | Beschreibung: Test mit Angaben\n" + code + "\n")
	f.close()
	print("meta(Testschiff (Eigene)): ", AirshipPresets.meta("Testschiff (Eigene)"))
	print("meta(Testschiff): ", AirshipPresets.meta("Testschiff"))
	var f2 := FileAccess.open(ModelLibrary.USER_FILE, FileAccess.WRITE)
	f2.store_string(backup)
	f2.close()
	s.free()
	print("ENDE")
	quit()
