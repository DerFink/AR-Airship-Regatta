# 2026-11-11 17:10 – Erstversion: Bestenliste nur mit unveränderten Modellen der Auswahl (Aussehen und Regler zählen nicht)
extends SceneTree
func _initialize() -> void:
	var s := AirshipPhysics.new()
	var fc := FlightController.new()
	fc.airship = s
	s.add_child(fc)
	root.add_child(s)
	AirshipPresets.chewie(s)
	print("Chewie unverändert: '%s'" % AirshipPresets.standard_model_of(s))
	s.livery.material = "gold"
	fc.params[FlightController.Axis.PITCH]["Kp"] = 1.1
	print("Chewie Gold + anderer Regler: '%s'" % AirshipPresets.standard_model_of(s))
	s.tail.area_m2 *= 1.2
	s.rebuild_mass_properties()
	print("Chewie größeres Leitwerk: '%s'" % AirshipPresets.standard_model_of(s))
	AirshipPresets.albacore_default(s)
	print("Albacore: '%s'" % AirshipPresets.standard_model_of(s))
	s.payload_mass_kg = 0.01
	s.rebuild_mass_properties()
	print("Albacore mit Nutzlast: '%s'" % AirshipPresets.standard_model_of(s))
	print("ENDE")
	quit()
