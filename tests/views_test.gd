# 2026-11-13 03:30 – Modusknöpfe nach Index der eigenen Modi
# 2026-11-11 03:00 – wartet, bis main.gd fertig aufgebaut ist (Ladeanzeige)
# 2026-11-11 01:50 – Baukasten mit Boxmaß-Ecke (Bild), Nutzlast, Akku, ohne Teensy nur Direkt
# 2026-11-10 22:30 – Erstversion: neue Ansichten – Startseite, Modell & Bau, Grundlagen, Autopilot, Perspektiven, Sprachwechsel; speichert auf Wunsch Bildschirmfotos (Argument --shots=<Ordner>, braucht echte Grafik)
extends SceneTree
var main: Node
var f := 0
var shots := ""

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots = a.substr(8)
	I18n.set_language("de", true)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _shot(name: String) -> void:
	if shots == "": return
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(shots + "/" + name + ".png")

func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true                         # Szene abgebaut → Ende
	if not main.ready_done: return false     # Ladeanzeige: Aufbau läuft noch
	f += 1
	if f == 20:
		print("Startansicht: view=%d (6 = START), Start sichtbar=%s" % [main.view, main.start_screen.visible])
		print("Fliegen-Knopf: ", main.start_screen._btn_fly.text)
		_shot("start_de")
	if f == 24:
		main.start_screen.build_requested.emit()
	if f == 34:
		var h: ModelHub = main.hub
		print("Modell & Bau: view=%d, Locations=%d, Modelle+Eigenbau=%d, Detail=%s / %s" % [main.view, h._loc_list.get_child_count(), h._mod_list.get_child_count(), h._detail_name.text, h._detail_meta.text])
		print("Daten: ", h._detail_data.text)
		_shot("hub")
		h._select(0)
	if f == 38:
		print("Auswahl 0: ", main.hub._detail_name.text, " – ", main.hub._detail_data.text)
		main.hub._loc_list.get_child(1).emit_signal("pressed")
	if f == 42:
		print("Location jetzt %d, Abstand %.0f m" % [main.course.location, main.course.distance()])
		main.hub._dist_edit.text = "30"
		main.hub._apply_distance()
		print("Abstand nach Eingabe 30: %.0f m" % main.course.distance())
		main.course.set_location(0)
		main.course.set_distance(18.0)
		main.hub._on_fly()
	if f == 46:
		print("Nach „Fliegen“: view=%d (0 = FLY), Modell %s" % [main.view, main.ship.model_name])
		_shot("fly_pilot")
		main.hud.autopilot_requested.emit()
	if f == 200:
		print("Autopilot aktiv=%s, Rennen: %s, Höhe %.2f m, Fahrt %.1f m/s" % [main.autopilot.active, main.course.race_text(), main.ship.global_position.y, main.ship.linear_velocity.length()])
		main.hud._btn_persp.emit_signal("pressed")
	if f == 230:
		print("Perspektive %d: %s" % [main.hud.perspective, main.hud._btn_persp.text])
		_shot("fly_chase")
		main.hud._btn_persp.emit_signal("pressed")
	if f == 260:
		print("Perspektive %d: %s" % [main.hud.perspective, main.hud._btn_persp.text])
		_shot("fly_chase_attitude")
	if f == 1200:
		print("Autopilot nach 19 s: aktiv=%s, %s" % [main.autopilot.active, main.course.race_text()])
		main.hud.autopilot_requested.emit()          # stoppen
	if f == 1204:
		print("Gestoppt: aktiv=%s, hud=%s, Modus=%d" % [main.autopilot.active, main.hud.autopilot_active, int(main.fc.mode)])
		main.hud.hub_requested.emit()
	if f == 1208:
		print("Menü → view=%d (7 = HUB)" % main.view)
		main.hub.home_requested.emit()
	if f == 1212:
		main.start_screen.about_requested.emit()
	if f == 1216:
		var a: AboutPanel = main.about
		print("Grundlagen: view=%d, Text beginnt: %s" % [main.view, a._text.get_parsed_text().substr(0, 60)])
		_shot("about")
		a._show(4)
	if f == 1220:
		print("Über/Lizenz enthält Kontakt: ", main.about._text.get_parsed_text().contains("erich.fink ät aerarium.de"))
		main.about.closed.emit()
		main.start_screen.settings_requested.emit()
		I18n.set_language("en", false)
	if f == 1224:
		print("Einstellungen: view=%d (9 = SETTINGS)" % main.view)
		_shot("settings")
		main.settings.closed.emit()
	if f == 1226:
		main.start_screen._refresh()
	if f == 1230:
		print("EN: ", main.start_screen._btn_fly.text, " | ", tr("Einstellungen"))
		_shot("start_en")
		I18n.set_language("zh_TW", false)
		main.start_screen._refresh()
	if f == 1236:
		print("ZH: ", main.start_screen._btn_fly.text)
		_shot("start_zh")
		I18n.set_language("de", false)
		main.hub.edit_requested.emit()
	if f == 1260:
		var box: AABB = main.visual.local_aabb()
		print("Baukasten: view=%d, Boxmaß L %.2f B %.2f H %.2f m, Wände/Linien %d, h_offset %.2f" % [main.view, box.size.z, box.size.x, box.size.y, main.gauge.get_child_count(), main.camera.h_offset])
		print("Massen: gesamt %.0f g ohne Helium, Akku %.0f g, Ballast %.0f g, Teensy %s" % [main.ship.structure_mass_kg * 1000, main.ship.battery_mass_kg * 1000, main.ship.ballast_kg * 1000, main.ship.fc_teensy])
		_shot("builder")
		main.ship.payload_mass_kg = 0.02
		main.ship.payload_x = 0.2
		main.ship.payload_angle_deg = 180
		main.ship.livery.material = "gold"
		main.ship.rebuild_mass_properties()
	if f == 1280:
		print("Nutzlast 20 g: Ballast %.0f g, Schwerpunkt z %.3f m" % [main.ship.ballast_kg * 1000, main.ship.cg_offset.z])
		_shot("builder_payload")
		var tabs: TabContainer = main.builder._left.get_child(0)
		tabs.current_tab = 3
		main.builder._show_flow()
		var code := ModelCodec.encode(main.ship)
		var d := ModelCodec.decode(code)
		print("Codec: ok=%s, Nutzlast %.3f, Akku %dS %d mAh, Material %s" % [d.ok, d.data.mass.pl, d.data.mass.bs, d.data.mass.bmah, d.data.look.mat])
	if f == 1286:
		_shot("builder_flow")
		main.builder._flow_win.visible = false
		main.ship.fc_teensy = false
		main.fc.mode = FlightController.Mode.MODE3
		main.builder.closed.emit()
	if f == 1292:
		main.hub.closed.emit()
	if f == 1298:
		print("Ohne Teensy: Mode-3-Knopf gesperrt=%s, Direkt gedrückt=%s" % [main.hud._mode_btns[main.fc.modes.size() - 1].disabled, main.hud._mode_btns[0].button_pressed])
		AirshipPresets.chewie(main.ship)
		print("ENDE")
		return true
	return false
