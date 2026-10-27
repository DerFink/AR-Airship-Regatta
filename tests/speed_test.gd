extends SceneTree
# Beschleunigung und Endgeschwindigkeit von Chewie bei Vollgas (Mode 2),
# dazu die Lage von HUD-Elementen (müssen im Bild liegen).

var main: Node
var f := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_dt: float) -> bool:
	f += 1
	if f == 3:
		AirshipPresets.chewie(main.ship)
		main.fc.mode = FlightController.Mode.STABILIZED
		main.hud._btn_arm.button_pressed = true
		main.hud.stick_left.value = Vector2(0, 1.0)          # Vollgas
	if f % 15 == 0 and f <= 240:
		var m: VectorMotor = main.ship.motors[0]
		var b: Basis = main.ship.global_transform.basis
		print("pos=%s nick=%.0f° roll=%.0f° | " % [main.ship.global_position.snapped(Vector3.ONE*0.1), rad_to_deg(asin(-b.z.y)), rad_to_deg(atan2(-b.x.y, b.y.y))], "t=%4.1fs  v=%5.1f km/h  Schub je Motor %.2f N (Faktor %.2f)  Drehzahl %.0f" % [
			f / 60.0, main.ship.airspeed * 3.6, m.thrust_for(m._throttle) * m.speed_factor(main.ship.airspeed),
			m.speed_factor(main.ship.airspeed), m.rpm()])
	if f == 241:
		var vs: Vector2 = root.get_visible_rect().size
		var h = main.hud
		var ok := true
		for c in [h._tl, h._tr, h.stick_left, h.stick_right]:
			var r := Rect2(c.position, c.size)
			ok = ok and Rect2(Vector2.ZERO, vs).encloses(r)
		print("HUD-Elemente vollständig im Bild: ", ok)
		print("ENDE")
		return true
	return false
