# 2026-10-29 01:13 – Test-Nickanschlag entfernt (ersetzt durch Nick-Schutz im Flugcontroller)
# 2026-10-28 08:51 – Testhilfe Nickanschlag (pitch_limit_*): Nase bleibt innerhalb ±Grenze
# 2026-10-28 00:15 – Signal model_applied und fc_gains (PID-Vorgaben je Modell)
# 2026-10-27 23:49 – Turm an der Hüllenunterseite als feste Flosse (sail_*), wird wie das Leitwerk bei jedem Neuaufbau erzeugt
# 2026-10-27 16:07 – Massenmodell aus Teilmassen: Hülle (verteilt), Motoren am Einbauort, Elektronik + Akku + Ballast als Masse unten an der Hülle (Menge aus Auftrieb, Lage automatisch getrimmt); Schwerpunkt und Trägheit daraus berechnet; Bauteile werden vor der Massenbilanz platziert
# 2026-10-27 15:09 – Leitwerk als TailConfig: Flossen werden bei rebuild_mass_properties() daraus erzeugt, Canards bleiben erhalten
# 2026-10-27 12:55 – reset_to(): Schiff im Physikschritt an den Startpunkt versetzen, Geschwindigkeiten/Motoren/Ruder nullen
# 2026-10-27 12:23 – Motoren bekommen ihre Anströmung (Schubabfall mit der Fahrt); Anstellwinkel erst ab 1 m/s angezeigt (vorher z. B. 105° beim Absinken im Stand)
# 2026-10-27 11:08 – Modellname und Gestaltung (livery) als Teil der Konfiguration
# 2026-10-27 10:42 – rebuild_mass_properties() platziert alle Bauteile parametrisch neu (place_on_hull) und meldet Änderungen per Signal config_changed (für Darstellung/Baukasten)
# 2026-10-27 10:35 – Erstversion: 6-DOF-Integrator mit virtuellen Massen (Kirchhoff), Munk-Moment, Querstrom-Rumpfkräfte, Leitwerke/Canards, Vektormotoren, Telemetrie, vereinfachter Modus
# =============================================================================
# AirshipPhysics.gd  (an den RigidBody3D des Luftschiffs hängen)
# -----------------------------------------------------------------------------
# Eigener 6-DOF-Physikschritt für ein Prallluftschiff (starre Hülle).
#
# Warum ein eigener Integrator?
#   Godots RigidBody3D kennt nur EINE Masse für alle Richtungen. Ein
#   Luftschiff schiebt beim Beschleunigen aber quer viel mehr Luft mit als
#   längs (virtuelle Massen, ATTAS-Ansatz). Deshalb ist custom_integrator
#   aktiv: Godot übernimmt nur noch Kollisionen, Bewegung rechnen wir selbst.
#
# Bewegungsgleichungen im Körpersystem (Kirchhoff-Form):
#   (m + Ma)·a  = F_ext + Ma·(ω × v) − ω × (Ma·v)
#   (I + Ia)·ω̇  = T_ext − ω × ((I + Ia)·ω) − v × (Ma·v)
#                                            └──── Munk-Moment ────┘
# Das Munk-Moment entsteht also direkt aus den ungleichen virtuellen Massen
# längs (k1) und quer (k2) – genau der destabilisierende Rumpfanteil.
#
# Körpersystem: Ursprung = Auftriebszentrum, -Z = Nase, +Y = oben, +X = rechts.
# =============================================================================
class_name AirshipPhysics
extends RigidBody3D

## Telemetrie für HUD und Flugcontroller (einmal pro Physikschritt).
signal telemetry_updated(data: Dictionary)
## Hülle oder Bauteile wurden geändert → Darstellung und Validator neu aufbauen.
signal config_changed
## Ein Modell wurde ausgewählt (Preset/Sammlung) → z. B. PID-Standardwerte übernehmen.
signal model_applied

# --- Konfiguration aus dem Baukasten -----------------------------------------
@export var hull: GertlerHull
@export var surfaces: Array[ControlSurface] = []
@export var motors: Array[VectorMotor] = []
## Name des Modells (erscheint im Modell-String und in der Auswahl).
@export var model_name := "Albacore Standard"
## Gestaltung der Hülle (Farbe, Schriftzug, Logo) – rein optisch.
@export var livery: Livery = Livery.new()
## Symmetrisches Leitwerk. Seine Flossen werden bei jedem Neuaufbau aus dieser
## Beschreibung erzeugt; null = nur freie Flächen (z. B. alte Modell-Strings).
@export var tail: TailConfig

@export_group("Massen")
## Hülle mit Nähten (ohne Traggas), in kg. Verteilt über die Hüllenfläche.
@export_range(0.0, 10000.0, 0.001, "or_greater") var hull_mass_kg: float = 0.086
## Elektronik ohne Akku (Flugcontroller, Empfänger, BEC), in kg.
## Sitzt zusammen mit Akku und Ballast unten an der Hülle.
@export_range(0.0, 10000.0, 0.001, "or_greater") var electronics_mass_kg: float = 0.030
## Längsposition der unten angeklebten Restmasse (0 = Nase, 1 = Heck).
@export_range(0.0, 1.0, 0.01) var ballast_x: float = 0.45
## true = Restmasse wird so verschoben, dass der Schwerpunkt genau unter dem
## Auftriebszentrum liegt (Schiff hängt waagrecht).
@export var ballast_auto_x: bool = true
## Gesamte Strukturmasse ohne Traggas (Summe aller Teile), kg. Bei auto_trim
## wird sie aus dem Auftrieb bestimmt, sonst gilt der eingetragene Wert.
@export_range(0.0, 10000.0, 0.001, "or_greater") var structure_mass_kg: float = 0.25
## Gesamtschwerpunkt relativ zum Auftriebszentrum – wird in
## rebuild_mass_properties() aus allen Teilmassen berechnet.
@export var cg_offset: Vector3 = Vector3(0, -0.12, 0)
## Bei true wird die Restmasse (Akku + Ballast) so gesetzt, dass das Schiff
## um trim_heaviness_n schwerer als Luft ist (schwebt fast neutral).
@export var auto_trim: bool = true
@export var trim_heaviness_n: float = 0.05

## PID-Standardwerte dieses Modells für die geregelten Modi:
## {"pitch": [kp, ki, kd], "roll": [...], "yaw": [...]}; leer = keine Vorgabe.
@export var fc_gains: Dictionary = {}

@export_group("Turm")
## Fester Turm an der Hüllenunterseite (wie der U-Boot-Turm, nur kopfüber).
## Wirkt aerodynamisch wie eine feste Flosse ohne Ruder.
@export var sail_enabled: bool = false
## Mitte des Turms als Längsposition (0 = Nase, 1 = Heck).
@export_range(0.05, 0.95, 0.01) var sail_x: float = 0.30
## Turmlänge als Anteil der Rumpflänge.
@export_range(0.02, 0.4, 0.005) var sail_length_frac: float = 0.12
## Turmhöhe als Anteil des Rumpfdurchmessers.
@export_range(0.05, 1.0, 0.01) var sail_height_frac: float = 0.33

@export_group("Atmosphäre")
@export var air_density: float = 1.20       ## kg/m³ (Meereshöhe, 20 °C)
@export var gas_density: float = 0.17       ## Helium ≈ 0,17 kg/m³
@export var wind: Vector3 = Vector3.ZERO    ## Weltkoordinaten, m/s
@export var gravity_mps2: float = 9.81

@export_group("Rumpf-Aerodynamik")
## Längs-Widerstandsbeiwert bezogen auf V^(2/3).
@export_range(0.0, 0.2, 0.001) var hull_cd_axial: float = 0.035
## Querstrom-Widerstand des Kreiszylinders (Allen-Perkins).
@export_range(0.0, 2.0, 0.01) var hull_cd_crossflow: float = 1.0
## Schlankheits-Korrektur η für den Querstrom (0,5–0,7 für L/D 4–8).
@export_range(0.1, 1.0, 0.01) var crossflow_eta: float = 0.6
## Anzahl Rumpfscheiben für die Querstrom-Integration (Watchdog reduziert).
@export_range(2, 64, 1) var crossflow_slices: int = 16
## Kleine Zusatzdämpfung um die Längsachse (Rollen), N·m·s.
@export var roll_damping: float = 0.02

# --- Abgeleitete Größen -------------------------------------------------------
var total_mass: float = 0.0
## Akku + Ballast (aus dem Auftrieb berechnet), kg
var rest_mass_kg: float = 0.0
## Elektronik + Akku + Ballast als eine Masse unten an der Hülle, kg
var bottom_mass_kg: float = 0.0
## Ort dieser Masse im Körpersystem (direkt am Hüllenboden)
var bottom_mass_pos: Vector3 = Vector3.ZERO
## true = Hülle, Motoren und Elektronik wiegen schon mehr als der Auftrieb trägt
var overweight: bool = false
var added_mass: Vector3 = Vector3.ZERO      ## Ma (diagonal, Körperachsen)
var inertia_rb: Vector3 = Vector3.ZERO      ## I  (diagonal)
var added_inertia: Vector3 = Vector3.ZERO   ## Ia (diagonal)
var simplified: bool = false                ## vom Watchdog gesetzt
var _full_slices: int = 16

# --- Telemetrie (öffentlich lesbar) ------------------------------------------
var airspeed: float = 0.0
var alpha_deg: float = 0.0       ## Anstellwinkel (Nick)
var beta_deg: float = 0.0        ## Schiebewinkel (Gier)
var munk_moment: Vector3 = Vector3.ZERO
var surface_moment: Vector3 = Vector3.ZERO
var hull_viscous_moment: Vector3 = Vector3.ZERO
var vector_moment: Vector3 = Vector3.ZERO
var _reset_to = null                 ## Transform3D, wenn ein Zurücksetzen ansteht


func _ready() -> void:
	custom_integrator = true        # Godot rechnet nur noch Kollisionen
	can_sleep = false
	if hull == null:
		hull = GertlerHull.new()
	set_hull(hull)
	_full_slices = crossflow_slices
	rebuild_mass_properties()


## Neue Hülle setzen (Baukasten / Preset) und Änderungen abonnieren.
func set_hull(h: GertlerHull) -> void:
	if hull and hull != h and hull.shape_changed.is_connected(rebuild_mass_properties):
		hull.shape_changed.disconnect(rebuild_mass_properties)
	hull = h
	if not hull.shape_changed.is_connected(rebuild_mass_properties):
		hull.shape_changed.connect(rebuild_mass_properties)


# =============================================================================
# Massen, Trägheiten und virtuelle Massen aus der Hüllengeometrie
# =============================================================================
func rebuild_mass_properties() -> void:
	# --- 1) Leitwerk erzeugen und alle Bauteile an die Hülle setzen ---------
	# (zuerst, weil die Motormassen ihren Einbauort brauchen)
	# Erzeugte Teile (Leitwerk, Turm) neu anlegen, freie Flächen (Canards) behalten
	var free: Array[ControlSurface] = []
	for s in surfaces:
		if s.sail_member or (tail and s.tail_member):
			continue
		free.append(s)
	var gen: Array[ControlSurface] = []
	if tail:
		gen = tail.generate()
	if sail_enabled:
		gen.append(_make_sail())
	gen.append_array(free)
	surfaces = gen
	for s in surfaces:
		s.place_on_hull(hull)
	for mot in motors:
		mot.place_on_hull(hull)

	# --- 2) Massenbilanz ------------------------------------------------------
	#   Traggas      im Auftriebszentrum (Ursprung)
	#   Hülle        verteilt, Schwerpunkt ≈ Auftriebszentrum
	#   Motoren      je an ihrem Einbauort (mit Schwenkservo)
	#   Unten        Elektronik + Akku + Ballast, direkt am Hüllenboden
	var V := hull.volume_m3
	var a := hull.length_m * 0.5           # Halbachse längs
	var b := hull.diameter_m * 0.5         # Halbachse quer
	var gas_mass := gas_density * V
	var motor_mass := 0.0
	for mot in motors:
		motor_mass += mot.mass_kg
	var fixed := hull_mass_kg + motor_mass + electronics_mass_kg
	if auto_trim:
		# Auftrieb = ρ_Luft·V·g ; Gewicht = (Struktur + Gas)·g + gewünschte Schwere
		var needed := air_density * V - gas_mass + trim_heaviness_n / gravity_mps2
		rest_mass_kg = maxf(0.0, needed - fixed)
		overweight = fixed > needed
	else:
		rest_mass_kg = maxf(0.0, structure_mass_kg - fixed)
		overweight = false
	structure_mass_kg = fixed + rest_mass_kg
	bottom_mass_kg = electronics_mass_kg + rest_mass_kg
	total_mass = structure_mass_kg + gas_mass
	mass = maxf(total_mass, 0.001)         # für Godots Kollisionsantwort

	# Längsmoment der Motoren (Körper-Z, + = hinten) – für das Austrimmen
	var mz_motors := 0.0
	for mot in motors:
		mz_motors += mot.mass_kg * mot.position.z
	if ballast_auto_x and bottom_mass_kg > 1e-6:
		# Unten-Masse so legen, dass der Gesamtschwerpunkt unter dem Auftriebszentrum liegt
		var z_needed := -mz_motors / bottom_mass_kg
		ballast_x = clampf((z_needed + hull.cb_from_nose) / hull.length_m, 0.05, 0.95)
	var zb := ballast_x * hull.length_m - hull.cb_from_nose
	bottom_mass_pos = Vector3(0, -hull.radius_at(ballast_x), zb)   # klebt am Hüllenboden

	# Gesamtschwerpunkt (Gas und Hülle sitzen im Ursprung)
	var moment := bottom_mass_pos * bottom_mass_kg
	for mot in motors:
		moment += mot.position * mot.mass_kg
	cg_offset = moment / maxf(total_mass, 1e-6)

	# --- 3) Trägheitsmomente um das Auftriebszentrum (Diagonale) -----------
	# X = Nickachse, Y = Gierachse, Z = Rollachse (Längsachse)
	# Traggas als Vollellipsoid, Hülle als dünne Schale (Näherung),
	# Motoren und Unten-Masse als Punktmassen (Steiner).
	var i_lat := gas_mass * (a * a + b * b) / 5.0 + hull_mass_kg * (a * a / 3.0 + b * b / 2.0)
	var i_ax := gas_mass * 2.0 * b * b / 5.0 + hull_mass_kg * 2.0 * b * b / 3.0
	var I := Vector3(i_lat, i_lat, i_ax)
	var pts: Array = [[bottom_mass_kg, bottom_mass_pos]]
	for mot in motors:
		pts.append([mot.mass_kg, mot.position])
	for p in pts:
		var m: float = p[0]
		var r: Vector3 = p[1]
		I += m * Vector3(r.y * r.y + r.z * r.z, r.x * r.x + r.z * r.z, r.x * r.x + r.y * r.y)
	inertia_rb = I

	# --- 4) Virtuelle Massen (ATTAS): Längs k1, quer k2, Drehung k' ---------
	var m_air := air_density * V
	added_mass = Vector3(hull.k2 * m_air, hull.k2 * m_air, hull.k1 * m_air)
	var i_air := m_air * (a * a + b * b) / 5.0
	added_inertia = Vector3(hull.k_rot * i_air, hull.k_rot * i_air, 0.0)
	config_changed.emit()


## Turm als feste Flosse an der Unterseite (180°): Fläche = Länge × Höhe,
## Streckung = Höhe / Länge, kein Ruderausschlag.
func _make_sail() -> ControlSurface:
	var c := sail_length_frac * hull.length_m
	var h := sail_height_frac * hull.diameter_m
	var s := ControlSurface.new()
	s.display_name = "Turm"
	s.kind = ControlSurface.Kind.FLAP
	s.hull_x = sail_x
	s.hull_angle_deg = 180.0
	s.area_m2 = c * h
	s.aspect_ratio = h / c
	s.taper = 0.85
	s.max_deflection_deg = 0.0
	s.sail_member = true
	return s


# =============================================================================
# Der eigentliche 6-DOF-Schritt
# =============================================================================
## Schiff an eine Stelle zurücksetzen (Startpunkt). Wird im nächsten
## Physikschritt ausgeführt – nur dort darf man einen RigidBody sicher
## versetzen. Geschwindigkeiten, Motoren und Ruder werden genullt.
func reset_to(xform: Transform3D) -> void:
	_reset_to = xform
	for m in motors:
		m._throttle = 0.0
		m._swivel_deg = 0.0
	for s in surfaces:
		s._servo_deg = 0.0
		s._flex_deg = 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _reset_to != null:
		state.transform = _reset_to
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_reset_to = null
		return
	var dt := state.step
	var body_basis := state.transform.basis.orthonormalized()   # Körper → Welt
	var to_body := body_basis.transposed()  # Welt → Körper (orthonormal)

	var w_b := to_body * state.angular_velocity
	var v_rel := to_body * (state.linear_velocity - wind)   # gegenüber der Luft

	var F := Vector3.ZERO      # Summe Kräfte (Körpersystem)
	var T := Vector3.ZERO      # Summe Momente um das Auftriebszentrum

	# --- 1) Gewicht und Auftrieb ---------------------------------------------
	var g_b := to_body * Vector3(0, -gravity_mps2, 0)
	var weight := g_b * total_mass
	var buoyancy := -g_b * (air_density * hull.volume_m3)
	F += weight + buoyancy
	T += cg_offset.cross(weight)            # Pendel-Rückstellung (Schwerpunkt unten)

	# --- 2) Rumpf: Längswiderstand ------------------------------------------
	var q_ref := 0.5 * air_density * pow(hull.volume_m3, 2.0 / 3.0) * hull_cd_axial
	F.z += -q_ref * v_rel.z * absf(v_rel.z)

	# --- 3) Rumpf: Querstrom in Scheiben (viskos, wirkt hinten stabilisierend
	#        und dämpft Nick-/Gierdrehungen) ------------------------------------
	hull_viscous_moment = Vector3.ZERO
	var n := crossflow_slices
	var dx := hull.length_m / n
	for i in n:
		var xn := (i + 0.5) / n
		var p := Vector3(0, 0, xn * hull.length_m - hull.cb_from_nose)
		var v_loc := v_rel + w_b.cross(p)
		var v_perp := Vector3(v_loc.x, v_loc.y, 0.0)
		var sp := v_perp.length()
		if sp < 1e-4:
			continue
		var dF := -v_perp * (0.5 * air_density * hull_cd_crossflow * crossflow_eta
				* 2.0 * hull.radius_at(xn) * dx * sp)
		F += dF
		var dT := p.cross(dF)
		T += dT
		hull_viscous_moment += dT

	# --- 4) Steuerflächen: Leitwerke, Pendelruder, Canards --------------------
	surface_moment = Vector3.ZERO
	for s in surfaces:
		var v_s := v_rel + w_b.cross(s.position)
		var fs := s.compute_force(v_s, air_density, dt)
		F += fs
		var ts := s.position.cross(fs)
		T += ts
		surface_moment += ts

	# --- 5) Schubvektor-Motoren ----------------------------------------------
	vector_moment = Vector3.ZERO
	for mot in motors:
		var fm := mot.compute_force(dt, v_rel + w_b.cross(mot.position))   # Anströmung am Motor
		F += fm
		var tm := mot.position.cross(fm)
		T += tm
		vector_moment += tm

	# --- 6) Kleine Rolldämpfung ----------------------------------------------
	T.z += -roll_damping * w_b.z

	# --- 7) Virtuelle Massen & Munk-Moment (Kirchhoff) -----------------------
	var Ma_v := added_mass * v_rel                      # komponentenweise = diag(Ma)·v
	munk_moment = -v_rel.cross(Ma_v)                    # destabilisierend!
	T += munk_moment
	F += added_mass * w_b.cross(v_rel) - w_b.cross(Ma_v)

	# --- 8) Beschleunigungen lösen (Diagonal-Massenmatrix) -------------------
	var m_eff := Vector3.ONE * total_mass + added_mass
	var a_b := F / m_eff
	var I_eff := inertia_rb + added_inertia
	var gyro := w_b.cross(I_eff * w_b)
	var wdot_b := (T - gyro) / I_eff

	# --- 9) Geschwindigkeiten integrieren (semi-implizit) --------------------
	state.linear_velocity += body_basis * a_b * dt
	state.angular_velocity += body_basis * wdot_b * dt

	_update_telemetry(v_rel)


# =============================================================================
# Telemetrie für HUD / Flugcontroller
# =============================================================================
func _update_telemetry(v_rel: Vector3) -> void:
	airspeed = v_rel.length()
	# Unter ~1 m/s ist die Anströmrichtung zufällig (Schweben, Absinken) –
	# der Anstellwinkel wäre dann sinnlos (z. B. 105° beim Sinken im Stand).
	if airspeed > 1.0:
		# Vorwärtsfahrt = -Z; Anstellwinkel positiv, wenn die Nase über der Bahn liegt
		alpha_deg = rad_to_deg(atan2(-v_rel.y, -v_rel.z))
		beta_deg = rad_to_deg(atan2(v_rel.x, -v_rel.z))
	else:
		alpha_deg = 0.0
		beta_deg = 0.0
	telemetry_updated.emit({
		"airspeed": airspeed,
		"alpha_deg": alpha_deg,
		"beta_deg": beta_deg,
		"munk_moment": munk_moment,
		"surface_moment": surface_moment,
		"hull_viscous_moment": hull_viscous_moment,
		"vector_moment": vector_moment,
	})


# =============================================================================
# Vereinfachter Modus (vom PerformanceWatchdog aufgerufen)
# =============================================================================
func set_simplified(on: bool) -> void:
	simplified = on
	crossflow_slices = 6 if on else _full_slices
	for s in surfaces:
		s.flex_enabled_runtime = not on     # Pseudo-Flex-Gelenke abschalten
