# 2026-10-27 11:08 – Rückwärtsschub: pro Motor(paar) zuschaltbar (reverse_allowed) mit reduziertem Wirkungsgrad (reverse_efficiency); Propellerdaten für Sound (Durchmesser, Blattzahl, max. Drehzahl, Drehrichtung); pair_id für gemeinsame Einstellung im Baukasten; signed_thrust_estimate() für den Mischer; rpm() / is_reversing() für den Sound
# 2026-10-27 10:42 – Parametrische Platzierung (hull_x, hull_angle_deg, standoff_m) und Pigleg-Schwenkachse: swivel_tilt_deg dreht die Querachse um die Längsachse nach unten; invert_swivel automatisch für linke Seite
# 2026-10-27 10:28 – Erstversion: schwenkbare Motorgondel mit Schub vor/zurück, Servo-Ratenbegrenzung, Momentenbeitrag für Mischer
# =============================================================================
# VectorMotor.gd
# -----------------------------------------------------------------------------
# Schwenkbare Motorgondel. Der Schubvektor wird um eine frei wählbare
# Schwenkachse gedreht (z. B. 45° nach unten geneigt wie beim Chewie-Aufbau).
#
# Schub vor und zurück (Gasknüppel-Mitte = Stopp):
#   Ein normaler Propeller ist für eine Drehrichtung geformt. Rückwärts
#   laufend trifft die Luft auf die "falsche" Profilseite, er erzeugt deutlich
#   weniger Schub – typisch 40–70 % des Vorwärtsschubs bei gleicher Drehzahl.
#   Symmetrische 3D-Propeller erreichen fast 100 %. Das bildet
#   reverse_efficiency ab. Ist reverse_allowed aus, bleibt der Motor im
#   unteren Knüppelbereich einfach stehen.
# =============================================================================
class_name VectorMotor
extends Resource

@export var display_name: String = "Motor"
## Motoren mit gleicher pair_id werden im Baukasten gemeinsam eingestellt
## (z. B. "bug" für das linke und rechte Bugmotor-Paar).
@export var pair_id: String = ""

# --- Parametrische Lage (das speichert der Baukasten) -------------------------
## Längsposition: 0 = Nase, 1 = Heck.
@export_range(0.0, 1.0, 0.01) var hull_x: float = 0.25
## Umfangswinkel von hinten gesehen: 0° oben, 90° rechts, 180° unten, 270° links.
@export_range(0.0, 360.0, 1.0) var hull_angle_deg: float = 90.0
## Abstand der Gondel-Mitte von der Hüllenoberfläche (m).
@export_range(0.0, 2.0, 0.01, "or_greater") var standoff_m: float = 0.08
## Pigleg-Neigung der Schwenkachse: Die waagrechte Querachse wird um die
## Längsachse nach unten gedreht. 0° = reine Nickschwenkung,
## 45° = Chewie (gemeinsam schwenken → Nick, gegensinnig → Gier).
@export_range(-90.0, 90.0, 1.0) var swivel_tilt_deg: float = 0.0

# --- Schub vor / zurück -------------------------------------------------------
## Maximaler Standschub VORWÄRTS in Newton (je Motor).
@export_range(0.0, 500.0, 0.01, "or_greater") var max_thrust_n: float = 1.5
## Darf der Regler rückwärts drehen (Knüppel unter der Mitte)?
@export var reverse_allowed: bool = true
## Rückwärtsschub als Anteil des Vorwärtsschubs bei gleicher Knüppelstellung.
## Normaler Propeller ≈ 0,5–0,6 · 3D-Propeller (symmetrisch) ≈ 0,9–1,0
@export_range(0.1, 1.0, 0.05) var reverse_efficiency: float = 0.55

# --- Propeller (für Klang; Schub kommt aus max_thrust_n) ----------------------
## Propellerdurchmesser in Zoll (5" = 12,7 cm).
@export_range(1.0, 30.0, 0.5) var prop_diameter_in: float = 5.0
@export_range(2, 6, 1) var prop_blades: int = 2
## Drehzahl bei Vollgas (U/min).
@export_range(1000.0, 60000.0, 500.0) var max_rpm: float = 18000.0
## Drehrichtung vorwärts: +1 = rechtsdrehend (CW), −1 = linksdrehend (CCW).
@export_range(-1, 1, 2) var spin_dir: int = 1

# --- Daraus berechnet (place_on_hull) ----------------------------------------
## Montagepunkt im Körpersystem (m).
@export var position: Vector3 = Vector3(0.3, -0.1, -0.6)
## Schubrichtung in Nullstellung (vorwärts = -Z).
@export var thrust_direction: Vector3 = Vector3(0, 0, -1)
## Schwenkachse. Beispiel 45° geneigt: Vector3(1, -1, 0).normalized()
@export var swivel_axis: Vector3 = Vector3(1, 0, 0)
## Maximaler Schwenkwinkel in Grad.
@export_range(0.0, 180.0, 1.0) var max_swivel_deg: float = 60.0
## Schwenk-Servogeschwindigkeit in Grad/s.
@export_range(30.0, 2000.0, 10.0) var servo_speed_dps: float = 400.0
## Motor-Hochlaufzeit in Sekunden (Propeller-Trägheit). Beim Umsteuern
## läuft der Propeller durch den Stillstand – das dauert entsprechend.
@export_range(0.0, 1.0, 0.01) var spool_time_s: float = 0.15
## Spiegelt das Schwenk-Kommando (für links/rechts montierte Gondeln).
@export var invert_swivel: bool = false

# --- Laufzeit-Zustand ---------------------------------------------------------
var throttle_cmd: float = 0.0   ## -1..+1 (bidirektional)
var swivel_cmd: float = 0.0     ## -1..+1 → ±max_swivel_deg
var armed: bool = false         ## Ohne Armen kein Schub (Failsafe!)
var _throttle: float = 0.0      ## tatsächliche Drehzahl-Stellung −1..+1
var _swivel_deg: float = 0.0


# =============================================================================
# Position und Schwenkachse aus den Parametern berechnen.
# Beispiel rechte Gondel (90°), Neigung 45°: Achse = (1, −1, 0)/√2.
# Positiver Schwenk kippt den Schub bei beiden Seiten nach oben (Nase hoch,
# wenn die Motoren vor dem Auftriebszentrum sitzen) – dafür wird die linke
# Gondel automatisch gespiegelt.
# =============================================================================
func place_on_hull(hull: GertlerHull) -> void:
	var a := deg_to_rad(hull_angle_deg)
	var d := Vector3(sin(a), cos(a), 0.0)                  # vom Rumpf weg
	var z := hull_x * hull.length_m - hull.cb_from_nose
	position = d * (hull.radius_at(hull_x) + standoff_m) + Vector3(0, 0, z)
	# Querachse der Gondel = Abstehrichtung, um die Längsachse nach unten geneigt
	var side := signf(d.x) if absf(d.x) > 0.01 else 1.0
	swivel_axis = d.rotated(Vector3(0, 0, 1), -side * deg_to_rad(swivel_tilt_deg)).normalized()
	invert_swivel = side < 0.0


## Aktuelle Schubrichtung (nach Schwenk) im Körpersystem.
func current_direction() -> Vector3:
	var ang := deg_to_rad(_swivel_deg)
	return thrust_direction.normalized().rotated(swivel_axis.normalized(), ang)


## Schub (N, mit Vorzeichen) für eine Drehzahl-Stellung t (−1..+1).
## Propellerschub ~ Drehzahl², rückwärts mit reduziertem Wirkungsgrad.
func thrust_for(t: float) -> float:
	var f := max_thrust_n * t * absf(t)
	return f * reverse_efficiency if t < 0.0 else f


## Schubkraft (N) im Körpersystem für diesen Physikschritt.
func compute_force(dt: float) -> Vector3:
	# Sollwert: Failsafe (nicht scharf → aus), Rückwärts nur wenn erlaubt
	var t_target := clampf(throttle_cmd, -1.0, 1.0) if armed else 0.0
	if not reverse_allowed:
		t_target = maxf(t_target, 0.0)
	if not armed:
		_throttle = 0.0
	elif spool_time_s > 0.0:
		_throttle = lerpf(_throttle, t_target, clampf(dt / spool_time_s, 0.0, 1.0))
	else:
		_throttle = t_target

	var s := -swivel_cmd if invert_swivel else swivel_cmd
	_swivel_deg = move_toward(_swivel_deg, clampf(s, -1.0, 1.0) * max_swivel_deg, servo_speed_dps * dt)
	return current_direction() * thrust_for(_throttle)


## Für den Mischer: erwarteter Schub mit Vorzeichen bei Gas-Kommando t.
## Rückwärts kehrt sich die Wirkung eines Schwenks um – deshalb das Vorzeichen.
## Fast kein Gas → kleiner Referenzschub, damit der Mischer die Richtung kennt.
func signed_thrust_estimate(t: float) -> float:
	if not reverse_allowed:
		t = maxf(t, 0.0)
	var f := thrust_for(t)
	var floor_n := 0.2 * max_thrust_n * (reverse_efficiency if t < 0.0 else 1.0)
	if absf(f) < floor_n:
		f = floor_n * (-1.0 if t < 0.0 else 1.0)
	return f


## Momentenänderung pro Radiant Schwenk bei Referenzschub (für den Mischer).
## ref_thrust mit Vorzeichen: negativ = Rückwärtsschub.
func moment_per_rad_swivel(cg: Vector3, ref_thrust: float) -> Vector3:
	var d := current_direction()
	var dd := swivel_axis.normalized().cross(d)       # Ableitung der Richtung nach dem Winkel
	if invert_swivel: dd = -dd
	return (position - cg).cross(dd * ref_thrust)


## Momentenänderung pro Newton zusätzlichem Schub (für Differenzschub).
func moment_per_newton(cg: Vector3) -> Vector3:
	return (position - cg).cross(current_direction())


# --- Für den Sound ------------------------------------------------------------
## Aktuelle Drehzahl in U/min (Betrag).
func rpm() -> float:
	return absf(_throttle) * max_rpm

## Läuft der Propeller gerade rückwärts?
func is_reversing() -> bool:
	return _throttle < -0.01
