# 2026-11-13 02:00 – fixed: feste Flosse ohne Ruder (Finne)
# 2026-11-12 11:45 – Vorgeschlagenes Gewicht: Depron 120 g/m² (profiliert 2 Lagen) + Pauschale 2–5 g je nach Fläche; mass_auto (von Hand eingetragenes Gewicht nur, wenn aus)
# 2026-11-11 17:45 – Profilname „Platte … mm“ übersetzt, Dezimalzeichen je Sprache
# 2026-11-11 08:20 – Reynoldszahl wird aus Fahrt und mittlerer Tiefe bestimmt (Re = v·c/ν) statt pauschal 10⁵; Profilwerte (Grundwiderstand, Abriss, Auftriebsanstieg dicker Profile) hängen von Re ab
# 2026-11-11 07:20 – Profil: flache Platte (Dicke in mm) oder symmetrisches NACA 00xx (Dicke in % der Tiefe) – wirkt auf Auftriebsanstieg, Abrisswinkel, Weichheit des Abrisses und Grundwiderstand
# 2026-11-11 10:05 – Eigene Masse je Fläche (mass_kg, für Canards)
# 2026-11-07 23:55 – Flossen an der Hülle: wirksame Streckung doppelt (Hülle als Spiegelwand) und Rumpf-Flossen-Interferenz 1,3 (Chewie lief sonst nicht geradeaus)
# 2026-11-07 23:00 – größter Ausschlag bis 80° einstellbar (Chewie: Pendelflossen ±50°)
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
## Eigene Masse dieser Fläche (kg) – nur für Canards und nur, wenn mass_auto
## aus ist (von Hand eingetragen); Leitwerksflossen nutzen AirshipPhysics.
@export_range(0.0, 50.0, 0.001, "or_greater") var mass_kg: float = 0.0
## true = Masse nach suggested_mass_kg() (Depron + Pauschale), false = mass_kg
@export var mass_auto: bool = true
## Feste Flosse ohne Ruder (Finne): bekommt keine Stellbefehle
@export var fixed: bool = false
@export var tail_member: bool = false
## true = fester Turm unter/über der Hülle (wie beim U-Boot): ohne Ruder,
## wird aus den Turm-Einstellungen von AirshipPhysics neu erzeugt.
@export var sail_member: bool = false
## Profil-Nullwiderstand (flache Depronplatte ≈ 0,02).
@export_range(0.0, 0.2, 0.001) var cd0: float = 0.02   ## (alt, nur noch Rückfall – Grundwiderstand kommt aus dem Profil)
## Profil: false = flache Platte („Brettchen“, z. B. Depron), true = NACA 00xx
@export var profile_naca: bool = true
## Dicke NACA in Anteil der Tiefe (0,09 = NACA 0009, 0,20 = NACA 0020)
@export_range(0.04, 0.30, 0.01) var naca_thickness: float = 0.12
## Dicke der flachen Platte (mm)
@export_range(0.5, 20.0, 0.5) var plate_thickness_mm: float = 3.0
## Leitwerks-Wirkungsgrad (Abschattung durch den Rumpf).
@export_range(0.3, 1.5, 0.01) var efficiency: float = 0.8

# --- Ruder / Ausschlag --------------------------------------------------------
## Maximaler Ausschlag in Grad (Klappe bzw. ganze Fläche).
@export_range(0.0, 80.0, 0.5) var max_deflection_deg: float = 25.0
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
	last_re = reynolds(speed)
	var pr := profile_params(last_re)
	var cl := lift_coefficient(alpha, pr)
	var cdi := cl * cl / (PI * effective_aspect_ratio() * 0.85)
	var cd: float = float(pr.cd0) + cdi + 1.2 * pow(sin(alpha), 2)     # Plattenwiderstand bei großen Winkeln

	# Auftriebsrichtung: senkrecht zum Fahrtwind, in der Ebene von Wind und Normale
	var lift_dir := (n - flow * flow.dot(n))
	if lift_dir.length_squared() < 1e-8:
		lift_dir = n
	lift_dir = lift_dir.normalized()

	var lift := lift_dir * (q * area_m2 * cl * efficiency * BODY_INTERFERENCE)
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


## Rumpf-Flossen-Interferenz: Die Hülle verstärkt die Flossenkraft (Querströmung
## um den Rumpf, Übertragung der Flossenlast auf die Hülle). Faktor wie im
## Luftschiff-Simulator (K = 1,3).
const BODY_INTERFERENCE := 1.3


## Wirksame Streckung: Die Flosse sitzt mit der Wurzel an der Hülle. Die Hülle
## wirkt wie eine Spiegelwand, an der Wurzel strömt keine Luft um ⇒ die Flosse
## wirkt wie eine doppelt so gestreckte freie Fläche.
func effective_aspect_ratio() -> float:
	return 2.0 * aspect_ratio


## Auftriebsanstieg nach Helmbold (gut für kleine Seitenverhältnisse),
## mit der wirksamen Streckung an der Hülle.
func lift_slope() -> float:
	var A := effective_aspect_ratio()
	return TAU * A / (2.0 + sqrt(A * A + 4.0))


## Auftriebsbeiwert mit weichem Übergang in den Strömungsabriss.
## Bis zum Abrisswinkel des Profils linear, darüber Flachplatten-Verhalten
## (sin·cos); wie weich der Übergang ist, hängt ebenfalls vom Profil ab.
func lift_coefficient(alpha: float, pr: Dictionary = {}) -> float:
	if pr.is_empty():
		pr = profile_params(RE_REF)
	var cl_lin: float = lift_slope() * float(pr.slope) * alpha
	var cl_plate := 2.0 * sin(alpha) * cos(alpha)
	var blend := clampf((absf(alpha) - deg_to_rad(float(pr.stall_deg))) / deg_to_rad(float(pr.width_deg)), 0.0, 1.0)
	return lerpf(cl_lin, cl_plate, blend)


# -----------------------------------------------------------------------------
# Profil-Kennwerte für kleine Flossen, abhängig von der Reynoldszahl
#   Re = v · c / ν    (v Fahrt, c mittlere Tiefe, ν = 1,5·10⁻⁵ m²/s für Luft)
# Chewie-Flosse (c ≈ 0,19 m): 1 m/s → Re ≈ 13 000, 5 m/s → 63 000, 10 m/s → 127 000.
# Bezug sind Messreihen für NACA 0009…0021 und dünne Platten bei Re ≈ 10⁵,
# übertragen auf die kleinen Seitenverhältnisse der Flossen (Abriss später):
#   Platte:    scharfe Vorderkante → Abriss früh (≈ 14°) und schnell (6°), kaum
#              von Re abhängig; Grundwiderstand aus Dicke (stumpfe Kanten)
#   NACA 00xx: Abriss später und weicher, je dicker desto mehr. Bei kleinerem
#              Re reißt die laminare Grenzschicht früher ab (Ablöseblase):
#              Abriss früher, dicke Profile verlieren Auftriebsanstieg
#   Reibung:   Grundwiderstand ∝ Re^−0,5 (laminare Grenzschicht), begrenzt
# Werte sind Näherungen (ANNAHME) und können durch Messungen ersetzt werden.
# -----------------------------------------------------------------------------
const NU_AIR := 1.5e-5                 ## kinematische Zähigkeit der Luft (m²/s, 20 °C)
const RE_REF := 1.0e5                  ## Bezugs-Reynoldszahl der Kennwerte
## zuletzt berechnete Reynoldszahl (für Anzeigen)
var last_re := 0.0


## Reynoldszahl der Fläche bei Fahrt speed (m/s).
func reynolds(speed: float) -> float:
	return absf(speed) * mean_chord() / NU_AIR


func profile_params(re: float = RE_REF) -> Dictionary:
	var r := clampf(re, 5000.0, 1.0e6) / RE_REF
	var lg := log(r) / log(10.0)                         # log10(Re/10⁵): −1,3 … +1
	var friction := clampf(pow(r, -0.5), 0.6, 2.5)       # laminare Reibung
	if not profile_naca:
		var t_rel := plate_thickness_mm / 1000.0 / maxf(mean_chord(), 0.01)
		return {"slope": 0.95, "stall_deg": 14.0, "width_deg": 6.0,
			"cd0": 0.008 * friction + 0.010 + 0.25 * t_rel}   # Reibung + Kantenwiderstand
	var t := naca_thickness
	var thick := maxf(0.0, t - 0.12)
	return {"slope": clampf(1.0 - 0.6 * thick * clampf(pow(r, -0.3), 0.6, 2.2), 0.7, 1.0),
		"stall_deg": clampf(18.0 + 55.0 * (t - 0.09) + 3.0 * lg, 12.0, 27.0),
		"width_deg": clampf(8.0 + 45.0 * (t - 0.09), 6.0, 16.0),
		"cd0": (0.008 + 0.07 * t) * friction}


## Grundwiderstand des Profils bei der Bezugs-Reynoldszahl.
func profile_cd0() -> float:
	return float(profile_params(RE_REF).cd0)


## Mittlere Tiefe (m) aus Fläche und Spannweite.
func mean_chord() -> float:
	return area_m2 / maxf(span_m(), 1e-4)


## Kurzname des Profils für Anzeigen („NACA 0020“, „Platte 3 mm“).
func profile_name() -> String:
	if profile_naca:
		return "NACA 00%02d" % roundi(naca_thickness * 100.0)
	return I18n.dec((I18n.t("Platte %.1f mm") % plate_thickness_mm).replace(".0 ", " "))


# --- Vorgeschlagenes Gewicht (Baukasten) -------------------------------------
## Flächengewicht Depron (kg/m²): Brettchen = 1 Lage, profiliert (NACA) = 2 Lagen
const DEPRON_KG_M2 := 0.120
## Pauschale für Servo, Anlenkung und Versteifungen je Fläche: 2 g bei kleinen,
## 5 g bei großen Flächen (linear zwischen 150 und 600 cm²)
const FITTING_MIN_KG := 0.002
const FITTING_MAX_KG := 0.005

## Depron-Gewicht der Fläche (kg): Fläche × 120 g/m², profiliert doppelt.
func depron_mass_kg() -> float:
	return area_m2 * DEPRON_KG_M2 * (2.0 if profile_naca else 1.0)

## Pauschale Servo/Anlenkung/Versteifung (kg) nach der Flächengröße.
func fitting_mass_kg() -> float:
	var k := clampf((area_m2 - 0.015) / (0.060 - 0.015), 0.0, 1.0)
	return lerpf(FITTING_MIN_KG, FITTING_MAX_KG, k)

## Vorgeschlagenes Endgewicht der Fläche (kg) = Depron + Pauschale.
func suggested_mass_kg() -> float:
	return depron_mass_kg() + fitting_mass_kg()


## Geschätzte Masse der Fläche ohne Servo (kg) bei Schaumdichte rho_foam (kg/m³).
## NACA-Querschnitt ≈ 0,685 · t · c²; Platte = Dicke · Tiefe.
func estimated_mass_kg(rho_foam: float) -> float:
	if profile_naca:
		return rho_foam * area_m2 * 0.685 * naca_thickness * mean_chord()
	return rho_foam * area_m2 * plate_thickness_mm / 1000.0


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
	var force := lift_dir * (area_m2 * lift_slope() * efficiency * BODY_INTERFERENCE * tau)
	return (position - cg).cross(force)
