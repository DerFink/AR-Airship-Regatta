# 2026-10-28 08:14 – Erstversion: Strecke (Abstand, Feld), Farbwechsel hinterer Pylon, 3 Runden mit fliegendem Start
extends SceneTree
# Prüft die Rennlogik mit einer vorgegebenen Bug-Bahn (ohne Physik):
# Start hinter Pylon 1 → Linie Pylon 1 (Zeit startet) → Linie Pylon 2 (grün)
# → zurück über Pylon 1 (rot, nächste Runde) … nach 3 Runden Ziel.
func _initialize() -> void:
	var c := Course.new()
	root.add_child(c)
	c.set_course(0, 25.0)
	print("Strecke: %s, Abstand %.0f m, Feld %.0f × %.0f m" % [c.title(), c.distance(), c.distance() + 2 * Course.FIELD_MARGIN, Course.FIELD_WIDTH])
	c.reset_race()
	var path := [-1.0, -0.5]
	for r in 3:
		path.append_array([0.5, 9.0, 17.5, 18.5, 12.0, 3.0, -0.4, -1.0])   # hin und zurück
	path.append_array([0.5, 18.5, -0.5])                                  # nach dem Ziel: kein Zählen mehr
	var log := []
	for x in path:
		c.track(x, 1.0)
		log.append("%.1f:%s%s" % [x, "G" if c.far_green else "r", ["W", "L%d" % c.lap, "Z"][c.race] if c.race != Course.Race.RUN else "L%d" % c.lap])
	print(" ".join(log))
	print("Ergebnis: ", c.race_text(), " | Runden=", c.lap, " fertig=", c.race == Course.Race.DONE)
	c.set_course(1, 30.0)
	print("Frei: ", c.title(), " Abstand ", c.distance())
	c.set_course(0, 30.0)
	print("ENDE")
	quit()
