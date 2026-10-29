# 2026-10-29 03:23 – Gier-Parameter Knüppelstärke/Dämpfung (ys, yd)
# 2026-10-29 02:37 – optionale Feldgrenze (Rechteck + Rand) als Bedingung, langsamere Gasstufen in der Suche
# 2026-10-29 02:25 – Werkzeug (nicht in der CI): Rennlinien-Autopilot fliegt die Acht über die Knüppel, Zufallssuche über Linie, Gasstufen und Gier-Reglerwerte; Aufruf: godot --headless --fixed-fps 60 -s tests/race_search.gd -- chewie <Anzahl> <Seed> [Start-JSON] [local]
extends SceneTree
# Rennlinien-Autopilot (NUR Test/Messlatte, nicht in der App, nicht für den Teensy):
# fliegt die Acht um beide Pylone über die Knüppel (wie ein Pilot) und misst
# die Zeit für 3 Runden. Zufallssuche über Fluglinie, Gasstufen und Reglerwerte.
var runs: Array = []
var f := 0
const SPACING := 150.0
const T_MAX := 90.0
## Feldgrenze: Rand über das weiße Rechteck hinaus (m); < 0 = keine Grenze
var FIELD_MARGIN_EXTRA := -1.0
var preset := "chewie"

func _path(d: float, R: float) -> PackedVector2Array:
	# geschlossene Acht (x = Strecke, y = quer; +y = Pilotenseite)
	var pts := PackedVector2Array()
	pts.append(Vector2(0, R))
	for i in 13:                                   # Bogen um Pylon 2 (außen herum)
		var a := -PI * 0.5 + PI * i / 12.0
		pts.append(Vector2(d + R * cos(a), R * sin(a)))
	for i in 13:                                   # Bogen um Pylon 1
		var a := -PI * 0.5 - PI * i / 12.0
		pts.append(Vector2(R * cos(a), R * sin(a)))
	return pts

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	preset = args[0]
	if args.size() > 5: FIELD_MARGIN_EXTRA = float(args[5])
	var rng := RandomNumberGenerator.new(); rng.seed = int(args[2])
	var pick := func(a: Array): return a[rng.randi_range(0, a.size() - 1)]
	for k in int(args[1]):
		var p := {"R": pick.call([2.0, 3.0, 4.0, 5.0]), "L": pick.call([2.0, 3.0, 4.5]), "thr_hi": pick.call([0.3, 0.4, 0.55, 0.7]),
			"thr_lo": pick.call([0.1, 0.2, 0.3, 0.45]), "sw": pick.call([15.0, 30.0, 50.0]), "ky": pick.call([1.0, 2.0, 4.0]),
			"mode": pick.call([1, 2]), "ys": pick.call([0.7, 1.0, 1.5]), "yd": pick.call([0.7, 1.0, 1.5]),
			"vy": pick.call([0.4, 0.7, 1.0])}
		if args.size() > 4 and args[4] == "local":
			p = {"R": pick.call([3.0, 3.5, 4.0]), "L": pick.call([2.0, 2.5, 3.0]), "thr_hi": pick.call([0.6, 0.7, 0.85]),
				"thr_lo": pick.call([0.3, 0.45, 0.6]), "sw": pick.call([20.0, 30.0, 40.0]), "ky": pick.call([1.0, 1.5, 2.0]),
				"mode": pick.call([1, 2]), "ys": pick.call([0.8, 1.0, 1.2]), "yd": pick.call([0.8, 1.0, 1.3]),
				"vy": pick.call([0.4, 0.55, 0.7])}
		if k == 0 and args.size() > 3 and args[3] != "": p = JSON.parse_string(args[3])
		var s := AirshipPhysics.new()
		if preset == "chewie": AirshipPresets.chewie(s)
		else: AirshipPresets.albacore_default(s)
		var c := Course.new(); root.add_child(c)            # nur für die Rundenlogik
		var off := Vector3(0, 0, k * SPACING)
		s.transform = c.start_transform(s).translated(off)
		var fc := FlightController.new(); fc.airship = s; s.add_child(fc); root.add_child(s)
		runs.append({"p": p, "s": s, "fc": fc, "c": c, "off": off, "path": _path(c.distance(), p.R), "prog": 0, "box": Rect2(), "done_t": -1.0, "hmin": 99.0, "hmax": -99.0, "pmax": 0.0})

func _nose(e) -> Vector3:
	var s: AirshipPhysics = e.s
	return s.global_transform * Vector3(0, 0, -s.hull.cb_from_nose) - e.off

func _physics_process(dt: float) -> bool:
	f += 1
	var t := f / 60.0
	var active := 0
	for e in runs:
		var fc: FlightController = e.fc
		var s: AirshipPhysics = e.s
		var p: Dictionary = e.p
		if f == 2:
			fc.apply_model_gains(s.fc_gains)
			fc.mode = p.mode
			fc.params[FlightController.Axis.YAW].stick = p.get("ys", 1.0)
			fc.params[FlightController.Axis.YAW].damp = p.get("yd", 1.0)
			fc.vec_yaw_gain = p.vy
			fc.armed = true
			e.c.reset_race()
		if e.done_t >= 0.0: continue
		active += 1
		var nose := _nose(e)
		var pos := Vector2(nose.x, nose.z)
		# Fortschritt auf der Bahn: nächster Punkt nur vorwärts suchen (Kreuzung!)
		var path: PackedVector2Array = e.path
		var n := path.size()
		var best: int = e.prog
		var bd := pos.distance_to(path[best % n])
		for j in range(1, 9):
			var q: int = e.prog + j
			var dd := pos.distance_to(path[q % n])
			if dd < bd: bd = dd; best = q
		e.prog = best
		# Zielpunkt: so weit voraus, bis Abstand ≥ L
		var tgt := path[(best + 1) % n]
		for j in range(1, n):
			tgt = path[(best + j) % n]
			if pos.distance_to(tgt) >= p.L: break
		var fwd: Vector3 = -s.global_transform.basis.z
		var psi := atan2(fwd.z, fwd.x)
		var want := atan2(tgt.y - pos.y, tgt.x - pos.x)
		var err := wrapf(want - psi, -PI, PI)
		var yaw := clampf(p.ky * err / deg_to_rad(45.0), -1.0, 1.0)
		var thr: float = p.thr_lo if absf(rad_to_deg(err)) > p.sw else p.thr_hi
		# Höhe 2 m halten (wie ein Pilot mit dem Nick-Knüppel)
		var h := s.global_position.y
		var pitch := clampf(0.8 * (2.0 - h) - 0.6 * s.linear_velocity.y, -1.0, 1.0)
		fc.set_sticks(Vector2(0, thr), Vector2(yaw, -pitch))
		e.c.track(nose.x, nose.z, dt)
		var b: Rect2 = e.box
		e.box = b.expand(pos) if b.size != Vector2.ZERO or b.position != Vector2.ZERO else Rect2(pos, Vector2.ZERO)
		e.hmin = minf(e.hmin, h); e.hmax = maxf(e.hmax, h)
		e.pmax = maxf(e.pmax, absf(rad_to_deg(asin(clampf(fwd.y, -1, 1)))))
		if e.c.race == Course.Race.DONE: e.done_t = t
	if active == 0 or t >= T_MAX:
		var res: Array = []
		for e in runs:
			var c: Course = e.c
			var score: float = c.time_s if c.race == Course.Race.DONE else 1000.0 - c.lap * 100.0 - c.next_gate * 10.0
			# Optional: Feldgrenze (Rechteck ± Rand) einhalten, sonst ungültig
			if FIELD_MARGIN_EXTRA >= 0.0:
				var bx: Rect2 = e.box
				var m := FIELD_MARGIN_EXTRA
				if bx.position.x < -Course.FIELD_MARGIN - m or bx.end.x > c.distance() + Course.FIELD_MARGIN + m \
						or bx.position.y < -Course.FIELD_WIDTH * 0.5 - m or bx.end.y > Course.FIELD_WIDTH * 0.5 + m:
					score += 2000.0
			res.append([score, e])
		res.sort_custom(func(a, b): return a[0] < b[0])
		for i in mini(10, res.size()):
			var e = res[i][1]
			var c: Course = e.c
			var bx: Rect2 = e.box
			print("R %6.1f s  Runden %s  Feld x %.0f…%.0f m, quer %.0f…%.0f m, Höhe %.1f…%.1f m, Nick max %.0f°  %s" % [res[i][0], c.lap_times, bx.position.x, bx.end.x, bx.position.y, bx.end.y, e.hmin, e.hmax, e.pmax, JSON.stringify(e.p)])
		return true
	return false
