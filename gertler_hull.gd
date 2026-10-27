# 2026-10-27 11:08 – Mesh mit Texturkoordinaten (u längs, v rund um die Hülle) für Schriftzug und Logo
# 2026-10-27 10:20 – Erstversion: Gertler-Polynom (DTMB Series 58), Volumen-Skalierung, Auftriebszentrum, Lamb-Koeffizienten, Mesh-Generator
# =============================================================================
# GertlerHull.gd
# -----------------------------------------------------------------------------
# Erzeugt die Rumpfform eines Luftschiffs nach den Gertler-Formeln
# (DTMB Report 1468, "Series 58"). Die Kontur ist ein Polynom 6. Grades:
#
#     y(x)^2 = a1*x + a2*x^2 + ... + a6*x^6
#
#   x = Längsposition / Rumpflänge          (0 = Nase, 1 = Heck)
#   y = lokaler Radius  / Max.-Durchmesser  (Maximum = 0,5)
#
# Die 6 Koeffizienten a1..a6 ergeben sich aus 6 Formparametern:
#   m   – Lage des größten Durchmessers (Anteil der Länge)
#   r0  – dimensionsloser Nasenradius   r0 = R_Nase * L / D^2
#   r1  – dimensionsloser Heckradius    r1 = R_Heck * L / D^2
#   cp  – Prismenkoeffizient (Völligkeit: Volumen / Zylindervolumen)
#   + Randbedingungen: y(1)=0, y(m)=0,5, y'(m)=0
#
# Daraus berechnet diese Klasse zusätzlich alles, was die Physik braucht:
# Länge/Durchmesser aus Volumen, Auftriebszentrum, Lamb-Koeffizienten
# (virtuelle Massen) und ein 3D-Mesh für die Darstellung.
# =============================================================================
class_name GertlerHull
extends Resource

## Wird ausgelöst, wenn sich die Form geändert hat (Editor aktualisiert Vorschau).
signal shape_changed

# --- Formparameter -----------------------------------------------------------
# Standard-Preset: Näherung an USS Albacore (AGSS-569).
# HINWEIS: Werte vor Release gegen die Series-58-Tabelle prüfen (Modell 4621).
@export_range(0.2, 0.6, 0.01) var m: float = 0.40:
	set(v): m = v; _rebuild()
@export_range(0.0, 1.0, 0.01) var r0: float = 0.50:
	set(v): r0 = v; _rebuild()
@export_range(0.0, 0.5, 0.01) var r1: float = 0.00:
	set(v): r1 = v; _rebuild()
@export_range(0.5, 0.75, 0.005) var cp: float = 0.65:
	set(v): cp = v; _rebuild()

# --- Größenparameter ---------------------------------------------------------
## Schlankheitsgrad Länge/Durchmesser (Standard 5).
@export_range(2.0, 12.0, 0.1) var length_to_diameter: float = 5.0:
	set(v): length_to_diameter = v; _rebuild()
## Hüllenvolumen in m³ (Standard 0,25 m³, nach oben offen).
@export_range(0.01, 10000.0, 0.01, "or_greater") var volume_m3: float = 0.25:
	set(v): volume_m3 = v; _rebuild()

# --- Abgeleitete Größen (nur lesen) ------------------------------------------
var coeffs: PackedFloat64Array = PackedFloat64Array([0, 0, 0, 0, 0, 0])
var length_m: float = 0.0          ## Rumpflänge L
var diameter_m: float = 0.0        ## Max. Durchmesser D
var cb_from_nose: float = 0.0      ## Auftriebszentrum, Abstand von der Nase in m
var k1: float = 0.0                ## Lamb-Koeffizient längs (axial)
var k2: float = 0.0                ## Lamb-Koeffizient quer
var k_rot: float = 0.0             ## Lamb-Koeffizient Drehung (Nick/Gier)


func _init() -> void:
	_rebuild()


# =============================================================================
# Neuberechnung aller abgeleiteten Größen
# =============================================================================
func _rebuild() -> void:
	_solve_coefficients()
	# Volumen V = π · D² · L · cp / 4   mit  L = λ · D
	# → D = (4V / (π · λ · cp))^(1/3)
	diameter_m = pow(4.0 * volume_m3 / (PI * length_to_diameter * cp), 1.0 / 3.0)
	length_m = length_to_diameter * diameter_m
	cb_from_nose = _centroid() * length_m
	_compute_lamb()
	shape_changed.emit()


# -----------------------------------------------------------------------------
# Löst das lineare 6×6-Gleichungssystem für a1..a6 (Gauß mit Pivotsuche).
# Jede Zeile ist eine Bedingung an das Polynom f(x) = y².
# -----------------------------------------------------------------------------
func _solve_coefficients() -> void:
	var A: Array = []
	var b: Array = []
	# 1) Nasenradius:   f'(0) = a1 = 2·r0
	A.append([1.0, 0.0, 0.0, 0.0, 0.0, 0.0]); b.append(2.0 * r0)
	# 2) Heckspitze:    f(1) = 0
	A.append([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]); b.append(0.0)
	# 3) Max.-Radius:   f(m) = 0,25  (y = 0,5)
	var row3 := []
	for k in range(1, 7): row3.append(pow(m, k))
	A.append(row3); b.append(0.25)
	# 4) Waagrechte Tangente bei m:  f'(m) = 0
	var row4 := []
	for k in range(1, 7): row4.append(k * pow(m, k - 1))
	A.append(row4); b.append(0.0)
	# 5) Heckradius:    f'(1) = -2·r1
	A.append([1.0, 2.0, 3.0, 4.0, 5.0, 6.0]); b.append(-2.0 * r1)
	# 6) Völligkeit:    ∫ f dx = cp / 4
	var row6 := []
	for k in range(1, 7): row6.append(1.0 / (k + 1))
	A.append(row6); b.append(cp / 4.0)

	var x := _gauss(A, b)
	for i in 6:
		coeffs[i] = x[i]


## Gauß-Elimination mit Spalten-Pivotisierung (klein, aber numerisch robust).
static func _gauss(A: Array, b: Array) -> Array:
	var n := b.size()
	for i in n:
		var p := i
		for r in range(i + 1, n):
			if absf(A[r][i]) > absf(A[p][i]): p = r
		var tmp = A[i]; A[i] = A[p]; A[p] = tmp
		var tb = b[i]; b[i] = b[p]; b[p] = tb
		for r in range(i + 1, n):
			var f: float = A[r][i] / A[i][i]
			for c in range(i, n): A[r][c] -= f * A[i][c]
			b[r] -= f * b[i]
	var x := []
	x.resize(n)
	for i in range(n - 1, -1, -1):
		var s: float = b[i]
		for c in range(i + 1, n): s -= A[i][c] * x[c]
		x[i] = s / A[i][i]
	return x


# =============================================================================
# Geometrie-Abfragen (werden von Physik, Validator und Mesh genutzt)
# =============================================================================

## Dimensionsloses y² an der Stelle x (0..1). Negative Werte werden abgeschnitten.
func y_squared(x: float) -> float:
	var s := 0.0
	var xp := x
	for i in 6:
		s += coeffs[i] * xp
		xp *= x
	return maxf(s, 0.0)


## Lokaler Radius in Metern an der Längsposition x (0 = Nase, 1 = Heck).
func radius_at(x: float) -> float:
	return sqrt(y_squared(clampf(x, 0.0, 1.0))) * diameter_m


## Schwerpunkt der Volumenverteilung = Auftriebszentrum (dimensionslos).
func _centroid(samples: int = 400) -> float:
	var num := 0.0
	var den := 0.0
	for i in samples + 1:
		var x := float(i) / samples
		var v := y_squared(x)
		num += x * v
		den += v
	return num / den if den > 0.0 else 0.5


# -----------------------------------------------------------------------------
# Lamb-Koeffizienten des äquivalenten Rotationsellipsoids.
# Sie beschreiben, wie viel umgebende Luft beim Beschleunigen "mitgezogen"
# wird (virtuelle Masse) und sind zugleich die Quelle des Munk-Moments.
# -----------------------------------------------------------------------------
func _compute_lamb() -> void:
	var lam := length_to_diameter
	var e := sqrt(1.0 - 1.0 / (lam * lam))      # Exzentrizität
	var L := log((1.0 + e) / (1.0 - e))
	var a0 := 2.0 * (1.0 - e * e) / pow(e, 3) * (0.5 * L - e)
	var b0 := 1.0 / (e * e) - (1.0 - e * e) / (2.0 * pow(e, 3)) * L
	k1 = a0 / (2.0 - a0)
	k2 = b0 / (2.0 - b0)
	# Drehträgheits-Koeffizient (Lamb), Näherung für prolate Ellipsoide
	var e4 := pow(e, 4)
	k_rot = e4 * (b0 - a0) / ((2.0 - e * e) * (2.0 * e * e - (2.0 - e * e) * (b0 - a0)))


# =============================================================================
# 3D-Mesh: Rotationskörper entlang der lokalen -Z-Achse (Godot "vorwärts").
# Ursprung des Meshes liegt im Auftriebszentrum, damit Physik und Grafik
# denselben Bezugspunkt haben.
# =============================================================================
func build_mesh(rings: int = 48, segments: int = 24) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		var x0 := float(i) / rings
		var x1 := float(i + 1) / rings
		# z = Abstand hinter dem Auftriebszentrum (+Z = hinten, -Z = vorne/Nase)
		var z0 := x0 * length_m - cb_from_nose
		var z1 := x1 * length_m - cb_from_nose
		var r0m := radius_at(x0)
		var r1m := radius_at(x1)
		for j in segments:
			var a0 := TAU * j / segments
			var a1 := TAU * (j + 1) / segments
			var p00 := Vector3(cos(a0) * r0m, sin(a0) * r0m, z0)
			var p01 := Vector3(cos(a1) * r0m, sin(a1) * r0m, z0)
			var p10 := Vector3(cos(a0) * r1m, sin(a0) * r1m, z1)
			var p11 := Vector3(cos(a1) * r1m, sin(a1) * r1m, z1)
			# Texturkoordinaten für die Gestaltung (siehe LiveryCanvas):
			#   u = 1 − x  → links Heck, rechts Nase
			#   v = 0,75 − Winkel/360° → rechte Seite 0,75, oben 0,5, links 0,25,
			#   Naht unten (Werte < 0 wiederholen sich über die Textur)
			var u0 := 1.0 - x0
			var u1 := 1.0 - x1
			var v0 := 0.75 - float(j) / segments
			var v1 := 0.75 - float(j + 1) / segments
			# Reihenfolge im Uhrzeigersinn von außen = Godot-Vorderseite
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(p10)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(p01)
	st.generate_normals()
	return st.commit()
