# 2026-11-15 23:10 – Glasdach 18 m statt 15 m; dunkelgrauer Bodenstrich an der Säulenlinie
# 2026-11-15 22:50 – Halle neu nach Foto: Glasdach 15 m; Säulenreihe (fest) mit 5 m tiefen Laufgängen rundum auf zwei Ebenen (0–5, 5–10 m, hineinfliegen möglich, Zwischendecke und Geländer fest); 10–15 m an der Säulenlinie geschlossen mit Wandbildern und großen Plakaten
# 2026-11-15 21:40 – Fehler grünes Flackern: Gras liegt in der Halle 20 cm unter dem Hallenboden (vorher 4 mm → Z-Fighting)
# 2026-11-12 11:00 – race_factor(): Rennfaktor ∛(L·B·H·π/6) für Modellliste und Kennwerte
# 2026-11-11 16:35 – Rennanzeige oben links nur noch nächster Kontrollpunkt; current_lap_time(), hint_text(), scored_time() (F7B: Gesamtzeit × ∛(L·B·H·π/6))
# 2026-11-11 12:15 – aerarium-Plakate an allen vier Hallenwänden: große oben (weiße Wand über der 2. Galerie), kleine unten an den Glastüren; Seitenverhältnis kommt aus dem Bild, nie gestreckt
# 2026-11-11 17:45 – Anzeige-Texte (Runde, Ziel, nächster Kontrollpunkt) übersetzt; Zeiten mit Dezimalzeichen je Sprache
# 2026-11-10 14:00 – Location „Halle“ / „Wiese“ (Wiese: keine Wände/Decke, Pylonabstand Vorgabe 200 m); Pylonabstand frei 5–500 m; Halle nachgebildet nach Fotos der Windreiter-Halle (Glasdach mit Holzraster, Band mit Horizont-Wandbildern, zwei Galerien mit Geländer, weiße Säulen, Glastüren, dunkler glänzender Boden)
# 2026-11-09 09:45 – Halle: Wände 10 m außerhalb des weißen Rechtecks, Decke 25 m, halb durchsichtig mit 5-m-Raster, Luftschiff prallt ab
# 2026-10-29 00:19 – course_key() für die Bestenliste
# 2026-10-28 15:12 – Start in 1,5 m Höhe
# 2026-10-28 09:02 – Startlage 1 m neben dem vorderen Pylon (Pilotenseite) statt genau davor
# 2026-10-28 08:51 – Acht um beide Pylone: 4 Kontrollpunkte mit Seite und Richtung, falsche Durchgänge zählen nicht (weiterfliegen bis korrekt), Rundenzeiten; hinterer Pylon grün auf Höhe von Pylon 2 als Kurvensignal
# 2026-10-28 08:14 – Erstversion: Strecke mit zwei Pylonen (Abstand einstellbar, Vorgabe „FN Hugo Eckener Cup“ = 18 m), weißes Rechteck (Pylonabstand + 2 × 3,5 m lang, 20 m breit), Farbwechsel des hinteren Pylons, Rundenzähler (3 Runden) mit fliegendem Start
# =============================================================================
# Course.gd  (Kind-Node der Hauptszene)
# -----------------------------------------------------------------------------
# Draufsicht (x = Streckenrichtung, z = quer):
#
#     ┌──────────────────────────────────────────┐  ← weißes Rechteck, 20 m breit
#     │  ●  vorderer Pylon (x = 0)        ●  hinterer Pylon (x = Abstand)
#     │   ☺ Pilot                                │
#     └──────────────────────────────────────────┘
#     3,5 m vor Pylon 1 bis 3,5 m hinter Pylon 2
#
# Rennablauf – eine Acht um beide Pylone (fliegender Start, 3 Runden):
#
#        4 ←─────────╮            ╭──────── 2 →
#     ╭─ │ ─╮         ╲          ╱       ╭─ │ ─╮
#     │  ● P1          ╳ (Mitte)          P2 ●  │      z < 0: dem Piloten abgewandt
#     ╰─ │ ─╯         ╱          ╲       ╰─ │ ─╯      z > 0: Pilotenseite
#        1 →─────────╯            ╰──────── ← 3
#
#   Kontrollpunkte (Linie quer durch einen Pylon, Seite, Richtung):
#     1  Pylon 1, Pilotenseite, Richtung Pylon 2   = Start/Ziel
#     2  Pylon 2, abgewandte Seite, weg von Pylon 1
#     3  Pylon 2, Pilotenseite, zurück zu Pylon 1
#     4  Pylon 1, abgewandte Seite, weg von Pylon 2
#   Sie müssen in dieser Reihenfolge überflogen werden. Ein Durchgang auf der
#   falschen Seite oder in falscher Richtung zählt nicht – der Pilot muss so
#   lange fliegen, bis der Pylon korrekt umrundet ist. Erst wenn nach Runde 3
#   wieder Punkt 1 (Ziellinie) überflogen wird, steht die Zeit.
#
# Anzeige für den Piloten: Der hintere Pylon wird grün, sobald der Bug auf
# seiner Höhe ist (Linie durch Pylon 2, egal welche Seite) – Zeichen zum
# Einleiten der Kurve. Über die Linie durch Pylon 1 wird er wieder rot.
# =============================================================================
class_name Course
extends Node3D

## Runde begonnen/fertig, Zeit gestartet/gestoppt → HUD neu beschriften
signal race_changed

enum Race { WAIT, RUN, DONE }

const CUP_NAME := "FN Hugo Eckener Cup"
const CUP_DISTANCE := 18.0
const MIN_DISTANCE := 5.0
const MAX_DISTANCE := 500.0
const MEADOW_DISTANCE := 200.0   ## Vorgabe Pylonabstand auf der Wiese
const LOCATION_NAMES := ["Halle", "Wiese"]
const PYLON_HEIGHT := 5.0
const FIELD_MARGIN := 3.5        ## Rechteck reicht so weit vor/hinter die Pylone
const FIELD_WIDTH := 20.0
## Halle: Säulenlinie 10 m außerhalb des weißen Rechtecks, Glasdach in 18 m Höhe.
## Hinter den Säulen rundum ein 5 m tiefer Laufgang auf zwei Ebenen (0–5 und
## 5–10 m, hineinfliegen möglich); darüber ist die Halle an der Säulenlinie zu.
const HALL_GAP := 10.0
const HALL_HEIGHT := 18.0
const LEVEL_HEIGHT := 5.0       ## Höhe einer Ebene
const WALK_DEPTH := 5.0         ## Tiefe der Laufgänge hinter den Säulen
const SLAB := 0.3               ## Dicke der Zwischendecken
const RAIL_H := 1.1             ## Geländerhöhe auf Ebene 2 (fest)
const COL_W := 0.8              ## Säulenquerschnitt
## aerarium-Plakate an den Hallenwänden (Bild: textures/aerarium_plakat.png)
const POSTER_TEX := "res://textures/aerarium_plakat.png"
const POSTER_BIG_H := 3.4       # Höhe der großen Plakate (m) auf der oberen Wand (10–15 m)
const POSTER_BIG_Y := 12.6      # Mitte der großen Plakate (m)
const POSTER_SMALL_H := 2.0     # Höhe der kleinen Plakate (m) an den Glastüren
const POSTER_SMALL_Y := 2.0     # Mitte der kleinen Plakate (m)
const POSTER_SPACING := 16.0    # Abstand zwischen zwei großen Plakaten (m) = 2 Säulenfelder
const POSTER_GAP := 0.06        # Abstand zur Wand (m), damit nichts flimmert
## Abprallen an Wänden und Decke (0 = kein Abprall, 1 = voll elastisch)
const HALL_BOUNCE := 0.6
const LINE_WIDTH := 0.10
const START_BEHIND := 1.0        ## Bug steht so weit hinter der Linie des vorderen Pylons
const START_BESIDE := 1.0        ## Abstand Hüllenseite ↔ vorderer Pylon (zur Pilotenseite hin)
const START_HEIGHT := 1.5        ## Schwebehöhe am Start (m)
const LAPS := 3
const SETTINGS_PATH := "user://strecke.cfg"

const COLOR_RED := Color("e5534b")
const COLOR_GREEN := Color("3fb27f")

## 0 = FN Hugo Eckener Cup (18 m), 1 = frei einstellbar
var preset := 0
## 0 = Halle (Wände und Decke), 1 = Wiese (keine Begrenzung)
var location := 0
## Wiesen-Boden (setzt main.gd). In der Halle liegt er 20 cm tiefer: vorher lag
## der Hallenboden nur 4 mm über dem grünen Gras – beide Flächen „kämpften“ um
## dieselbe Tiefe, das Gras blitzte grünlich durch (am Handy stark, wegen
## geringerer Tiefengenauigkeit im Browser).
var ground_mesh: MeshInstance3D
## Pylonabstand auf der Wiese (eigener Wert, Halle behält ihren)
var meadow_distance := MEADOW_DISTANCE
## Abstand bei „frei“ (m)
var free_distance := 25.0

var race := Race.WAIT
var lap := 0                     ## laufende Runde (1…LAPS)
var time_s := 0.0                ## Gesamtzeit seit dem Start
var far_green := false
var next_gate := 0               ## als Nächstes erwarteter Kontrollpunkt (0…3 = Punkt 1…4)
var lap_times: PackedFloat32Array = PackedFloat32Array()   ## fertige Runden
var _lap_start := 0.0
var _prev_nose := Vector2(NAN, NAN)   ## (x, z) des Bugs im letzten Schritt

## Kontrollpunkte: [Linie bei Pylon (0/1), Seite (+1 Piloten-, −1 abgewandt), Richtung (+1 = +x)]
const GATES := [[0, 1, 1], [1, -1, 1], [1, 1, -1], [0, -1, -1]]
const GATE_NAMES := ["Start/Ziel", "Pylon 2 außen", "Pylon 2 zurück", "Pylon 1 außen"]

var _far_mat := StandardMaterial3D.new()


func _ready() -> void:
	load_settings()
	rebuild()


## Aktueller Pylonabstand in m.
func distance() -> float:
	if location == 1:
		return meadow_distance
	return CUP_DISTANCE if preset == 0 else free_distance


## Name für die Anzeige.
## Schlüssel für die Bestenliste: eigene Liste je Strecke/Abstand.
func course_key() -> String:
	if location == 1:
		return "wiese_%.1f" % meadow_distance            # eigene Bestenliste je Abstand auf der Wiese
	return "cup" if preset == 0 else "frei_%.1f" % free_distance


func title() -> String:
	if location == 1:
		return I18n.t("Wiese %d m") % roundi(meadow_distance)
	return CUP_NAME if preset == 0 else I18n.t("Freie Strecke %d m") % roundi(free_distance)


# =============================================================================
# Pylone und Rechteck aufbauen (bei jeder Abstandsänderung)
# =============================================================================
func rebuild() -> void:
	for c in get_children(): c.queue_free()
	if ground_mesh:
		ground_mesh.position.y = -0.2 if location == 0 else 0.0
	var d := distance()
	var near_mat := StandardMaterial3D.new()
	near_mat.albedo_color = COLOR_RED
	_far_mat.albedo_color = COLOR_GREEN if far_green else COLOR_RED
	for i in 2:
		var py := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12; cyl.bottom_radius = 0.35; cyl.height = PYLON_HEIGHT
		py.mesh = cyl
		py.material_override = near_mat if i == 0 else _far_mat
		py.position = Vector3(0.0 if i == 0 else d, PYLON_HEIGHT * 0.5, 0.0)
		add_child(py)
	# Weißes Rechteck aus vier flachen Streifen knapp über dem Boden
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color.WHITE
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var x0 := -FIELD_MARGIN
	var x1 := d + FIELD_MARGIN
	var hw := FIELD_WIDTH * 0.5
	var strips := [
		[Vector3((x0 + x1) * 0.5, 0.01, -hw), Vector3(x1 - x0, 0.02, LINE_WIDTH)],
		[Vector3((x0 + x1) * 0.5, 0.01, hw), Vector3(x1 - x0, 0.02, LINE_WIDTH)],
		[Vector3(x0, 0.01, 0.0), Vector3(LINE_WIDTH, 0.02, FIELD_WIDTH)],
		[Vector3(x1, 0.01, 0.0), Vector3(LINE_WIDTH, 0.02, FIELD_WIDTH)],
	]
	for st in strips:
		var mi := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = st[1]
		mi.mesh = bx
		mi.material_override = lm
		mi.position = st[0]
		add_child(mi)
	if location == 0:
		_build_hall(x0 - HALL_GAP, x1 + HALL_GAP, hw + HALL_GAP)   # Wiese: keine Wände, keine Decke


# =============================================================================
# Halle (09.11.2026): vier Wände und Decke als Orientierung und Begrenzung.
# Die Flächen sind halb durchsichtig mit einem 5-m-Raster; das Luftschiff prallt
# daran ab (Abprall-Material nur an Wänden/Decke, der Boden bleibt ohne Abprall).
# =============================================================================
func _build_hall(xa: float, xb: float, hz: float) -> void:
	# Innenraum (Atrium): xa…xb, −hz…hz – dort stehen die Säulen. Dahinter rundum
	# ein Laufgang (WALK_DEPTH) auf zwei Ebenen (0–5 m und 5–10 m); darüber ist
	# die Halle an der Säulenlinie geschlossen (Wand mit Wandbildern und Logos).
	var hall := StaticBody3D.new()
	hall.name = "Halle"
	var pm := PhysicsMaterial.new()
	pm.bounce = HALL_BOUNCE
	pm.friction = 0.2
	hall.physics_material_override = pm
	add_child(hall)
	var D := WALK_DEPTH
	var H := HALL_HEIGHT
	var L := LEVEL_HEIGHT
	var cx := (xa + xb) * 0.5
	var lx := xb - xa                      # Innenraum
	var lz := 2.0 * hz
	var ox := lx + 2.0 * D                 # außen (mit Laufgang)
	var oz := lz + 2.0 * D
	var th := 1.0                          # Wanddicke (nur Kollision)
	var walk_top := 2.0 * L                # Laufgänge bis 10 m
	# --- Kollision -------------------------------------------------------------
	var boxes := [
		# Außenwände hinter den Laufgängen (0–10 m)
		[Vector3(xa - D - th * 0.5, walk_top * 0.5, 0), Vector3(th, walk_top, oz + 2 * th)],
		[Vector3(xb + D + th * 0.5, walk_top * 0.5, 0), Vector3(th, walk_top, oz + 2 * th)],
		[Vector3(cx, walk_top * 0.5, -hz - D - th * 0.5), Vector3(ox, walk_top, th)],
		[Vector3(cx, walk_top * 0.5, hz + D + th * 0.5), Vector3(ox, walk_top, th)],
		# obere, geschlossene Wand an der Säulenlinie (10–15 m)
		[Vector3(xa - th * 0.5, (walk_top + H) * 0.5, 0), Vector3(th, H - walk_top, lz + 2 * th)],
		[Vector3(xb + th * 0.5, (walk_top + H) * 0.5, 0), Vector3(th, H - walk_top, lz + 2 * th)],
		[Vector3(cx, (walk_top + H) * 0.5, -hz - th * 0.5), Vector3(lx, H - walk_top, th)],
		[Vector3(cx, (walk_top + H) * 0.5, hz + th * 0.5), Vector3(lx, H - walk_top, th)],
		# Glasdach über dem Innenraum
		[Vector3(cx, H + th * 0.5, 0), Vector3(lx + 2 * th, th, lz + 2 * th)],
	]
	# Zwischendecke (5 m) und Decke der oberen Laufgänge (10 m) als Ring aus 4 Platten
	for y in [L, walk_top]:
		boxes.append_array(_ring_boxes(xa, xb, hz, D, y - SLAB * 0.5, SLAB))
	# Geländer an der Kante der Ebene 2 (fest – man kann hängenbleiben)
	boxes.append_array(_ring_edge(xa, xb, hz, L + RAIL_H * 0.5, RAIL_H, 0.1))
	# Säulen (fest, wie Wände) – bis 10 m, darüber geht die Wand durch
	var cols := _column_spots(xa, xb, hz)
	for c in cols:
		boxes.append([Vector3(c.x, walk_top * 0.5, c.y), Vector3(COL_W, walk_top, COL_W)])
	for bx in boxes:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = bx[1]
		cs.shape = sh
		cs.position = bx[0]
		hall.add_child(cs)
	# --- Aussehen (Windreiter-Halle) --------------------------------------------
	var shader := load("res://hall.gdshader") as Shader
	# Außenwände der Laufgänge (kind 2: Glastüren unten, Fenster oben); Vorderseite nach innen
	var outer := [
		[Vector3(cx, walk_top * 0.5, -hz - D), ox, 0.0],
		[Vector3(cx, walk_top * 0.5, hz + D), ox, PI],
		[Vector3(xa - D, walk_top * 0.5, 0), oz, PI * 0.5],
		[Vector3(xb + D, walk_top * 0.5, 0), oz, -PI * 0.5],
	]
	for w in outer:
		_wall_quad(shader, 2, w[0], Vector2(w[1], walk_top), w[2])
	# obere Wand an der Säulenlinie (kind 0: weiß, Lüftungsdüsen, Wandbilder)
	var upper := [
		[Vector3(cx, (walk_top + H) * 0.5, -hz), lx, 0.0],
		[Vector3(cx, (walk_top + H) * 0.5, hz), lx, PI],
		[Vector3(xa, (walk_top + H) * 0.5, 0), lz, PI * 0.5],
		[Vector3(xb, (walk_top + H) * 0.5, 0), lz, -PI * 0.5],
	]
	for w in upper:
		_wall_quad(shader, 0, w[0], Vector2(w[1], H - walk_top), w[2])
	# Glasdach über dem Innenraum, Vorderseite nach unten
	var ceil := MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2(lx, lz)
	ceil.mesh = cq
	var cmat := ShaderMaterial.new()
	cmat.shader = shader
	cmat.set_shader_parameter("size_m", Vector2(lx, lz))
	cmat.set_shader_parameter("kind", 1)
	ceil.material_override = cmat
	ceil.position = Vector3(cx, H, 0)
	ceil.rotation.x = PI * 0.5
	ceil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ceil)
	# Boden: dunkelgrauer, glänzender Steinboden bis unter die Laufgänge
	var floor_mi := MeshInstance3D.new()
	var fp := PlaneMesh.new()
	fp.size = Vector2(ox, oz)
	floor_mi.mesh = fp
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.13, 0.15, 0.17)
	fmat.roughness = 0.35
	fmat.metallic_specular = 0.35
	floor_mi.material_override = fmat
	floor_mi.position = Vector3(cx, 0.004, 0)
	add_child(floor_mi)
	# Dunkelgrauer Strich am Boden entlang der Säulenlinie (wo früher die Wand war)
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.07, 0.08, 0.09)
	line_mat.roughness = 0.6
	var lw := 0.15                                    # Strichbreite (m), mittig auf der früheren Wandlinie
	for bx in [
		[Vector3(cx, 0.012, -hz), Vector3(lx + lw, 0.016, lw)],
		[Vector3(cx, 0.012, hz), Vector3(lx + lw, 0.016, lw)],
		[Vector3(xa, 0.012, 0), Vector3(lw, 0.016, lz)],
		[Vector3(xb, 0.012, 0), Vector3(lw, 0.016, lz)]]:
		_box_mesh(bx, line_mat)
	# Zwischendecken (weiß) und Geländer (Glas mit dunklem Handlauf)
	var slab_mat := StandardMaterial3D.new()
	slab_mat.albedo_color = Color(0.86, 0.86, 0.85)
	slab_mat.roughness = 0.8
	# Unterseiten bekommen kaum Licht und wirkten braun → leicht selbstleuchtend (wie beleuchtete Decken)
	slab_mat.emission_enabled = true
	slab_mat.emission = Color(0.55, 0.56, 0.57)
	for y in [L, walk_top]:
		for bx in _ring_boxes(xa, xb, hz, D, y - SLAB * 0.5, SLAB):
			_box_mesh(bx, slab_mat)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.75, 0.85, 0.28)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for bx in _ring_edge(xa, xb, hz, L + RAIL_H * 0.5, RAIL_H, 0.05):
		_box_mesh(bx, glass)
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.25, 0.26, 0.28)
	for bx in _ring_edge(xa, xb, hz, L + RAIL_H, 0.06, 0.08):
		_box_mesh(bx, rail_mat)
	# Säulen: weiße Vierkantpfeiler
	var col_mat := StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.95, 0.95, 0.94)
	col_mat.roughness = 0.7
	for c in cols:
		_box_mesh([Vector3(c.x, walk_top * 0.5, c.y), Vector3(COL_W, walk_top, COL_W)], col_mat)
	_build_posters(xa, xb, hz)


## Vier Platten eines Rings zwischen Säulenlinie (innen) und Außenwand, Unterkante y0.
func _ring_boxes(xa: float, xb: float, hz: float, d: float, y0: float, t: float) -> Array:
	var cx := (xa + xb) * 0.5
	var y := y0 + t * 0.5
	var full := xb - xa + 2.0 * d
	return [
		[Vector3(cx, y, -hz - d * 0.5), Vector3(full, t, d)],
		[Vector3(cx, y, hz + d * 0.5), Vector3(full, t, d)],
		[Vector3(xa - d * 0.5, y, 0), Vector3(d, t, 2.0 * hz)],
		[Vector3(xb + d * 0.5, y, 0), Vector3(d, t, 2.0 * hz)],
	]


## Schmale Kante entlang der Säulenlinie (Geländer), Mitte in Höhe y.
func _ring_edge(xa: float, xb: float, hz: float, y: float, h: float, t: float) -> Array:
	var cx := (xa + xb) * 0.5
	var o := COL_W * 0.5 + t * 0.5           # knapp hinter der Säulenvorderkante
	return [
		[Vector3(cx, y, -hz - o), Vector3(xb - xa, h, t)],
		[Vector3(cx, y, hz + o), Vector3(xb - xa, h, t)],
		[Vector3(xa - o, y, 0), Vector3(t, h, 2.0 * hz)],
		[Vector3(xb + o, y, 0), Vector3(t, h, 2.0 * hz)],
	]


## Säulenplätze (x, z): Längsseiten alle 8 m (ab xa + 4), Stirnseiten alle 8 m
## symmetrisch zur Mitte, dazu die vier Ecken.
func _column_spots(xa: float, xb: float, hz: float) -> Array:
	var out := []
	var px := xa + 4.0
	while px < xb - 2.0:
		out.append(Vector2(px, -hz)); out.append(Vector2(px, hz))
		px += 8.0
	var n := int(floor((2.0 * hz - 4.0) / 8.0))
	for i in n + 1:
		var pz := (i - n * 0.5) * 8.0
		out.append(Vector2(xa, pz)); out.append(Vector2(xb, pz))
	for c in [Vector2(xa, -hz), Vector2(xa, hz), Vector2(xb, -hz), Vector2(xb, hz)]:
		out.append(c)
	return out


## Wandfläche mit dem Hallen-Shader (Vorderseite in Richtung Drehung).
func _wall_quad(shader: Shader, kind: int, at: Vector3, size_m: Vector2, rot_y: float) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size_m
	mi.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("size_m", size_m)
	mat.set_shader_parameter("kind", kind)
	mi.material_override = mat
	mi.position = at
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Sichtbarer Quader [Mitte, Größe].
func _box_mesh(bx: Array, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = bx[1]
	mi.mesh = b
	mi.material_override = mat
	mi.position = bx[0]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## aerarium-Plakate wie aufgehängt: große oben an der weißen Wand über der
## 2. Galerie, kleine unten an den Glastüren, dazwischen versetzt – so ist aus
## fast jeder Blickrichtung eins zu sehen. Die Breite ergibt sich immer aus der
## Höhe × Seitenverhältnis des Bildes, das Logo wird also nie verzerrt.
func _build_posters(xa: float, xb: float, hz: float) -> void:
	var tex := load(POSTER_TEX) as Texture2D
	if tex == null:
		return
	var aspect := float(tex.get_width()) / float(tex.get_height())
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# leicht selbstleuchtend, damit das Plakat auch im Schatten gut lesbar bleibt
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.35
	var cx := (xa + xb) * 0.5
	# [Mitte der Wand, Breite der Wand, Drehung, Richtung entlang der Wand, Säulen?]
	var walls := [
		[Vector3(cx, 0, -hz), xb - xa, 0.0, Vector3.RIGHT, true],
		[Vector3(cx, 0, hz), xb - xa, PI, Vector3.RIGHT, true],   # gleiche Richtung wie hinten, damit die Säulenlücken passen
		[Vector3(xa, 0, 0), 2.0 * hz, PI * 0.5, Vector3.BACK, false],
		[Vector3(xb, 0, 0), 2.0 * hz, -PI * 0.5, Vector3.FORWARD, false],
	]
	for w in walls:
		var basis := Basis(Vector3.UP, w[2])
		var normal: Vector3 = basis * Vector3.BACK          # zeigt in die Halle
		var along: Vector3 = w[3]
		var length: float = w[1]
		# Längswände: Plakate mittig zwischen zwei Säulen (Säulen bei xa+4+8k).
		# Stirnwände: gleichmäßig verteilt.
		var big_pos := _poster_slots(length, POSTER_SPACING, w[4], xa - cx if w[4] else 0.0)
		for i in big_pos.size():
			var d: float = big_pos[i]
			_poster(mat, aspect, POSTER_BIG_H, POSTER_BIG_Y, w[0] + along * d + normal * POSTER_GAP, basis)
			# kleines Plakat unten, um eine halbe Teilung versetzt (zwischen den großen)
			var ds := d + POSTER_SPACING * 0.5
			# kleine Plakate hängen unten an den Glastüren der Außenwand (hinter dem Laufgang)
			if absf(ds) + POSTER_SMALL_H * aspect * 0.5 < length * 0.5 - 1.0:
				_poster(mat, aspect, POSTER_SMALL_H, POSTER_SMALL_Y, w[0] + along * ds - normal * (WALK_DEPTH - POSTER_GAP), basis)


## Positionen entlang einer Wand (Abstand von der Wandmitte). Mit Säulen liegen
## die Plätze genau zwischen zwei Säulen, sonst symmetrisch zur Mitte.
func _poster_slots(length: float, spacing: float, columns: bool, start_off: float) -> Array:
	var out := []
	var n := maxi(1, int(floor((length - 4.0) / spacing)))
	if columns:
		# Säulen bei start_off + 4 + 8k (von der Mitte gemessen) → Lücken bei +8, +24 …
		var p := start_off + 8.0
		while p < length * 0.5 - 4.0:
			out.append(p)
			p += spacing
	else:
		for i in n:
			out.append((i - (n - 1) * 0.5) * spacing)
	return out


## Ein Plakat: Fläche mit Höhe h, Breite h × Seitenverhältnis, Mitte in Höhe y.
func _poster(mat: Material, aspect: float, h: float, y: float, at: Vector3, basis: Basis) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(h * aspect, h)
	mi.mesh = q
	mi.material_override = mat
	mi.transform = Transform3D(basis, Vector3(at.x, y, at.z))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Startlage des Schiffs: Bug 1 m hinter der Linie des vorderen Pylons,
## Hüllenseite 1 m neben dem Pylon auf der Pilotenseite,
## Nase Richtung hinterer Pylon (+X), freischwebend in 4 m Höhe.
func start_transform(ship: AirshipPhysics) -> Transform3D:
	var x := -START_BEHIND - ship.hull.cb_from_nose
	# seitlich zur Pilotenseite versetzt, damit der Start über Punkt 1 zählt
	var z := START_BESIDE + ship.hull.diameter_m * 0.5
	return Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(x, START_HEIGHT, z))


# =============================================================================
# Rennen
# =============================================================================
func reset_race() -> void:
	race = Race.WAIT
	lap = 0
	time_s = 0.0
	next_gate = 0
	lap_times = PackedFloat32Array()
	_lap_start = 0.0
	_set_far_green(false)
	_prev_nose = Vector2(NAN, NAN)
	race_changed.emit()


## Jeden Physikschritt mit der Bug-Position (Welt-X = Strecke, Welt-Z = quer) aufrufen.
func track(nose_x: float, nose_z: float, dt: float) -> void:
	if race == Race.RUN:
		time_s += dt
	var now := Vector2(nose_x, nose_z)
	if is_nan(_prev_nose.x):
		_prev_nose = now
		return
	var prev := _prev_nose
	_prev_nose = now
	var lines := [0.0, distance()]
	for li in 2:
		var lx: float = lines[li]
		if (prev.x - lx < 0.0) == (now.x - lx < 0.0):
			continue                                   # diese Linie nicht überquert
		# Querposition genau an der Linie (linear zwischen den beiden Schritten)
		var t := (lx - prev.x) / (now.x - prev.x) if now.x != prev.x else 0.0
		var z := lerpf(prev.y, now.y, t)
		var side := 1 if z > 0.0 else -1
		var dir := 1 if now.x > prev.x else -1
		# Anzeige-Pylon: grün auf Höhe von Pylon 2, rot über Pylon 1
		if li == 1: _set_far_green(true)
		else: _set_far_green(false)
		_on_line(li, side, dir)


## Ein Linien-Durchgang: passt er zum erwarteten Kontrollpunkt?
func _on_line(line: int, side: int, dir: int) -> void:
	var g: Array = GATES[next_gate]
	if line != g[0] or side != g[1] or dir != g[2]:
		return                                         # falsch → zählt nicht, weiterfliegen
	match race:
		Race.WAIT:                                     # fliegender Start über Punkt 1
			race = Race.RUN
			lap = 1
			time_s = 0.0
			_lap_start = 0.0
			next_gate = 1
		Race.RUN:
			if next_gate == 0:                         # Ziellinie: Runde fertig
				lap_times.append(time_s - _lap_start)
				_lap_start = time_s
				if lap >= LAPS:
					race = Race.DONE
				else:
					lap += 1
					next_gate = 1
			else:
				next_gate = (next_gate + 1) % GATES.size()
	race_changed.emit()


func _set_far_green(on: bool) -> void:
	far_green = on
	_far_mat.albedo_color = COLOR_GREEN if on else COLOR_RED


## Text für die Anzeige im HUD.
func race_text() -> String:
	match race:
		Race.WAIT: return "Start: Pylon 1 passieren"
		Race.RUN: return I18n.t("nächster: ") + I18n.t(GATE_NAMES[next_gate])   # Zeiten stehen rechts (RacePanel)
		_: return I18n.t("Ziel · %s") % format_time(time_s)


## Hinweiszeile oben links unter der Rennanzeige (nur vor dem Start).
func hint_text() -> String:
	return "Pilotenseite, Richtung Pylon 2" if race == Race.WAIT else ""


## Zeit der laufenden Runde (s).
func current_lap_time() -> float:
	return time_s - _lap_start


## Gewertete Zeit nach dem F7B-Reglement: Gesamtzeit × ∛V_ref, dabei ist V_ref
## das Ellipsoid in der Box über alles: V_ref = L · B · H · π/6 (m³).
## Kleine Schiffe werden damit belohnt, große bekommen eine längere Zeit.
## Rennfaktor (F7B): Zahl, mit der die gemessene Zeit malgenommen wird,
## ∛(L·B·H·π/6) mit dem Boxmaß in m.
static func race_factor(box_m: Vector3) -> float:
	return pow(maxf(box_m.x * box_m.y * box_m.z * PI / 6.0, 1e-6), 1.0 / 3.0)


static func scored_time(total_s: float, box_m: Vector3) -> float:
	var v_ref := box_m.x * box_m.y * box_m.z * PI / 6.0
	return total_s * pow(maxf(v_ref, 1e-6), 1.0 / 3.0)


## Zeile unter der Rundenanzeige: nächster Kontrollpunkt und Rundenzeiten
## (fertige Runden, am Ende mit bester Runde).
func lap_text() -> String:
	var parts: Array[String] = []
	if race == Race.WAIT:
		return "Pilotenseite, Richtung Pylon 2"
	if race == Race.RUN:
		parts.append(I18n.t("nächster: ") + I18n.t(GATE_NAMES[next_gate]))
	var best := 0
	for i in lap_times.size():
		parts.append("R%d %s" % [i + 1, format_time(lap_times[i])])
		if lap_times[i] < lap_times[best]: best = i
	var txt := "   ".join(parts)
	if parts.is_empty(): return ""
	if race == Race.DONE:
		txt += I18n.t("   · beste: R%d") % (best + 1)
	return txt


static func format_time(t: float) -> String:
	var m := int(t / 60.0)
	var s := t - m * 60.0
	return I18n.dec("%d:%04.1f" % [m, s])


# =============================================================================
# Einstellungen
# =============================================================================
func set_course(new_preset: int, new_free_distance: float) -> void:
	preset = clampi(new_preset, 0, 1)
	free_distance = clampf(new_free_distance, MIN_DISTANCE, MAX_DISTANCE)
	save_settings()
	rebuild()


## Location wechseln (0 = Halle, 1 = Wiese).
func set_location(new_location: int) -> void:
	location = clampi(new_location, 0, 1)
	save_settings()
	rebuild()


## Pylonabstand eintragen (Zahlenfeld im Menü „Strecke“): auf der Wiese der
## Wiesen-Abstand, in der Halle der freie Abstand (schaltet auf „Frei“).
func set_distance(d: float) -> void:
	if location == 1:
		meadow_distance = clampf(d, MIN_DISTANCE, MAX_DISTANCE)
		save_settings()
		rebuild()
	else:
		set_course(1, d)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("strecke", "preset", preset)
	cfg.set_value("strecke", "frei_abstand", free_distance)
	cfg.set_value("strecke", "location", location)
	cfg.set_value("strecke", "wiese_abstand", meadow_distance)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	preset = clampi(int(cfg.get_value("strecke", "preset", preset)), 0, 1)
	free_distance = clampf(float(cfg.get_value("strecke", "frei_abstand", free_distance)), MIN_DISTANCE, MAX_DISTANCE)
	location = clampi(int(cfg.get_value("strecke", "location", location)), 0, 1)
	meadow_distance = clampf(float(cfg.get_value("strecke", "wiese_abstand", meadow_distance)), MIN_DISTANCE, MAX_DISTANCE)
