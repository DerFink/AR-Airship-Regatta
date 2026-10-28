# 2026-10-28 08:14 – Strecke als eigener Node (Course): einstellbarer Pylonabstand, weißes Feld, Rundenzählung; Start 1 m hinter dem vorderen Pylon; Ansicht „Strecke“
# 2026-10-28 00:15 – PID-Vorgaben beim Modellwechsel an den Flugcontroller
# 2026-10-27 23:28 – Startmodell wieder Albacore
# 2026-10-27 16:07 – Startmodell Chewie; Restmasse/Schwerpunkt nur im Baukasten einblenden
# 2026-10-27 15:12 – Baukasten: Modell mit einem Finger drehen, mit zwei Fingern zoomen (PC: Maus ziehen / Mausrad); Knopf „Ansicht zurücksetzen“
# 2026-10-27 12:55 – Kein Zoom mehr (fester Bildwinkel 60°, Wunsch des Nutzers); Knopf „Zurücksetzen“ stellt das Schiff an den Startpunkt
# 2026-10-27 12:52 – Pilotensicht wie beim RC-Fliegen: fester Standort (1 m Richtung Mitte, 3 m neben Pylon 1, Augenhöhe 1,7 m), Blick folgt dem Schiff mit sanftem Zoom; Strecke mit zwei Pylonen im Abstand von 25 m; Start 6 m vor dem Piloten in 4 m Höhe
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

enum View { FLY, BUILD, PID, SHARE, COURSE }

# --- Strecke und Pilot (Meter) ------------------------------------------------
# Draufsicht: vorderer Pylon bei x = 0, hinterer Pylon bei x = Abstand (Course).
# Der Pilot steht wie ein RC-Pilot fest am Boden: 1 m Richtung Streckenmitte,
# 3 m seitlich neben Pylon 1, Augenhöhe 1,7 m – Blick die Strecke entlang.
const PILOT_EYE := Vector3(1.0, 1.7, 3.0)
## Fester Bildwinkel wie mit bloßem Auge (kein Zoom – weit weg = klein).
const FOV := 60.0

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
var course: Course
var course_panel: CoursePanel
var ui_sounds: UISounds
var view := View.FLY
var _world_env: WorldEnvironment
var _scenery: Node3D
var _prop_sounds: Array[PropSound] = []

# --- Baukasten-Ansicht: Modell drehen und zoomen ----------------------------
var _orbit_yaw := 0.0            ## Drehung um die Hochachse (rad), 0 = von der Seite
var _orbit_pitch := 0.25         ## Blick von oben (rad)
var _orbit_zoom := 1.0           ## 1 = Standardabstand, < 1 näher, > 1 weiter
var _touches := {}               ## aktive Finger: Index → Position


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

	# Regatta-Strecke: Pylone, weißes Feld, Rundenzählung (siehe course.gd)
	course = Course.new()
	course.name = "Course"
	_scenery.add_child(course)


# =============================================================================
# Luftschiff mit Flugcontroller und Motorklang
# =============================================================================
func _build_ship() -> void:
	ship = AirshipPhysics.new()
	ship.name = "Airship"
	AirshipPresets.albacore_default(ship)    # Startmodell: Albacore
	# Start: Bug 1 m hinter dem vorderen Pylon, Nase Richtung hinterer Pylon
	ship.transform = course.start_transform(ship)
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
	camera.fov = FOV
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
	course_panel = CoursePanel.new()
	course_panel.setup(course)
	root.add_child(course_panel)

	hud.builder_requested.connect(func(): _set_view(View.BUILD))
	hud.pid_requested.connect(func(): _set_view(View.PID))
	hud.ar_requested.connect(ar.toggle)
	hud.reset_requested.connect(reset_ship)
	hud.course_requested.connect(func(): _set_view(View.COURSE))
	course_panel.closed.connect(func(): _set_view(View.FLY))
	course_panel.course_changed.connect(reset_ship)
	# Modellwahl im Baukasten: PID-Standardwerte des Modells übernehmen
	ship.model_applied.connect(func(): fc.apply_model_gains(ship.fc_gains))
	builder.closed.connect(func(): _set_view(View.FLY))
	builder.share_requested.connect(func(): _set_view(View.SHARE))
	builder.view_reset_requested.connect(reset_view)
	builder.ui_action.connect(ui_sounds.chime)
	share.ui_action.connect(ui_sounds.chime)
	share.closed.connect(func(): _set_view(View.BUILD))
	pid.closed.connect(func(): _set_view(View.FLY))
	watchdog.notice.connect(func(t): hud.show_notice(t, "warning"))
	ar.ar_state_changed.connect(func(on, msg): hud.set_ar_active(on); hud.show_notice(msg, "info", 2.0))


## Schiff an den Startpunkt zurück (Nase Richtung Pylon 2), Regler neu starten.
## Der Motor-Schalter bleibt, wie er ist – der Gasknüppel steht ja in der Mitte.
func reset_ship() -> void:
	ship.reset_to(course.start_transform(ship))
	fc._reset_integrators()
	course.reset_race()
	hud.show_notice("Zurückgesetzt", "info", 1.5)


## Rundenzählung: Bug-Position an die Strecke melden, Anzeige im HUD.
func _physics_process(dt: float) -> void:
	if view == View.BUILD or view == View.SHARE:
		return                                  # Schiff steht im Baukasten fest
	var nose := ship.global_transform * Vector3(0, 0, -ship.hull.cb_from_nose)
	course.track(nose.x, dt)
	hud.set_race_text(course.race_text())


## Baukasten-Ansicht auf Standard zurück (seitlich, leicht von oben).
func reset_view() -> void:
	_orbit_yaw = 0.0
	_orbit_pitch = 0.25
	_orbit_zoom = 1.0


# =============================================================================
# Gesten im Baukasten (nur in der freien Mitte – Bedienfelder fangen ihre
# Berührungen selbst ab):  1 Finger ziehen = drehen, 2 Finger = zoomen.
# Am PC: mit gedrückter Maus ziehen = drehen, Mausrad = zoomen.
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if view != View.BUILD:
		_touches.clear()
		return
	if event is InputEventScreenTouch:
		if event.pressed: _touches[event.index] = event.position
		else: _touches.erase(event.index)
	elif event is InputEventScreenDrag:
		if _touches.size() >= 2 and _touches.has(event.index):
			var ids := _touches.keys()
			var other: Vector2 = _touches[ids[1] if ids[0] == event.index else ids[0]]
			var before: float = (_touches[event.index] as Vector2).distance_to(other)
			var after: float = event.position.distance_to(other)
			if before > 1.0 and after > 1.0:
				_orbit_zoom = clampf(_orbit_zoom * before / after, 0.35, 3.0)
		elif _touches.size() == 1:
			_rotate_view(event.relative)
		_touches[event.index] = event.position
	elif event is InputEventMagnifyGesture:
		_orbit_zoom = clampf(_orbit_zoom / event.factor, 0.35, 3.0)
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: _orbit_zoom = clampf(_orbit_zoom * 0.9, 0.35, 3.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _orbit_zoom = clampf(_orbit_zoom * 1.1, 0.35, 3.0)
	elif event is InputEventMouseMotion and not DisplayServer.is_touchscreen_available() \
			and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_rotate_view(event.relative)


func _rotate_view(rel: Vector2) -> void:
	_orbit_yaw -= rel.x * 0.008
	_orbit_pitch = clampf(_orbit_pitch + rel.y * 0.006, -1.3, 1.4)


func _set_view(v: View) -> void:
	view = v
	hud.visible = v == View.FLY
	builder.visible = v == View.BUILD
	pid.visible = v == View.PID
	share.visible = v == View.SHARE
	course_panel.visible = v == View.COURSE
	# Baukasten/Teilen: Motoren aus, Schiff festhalten, ruhiger Klangteppich.
	# Flug/PID: kein Klangteppich – zu hören sind nur die Motoren.
	var workshop := v == View.BUILD or v == View.SHARE
	if workshop:
		fc.armed = false
	ship.freeze = workshop
	visual.set_workshop(workshop)          # Restmasse + Schwerpunkt nur im Baukasten zeigen
	ui_sounds.set_pad(workshop)


# =============================================================================
# Kamera: hinter dem Schiff (Flug) oder seitlich (Baukasten)
# =============================================================================
func _process(dt: float) -> void:
	var p := ship.global_position
	var L := ship.hull.length_m
	var a := clampf(dt * 3.0, 0.0, 1.0)
	if view == View.BUILD or view == View.SHARE:
		# Baukasten: um das Modell kreisen (drehen/zoomen per Gesten)
		var dist := L * 1.45 * _orbit_zoom
		var off := Vector3(0, 0, dist).rotated(Vector3.RIGHT, -_orbit_pitch).rotated(Vector3.UP, _orbit_yaw)
		camera.global_position = camera.global_position.lerp(p + off, clampf(dt * 10.0, 0.0, 1.0))
	else:
		# Flug: fester Pilotenstandort, Blick folgt dem Schiff (fester Bildwinkel)
		camera.global_position = camera.global_position.lerp(PILOT_EYE, a)
	if camera.global_position.distance_to(p) > 0.01:
		camera.look_at(p, Vector3.UP)
