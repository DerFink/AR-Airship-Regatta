# 2026-11-13 02:30 – Erstversion: Flugmodi des Piloten (Anzahl, Speichern/Laden, PID-Modus, Signalfluss-Abfrage), Rollausgleich-Drehung, Flossen einzeln (feste Finne) und Modell-String
extends SceneTree
var ok := true

func _fail(msg: String) -> void:
	print("FEHLER ", msg)
	ok = false

func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FlightController.SETTINGS_PATH))
	var ship := AirshipPhysics.new()
	AirshipPresets.chewie(ship)
	root.add_child(ship)
	var fc := FlightController.new()
	fc.airship = ship
	ship.add_child(fc)
	# --- Werkseinstellung: 2 Modi (Direkt, Angle) ---
	if fc.modes.size() != 2 or fc.modes[0].art != "direkt" or fc.modes[1].art != "angle":
		_fail("Werkseinstellung nicht Direkt + Angle: %s" % str(fc.modes))
	# --- Anzahl ändern, PID-Modus, Speichern/Laden ---
	fc.set_mode_count(5)
	if fc.modes.size() != 5: _fail("set_mode_count(5)")
	fc.modes[4]["name"] = "Rennen"
	fc.modes[4]["roll_comp"] = true
	fc.mode_index = 4
	if fc.mode != FlightController.Mode.CUSTOM: _fail("Modus 5 ist nicht PID")
	fc.save_settings()
	var fc2 := FlightController.new()
	fc2.airship = ship
	fc2.load_settings()
	if fc2.modes.size() != 5 or fc2.modes[4].name != "Rennen" or fc2.mode_index != 4:
		_fail("Modi nicht gespeichert/geladen: %d %s" % [fc2.modes.size(), str(fc2.mode_index)])
	fc2.free()
	# --- PID-Modus rechnet, Signalfluss liefert alle Ausgänge ---
	fc.armed = true
	fc.set_stick_functions(0.3, 0.0, 0.5, 0.0)
	fc._physics_process(1.0 / 60.0)
	var pr := fc.probe_outputs(4, "yaw", 1.0)
	if pr.size() != FlightController.mix_outputs(ship).size(): _fail("probe_outputs unvollständig")
	var any := false
	for k in pr: any = any or absf(pr[k]) > 0.01
	if not any: _fail("Seiten-Impuls bewegt kein Ruder")
	if fc.mode_index != 4: _fail("probe_outputs hat den Modus verstellt")
	# --- Rollausgleich: bei 90° wird Seite zu Höhe ---
	var r0 := fc.roll_rotate(0.0, 1.0, 0.0)
	var r90 := fc.roll_rotate(0.0, 1.0, 90.0)
	if not r0.is_equal_approx(Vector2(0, 1)): _fail("Rollausgleich bei 0° verändert den Befehl")
	if absf(r90.y) > 0.01 or absf(r90.x) < 0.99: _fail("Rollausgleich bei 90°: %s" % str(r90))
	# --- Flossen einzeln: λ mit fester Finne oben ---
	ship.tail.individual = true
	ship.tail.fin_cfg = []
	ship.tail.ensure_fin_cfg()
	ship.tail.fin_cfg[0]["kind"] = 0                 # oben fest
	ship.tail.fin_cfg[0]["area"] = 0.012
	ship.rebuild_mass_properties()
	var fins := ship.tail.generate()
	if not fins[0].fixed or fins[0].max_deflection_deg != 0.0: _fail("Finne oben nicht fest")
	if absf(fins[0].area_m2 - 0.012) > 1e-6: _fail("Fläche der Finne nicht übernommen")
	var code := ModelCodec.encode(ship)
	var d := ModelCodec.decode(ModelCodec.readable_header(ship, 0.72) + "\n" + code)
	if not d.ok: _fail("Code mit Eckdaten lässt sich nicht einlesen: " + d.error)
	else:
		var s2 := AirshipPhysics.new()
		ModelCodec.apply(s2, d.name, d.data)
		if not s2.tail.individual or int(s2.tail.fin_cfg[0].kind) != 0: _fail("Flossen einzeln nicht im Modell-String")
		s2.free()
	print("modes_test: ", "OK" if ok else "FEHLER")
	print("ENDE")
	quit()
