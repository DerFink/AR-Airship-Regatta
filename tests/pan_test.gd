# 2026-11-17 18:10 – Erstversion: Baukasten – Verschieben mit gedrücktem Scrollrad bewegt das Modell mit der Maus, Umschalt + linke Maustaste ebenso, Grenze greift, „Ansicht zurücksetzen“ stellt zurück; Bildschirmfotos mit --shots=<Ordner>
extends SceneTree

var main: Node
var f := 0
var ok := true
var shots := ""
var p0 := Vector2.ZERO           ## Bildpunkt des Schiffs vor dem Verschieben


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots = a.substr(8)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _fail(msg: String) -> void:
	print("FEHLER ", msg)
	ok = false


## Wo erscheint die Schiffsmitte auf dem Bildschirm?
func _ship_px() -> Vector2:
	return main.camera.unproject_position(main.ship.global_position)


## Mausbewegung mit gedrückten Tasten wie vom Betriebssystem
func _drag(rel: Vector2, mask: int, shift := false) -> void:
	var e := InputEventMouseMotion.new()
	e.relative = rel
	e.button_mask = mask
	e.shift_pressed = shift
	main._unhandled_input(e)


func _shot(n: String) -> void:
	if shots != "":
		root.get_viewport().get_texture().get_image().save_png(shots + "/" + n + ".png")


func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	match f:
		3:
			main._set_view(main.View.BUILD)
		40:
			p0 = _ship_px()
			_shot("pan_0")
			_drag(Vector2(120, 60), MOUSE_BUTTON_MASK_MIDDLE)     # Scrollrad gedrückt: rechts unten
		80:
			var d := _ship_px() - p0
			print("Scrollrad: Schiff bewegt um ", d)
			if d.x < 80 or d.y < 30: _fail("Modell folgt der Maus nicht (Scrollrad)")
			_shot("pan_1")
			var yaw: float = main._orbit_yaw
			_drag(Vector2(-120, -60), MOUSE_BUTTON_MASK_LEFT, true)   # Umschalt + links: zurück
			if main._orbit_yaw != yaw: _fail("Umschalt + linke Maustaste dreht statt zu verschieben")
		120:
			var d := _ship_px() - p0
			print("Umschalt+links zurück: Abstand ", d)
			if d.length() > 15: _fail("Umschalt + linke Maustaste verschiebt nicht zurück")
			_drag(Vector2(100000, 0), MOUSE_BUTTON_MASK_MIDDLE)       # sehr weit → Grenze
		160:
			var vp: Vector2 = root.get_viewport().get_visible_rect().size
			var px := _ship_px()
			print("an der Grenze: Schiff bei ", px, " Bild ", vp)
			if px.x > vp.x: _fail("Schiff ganz aus dem Bild geschoben")
			main.reset_view()
		200:
			var d := _ship_px() - p0
			print("nach Zurücksetzen: Abstand ", d)
			if d.length() > 15: _fail("Ansicht zurücksetzen stellt Verschieben nicht zurück")
			print("pan_test: " + ("OK" if ok else "FEHLER"))
			print("ENDE")
			if not ok: assert(false, "Verschieben im Baukasten fehlerhaft")
			quit(0 if ok else 1)
			return true
	return false
