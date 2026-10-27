extends SceneTree
# Leitwerk-Konfiguration: Anordnungen, Flossenwinkel, getrennte Flächen,
# Chewie-λ, Rundreise im Modell-String, Baukasten-Bedienung (Anordnung wechseln,
# Gesten-Zoom).
var main: Node
var f := 0
func _initialize() -> void:
	var t := TailConfig.new()
	for lay in TailConfig.Layout.values():
		t.layout = lay
		t.count = 5
		print("%-8s Flossen=%d Winkel=%s" % [TailConfig.LAYOUT_NAMES[lay], t.fin_count(), t.angles()])
	t.layout = TailConfig.Layout.PLUS; t.split_hv = true; t.area_h_m2 = 0.1; t.area_v_m2 = 0.05
	var fins := t.generate()
	print("getrennt: ", fins.map(func(s): return "%s=%.2f" % [s.display_name, s.area_m2]))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		AirshipPresets.chewie(main.ship)
		var s0: ControlSurface = main.ship.surfaces[0]
		print("Chewie: %d Flossen, %s, Fläche %.0f cm², Streckung %.1f, Pfeilung %.1f, Winkel %s" % [
			main.ship.surfaces.size(), "Pendel" if s0.kind == ControlSurface.Kind.ALL_MOVING else "Klappe",
			s0.area_m2 * 1e4, s0.aspect_ratio, s0.taper, main.ship.surfaces.map(func(s): return s.hull_angle_deg)])
		var code := ModelCodec.encode(main.ship)
		var r := ModelCodec.decode(code)
		var other := AirshipPhysics.new()
		ModelCodec.apply(other, r.name, r.data)
		print("Rundreise mit Leitwerk identisch: ", ModelCodec.encode(other) == code, "  Flossen nach Import: ", other.surfaces.size())
		other.free()
		main._set_view(main.View.BUILD)
	if f == 8:
		main.ship.tail.layout = TailConfig.Layout.EVEN
		main.ship.tail.count = 6
		main.builder._tail_changed(true)
		main.builder._add_canard()
		print("Nach Umstellung auf 6 gleichm. + Canard: Flächen=%d, Canards in Liste=%d" % [main.ship.surfaces.size(), main.builder._canard_list.item_count])
		var e := InputEventMagnifyGesture.new(); e.factor = 2.0
		main._unhandled_input(e)
		var d := InputEventScreenTouch.new(); d.index = 0; d.pressed = true; d.position = Vector2(800, 300)
		main._unhandled_input(d)
		var g := InputEventScreenDrag.new(); g.index = 0; g.position = Vector2(900, 300); g.relative = Vector2(100, 0)
		main._unhandled_input(g)
		print("Zoom=%.2f Drehung=%.2f rad" % [main._orbit_zoom, main._orbit_yaw])
	if f == 40:
		var vs: Vector2 = root.get_visible_rect().size
		var b = main.builder
		var ok := true
		for c in [b._left, b._right, b._banner, b._preview, b._view_btn]:
			ok = ok and Rect2(Vector2.ZERO, vs).encloses(Rect2(c.position, c.size))
		print("Baukasten-Elemente im Bild: ", ok, "  Banner ", b._banner.position, b._banner.size)
		print("ENDE")
		return true
	return false
