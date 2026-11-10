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
		I18n.set_language("en", false)
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
		print("ENDE")
		return true
	return false
