# 2026-11-10 14:10 – Erstversion: Akku-Modell (LiPo) – Spannung unter Last, Ladezustand, Strom, Restflugzeit; Schub fällt mit der Spannung (Schub ∝ Drehzahl² ∝ Spannung²)
# =============================================================================
# Battery.gd  (ein Knoten in der Hauptszene, rechnet vor dem Luftschiff)
# -----------------------------------------------------------------------------
# Chewie: 4S LiPo, 300 mAh (Gewicht steckt schon in den 260 g).
#
# Ablauf in jedem Physikschritt:
#   1. Leerlaufspannung E aus dem Ladezustand (typische LiPo-Kurve je Zelle).
#   2. Leistungsbedarf der Motoren bei der Bezugsspannung V0 (voller Akku):
#        P_motor = P_FULL · |Hebel|³        (Drehzahl ∝ Hebel, Leistung ∝ Drehzahl³)
#      Bei niedrigerer Spannung dreht der Motor langsamer: P ∝ (V/V0)³.
#   3. Spannung unter Last aus  V = E − I·R  und  I = P(V)/V:
#        a·V² + V − E = 0  mit  a = R·P0/V0³   →   V = (−1 + √(1 + 4aE)) / (2a)
#   4. Schubfaktor für alle Motoren (V/V0)², Drehzahl für den Klang V/V0.
#   5. Ladezustand sinkt um I·dt.
#
# ANNAHMEN (keine Messwerte, bitte mit echten Daten ersetzen):
#   POWER_PER_N15 = 25 W je N^1,5 Schub je Motor (1804-Motor mit 4"-Propeller:
#   ≈ 7 N bei ≈ 460 W). Innenwiderstand 25 mΩ je Zelle. Elektronik und Servos 2 W.
# =============================================================================
class_name Battery
extends Node

## Akku-Daten (im Menü „Strecke“ einstellbar)
var cells := 4
var capacity_mah := 300.0
## Annahmen (siehe oben)
const R_CELL := 0.025              ## Innenwiderstand je Zelle (Ω)
const POWER_PER_N15 := 25.0        ## W je N^1,5 Schub, je Motor
const P_AVIONICS := 2.0            ## Teensy, Empfänger, Servos (W)
const V_CELL_FULL := 4.2
## Leerlaufspannung je Zelle über dem Ladezustand (LiPo, typisch)
const OCV := [[0.0, 3.30], [0.05, 3.45], [0.10, 3.60], [0.20, 3.70], [0.30, 3.75], [0.40, 3.79],
	[0.50, 3.82], [0.60, 3.87], [0.70, 3.92], [0.80, 3.98], [0.90, 4.06], [1.00, 4.20]]
const SETTINGS_PATH := "user://akku.cfg"

var ship: AirshipPhysics
var soc := 1.0                     ## Ladezustand 0…1
var voltage := 16.8                ## Spannung unter Last (V)
var current := 0.0                 ## Strom (A)
var current_avg := 0.0             ## über ≈ 3 s geglätteter Strom (für die Restzeit)
var used_mah := 0.0


func _init() -> void:
	process_physics_priority = -50   # vor dem Luftschiff rechnen, damit der Schubfaktor im selben Schritt gilt


func _ready() -> void:
	load_settings()
	recharge()


## Akku voll (bei „Zurücksetzen“).
func recharge() -> void:
	soc = 1.0
	used_mah = 0.0
	current = 0.0
	current_avg = 0.0
	voltage = cells * V_CELL_FULL
	_apply(1.0)


## Leerlaufspannung des ganzen Akkus beim Ladezustand s.
func ocv(s: float) -> float:
	s = clampf(s, 0.0, 1.0)
	for i in range(1, OCV.size()):
		if s <= OCV[i][0]:
			var a: Array = OCV[i - 1]
			var b: Array = OCV[i]
			return cells * lerpf(a[1], b[1], (s - a[0]) / (b[0] - a[0]))
	return cells * V_CELL_FULL


func _physics_process(dt: float) -> void:
	if ship == null:
		return
	var v0 := cells * V_CELL_FULL
	var e := ocv(soc)
	var r := cells * R_CELL
	# Leistungsbedarf der Motoren bei V0 (Hebel = tatsächliche Drehzahl-Stellung)
	var p0 := 0.0
	for mot in ship.motors:
		if mot.armed:
			var lever := absf(mot._throttle)
			p0 += POWER_PER_N15 * pow(mot.max_thrust_n, 1.5) * lever * lever * lever
	# Spannung unter Last (siehe Kopf), Elektronik als kleiner Zusatzstrom
	var v := e
	if p0 > 0.01:
		var a := r * p0 / (v0 * v0 * v0)
		v = (-1.0 + sqrt(1.0 + 4.0 * a * e)) / (2.0 * a)
	var p_motor := p0 * pow(v / v0, 3.0)
	current = (p_motor + P_AVIONICS) / maxf(v, 1.0)
	voltage = v - P_AVIONICS / maxf(v, 1.0) * r
	current_avg += (current - current_avg) * clampf(dt / 3.0, 0.0, 1.0)
	# Ladezustand
	var mah := current * dt / 3.6
	used_mah += mah
	soc = maxf(soc - mah / capacity_mah, 0.0)
	_apply(v / v0)


## Schub- und Drehzahlfaktor an alle Motoren geben.
func _apply(k: float) -> void:
	if ship == null:
		return
	for mot in ship.motors:
		mot.voltage_factor = clampf(k, 0.0, 1.0)


## Geschätzte Restflugzeit (s) beim mittleren Strom der letzten Sekunden.
func remaining_s() -> float:
	if current_avg < 0.05:
		return INF
	return (soc * capacity_mah) / (current_avg * 1000.0) * 3600.0


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("akku", "zellen", cells)
	cfg.set_value("akku", "kapazitaet_mah", capacity_mah)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	cells = clampi(int(cfg.get_value("akku", "zellen", cells)), 1, 12)
	capacity_mah = clampf(float(cfg.get_value("akku", "kapazitaet_mah", capacity_mah)), 50.0, 20000.0)


## Akku-Daten ändern (Menü „Strecke“), danach voll laden.
func set_pack(new_cells: int, new_capacity_mah: float) -> void:
	cells = clampi(new_cells, 1, 12)
	capacity_mah = clampf(new_capacity_mah, 50.0, 20000.0)
	save_settings()
	recharge()
