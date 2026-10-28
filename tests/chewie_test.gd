# 2026-10-28 08:06 – Abschlussmeldung ENDE für die CI
# 2026-10-28 07:53 – nur Schwenkmotoren über tail_gain/vec_gain statt Mischmodus
extends SceneTree
# Prüft die Chewie-Pigleg-Geometrie:
#   gleichsinniger Schwenk → Nickmoment, gegensinniger → Giermoment
#   und dass der Mischer bei Nick- bzw. Gier-Stick genau so schwenkt.

func _initialize() -> void:
	var ship := AirshipPhysics.new()
	AirshipPresets.chewie(ship)
	for m in ship.motors:
		print("%s pos=%s achse=%s invert=%s" % [m.display_name, m.position.snapped(Vector3.ONE * 0.01), m.swivel_axis.snapped(Vector3.ONE * 0.01), m.invert_swivel])
	print("Canards: ", ship.surfaces.filter(func(s): return s.kind == ControlSurface.Kind.CANARD).size())

	# Direkter Geometrietest bei Schub 1 N und 30° Schwenk
	for case in [["gleichsinnig", 1.0, 1.0], ["gegensinnig", 1.0, -1.0]]:
		var T := Vector3.ZERO
		var F := Vector3.ZERO
		for i in 2:
			var m: VectorMotor = ship.motors[i]
			m.armed = true
			m.spool_time_s = 0.0
			m.throttle_cmd = 1.0
			m.swivel_cmd = case[1] if i == 0 else case[2]
			m.max_swivel_deg = 30.0
			m.servo_speed_dps = 1e6
			var f := m.compute_force(0.016)
			F += f
			T += m.position.cross(f)
		print("%s: Kraft=%s  Moment Nick(x)=%.3f Gier(y)=%.3f Roll(z)=%.3f" % [case[0], F.snapped(Vector3.ONE * 0.001), T.x, T.y, T.z])

	# Mischer: Nick- und Gier-Stick im direkten Modus (frisches Schiff, Neutralstellung)
	ship.free()
	ship = AirshipPhysics.new()
	AirshipPresets.chewie(ship)
	var fc := FlightController.new()
	fc.airship = ship
	fc.mode = FlightController.Mode.DIRECT
	fc.tail_gain = 0.0; fc.vec_gain = 1.0   # nur Schwenkmotoren
	for st in [["Nick hoch", Vector2(0, 0.5), Vector2(0, -1)], ["Gier rechts", Vector2(0, 0.5), Vector2(1, 0)]]:
		fc.set_sticks(st[1], st[2])
		fc._mix(Vector3(fc.cmd_pitch, -fc.cmd_yaw, 0.0))
		print("%s → Schwenk rechts=%.2f links=%.2f | Gas rechts=%.2f links=%.2f" % [st[0], ship.motors[0].swivel_cmd, ship.motors[1].swivel_cmd, ship.motors[0].throttle_cmd, ship.motors[1].throttle_cmd])
	print("Stick-Beschriftung: ", fc.stick_labels())
	fc.free()
	ship.free()
	print("ENDE")
	quit()
