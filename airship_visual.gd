# 2026-11-11 19:45 – Baukasten: Schiff pendelt auf seinen Hängewinkel (Bug-/Hecklastigkeit sichtbar)
# 2026-11-11 14:30 – Flossen drehen jetzt in die richtige Richtung (Vorzeichen war vertauscht); Hülle federt beim Stoß sichtbar nach; geplatzte Hülle: Riss entlang der oberen Längsnaht am Heck, Gaswolke, Hülle fällt vom Heck zur Nase hin in sich zusammen, Kollisionsform schrumpft mit
# 2026-11-11 07:00 – Motoren als Flachmotor (Glocke, Ring, Halter, Welle) mit Schwenkservo statt langer Gondel; Größe aus dem Propellerdurchmesser
# 2026-11-11 03:10 – Warnfarbe der Flossen (Validator) nur im Baukasten, im Flug echte Leitwerksfarbe
# 2026-11-11 01:00 – Material aus der Gestaltung (Silberfolie glänzend, Weiß matt, Goldfolie, Farbe; Leitwerk Weiß/Carbon/Folie/Farbe); Flossenwurzel reicht bis in die Hülle (keine Lücke an der gewölbten Hülle); Propellerkreis aus dem Propellerdurchmesser; Nutzlast als Block; local_aabb() für das Boxmaß
# 2026-10-27 23:49 – Turm als stromlinienförmiger Körper (NACA-Grundriss) in Hüllenfarbe
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
var _sail_mat := StandardMaterial3D.new() ## Turm in Hüllenfarbe
var _hull_mat := StandardMaterial3D.new()
var _payload_node := MeshInstance3D.new() ## Nutzlast (Block außen an der Hülle)
## Baukasten: Winkel, unter dem das Schiff hängt (+ = Nase hoch / hecklastig)
var trim_target_deg := 0.0
var _trim_deg := 0.0                     ## aktuelle Pendelstellung
var _trim_rate := 0.0
var _squash := 0.0                       ## Nachfedern nach einem Stoß (0 … 1, klingt ab)
var _drawn_front := 1.0                  ## zuletzt gezeichneter Stand der geplatzten Hülle


func _ready() -> void:
	ship = get_parent() as AirshipPhysics
	add_child(_hull_mesh)
	add_child(_canvas)
	add_child(_mass_node)
	add_child(_cg_node)
	add_child(_payload_node)
	var plm := StandardMaterial3D.new()
	plm.albedo_color = Color("e0a43a")
	_payload_node.material_override = plm
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
	ship.bumped.connect(func(k: float): _squash = maxf(_squash, k))
	ship.burst_changed.connect(_on_burst_changed)
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
	var hm := _hull_mat
	hm.albedo_color = Color.WHITE                 # Farbe kommt aus der Gestaltungs-Textur
	hm.albedo_texture = _canvas.get_texture()
	hm.texture_repeat = true                      # Naht unten: v < 0 wiederholt sich
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
	# Nutzlast: Würfel (Dichte ≈ 1 g/cm³), Innenseite liegt an der Hülle an
	_payload_node.visible = ship.payload_mass_kg > 0.0005
	if _payload_node.visible:
		var e := pow(ship.payload_mass_kg / 1000.0, 1.0 / 3.0)
		var pb := BoxMesh.new()
		pb.size = Vector3(e, e, e)
		_payload_node.mesh = pb
		var pa := deg_to_rad(ship.payload_angle_deg)
		var out := Vector3(sin(pa), cos(pa), 0.0)
		_payload_node.position = ship.payload_pos + out * 0.5 * e
		_payload_node.basis = Basis(Vector3(0, 0, 1), -pa)

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
		# Wurzel bis zur Längsachse verlängern: die Hülle wird zum Heck dünner,
		# sonst stünde die Hinterkante der Flosse frei über der Hülle (Lücke)
		var inset := ship.hull.radius_at(s.hull_x)
		# Lokale Achsen der Flosse: Y = abstehend, Z = Längsachse, X = Flächennormale
		# (rechtshändig: X = Y × Z)
		pivot.basis = Basis(d.cross(Vector3(0, 0, 1)), d, Vector3(0, 0, 1)).orthonormalized()
		var mi := MeshInstance3D.new()
		if s.sail_member:
			# Turm: dicker, stromlinienförmiger Körper in Hüllenfarbe
			mi.mesh = _sail_mesh(span, chord)
			mi.material_override = _sail_mat
		else:
			mi.mesh = _fin_mesh(span, chord, s.taper, inset)
			mi.material_override = _fin_mat
		pivot.add_child(mi)
		pivot.set_meta("surface", s)
		pivot.set_meta("base_basis", pivot.basis)
		_fin_nodes.append(pivot)

	# --- Motorgondeln -------------------------------------------------------
	for n in _motor_nodes: n.queue_free()
	_motor_nodes.clear()
	for m in ship.motors:
		var g := Node3D.new()
		add_child(g)
		g.position = m.position
		# Flachmotor (Außenläufer wie 1804): Glocke mit farbigem Ring, Motorhalter,
		# Welle; Größe passend zum Propeller (4" → Glocke Ø 23 × 12 mm).
		# Dahinter der Schwenkservo (nur bei schwenkbaren Motoren).
		var br := clampf(m.prop_diameter_in * 0.0029, 0.008, 0.04)     # Glockenradius
		var bh := br * 1.05                                             # Glockenhöhe
		var parts := [
			# [Radius, Höhe, Lage z (vorn = −), Farbe, metallisch]
			[br, bh, -bh * 0.5, Color("2b2e33"), 0.6],                  # Glocke
			[br * 1.02, bh * 0.25, -bh * 0.88, Color("c8402e"), 0.3],   # Ring vorn
			[br * 1.2, br * 0.26, br * 0.13, Color("4a4f57"), 0.2],     # Motorhalter
			[br * 0.22, br * 0.9, -bh - br * 0.35, Color("c0c4c8"), 0.9],  # Welle mit Propellermutter
		]
		for pdef in parts:
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = pdef[0]; cm.bottom_radius = pdef[0]; cm.height = pdef[1]; cm.radial_segments = 28
			mi.mesh = cm
			mi.rotation = Vector3(PI * 0.5, 0, 0)                      # Achse in Schubrichtung
			mi.position = Vector3(0, 0, pdef[2])
			var pmat := StandardMaterial3D.new()
			pmat.albedo_color = pdef[3]; pmat.metallic = pdef[4]; pmat.roughness = 0.35
			mi.material_override = pmat
			g.add_child(mi)
		if m.max_swivel_deg > 0.0:
			var servo := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(br * 1.05, br * 1.9, br * 2.0)
			servo.mesh = sb
			servo.position = Vector3(0, 0, br * 0.26 + br)
			var smat := StandardMaterial3D.new()
			smat.albedo_color = Color("1f6fb5")
			servo.material_override = smat
			g.add_child(servo)
		var prop := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		var pr := m.prop_diameter_in * 0.0254 * 0.5          # Propellerkreis aus den Modelldaten
		disc.top_radius = pr; disc.bottom_radius = pr; disc.height = 0.002
		prop.mesh = disc
		prop.rotation = Vector3(PI * 0.5, 0, 0)
		prop.position = Vector3(0, 0, -bh - br * 0.3)
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.2, 0.22, 0.25, 0.3)
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		prop.material_override = pm
		g.add_child(prop)
		g.set_meta("motor", m)
		_motor_nodes.append(g)


## Umhüllender Quader aller sichtbaren Teile im Körpersystem des Schiffs
## (Hülle, Flossen, Motoren mit Propellerkreis, Restmasse, Nutzlast) – das
## „Boxmaß“, mit dem vor dem Rennen gemessen wird.
func local_aabb() -> AABB:
	var nodes: Array[Node3D] = [_hull_mesh, _mass_node]
	if _payload_node.visible: nodes.append(_payload_node)
	nodes.append_array(_fin_nodes)
	nodes.append_array(_motor_nodes)
	var box := AABB()
	var first := true
	var inv := ship.global_transform.affine_inverse()
	for n in nodes:
		for mi in ([n] + n.find_children("*", "MeshInstance3D", true, false)):
			if not (mi is MeshInstance3D) or (mi as MeshInstance3D).mesh == null: continue
			var t: Transform3D = inv * (mi as MeshInstance3D).global_transform
			var a: AABB = t * (mi as MeshInstance3D).mesh.get_aabb()
			if first: box = a; first = false
			else: box = box.merge(a)
	return box


## Restmasse und Schwerpunkt nur im Baukasten zeigen (im Flug unsichtbar).
func set_workshop(on: bool) -> void:
	_workshop = on
	set_validation_level(_valid_level)            # Warnfarbe nur im Baukasten
	_mass_node.visible = on
	_cg_node.visible = on


## Turm (Segel des U-Boots) als geschlossener Körper: Grundriss wie ein
## symmetrisches NACA-Profil (vorn rund, hinten spitz), Dicke 35 % der Länge.
## Unten (y < 0) steckt er 15 % der Höhe in der Hülle, damit an der
## gewölbten Hülle kein Spalt bleibt; oben ist er etwas kürzer (Hinterkante
## leicht schräg). Lokal: Y = Höhe (abstehend), Z = Längsachse (+Z = hinten).
func _sail_mesh(height: float, chord: float) -> ArrayMesh:
	const N := 16                                # Punkte je Profilseite
	var thick := 0.35 * chord
	var y0 := -0.15 * height
	var rings: Array = []
	for level in 2:
		var y := y0 if level == 0 else height
		var c := chord if level == 0 else chord * 0.85      # oben kürzer
		var front := -chord * 0.5                           # Vorderkante senkrecht
		var ring := PackedVector3Array()
		# rechte Seite von vorn nach hinten, dann linke Seite zurück
		for side in [1.0, -1.0]:
			for i in N + 1:
				var k := i if side > 0.0 else N - i
				var u := float(k) / N
				var yt := 5.0 * (0.2969 * sqrt(u) - 0.1260 * u - 0.3516 * u * u + 0.2843 * u * u * u - 0.1036 * u * u * u * u)
				ring.append(Vector3(side * yt * thick, y, front + u * c))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r0: PackedVector3Array = rings[0]
	var r1: PackedVector3Array = rings[1]
	var n := r0.size()
	for i in n:                                  # Mantel
		var j := (i + 1) % n
		for v in [r0[i], r1[i], r1[j], r0[i], r1[j], r0[j]]:
			st.add_vertex(v)
	var top_c := Vector3(0, height, -chord * 0.5 + chord * 0.85 * 0.4)
	for i in n:                                  # Deckel (Fächer)
		for v in [top_c, r1[(i + 1) % n], r1[i]]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## Flache Flosse als Trapez (zweiseitig gerendert): Wurzeltiefe c_r an der
## Hülle, Endtiefe c_t = Zuspitzung · c_r außen, Hinterkante gerade.
## Lokal: Y = Spannweite (abstehend), Z = Längsachse (+Z = hinten).
func _fin_mesh(span: float, mean_chord: float, taper: float, inset := 0.0) -> ArrayMesh:
	var c_r := 2.0 * mean_chord / (1.0 + taper)
	var c_t := c_r * taper
	var te := c_r * 0.5                                   # Hinterkante (gerade)
	var p0 := Vector3(0, -inset, te - c_r)                # Wurzel vorn (steckt bis zur Achse in der Hülle)
	var p1 := Vector3(0, -inset, te)                      # Wurzel hinten
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
	# Glanz der Hülle und des Leitwerks je Material
	var g := Livery.gloss(_livery.material)
	_hull_mat.metallic = g.x
	_hull_mat.roughness = g.y
	_hull_mat.metallic_specular = 0.7
	var fg := Livery.gloss(_livery.fin_material)
	fin_color = _livery.fin_base_color()
	_fin_mat.albedo_color = fin_color
	_fin_mat.metallic = fg.x
	_fin_mat.roughness = fg.y
	_sail_mat.albedo_color = _livery.hull_color          # Turm in Hüllenfarbe
	_sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sail_mat.roughness = 0.6


# =============================================================================
# Einfärbung nach Validator (Baukasten): ok = Akzentfarbe, sonst Warnfarbe
# =============================================================================
var _valid_level := 0
func set_validation_level(level: int) -> void:
	_valid_level = level
	if not _workshop:
		_fin_mat.albedo_color = fin_color          # im Flug immer die echte Leitwerksfarbe
		return
	match level:
		TailValidator.Level.OK: _fin_mat.albedo_color = fin_color
		TailValidator.Level.MARGINAL: _fin_mat.albedo_color = UITheme.color("warning")
		_: _fin_mat.albedo_color = UITheme.color("danger")


# =============================================================================
# Live-Bewegung: Ruder kippen (vereinfacht ganze Fläche), Gondeln schwenken
# =============================================================================
func _process(_dt: float) -> void:
	_update_hull_state(_dt)
	_update_trim_pendulum(_dt)
	for p in _fin_nodes:
		var s: ControlSurface = p.get_meta("surface")
		var defl := deg_to_rad(s._flex_deg)
		if s.kind == ControlSurface.Kind.FLAP:
			defl *= 0.5                                       # Klappe ≈ halber Sichtausschlag
		var base: Basis = p.get_meta("base_basis")
		# Drehung um die Spannweitenachse. Lokales X der Flosse = −Normale der
		# Physik; positiver Ausschlag hebt die Vorderkante zur Normalen hin.
		p.basis = base * Basis(Vector3.UP, defl)
	for g in _motor_nodes:
		var m: VectorMotor = g.get_meta("motor")
		var dir := m.current_direction()
		# -Z der Gondel zeigt in Schubrichtung
		g.basis = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK)


# =============================================================================
# Aufprall und Platzen (Signale aus AirshipPhysics)
# =============================================================================
## Nachfedern der prallen Hülle bzw. Zusammenfallen der geplatzten Hülle.
func _update_hull_state(dt: float) -> void:
	if ship == null:
		return
	if ship.burst:
		# Hülle nur neu zeichnen, wenn das Gas ein Stück weiter entwichen ist
		if absf(_drawn_front - ship.deflate_front) > 0.03 or (ship.deflate_front == 0.0 and _drawn_front != 0.0):
			_drawn_front = ship.deflate_front
			_hull_mesh.mesh = _deflated_mesh(ship.hull, _drawn_front)
			_shrink_collision(_drawn_front)
		return
	if _squash > 0.001:
		# kurz gestaucht in Längsrichtung, dafür etwas dicker – wie ein Ball
		_hull_mesh.scale = Vector3(1.0 + 0.05 * _squash, 1.0 + 0.05 * _squash, 1.0 - 0.09 * _squash)
		_squash = maxf(0.0, _squash - dt * 4.0)
	elif _hull_mesh.scale != Vector3.ONE:
		_hull_mesh.scale = Vector3.ONE


## Baukasten: das Schiff pendelt langsam auf seinen Hängewinkel (gedämpfte
## Schwingung, Periode ≈ 3 s), damit Bug-/Hecklastigkeit sichtbar wird.
## Im Flug liegt die Lage allein bei der Physik → keine Drehung.
func _update_trim_pendulum(dt: float) -> void:
	if not _workshop:
		if rotation != Vector3.ZERO:
			rotation = Vector3.ZERO
			_trim_deg = 0.0; _trim_rate = 0.0
		return
	const W := TAU / 3.0                    # Eigenfrequenz
	const ZETA := 0.25                      # Dämpfung (schwingt sichtbar ein paar Mal)
	var acc := -W * W * (_trim_deg - trim_target_deg) - 2.0 * ZETA * W * _trim_rate
	_trim_rate += acc * dt
	_trim_deg += _trim_rate * dt
	rotation.x = deg_to_rad(_trim_deg)      # + = Nase hoch (Nase zeigt nach −Z)


func _on_burst_changed(on: bool) -> void:
	_hull_mesh.scale = Vector3.ONE
	_squash = 0.0
	if on:
		_drawn_front = 1.0
		_hull_mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # durch den Riss sieht man die Innenseite
		_hull_mesh.mesh = _deflated_mesh(ship.hull, 1.0)
		_gas_cloud()
	else:
		_hull_mat.cull_mode = BaseMaterial3D.CULL_BACK
		rebuild()                                             # heile Hülle und volle Kollisionsform


## Hülle nach dem Platzen. front = bis wohin (ab Nase, 0…1) noch Gas trägt.
## Dahinter: Hülle schlaff, faltig, sackt nach unten und liegt breiter.
## Die obere Längsnaht ist am Heck aufgerissen (Lücke im Netz).
## Texturkoordinaten wie GertlerHull.build_mesh(), damit die Gestaltung bleibt.
func _deflated_mesh(h: GertlerHull, front: float) -> ArrayMesh:
	const RINGS := 48
	const SEGS := 24
	const TEAR_FROM := 0.70          # Riss reicht vom Heck bis 70 % der Länge
	var top_seg := SEGS / 4          # Segment über 90° = oben
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	for i in RINGS + 1:
		var x := float(i) / RINGS
		var r := h.radius_at(x)
		var z := x * h.length_m - h.cb_from_nose
		# 0 = noch prall, 1 = leer (weicher Übergang an der Gasgrenze)
		var k := smoothstep(front - 0.08, front + 0.02, x)
		var ring := []
		for j in SEGS + 1:
			var a := TAU * j / SEGS
			var fold := 1.0 + 0.18 * sin(a * 5.0 + x * 37.0) * k          # Falten
			var rr := r * lerpf(1.0, 0.7, k) * fold
			var px := cos(a) * rr * lerpf(1.0, 1.9, k)                     # liegt flach und breit
			var py := sin(a) * rr * lerpf(1.0, 0.35, k) - r * 0.45 * k     # sackt nach unten
			ring.append(Vector3(px, py, z))
		pts.append(ring)
	for i in RINGS:
		var x0 := float(i) / RINGS
		var x1 := float(i + 1) / RINGS
		for j in SEGS:
			if j == top_seg and x0 >= TEAR_FROM:
				continue                                              # aufgerissene Längsnaht
			var u0 := 1.0 - x0
			var u1 := 1.0 - x1
			var v0 := 0.75 - float(j) / SEGS
			var v1 := 0.75 - float(j + 1) / SEGS
			var p00: Vector3 = pts[i][j]
			var p01: Vector3 = pts[i][j + 1]
			var p10: Vector3 = pts[i + 1][j]
			var p11: Vector3 = pts[i + 1][j + 1]
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(p10)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


## Kollisionsform schrumpft mit der Hülle, damit das Wrack am Boden aufliegt.
func _shrink_collision(front: float) -> void:
	var h := ship.hull
	var cap := CapsuleShape3D.new()
	cap.radius = h.diameter_m * 0.5 * lerpf(0.7, 1.0, front)    # Unterkante der schlaffen Hülle ≈ 0,7 r unter der Achse
	cap.height = maxf(h.length_m * lerpf(0.85, 1.0, front), cap.radius * 2.0 + 0.01)
	_collision.shape = cap


## Helium-Wolke am Riss (oben am Heck): steigt auf und verblasst.
func _gas_cloud() -> void:
	var h := ship.hull
	var x := 0.86
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 40
	p.lifetime = 1.6
	p.explosiveness = 0.7
	p.local_coords = false                                     # Wolke bleibt in der Luft stehen
	p.position = Vector3(0, h.radius_at(x), x * h.length_m - h.cb_from_nose)
	p.direction = Vector3(0, 1, 0.4)
	p.spread = 40.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.4
	p.gravity = Vector3(0, 0.6, 0)                             # Helium steigt
	p.damping_min = 0.8
	p.damping_max = 1.6
	var s := maxf(h.diameter_m * 0.18, 0.03)
	var sph := SphereMesh.new()
	sph.radius = s
	sph.height = 2.0 * s
	sph.radial_segments = 8
	sph.rings = 4
	p.mesh = sph
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1, 1, 1, 1)
	sph.material = m
	var grad := Gradient.new()
	grad.set_color(0, Color(0.92, 0.96, 1.0, 0.55))
	grad.set_color(1, Color(0.92, 0.96, 1.0, 0.0))
	p.color_ramp = grad
	var curve := Curve.new()
	curve.max_value = 2.0
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(1, 2.0))
	p.scale_amount_curve = curve
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.5).timeout.connect(p.queue_free)
