# 2026-10-29 00:19 – Bestenliste in den Test aufgenommen
# 2026-10-28 08:51 – Acht um beide Pylone: Kontrollpunkte mit Seite und Richtung, falscher Durchgang zählt nicht, Rundenzeiten
extends SceneTree
# Prüft die Rennlogik mit einer vorgegebenen Bug-Bahn (x = Strecke, z = quer,
# z > 0 = Pilotenseite), ohne Physik. Jeder Bahnpunkt = 1 s.
func _initialize() -> void:
	var c := Course.new()
	root.add_child(c)
	c.set_course(0, 25.0)
	print("Strecke: %s, Abstand %.0f m, Feld %.0f × %.0f m" % [c.title(), c.distance(), c.distance() + 2 * Course.FIELD_MARGIN, Course.FIELD_WIDTH])
	c.reset_race()
	# Eine korrekte Acht: über P1 Pilotenseite → P2 außen → P2 zurück → P1 außen → Ziel
	var eight := [Vector2(1, 2), Vector2(9, 0), Vector2(19, -3), Vector2(21, 0), Vector2(17, 3), Vector2(9, 0), Vector2(-1, -3), Vector2(-3, 0), Vector2(-1, 2)]
	# Fehler: P2 auf der falschen Seite (Pilotenseite) passiert, dann korrekt nachgeholt
	var wrong := [Vector2(1, 2), Vector2(9, 0), Vector2(19, 3), Vector2(21, 0), Vector2(17, -3), Vector2(16, -3), Vector2(19, -3), Vector2(21, 0), Vector2(17, 3), Vector2(9, 0), Vector2(-1, -3), Vector2(-3, 0), Vector2(-1, 2)]
	var path: Array = [Vector2(-1, 2)]
	path.append_array(eight.slice(0, 8))              # Runde 1 (ohne Ziel-Punkt)
	path.append_array(wrong.slice(0, 12))             # Runde 2 mit Fehler
	path.append_array(eight)                          # Runde 3 + Ziel
	path.append_array(eight)                          # nach dem Ziel: nichts zählt mehr
	var seen := []
	for p in path:
		c.track(p.x, p.y, 1.0)
		seen.append("%s%s" % ["G" if c.far_green else "r", ["W", "L%d.%d" % [c.lap, c.next_gate], "Z"][c.race]])
	print(" ".join(seen))
	print("Ergebnis: ", c.race_text(), " | ", c.lap_text())
	print("Rundenzeiten: ", c.lap_times, " fertig=", c.race == Course.Race.DONE)
	# Bestenliste: Ergebnis eintragen, Platz prüfen, Liste lesen
	var key := "test_%d" % Time.get_ticks_usec()
	var p1 := Leaderboard.add(key, c.time_s, c.lap_times, "Testpilot", "Chewie")
	var p2 := Leaderboard.add(key, c.time_s - 5.0, c.lap_times, "Schneller", "Albacore")
	print("Bestenliste: Platz %d dann %d, Liste %s, Platz für 1:00,0 wäre %d" % [p1, p2,
		Leaderboard.entries(key).map(func(e): return "%s %s" % [e.name, Course.format_time(e.total)]), Leaderboard.rank_for(key, 60.0)])
	c.set_course(1, 30.0)
	print("Frei: ", c.title(), " Abstand ", c.distance())
	c.set_course(0, 30.0)
	print("ENDE")
	quit()
