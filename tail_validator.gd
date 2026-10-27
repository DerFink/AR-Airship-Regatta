# 2026-10-27 10:40 – Erstversion: Leitwerksvolumen V_T für Nick und Gier, Stabilitätsmaß gegen Munk-Moment, Canard-Berücksichtigung, Warnstufen
# =============================================================================
# TailValidator.gd
# -----------------------------------------------------------------------------
# Prüft beim Zusammenbau im Baukasten, ob die Leitwerke groß genug sind, um das
# destabilisierende Munk-Moment des Rumpfs auszugleichen.
#
# Vorgehen (lineare Stabilität für kleine Winkel):
#   Munk-Steigung      dM_hull/dα = 2 · V · (k2 − k1)          (pro Pa Staudruck)
#   Flächen-Steigung   dM_tail/dα = Σ S · CLα · η · τ_n · l
#        τ_n = Anteil der Fläche, der in dieser Achse wirkt (Normale²)
#        l   = Abstand hinter dem Schwerpunkt (Canards vorn → negativ!)
#   Stabilitätsmaß     = Flächen-Steigung / Munk-Steigung
#        > 1  → statisch stabil
#        < 1  → instabil, Flugcontroller muss nachhelfen
#
# Die Rechnung ist bewusst konservativ: Der viskose Querstrom-Auftrieb des
# Rumpfs, der im Flug zusätzlich stabilisiert, ist bei kleinen Winkeln
# quadratisch und taucht in der linearen Steigung nicht auf.
# =============================================================================
class_name TailValidator
extends RefCounted

enum Level { OK, MARGINAL, UNSTABLE }

## Schwellen (später anhand von Flugtests kalibrieren).
const THRESHOLD_STABLE := 1.1
const THRESHOLD_MARGINAL := 0.8

const MSG_UNSTABLE := "Achtung: Leitwerksfläche zu klein – aerodynamisch instabil!"
const MSG_MARGINAL := "Grenzwertig – Flugcontroller-Unterstützung empfohlen."
const MSG_OK := "Leitwerk ausreichend – statisch stabil."


# =============================================================================
# Hauptfunktion. Gibt ein Dictionary mit allen Werten für den Editor zurück.
#   cg: Schwerpunkt relativ zum Auftriebszentrum (aus AirshipPhysics.cg_offset)
# =============================================================================
static func validate(hull: GertlerHull, surfaces: Array[ControlSurface],
		cg: Vector3 = Vector3.ZERO) -> Dictionary:
	var V := hull.volume_m3
	var munk_slope := 2.0 * V * (hull.k2 - hull.k1)

	var pitch_slope := 0.0     # Σ S·CLα·η·n_y²·l
	var yaw_slope := 0.0       # Σ S·CLα·η·n_x²·l
	var vt_pitch := 0.0        # Σ S·n_y²·l / V   (Leitwerksvolumen-Koeffizient)
	var vt_yaw := 0.0
	var canard_penalty := 0.0  # Anteil, den Canards "wegnehmen" (für Hinweistext)

	for s in surfaces:
		var n := s.normal.normalized()
		var l := s.position.z - cg.z                  # + hinten, − vorne
		var k := s.area_m2 * s.lift_slope() * s.efficiency
		var ny2 := n.y * n.y                          # wirkt im Nicken
		var nx2 := n.x * n.x                          # wirkt im Gieren
		pitch_slope += k * ny2 * l
		yaw_slope += k * nx2 * l
		vt_pitch += s.area_m2 * ny2 * l / V
		vt_yaw += s.area_m2 * nx2 * l / V
		if l < 0.0 or s.kind == ControlSurface.Kind.CANARD:
			canard_penalty += absf(k * (ny2 + nx2) * l)

	var ratio_pitch := pitch_slope / munk_slope if munk_slope > 0.0 else 99.0
	var ratio_yaw := yaw_slope / munk_slope if munk_slope > 0.0 else 99.0
	var worst := minf(ratio_pitch, ratio_yaw)

	var level := Level.OK
	var msg := MSG_OK
	if worst < THRESHOLD_MARGINAL:
		level = Level.UNSTABLE
		msg = MSG_UNSTABLE
	elif worst < THRESHOLD_STABLE:
		level = Level.MARGINAL
		msg = MSG_MARGINAL

	# Zusatzhinweis: welche Achse ist das Problem, und wie viel Fläche fehlt?
	var detail := ""
	if level != Level.OK:
		var axis := "Nick" if ratio_pitch <= ratio_yaw else "Gier"
		detail = "Schwächste Achse: %s (Stabilitätsmaß %.2f)." % [axis, worst]
		if canard_penalty > 0.0:
			detail += " Canards verringern die Stabilität."

	return {
		"level": level,
		"message": msg,
		"detail": detail,
		"ratio_pitch": ratio_pitch,
		"ratio_yaw": ratio_yaw,
		"vt_pitch": vt_pitch,
		"vt_yaw": vt_yaw,
		"munk_slope": munk_slope,
	}


## Fehlende Fläche (m²) am Heck, um in der schwächsten Achse "stabil" zu werden.
## Praktisch für einen "Leitwerk anpassen"-Knopf im Editor.
static func required_extra_area(result: Dictionary, tail_lever_m: float,
		cl_alpha_eta: float = 2.7) -> float:
	var worst := minf(result.ratio_pitch, result.ratio_yaw)
	if worst >= THRESHOLD_STABLE or tail_lever_m <= 0.0:
		return 0.0
	var missing_slope: float = (THRESHOLD_STABLE - worst) * result.munk_slope
	return missing_slope / (cl_alpha_eta * tail_lever_m)
