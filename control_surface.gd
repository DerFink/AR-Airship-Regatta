# 2026-10-27 23:49 – Kennung sail_member für den festen Turm
# 2026-10-27 23:28 – Pseudo-Flex wirkt auch beim Pendelleitwerk, wenn eingeschaltet
# 2026-10-27 15:09 – Zuspitzung (taper, im LTA-Simulator „Pfeilung“) und Kennung tail_member für Flossen aus dem symmetrischen Leitwerk
# 2026-10-27 10:42 – Parametrische Platzierung: hull_x (Längsposition) + hull_angle_deg (Umfangswinkel) → place_on_hull() berechnet Druckpunkt und Normale; span_m() für Darstellung; Servo/Flex wird auch im Stand nachgeführt (Ruder bewegen sich beim Bodentest sichtbar)
# 2026-10-27 10:25 – Erstversion: Ruderklappe, Pendelleitwerk, Canard; Pseudo-Flex-Gelenk; Klappenwirksamkeit; Stall-Modell
# =============================================================================
# ControlSurface.gd
# -----------------------------------------------------------------------------
# Ein aerodynamisches Steuerelement aus dem Baukasten. Dieselbe Klasse deckt
# alle drei Varianten ab, weil sich nur die Umsetzung des Ausschlags
# unterscheidet:
#
#   FLAP        – feste Flosse mit Ruderklappe (Wirksamkeit hängt von der
#                 Klappentiefe ab, optional "Pseudo-Flex" für Depron)
#   ALL_MOVING  – Pendelleitwerk: die ganze Fläche dreht sich
#   CANARD      – Steuerfläche am Bug (physikalisch wie ALL_MOVING oder FLAP,
#                 wird aber vom Validator als destabilisierend gewertet)
#
# Koordinaten sind im Körpersystem des Luftschiffs (Ursprung = Auftriebs-
# zentrum, -Z = vorne, +Y = oben, +X = rechts).
# =============================================================================
class_name ControlSurface
extends Resource

enum Kind { FLAP, ALL_MOVING, CANARD }

# --- Grundeinstellungen aus dem Baukasten ------------------------------------
@export var display_name: String = "Leitwerk"
@export var kind: Kind = Kind.FLAP
# --- Parametrische Lage am Rumpf (das speichert der Baukasten) ---------------
## Längsposition des Druckpunkts: 0 = Nase, 1 = Heck. Canards: ca. 0,1–0,25.
@export_range(0.0, 1.0, 0.01) var hull_x: float = 0.90
## Umfangswinkel, in den die Flosse vom Rumpf absteht (von hinten gesehen):
## 0° = oben, 90° = rechts, 180° = unten, 270° = links, 135° = unten rechts.
@export_range(0.0, 360.0, 1.0) var hull_angle_deg: float = 0.0

# --- Daraus berechnet (place_on_hull) – von der Physik genutzt ----------------
## Druckpunkt der Fläche im Körpersystem (m).
@export var position: Vector3 = Vector3(0, 0, 1.0)
## Flächennormale im Körpersystem. (0,1,0) = waagrechte Fläche (Höhenleitwerk),
## (1,0,0) = senkrechte Fläche (Seitenleitwerk), schräg = V-/Y-Leitwerk.
@export var normal: Vector3 = Vector3(0, 1, 0)
## Gesamtfläche dieses Bauteils in m².
@export_range(0.001, 50.0, 0.001, "or_greater") var area_m2: float = 0.04
## Seitenverhältnis (Spannweite² / Fläche). Kleine Flossen: 1–3.
@export_range(0.3, 10.0, 0.1) var aspect_ratio: float = 1.5
## Pfeilung wie im LTA-Simulator = Zuspitzung: Endtiefe / Wurzeltiefe
## (1 = Rechteck). Ändert Form und Druckpunkt, nicht die Fläche.
@export_range(0.2, 1.0, 0.05) var taper: float = 1.0
## Gehört zum symmetrischen Leitwerk (wird aus TailConfig erzeugt). Freie
## Flächen wie Canards haben false und bleiben beim Neuaufbau erhalten.
@export var tail_member: bool = false
## true = fester Turm unter/über der Hülle (wie beim U-Boot): ohne Ruder,
## wird aus den Turm-Einstellungen von AirshipPhysics neu erzeugt.
@export var sail_member: bool = false
## Profil-Nullwiderstand (flache Depronplatte ≈ 0,02).
@export_range(0.0, 0.2, 0.001) var cd0: float = 0.02
## Leitwerks-Wirkungsgrad (Abschattung durch den Rumpf).
@export_range(0.3, 1.0, 0.01) var efficiency: float = 0.8

# --- Ruder / Ausschlag --------------------------------------------------------
## Maximaler Ausschlag in Grad (Klappe bzw. ganze Fläche).
@export_range(0.0, 45.0, 0.5) var max_deflection_deg: float = 25.0
## Klappentiefe als Anteil der Profiltiefe (nur FLAP).
@export_range(0.1, 0.6, 0.01) var flap_chord_ratio: float = 0.30
## Servo-Stellgeschwindigkeit in Grad/s (digitale Servos ~ 400–600 °/s).
@export_range(30.0, 2000.0, 10.0) var servo_speed_dps: float = 500.0

# --- Pseudo-Flex-Gelenk (Depron mit Klebeband-Scharnier) ---------------------
## Simuliert, dass ein weiches Scharnier unter Luftlast nachgibt:
## der wirksame Ausschlag sinkt mit dem Staudruck, und es gibt Verzögerung.
@export var pseudo_flex: bool = false
## Nachgiebigkeit: Ausschlagsverlust pro Pascal Staudruck.
@export_range(0.0, 0.2, 0.001) var flex_compliance: float = 0.02
## Zeitkonstante der Flex-Verzögerung in Sekunden.
@export_range(0.0, 0.5, 0.01) var flex_time_constant: float = 0.08

# --- Laufzeit-Zustand ---------------------------------------------------------
var command: float = 0.0            ## Sollwert vom Mischer, -1..+1
var _servo_deg: float = 0.0          ## tatsächliche Servo-Stellung
var _flex_deg: float = 0.0           ## wirksamer Ausschlag nach Flex-Filter
var flex_enabled_runtime: bool = true ## Watchdog kann Flex global abschalten


# =============================================================================
# Kräfte berechnen. Rückgabe: Kraft im Körpersystem (N), Angriffspunkt = position.
#   v_local : Anströmgeschwindigkeit der Fläche relativ zur Luft (Körpersystem)
#             – also bereits inkl. Drehanteil ω × r
#   rho     : Luftdichte
#   dt      : Physik-Zeitschritt
# =============================================================================
func compute_force(v_local: Vector3, rho: float, dt: float) -> Vector3:
	# 1) Servo fährt mit begrenzter Geschwindigkeit auf den Sollwert
	var target := clampf(command, -1.0, 1.0) * max_deflection_deg
	_servo_deg = move_toward(_servo_deg, target, servo_speed_dps * dt)

	# Luft trifft die Fläche mit -v_local (Fahrtwind)
	var speed := v_local.length()
	var q := 0.5 * rho * speed * speed                 # Staudruck

	# 2) Pseudo-Flex: weiches Scharnier gibt unter Last nach + Verzögerung
	#    (läuft auch im Stand, damit die Darstellung den Ausschlag zeigt)
	var eff_deg := _servo_deg
	if pseudo_flex and flex_enabled_runtime:   # Klappe: Scharnier gibt nach · Pendel: Welle/Fläche verdreht sich
		var loaded := _servo_deg / (1.0 + flex_compliance * q)
		var a := 1.0 if flex_time_constant <= 0.0 else clampf(dt / flex_time_constant, 0.0, 1.0)
		_flex_deg = lerpf(_flex_deg, loaded, a)
		eff_deg = _flex_deg
	else:
		_flex_deg = _servo_deg
	if speed < 0.05:
		return Vector3.ZERO                            # ohne Fahrtwind keine Kraft

	# 3) Umrechnung des Ausschlags in eine wirksame Anstellwinkel-Änderung
	var delta_alpha := deg_to_rad(eff_deg)
	if kind == Kind.FLAP:
		delta_alpha *= flap_effectiveness(flap_chord_ratio)
	# Pendelleitwerk / Canard (ALL_MOVING-Bauart): volle Drehung = voller Winkel

	# 4) Geometrischer Anstellwinkel der Fläche
	var n := normal.normalized()
	var flow := -v_local / speed                       # Richtung des Fahrtwinds
	# Positiv, wenn der Wind von der Unterseite (gegen n) auf die Fläche trifft
	var alpha_geo := asin(clampf(flow.dot(n), -1.0, 1.0))
	var alpha := alpha_geo + delta_alpha

	# 5) Auftrieb (mit Stall) und Widerstand
	var cl := lift_coefficient(alpha)
	var cdi := cl * cl / (PI * aspect_ratio * 0.85)
	var cd := cd0 + cdi + 1.2 * pow(sin(alpha), 2)     # Plattenwiderstand bei großen Winkeln

	# Auftriebsrichtung: senkrecht zum Fahrtwind, in der Ebene von Wind und Normale
	var lift_dir := (n - flow * flow.dot(n))
	if lift_dir.length_squared() < 1e-8:
		lift_dir = n
	lift_dir = lift_dir.normalized()

	var lift := lift_dir * (q * area_m2 * cl * efficiency)
	var drag := flow * (q * area_m2 * cd)
	return lift + drag


## Spannweite einer Flosse (m) aus Fläche und Seitenverhältnis.
func span_m() -> float:
	return sqrt(area_m2 * aspect_ratio)


## Richtung (Körpersystem), in die die Flosse vom Rumpf absteht.
func outward_dir() -> Vector3:
	var a := deg_to_rad(hull_angle_deg)
	return Vector3(sin(a), cos(a), 0.0)


# =============================================================================
# Berechnet Druckpunkt und Normale aus hull_x / hull_angle_deg.
# Muss nach jeder Änderung an Hülle oder Bauteil aufgerufen werden
# (AirshipPhysics.rebuild_mass_properties() erledigt das für alle Teile).
# =============================================================================
func place_on_hull(hull: GertlerHull) -> void:
	var d := outward_dir()
	var z := hull_x * hull.length_m - hull.cb_from_nose
	# Druckpunkt ≈ 40 % der Spannweite außerhalb der Hülle
	position = d * (hull.radius_at(hull_x) + 0.4 * span_m()) + Vector3(0, 0, z)
	# Flossenebene = Längsachse + Abstehrichtung → Normale steht senkrecht darauf
	normal = Vector3(0, 0, 1).cross(d).normalized()


## Auftriebsanstieg nach Helmbold (gut für kleine Seitenverhältnisse).
func lift_slope() -> float:
	var A := aspect_ratio
	return TAU * A / (2.0 + sqrt(A * A + 4.0))


## Auftriebsbeiwert mit weichem Übergang in den Strömungsabriss.
## Unterhalb ~ 20° linear, darüber Flachplatten-Verhalten (sin·cos).
func lift_coefficient(alpha: float) -> float:
	var cl_lin := lift_slope() * alpha
	var cl_plate := 2.0 * sin(alpha) * cos(alpha)
	var stall := deg_to_rad(20.0)
	var blend := clampf((absf(alpha) - stall) / deg_to_rad(10.0), 0.0, 1.0)
	return lerpf(cl_lin, cl_plate, blend)


## Klappenwirksamkeit τ nach der Profiltheorie dünner Platten:
## eine 30-%-Klappe erzeugt ca. 66 % der Wirkung eines Pendelruders.
static func flap_effectiveness(cf: float) -> float:
	var theta := acos(2.0 * cf - 1.0)
	return 1.0 - (theta - sin(theta)) / PI


## Hilfsfunktion für Mischer und Validator:
## Moment (Körpersystem) pro Radiant wirksamem Ausschlag bei Staudruck q = 1 Pa,
## für Fahrt nach vorn. Vorzeichen = in welche Richtung das Ruder dreht.
func moment_per_rad(cg: Vector3 = Vector3.ZERO) -> Vector3:
	var tau := flap_effectiveness(flap_chord_ratio) if kind == Kind.FLAP else 1.0
	var n := normal.normalized()
	# Fahrtwind kommt von vorn (+Z-Richtung im Körpersystem)
	var flow := Vector3(0, 0, 1)
	var lift_dir := (n - flow * flow.dot(n)).normalized()
	var force := lift_dir * (area_m2 * lift_slope() * efficiency * tau)
	return (position - cg).cross(force)
