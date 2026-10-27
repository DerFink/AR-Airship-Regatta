# 2026-10-27 23:28 – Pseudo-Flex auch für Pendelleitwerke erlaubt (schaltbar)
# 2026-10-27 15:09 – Erstversion: symmetrisches Leitwerk als Konfiguration (1–8 Flossen; Anordnungen +, ×, Y, λ, gleichmäßig), Bauart Klappe/Pendel, Fläche, Streckung, Pfeilung (Zuspitzung), V-Winkel, optional getrennte Flächen für Höhen- und Seitenleitwerk
# =============================================================================
# TailConfig.gd
# -----------------------------------------------------------------------------
# Das Leitwerk wird nicht Flosse für Flosse gebaut, sondern als EINE
# symmetrische Anordnung beschrieben (wie im LTA-Luftschiffsimulator).
# generate() erzeugt daraus die einzelnen ControlSurface-Flossen.
#
# Winkel von hinten gesehen: 0° oben, 90° rechts, 180° unten, 270° links.
#
#   PLUS   +   4 Flossen: oben, rechts, unten, links
#   CROSS  ×   4 Flossen: diagonal (45°, 135°, 225°, 315°)
#   Y          3 Flossen: eine unten, zwei schräg oben (V-Winkel über waagrecht)
#   LAMBDA λ   3 Flossen: eine oben, zwei schräg unten (V-Winkel unter waagrecht)
#   EVEN       1–8 Flossen gleichmäßig verteilt, um "rotation_deg" gedreht
#
# "Höhen-/Seitenleitwerk getrennt": Flossen, die eher waagrecht stehen,
# bekommen area_h_m2, eher senkrechte area_v_m2.
# =============================================================================
class_name TailConfig
extends Resource

enum Layout { PLUS, CROSS, Y, LAMBDA, EVEN }

const LAYOUT_NAMES := ["+", "×", "Y", "λ", "gleichm."]

@export var layout: Layout = Layout.PLUS
## Anzahl der Flossen – nur bei EVEN frei (1–8), sonst durch die Anordnung fest.
@export_range(1, 8, 1) var count: int = 4
## Y/λ: Neigung der beiden Schrägflossen gegen die Waagrechte.
@export_range(0.0, 85.0, 1.0) var v_angle_deg: float = 45.0
## EVEN: Drehung der ganzen Anordnung.
@export_range(0.0, 359.0, 1.0) var rotation_deg: float = 0.0
@export var kind: ControlSurface.Kind = ControlSurface.Kind.FLAP
## Fläche JE FLOSSE in m².
@export_range(0.002, 50.0, 0.001, "or_greater") var area_m2: float = 0.08
@export var split_hv: bool = false
@export_range(0.002, 50.0, 0.001, "or_greater") var area_h_m2: float = 0.08
@export_range(0.002, 50.0, 0.001, "or_greater") var area_v_m2: float = 0.08
## Streckung (Spannweite² / Fläche).
@export_range(0.3, 6.0, 0.1) var aspect_ratio: float = 1.5
## Pfeilung wie im LTA-Simulator = Zuspitzung: Endtiefe / Wurzeltiefe.
@export_range(0.2, 1.0, 0.05) var taper: float = 1.0
## Längsposition des Druckpunkts (0 = Nase, 1 = Heck).
@export_range(0.5, 1.0, 0.01) var hull_x: float = 0.90
@export_range(0.0, 45.0, 1.0) var max_deflection_deg: float = 25.0
@export var pseudo_flex: bool = false


## Effektive Flossenzahl je nach Anordnung.
func fin_count() -> int:
	match layout:
		Layout.PLUS, Layout.CROSS: return 4
		Layout.Y, Layout.LAMBDA: return 3
	return clampi(count, 1, 8)


## Umfangswinkel aller Flossen (Grad, von hinten gesehen).
func angles() -> Array[float]:
	var v := v_angle_deg
	match layout:
		Layout.PLUS: return [0.0, 90.0, 180.0, 270.0]
		Layout.CROSS: return [45.0, 135.0, 225.0, 315.0]
		Layout.Y: return [180.0, 90.0 - v, 270.0 + v]
		Layout.LAMBDA: return [0.0, 90.0 + v, 270.0 - v]
	var n := fin_count()
	# Zwei Flossen ohne Drehung liegen waagrecht (klassisches Höhenleitwerk)
	var offset := rotation_deg + (90.0 if n == 2 else 0.0)
	var out: Array[float] = []
	for i in n:
		out.append(fposmod(offset + 360.0 * i / n, 360.0))
	return out


## Steht eine Flosse bei diesem Winkel eher waagrecht (Höhenleitwerk)?
static func is_horizontal(angle_deg: float) -> bool:
	var a := deg_to_rad(angle_deg)
	return absf(sin(a)) >= absf(cos(a)) - 0.001


## Fläche einer Flosse bei diesem Winkel.
func area_for(angle_deg: float) -> float:
	if not split_hv:
		return area_m2
	return area_h_m2 if is_horizontal(angle_deg) else area_v_m2


## Name für die Teileliste.
static func fin_name(angle_deg: float) -> String:
	var names := {0: "oben", 45: "oben rechts", 90: "rechts", 135: "unten rechts",
		180: "unten", 225: "unten links", 270: "links", 315: "oben links"}
	var key := int(round(angle_deg / 45.0)) * 45 % 360
	return "Leitwerk " + names.get(key, "%d°" % roundi(angle_deg))


## Erzeugt die Flossen (noch nicht am Rumpf platziert – das macht
## AirshipPhysics.rebuild_mass_properties()).
func generate() -> Array[ControlSurface]:
	var out: Array[ControlSurface] = []
	for a in angles():
		var s := ControlSurface.new()
		s.display_name = fin_name(a)
		s.kind = kind
		s.tail_member = true
		s.hull_x = hull_x
		s.hull_angle_deg = a
		s.area_m2 = area_for(a)
		s.aspect_ratio = aspect_ratio
		s.taper = taper
		s.max_deflection_deg = max_deflection_deg
		s.pseudo_flex = pseudo_flex
		out.append(s)
	return out
