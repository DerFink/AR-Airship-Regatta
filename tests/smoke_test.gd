# 2026-10-28 08:06 – Abschlussmeldung ENDE für die CI
extends SceneTree
# Headless-Rauchtest: Hülle, Validator, Presets, 6-DOF-Schritt, Flugcontroller

var ship: AirshipPhysics
var fc: FlightController
var frames := 0

func _initialize() -> void:
	var h := GertlerHull.new()
	print("D=%.3f L=%.3f CB=%.3f k1=%.4f k2=%.4f krot=%.4f" % [h.diameter_m, h.length_m, h.cb_from_nose, h.k1, h.k2, h.k_rot])
	var neg := false
	for i in 101:
		if h.y_squared(i / 100.0) <= 0.0 and i > 0 and i < 100: neg = true
	print("Kontur negativ innen: ", neg, "  coeffs=", h.coeffs)
	var mesh := h.build_mesh()
	print("Mesh-Vertices: ", mesh.surface_get_array_len(0))

	ship = AirshipPhysics.new()
	var col := CollisionShape3D.new(); col.shape = SphereShape3D.new(); ship.add_child(col)
	AirshipPresets.albacore_default(ship)
	var r := TailValidator.validate(ship.hull, ship.surfaces, ship.cg_offset)
	print("Albacore: ", r.message, " pitch=%.2f yaw=%.2f VT=%.2f" % [r.ratio_pitch, r.ratio_yaw, r.vt_pitch])
	var c := AirshipPhysics.new()
	AirshipPresets.chewie(c)
	var r2 := TailValidator.validate(c.hull, c.surfaces, c.cg_offset)
	print("Chewie: ", r2.message, " pitch=%.2f yaw=%.2f ", r2.detail % [] if false else r2.detail, " pitch=%.2f yaw=%.2f" % [r2.ratio_pitch, r2.ratio_yaw])
	c.free()

	fc = FlightController.new()
	fc.airship = ship
	ship.add_child(fc)
	root.add_child(ship)
	ship.angular_velocity = Vector3.ZERO
	fc.mode = FlightController.Mode.STABILIZED
	fc.armed = true
	fc.set_sticks(Vector2(0, 0.6), Vector2(0, 0))   # 60 % Gas vorwärts

func _physics_process(_dt: float) -> bool:
	frames += 1
	if frames == 1: ship.rotate_x(deg_to_rad(10))   # Störung: 10° Nase hoch
	if frames % 60 == 0:
		var b := ship.global_transform.basis
		print("t=%2ds v=%.2f m/s alpha=%.1f° pitch=%.1f° pos.y=%.2f munk=%.3f surf=%.3f" % [frames / 60, ship.airspeed, ship.alpha_deg, rad_to_deg(asin(-b.z.y)), ship.global_position.y, ship.munk_moment.x, ship.surface_moment.x])
	if frames >= 600:
		print("ENDE")
		return true
	return false
