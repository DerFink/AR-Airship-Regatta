extends SceneTree
# Headless-Test der kompletten App: Hauptszene laden, fliegen (Knüppel),
# Baukasten bedienen (Preset, Hülle, Bauteil), PID-Menü, zurück zum Flug.

var main: Node
var f := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _process(_dt: float) -> bool:
	f += 1
	match f:
		5:
			main.fc.mode = FlightController.Mode.STABILIZED
			main.hud._btn_arm.button_pressed = true          # Motoren an über den Schalter
			main.hud.stick_left.value = Vector2(0, 0.7)       # Gas
			main.hud.stick_right.value = Vector2(0.5, 0.2)    # Gier rechts + Nick
		240:
			print("Flug: v=%.2f m/s armed=%s alpha=%.1f pills=%s | %s" % [main.ship.airspeed, main.fc.armed, main.ship.alpha_deg, main.hud._pill_speed.text, main.hud._pill_mode.text])
			print("Knüppel-Beschriftung: ", main.hud.stick_left.caption, " / ", main.hud.stick_right.caption)
			main._set_view(main.View.BUILD)
		245:
			print("Baukasten: armed=%s frozen=%s banner=%s" % [main.fc.armed, main.ship.freeze, main.builder._banner.get_child(0).text])
			main.builder._on_preset(2)                       # Chewie
		250:
			print("Chewie geladen: Teile=%d Banner=%s" % [main.builder._parts_list.item_count, main.builder._banner.get_child(0).text])
			main.builder._add_canard()
			main.ship.hull.volume_m3 = 0.4
		255:
			print("Nach Canard + 0,4 m³: L=%.2f Teile=%d Stats=%s" % [main.ship.hull.length_m, main.builder._parts_list.item_count, main.builder._stats.text.replace("\n", " | ")])
			main.builder._on_part_selected(0)   # erster Motor
			print("Editor-Zeilen für Motor: ", main.builder._editor_box.get_child_count())
			main._set_view(main.View.PID)
		260:
			print("PID-Regler-Zeilen: ", main.pid._gain_box.get_child_count())
			main.fc.set_param(FlightController.Mode.STABILIZED, FlightController.Axis.PITCH, "kp", 1.2)
			print("kp Nick Mode 2 = ", main.fc.get_param(FlightController.Mode.STABILIZED, FlightController.Axis.PITCH, "kp"))
			main._set_view(main.View.FLY)
		300:
			print("Watchdog vereinfachen-Test")
			main.watchdog._set_simplified(true)
			print("Banner: ", main.hud._banner.get_child(0).text, " slices=", main.ship.crossflow_slices)
			print("Motorklänge: ", main._prop_sounds.size(), " für ", main.ship.motors.size(), " Motoren")
			main.hud._btn_arm.button_pressed = true          # nach dem Baukasten neu scharf schalten
			main.hud.stick_left.value = Vector2(0, -0.8)       # Gas zurück: Rückwärtsschub
			main.hud.stick_right.value = Vector2.ZERO
		420:
			print("Rückwärts: v=%.2f m/s, Motor-Drehzahl %.0f U/min, rückwärts=%s" % [main.ship.airspeed, main.ship.motors[0].rpm(), main.ship.motors[0].is_reversing()])
			main.hud.stick_left.value = Vector2.ZERO
			main.reset_ship()
		421:
			pass
		423:
			print("Zurückgesetzt: Position %s, v=%.2f m/s, Kamera-Bildwinkel %.0f°" % [main.ship.global_position.snapped(Vector3.ONE * 0.1), main.ship.linear_velocity.length(), main.camera.fov])
			main._set_view(main.View.BUILD)
			main.ship.livery.text = "TEST"
			main.builder.get_child(0).get_child(0).current_tab = 3   # Reiter Gestaltung
			main._set_view(main.View.SHARE)
		425:
			print("Teilen: armed=%s String=%s… Hinweis=%s" % [main.fc.armed, main.share._code.text.left(20), main.share._logo_hint.text])
			main.share._on_save()
			print("Banner: ", main.share._banner.get_child(0).text)
			main._set_view(main.View.BUILD)
		430:
			print("Modellliste im Baukasten: %d Einträge" % main.builder._preset.item_count)
			print("ENDE ohne Abbruch")
			return true
	return false
