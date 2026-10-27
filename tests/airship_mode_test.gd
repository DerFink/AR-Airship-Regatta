extends SceneTree
# Test Mode 4 „Luftschiff“: Roll frei, Nick gegen Horizont, Gier um die Senkrechte.
# Chewie und Albacore je mit ihren PID-Vorgaben bei 50 % und 100 % Schub,
# nach 8 s Rollstoß (Krängung), ab 12 s Nick-Befehl „hoch“.
var cases: Array = []
var f := 0
func _initialize() -> void:
	var i := 0
	for preset in ["chewie", "albacore"]:
		for th in [0.5, 1.0]:
			var s := AirshipPhysics.new()
			if preset == "chewie": AirshipPresets.chewie(s)
			else: AirshipPresets.albacore_default(s)
			s.position = Vector3(i * 200.0, 100.0, 0)
			var fc := FlightController.new()
			fc.airship = s
			s.add_child(fc)
			root.add_child(s)
			cases.append({"s": s, "fc": fc, "name": preset, "th": th, "rmax": 0.0, "p_end": 0.0, "p_mid": 0.0})
			i += 1
func _pitch_roll(s: AirshipPhysics) -> Vector2:
	var b := s.global_transform.basis
	return Vector2(rad_to_deg(asin(clampf(-b.z.y, -1, 1))), rad_to_deg(atan2(-b.x.y, b.y.y)))
func _process(_dt: float) -> bool:
	f += 1
	if f == 2:
		for c in cases:
			c.fc.apply_model_gains(c.s.fc_gains)
			c.fc.mode = FlightController.Mode.AIRSHIP
			c.fc.armed = true
			c.fc.set_sticks(Vector2(0, c.th), Vector2.ZERO)
	if f == 480:   # Rollstoß
		for c in cases: c.s.angular_velocity = -c.s.global_transform.basis.z * 1.2
	if f == 720:   # Nick hoch (Stick ziehen = −right.y)
		for c in cases: c.fc.set_sticks(Vector2(0, c.th), Vector2(0, -0.5))
	if f > 480:
		for c in cases:
			var pr := _pitch_roll(c.s)
			c.rmax = maxf(c.rmax, absf(pr.y))
			if f == 719: c.p_mid = pr.x
			c.p_end = pr.x
	if f >= 1200:
		for c in cases:
			var pr := _pitch_roll(c.s)
			print("%-8s Schub %.1f: Nick vor Befehl %5.1f°, Nick nach Befehl (Soll 15°) %5.1f°, max. Krängung %5.1f°, Krängung am Ende %5.1f°" % [c.name, c.th, c.p_mid, c.p_end, c.rmax, pr.y])
		print("ENDE")
		return true
	return false
