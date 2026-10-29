# 2026-10-29 07:45 – Modus Gedämpft im Testprogramm
# 2026-10-29 01:53 – Erstversion: Testprogramm des Nutzers (50 % Schub, je 0,5 s gerade/links/gerade/rechts) für Chewie und Albacore in Geregelt und Luftschiff, Start 1,5 m über dem Boden
extends SceneTree
# Prüft, ob das Luftschiff mit den Modell-Reglerwerten enge Kurven fliegt,
# ohne auf den Boden zu kommen. Ausgabe je Modell und Modus: größte
# Höhenabweichung, tiefster Punkt der Hülle, Nick/Roll maximal, Kursänderung.
var ships: Array = []
var f := 0
func _initialize() -> void:
	var i := 0
	for preset in ["chewie", "albacore"]:
		for md in [FlightController.Mode.STABILIZED, FlightController.Mode.AIRSHIP, FlightController.Mode.DAMPED]:
			var s := AirshipPhysics.new()
			if preset == "chewie": AirshipPresets.chewie(s)
			else: AirshipPresets.albacore_default(s)
			s.position = Vector3(i * 200.0, 1.5, 0)
			s.rotation.y = -PI * 0.5
			var fc := FlightController.new(); fc.airship = s; s.add_child(fc); root.add_child(s)
			ships.append({"name": preset, "md": md, "s": s, "fc": fc, "dy": 0.0, "low": 99.0, "pmax": 0.0, "rmax": 0.0, "hmin": 0.0, "hmax": 0.0})
			i += 1
func _physics_process(_d: float) -> bool:   # im Physiktakt: Zeiten stimmen auch ohne --fixed-fps
	f += 1
	var t := f / 60.0
	for e in ships:
		if f == 2:
			e.fc.apply_model_gains(e.s.fc_gains); e.fc.mode = e.md; e.fc.armed = true
		var yaw := 0.0
		if t >= 0.5 and t < 1.0: yaw = -1.0
		elif t >= 1.5 and t < 2.0: yaw = 1.0
		e.fc.set_sticks(Vector2(0, 0.5), Vector2(yaw, 0))
		if f > 2:
			var s: AirshipPhysics = e.s
			var b := s.global_transform.basis
			e.dy = maxf(e.dy, absf(s.global_position.y - 1.5))
			e.low = minf(e.low, s.global_position.y - s.hull.diameter_m * 0.5)
			e.pmax = maxf(e.pmax, absf(rad_to_deg(asin(clampf(-b.z.y, -1, 1)))))
			e.rmax = maxf(e.rmax, absf(rad_to_deg(atan2(-b.x.y, b.y.y))))
			var n: Vector3 = -b.z
			var h := rad_to_deg(atan2(-n.z, n.x))
			e.hmin = minf(e.hmin, h); e.hmax = maxf(e.hmax, h)
	if t >= 6.0:
		for e in ships:
			print("%-8s %-10s Höhe ±%.2f m, Hülle min %.2f m über Boden%s, Nick max %4.1f°, Roll max %4.1f°, Kurs %+.0f…%+.0f°" % [
				e.name, FlightController.MODE_NAMES[e.md], e.dy, e.low, "  BODEN!" if e.low <= 0.02 else "", e.pmax, e.rmax, e.hmin, e.hmax])
		print("ENDE")
		return true
	return false
