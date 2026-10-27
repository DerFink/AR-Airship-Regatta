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
	ship.set_hull(GertlerHull.new())     # Standardwerte = Albacore-Näherung
	ship.model_name = "Albacore Standard"
	ship.livery = Livery.new()
	var a := 0.14                        # je Flosse (0,08 war instabil, s. Kopf)
	var fins: Array[ControlSurface] = [
		make_fin("Seitenleitwerk oben", 0.90, 0.0, a),
		make_fin("Höhenleitwerk rechts", 0.90, 90.0, a),
		make_fin("Seitenleitwerk unten", 0.90, 180.0, a),
		make_fin("Höhenleitwerk links", 0.90, 270.0, a),
	]
	ship.surfaces = fins
	var heck := make_motor("Heckmotor", 1.0, 0.0, 1.5, 0.0)
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
# 2 Bugmotoren links/rechts, jede Gondel schwenkt um eine eigene Achse, die
# um die Längsachse 45° nach unten gedreht ist (Pigleg-Anordnung):
#   – beide Gondeln gleichsinnig geschwenkt → Schub kippt nach oben/unten → Nick
#   – gegensinnig geschwenkt → Seitenkräfte addieren sich → Gier
# ANNAHME (bitte am Modell nachmessen): Längsposition 0,25, Flossen 0,09 m².
# =============================================================================
static func chewie(ship: AirshipPhysics) -> void:
	ship.set_hull(GertlerHull.new())
	ship.model_name = "Chewie"
	ship.livery = Livery.new()
	var fins: Array[ControlSurface] = [
		make_fin("Seitenleitwerk oben", 0.90, 0.0, 0.09),
		make_fin("Leitwerk unten rechts", 0.90, 135.0, 0.09),
		make_fin("Leitwerk unten links", 0.90, 225.0, 0.09),
	]
	for s in fins:
		s.pseudo_flex = true             # Depron mit Klebeband-Scharnier
	ship.surfaces = fins
	var mots: Array[VectorMotor] = [
		make_motor("Bugmotor rechts", 0.25, 90.0, 1.2, 60.0, 45.0),
		make_motor("Bugmotor links", 0.25, 270.0, 1.2, 60.0, 45.0),
	]
	# Paar gemeinsam einstellbar; gegenläufige Propeller wie beim Quadcopter.
	# Rückwärtsschub erlaubt (ESC vor/zurück), normaler Propeller ≈ 55 % rückwärts.
	for i in mots.size():
		mots[i].pair_id = "bug"
		mots[i].spin_dir = 1 if i == 0 else -1
		mots[i].reverse_allowed = true
		mots[i].reverse_efficiency = 0.55
	ship.motors = mots
	ship.rebuild_mass_properties()
