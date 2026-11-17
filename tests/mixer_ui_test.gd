# 2026-11-17 09:10 – Erstversion: Mischer-Fenster zeigt beim Wechsel des Modus die Tabelle dieses Modus (früher blieb die Tabelle des Flugmodus stehen)
extends SceneTree
# Ablauf: Hauptszene laden, Luftschiff mit 3 manuellen Modi, Modus 2 bekommt eine
# eigene Tabelle mit anderem Wert. Mischer öffnen (Modus 1), dann Modus 2 wählen
# → im Feld muss der Wert von Modus 2 stehen; zurück zu Modus 1 → Grundwert.

var main: Node
var f := 0
var ok := true
var key := ""


func _initialize() -> void:
	I18n.set_language("de", true)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


## Text des ersten Prozentfelds (Nick des ersten Ruders) im Mischer
func _first_cell_text() -> String:
	var b: BuilderPanel = main.builder
	for c in b._mix_body.get_children():
		if c is ScrollContainer:
			var grid: GridContainer = c.get_child(0)
			# Zeile 1: Überschriften (grid.columns), Zeile 2: Name, Grundstellung, „–“, Nick …
			return (grid.get_child(grid.columns + 3) as LineEdit).text
	return "?"


func _mode_buttons() -> Array:
	var b: BuilderPanel = main.builder
	var row: Node = b._mix_body.get_child(0)
	return row.get_children()


func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	var ship: AirshipPhysics = main.ship
	var fc: FlightController = main.fc
	match f:
		5:
			# drei manuelle Modi, Modus 2 mit eigener Tabelle (erstes Ruder Nick = 77 %)
			fc.set_mode_count(3)
			for m in fc.modes: m["art"] = "direkt"
			fc.mode_index = 0
			main.builder._show_mixer()            # legt ggf. die Grundtabelle aus der Einbaulage an
		6:
			var outs := FlightController.mix_outputs(ship)
			key = outs[0].key
			ship.mix_table[key] = [11.0, 0.0, 0.0]
			var t2: Dictionary = ship.mix_table.duplicate(true)
			t2[key] = [77.0, 0.0, 0.0]
			fc.modes[1]["mix"] = t2
			main.builder._refill_mixer()
		8:
			print("Modus 1 gewählt: Nick erstes Ruder = ", _first_cell_text())
			if _first_cell_text() != "11 %": ok = false; print("FEHLER Modus 1 zeigt nicht 11 %")
			_mode_buttons()[1].emit_signal("pressed")
		12:
			print("Modus 2 gewählt: Nick erstes Ruder = ", _first_cell_text())
			if _first_cell_text() != "77 %": ok = false; print("FEHLER Modus 2 zeigt nicht 77 % (Tabelle bleibt stehen)")
			_mode_buttons()[0].emit_signal("pressed")
		16:
			print("zurück Modus 1: Nick erstes Ruder = ", _first_cell_text())
			if _first_cell_text() != "11 %": ok = false; print("FEHLER zurück auf Modus 1 nicht 11 %")
			print("mixer_ui_test: " + ("OK" if ok else "FEHLER"))
			print("ENDE")
			if not ok: assert(false, "Mischer zeigt falsche Tabelle")
			quit(0 if ok else 1)
			return true
	return false
