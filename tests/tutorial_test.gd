# 2026-11-17 09:45 – Erstversion: Tutorial – Knopf auf der Startseite, 6 Karten mit passender Ansicht und markiertem Bereich, Überspringen führt zur Startseite; Bildschirmfotos mit --shots=<Ordner>
extends SceneTree

var main: Node
var f := 0
var ok := true
var shots := ""
var step := 0
const VIEW_OF := {"start": 6, "fly": 0}        # main.View.START = 6, FLY = 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots = a.substr(8)
	I18n.set_language("de", true)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _shot(name: String) -> void:
	if shots == "": return
	root.get_viewport().get_texture().get_image().save_png(shots + "/" + name + ".png")


func _fail(msg: String) -> void:
	print("FEHLER ", msg)
	ok = false


func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	var tut: Tutorial = main.tutorial
	if f == 10:
		if not main.start_screen._btn_tut.visible: _fail("Knopf Tutorial fehlt")
		if tut.visible: _fail("Tutorial ist von selbst offen")
		_shot("tut_0_start")
		main.start_screen._btn_tut.emit_signal("pressed")
	# je Karte 12 Bilder: prüfen, Bild, weiter
	if f >= 14 and step < Tutorial.STEPS.size():
		if (f - 14) % 12 == 8:
			var s: Dictionary = Tutorial.STEPS[step]
			print("Karte %d: %s | Ansicht %d | markiert %d" % [step + 1, tut._title.text, main.view, tut._rects.size()])
			if main.view != VIEW_OF[s.view]: _fail("Karte %d: falsche Ansicht %d" % [step + 1, main.view])
			if s.target == "eight":
				if not main.track.attention: _fail("Karte 4: Acht pulsiert nicht")
			elif s.target != "race_panel" and tut._rects.is_empty(): _fail("Karte %d: nichts markiert" % (step + 1))
			_shot("tut_%d" % (step + 1))
		if (f - 14) % 12 == 11:
			step += 1
			if step < Tutorial.STEPS.size():
				tut._b_next.emit_signal("pressed")
			else:
				tut._b_skip.emit_signal("pressed")      # letzte Karte: Schließen
	if step >= Tutorial.STEPS.size() and f > 14 + 12 * Tutorial.STEPS.size() + 4:
		if tut.visible: _fail("Tutorial nach Schließen noch sichtbar")
		if main.view != 6: _fail("nach dem Tutorial nicht auf der Startseite")
		if main.track.attention: _fail("Acht pulsiert nach dem Tutorial weiter")
		print("tutorial_test: " + ("OK" if ok else "FEHLER"))
		print("ENDE")
		if not ok: assert(false, "Tutorial fehlerhaft")
		quit(0 if ok else 1)
		return true
	return false
