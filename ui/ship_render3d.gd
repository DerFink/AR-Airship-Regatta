# 2026-11-16 00:50 – Erstversion: Vorschaubilder der Luftschiffe als echtes 3D-Bild (gleiches Modell wie auf dem Flugfeld: Hülle, Folie/Farbe, Schriftzug, Logos, Leitwerk, Motoren) statt gezeichneter Seitenansicht
# =============================================================================
# ShipRender3D.gd  (ein Knoten in der Hauptszene, nimmt Aufträge der Reihe nach an)
# -----------------------------------------------------------------------------
#   ShipRender3D.into(rect, build, width_px)
#     rect   – TextureRect, das das Bild bekommt (bis dahin bleibt das alte Bild)
#     build  – Callable(ship): baut das Modell (Preset, Sammlung, Kopie des aktuellen)
#     width  – Bildbreite in Pixeln
#
# Ablauf je Auftrag: eigener SubViewport mit eigener 3D-Welt (Licht, Umgebung,
# Kamera von der Seite, Nase links) → das Luftschiff mit AirshipVisual wird
# genau wie im Flug aufgebaut → nach drei Bildern ist es gezeichnet → Bild
# kopieren, Viewport wieder entfernen. Fertige Bilder werden je Modell-Code und
# Breite gemerkt. Ohne Grafik (Tests, Werkzeuge) bleibt das gezeichnete Bild.
# =============================================================================
class_name ShipRender3D
extends Node

## Der eine Knoten in der Szene (setzt main.gd)
static var inst: ShipRender3D
## Fertige Bilder: "Code-Hash_Breite" → Texture2D
static var _cache := {}

var _queue: Array = []        ## [{cb, build, width, key}]
var _busy := false


## Bild für ein TextureRect bestellen. Gibt es das Bild schon, wird es sofort gesetzt.
static func into(rect: TextureRect, build: Callable, width_px: int) -> void:
	if rect == null:
		return
	request(build, width_px, func(tex: Texture2D):
		if is_instance_valid(rect): rect.texture = tex)


## Bild bestellen; cb(Texture2D) kommt, sobald es fertig ist (sofort, wenn schon gemerkt).
static func request(build: Callable, width_px: int, cb: Callable) -> void:
	if inst == null or DisplayServer.get_name() == "headless":
		return
	var s := AirshipPhysics.new()
	build.call(s)
	var key := "%d_%d" % [ModelCodec.encode(s).hash(), width_px]
	s.free()
	if _cache.has(key):
		cb.call(_cache[key])
		return
	inst._queue.append({"cb": cb, "build": build, "width": width_px, "key": key})
	inst._next()


## Bauanleitung für eine Kopie eines vorhandenen Luftschiffs (über den Modell-Code).
static func copy_of(ship: AirshipPhysics) -> Callable:
	var code := ModelCodec.encode(ship)
	return func(s: AirshipPhysics):
		var r := ModelCodec.decode(code)
		if r.ok:
			ModelCodec.apply(s, r.name, r.data)


func _next() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	var job: Dictionary = _queue.pop_front()
	if _cache.has(job.key):                       # inzwischen schon gezeichnet
		job.cb.call(_cache[job.key])
		_busy = false
		_next.call_deferred()
		return
	_render(job)


func _render(job: Dictionary) -> void:
	var w: int = job.width
	var h := int(w * 0.42)
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	# Licht und Umgebung wie draußen (hell, weiche Schatten)
	var env := WorldEnvironment.new()
	# gleicher Himmel wie auf dem Flugfeld (Licht und Spiegelung der Silberfolie),
	# Hintergrund aber durchsichtig
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.sky = Sky.new()
	e.sky.sky_material = ProceduralSkyMaterial.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)          # wie die Sonne über dem Flugfeld
	vp.add_child(sun)
	# Luftschiff: eingefroren, ohne Physik – nur zum Anschauen
	var s := AirshipPhysics.new()
	job.build.call(s)
	s.freeze = true
	var vis := AirshipVisual.new()
	s.add_child(vis)
	vp.add_child(s)
	# Kamera von links (Nase −Z zeigt nach links), senkrecht, ohne Perspektive
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	vp.add_child(cam)
	# drei Bilder warten: Hülle, Schrift und Logos sind dann aufgebaut und gezeichnet
	await get_tree().process_frame
	var box := _bounds(s)
	var c := box.get_center()
	var need_w := box.size.z * 1.08
	var need_h := box.size.y * 1.15
	cam.size = maxf(need_h, need_w * float(h) / float(w))     # size = sichtbare Höhe
	cam.global_transform = Transform3D(Basis.looking_at(Vector3.RIGHT, Vector3.UP), c - Vector3.RIGHT * 20.0)
	cam.near = 0.1
	cam.far = 60.0
	cam.make_current()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var tex := ImageTexture.create_from_image(img)
	_cache[job.key] = tex
	job.cb.call(tex)
	vp.queue_free()
	_busy = false
	_next()


## Umriss aller sichtbaren Teile (Hülle, Flossen, Motoren …) im Weltsystem.
func _bounds(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for n in root.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		if not vi.is_visible_in_tree():
			continue
		var b := vi.global_transform * vi.get_aabb()
		if b.size.length() < 0.001 or b.size.length() > 50.0:
			continue
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	if first:
		out = AABB(Vector3(-0.3, -0.3, -1.5), Vector3(0.6, 0.6, 3.0))
	return out
