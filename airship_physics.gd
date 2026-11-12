# 2026-11-12 22:55 – Mischer von Hand: mix_manual, mix_table
# 2026-11-12 22:15 – Akku wahlweise an eigener Stelle (battery_own_x, battery_x); Restmasse/Ballast gleicht weiter aus
# 2026-11-12 21:30 – model_description (Kurzbeschreibung bis 100 Zeichen)
# 2026-11-12 11:45 – Hüllenmasse berechnet (Oberfläche × Folie 27 g/m² + 7 % für Nähte, Ränder, Ventil); Flossen/Canards nach Vorschlag (Depron + Pauschale) oder von Hand: fin_mass_of()
# 2026-11-12 10:40 – Platzen ist Grundregel (nicht abschaltbar)
# 2026-11-12 10:05 – Hülle platzt pauschal ab 20 km/h Fahrt beim Aufprall (fester Wert, nicht mehr einstellbar)
# 2026-11-11 18:05 – repair(): heile Hülle auch beim Wechsel in Baukasten/Menü (vorher blieb sie dort schlaff)
# 2026-11-11 14:10 – Aufprall: Stoß wird gemessen (Hülle federt sichtbar), über der Grenzgeschwindigkeit platzt die Hülle hinten (Druckwelle läuft nach hinten), Gas entweicht vom Heck zur Nase, Auftrieb und Auftriebspunkt wandern mit, Motoren aus
# 2026-11-11 10:05 – Teensy-Masse einstellbar (teensy_mass_kg); Canards mit eigener Masse (ControlSurface.mass_kg) in Massenbilanz, Schwerpunkt und Trägheit
# 2026-11-10 23:30 – Turm entfällt (lässt sich als Canard abbilden); Teensy-Flugcontroller als Bauteil (+10 g, ohne Teensy nur „Direkt“); Akku (Zellen, Kapazität, Masse) als Teil der Restmasse; frei platzierbare Nutzlast (Masse, Längslage, Umfangswinkel)
# 2026-11-07 23:30 – Munk-Moment mit Abminderung munk_factor (Standard 0,6: Grenzschicht am Heck; mit 1,0 schwang Chewie mit den echten Teensy-Reglerwerten stark in Nick)
# 2026-11-07 21:40 – Masse je Leitwerksflosse (fin_mass_kg) als Punktmasse am Einbauort: in Massenbilanz, Schwerpunkt, Austrimmen der Restmasse und Trägheit
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
## Hülle ist geplatzt (true) bzw. nach dem Zurücksetzen wieder heil (false)
signal burst_changed(on: bool)
## Stoß gegen Wand/Boden/Pylon: Stärke 0…1 (1 = Grenze zum Platzen), für das Nachfedern der Hülle
signal bumped(strength: float)

# --- Konfiguration aus dem Baukasten -----------------------------------------
@export var hull: GertlerHull
@export var surfaces: Array[ControlSurface] = []
@export var motors: Array[VectorMotor] = []
## Name des Modells (erscheint im Modell-String und in der Auswahl).
@export var model_name := "Albacore Standard"
## Kurzbeschreibung des Modells (bis 100 Zeichen, im Baukasten und in der Modellliste)
@export var model_description := ""
## Mischer von Hand (Reiter Steuerung → Mischer einstellen): an = mix_table gilt
## im Modus Direkt und ohne Flugcontroller, aus = Mischer nach Einbaulage.
@export var mix_manual := false
## Mischtabelle: Ausgang → [Nick, Gier, Roll] in % des Vollausschlags.
## Ausgänge: "s0", "s1" … = surfaces[i] (Flossen, Canards), "m0" … = motors[i] (Schwenker)
@export var mix_table := {}
## Gestaltung der Hülle (Farbe, Schriftzug, Logo) – rein optisch.
@export var livery: Livery = Livery.new()
## Symmetrisches Leitwerk. Seine Flossen werden bei jedem Neuaufbau aus dieser
## Beschreibung erzeugt; null = nur freie Flächen (z. B. alte Modell-Strings).
@export var tail: TailConfig

@export_group("Massen")
## Hülle (ohne Traggas), in kg. Verteilt über die Hüllenfläche. Wird bei jedem
## Neuaufbau BERECHNET: Oberfläche × Folien-Flächengewicht × (1 + HULL_EXTRA).
@export_range(0.0, 10000.0, 0.001, "or_greater") var hull_mass_kg: float = 0.086
## Flächengewicht der Hüllenfolie (kg/m²), Standard 27 g/m²
@export_range(0.001, 1.0, 0.001, "or_greater") var hull_film_kg_m2: float = 0.027
## Zuschlag zur Folie: 2 % Nähte + 5 % Ränder und Ventil
const HULL_EXTRA := 0.07
## Elektronik ohne Akku (Flugcontroller, Empfänger, BEC), in kg.
## Sitzt zusammen mit Akku und Ballast unten an der Hülle.
@export_range(0.0, 10000.0, 0.001, "or_greater") var electronics_mass_kg: float = 0.030
## Masse je Leitwerksflosse (mit Servo), in kg – nur wenn fin_mass_auto aus ist
## (von Hand eingetragen). Sitzt im Flächenschwerpunkt der Flosse.
@export_range(0.0, 100.0, 0.001, "or_greater") var fin_mass_kg: float = 0.0
## true = Flossengewicht nach Vorschlag (Depron + Pauschale, siehe ControlSurface)
@export var fin_mass_auto: bool = true
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

@export_group("Flugcontroller, Akku, Nutzlast")
## Teensy-Flugcontroller eingebaut? Ohne ihn gibt es nur „Direkt“ (Knüppel
## gehen ohne Regler auf Ruder und Schwenker). Masse TEENSY_MASS_KG kommt zur
## Elektronik unten an der Hülle dazu.
@export var fc_teensy: bool = true
const TEENSY_MASS_KG := 0.010
## Masse des Teensy-Flugcontrollers (kg), im Baukasten einstellbar
@export_range(0.0, 1.0, 0.001) var teensy_mass_kg: float = TEENSY_MASS_KG
## Akku: Zellenzahl (S), Kapazität (mAh) und Masse (kg). Er ist Teil der
## Restmasse unten an der Hülle (Rest = Ballast).
@export_range(1, 12, 1) var battery_cells: int = 4
@export_range(50.0, 100000.0, 10.0) var battery_mah: float = 300.0
@export_range(0.0, 50.0, 0.001) var battery_mass_kg: float = 0.038
## Akku an eigener Stelle (sonst Teil der Restmasse an ballast_x)
@export var battery_own_x: bool = false
## Längslage des Akkus (0 = Nase, 1 = Heck), klebt unten an der Hülle
@export_range(0.0, 1.0, 0.01) var battery_x: float = 0.45
## Lage des Akkus im Körpersystem (nur bei battery_own_x)
var battery_pos := Vector3.ZERO
## Nutzlast: frei platzierbare Punktmasse an der Hülle (0 = keine).
@export_range(0.0, 50.0, 0.001, "or_greater") var payload_mass_kg: float = 0.0
## Längslage der Nutzlast (0 = Nase, 1 = Heck)
@export_range(0.0, 1.0, 0.01) var payload_x: float = 0.5
## Umfangswinkel der Nutzlast (0° oben, 90° rechts, 180° unten, 270° links)
@export_range(0.0, 360.0, 1.0) var payload_angle_deg: float = 180.0
## Lage der Nutzlast im Körpersystem (aus payload_x / payload_angle_deg)
var payload_pos := Vector3.ZERO
## Ballast (kg) = Restmasse − Akku; negativ heißt: der Akku ist schwerer als erlaubt
var ballast_kg := 0.0

@export_group("Turm (entfällt – nur noch für alte Modell-Strings)")
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
## Anteil des Munk-Moments aus der Potentialtheorie, der am echten Rumpf wirkt.
## Die Grenzschicht am Heck nimmt einen Teil davon weg (1,0 = reine Theorie).
## 0,6: mit dem vollen Wert schwang Chewie mit den Reglerwerten des echten
## Teensy-Codes in Nick ±20° (am echten Modell nicht beobachtet).
@export_range(0.0, 1.0, 0.01) var munk_factor: float = 0.6
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

# --- Aufprall und Platzen ------------------------------------------------------
# Prallt das Schiff gegen etwas, federt die pralle Hülle wie ein Ball zurück
# (Rückprall über das Physikmaterial der Halle). Ist das Schiff beim Aufprall
# 20 km/h oder schneller (pauschal, gleich aus welcher Richtung), läuft eine Druckwelle durch das Gas nach
# hinten und die Hülle reißt am Heck entlang einer Längsnaht auf. Das Gas
# entweicht von hinten nach vorn: deflate_front wandert in DEFLATE_S Sekunden
# vom Heck (1) zur Nase (0); nur vor dieser Stelle trägt noch Gas.
const DEFLATE_S := 1.4
const BURST_SPEED_MPS := 20.0 / 3.6  ## Hülle platzt pauschal ab 20 km/h Fahrt beim Aufprall
const BUMP_FULL_MPS := 3.0           ## Stoß mit dieser Geschwindigkeit auf die Wand = voller Aufprall-Klang
var burst := false                   ## Hülle ist geplatzt
var deflate_front := 1.0             ## 1 = prall … 0 = leer (Anteil der Länge ab Nase, der noch Gas hat)
var _v_prev := Vector3.ZERO          ## Geschwindigkeit am Ende des letzten Schritts (vor dem Stoß)
var _w_prev := Vector3.ZERO
var _bump_cool := 0.0                ## kurze Sperre, damit ein Stoß nur einmal zählt


func _ready() -> void:
	custom_integrator = true        # Godot rechnet nur noch Kollisionen
	can_sleep = false
	contact_monitor = true          # Berührungen melden, um den Aufprall zu messen
	max_contacts_reported = 4
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
## Masse einer Leitwerksflosse oder eines Canards (kg): Vorschlag (Depron +
## Pauschale) oder von Hand eingetragen. Turm-Teile zählen nicht.
func fin_mass_of(s: ControlSurface) -> float:
	if s.sail_member:
		return 0.0
	if s.tail_member:
		return s.suggested_mass_kg() if fin_mass_auto else fin_mass_kg
	return s.suggested_mass_kg() if s.mass_auto else s.mass_kg


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
	# Turm entfällt (10.11.2026): eine feste Flosse unten lässt sich als Canard bauen
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
	# Hülle: aus Oberfläche und Folie berechnet (kein Schieberegler mehr)
	hull_mass_kg = hull.surface_m2() * hull_film_kg_m2 * (1.0 + HULL_EXTRA)
	var V := hull.volume_m3
	var a := hull.length_m * 0.5           # Halbachse längs
	var b := hull.diameter_m * 0.5         # Halbachse quer
	var gas_mass := gas_density * V
	var motor_mass := 0.0
	for mot in motors:
		motor_mass += mot.mass_kg
	# Leitwerksflossen als Punktmassen an ihrem Einbauort (nur erzeugte Flossen, nicht Canards/Turm)
	var fins: Array[ControlSurface] = []
	for s in surfaces:
		if s.tail_member:
			fins.append(s)
	var fin_total := 0.0
	for s in fins:
		fin_total += fin_mass_of(s)
	# Freie Flächen (Canards) mit eigener Masse als Punktmassen am Einbauort
	var extra: Array = []
	for s in surfaces:
		if not s.tail_member and not s.sail_member and fin_mass_of(s) > 0.0:
			extra.append([fin_mass_of(s), s.position])
			fin_total += fin_mass_of(s)
	var fc_mass := teensy_mass_kg if fc_teensy else 0.0
	# Nutzlast sitzt außen an der Hülle (wie eine Gondel)
	var pa := deg_to_rad(payload_angle_deg)
	payload_pos = Vector3(sin(pa), cos(pa), 0.0) * hull.radius_at(payload_x) \
		+ Vector3(0, 0, payload_x * hull.length_m - hull.cb_from_nose)
	var fixed := hull_mass_kg + motor_mass + electronics_mass_kg + fc_mass + fin_total + payload_mass_kg
	if auto_trim:
		# Auftrieb = ρ_Luft·V·g ; Gewicht = (Struktur + Gas)·g + gewünschte Schwere
		var needed := air_density * V - gas_mass + trim_heaviness_n / gravity_mps2
		rest_mass_kg = maxf(0.0, needed - fixed)
		overweight = fixed > needed
	else:
		rest_mass_kg = maxf(0.0, structure_mass_kg - fixed)
		overweight = false
	structure_mass_kg = fixed + rest_mass_kg
	ballast_kg = rest_mass_kg - battery_mass_kg       # Akku gehört zur Restmasse
	bottom_mass_kg = electronics_mass_kg + fc_mass + rest_mass_kg
	# Akku an eigener Stelle: zählt nicht zur Unten-Masse an ballast_x
	var bat_own := battery_own_x and battery_mass_kg > 0.0
	if bat_own:
		bottom_mass_kg = maxf(bottom_mass_kg - battery_mass_kg, 0.0)
		battery_pos = Vector3(0, -hull.radius_at(battery_x), battery_x * hull.length_m - hull.cb_from_nose)
	total_mass = structure_mass_kg + gas_mass
	mass = maxf(total_mass, 0.001)         # für Godots Kollisionsantwort

	# Längsmoment der Motoren (Körper-Z, + = hinten) – für das Austrimmen
	var mz_motors := 0.0
	for mot in motors:
		mz_motors += mot.mass_kg * mot.position.z
	for s in fins:
		mz_motors += fin_mass_of(s) * s.position.z             # Flossen hinten: Restmasse wandert nach vorn
	mz_motors += payload_mass_kg * payload_pos.z
	for e in extra: mz_motors += e[0] * (e[1] as Vector3).z
	if bat_own: mz_motors += battery_mass_kg * battery_pos.z
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
	for s in fins:
		moment += s.position * fin_mass_of(s)
	moment += payload_pos * payload_mass_kg
	for e in extra: moment += (e[1] as Vector3) * float(e[0])
	if bat_own: moment += battery_pos * battery_mass_kg
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
	for s in fins:
		pts.append([fin_mass_of(s), s.position])
	pts.append([payload_mass_kg, payload_pos])
	pts.append_array(extra)
	if bat_own: pts.append([battery_mass_kg, battery_pos])
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
	repair()


## Geplatzte Hülle durch eine heile ersetzen (Zurücksetzen, Baukasten, Menü).
func repair() -> void:
	if burst:
		burst = false
		deflate_front = 1.0
		physics_material_override = null
		burst_changed.emit(false)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _reset_to != null:
		state.transform = _reset_to
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_reset_to = null
		_v_prev = Vector3.ZERO
		_w_prev = Vector3.ZERO
		return
	var dt := state.step
	_check_impacts(state, dt)
	var body_basis := state.transform.basis.orthonormalized()   # Körper → Welt
	var to_body := body_basis.transposed()  # Welt → Körper (orthonormal)

	var w_b := to_body * state.angular_velocity
	var v_rel := to_body * (state.linear_velocity - wind)   # gegenüber der Luft

	var F := Vector3.ZERO      # Summe Kräfte (Körpersystem)
	var T := Vector3.ZERO      # Summe Momente um das Auftriebszentrum

	# --- 1) Gewicht und Auftrieb ---------------------------------------------
	var g_b := to_body * Vector3(0, -gravity_mps2, 0)
	var weight := g_b * total_mass
	var gas := 1.0                          # Anteil des Gases, das noch trägt
	var cb_now := Vector3.ZERO              # Auftriebspunkt (wandert nach dem Platzen nach vorn)
	if burst:
		deflate_front = maxf(0.0, deflate_front - dt / DEFLATE_S)
		var g := _gas_left(deflate_front)
		gas = g.x
		cb_now = Vector3(0, 0, g.y)
	var buoyancy := -g_b * (air_density * hull.volume_m3 * gas)
	F += weight + buoyancy
	T += cb_now.cross(buoyancy)             # Heck leer, Nase trägt noch → Heck sackt zuerst
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
		if burst:
			mot.armed = false                 # Hülle geplatzt → Motoren sofort aus
		var fm := mot.compute_force(dt, v_rel + w_b.cross(mot.position))   # Anströmung am Motor
		F += fm
		var tm := mot.position.cross(fm)
		T += tm
		vector_moment += tm

	# --- 6) Kleine Rolldämpfung ----------------------------------------------
	T.z += -roll_damping * w_b.z

	# --- 7) Virtuelle Massen & Munk-Moment (Kirchhoff) -----------------------
	var Ma_v := added_mass * v_rel                      # komponentenweise = diag(Ma)·v
	munk_moment = -v_rel.cross(Ma_v) * munk_factor      # destabilisierend!
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
	_v_prev = state.linear_velocity
	_w_prev = state.angular_velocity

	_update_telemetry(v_rel)


## Berührungen auswerten: Wie schnell ist das Schiff senkrecht auf die
## Fläche zugeflogen? (Geschwindigkeit vom Schritt davor, also vor dem Rückprall)
func _check_impacts(state: PhysicsDirectBodyState3D, dt: float) -> void:
	_bump_cool = maxf(0.0, _bump_cool - dt)
	var count := state.get_contact_count()
	if count == 0 or _bump_cool > 0.0:
		return
	var worst := 0.0
	for i in count:
		var nrm := state.get_contact_local_normal(i)          # zeigt von der Wand zum Schiff
		var r := state.get_contact_local_position(i) - state.transform.origin
		var v := _v_prev + _w_prev.cross(r)                   # Geschwindigkeit an der Berührstelle
		worst = maxf(worst, -v.dot(nrm))                      # > 0: fliegt auf die Fläche zu
	if worst < 0.3:
		return                                                # nur Anlehnen / Rollen
	_bump_cool = 0.25
	bumped.emit(clampf(worst / BUMP_FULL_MPS, 0.0, 1.0))
	# Platzen: pauschal nach der Fahrt des Schiffs vor dem Stoß (nicht nur senkrecht zur Wand)
	if not burst and _v_prev.length() >= BURST_SPEED_MPS:      # Grundregel, nicht abschaltbar
		_start_burst()


## Hülle platzt: Druckwelle läuft nach hinten, die Naht reißt am Heck.
func _start_burst() -> void:
	burst = true
	deflate_front = 1.0
	# Schlaffe Hülle springt nicht mehr: „absorbierendes“ Material zieht den
	# Rückprall der Halle ab (0,6 − 1 → 0)
	var pm := PhysicsMaterial.new()
	pm.absorbent = true
	pm.bounce = 1.0
	pm.friction = 0.8
	physics_material_override = pm
	burst_changed.emit(true)


## Gas vor der Stelle front (0 Nase … 1 Heck): x = Anteil am Gesamtvolumen,
## y = Lage seines Schwerpunkts auf der Längsachse (Körper-Z).
func _gas_left(front: float) -> Vector2:
	const N := 24
	var total := 0.0
	var part := 0.0
	var moment := 0.0
	for i in N:
		var x := (i + 0.5) / N
		var r := hull.radius_at(x)
		var dv := r * r                                       # ∝ Scheibenvolumen
		total += dv
		if x < front:
			part += dv
			moment += dv * (x * hull.length_m - hull.cb_from_nose)
	if part <= 0.0:
		return Vector2(0.0, 0.0)
	return Vector2(part / total, moment / part)


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
