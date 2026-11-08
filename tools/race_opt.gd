# 2026-11-08 22:00 – Flossen so groß, dass sie nicht über das Boxmaß hinausragen (höchstens Chewie-Größe)
# 2026-11-08 21:50 – Bugmotor so platziert, dass er das Boxmaß nicht vergrößert
# 2026-11-08 21:30 – Konfigurationen für den Vergleich (Volumen, Leitwerk X/+/λ/umgekehrtes V, Antrieb mit/ohne Schwenk/Bugmotor), Boxmaß und F7b-Wertung in der Ausgabe
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


## Modell-Varianten für den Konfigurationsvergleich (08.11.2026)
##   thrust / swivel        Schub je Motor (N) bzw. Schwenkbereich (°) überschreiben
##   volume                 Hüllenvolumen (m³), L/D bleibt 6; alles andere skaliert:
##                          Fläche/Schub/Motoren/Schwenk ∝ (V/0,25)^(2/3), Hülle 27 g/m²
##   tail   "X" | "+" | "L" (Lambda) | "IV" (umgekehrtes V + Finne oben bis zur Boxkante)
##   prop   "swivel" (2 Motoren seitlich unten, Schwenk entlang der Hülle, wie Chewie)
##          "fixed"  (dieselben Motoren ohne Schwenk)
##          "bow"    (1 Motor vorn unten, schwenkt um die Hochachse, liegt im Boxmaß)
##   no_fc  true = ohne Teensy (Mode 1 Direkt, Elektronik leichter)
func _apply_opts(s: AirshipPhysics, o: Dictionary) -> void:
	if o.has("volume") or o.has("tail") or o.has("prop"):
		_build_config(s, o)
	if o.has("thrust"):
		for m in s.motors: m.max_thrust_n = float(o.thrust)
	if o.has("swivel"):
		for m in s.motors: m.max_swivel_deg = float(o.swivel)
	s.rebuild_mass_properties()


func _build_config(s: AirshipPhysics, o: Dictionary) -> void:
	var V := float(o.get("volume", 0.25))
	var k := pow(V / 0.25, 2.0 / 3.0)                 # Flächen-/Schub-Maßstab
	var kl := pow(V / 0.25, 1.0 / 3.0)                # Längen-Maßstab
	s.hull.volume_m3 = V
	s.set_hull(s.hull)
	# Hülle 27 g/m² (Oberfläche aus der Gertler-Form)
	s.hull_mass_kg = 0.027 * _hull_area(s.hull)
	# Elektronik: Teensy + RX + BEC 30 g; ohne Teensy 25 g
	s.electronics_mass_kg = 0.025 if bool(o.get("no_fc", false)) else 0.030
	# Leitwerk (08.11.2026): Pendelflossen ±50°, jede Flosse so groß, dass ihre Spitze
	# nicht über das Boxmaß der Hülle (+ Akku unten) hinausragt – höchstens aber
	# Chewies Flossengröße (0,0361 m² × k). Am Heck ist die Hülle dünn, dort passen
	# schräge Flossen gut in die Ecken der Box.
	var t: TailConfig = s.tail
	var a_max := 0.0361 * k
	var r_max := s.hull.diameter_m * 0.5
	var batt := 0.02 * kl
	var r_f := s.hull.radius_at(t.hull_x)
	var fit := func(angle_deg: float) -> float:
		var a := deg_to_rad(angle_deg)
		var lim := INF
		if absf(sin(a)) > 1e-3: lim = minf(lim, r_max / absf(sin(a)))
		if cos(a) > 1e-3: lim = minf(lim, r_max / cos(a))
		if cos(a) < -1e-3: lim = minf(lim, (r_max + batt) / -cos(a))
		var b := maxf(lim - r_f, 0.0)
		return clampf(b * b / t.aspect_ratio, 0.002, a_max)
	t.split_hv = true
	match str(o.get("tail", "L")):
		"X":
			t.layout = TailConfig.Layout.CROSS
			t.area_h_m2 = fit.call(45.0); t.area_v_m2 = t.area_h_m2
		"+":
			t.layout = TailConfig.Layout.PLUS
			t.area_h_m2 = fit.call(90.0); t.area_v_m2 = fit.call(0.0)
		"IV":
			# umgekehrtes V: zwei Schrägflossen 45° unter der Waagrechten + Finne oben
			t.layout = TailConfig.Layout.LAMBDA; t.v_angle_deg = 44.0
			t.area_h_m2 = fit.call(134.0); t.area_v_m2 = fit.call(0.0)
		_:
			# Lambda wie Chewie: gleichmäßig verteilt, untere Flossen 30° unter der Waagrechten
			t.layout = TailConfig.Layout.LAMBDA; t.v_angle_deg = 30.0
			t.area_h_m2 = fit.call(120.0); t.area_v_m2 = fit.call(0.0)
	s.fin_mass_kg = 0.010 * k                          # Flosse + Servo (Mittelwert, unabhängig von der Flossengröße)
	s.tail = t
	s.surfaces.clear()
	# Antrieb
	var prop := str(o.get("prop", "swivel"))
	var thrust := 7.0 * k
	var rp := 0.0508 * kl                             # 4"-Propeller, mit der Länge skaliert
	var mots: Array[VectorMotor] = []
	if prop == "bow":
		var m := AirshipPresets.make_motor("Bugmotor", 0.10, 180.0, 2.0 * thrust, 45.0, 90.0)
		m.prop_diameter_in = 4.0 * kl * sqrt(2.0)
		m.standoff_m = rp * sqrt(2.0) + 0.01
		m.mass_kg = (2.0 * 0.0185 + 0.0115) * k        # Motor für doppelten Schub + ein Schwenkservo
		m.reverse_allowed = true; m.reverse_efficiency = 0.55; m.spool_time_s = 0.03
		mots.append(m)
	else:
		mots = AirshipPresets.chewie_motor_pair()
		for m in mots:
			m.max_thrust_n = thrust
			m.standoff_m = rp + 0.01
			m.prop_diameter_in = 4.0 * kl
			if prop == "fixed":
				m.max_swivel_deg = 0.0
				m.mass_kg = 0.0185 * k                    # ohne Schwenkmechanismus (23 g für beide)
			else:
				m.mass_kg = 0.030 * k
	s.motors = mots
	s.rebuild_mass_properties()
	# Bugmotor: so weit hinten wie möglich, aber Motor + Propellerkreis dürfen nicht
	# unter die Box (Hülle + Akku) ragen – vorn ist die Hülle schlank genug
	if prop == "bow":
		var bottom := _box(s, true).z - s.hull.diameter_m * 0.5   # Abstand Achse → Boxunterkante
		var m: VectorMotor = s.motors[0]
		var rpb := m.prop_diameter_in * 0.0254 * 0.5
		for i in range(30, -1, -1):
			m.hull_x = i * 0.01
			if s.hull.radius_at(m.hull_x) + m.standoff_m + rpb <= bottom + 0.0005:
				break
		s.rebuild_mass_properties()
	# Motoren seitlich: so weit vorn/unten setzen, dass sie das Boxmaß nicht vergrößern
	if prop != "bow":
		var base := _box(s, true)
		for x in [0.25, 0.22, 0.19, 0.16, 0.13, 0.10]:
			for m in s.motors: m.hull_x = x
			s.rebuild_mass_properties()
			var b := _box(s, false)
			if b.y <= base.y + 0.001 and b.z <= base.z + 0.001:
				break


## Oberfläche der Gertler-Hülle (Kegelstumpf-Summe)
static func _hull_area(h: GertlerHull) -> float:
	var A := 0.0
	var n := 400
	for i in n:
		var x0 := float(i) / n
		var x1 := float(i + 1) / n
		var r0 := h.radius_at(x0)
		var r1 := h.radius_at(x1)
		var dl := (x1 - x0) * h.length_m
		A += PI * (r0 + r1) * sqrt(dl * dl + (r1 - r0) * (r1 - r0))
	return A


## Boxmaß über alles (x = Länge, y = Breite, z = Höhe): Hülle, Flossen,
## Motoren mit Propellerkreis, Akku unten (2 cm × Längenmaßstab).
## hull_only: nur Hülle, Flossen und Akku (Bezug für die Motorplatzierung).
func _box(s: AirshipPhysics, hull_only: bool) -> Vector3:
	var h := s.hull
	var r := h.diameter_m * 0.5
	var kl := pow(h.volume_m3 / 0.25, 1.0 / 3.0)
	var right := r; var left := r; var up := r; var down := r + 0.02 * kl
	for srf in s.surfaces:
		if not srf.tail_member: continue
		var a := deg_to_rad(srf.hull_angle_deg)
		var tip := h.radius_at(srf.hull_x) + sqrt(srf.aspect_ratio * srf.area_m2)
		right = maxf(right, tip * sin(a)); left = maxf(left, -tip * sin(a))
		up = maxf(up, tip * cos(a)); down = maxf(down, -tip * cos(a))
	if not hull_only:
		for m in s.motors:
			var rp := m.prop_diameter_in * 0.0254 * 0.5
			var c: Vector3 = m.position
			right = maxf(right, c.x + rp); left = maxf(left, -c.x + rp)
			up = maxf(up, c.y + rp); down = maxf(down, -c.y + rp)
	return Vector3(h.length_m, right + left, up + down)


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
		fc.mode = 0 if bool(c.get("model_opts", {}).get("no_fc", false)) else int(c.get("mode", 2))
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
		var bx := _box(r.s, false)
		var vref := bx.x * bx.y * bx.z * PI / 6.0
		out.append({"c": r.c, "total": total, "laps": laps, "fail": r.fail, "tr": r.tr if trace else [],
			"box": [snappedf(bx.x, 0.001), snappedf(bx.y, 0.001), snappedf(bx.z, 0.001)], "vref": snappedf(vref, 0.0001),
			"tau": snappedf(pow(vref, 1.0 / 3.0), 0.0001), "score": snappedf(total * pow(vref, 1.0 / 3.0), 0.01) if total > 0 else -1.0,
			"mass_g": snappedf(r.s.structure_mass_kg * 1000.0, 0.1), "rest_g": snappedf(r.s.rest_mass_kg * 1000.0, 0.1),
			"overweight": r.s.overweight, "motor_x": r.s.motors[0].hull_x})
	var fa := FileAccess.open("user://race_out.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("FERTIG ", out.size())
	print("ENDE")
