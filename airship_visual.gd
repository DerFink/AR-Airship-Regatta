# 2026-10-27 16:07 – Restmasse (Block am Hüllenboden) und Schwerpunkt (rote Kugel) im Baukasten sichtbar
# 2026-10-27 15:09 – Flossen als Trapez mit Zuspitzung (Pfeilung) statt Quader
# 2026-10-27 11:08 – Hülle trägt die Gestaltungs-Textur (LiveryCanvas: Farbe, Schriftzug, Logo); bei Änderungen der Gestaltung wird nur neu gemalt
# 2026-10-27 10:42 – Erstversion: 3D-Darstellung aus der Konfiguration (Hülle, Flossen, Motorgondeln mit Live-Schwenk und Ruderausschlag), Einfärbung nach Validator-Ergebnis, Kollisionsform passend zur Hülle
# =============================================================================
# AirshipVisual.gd  (Kind-Node von AirshipPhysics)
# -----------------------------------------------------------------------------
# Baut die sichtbare Geometrie aus der aktuellen Konfiguration auf und
# aktualisiert sie, sobald der Baukasten etwas ändert (Signal config_changed).
# Flossen und Gondeln bewegen sich live mit Ruderausschlag und Schwenk.
# Grafik und Physik nutzen denselben Ursprung (Auftriebszentrum).
# =============================================================================
class_name AirshipVisual
extends Node3D

@export var hull_color := Color("dfe5ea")
@export var fin_color := Color("3d8bfd")
@export var motor_color := Color("39414b")

var ship: AirshipPhysics
var _fin_nodes: Array[Node3D] = []
var _motor_nodes: Array[Node3D] = []
var _hull_mesh := MeshInstance3D.new()
var _collision: CollisionShape3D
var _fin_mat := StandardMaterial3D.new()
var _canvas := LiveryCanvas.new()        ## malt Farbe, Schriftzug und Logo
var _livery: Livery                      ## aktuell angezeigte Gestaltung
var _mass_node := MeshInstance3D.new()   ## Restmasse unten an der Hülle (nur im Baukasten)
var _cg_node := MeshInstance3D.new()     ## Gesamtschwerpunkt (nur im Baukasten)
var _workshop := false


func _ready() -> void:
	ship = get_parent() as AirshipPhysics
	add_child(_hull_mesh)
	add_child(_canvas)
	add_child(_mass_node)
	add_child(_cg_node)
	# Restmasse: halbtransparenter Block (türkis), Schwerpunkt: rote Kugel,
	# die durch die Hülle hindurch sichtbar bleibt
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.11, 0.62, 0.46, 0.75)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mass_node.material_override = bm
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color("e24b4a")
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.no_depth_test = true
	_cg_node.material_override = cm
	var sph := SphereMesh.new()
	sph.radius = 0.012; sph.height = 0.024
	_cg_node.mesh = sph
	set_workshop(false)
	_fin_mat.albedo_color = fin_color
	_fin_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Kollisionsform als Geschwister des Visuals (muss direktes Kind des Bodys sein)
	_collision = CollisionShape3D.new()
	_collision.name = "HullCollision"
	ship.add_child.call_deferred(_collision)
	ship.config_changed.connect(rebuild)
	rebuild()


# =============================================================================
# Alles neu aufbauen (nach Änderung im Baukasten)
# =============================================================================
func rebuild() -> void:
	if ship == null or ship.hull == null:
		return
	var h := ship.hull
	# --- Hülle --------------------------------------------------------------
	_hull_mesh.mesh = h.build_mesh(64, 32)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color.WHITE                 # Farbe kommt aus der Gestaltungs-Textur
	hm.albedo_texture = _canvas.get_texture()
	hm.texture_repeat = true                      # Naht unten: v < 0 wiederholt sich
	hm.roughness = 0.6
	_hull_mesh.material_override = hm
	_hook_livery()
	_repaint()

	# --- Restmasse (Elektronik + Akku + Ballast) und Schwerpunkt ----------
	# Blockgröße aus der Masse (Dichte ≈ 2 g/cm³, Seiten 3 : 1,5 : 1),
	# Oberseite liegt am Hüllenboden an.
	var vol := maxf(ship.bottom_mass_kg, 0.001) / 2000.0
	var k := pow(vol / 4.5, 1.0 / 3.0)
	var box := BoxMesh.new()
	box.size = Vector3(1.5 * k, k, 3.0 * k)
	_mass_node.mesh = box
	_mass_node.position = ship.bottom_mass_pos - Vector3(0, 0.5 * k, 0)
	_cg_node.position = ship.cg_offset

	# --- Kollision: Kapsel entlang der Längsachse ---------------------------
	var cap := CapsuleShape3D.new()
	cap.radius = h.diameter_m * 0.5
	cap.height = h.length_m
	_collision.shape = cap
	_collision.rotation = Vector3(PI * 0.5, 0, 0)           # Kapsel liegt in Z
	_collision.position = Vector3(0, 0, h.length_m * 0.5 - h.cb_from_nose)

	# --- Flossen ------------------------------------------------------------
	for n in _fin_nodes: n.queue_free()
	_fin_nodes.clear()
	for s in ship.surfaces:
		var pivot := Node3D.new()
		add_child(pivot)
		var span := s.span_m()
		var chord := s.area_m2 / span
		var d := s.outward_dir()
		var root := s.position - d * 0.4 * span               # Flossenwurzel an der Hülle
		pivot.position = root
		# Lokale Achsen der Flosse: Y = abstehend, Z = Längsachse, X = Flächennormale
		# (rechtshändig: X = Y × Z)
		pivot.basis = Basis(d.cross(Vector3(0, 0, 1)), d, Vector3(0, 0, 1)).orthonormalized()
		var mi := MeshInstance3D.new()
		mi.mesh = _fin_mesh(span, chord, s.taper)
		mi.material_override = _fin_mat
		pivot.add_child(mi)
		pivot.set_meta("surface", s)
		pivot.set_meta("base_basis", pivot.basis)
		_fin_nodes.append(pivot)

	# --- Motorgondeln -------------------------------------------------------
	for n in _motor_nodes: n.queue_free()
	_motor_nodes.clear()
	var mm := StandardMaterial3D.new()
	mm.albedo_color = motor_color
	for m in ship.motors:
		var g := Node3D.new()
		add_child(g)
		g.position = m.position
		var body := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.025; cyl.bottom_radius = 0.03; cyl.height = 0.09
		body.mesh = cyl
		body.rotation = Vector3(PI * 0.5, 0, 0)               # Zylinder liegt in Schubrichtung
		body.material_override = mm
		g.add_child(body)
		var prop := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.07; disc.bottom_radius = 0.07; disc.height = 0.004
		prop.mesh = disc
		prop.rotation = Vector3(PI * 0.5, 0, 0)
		prop.position = Vector3(0, 0, -0.05)
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(motor_color, 0.35)
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		prop.material_override = pm
		g.add_child(prop)
		g.set_meta("motor", m)
		_motor_nodes.append(g)


## Restmasse und Schwerpunkt nur im Baukasten zeigen (im Flug unsichtbar).
func set_workshop(on: bool) -> void:
	_workshop = on
	_mass_node.visible = on
	_cg_node.visible = on


## Flache Flosse als Trapez (zweiseitig gerendert): Wurzeltiefe c_r an der
## Hülle, Endtiefe c_t = Zuspitzung · c_r außen, Hinterkante gerade.
## Lokal: Y = Spannweite (abstehend), Z = Längsachse (+Z = hinten).
func _fin_mesh(span: float, mean_chord: float, taper: float) -> ArrayMesh:
	var c_r := 2.0 * mean_chord / (1.0 + taper)
	var c_t := c_r * taper
	var te := c_r * 0.5                                   # Hinterkante (gerade)
	var p0 := Vector3(0, 0, te - c_r)                     # Wurzel vorn
	var p1 := Vector3(0, 0, te)                           # Wurzel hinten
	var p2 := Vector3(0, span, te)                        # Spitze hinten
	var p3 := Vector3(0, span, te - c_t)                  # Spitze vorn
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [p0, p1, p2, p0, p2, p3]:
		st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# =============================================================================
# Gestaltung: bei neuer Livery (Preset/Import) Signal umhängen, dann neu malen
# =============================================================================
func _hook_livery() -> void:
	if ship.livery == _livery:
		return
	if _livery and _livery.changed_look.is_connected(_repaint):
		_livery.changed_look.disconnect(_repaint)
	_livery = ship.livery
	if _livery:
		_livery.changed_look.connect(_repaint)


func _repaint() -> void:
	if _livery == null:
		_livery = Livery.new()
	_canvas.repaint(_livery, ship.hull.length_to_diameter)


# =============================================================================
# Einfärbung nach Validator (Baukasten): ok = Akzentfarbe, sonst Warnfarbe
# =============================================================================
func set_validation_level(level: int) -> void:
	match level:
		TailValidator.Level.OK: _fin_mat.albedo_color = fin_color
		TailValidator.Level.MARGINAL: _fin_mat.albedo_color = UITheme.color("warning")
		_: _fin_mat.albedo_color = UITheme.color("danger")


# =============================================================================
# Live-Bewegung: Ruder kippen (vereinfacht ganze Fläche), Gondeln schwenken
# =============================================================================
func _process(_dt: float) -> void:
	for p in _fin_nodes:
		var s: ControlSurface = p.get_meta("surface")
		var defl := deg_to_rad(s._flex_deg)
		if s.kind == ControlSurface.Kind.FLAP:
			defl *= 0.5                                       # Klappe ≈ halber Sichtausschlag
		var base: Basis = p.get_meta("base_basis")
		p.basis = base * Basis(Vector3.UP, -defl)             # Drehung um die Spannweitenachse
	for g in _motor_nodes:
		var m: VectorMotor = g.get_meta("motor")
		var dir := m.current_direction()
		# -Z der Gondel zeigt in Schubrichtung
		g.basis = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK)
