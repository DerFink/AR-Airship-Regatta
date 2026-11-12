# 2026-11-12 10:05 – Grenze 20 km/h: 16 km/h prallt ab, 25 km/h Anlauf platzt
# 2026-11-11 14:50 – Erstversion: Aufprall und Platzen (langsam = abprallen, schnell = Hülle platzt hinten und fällt), Drehrichtung der Flossen in der Darstellung
extends SceneTree
var main: Node
var f := 0
var hz := 0.0
var ok := true
var phase := 0
var t0 := 0
var bumps := 0
var bursts := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _fail(msg: String) -> void:
	print("FEHLER ", msg); ok = false

## Schiff 4 m vor die hintere Wand setzen, Nase zur Wand
func _launch(s: AirshipPhysics) -> void:
	s.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 6, -hz + 4.0)))
	t0 = f

func _physics_process(_dt: float) -> bool:   # zählt Physikschritte (CI läuft ohne feste Bildrate)
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	var s: AirshipPhysics = main.ship
	match phase:
		0:
			hz = Course.FIELD_WIDTH * 0.5 + Course.HALL_GAP
			s.bumped.connect(func(_k): bumps += 1)
			s.burst_changed.connect(func(on): if on: bursts += 1)
			s.burst_enabled = true
			# Flossen-Darstellung: positiver Ausschlag hebt die Vorderkante zur Normalen
			var fin_ok := 0
			for sf in s.surfaces:
				sf._flex_deg = 20.0
				sf._servo_deg = 20.0
				sf.command = 20.0 / sf.max_deflection_deg
			main.visual._process(0.016)
			for p in main.visual._fin_nodes:
				var sf: ControlSurface = p.get_meta("surface")
				var lead: Vector3 = p.basis * Vector3(0, 0, -1)          # Vorderkante (Nase = -Z)
				if lead.dot(sf.normal) > 0.1: fin_ok += 1
				# Physik: Kraft bei Vorwärtsfahrt zeigt dann zur Normalen
				var fz := sf.compute_force(Vector3(0, 0, -5), 1.2, 0.016)
				if fz.dot(sf.normal) <= 0.0: _fail("Flossenkraft gegen die Normale")
			if fin_ok != main.visual._fin_nodes.size(): _fail("Flossen drehen falsch herum (%d von %d richtig)" % [fin_ok, main.visual._fin_nodes.size()])
			for sf in s.surfaces:
				sf._flex_deg = 0.0; sf._servo_deg = 0.0; sf.command = 0.0
			_launch(s); phase = 1
		1:
			if f == t0 + 3: s.linear_velocity = Vector3(0, 0, -4.5)        # 16 km/h: prallt nur ab
			if f == t0 + 150:
				if bumps < 1: _fail("kein Stoß erkannt")
				if s.burst: _fail("bei 4,5 m/s (16 km/h) geplatzt")
				if s.linear_velocity.z <= 0.3: _fail("nicht abgeprallt (vz %.2f)" % s.linear_velocity.z)
				_launch(s); phase = 2
		2:
			if f == t0 + 3: s.linear_velocity = Vector3(0, 0, -7.0)        # 25 km/h (am Aufprall ≈ 23 km/h): zu schnell
			if f == t0 + 420:
				if bursts != 1: _fail("bei 7 m/s Anlauf (≈ 23 km/h am Aufprall) nicht geplatzt")
				if s.deflate_front > 0.0: _fail("Gas nicht ganz entwichen")
				if s.global_position.y > 0.8: _fail("Wrack liegt nicht am Boden (y %.2f)" % s.global_position.y)
				main._set_view(main.View.BUILD)               # Baukasten: Hülle muss wieder heil sein
				if s.burst: _fail("Baukasten zeigt geplatzte Hülle")
				main._set_view(main.View.FLY)
				main.reset_ship(); phase = 3; t0 = f
		3:
			if f == t0 + 10:
				if s.burst: _fail("Zurücksetzen repariert die Hülle nicht")
				print("crash_test: ", "OK" if ok else "FEHLER")
				if not ok: push_error("SCRIPT ERROR: crash_test")
				print("ENDE")
				return true
	return false
