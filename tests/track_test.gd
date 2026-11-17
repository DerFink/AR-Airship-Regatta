# 2026-11-17 08:50 – Erstversion: Acht auf dem Boden bleibt beim Wechsel Halle → Wiese → Halle erhalten und passt sich dem Pylonabstand an
extends SceneTree
# Nachgestellt wie in main.gd: CourseTrack ist ein Kind der Strecke. Früher hat
# Course.rebuild() beim Ortswechsel alle Kinder gelöscht – auch die Spur.

var c: Course
var tr_node: CourseTrack
var ship: AirshipPhysics
var ok := true
var _n := 0


func _initialize() -> void:
	c = Course.new()
	root.add_child(c)
	ship = AirshipPhysics.new()
	root.add_child(ship)
	tr_node = CourseTrack.new()
	tr_node.course = c
	tr_node.ship = ship
	c.add_child(tr_node)


## Ablauf über mehrere Bilder, damit queue_free() wirklich ausgeführt wird.
func _process(_dt: float) -> bool:
	_n += 1
	match _n:
		3:
			_check("Halle", 0)
			c.set_location(1)                     # → Wiese
		6:
			_check("Wiese", 1)
			c.set_location(0)                     # → zurück in die Halle
		9:
			_check("Halle wieder", 0)
			print("track_test: " + ("OK" if ok else "FEHLER"))
			print("ENDE")
			quit(0 if ok else 1)
			return true
	return false


func _check(name: String, loc: int) -> void:
	var alive := is_instance_valid(tr_node) and tr_node.get_parent() == c
	var dist_ok := alive and absf(tr_node._dist - c.distance()) < 0.01 and tr_node._pts.size() > 0
	print("%s: Spur vorhanden %s, Abstand %.1f m (Spur %.1f m)" % [name, alive, c.distance(), tr_node._dist if alive else -1.0])
	if not (alive and dist_ok and c.location == loc):
		print("FEHLER: Acht fehlt oder passt nicht (%s)" % name)
		ok = false
		assert(false, "Acht verschwunden")
