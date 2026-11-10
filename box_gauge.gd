# 2026-11-11 02:20 – Maßzahlen liegen wie in der technischen Zeichnung neben der Maßlinie in der Wand-/Bodenebene; Striche im Körpersystem ausgerichtet
# 2026-11-11 02:00 – Schwerpunkt mit Abstand zur Stirnwand (x_S) und zum Boden (y_S); Wände gleichmäßig hell (unbeleuchtet) mit sichtbarem 10-cm-Raster; größere Maßzahlen
# 2026-11-11 01:10 – Erstversion: Boxmaß im Baukasten – das Luftschiff steht in einer Ecke (Seite an der Rückwand, Heck an der Stirnwand, unten auf dem Boden); Länge, Breite und Höhe sind wie in einer technischen Zeichnung mit Maßlinien, Pfeilen und Maßzahlen an Wände und Boden gezeichnet
# =============================================================================
# BoxGauge.gd  (Kind-Node des Luftschiffs, Koordinaten im Körpersystem)
# -----------------------------------------------------------------------------
# So wird vor dem Rennen gemessen: Schiff in eine Ecke schieben, dann sind
# Länge, Breite und Höhe des umhüllenden Quaders direkt ablesbar.
#
#   Blick von der Seite (Kamera rechts vom Schiff):
#
#        |<──────────── L = 2,60 m ────────────>|        Rückwand (Schiff links
#      ┬ ┌─────────────────────────────────────┐|        liegt an), Raster 10 cm
#      H │        ══════ Luftschiff ══════      │|  ← Stirnwand (Heck liegt an)
#      ┴ └─────────────────────────────────────┘|
#   ═══════════ Boden ══════ B = 0,52 m (quer) ═══
#
# Körpersystem: −Z = Nase, +Z = Heck, +X = rechts, +Y = oben.
# =============================================================================
class_name BoxGauge
extends Node3D

## Ausdehnung von Ecke und Maßen (Körpersystem) – für Kameraabstand und Bildmitte
var extent := AABB()

const GRID_M := 0.10                     ## Rasterweite auf Wänden und Boden
const INK := Color("1d2a3a")             ## Farbe der Maßlinien und Zahlen
var _paper: StandardMaterial3D           ## Wandmaterial mit Raster
var _ink: StandardMaterial3D


func _init() -> void:
	# Raster-„Papier“: eine Zelle mit dünnem Rand, wird je 10 cm wiederholt
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color("e9edf1"))
	for i in 64:
		for w in 2:
			img.set_pixel(i, w, Color("a9b6c4")); img.set_pixel(w, i, Color("a9b6c4"))
	_paper = StandardMaterial3D.new()
	_paper.albedo_texture = ImageTexture.create_from_image(img)
	_paper.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # gleichmäßig wie Papier
	_paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ink = StandardMaterial3D.new()
	_ink.albedo_color = INK
	_ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


## Ecke und Maße für den umhüllenden Quader box (Körpersystem) neu aufbauen.
## cg: Gesamtschwerpunkt im Körpersystem.
func rebuild(box: AABB, cg := Vector3.ZERO) -> void:
	for c in get_children(): c.queue_free()
	var x0 := box.position.x
	var x1 := box.end.x
	var y0 := box.position.y
	var y1 := box.end.y
	var z0 := box.position.z
	var z1 := box.end.z
	var L := box.size.z
	var B := box.size.x
	var H := box.size.y
	var m := maxf(L * 0.18, 0.25)                   # Rand um das Schiff
	var e := 0.003                                  # Abstand der Zeichnung vor der Wand
	var t := maxf(L * 0.006, 0.008)                 # Strichstärke (≈ 2 px im Bild)
	var fs := maxf(L * 0.05, 0.06)                  # Schrifthöhe (m)
	var mf := m * 1.7                               # vorne mehr Platz für die Maßzahlen
	extent = AABB(Vector3(x0, y0, z0 - mf), Vector3(B + 1.8 * m, H + m, L + mf))
	# --- Wände und Boden (Ecke) ---
	_plane(Vector3(x0, (y0 + y1 + m) * 0.5, (z0 - mf + z1) * 0.5), Vector2(L + mf, H + m), Basis(Vector3.UP, PI * 0.5))   # Rückwand (x = x0)
	_plane(Vector3((x0 + x1 + m) * 0.5, (y0 + y1 + m) * 0.5, z1), Vector2(B + m, H + m), Basis())                           # Stirnwand (z = z1)
	_plane(Vector3((x0 + x1 + 1.8 * m) * 0.5, y0, (z0 - mf + z1) * 0.5), Vector2(B + 1.8 * m, L + mf), Basis(Vector3.RIGHT, -PI * 0.5))  # Boden (y = y0)
	var xw := x0 + e
	var yb := y0 + e
	# --- Länge L: über dem Schiff an der Rückwand ---
	var yl := y1 + m * 0.45
	_dim(Vector3(xw, yl, z0), Vector3(xw, yl, z1), t, "L = %s" % _m(L), fs, "above")
	_line(Vector3(xw, y1, z0), Vector3(xw, yl + m * 0.12, z0), t * 0.6)      # Hilfslinien
	_line(Vector3(xw, y1, z1), Vector3(xw, yl + m * 0.12, z1), t * 0.6)
	# --- Höhe H (innen, Zahl darüber) und Schwerpunkthöhe y_S (außen, Zahl rechts) vor der Nase ---
	var zh := z0 - m * 0.45
	var zy := zh - m * 0.45
	_line(Vector3(xw, y0 + e, z0), Vector3(xw, y0 + e, zy - m * 0.1), t * 0.6)
	_line(Vector3(xw, y1, z0), Vector3(xw, y1, zh - m * 0.1), t * 0.6)
	_dim(Vector3(xw, y0, zh), Vector3(xw, y1, zh), t, "H = %s" % _m(H), fs, "top")
	# Schwerpunkt S: Zeichen auf der Rückwand (wegen der Symmetrie liegt er in der Mittelebene)
	var xs := xw + e
	_cross(Vector3(xs, cg.y, cg.z), maxf(L * 0.02, 0.03), t)
	_line(Vector3(xs, cg.y, cg.z), Vector3(xs, cg.y, zy - m * 0.1), t * 0.4)     # Hilfslinie Höhe von S
	_dim(Vector3(xw, y0, zy), Vector3(xw, cg.y, zy), t * 0.8, "y_S = %s" % _m(cg.y - y0), fs * 0.85, "right")
	# --- Abstand des Schwerpunkts zur Stirnwand x_S: auf dem Boden vor dem Schiff ---
	var xf := x1 + m * 0.5
	_line(Vector3(x0, yb, cg.z), Vector3(xf + m * 0.08, yb, cg.z), t * 0.5)      # Lot von S auf den Boden
	_line(Vector3(xs, y0, cg.z), Vector3(xs, cg.y, cg.z), t * 0.4)
	_dim(Vector3(xf, yb, cg.z), Vector3(xf, yb, z1), t * 0.8, "x_S = %s" % _m(z1 - cg.z), fs * 0.85, "near")
	# --- Breite B: auf dem Boden vor der Nase (quer zur Längsachse) ---
	var zb := z0 - m * 0.9
	_dim(Vector3(x0, yb, zb), Vector3(x1, yb, zb), t, "B = %s" % _m(B), fs, "right")
	_line(Vector3(x1, yb, zb - m * 0.08), Vector3(x1, yb, z0), t * 0.5)


## Wandfläche mit Raster (Rasterweite GRID_M).
func _plane(center: Vector3, sz: Vector2, b: Basis) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = sz
	mi.mesh = q
	var mat := _paper.duplicate() as StandardMaterial3D
	mat.uv1_scale = Vector3(sz.x / GRID_M, sz.y / GRID_M, 1.0)
	mi.material_override = mat
	mi.position = center
	mi.basis = b
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Maßlinie von a nach b mit Pfeilspitzen und Maßzahl (Label zeigt zur Kamera).
## where: Lage der Maßzahl zur Linie aus Sicht der Kamera – "above" (darüber),
## "left"/"right" (daneben), "near" (zur Kamera hin, unter der Linie).
## Die Zahl steht waagrecht und immer lesbar (zur Kamera gedreht) und wird
## nicht von Wand oder Boden verdeckt.
func _dim(a: Vector3, b: Vector3, t: float, text: String, fs: float, where: String) -> void:
	_line(a, b, t)
	var d := (b - a).normalized()
	var al := clampf(a.distance_to(b) * 0.06, 0.02, 0.08)
	_arrow(a, d, al, t)
	_arrow(b, -d, al, t)
	var lab := Label3D.new()
	lab.text = text
	lab.pixel_size = fs / 48.0
	lab.font_size = 48
	lab.outline_size = 8
	lab.modulate = INK
	lab.outline_modulate = Color("e9edf1")
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	var mid := (a + b) * 0.5
	# Kamera rechts vom Schiff: Bild rechts = −Z (Nase), Bild links = +Z, zur Kamera = +X
	match where:
		"above":
			lab.position = mid + Vector3(0, fs * 0.75, 0)
		"top":
			lab.position = b + Vector3(0, fs * 0.8, 0)
		"right":
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lab.position = mid + Vector3(0, 0, -fs * 0.4)
		"left":
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lab.position = mid + Vector3(0, 0, fs * 0.4)
		_:
			lab.position = mid + Vector3(fs * 0.9, 0, 0)
	add_child(lab)


## Schwerpunkt-Zeichen: Kreuz mit Kreis (in der Wandebene x = const).
func _cross(p: Vector3, r: float, t: float) -> void:
	_line(p + Vector3(0, -r, 0), p + Vector3(0, r, 0), t)
	_line(p + Vector3(0, 0, -r), p + Vector3(0, 0, r), t)
	var n := 16
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		_line(p + Vector3(0, sin(a0), cos(a0)) * r * 0.7, p + Vector3(0, sin(a1), cos(a1)) * r * 0.7, t * 0.8)


## Strich als dünner Quader von a nach b.
func _line(a: Vector3, b: Vector3, t: float) -> void:
	var len := a.distance_to(b)
	if len < 1e-4: return
	var mi := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(t, t, len)
	mi.mesh = bx
	mi.material_override = _ink
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# lokal ausrichten (look_at_from_position rechnet global – das Schiff ist aber gedreht)
	mi.position = (a + b) * 0.5
	mi.basis = Basis.looking_at(b - a, Vector3.UP if absf((b - a).normalized().y) < 0.95 else Vector3.RIGHT)


## Pfeilspitze an p, zeigt in Richtung -dir (nach außen auf die Hilfslinie).
func _arrow(p: Vector3, dir: Vector3, len: float, t: float) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = maxf(len * 0.32, t * 1.5)
	c.height = len
	mi.mesh = c
	mi.material_override = _ink
	add_child(mi)
	# Zylinder-Achse (lokal +Y) zeigt von der Grundfläche zur Spitze → Spitze an p
	var y := -dir
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	mi.basis = Basis(x, y, z)
	mi.position = p - y * len * 0.5


static func _m(v: float) -> String:
	return ("%.2f m" % v).replace(".", ",")
