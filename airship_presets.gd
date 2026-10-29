# 2026-10-29 01:53 – Reglerwerte für den Kaskadenregler (Chewie, Albacore) aus automatischer Suche
# 2026-10-28 07:53 – PID-Vorgaben neu ermittelt für den fahrtunabhängigen Mischer: Chewie P3 I0,1 D2, Leitwerk 100 %, Schwenk 25 %; Albacore P3 I0,1 D3
# 2026-10-28 00:15 – Albacore nach Bauplan: L/D 7,5, X-Flossen ca. 2,4 % von L·D je Flosse, Streckung 1,2, Pfeilung 0,8, Turm bei 36 % / 13,5 % L / 0,59 D; PID-Vorgaben Albacore (P3 I0,1 D3) und Chewie (P2 I0 D2)
# 2026-10-27 23:49 – Albacore mit Turm an der Unterseite (30 % Länge, 12 % L lang, 1/3 D hoch); Chewie ohne Turm
# 2026-10-27 23:28 – Albacore wieder Standard: X-Heck mit Ruderklappen wie das Original, Schriftzug USS ALBACORE, Heckmotor an der Hüllenunterseite; Chewie: Schriftzug aerarium e.V., Pendel 35°, starres Leitwerk
# 2026-10-27 16:07 – Chewie laut Nutzer: L/D 6, Hülle 86 g, Motoren seitlich unten bei 135°/225°, Massen (90 g Antrieb + Elektronik, Aufteilung angenommen); Massenwerte in beiden Presets
# 2026-10-27 15:09 – Presets nutzen TailConfig: Albacore = + mit Klappen, Chewie = λ in Pendelausführung (19 × 19 cm, Streckung 1, Pfeilung 0,8, 45°)
# 2026-10-27 14:36 – Chewie: λ-Leitwerk in Pendelausführung, je ca. 19 × 19 cm, Streckung 1 (Nutzerangabe); Motorschwenk max. 110°
# 2026-10-27 12:23 – Chewie-Antrieb auf 2 × GEPRC SpeedX2 1804 mit 4"-Propellern umgestellt (ca. 7 N Standschub je Motor, 27 000 U/min, Steigung 3" – Annahmen, s. u.)
# 2026-10-27 11:08 – Motorpaare mit pair_id, gegenläufige Propeller bei Chewie, Rückwärtsschub-Daten, Propellerdaten für den Klang; Auswahlliste enthält Modellsammlung und eigene Modelle; Presets setzen Name und Standard-Gestaltung
# 2026-10-27 10:42 – Auf parametrische Platzierung umgestellt (make_fin/make_motor mit Längsposition + Umfangswinkel); Chewie korrigiert: keine Canards, Bugmotoren mit Pigleg-Schwenkachse 45° (gemeinsam = Nick, gegensinnig = Gier); Preset-Liste für das Auswahlmenü
# 2026-10-27 10:23 – Albacore-Flossen von 0,08 auf 0,14 m² vergrößert (Validator + Flugtest: ruhigeres Einschwingen); vorher: Erstversion Presets Albacore/Chewie
# =============================================================================
# AirshipPresets.gd
# -----------------------------------------------------------------------------
# Fertige Baukasten-Konfigurationen. Alle Bauteile werden nur über
# Längsposition (0 = Nase, 1 = Heck) und Umfangswinkel (0° oben, 90° rechts,
# 180° unten, 270° links – von hinten gesehen) beschrieben. Die genaue Lage
# rechnet AirshipPhysics.rebuild_mass_properties() aus der Hülle aus, darum
# wachsen die Presets beim Skalieren (Volumen, L/D) automatisch mit.
# =============================================================================
class_name AirshipPresets
extends RefCounted

## Einträge für das Auswahlmenü: eingebaute Presets, danach die
## Modellsammlung des Admins und die eigenen gespeicherten Modelle.
## Jeder Eintrag: {name, build} – build(ship) baut das Modell auf.
static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{"name": "Albacore Standard", "build": albacore_default},
		{"name": "Chewie", "build": chewie},
	]
	for e in ModelLibrary.entries():
		out.append({"name": "%s (%s)" % [e.name, e.source],
			"build": _build_from_code.bind(e.code)})
	return out


## Baut ein Modell aus einem Modell-String (für Sammlung und eigene Modelle).
static func _build_from_code(ship: AirshipPhysics, code: String) -> void:
	var r := ModelCodec.decode(code)
	if r.ok:
		ModelCodec.apply(ship, r.name, r.data)


## Neue Flosse an Längsposition x und Umfangswinkel angle_deg.
static func make_fin(name: String, x: float, angle_deg: float, area: float,
		kind := ControlSurface.Kind.FLAP) -> ControlSurface:
	var s := ControlSurface.new()
	s.display_name = name
	s.kind = kind
	s.hull_x = x
	s.hull_angle_deg = angle_deg
	s.area_m2 = area
	return s


## Neue Motorgondel. tilt_deg = Pigleg-Neigung der Schwenkachse.
static func make_motor(name: String, x: float, angle_deg: float, thrust_n: float,
		max_swivel_deg := 60.0, tilt_deg := 0.0) -> VectorMotor:
	var m := VectorMotor.new()
	m.display_name = name
	m.hull_x = x
	m.hull_angle_deg = angle_deg
	m.max_thrust_n = thrust_n
	m.max_swivel_deg = max_swivel_deg
	m.swivel_tilt_deg = tilt_deg
	return m


# =============================================================================
# Standard: USS Albacore-Form, L/D 5, 0,25 m³, Kreuzleitwerk mit Ruderklappen,
# starrer Heckmotor.
# =============================================================================
static func albacore_default(ship: AirshipPhysics) -> void:
	# Schlankheit wie das Original (62,6 m / 8,3 m ≈ 7,5)
	var h := GertlerHull.new()
	h.length_to_diameter = 7.5
	h.volume_m3 = 0.25
	ship.set_hull(h)
	ship.model_name = "Albacore Standard"
	ship.livery = Livery.new()
	ship.livery.text = "USS ALBACORE"         # fester Schriftzug des Originals
	# Turm wie beim Original, aber an der Unterseite (Optik + Wirkung als feste Flosse)
	ship.sail_enabled = true
	# Maße aus dem Bauplan abgemessen (Genauigkeit ca. ±10 %)
	ship.sail_x = 0.36
	ship.sail_length_frac = 0.135
	ship.sail_height_frac = 0.59
	# Massen: Hülle 86 g, Elektronik 30 g; Akku + Ballast ergibt sich aus dem Auftrieb
	ship.hull_mass_kg = 0.086
	ship.electronics_mass_kg = 0.030
	ship.ballast_auto_x = true
	# X-Heck wie das Original (Phase III): 4 diagonale Flossen mit Ruderklappen
	# direkt VOR dem Heckpropeller. Maße aus dem Bauplan abgemessen:
	# Fläche je Flosse ≈ 2,4 % von L·D, Spannweite ≈ 0,47 D, Streckung ≈ 1,2,
	# Pfeilung (Endtiefe/Wurzeltiefe) 0,8, Hinterkante senkrecht.
	# Damit ist die Albacore aerodynamisch instabil → fliegt nur mit Regler.
	var t := TailConfig.new()
	t.layout = TailConfig.Layout.CROSS
	t.kind = ControlSurface.Kind.FLAP
	t.area_m2 = 0.024 * h.length_m * h.diameter_m
	t.aspect_ratio = 1.2
	t.taper = 0.8
	t.hull_x = 0.95
	# Reglerwerte (Kaskadenregler) aus automatischer Suche im Simulator
	# (Testprogramm, 100 % mit Nickböe, Steigen)
	ship.fc_gains = {
		"pitch": {"ang_p": 3.0, "rate_p": 3.0, "rate_i": 0.3, "rate_d": 0.0, "max_rate": 30.0},
		"roll": {"ang_p": 2.0, "rate_p": 2.0, "rate_i": 0.2, "rate_d": 0.05, "max_rate": 30.0, "damp_free": 0.2},
		"yaw": {"rate_p": 0.5, "rate_i": 0.2, "rate_d": 0.0, "max_rate": 40.0, "ff": 0.0},
		"mix": [1.0, 1.0], "swv_pitch": 30.0}
	ship.tail = t
	ship.surfaces.clear()                # Flossen erzeugt rebuild_mass_properties() aus ship.tail
	# Winkel 180° = Hüllenunterseite: wird der Motor im Baukasten nach vorn
	# verschoben, wandert er unten an der Hülle entlang (wichtig für den Schwerpunkt)
	var heck := make_motor("Heckmotor", 1.0, 180.0, 1.5, 0.0)
	heck.standoff_m = 0.0                # sitzt auf der Längsachse an der Heckspitze
	heck.pair_id = "heck"
	heck.prop_diameter_in = 7.0          # größerer, langsamer Propeller → tieferer Ton
	heck.max_rpm = 12000.0
	var mots: Array[VectorMotor] = [heck]
	ship.motors = mots
	ship.rebuild_mass_properties()


# =============================================================================
# Chewie: umgekehrtes Y-Leitwerk (1 oben, 2 unten bei ±45° zur Senkrechten,
# die auch Seite mitsteuern), KEINE Canards.
# 2 Bugmotoren seitlich unten (45° unter der Waagrechten), jede Gondel schwenkt um eine eigene Achse, die
# um die Längsachse 45° nach unten gedreht ist (Pigleg-Anordnung):
#   – beide Gondeln gleichsinnig geschwenkt → Schub kippt nach oben/unten → Nick
#   – gegensinnig geschwenkt → Seitenkräfte addieren sich → Gier
# ANNAHME (bitte am Modell nachmessen): Längsposition der Motoren 0,25.
# =============================================================================
static func chewie(ship: AirshipPhysics) -> void:
	# Hülle laut Nutzer: 0,25 m³, L/D 6, Octax mit Nähten 86 g
	var h := GertlerHull.new()
	h.length_to_diameter = 6.0
	h.volume_m3 = 0.25
	ship.set_hull(h)
	ship.model_name = "Chewie"
	ship.livery = Livery.new()
	ship.livery.text = "aerarium e.V."       # fester Schriftzug
	# Reglerwerte (Kaskadenregler) aus automatischer Suche im Simulator:
	# Testprogramm (50 % Schub, je 0,5 s links/rechts), 100 % mit Nickböe,
	# Steigen; geprüft auch an „falsch gebauten“ Varianten (Schub ±30 %,
	# Schwenkachse 40/50°, verdrehte Flosse, größere Flossen).
	ship.fc_gains = {
		"pitch": {"ang_p": 4.0, "rate_p": 2.0, "rate_i": 0.2, "rate_d": 0.05, "max_rate": 35.0},
		"roll": {"ang_p": 4.0, "rate_p": 1.0, "rate_i": 0.2, "rate_d": 0.05, "max_rate": 30.0, "damp_free": 0.3},
		"yaw": {"rate_p": 0.7, "rate_i": 0.1, "rate_d": 0.0, "max_rate": 40.0, "ff": 0.0},
		"mix": [1.0, 0.4], "swv_pitch": 80.0}
	ship.sail_enabled = false                # Chewie hat keinen Turm
	# Massen laut Nutzer: beide Motoren mit Schwenkservos + Teensy + RX + BEC = 90 g.
	# ANNAHME zur Aufteilung: je Motorgondel mit Servo 30 g, Elektronik 30 g.
	# Akku + Ballast klebt mit der Elektronik unten an der Hülle; die Menge
	# ergibt sich aus dem Auftrieb, die Längslage trimmt sich automatisch.
	ship.hull_mass_kg = 0.086
	ship.electronics_mass_kg = 0.030
	ship.ballast_auto_x = true
	# λ-Leitwerk (umgekehrtes Y) laut Nutzer: Pendelausführung, je ca. 19 × 19 cm
	# (0,036 m²), Streckung 1, Pfeilung (Zuspitzung) 0,8, untere Flossen 45°
	# unter der Waagrechten.
	var t := TailConfig.new()
	t.layout = TailConfig.Layout.LAMBDA
	t.v_angle_deg = 45.0
	t.kind = ControlSurface.Kind.ALL_MOVING
	t.area_m2 = 0.0361
	t.aspect_ratio = 1.0
	t.taper = 0.8
	t.max_deflection_deg = 35.0          # Pendel-Flossen: großer Ausschlag
	t.pseudo_flex = false                # superleichte, starre 3D-Flossen: keine Verformung
	ship.tail = t
	ship.surfaces.clear()                # Flossen erzeugt rebuild_mass_properties() aus ship.tail
	# Antrieb laut Nutzer: 2 × GEPRC SpeedX2 1804 mit 4"-Propellern.
	# ANNAHMEN (bitte bestätigen): 2450 KV an 4S → ca. 27 000 U/min unter Last,
	# ca. 7 N (≈ 700 g) Standschub je Motor, Steigung 3", 2 Blätter.
	var mots: Array[VectorMotor] = [
		# seitlich unten, 45° unter der Waagrechten (135° rechts, 225° links)
		make_motor("Bugmotor rechts", 0.25, 135.0, 7.0, 110.0, 45.0),
		make_motor("Bugmotor links", 0.25, 225.0, 7.0, 110.0, 45.0),
	]
	# Paar gemeinsam einstellbar; gegenläufige Propeller wie beim Quadcopter.
	# Rückwärtsschub erlaubt (ESC vor/zurück), normaler Propeller ≈ 55 % rückwärts.
	for i in mots.size():
		mots[i].pair_id = "bug"
		mots[i].spin_dir = 1 if i == 0 else -1
		mots[i].reverse_allowed = true
		mots[i].reverse_efficiency = 0.55
		mots[i].prop_diameter_in = 4.0
		mots[i].prop_pitch_in = 3.0
		mots[i].prop_blades = 2
		mots[i].max_rpm = 27000.0
		mots[i].spool_time_s = 0.08      # kleine Motoren drehen schnell hoch
		mots[i].mass_kg = 0.030          # Motor + Propeller + Schwenkservo (Annahme, s. o.)
	ship.motors = mots
	ship.rebuild_mass_properties()
