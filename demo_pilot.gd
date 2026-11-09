# 2026-11-09 10:20 – Reglerwerte aus FlightController.SIM_OPT (gleich wie die Reglerwahl „Sim-optimiert“)
# 2026-11-09 10:00 – Erstversion: Demo-Flug – der Autopilot aus der Rennoptimierung (tools/race_opt.gd) fliegt Chewies schnellste gefundene Runde (3 Runden ≈ 11,5 s) mit den im Simulator optimierten Reglerwerten
# =============================================================================
# DemoPilot.gd
# -----------------------------------------------------------------------------
# Fliegt die Acht wie in der Optimierung: Sollbahn aus zwei Kreisen um die
# Pylone mit tangentialen Diagonalen, Pure-Pursuit-Lenkung über den
# Seitenknüppel, Gasprofil je Kurve, Höhe 1,5 m über den Nickknüppel.
# Gesteuert wird nur über die Knüppel (FlightController.set_sticks) – der Regler
# arbeitet also wie beim Piloten. Während der Demo gelten die optimierten
# Reglerwerte; danach werden die vorherigen Werte wiederhergestellt.
# =============================================================================
class_name DemoPilot
extends Node

signal finished

## Beste gefundene Flugweise (Suche vom 08.11.2026, Mittel aus 3 Flügen mit Böen 11,5 s)
const FLY := {"R1": 2.102, "R2": 2.445, "L": 3.867, "k": 2.673, "kff": 0.06,
	"t_str": 0.866, "cut_before": 2.853, "t_cut": 0.862, "t_arc": 1.0,
	"dip_len": 0.863, "t_dip": 0.788, "boost_start": 0.703}
const H_TARGET := 1.5
const STEP := 0.1                 ## Punktabstand der Sollbahn (m)

var ship: AirshipPhysics
var fc: FlightController
var course: Course
var active := false

var _path: Array = []             ## [Punkt (x, z), im Bogen?, Weg bis Bogen, Weg seit Bogen]
var _idx := 0
var _t := 0.0
var _saved_params := {}
var _saved_general := {}
var _saved_mode := 0


## Demo starten (Schiff steht am Start, Rennen zurückgesetzt).
func start() -> void:
	_path = _make_path(course.distance())
	_idx = 0
	_t = 0.0
	_saved_params = fc.params.duplicate(true)
	_saved_general = {"yaw_swivel_full_lever": fc.yaw_swivel_full_lever}   # einziger allgemeiner Wert in SIM_OPT
	_saved_mode = int(fc.mode)
	fc.apply_overrides(FlightController.SIM_OPT)    # im Simulator optimierte Reglerwerte
	fc.mode = FlightController.Mode.MODE3
	fc.armed = true
	active = true


## Demo beenden und die vorherigen Reglerwerte wiederherstellen.
func stop() -> void:
	if not active:
		return
	active = false
	fc.params = _saved_params
	for k in _saved_general: fc.set(k, _saved_general[k])
	fc.mode = _saved_mode
	fc.armed = false
	fc.set_sticks(Vector2.ZERO, Vector2.ZERO)
	finished.emit()


func _physics_process(dt: float) -> void:
	if not active:
		return
	_t += dt
	var b := ship.global_transform.basis
	var p3 := ship.global_position - course.global_position
	var p := Vector2(p3.x, p3.z)
	var n := _path.size()
	# Fortschritt auf der Sollbahn: nächster Punkt in einem Fenster voraus
	var best := _idx
	var bd := INF
	for k in range(_idx, _idx + 60):
		var dd: float = (_path[k % n][0] as Vector2).distance_squared_to(p)
		if dd < bd: bd = dd; best = k
	_idx = best
	# Lenkung: Zielpunkt L voraus, Kursfehler × k, plus Krümmungs-Vorsteuerung
	var fwd := Vector2(-b.z.x, -b.z.z).normalized()
	var rgt := Vector2(b.x.x, b.x.z).normalized()
	var tgt: Vector2 = _path[(best + int(FLY.L / STEP)) % n][0]
	var want := (tgt - p).normalized()
	var yaw_cmd: float = FLY.k * atan2(want.dot(rgt), want.dot(fwd))
	var v := maxf(ship.linear_velocity.length(), 0.5)
	var m := clampi(int(v * 0.5 / STEP), 2, 60)
	var t0: Vector2 = ((_path[(best + 1) % n][0] as Vector2) - _path[best % n][0]).normalized()
	var t1: Vector2 = ((_path[(best + m + 1) % n][0] as Vector2) - _path[(best + m) % n][0]).normalized()
	var d_psi := wrapf(atan2(t1.dot(rgt), t1.dot(fwd)) - atan2(t0.dot(rgt), t0.dot(fwd)), -PI, PI)
	yaw_cmd += FLY.kff * rad_to_deg(d_psi / 0.5) / 180.0
	# Gasprofil: vor dem Bogen etwas weg, im Bogen voll, danach kurz zurück, dann Gerade
	var pt: Array = _path[best % n]
	var thr: float = FLY.t_str
	if pt[1]: thr = FLY.t_arc
	elif pt[2] <= FLY.cut_before: thr = FLY.t_cut
	elif pt[3] <= FLY.dip_len: thr = FLY.t_dip
	if _t < FLY.boost_start: thr = 1.0
	# Höhe halten (Nickknüppel nach hinten = Nase hoch = negatives y)
	var pitch_stick := clampf(-(0.8 * (H_TARGET - p3.y) - 0.6 * ship.linear_velocity.y), -1.0, 1.0)
	fc.set_sticks(Vector2(0, thr), Vector2(clampf(yaw_cmd, -1.0, 1.0), pitch_stick))


## Sollbahn: Acht aus Kreisen um beide Pylone mit tangentialen Diagonalen
func _make_path(dist: float) -> Array:
	var R1: float = FLY.R1
	var R2: float = FLY.R2
	var pts: Array = []
	var seg := func(a: Vector2, b: Vector2):
		var k := maxi(2, int(a.distance_to(b) / STEP))
		for i in k: pts.append([a.lerp(b, float(i) / k), false])
	var arc := func(c: Vector2, r: float, a0: float, a1: float):
		var k := maxi(8, int(absf(a1 - a0) * r / STEP))
		for i in k:
			var a := lerpf(a0, a1, float(i) / k)
			pts.append([c + Vector2(cos(a), sin(a)) * r, true])
	var al := asin(clampf((R1 + R2) / dist, -0.99, 0.99))
	var sa := sin(al)
	var ca := cos(al)
	seg.call(Vector2(R1 * sa, R1 * ca), Vector2(dist - R2 * sa, -R2 * ca))
	arc.call(Vector2(dist, 0), R2, -(PI * 0.5 + al), PI * 0.5 + al)
	seg.call(Vector2(dist - R2 * sa, R2 * ca), Vector2(R1 * sa, -R1 * ca))
	arc.call(Vector2(0, 0), R1, -(PI * 0.5 - al), -(PI * 1.5 + al))
	# je Punkt: Weg bis zum nächsten Bogen und seit dem letzten Bogen
	var n := pts.size()
	var to_arc := []; to_arc.resize(n)
	var since := []; since.resize(n)
	var d := 1e9
	for k in range(2 * n - 1, -1, -1):
		var i := k % n
		d = 0.0 if pts[i][1] else d + STEP
		if k < n: to_arc[i] = d
	d = 1e9
	for k in 2 * n:
		var i := k % n
		d = 0.0 if pts[i][1] else d + STEP
		if k >= n: since[i] = d
	for i in n:
		pts[i].append(to_arc[i]); pts[i].append(since[i])
	return pts
