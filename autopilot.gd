# 2026-11-11 16:00 – Acht als statische Funktion figure_eight() (auch für die Bodenspur)
# 2026-11-10 21:30 – Umbenannt zu Autopilot (ersetzt den Demo-Flug): fliegt live die aktuelle Strecke mit dem aktuellen Modell und den aktuellen Reglerwerten; kann scheitern (Akku leer, Bahn verloren) und meldet das per Signal failed
# 2026-11-09 17:00 – Demo fliegt mit den echten Reglerwerten (Teensy-Werkseinstellung, Mode 3), Flugweise dafür neu optimiert (12,3 s)
# 2026-11-09 14:00 – Robuste Bestrunde Mode 3 (Böen und Knüppelverzögerung mitgerechnet)
# 2026-11-09 13:15 – Neue Bestrunde Mode 3 (mit Boden gerechnet, Sollhöhe 2,2 m); Demo wieder in Mode 3; rechnet vor dem Flugregler (vorher 1 Schritt Verzögerung → Höhe schaukelte sich auf)
# 2026-11-09 12:45 – Demo fliegt in Mode 2 (die Werte stammen aus Mode 2 – Fehler im Optimierer), kein Bodenkontakt mehr; Höhenhaltung aus FLY (h_target/h_kp/h_kd)
# 2026-11-09 10:20 – Reglerwerte aus FlightController.SIM_OPT (gleich wie die Reglerwahl „Sim-optimiert“)
# 2026-11-09 10:00 – Erstversion: Demo-Flug – der Autopilot aus der Rennoptimierung (tools/race_opt.gd) fliegt Chewies schnellste gefundene Runde (3 Runden ≈ 11,5 s) mit den im Simulator optimierten Reglerwerten
# =============================================================================
# Autopilot.gd
# -----------------------------------------------------------------------------
# Live-Flug der aktuellen Strecke: Modell, Reglerwerte, Akku und Location
# bleiben, wie sie sind – nur der Flugmodus wird für die Dauer auf Mode 3
# gestellt (darin wurde die Flugweise optimiert). Gelingt der Flug nicht
# (Akku leer, mehr als LOST_M neben der Bahn, Bodenberührung mit Tempo), endet
# er mit dem Signal failed(Grund).
#
# Fliegt die Acht wie in der Optimierung: Sollbahn aus zwei Kreisen um die
# Pylone mit tangentialen Diagonalen, Pure-Pursuit-Lenkung über den
# Seitenknüppel, Gasprofil je Kurve, Höhe 1,5 m über den Nickknüppel.
# Gesteuert wird nur über die Knüppel (FlightController.set_sticks) – der Regler
# arbeitet also wie beim Piloten. Nach dem Flug wird der vorherige Modus
# wiederhergestellt.
# =============================================================================
class_name Autopilot
extends Node

func _init() -> void:
	process_physics_priority = -100    # vor dem Flugregler rechnen: Knüppel im selben Physikschritt (wie in der Optimierung)

signal finished
## Autopilot gibt auf – reason ist ein kurzer Text für die Anzeige
signal failed(reason: String)

## So weit (m) darf das Schiff neben der Sollbahn sein, sonst gilt sie als verloren
const LOST_M := 6.0

## Beste gefundene Flugweise in Mode 3 mit den echten Reglerwerten (Teensy-Werkseinstellung,
## Suche vom 09.11.2026: mit Boden, je Satz 4 Flüge – ohne/mit Böen, 0–2 Schritte
## Knüppelverzögerung; Mittel 12,26 s, Hülle min. 1,03 m über Boden, Roll max. 5°)
const FLY := {"R1": 2.888, "R2": 2.864, "L": 4.0, "k": 3.03, "kff": 0.072,
	"t_str": 0.854, "cut_before": 3.0, "t_cut": 0.674, "t_arc": 0.994,
	"dip_len": 0.695, "t_dip": 0.839, "boost_start": 0.65,
	"h_target": 1.5, "h_kp": 0.557, "h_kd": 0.328}
const STEP := 0.1                 ## Punktabstand der Sollbahn (m)

var ship: AirshipPhysics
var fc: FlightController
var course: Course
var battery: Battery
var active := false

var _path: Array = []             ## [Punkt (x, z), im Bogen?, Weg bis Bogen, Weg seit Bogen]
var _idx := 0
var _t := 0.0
var _saved_params := {}
var _saved_general := {}
var _saved_mode := 0


## Autopilot starten (Schiff steht am Start, Rennen zurückgesetzt).
func start() -> void:
	_path = _make_path(course.distance())
	_idx = 0
	_t = 0.0
	# Eigene Einstellungen des Piloten merken (werden nach dem Flug wiederhergestellt)
	_saved_params = fc.params.duplicate(true)
	_saved_general = {}
	for key in FlightController.GENERAL_KEYS:
		_saved_general[key] = fc.get(key)
	_saved_mode = int(fc.mode)
	# Live-Flug: die aktuellen Reglerwerte bleiben (Wunsch Nutzer 10.11.2026)
	fc.mode = FlightController.Mode.MODE3            # in diesem Modus wurde optimiert
	fc.armed = true
	active = true


## Autopilot beenden und die vorherigen Reglerwerte wiederherstellen.
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
	# Gescheitert? (Akku leer, Bahn verloren)
	if battery and battery.soc <= 0.0:
		_fail("Akku leer")
		return
	if bd > LOST_M * LOST_M and _t > 2.0:
		_fail("Bahn verloren")
		return
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
	# Höhe halten (Nickknüppel nach hinten = Nase hoch = negatives y):
	# Sollhöhe h_target, Verstärkung auf Höhenfehler h_kp und Steigrate h_kd
	var pitch_stick := clampf(-(FLY.h_kp * (FLY.h_target - p3.y) - FLY.h_kd * ship.linear_velocity.y), -1.0, 1.0)
	fc.set_sticks(Vector2(0, thr), Vector2(clampf(yaw_cmd, -1.0, 1.0), pitch_stick))


## Sollbahn: Acht aus Kreisen um beide Pylone mit tangentialen Diagonalen
func _make_path(dist: float) -> Array:
	return figure_eight(dist)


## Die Acht als Punktliste (auch für die Spur auf dem Hallenboden, CourseTrack).
## Je Punkt: [Vector2(x, z), im Bogen?, Weg bis Bogen, Weg seit Bogen].
static func figure_eight(dist: float) -> Array:
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


## Aufgeben: Regler zurückstellen und Grund melden.
func _fail(reason: String) -> void:
	stop()
	failed.emit(reason)
