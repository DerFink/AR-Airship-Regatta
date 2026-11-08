# 2026-11-08 21:00 – Erstversion: Autopilot fliegt die Acht (3 Runden, fliegender Start) mit mehreren Parametersätzen gleichzeitig; Ergebnis als JSON, beste Bahn als CSV
# =============================================================================
# race_opt.gd  (Werkzeug, headless:  godot --headless --fixed-fps 60 -s tools/race_opt.gd)
# -----------------------------------------------------------------------------
# Liest Kandidaten aus user://race_in.json:
#   {"model": "chewie", "cands": [{"mode":2,"R1":2,"R2":2,"L":2.5,"k":1.5,
#     "t_str":0.6,"t_turn":0.25,"brake":2.0,"model_opts":{...}}, …], "trace": true}
# und fliegt jeden Satz in einem eigenen Luftschiff (alle im selben Physiklauf,
# weit auseinander). Gesteuert wird NUR über die Knüppel (set_sticks), also über
# den nachgebauten Teensy-Regler – wie ein Pilot.
#
# Bahn (Draufsicht, x = Strecke, z = quer, Pilot bei z > 0):
#   A: (0, +R1) → (d, −R2)     Gerade schräg über die Mitte
#   Bogen um Pylon 2 (Mittelpunkt (d,0), Radius R2) von (d,−R2) über (d+R2,0) nach (d,+R2)
#   B: (d, +R2) → (0, −R1)
#   Bogen um Pylon 1 von (0,−R1) über (−R1,0) nach (0,+R1)
# Das ergibt genau die Kontrollpunkte der Strecke (Course.GATES).
#
# Lenkung: Pure Pursuit – Zielpunkt L Meter voraus auf der Bahn, Seitenknüppel
# = k · Kursfehler (rad), begrenzt auf ±1. Gas: t_str auf den Geraden, t_turn ab
# „brake“ Meter vor einem Bogen bis zu seinem Ende. Höhe: Nickknüppel hält 1,5 m.
# =============================================================================
extends SceneTree

const SPACING := 400.0
const T_MAX := 150.0              ## Abbruch nach 150 s Flugzeit
const H_TARGET := 1.5

var runs: Array = []
var f := 0
var trace := false
var dist := Course.CUP_DISTANCE


func _initialize() -> void:
	var txt := FileAccess.get_file_as_string("user://race_in.json")
	var inp = JSON.parse_string(txt)
	trace = bool(inp.get("trace", false))
	var i := 0
	for c in inp.cands:
		var s := AirshipPhysics.new()
		AirshipPresets.chewie(s)
		_apply_opts(s, c.get("model_opts", {}))
		var off := Vector3(i * SPACING, 0, 0)
		var course := Course.new()
		course.preset = 0
		var st := course.start_transform(s)
		st.origin += off
		s.transform = st
		var fc := FlightController.new()
		fc.airship = s
		s.add_child(fc)
		root.add_child(s)
		runs.append({"s": s, "fc": fc, "c": c, "course": course, "off": off, "path": _make_path(c),
			"idx": 0, "done": false, "t": 0.0, "laps": [], "tr": [], "fail": ""})
		i += 1


## Modell-Varianten (für spätere Konfigurationsvergleiche)
func _apply_opts(s: AirshipPhysics, o: Dictionary) -> void:
	if o.has("thrust"):
		for m in s.motors: m.max_thrust_n = float(o.thrust)
	if o.has("swivel"):
		for m in s.motors: m.max_swivel_deg = float(o.swivel)
	s.rebuild_mass_properties()


## Bahn als Punktliste (je ≈ 0,1 m) mit Markierung „im Bogen“
func _make_path(c: Dictionary) -> Array:
	var R1: float = c.R1
	var R2: float = c.R2
	var pts: Array = []
	var seg := func(a: Vector2, b: Vector2, arc: bool):
		var n := maxi(2, int(a.distance_to(b) / 0.1))
		for k in n: pts.append([a.lerp(b, float(k) / n), arc])
	var arc_pts := func(center: Vector2, r: float, a0: float, a1: float):
		var n := maxi(8, int(absf(a1 - a0) * r / 0.1))
		for k in n:
			var a := lerpf(a0, a1, float(k) / n)
			pts.append([center + Vector2(cos(a), sin(a)) * r, true])
	seg.call(Vector2(0, R1), Vector2(dist, -R2), false)
	arc_pts.call(Vector2(dist, 0), R2, -PI * 0.5, PI * 0.5)          # über +x-Seite (hinter Pylon 2)
	seg.call(Vector2(dist, R2), Vector2(0, -R1), false)
	arc_pts.call(Vector2(0, 0), R1, -PI * 0.5, -PI * 1.5)            # über −x-Seite (vor Pylon 1)
	return pts


func _physics_process(dt: float) -> bool:
	f += 1
	var all_done := true
	for r in runs:
		if r.done:
			continue
		all_done = false
		_step(r, dt)
	if all_done or f * dt > T_MAX + 5.0:
		_finish()
		return true
	return false


func _step(r: Dictionary, dt: float) -> void:
	var s: AirshipPhysics = r.s
	var fc: FlightController = r.fc
	var c: Dictionary = r.c
	if f == 1:
		fc.apply_model_gains(s.fc_gains)
		fc.mode = int(c.get("mode", 2))
		fc.armed = true
	r.t += dt
	var b := s.global_transform.basis
	var p3: Vector3 = s.global_position - r.off
	var p := Vector2(p3.x, p3.z)
	# Fortschritt auf der Bahn: nächster Punkt in einem Fenster voraus (Bahn ist geschlossen)
	var path: Array = r.path
	var n := path.size()
	var best: int = r.idx
	var bd := INF
	for k in range(r.idx, r.idx + 60):
		var q: Vector2 = path[k % n][0]
		var dd := q.distance_squared_to(p)
		if dd < bd: bd = dd; best = k
	r.idx = best
	var la := int(float(c.L) / 0.1)
	var tgt: Vector2 = path[(best + la) % n][0]
	# Kursfehler (rechts = +)
	var fwd3 := -b.z; var right3 := b.x
	var fwd := Vector2(fwd3.x, fwd3.z).normalized()
	var rgt := Vector2(right3.x, right3.z).normalized()
	var want := (tgt - p).normalized()
	var err := atan2(want.dot(rgt), want.dot(fwd))
	var yaw := clampf(float(c.k) * err, -1.0, 1.0)
	# Gas: im Bogen oder kurz davor gedrosselt
	var brake_n := int(float(c.brake) / 0.1)
	var in_turn: bool = path[(best + brake_n) % n][1] or path[best % n][1]
	var thr: float = c.t_turn if in_turn else c.t_str
	# Höhe halten (Nickknüppel: −y = Nase hoch)
	var h: float = p3.y
	var vz := s.linear_velocity.y
	var pitch_stick := clampf(-(0.8 * (H_TARGET - h) - 0.6 * vz), -1.0, 1.0)
	fc.set_sticks(Vector2(0, thr), Vector2(yaw, pitch_stick))
	# Rundenwertung mit der echten Streckenlogik (Bug-Position)
	var nose: Vector3 = s.global_transform * Vector3(0, 0, -s.hull.cb_from_nose) - r.off
	var course: Course = r.course
	course.track(nose.x, nose.z, dt)
	if trace and f % 3 == 0:
		r.tr.append([snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(thr, 0.01), snappedf(s.linear_velocity.length(), 0.01),
			snappedf(rad_to_deg(atan2(-b.x.y, b.y.y)), 0.1), snappedf(h, 0.01)])
	if course.race == Course.Race.DONE:
		r.done = true
	elif r.t > T_MAX:
		r.done = true; r.fail = "Zeit"
	elif absf(h - H_TARGET) > 6.0 or absf(p.y) > 15.0 or p.x < -10.0 or p.x > dist + 10.0:
		r.done = true; r.fail = "Bahn verlassen t=%.1f h=%.1f x=%.1f z=%.1f" % [r.t, h, p.x, p.y]


func _finish() -> void:
	var out: Array = []
	for r in runs:
		var course: Course = r.course
		var laps: Array = []
		for lt in course.lap_times: laps.append(snappedf(lt, 0.01))
		var total := -1.0
		if course.race == Course.Race.DONE and r.fail == "":
			total = snappedf(course.time_s, 0.01)
		out.append({"c": r.c, "total": total, "laps": laps, "fail": r.fail, "tr": r.tr if trace else []})
	var fa := FileAccess.open("user://race_out.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("FERTIG ", out.size())
	print("ENDE")
