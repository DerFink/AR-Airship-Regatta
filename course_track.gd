# 2026-11-11 16:00 – Erstversion (Entwurf): Flugspur als Acht auf dem Hallenboden – gestrichelte Linie um beide Pylone mit Richtungspfeilen, Punkt unter dem Luftschiff (Lot auf den Boden) und hell hervorgehobenes Stück der Acht direkt vor dem Schiff
# =============================================================================
# CourseTrack.gd  (Kind der Strecke)
# -----------------------------------------------------------------------------
# Die Acht ist dieselbe Sollbahn, die der Autopilot fliegt (zwei Kreise um die
# Pylone, tangentiale Diagonalen) – passt sich dem Pylonabstand an.
#   – Grundlinie:   gestrichelt, halbtransparent
#   – Pfeile:       alle 2 m in Flugrichtung
#   – Lot:          Ring auf dem Boden genau unter dem Luftschiff
#   – Vorausschau:  die nächsten 4 m der Acht ab der Stelle, an der das Schiff
#                   gerade ist, leuchten → man sieht, wohin es weitergeht
# =============================================================================
class_name CourseTrack
extends Node3D

const Y := 0.012                       ## Höhe über dem Boden (gegen Flimmern)
const WIDTH := 0.07                    ## Linienbreite (m)
const AHEAD_M := 4.0                   ## Länge des hervorgehobenen Stücks
const COLOR := Color(1.0, 0.48, 0.24, 0.55)
const COLOR_AHEAD := Color(1.0, 0.85, 0.3, 0.95)

var course: Course
var ship: AirshipPhysics
var _pts: Array = []                   ## Punkte der Acht (Vector2 x, z), Abstand 0,1 m
var _base := MeshInstance3D.new()
var _ahead := MeshInstance3D.new()
var _ring := MeshInstance3D.new()
var _idx := 0
var _dist := -1.0


func _ready() -> void:
	for mi in [_base, _ahead, _ring]:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_base.material_override = _mat(COLOR)
	_ahead.material_override = _mat(COLOR_AHEAD)
	_ring.material_override = _mat(COLOR_AHEAD)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.22
	torus.outer_radius = 0.3
	_ring.mesh = torus
	_ring.scale = Vector3(1, 0.05, 1)


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Acht neu aufbauen (bei neuem Pylonabstand).
func rebuild() -> void:
	_dist = course.distance()
	_pts = []
	for p in Autopilot.figure_eight(_dist):
		_pts.append(p[0])
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := _pts.size()
	# gestrichelt: 0,5 m Strich, 0,3 m Lücke
	var run := 0.0
	for i in n:
		var a: Vector2 = _pts[i]
		var b: Vector2 = _pts[(i + 1) % n]
		run += a.distance_to(b)
		if fmod(run, 0.8) < 0.5:
			_quad(im, a, b, WIDTH)
	# Richtungspfeile alle 2 m (Winkel ˄ in Flugrichtung)
	run = 0.0
	var next := 1.0
	for i in n:
		var a: Vector2 = _pts[i]
		var b: Vector2 = _pts[(i + 1) % n]
		run += a.distance_to(b)
		if run >= next:
			next += 2.0
			var d := (b - a).normalized()
			var side := Vector2(-d.y, d.x)
			var tip := a + d * 0.25
			_quad(im, a - d * 0.1 + side * 0.22, tip, WIDTH * 1.2)
			_quad(im, a - d * 0.1 - side * 0.22, tip, WIDTH * 1.2)
	im.surface_end()
	_base.mesh = im


## Dünnes Rechteck auf dem Boden von a nach b.
static func _quad(im: ImmediateMesh, a: Vector2, b: Vector2, w: float) -> void:
	var d := (b - a)
	if d.length() < 1e-5: return
	var s := Vector2(-d.y, d.x).normalized() * w * 0.5
	var p := [a + s, a - s, b - s, b + s]
	for k in [0, 1, 2, 0, 2, 3]:
		im.surface_add_vertex(Vector3(p[k].x, Y, p[k].y))


func _process(_dt: float) -> void:
	if course == null or ship == null:
		return
	if absf(course.distance() - _dist) > 0.01:
		rebuild()
	var n := _pts.size()
	if n == 0: return
	var p3 := ship.global_position - global_position
	var p := Vector2(p3.x, p3.z)
	# Lot auf den Boden
	_ring.position = Vector3(p.x, Y, p.y)
	# Stelle auf der Acht: nächster Punkt in einem Fenster voraus (wie der Autopilot)
	var best := _idx
	var bd := INF
	for k in range(_idx - 20, _idx + 80):
		var dd: float = (_pts[posmod(k, n)] as Vector2).distance_squared_to(p)
		if dd < bd: bd = dd; best = posmod(k, n)
	if bd > 9.0:                                  # weit weg (z. B. nach Zurücksetzen): ganz suchen
		for k in n:
			var dd: float = (_pts[k] as Vector2).distance_squared_to(p)
			if dd < bd: bd = dd; best = k
	_idx = best
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := int(AHEAD_M / 0.1)
	for k in steps:
		_quad(im, _pts[(best + k) % n], _pts[(best + k + 1) % n], WIDTH * 1.6)
	im.surface_end()
	_ahead.mesh = im
