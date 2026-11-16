# 2026-11-16 23:40 – Erstversion: volle 6×6-Massenmatrix – (1) symmetrischer Sonderfall = bisherige Diagonal-Rechnung, (2) Matrix symmetrisch und positiv definit, (3) Chewie fliegt im Modus Angle mit beiden Rechenarten stabil, (4) Rechenzeit je Schritt
extends SceneTree

var ok := true


func _close(a: Vector3, b: Vector3, tol: float) -> bool:
	return (a - b).length() <= tol * maxf(1.0, b.length())


func _initialize() -> void:
	var s := AirshipPhysics.new()
	AirshipPresets.chewie(s)
	root.add_child(s)
	s.rebuild_mass_properties()

	# --- (1) Sonderfall: Schwerpunkt im Ursprung, nur Hülle → wie Diagonale ---
	var i_dist := Vector3(0.4, 0.4, 0.05)
	s.cg_offset = Vector3.ZERO
	s.inertia_rb = i_dist
	s._build_mass_matrix(i_dist, [], [])
	var v := Vector3(0.3, -0.2, -4.0)
	var w := Vector3(0.1, 0.25, -0.05)
	var F := Vector3(0.2, -0.1, 0.5)
	var T := Vector3(0.03, -0.02, 0.01)
	var acc: Array = s._solve_full(F, T, v, w)
	# bisherige Rechnung (Körperableitungen)
	var Ma_v := s.added_mass * v
	var munk := -v.cross(Ma_v) * s.munk_factor
	var Fd := F + s.added_mass * w.cross(v) - w.cross(Ma_v)
	var a_in := Fd / (Vector3.ONE * s.total_mass + s.added_mass)
	var vdot := a_in - w.cross(v)
	var I_eff := s.inertia_rb + s.added_inertia
	var wdot := (T + munk - w.cross(I_eff * w)) / I_eff
	if _close(acc[0], vdot, 1e-6) and _close(acc[1], wdot, 1e-6):
		print("ok   Sonderfall gleich der Diagonal-Rechnung")
	else:
		print("FEHLER Sonderfall: voll ", acc, " diagonal ", [vdot, wdot]); ok = false

	# --- (2) echte Matrix: symmetrisch, positiv definit ---
	s.rebuild_mass_properties()
	var sym := true
	for i in 6:
		for j in 6:
			if absf(s._m6[i * 6 + j] - s._m6[j * 6 + i]) > 1e-9: sym = false
	if sym and s._m6_ok:
		print("ok   M symmetrisch und positiv definit (Kopplung m·r_G: %.4f)" % s._m6[0 * 6 + 5])
	else:
		print("FEHLER M nicht symmetrisch/positiv definit"); ok = false

	# --- (4) Rechenzeit ---
	var t0 := Time.get_ticks_usec()
	for k in 1000:
		s._solve_full(F, T, v, w)
	var us := float(Time.get_ticks_usec() - t0) / 1000.0
	print("ok   Rechenzeit je Schritt (voll): %.1f µs" % us)
	s.queue_free()

	# --- (3) Flug: Angle-Modus, beide Rechenarten ---
	for full in [false, true]:
		var sh := AirshipPhysics.new()
		AirshipPresets.chewie(sh)
		sh.mass_matrix_full = full
		root.add_child(sh)
		sh.rebuild_mass_properties()
		sh.global_position = Vector3(0, 20, 0)
		var fc := FlightController.new()
		fc.airship = sh
		sh.add_child(fc)
		fc.adopt_ship_modes(sh)
		fc.mode_index = 1
		fc.armed = true
		_flights.append([sh, fc, full])
	print("Flug läuft …")


var _flights: Array = []
var _n := 0


func _physics_process(_dt: float) -> bool:
	_n += 1
	for fl in _flights:
		var fc: FlightController = fl[1]
		fc.cmd_throttle = 0.7
		fc.cmd_pitch = 0.3 if (_n / 120) % 2 == 0 else -0.3
		fc.cmd_yaw = 0.4 if (_n / 180) % 2 == 0 else -0.4
	if _n == 600:
		for fl in _flights:
			var sh: AirshipPhysics = fl[0]
			var pitch := rad_to_deg(asin(clampf(-sh.global_transform.basis.z.y, -1.0, 1.0)))
			var roll := rad_to_deg(asin(clampf(sh.global_transform.basis.x.y, -1.0, 1.0)))
			var v := sh.linear_velocity.length()
			print("%s: v %.1f m/s, Nick %.1f°, Roll %.1f°" % ["voll" if fl[2] else "diagonal", v, pitch, roll])
			if absf(pitch) > 45.0 or absf(roll) > 30.0 or v > 30.0 or is_nan(v):
				print("FEHLER Flug instabil (%s)" % ("voll" if fl[2] else "diagonal")); ok = false
		print("mass6_test: " + ("OK" if ok else "FEHLER"))
		print("ENDE")
		quit(0 if ok else 1)
		return true
	return false
