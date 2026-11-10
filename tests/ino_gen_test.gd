# 2026-11-11 13:40 – Erstversion: parametrischer .ino-Export – Chewie, Albacore (×-Leitwerk) und Kanalzuordnung; schreibt die Sketche zum Vergleich nach user://ino_test/
extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("user://ino_test")
	for b in [AirshipPresets.chewie, AirshipPresets.albacore_default]:
		var s := AirshipPhysics.new()
		b.call(s)
		var fc := FlightController.new()
		fc.airship = s
		s.add_child(fc)
		root.add_child(s)
		s.rebuild_mass_properties()
		fc.reset_to_defaults(s.fc_gains)
		var r: Dictionary = InoExport.build(fc, s.model_name, {"mixer": true})
		var f := FileAccess.open("user://ino_test/%s.ino" % s.model_name.replace(" ", "_"), FileAccess.WRITE)
		f.store_string(r.text); f.close()
		print(s.model_name, ": ", r.text.length(), " Zeichen, Hinweise: ", " | ".join(r.notes))
		print("  Prüfung: ", InoExport.check(s, fc))
	# Kanalzuordnung (Simulator-Belegung)
	var s2 := AirshipPhysics.new()
	AirshipPresets.chewie(s2)
	var fc2 := FlightController.new()
	fc2.airship = s2
	s2.add_child(fc2)
	root.add_child(s2)
	var r2: Dictionary = InoExport.build(fc2, "Chewie", {"channels": {"yaw": [1, false], "pitch": [2, true], "thr": [3, false], "roll": [4, false], "arm": [5, false], "mode": [6, false], "zero": [12, false]}})
	var f2 := FileAccess.open("user://ino_test/Chewie_kanaele.ino", FileAccess.WRITE)
	f2.store_string(r2.text); f2.close()
	print("Kanäle: ", " | ".join(r2.notes))
	print(ProjectSettings.globalize_path("user://ino_test"))
	print("ENDE")
	quit()
