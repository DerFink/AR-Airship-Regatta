# 2026-11-11 19:30 – Prüft auch das Laden alter Einstellungen (Stickmode wurde überschrieben)
# 2026-11-11 15:45 – Erstversion: Stickmode 1–4 (heli-planet-Nomenklatur), Standard Mode 4
extends SceneTree

func _initialize() -> void:
	var ok := true
	var fc := FlightController.new()
	if fc.stick_mode != 4:
		print("FEHLER Standard ist nicht Mode 4"); ok = false
	# Erwartung je Mode: wo liegt Gas, Nick, Gier, Rolle (L/R, x/y)
	var expect := {
		1: {"thr": "Ry", "pitch": "Ly", "yaw": "Lx", "roll": "Rx"},
		2: {"thr": "Ly", "pitch": "Ry", "yaw": "Lx", "roll": "Rx"},
		3: {"thr": "Ry", "pitch": "Ly", "yaw": "Rx", "roll": "Lx"},
		4: {"thr": "Ly", "pitch": "Ry", "yaw": "Rx", "roll": "Lx"},
	}
	for m in expect:
		fc.stick_mode = m
		var vals := {"thr": 0.1, "pitch": 0.2, "yaw": 0.3, "roll": 0.4}
		var s := fc.sticks_for(vals.thr, vals.pitch, vals.yaw, vals.roll)
		for fn in vals:
			var where: String = expect[m][fn]
			var st: Vector2 = s[0] if where[0] == "L" else s[1]
			var v := st.x if where[1] == "x" else st.y
			if absf(v - vals[fn]) > 1e-6:
				print("FEHLER Mode %d: %s nicht auf %s" % [m, fn, where]); ok = false
		fc.yaw_expo = 0.0
		fc.set_sticks(s[0], s[1])
		if absf(fc.cmd_throttle - 0.1) > 1e-6 or absf(fc.cmd_pitch + 0.2) > 1e-6 or absf(fc.cmd_yaw - 0.3) > 1e-6:
			print("FEHLER Mode %d: Kommandos falsch" % m); ok = false
	fc.free()
	# Gespeicherte alte Einstellung (Mode 1, Nomenklatur 3) wird beim Laden zu Mode 4 –
	# und darf danach nicht wieder überschrieben werden (Fehler bis 0.26.0)
	var cfg := ConfigFile.new()
	var had := cfg.load(FlightController.SETTINGS_PATH) == OK
	var keep := cfg.encode_to_text()
	cfg.set_value("general", "stick_mode", 1)
	cfg.set_value("general", "stick_nomenklatur", 3)
	cfg.set_value("general", "version", FlightController.SETTINGS_VERSION)
	cfg.save(FlightController.SETTINGS_PATH)
	var fc2 := FlightController.new()
	fc2.load_settings()
	if fc2.stick_mode != 4:
		print("FEHLER alter Stickmode 1 wurde nicht zu Mode 4 (", fc2.stick_mode, ")"); ok = false
	fc2.free()
	if had:
		var back := ConfigFile.new(); back.parse(keep); back.save(FlightController.SETTINGS_PATH)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FlightController.SETTINGS_PATH))
	print("stickmode_test: ", "OK" if ok else "FEHLER")
	if not ok: push_error("SCRIPT ERROR: stickmode_test")
	print("ENDE")
	quit(0 if ok else 1)
