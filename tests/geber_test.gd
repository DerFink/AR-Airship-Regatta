# 2026-11-16 19:25 – Flugmodi je Luftschiff: Modell-String, Fingerabdruck, adopt_ship_modes
# 2026-11-16 18:25 – Erstversion: Mischer mit Grundstellung, Gebern S1–S4 und Desaturierung; Modell-String behält die Erweiterung
extends SceneTree

var ok := true


func _check(name: String, got: float, want: float) -> void:
	if absf(got - want) > 0.001:
		print("FEHLER %s: %.3f statt %.3f" % [name, got, want])
		ok = false
	else:
		print("ok   %s = %.3f" % [name, got])


func _initialize() -> void:
	var s := AirshipPhysics.new()
	AirshipPresets.chewie(s)
	root.add_child(s)
	var fc := FlightController.new()
	fc.airship = s
	s.add_child(fc)
	fc.mode_index = 0
	# --- Desaturierung: Grundstellung 50 %, Nick 100 % ---
	_check("Grundstellung ohne Knüppel", FlightController.desaturate(0.5, 0.0), 0.5)
	_check("Grundstellung + voller Knüppel (anteilig gekürzt)", FlightController.desaturate(0.5, 1.0), 1.0)
	_check("Grundstellung − voller Knüppel", FlightController.desaturate(0.5, -1.0), -0.5)
	_check("Grundstellung − doppelter Knüppel", FlightController.desaturate(0.5, -2.0), -1.0)
	# --- Schub je Motor: Gas + Gier überschreiten 100 % ---
	s.mix_table["t0"] = [100.0, 0.0, 100.0, 0.0]
	fc.cmd_throttle = 1.0; fc.cmd_yaw = 1.0; fc.cmd_pitch = 0.0; fc.cmd_aux = 0.0
	_check("Schub Gas+Gier begrenzt", fc.motor_throttle(0), 1.0)
	# gemeinsame Desaturierung: Gas 80 % + Gier 50 % → links 1,3 / rechts 0,3 → beide × 1/1,3
	s.mix_table["t0"] = [100.0, 0.0, 100.0, 0.0]
	s.mix_table["t1"] = [100.0, 0.0, -100.0, 0.0]
	fc.cmd_throttle = 0.8; fc.cmd_yaw = 0.5
	fc._thr_frame = -2
	_check("Gruppe: Motor links", fc.motor_throttle(0), 1.0)
	_check("Gruppe: Motor rechts (Verhältnis bleibt)", fc.motor_throttle(1), 0.3 / 1.3)
	fc._thr_frame = -2
	# --- Geber S1 als Grundschub (Drehknopf) ---
	s.mix_table["t0"] = [0.0, 0.0, 0.0, 0.0]
	s.mix_table["t1"] = [0.0, 0.0, 0.0, 0.0]
	s.mix_table["et1"] = [0.0, 100.0, 0.0, 0.0, 0.0]
	fc.cmd_geber[0] = 0.5
	fc._thr_frame = -2
	_check("Schub aus Geber S1", fc.motor_throttle(1), 0.5)
	if not fc.geber_used(0):
		print("FEHLER geber_used(0) sollte true sein"); ok = false
	if fc.geber_used(1):
		print("FEHLER geber_used(1) sollte false sein"); ok = false
	# --- Modell-String behält Grundstellung/Geber ---
	s.mix_table["em0"] = [40.0, 0.0, 25.0, 0.0, 0.0]
	var r := ModelCodec.decode(ModelCodec.encode(s))
	var t: Dictionary = r.data.mix.t
	if not (t.get("em0") is Array) or absf(float(t.em0[0]) - 40.0) > 0.01 or absf(float(t.et1[1]) - 100.0) > 0.01:
		print("FEHLER Modell-String verliert e-Einträge: ", t.get("em0"), " ", t.get("et1")); ok = false
	else:
		print("ok   Modell-String mit Grundstellung/Gebern")
	# --- Flugmodi je Luftschiff: im Modell-String, aber nicht im Fingerabdruck ---
	var fp0 := ModelCodec.fingerprint(s)
	s.flight_modes = [{"name": "Dash", "art": "direkt", "roll_comp": false},
		{"name": "Hover", "art": "direkt", "roll_comp": false, "mix": {"t0": [50.0, 0.0, 0.0, 0.0], "em0": [-100.0, 0.0, 0.0, 0.0, 0.0]}}]
	var r2 := ModelCodec.decode(ModelCodec.encode(s))
	var s2 := AirshipPhysics.new()
	ModelCodec.apply(s2, r2.name, r2.data)
	if s2.flight_modes.size() != 2 or str(s2.flight_modes[1].name) != "Hover" or not (s2.flight_modes[1].get("mix") is Dictionary) \
			or absf(float(s2.flight_modes[1].mix.em0[0]) + 100.0) > 0.01:
		print("FEHLER Flugmodi gehen im Modell-String verloren: ", s2.flight_modes); ok = false
	else:
		print("ok   Flugmodi im Modell-String")
	if ModelCodec.fingerprint(s) != fp0:
		print("FEHLER Flugmodi verändern den Fingerabdruck"); ok = false
	else:
		print("ok   Fingerabdruck ohne Flugmodi")
	fc.adopt_ship_modes(s2)
	if fc.modes != s2.flight_modes or fc.modes.size() != 2:
		print("FEHLER adopt_ship_modes"); ok = false
	else:
		print("ok   Regler arbeitet auf den Modi des Luftschiffs")
	s2.free()
	print("geber_test: " + ("OK" if ok else "FEHLER"))
	print("ENDE")
	quit(0 if ok else 1)
