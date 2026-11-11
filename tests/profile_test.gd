# 2026-11-11 08:30 – Profilvergleich Platte / NACA 0009 / NACA 0020 bei echter Reynoldszahl (Chewie-Flosse 361 cm², Streckung 1): Auftrieb über Anstellwinkel, Re je Fahrt
extends SceneTree
func _initialize() -> void:
	var defs := [["Platte 3 mm", false, 0.12], ["NACA 0009", true, 0.09], ["NACA 0020", true, 0.20]]
	for v in [2.0, 6.0, 10.0]:
		for d in defs:
			var s := ControlSurface.new()
			s.area_m2 = 0.0361; s.aspect_ratio = 1.0
			s.profile_naca = d[1]; s.naca_thickness = d[2]; s.plate_thickness_mm = 3.0
			var re := s.reynolds(v)
			var pr := s.profile_params(re)
			var vals := []
			for a in range(0, 41, 2):
				vals.append(snappedf(s.lift_coefficient(deg_to_rad(a), pr), 0.01))
			print("v=%.0f Re=%d %s stall=%.1f cd0=%.4f CL=%s" % [v, re, d[0], pr.stall_deg, pr.cd0, str(vals)])
	print("ENDE")
	quit()
