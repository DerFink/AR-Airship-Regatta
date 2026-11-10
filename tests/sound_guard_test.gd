# 2026-11-11 12:10 – .ino-Export und Bausteine
# 2026-11-11 10:45 – Erstversion: Klang-Sicherung – Stufen Fein/Mittel/Einfach, Herunterschalten bei Aussetzern, gemeinsamer Klang ab 3 Motoren; Modell-String mit Regler und Massen
extends SceneTree
var main: Node
var f := 0
func _initialize() -> void:
	PropSynth.level = 2
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	if f == 5:
		print("Start: Stufe %d, Klangerzeuger %d (Motoren %d)" % [PropSynth.level, main._prop_sounds.size(), main.ship.motors.size()])
		PropSynth.underrun = true                   # Aussetzer melden
	if f == 8:
		print("Nach Aussetzer: Stufe %d, Klangerzeuger %d, Motoren je Klang %d" % [PropSynth.level, main._prop_sounds.size(), main._prop_sounds[0].motors.size()])
		main.sound_guard._cool = 0.0
		PropSynth.underrun = true
	if f == 11:
		print("Nach 2. Aussetzer: Stufe %d, Schleife=%s" % [PropSynth.level, main._prop_sounds[0]._fallback != null])
		PropSynth.level = 2
		# drittes Motorpaar → ab 3 Motoren gemeinsamer Klang
		var r := AirshipPresets.make_motor("Motor r3", 0.6, 135.0, 1.2, 60.0, 45.0)
		var l := AirshipPresets.make_motor("Motor l3", 0.6, 225.0, 1.2, 60.0, 45.0)
		r.pair_id = "p3"; l.pair_id = "p3"
		main.ship.motors.append(r); main.ship.motors.append(l)
		main.ship.rebuild_mass_properties()
	if f == 14:
		print("4 Motoren, Stufe Fein gewählt: Klangerzeuger %d (gemeinsam)" % main._prop_sounds.size())
		# Regler im Modell-String
		main.fc.params[FlightController.Axis.PITCH]["Kp"] = 0.77
		main.fc.pitch_max_deg = 27.0
		main.ship.fin_mass_kg = 0.012
		main.ship.teensy_mass_kg = 0.008
		var code := ModelCodec.encode(main.ship)
		var d := ModelCodec.decode(code)
		print("String: ok=%s, Kp Nick %.2f, pitch_max %.0f, Flosse %.3f kg, Teensy %.3f kg" % [d.ok, d.data.fc.pitch.Kp, d.data.fc.gen.pitch_max_deg, d.data.mass.fm, d.data.mass.tm])
		main.fc.params[FlightController.Axis.PITCH]["Kp"] = 0.6
		main.fc.pitch_max_deg = 30.0
		ModelCodec.apply(main.ship, d.name, d.data)
		main.ship.model_applied.emit()
		print("Nach Import: Kp Nick %.2f, pitch_max %.0f, Teensy %.3f kg" % [main.fc.params[FlightController.Axis.PITCH]["Kp"], main.fc.pitch_max_deg, main.ship.teensy_mass_kg])
		AirshipPresets.chewie(main.ship)
		main.ship.model_applied.emit()
		main.fc.reset_to_defaults(main.ship.fc_gains)
		# .ino-Export mit Werkseinstellung: es dürfen kaum Werte abweichen
		var r: Dictionary = InoExport.build(main.fc, "Chewie")
		print("ino: %d Zeichen, geändert %d: %s, fehlt: %s" % [r.text.length(), r.changed.size(), ", ".join(r.changed), ", ".join(r.missing)])
		print("Kopf: ", r.text.get_slice("\n", 0).left(160))
		# Baustein „Nick-Schutz“ aus → 0, wieder an → zurück
		FcBlocks.set_on(main.fc, "protect", false)
		var off: float = main.fc.pitch_protect_band_deg
		var r2: Dictionary = InoExport.build(main.fc, "Chewie")
		FcBlocks.set_on(main.fc, "protect", true)
		print("Nick-Schutz aus: %.0f (ino: %s), wieder an: %.0f" % [off, ", ".join(r2.changed), main.fc.pitch_protect_band_deg])
		print("ENDE")
		main.queue_free()
	return false
