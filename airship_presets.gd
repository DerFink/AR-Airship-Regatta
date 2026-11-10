# 2026-11-11 15:00 – meta(): Angaben auch für Modelle aus der Sammlung (Angabenzeile in models/sammlung.txt)
# 2026-11-10 23:35 – Elektronik ohne Teensy 20 g + Teensy 10 g (Summe wie bisher 30 g); Akku 4S 300 mAh, 38 g (ANNAHME, bitte nachwiegen); keine Nutzlast; Turm entfällt
# 2026-11-10 20:30 – META: Autor, Team und Kurzbeschreibung je Modell (für Modell & Bau)
# 2026-11-08 20:30 – Chewie: Gesamtmasse 260 g (≈ 1 % schwerer als der Auftrieb)
# 2026-11-08 19:30 – Chewie-/Albacore-Motoren: Hochlaufzeit 30 ms wie bei Quadcopter-Motoren (vorher 80 ms)
# 2026-11-08 16:20 – Albacore standardmäßig ohne Turm und mit Chewies Bugmotoren (gemeinsame Funktion chewie_motor_pair)
# 2026-11-08 14:30 – Chewie: Schwenkbereich der Motoren ±45° (Angabe Nutzer)
# 2026-11-07 23:55 – Chewie: Schwenkachse wieder +45° (Schub schwenkt entlang der Hülle, vom Nutzer bestätigt)
# 2026-11-07 23:00 – Chewie: Reglerwerte aus dem Teensy-Code (Werkseinstellung), untere Flossen 30° unter der Waagrechten (Einbauwinkel 60°/300° wie im Teensy-Mischer), Flossen ±50°; Albacore ohne eigene Reglerwerte
# 2026-11-07 21:40 – Chewie: Hülle 85 g, Flossen je 10 g, Restmasse unten; Schwenkachse −45° (Schub schwenkt radial, kaum Rollmoment), Schwenkbereich ±50°
# 2026-11-07 20:45 – Regler-Vorgaben für Direkt/Mode 2/Mode 3 (Gier-Anteile aus Chewies Teensy-Code, Roll-Feder-Dämpfer)
# 2026-10-29 03:23 – Gier-Vorgaben: Chewie Knüppelstärke 1,3 / Dämpfung 1,3, Albacore 1,0 / 1,0
# 2026-10-29 02:43 – Chewie: Renn-Abstimmung Gier (Rate P 2,5, max. 120 °/s, Motorschwenk Gier 40 %)
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
## Angaben zu den eingebauten Modellen für die Auswahl in „Modell & Bau“.
const META := {
	"Chewie": {"author": "Erich Fink", "team": "aerarium e.V.",
		"desc": "Rennluftschiff für die Halle: 0,25 m³ Helium, 260 g, drei Pendelflossen in λ-Anordnung und zwei entlang der Hülle schwenkbare Motoren. Wendet unter 2 m Radius."},
	"Albacore Standard": {"author": "Simulator-Team", "team": "RC Airship Regatta",
		"desc": "Standardhülle nach dem U-Boot USS Albacore (Gertler-Form), Kreuzleitwerk, Antrieb wie Chewie. Gutmütiges Lernmodell."},
}


## Angaben (Autor, Team, Beschreibung) zu einem Modellnamen; unbekannt → leer.
static func meta(name: String) -> Dictionary:
	if META.has(name):
		return META[name]
	# Sammlung/Eigene: Anzeigename „Name (Quelle)“ oder nur der Modellname
	for e in ModelLibrary.entries():
		if name == "%s (%s)" % [e.name, e.source] or name == e.name:
			return e.meta
	return {"author": "", "team": "", "desc": ""}


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
	ship.livery.material = "folie"            # Silberfolie
	ship.livery.fin_material = "weiss"
	# Turm wie beim Original, aber an der Unterseite (Optik + Wirkung als feste Flosse)
	ship.sail_enabled = false              # Turm standardmäßig aus (im Baukasten zuschaltbar)
	# Maße aus dem Bauplan abgemessen (Genauigkeit ca. ±10 %)
	ship.sail_x = 0.36
	ship.sail_length_frac = 0.135
	ship.sail_height_frac = 0.59
	# Massen: Hülle 86 g, Elektronik 30 g; Akku + Ballast ergibt sich aus dem Auftrieb
	ship.hull_mass_kg = 0.086
	ship.electronics_mass_kg = 0.020        # Empfänger, BEC, Kabel (Teensy extra, s. u.)
	ship.fc_teensy = true                    # Teensy-Flugcontroller: +10 g
	ship.battery_cells = 4
	ship.battery_mah = 300.0
	ship.battery_mass_kg = 0.038             # ANNAHME: typischer 4S-300-mAh-LiPo, bitte nachwiegen
	ship.payload_mass_kg = 0.0
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
	# Regler: Werte aus Chewies Teensy-Code (noch nicht auf die Albacore abgestimmt)
	ship.fc_gains = {}
	ship.tail = t
	ship.surfaces.clear()                # Flossen erzeugt rebuild_mass_properties() aus ship.tail
	# Antrieb wie bei Chewie (Wunsch Nutzer 08.11.2026): zwei schwenkbare Bugmotoren
	# seitlich unten statt des Heckmotors
	ship.motors = chewie_motor_pair()
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
	ship.livery.material = "folie"           # Silberfolie wie das echte Schiff
	ship.livery.fin_material = "weiss"       # weiße Flossen
	# Regler: Werte 1:1 aus Chewies Teensy-Code (Chewie_SBUS_dRehmFlight_Teensy_BETA_1_3,
	# Stand 04.11.2026) – das sind auch die Werkseinstellungen des FlightController.
	ship.fc_gains = {}
	ship.sail_enabled = false                # Chewie hat keinen Turm
	# Massen laut Nutzer (07.11.2026): Hülle 85 g, jede Leitwerksflosse ca. 10 g;
	# beide Motoren mit Schwenkservos + Teensy + RX + BEC = 90 g.
	# ANNAHME zur Aufteilung: je Motorgondel mit Servo 30 g, Elektronik 30 g.
	# Alle übrigen Massen (Elektronik, Akku, Ballast) kleben unten an der Hülle;
	# die Menge ergibt sich aus dem Auftrieb, die Längslage trimmt sich automatisch.
	ship.hull_mass_kg = 0.085
	ship.fin_mass_kg = 0.010
	# Gesamtmasse exakt 260 g, etwa 1 % schwerer als der Auftrieb (Angabe Nutzer 08.11.2026):
	# Auftrieb 0,25 m³ · (1,20 − 0,17) kg/m³ = 257,5 g ⇒ 2,5 g zu schwer = 0,0245 N
	ship.trim_heaviness_n = 0.0245
	ship.electronics_mass_kg = 0.020        # Empfänger, BEC, Kabel (Teensy extra, s. u.)
	ship.fc_teensy = true                    # Teensy-Flugcontroller: +10 g
	ship.battery_cells = 4
	ship.battery_mah = 300.0
	ship.battery_mass_kg = 0.038             # ANNAHME: typischer 4S-300-mAh-LiPo, bitte nachwiegen
	ship.payload_mass_kg = 0.0
	ship.ballast_auto_x = true
	# λ-Leitwerk (umgekehrtes Y) laut Nutzer: Pendelausführung, je ca. 19 × 19 cm
	# (0,036 m²), Streckung 1, Pfeilung (Zuspitzung) 0,8, untere Flossen 45°
	# unter der Waagrechten.
	var t := TailConfig.new()
	t.layout = TailConfig.Layout.LAMBDA
	# Untere Flossen 30° unter der Waagrechten: Einbauwinkel 60°/300° (von unten) wie im Teensy-Mischer
	t.v_angle_deg = 30.0
	t.kind = ControlSurface.Kind.ALL_MOVING
	t.area_m2 = 0.0361
	t.aspect_ratio = 1.0
	t.taper = 0.8
	t.max_deflection_deg = 50.0          # Pendel-Flossen ±50° (Angabe Nutzer)
	t.pseudo_flex = false                # superleichte, starre 3D-Flossen: keine Verformung
	ship.tail = t
	ship.surfaces.clear()                # Flossen erzeugt rebuild_mass_properties() aus ship.tail
	# Antrieb laut Nutzer: 2 × GEPRC SpeedX2 1804 mit 4"-Propellern.
	# ANNAHMEN (bitte bestätigen): 2450 KV an 4S → ca. 27 000 U/min unter Last,
	# ca. 7 N (≈ 700 g) Standschub je Motor, Steigung 3", 2 Blätter.
	var mots := chewie_motor_pair()
	ship.motors = mots
	ship.rebuild_mass_properties()


## Chewies Antrieb: zwei Bugmotoren seitlich unten (45° unter der Waagrechten) an
## Schwenkachsen, die radial durch den Motorfuß zeigen (Schub schwenkt entlang der
## Hülle), ±45° Schwenk, gegenläufige 4"-Propeller, Rückwärtsschub erlaubt.
## Wird auch für die Albacore verwendet.
static func chewie_motor_pair() -> Array[VectorMotor]:
	var mots: Array[VectorMotor] = [
		# seitlich unten, 45° unter der Waagrechten (135° rechts, 225° links).
		# Schwenkachse +45° (bestätigt 07.11.2026): die Achse zeigt radial durch den
		# Motorfuß, der Schub schwenkt ENTLANG der Hülle. Gegensinniges Schwenken
		# (Gier) erzeugt dabei auch ein Rollmoment – der Teensy-Regler gleicht es über
		# Flossen und Motorschwenker (MOTOR_ROLL_SIGN) aus. Schwenkbereich ±45° (Angabe Nutzer 08.11.2026).
		make_motor("Bugmotor rechts", 0.25, 135.0, 7.0, 45.0, 45.0),
		make_motor("Bugmotor links", 0.25, 225.0, 7.0, 45.0, 45.0),
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
		mots[i].spool_time_s = 0.03      # Quadcopter-Motor: ≈ 30 ms Zeitkonstante (vorher 80 ms)
		mots[i].mass_kg = 0.030          # Motor + Propeller + Schwenkservo (Annahme)
	return mots
