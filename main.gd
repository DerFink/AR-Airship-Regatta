# 2026-10-27 12:22 – Fix: Vollbild-Anker mit set_anchors_and_offsets_preset (vorher blieb die Fläche 0 px groß → Knüppel und Menüs landeten oben links)
# 2026-10-27 11:08 – Teilen-Dialog als eigene Ansicht; Sound: Propellergeräusch je Motor (wird bei Bauteil-Änderungen neu aufgebaut), ruhige Töne + leiser Klangteppich nur im Baukasten, im Flug sonst Stille
# 2026-10-27 10:42 – Erstversion: Hauptszene setzt alles zusammen (Testgelände mit Regatta-Pylonen, Luftschiff, Flugcontroller, Watchdog, AR-Schalter, Verfolgerkamera / Baukasten-Kamera, UI mit zentralem Theme)
# =============================================================================
# Main.gd  (Wurzel der Hauptszene main.tscn)
# -----------------------------------------------------------------------------
# Baut die komplette App per Code auf, damit alles an einem Ort nachvollziehbar
# ist:
#   Welt ─ Himmel, Licht, Boden, Pylone
#   Luftschiff (AirshipPhysics) ─ AirshipVisual, FlightController, PropSound je Motor
#   PerformanceWatchdog, ARToggle, UISounds
#   CanvasLayer ─ UI-Wurzel (Theme) ─ FlightHUD | BuilderPanel | PIDPanel | SharePanel
# =============================================================================
extends Node3D

enum View { FLY, BUILD, PID, SHARE }

var ship: AirshipPhysics
var visual: AirshipVisual
var fc: FlightController
var watchdog: PerformanceWatchdog
var ar: ARToggle
var camera: Camera3D
var hud: FlightHUD
var builder: BuilderPanel
var pid: PIDPanel
var share: SharePanel
var ui_sounds: UISounds
var view := View.FLY
var _world_env: WorldEnvironment
var _scenery: Node3D
var _prop_sounds: Array[PropSound] = []


func _ready() -> void:
	_build_world()
	_build_ship()
	_build_ui()
	_set_view(View.FLY)


# =============================================================================
# Testgelände
# =============================================================================
func _build_world() -> void:
	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_world_env.environment = env
	add_child(_world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	# Alles, was im AR-Modus verschwinden soll, hängt an _scenery
	_scenery = Node3D.new()
	add_child(_scenery)
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	gs.shape = box
	gs.position.y = -0.5
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	gm.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("5f7d4f")
	gm.material_override = mat
	ground.add_child(gm)
	_scenery.add_child(ground)

	# Regatta-Pylone (rot) im Kreis
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("e5534b")
	for i in 6:
		var a := TAU * i / 6.0
		var py := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.15; cyl.bottom_radius = 0.4; cyl.height = 6.0
		py.mesh = cyl
		py.material_override = pm
		py.position = Vector3(cos(a) * 30.0, 3.0, sin(a) * 30.0)
		_scenery.add_child(py)


# =============================================================================
# Luftschiff mit Flugcontroller und Motorklang
# =============================================================================
func _build_ship() -> void:
	ship = AirshipPhysics.new()
	ship.name = "Airship"
	AirshipPresets.albacore_default(ship)
	ship.position = Vector3(0, 3, 0)
	visual = AirshipVisual.new()
	ship.add_child(visual)
	fc = FlightController.new()
	fc.airship = ship
	ship.add_child(fc)
	add_child(ship)
	ship.config_changed.connect(_rebuild_prop_sounds)
	_rebuild_prop_sounds()

	watchdog = PerformanceWatchdog.new()
	watchdog.airship = ship
	add_child(watchdog)

	ar = ARToggle.new()
	ar.virtual_environment = _scenery
	ar.world_environment = _world_env
	add_child(ar)

	ui_sounds = UISounds.new()
	add_child(ui_sounds)

	camera = Camera3D.new()
	camera.fov = 60
	add_child(camera)
	camera.make_current()


## Ein Klangerzeuger pro Motor, an dessen Position. Neu aufbauen, wenn
## Motoren hinzukommen/entfallen; sonst nur die Lage nachführen.
func _rebuild_prop_sounds() -> void:
	var same := _prop_sounds.size() == ship.motors.size()
	if same:
		for i in _prop_sounds.size():
			same = same and _prop_sounds[i].motor == ship.motors[i]
	if not same:
		for p in _prop_sounds: p.queue_free()
		_prop_sounds.clear()
		for m in ship.motors:
			var p := PropSound.new()
			p.setup(m)
			ship.add_child(p)
			_prop_sounds.append(p)
	for p in _prop_sounds:
		p.position = p.motor.position


# =============================================================================
# Oberfläche
# =============================================================================
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.build_theme()          # ein Theme für alles
	layer.add_child(root)

	hud = FlightHUD.new()
	hud.setup(fc, ship)
	root.add_child(hud)
	builder = BuilderPanel.new()
	builder.setup(ship, visual)
	root.add_child(builder)
	pid = PIDPanel.new()
	pid.setup(fc)
	root.add_child(pid)
	share = SharePanel.new()
	share.setup(ship)
	root.add_child(share)

	hud.builder_requested.connect(func(): _set_view(View.BUILD))
	hud.pid_requested.connect(func(): _set_view(View.PID))
	hud.ar_requested.connect(ar.toggle)
	builder.closed.connect(func(): _set_view(View.FLY))
	builder.share_requested.connect(func(): _set_view(View.SHARE))
	builder.ui_action.connect(ui_sounds.chime)
	share.ui_action.connect(ui_sounds.chime)
	share.closed.connect(func(): _set_view(View.BUILD))
	pid.closed.connect(func(): _set_view(View.FLY))
	watchdog.notice.connect(func(t): hud.show_notice(t, "warning"))
	ar.ar_state_changed.connect(func(on, msg): hud.set_ar_active(on); hud.show_notice(msg, "info", 2.0))


func _set_view(v: View) -> void:
	view = v
	hud.visible = v == View.FLY
	builder.visible = v == View.BUILD
	pid.visible = v == View.PID
	share.visible = v == View.SHARE
	# Baukasten/Teilen: Motoren aus, Schiff festhalten, ruhiger Klangteppich.
	# Flug/PID: kein Klangteppich – zu hören sind nur die Motoren.
	var workshop := v == View.BUILD or v == View.SHARE
	if workshop:
		fc.armed = false
	ship.freeze = workshop
	ui_sounds.set_pad(workshop)


# =============================================================================
# Kamera: hinter dem Schiff (Flug) oder seitlich (Baukasten)
# =============================================================================
func _process(dt: float) -> void:
	var p := ship.global_position
	var L := ship.hull.length_m
	var target: Vector3
	if view == View.BUILD or view == View.SHARE:
		target = p + Vector3(L * 1.4, L * 0.25, 0)            # Seitenansicht
	else:
		var back := ship.global_transform.basis.z
		back.y = 0.0
		back = back.normalized() if back.length() > 0.01 else Vector3.BACK
		target = p + back * L * 2.2 + Vector3.UP * L * 0.6    # leicht erhöht dahinter
	camera.global_position = camera.global_position.lerp(target, clampf(dt * 3.0, 0.0, 1.0))
	camera.look_at(p, Vector3.UP)
