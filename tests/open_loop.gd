extends SceneTree
# Ungeregelter Flug (Mode 1, Sticks neutral außer Gas) für verschiedene Flossengrößen
var ships := []
var frames := 0
func _initialize() -> void:
	for area in [0.08, 0.14]:
		var s := AirshipPhysics.new()
		var col := CollisionShape3D.new(); col.shape = SphereShape3D.new(); s.add_child(col)
		AirshipPresets.albacore_default(s)
		for f in s.surfaces: f.area_m2 = area
		s.trim_heaviness_n = 0.0
		s.rebuild_mass_properties()
		s.position = Vector3(ships.size() * 50, 0, 0)
		var fc := FlightController.new(); fc.airship = s; s.add_child(fc)
		root.add_child(s)
		fc.mode = FlightController.Mode.DIRECT
		fc.armed = true
		fc.set_sticks(Vector2(0, 0.8), Vector2.ZERO)
		ships.append([area, s])
func _physics_process(_dt: float) -> bool:
	frames += 1
	if frames == 240:
		for e in ships: e[1].rotate_x(deg_to_rad(5))   # Störung nach 4 s Anlauf
	if frames % 60 == 0 and frames >= 240:
		var line := "t=%2ds " % (frames / 60)
		for e in ships:
			var b: Basis = e[1].global_transform.basis
			line += "| A=%.2f pitch=%6.1f° alpha=%5.1f° v=%.1f " % [e[0], rad_to_deg(asin(-b.z.y)), e[1].alpha_deg, e[1].airspeed]
		print(line)
	return frames >= 900
