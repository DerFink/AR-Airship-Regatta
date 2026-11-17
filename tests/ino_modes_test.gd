# 2026-11-17 21:20 – Erstversion: Teensy-Export mit Modus-Tabelle – Testmodell mit 5 Flugmodi (Direkt mit eigener Tabelle, PID mit Rollausgleich, Angle, Horizon, PID ohne eigene Tabelle), Motoren aus/Gas-Anteil/Grundstellung, Drehgeber. Schreibt Sketch und Vergleichsfälle (Simulator-Ergebnisse) nach res://build/ino_test/ für tests/ino_compare.py
extends SceneTree

var ok := true


func _fail(msg: String) -> void:
	print("FEHLER ", msg)
	ok = false


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/ino_test")
	var s := AirshipPhysics.new()
	AirshipPresets.chewie(s)
	var fc := FlightController.new()
	fc.airship = s
	s.add_child(fc)
	root.add_child(s)
	s.rebuild_mass_properties()
	fc.reset_to_defaults(s.fc_gains)
	# --- Testmodell: 5 Flugmodi ---
	var outs := FlightController.mix_outputs(s)
	var ta := {}                                   # Modus 1 „Dash“: eigene Tabelle mit Grundstellung und Drehgeber
	var w := [[60.0, -20.0, 10.0], [-40.0, 30.0, 0.0], [25.0, 70.0, -15.0], [-80.0, 10.0, 40.0], [0.0, -55.0, 20.0]]
	for i in outs.size():
		ta[outs[i].key] = w[i % w.size()]
		ta["e" + outs[i].key] = [10.0 * (i % 3) - 10.0, 30.0 if i == 0 else 0.0, 0.0, -20.0 if i == 2 else 0.0, 0.0]
	ta["t0"] = [80.0, 0.0, 0.0, 0.0]
	ta["t1"] = [100.0, 0.0, 40.0, 0.0]               # mit Gier-Anteil (Differenzschub) – darf NICHT in den Sketch
	ta["et1"] = [20.0, 50.0, 0.0, 0.0, 0.0]          # Grundstellung 20 % + S1
	var tb := ta.duplicate(true)                     # Modus 2 „Cruise“: PID mit Rollausgleich, Motor 0 aus
	tb["x0"] = true
	for i in outs.size():
		tb[outs[i].key] = w[(i + 2) % w.size()]
	var axes := {"pitch": {"on": true, "kind": "angle", "Kp": 0.8, "Ki": 0.3, "Kd": 0.2, "max": 25.0},
		"roll": {"on": true, "kind": "rate", "Kp": 0.5, "Ki": 0.1, "Kd": 0.05, "max": 60.0},
		"yaw": {"on": false, "kind": "rate", "Kp": 1.0, "Ki": 0.4, "Kd": 0.0, "max": 150.0}}
	s.flight_modes = [
		{"name": "Dash", "art": "direkt", "roll_comp": false, "mix": ta},
		{"name": "Cruise", "art": "pid", "roll_comp": true, "axes": axes, "mix": tb},
		{"name": "Hover", "art": "angle", "roll_comp": true},
		{"name": "Spin", "art": "horizon", "roll_comp": false},
		{"name": "Mix", "art": "pid", "roll_comp": false, "axes": FlightController.default_axes()},
	]
	fc.adopt_ship_modes(s)
	if not InoExport.needs_mode_table(fc): _fail("Modus-Tabelle nicht erkannt")
	var ch := {"thr": [1, false], "pitch": [5, false], "yaw": [6, false], "roll": [7, false], "arm": [14, false], "mode": [13, false],
		"s1": [3, false], "s2": [4, true], "s3": [0, false], "s4": [0, false]}
	var r: Dictionary = InoExport.build(fc, "Testmodell", {"mixer": true, "channels": ch})
	var f := FileAccess.open("res://build/ino_test/Testmodell_5_Modi.ino", FileAccess.WRITE)
	f.store_string(r.text); f.close()
	print("Hinweise: ", " | ".join(r.notes))
	var txt: String = r.text
	for must in ["const int   MODE_COUNT = 5;", "MODE_ART[MODE_COUNT]       = {1, 4, 2, 3, 4}", "void controlPIDMode()", "mixMotorsTable();", "\"Cruise\""]:
		if txt.find(must) < 0: _fail("im Sketch fehlt: " + must)
	if not " ".join(r.notes).contains("Differenzschub"): _fail("Hinweis auf nicht übernommenen Differenzschub fehlt")
	# --- Vergleichsfälle: was rechnet der Simulator? ---
	var acts := fc.actuator_table().slice(0, 7)
	var cases := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1711
	for c in 60:
		var slot := c % 5
		fc.mode_index = slot
		var m: Dictionary = fc.modes[slot]
		var gb := [rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0.0, 0.0]
		fc.cmd_geber = gb
		var cs := {"slot": slot, "geber": gb}
		var art := str(m.art)
		if art == "direkt":
			var p := rng.randf_range(-1, 1); var y := rng.randf_range(-1, 1); var ra := rng.randf_range(-1, 1)
			var roll := rng.randf_range(-40, 40)
			fc.cmd_pitch = p; fc.cmd_yaw = y; fc.cmd_aux = ra
			fc._mix_direct(p * fc.pitch_max_deg, y * FlightController.MAX_YAW, roll)
			cs.merge({"kind": "direct", "p": p, "y": y, "r": ra, "roll": roll})
		elif art == "pid":
			var p := rng.randf_range(-1, 1); var y := rng.randf_range(-1, 1); var ra := rng.randf_range(-1, 1)
			var pi_ := rng.randf_range(-30, 30); var ri := rng.randf_range(-30, 30)
			var gp := rng.randf_range(-50, 50); var gr := rng.randf_range(-50, 50); var gy := rng.randf_range(-80, 80)
			fc.cmd_pitch = p; fc.cmd_yaw = y; fc.cmd_aux = ra
			fc.armed = true
			fc._cint = {"pitch": 0.0, "roll": 0.0, "yaw": 0.0}
			fc._cprev = {"pitch": 0.0, "roll": 0.0, "yaw": 0.0}
			fc._run_custom(m, 0.01, pi_, ri, gp, gr, gy)
			cs.merge({"kind": "pid", "p": p, "y": y, "r": ra, "pitch_imu": pi_, "roll": ri, "gp": gp, "gr": gr, "gy": gy, "dt": 0.01})
		else:
			continue                                   # Angle/Horizon: Regler der Vorlage (unverändert)
		var exp := []
		for a in acts:
			var idx := int(str(a.key).substr(1))
			exp.append(s.surfaces[idx].command if a.kind == "fin" else s.motors[idx].swivel_cmd)
		cs["servo"] = exp
		# Motoren (nur Gas; Knüppel Nick/Gier/Roll auf 0, damit der Differenzschub nicht hineinspielt)
		var thr := rng.randf_range(-1, 1)
		fc.cmd_throttle = thr
		var cp := fc.cmd_pitch; var cy := fc.cmd_yaw; var ca := fc.cmd_aux
		fc.cmd_pitch = 0.0; fc.cmd_yaw = 0.0; fc.cmd_aux = 0.0
		var me := []
		for j in s.motors.size():
			fc._thr_frame = -1
			me.append(fc.motor_throttle(j))
		fc.cmd_pitch = cp; fc.cmd_yaw = cy; fc.cmd_aux = ca
		cs["thr"] = thr
		cs["motors"] = me
		cases.append(cs)
	# Gegenprobe Richtung: Simulator-Mischer nach Einbaulage (Modus ohne Tabelle) bei kleinen Knüppelwerten
	var geo := []
	fc.mode_index = 3                                # „Spin“: keine eigene Tabelle, kein Rollausgleich
	fc.cmd_geber = [0.0, 0.0, 0.0, 0.0]
	for c in 20:
		var p := rng.randf_range(-0.3, 0.3); var y := rng.randf_range(-0.3, 0.3); var rr := rng.randf_range(-0.3, 0.3)
		var stick_r := signf(rr) * (FlightController.MODE1_ROLL_DEADBAND + absf(rr) * (1.0 - FlightController.MODE1_ROLL_DEADBAND))
		fc.cmd_aux = stick_r
		fc._mix_direct(p * fc.pitch_max_deg, y * FlightController.MAX_YAW, 0.0)
		var sim := []
		var clamp := false
		for a in acts:
			var idx := int(str(a.key).substr(1))
			var v: float = s.surfaces[idx].command if a.kind == "fin" else s.motors[idx].swivel_cmd
			if absf(v) > 0.99: clamp = true
			sim.append(v)
		if not clamp:
			geo.append({"p": p, "y": y, "stick_r": stick_r, "sim": sim})
	# Schalterstellungen Kanal 13 → Modus (oben = 1)
	var sw := []
	for pwm in [2000, 1850, 1790, 1610, 1500, 1390, 1210, 1000]:
		sw.append({"pwm": pwm, "slot": clampi(int(floor((2000.0 - pwm) / 1000.0 * 5)), 0, 4)})
	var out := {"geo": geo, "servo_max": acts.map(func(a): return float(a.max)), "kinds": acts.map(func(a): return str(a.kind)),
		"motors": s.motors.size(), "cases": cases, "switch": sw}
	var jf := FileAccess.open("res://build/ino_test/Testmodell_5_Modi.json", FileAccess.WRITE)
	jf.store_string(JSON.stringify(out)); jf.close()
	print("Fälle: ", cases.size())
	print(ProjectSettings.globalize_path("res://build/ino_test"))
	print("ino_modes_test: " + ("OK" if ok else "FEHLER"))
	print("ENDE")
	if not ok: assert(false, "Teensy-Export mit Modus-Tabelle fehlerhaft")
	quit(0 if ok else 1)
