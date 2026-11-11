# 2026-11-11 07:50 – Erstversion: Profilvergleich Platte / NACA 0009 / NACA 0020 – Auftrieb und Widerstand über dem Anstellwinkel (Chewie-Flosse 361 cm², Streckung 1)
extends SceneTree
func _initialize() -> void:
	var defs := [["Platte 3 mm", false, 0.12, 3.0], ["NACA 0009", true, 0.09, 3.0], ["NACA 0020", true, 0.20, 3.0]]
	for d in defs:
		var s := ControlSurface.new()
		s.area_m2 = 0.0361; s.aspect_ratio = 1.0
		s.profile_naca = d[1]; s.naca_thickness = d[2]; s.plate_thickness_mm = d[3]
		var pr := s.profile_params()
		var row := "%-12s cd0 %.3f  Abriss %4.1f°  |" % [d[0], pr.cd0, pr.stall_deg]
		for a in [5, 10, 15, 20, 25, 30]:
			row += "  cl(%d°) %.2f" % [a, s.lift_coefficient(deg_to_rad(a))]
		print(row, "  | Schaum 25 kg/m³: %d g" % roundi(s.estimated_mass_kg(25.0) * 1000))
	print("ENDE")
	quit()
