# 2026-11-11 10:40 – Klang-Sicherung (SoundGuard): Klangstufe Fein/Mittel/Einfach, Klangerzeuger werden bei Stufenwechsel neu gebaut
# 2026-11-11 02:55 – Ladeanzeige (Luftschiff fliegt die Acht) während des Aufbaus; Baukasten: Boxmaß-Ecke, Seitenansicht mittig zwischen den Spalten, Strecke ausgeblendet; Regler-Menü aus dem Baukasten
# 2026-11-11 00:15 – Bestenliste aus „Modell & Bau“; Akku-Daten aus dem Modell
# 2026-11-10 22:00 – Neue Ansichten: Startseite (erste Ansicht), „Modell & Bau“ (ModelHub), „Grundlagen des Simulators“ (AboutPanel); Sprache (I18n) beim Start; Autopilot (live, aktuelles Modell/Regler) statt Demo; Kamera-Perspektiven Pilot am Start / Hinterher / Hinterher + Lage; AR-Knopf und Bestenlisten-Menü entfernt
# 2026-11-10 17:00 – Propellerklang: PropSynth (gleitende Tonhöhe) statt PropSound-Schleife; Rückfall auf die Schleife macht PropSynth selbst
# 2026-11-10 14:10 – Boden 3 × 3 km (Wiese mit 500 m Pylonabstand); Akku-Modell (4S 300 mAh), wird bei „Zurücksetzen“ voll geladen; Location aus der Flugansicht
# 2026-11-09 10:20 – Reglerwahl Teensy/Sim-optimiert aus der Flugansicht; Modellwechsel behält „Sim-optimiert“
# 2026-11-09 10:00 – Demo-Flug (DemoPilot) verdrahtet; Zurücksetzen beendet die Demo
# 2026-11-08 17:40 – Bestenliste mit dem Sender: SH bestätigt/schließt das Fenster, rechter Knüppel wählt
# 2026-11-07 21:10 – Menü der Flugansicht verdrahtet (Modell wählen, Bestenliste, Angaben Modell/Strecke)
# 2026-10-29 03:38 – reset_all_settings(): Flugcontroller, Strecke, Startposition
# 2026-10-29 00:19 – Bestenliste: nach dem Ziel Namen eintragen (Top 10), Ansicht LEADER
# 2026-10-28 15:12 – Pilot 6 m neben Pylon 1; Startmodell Chewie; PID-Vorgaben beim ersten Start bzw. nach Update übernehmen
# 2026-10-28 08:51 – Bug-Position x und z an die Strecke (Seite am Pylon)
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
#   Luftschiff (AirshipPhysics) ─ AirshipVisual, FlightController, PropSynth je Motor (Rückfall PropSound)
#   PerformanceWatchdog, ARToggle, UISounds
#   CanvasLayer ─ UI-Wurzel (Theme) ─ StartScreen | FlightHUD | ModelHub | AboutPanel | BuilderPanel | PIDPanel | SharePanel
# =============================================================================
extends Node3D

enum View { FLY, BUILD, PID, SHARE, COURSE, LEADER, START, HUB, ABOUT }

# --- Strecke und Pilot (Meter) ------------------------------------------------
# Draufsicht: vorderer Pylon bei x = 0, hinterer Pylon bei x = Abstand (Course).
# Der Pilot steht wie ein RC-Pilot fest am Boden: 1 m Richtung Streckenmitte,
# 6 m seitlich neben Pylon 1, Augenhöhe 1,7 m – Blick die Strecke entlang.
const PILOT_EYE := Vector3(1.0, 1.7, 6.0)
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
var autopilot: Autopilot             ## Autopilot (fliegt live die aktuelle Strecke)
var start_screen: StartScreen
var hub: ModelHub
var about: AboutPanel
var battery: Battery                 ## Akku-Modell (Spannung, Ladezustand, Schubabfall)
var course_panel: CoursePanel
var leader_panel: LeaderboardPanel
var ui_sounds: UISounds
var view := View.FLY
## Aufbau fertig (Welt, Schiff, Oberfläche) – vorher tun _process & Co. nichts
var ready_done := false
var _leader_back := View.FLY        ## wohin das Bestenlisten-Fenster zurückführt
var _pid_back := View.FLY           ## wohin „Fertig“ im Regler-Menü zurückführt
var _world_env: WorldEnvironment
var _scenery: Node3D
var _prop_sounds: Array[PropSynth] = []
var _sound_level := -1               ## Klangstufe, mit der _prop_sounds gebaut wurden
var sound_guard: SoundGuard          ## Klang-Sicherung (Fein → Mittel → Einfach)
var gauge: BoxGauge                  ## Boxmaß-Ecke im Baukasten

# --- Baukasten-Ansicht: Modell drehen und zoomen ----------------------------
var _orbit_yaw := 0.0            ## Drehung um die Hochachse (rad), 0 = von der Seite
var _orbit_pitch := 0.25         ## Blick von oben (rad)
var _orbit_zoom := 1.0           ## 1 = Standardabstand, < 1 näher, > 1 weiter
var _touches := {}               ## aktive Finger: Index → Position


func _ready() -> void:
	I18n.setup()                             # gespeicherte Sprache laden (vor dem Aufbau der Oberfläche)
	# Ladeanzeige (Luftschiff fliegt die Acht) zuerst – zwischen den Bauschritten
	# wird je ein Bild gezeichnet, damit sie sich bewegt
	var load_layer := CanvasLayer.new()
	load_layer.layer = 100
	add_child(load_layer)
	var loader := LoadingOverlay.new()
	load_layer.add_child(loader)
	await get_tree().process_frame
	await get_tree().process_frame
	_build_world()
	await get_tree().process_frame
	_build_ship()                            # Modelldaten sind geladen, bevor das Menü erscheint
	await get_tree().process_frame
	_build_ui()
	_set_view(View.START)
	ready_done = true
	loader.finish()


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
	box.size = Vector3(3000, 1, 3000)                  # groß genug für die Wiese (bis 500 m Pylonabstand)
	gs.shape = box
	gs.position.y = -0.5
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3000, 3000)
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
	AirshipPresets.chewie(ship)              # Startmodell: Chewie
	# Start: Bug 1 m hinter dem vorderen Pylon, Nase Richtung hinterer Pylon
	ship.transform = course.start_transform(ship)
	visual = AirshipVisual.new()
	ship.add_child(visual)
	fc = FlightController.new()
	fc.airship = ship
	ship.add_child(fc)
	add_child(ship)
	ship.config_changed.connect(_rebuild_prop_sounds)
	# Boxmaß-Ecke (nur im Baukasten sichtbar), folgt jeder Änderung am Modell
	gauge = BoxGauge.new()
	gauge.visible = false
	ship.add_child(gauge)
	ship.config_changed.connect(func(): _rebuild_gauge.call_deferred())
	_rebuild_prop_sounds()

	# Akku-Modell: rechnet vor dem Luftschiff und gibt den Schubfaktor an die Motoren
	battery = Battery.new()
	battery.name = "Battery"
	battery.ship = ship
	add_child(battery)
	# Akku-Daten kommen aus dem Modell (Baukasten → Antrieb)
	ship.config_changed.connect(func():
		if battery.cells != ship.battery_cells or absf(battery.capacity_mah - ship.battery_mah) > 0.5:
			battery.set_pack(ship.battery_cells, ship.battery_mah))
	battery.set_pack(ship.battery_cells, ship.battery_mah)

	watchdog = PerformanceWatchdog.new()
	watchdog.airship = ship
	add_child(watchdog)
	sound_guard = SoundGuard.new()
	add_child(sound_guard)
	watchdog.simplified_changed.connect(sound_guard.on_low_fps)
	sound_guard.level_changed.connect(func(_l): _rebuild_prop_sounds(true))

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
func _rebuild_prop_sounds(force := false) -> void:
	# Klangstufe (SoundGuard): Fein = je Motor, Mittel = ein Klang für alle, Einfach = Schleifen
	var lv := SoundGuard.level_for(ship.motors.size())
	var shared := lv == 1 and ship.motors.size() > 1
	var same := not force and lv == _sound_level
	if same:
		if shared:
			same = _prop_sounds.size() == 1 and _prop_sounds[0].motors == ship.motors
		else:
			same = _prop_sounds.size() == ship.motors.size()
			for i in mini(_prop_sounds.size(), ship.motors.size()):
				same = same and _prop_sounds[i].motor == ship.motors[i]
	if not same:
		for p in _prop_sounds: p.queue_free()
		_prop_sounds.clear()
		_sound_level = lv
		if ship.motors.is_empty():
			return
		if shared:
			var p := PropSynth.new()                     # ein gemeinsamer Klang in der Schiffsmitte
			p.setup_shared(ship.motors.duplicate())
			ship.add_child(p)
			_prop_sounds.append(p)
		else:
			for m in ship.motors:
				var p := PropSynth.new()                 # Fein: gleitende Tonhöhe; Einfach: Schleife
				p.setup(m)
				ship.add_child(p)
				_prop_sounds.append(p)
	for p in _prop_sounds:
		p.position = Vector3.ZERO if p.motors.size() > 1 else p.motor.position


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
	hud.course = course
	hud.battery = battery
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
	course_panel.setup(course, battery)
	root.add_child(course_panel)
	leader_panel = LeaderboardPanel.new()
	leader_panel.setup(course, ship)
	root.add_child(leader_panel)
	# Startseite, Modell & Bau, Grundlagen
	hub = ModelHub.new()
	hub.setup(ship, course)
	root.add_child(hub)
	about = AboutPanel.new()
	root.add_child(about)
	start_screen = StartScreen.new()
	start_screen.info_source = func():
		var joy := ""
		if hud._joy and hud._joy.active():
			joy = Input.get_joy_name(hud._joy.device)
		return {"model": ship.model_name, "location": tr(Course.LOCATION_NAMES[course.location]), "joy": joy}
	start_screen.preview_source = func(): return ShipPreview.texture(ship, 900)
	root.add_child(start_screen)
	start_screen.fly_requested.connect(func(): _set_view(View.FLY))
	start_screen.build_requested.connect(func(): _set_view(View.HUB))
	start_screen.about_requested.connect(func(): _set_view(View.ABOUT))
	# „Einstellungen“: vorerst das Regler-Menü (Steuerung, Modus, alles zurücksetzen)
	start_screen.settings_requested.connect(func(): _pid_back = View.START; _set_view(View.PID))
	about.closed.connect(func(): _set_view(View.START))
	hub.closed.connect(func(): _set_view(View.FLY))
	hub.home_requested.connect(func(): _set_view(View.START))
	hub.fly_requested.connect(func(): reset_ship(); _set_view(View.FLY))
	hub.edit_requested.connect(func(): _set_view(View.BUILD))
	hub.export_requested.connect(func(): _set_view(View.SHARE))
	hub.location_changed.connect(reset_ship)
	hub.calibrate_requested.connect(func(): _set_view(View.FLY); hud.open_calibration())
	hub.leaderboard_requested.connect(func(): _leader_back = View.HUB; leader_panel.show_list(); _set_view(View.LEADER))
	hud.hub_requested.connect(func(): _set_view(View.HUB))
	hud.autopilot_requested.connect(_toggle_autopilot)

	hud.reset_requested.connect(func():
		# Schalter SH / Zurücksetzen: im Bestenlisten-Fenster bestätigt bzw. schließt er es
		if view == View.LEADER:
			leader_panel.confirm_by_switch()
		else:
			reset_ship())
	# Autopilot: fliegt live die aktuelle Strecke (aktuelles Modell, aktuelle Reglerwerte)
	autopilot = Autopilot.new()
	autopilot.ship = ship; autopilot.fc = fc; autopilot.course = course; autopilot.battery = battery
	add_child(autopilot)
	autopilot.finished.connect(func(): hud.autopilot_active = false)
	autopilot.failed.connect(func(reason: String):
		hud.show_notice("%s: %s (%s)" % [tr("Autopilot"), tr(reason), course.race_text()], "warning", 6.0))
	course_panel.closed.connect(func(): _set_view(View.FLY))
	course_panel.course_changed.connect(reset_ship)
	course_panel.leaderboard_requested.connect(func(): leader_panel.show_list(); _set_view(View.LEADER))
	leader_panel.closed.connect(func(): _set_view(_leader_back); _leader_back = View.FLY)
	# Auswahl Eintragen/Nicht eintragen mit dem rechten Senderknüppel (links/rechts)
	leader_panel.stick_source = func(): return hud._joy.right.x if hud._joy and hud._joy.active() else 0.0
	course.race_changed.connect(_on_race_changed)
	# Modellwahl im Baukasten: PID-Standardwerte des Modells übernehmen
	ship.model_applied.connect(func():
		fc.apply_model_gains(ship.fc_gains)
		if fc.preset == "sim":                       # Reglerwahl „Sim-optimiert“ bleibt bestehen
			fc.apply_overrides(fc.SIM_OPT)
			fc.save_settings())
	# Erster Start (oder Einstellungen aus älterer Version): PID-Vorgaben des
	# Startmodells übernehmen; danach bleiben die eigenen Werte erhalten.
	if fc.settings_outdated:
		fc.apply_model_gains(ship.fc_gains)
	builder.closed.connect(func(): _set_view(View.HUB))
	builder.share_requested.connect(func(): _set_view(View.SHARE))
	builder.pid_requested.connect(func(): _pid_back = View.BUILD; _set_view(View.PID))
	builder.view_reset_requested.connect(reset_view)
	builder.ui_action.connect(ui_sounds.chime)
	share.ui_action.connect(ui_sounds.chime)
	share.closed.connect(func(): _set_view(View.BUILD))
	pid.closed.connect(func(): _set_view(_pid_back); _pid_back = View.FLY)
	pid.reset_all_requested.connect(reset_all_settings)
	watchdog.notice.connect(func(t): hud.show_notice(t, "warning"))
	sound_guard.notice.connect(func(t): hud.show_notice(t, "warning", 3.0))
	ar.ar_state_changed.connect(func(_on, msg): hud.show_notice(msg, "info", 2.0))


## Autopilot an/aus. An: Schiff an den Start (voller Akku), dann übernimmt der
## Autopilot mit dem aktuellen Modell und den aktuellen Reglerwerten.
func _toggle_autopilot() -> void:
	if autopilot.active or hud.autopilot_active:
		reset_ship()                                  # Stoppen = Zurücksetzen
		return
	reset_ship()
	hud.autopilot_active = true
	hud.show_notice(tr("Autopilot") + " – " + tr("Zurücksetzen") + " = Stopp", "info", 4.0)
	await get_tree().create_timer(0.2).timeout
	if hud.autopilot_active:
		autopilot.start()


## Schiff an den Startpunkt zurück (Nase Richtung Pylon 2), Regler neu starten.
## Der Motor-Schalter bleibt, wie er ist – der Gasknüppel steht ja in der Mitte.
func reset_ship() -> void:
	if autopilot and autopilot.active:
		autopilot.stop()                              # Zurücksetzen beendet den Autopiloten
	hud.autopilot_active = false
	ship.reset_to(course.start_transform(ship))
	fc._reset_integrators()
	course.reset_race()
	if battery:
		battery.recharge()                            # neuer Start = voller Akku
	hud.show_notice("Zurückgesetzt", "info", 1.5)


## Rennen im Ziel: Schafft die Zeit die Top 10, Namen für die Bestenliste
## abfragen (Motoren aus, damit das Schiff nicht weiterfliegt).
func _on_race_changed() -> void:
	if course.race != Course.Race.DONE or view == View.LEADER:
		return
	if autopilot and autopilot.active:
		# Autopilot im Ziel: Zeit zeigen, nichts in die Bestenliste
		hud.show_notice("%s · %s (%s)" % [tr("Autopilot"), Course.format_time(course.time_s), course.lap_text()], "info", 6.0)
		autopilot.stop()
		return
	if Leaderboard.rank_for(course.course_key(), course.time_s) > 0:
		fc.armed = false
		leader_panel.show_result()
		_set_view(View.LEADER)
	else:
		hud.show_notice("Ziel · %s – nicht unter den besten %d" % [Course.format_time(course.time_s), Leaderboard.MAX_ENTRIES], "info", 4.0)


## Rundenzählung: Bug-Position an die Strecke melden, Anzeige im HUD.
func _physics_process(dt: float) -> void:
	if not ready_done: return
	if view == View.BUILD or view == View.SHARE:
		return                                  # Schiff steht im Baukasten fest
	var nose := ship.global_transform * Vector3(0, 0, -ship.hull.cb_from_nose)
	course.track(nose.x, nose.z, dt)
	hud.set_race_text(course.race_text(), course.lap_text())


## Knopf „Alle Einstellungen zurücksetzen“ (PID-Menü): Flugcontroller auf
## Werkseinstellung + Vorgaben des aktuellen Modells, Strecke auf den
## FN Hugo Eckener Cup, Schiff an den Start. Bestenliste und eigene Modelle
## bleiben erhalten.
func reset_all_settings() -> void:
	fc.armed = false
	fc.reset_to_defaults(ship.fc_gains)
	FcBlocks.clear()                                  # Bausteine wieder alle an (Werte sind jetzt Werkseinstellung)
	course.set_course(0, 25.0)
	reset_ship()
	pid._sync()
	hud.show_notice("Alle Einstellungen zurückgesetzt", "info", 2.0)


## Boxmaß-Ecke an den aktuellen Umriss des Schiffs anpassen.
func _rebuild_gauge() -> void:
	if gauge.visible:
		gauge.rebuild(visual.local_aabb(), ship.cg_offset)


## Baukasten-Ansicht auf Standard zurück (genau von der Seite, leicht von oben).
func reset_view() -> void:
	_orbit_yaw = 0.0
	_orbit_pitch = 0.3
	_orbit_zoom = 1.0


# =============================================================================
# Gesten im Baukasten (nur in der freien Mitte – Bedienfelder fangen ihre
# Berührungen selbst ab):  1 Finger ziehen = drehen, 2 Finger = zoomen.
# Am PC: mit gedrückter Maus ziehen = drehen, Mausrad = zoomen.
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if not ready_done: return
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
	leader_panel.visible = v == View.LEADER
	start_screen.visible = v == View.START
	hub.visible = v == View.HUB
	about.visible = v == View.ABOUT
	if v != View.FLY and autopilot and autopilot.active:
		reset_ship()                                  # Ansicht verlassen beendet den Autopiloten
	if v == View.START or v == View.HUB or v == View.ABOUT:
		fc.armed = false                              # außerhalb der Flugansicht: Motoren aus
	# Baukasten/Teilen: Motoren aus, Schiff festhalten, ruhiger Klangteppich.
	# Flug/PID: kein Klangteppich – zu hören sind nur die Motoren.
	var workshop := v == View.BUILD or v == View.SHARE
	if workshop:
		fc.armed = false
	ship.freeze = workshop
	if workshop:
		# Baukasten: Schiff waagrecht an den Start (Seitenansicht), Boxmaß-Ecke zeigen
		if not gauge.visible:
			ship.global_transform = course.start_transform(ship)
			ship.linear_velocity = Vector3.ZERO
			ship.angular_velocity = Vector3.ZERO
			_orbit_yaw = 0.0
			_orbit_pitch = 0.3
			_orbit_zoom = 1.0
		_rebuild_gauge.call_deferred()
	gauge.visible = workshop
	# Werkstatt: Strecke und Halle ausblenden, nur das Schiff in der Messecke
	course.visible = not workshop
	_scenery.visible = not workshop
	if not workshop:
		camera.h_offset = 0.0
	visual.set_workshop(workshop)          # Restmasse + Schwerpunkt nur im Baukasten zeigen
	ui_sounds.set_pad(workshop)


# =============================================================================
# Kamera: hinter dem Schiff (Flug) oder seitlich (Baukasten)
# =============================================================================
func _process(dt: float) -> void:
	if not ready_done: return
	var p := ship.global_position
	var L := ship.hull.length_m
	var a := clampf(dt * 3.0, 0.0, 1.0)
	if view == View.BUILD or view == View.SHARE:
		# Baukasten: von der rechten Seite auf das Schiff in der Boxmaß-Ecke
		# (drehen/zoomen per Gesten). Abstand so, dass Schiff + Maße in die
		# freie Mitte zwischen den Spalten passen; h_offset schiebt das Bild,
		# damit es genau mittig zwischen den Spalten steht.
		var box := gauge.extent if gauge.extent.size.z > 0.01 else visual.local_aabb()   # Ecke samt Maßen
		var c_local := box.get_center()
		c_local.x = 0.0                                             # quer: auf die Schiffsmitte
		p = ship.global_transform * c_local
		var vp := camera.get_viewport().get_visible_rect().size
		var span := builder.free_span() if view == View.BUILD else Vector2(0, builder.size.x)
		var ui_w := maxf(builder.size.x, 1.0)
		var ui_h := maxf(builder.size.y, 1.0)
		var tan_h := tan(deg_to_rad(FOV) * 0.5)
		var aspect := vp.x / maxf(vp.y, 1.0)
		var free_frac := clampf((span.y - span.x) / ui_w, 0.2, 1.0)
		var need_w := box.size.z * 1.2                              # Ecke mit allen Maßen + Rand
		var need_h := box.size.y * 1.5
		var dist := maxf(need_w / (2.0 * tan_h * aspect * free_frac), need_h / (2.0 * tan_h)) * _orbit_zoom
		var off_l := Vector3(dist, 0, 0).rotated(Vector3(0, 0, 1), _orbit_pitch).rotated(Vector3.UP, _orbit_yaw)
		var off := ship.global_basis * off_l
		camera.global_position = camera.global_position.lerp(p + off, clampf(dt * 10.0, 0.0, 1.0))
		# Bildmitte auf die Mitte der freien Fläche schieben
		var shift_ui := (span.x + span.y) * 0.5 - ui_w * 0.5
		camera.h_offset = -shift_ui / ui_h * 2.0 * dist * tan_h
	elif hud.perspective == 1 or hud.perspective == 2:
		# Hinterher: Kamera hinter und etwas über dem Schiff
		var b := ship.global_transform.basis
		if hud.perspective == 1:
			# Horizont bleibt waagrecht: nur die Kursrichtung des Schiffs zählt
			var fwd := -b.z
			fwd.y = 0.0
			if fwd.length() < 0.1:
				fwd = Vector3.FORWARD
			fwd = fwd.normalized()
			var want := p - fwd * L * 1.5 + Vector3.UP * L * 0.35
			camera.global_position = camera.global_position.lerp(want, clampf(dt * 6.0, 0.0, 1.0))
			if camera.global_position.distance_to(p) > 0.01:
				camera.look_at(p + Vector3.UP * L * 0.1, Vector3.UP)
		else:
			# Hinterher + Lage: Kamera fest am Schiff, rollt und nickt mit
			var want := ship.global_transform * Vector3(0, L * 0.35, L * 1.5)
			camera.global_position = camera.global_position.lerp(want, clampf(dt * 8.0, 0.0, 1.0))
			var target := Transform3D(Basis(), camera.global_position).looking_at(p + b.y * L * 0.1, b.y)
			camera.global_basis = camera.global_basis.slerp(target.basis.orthonormalized(), clampf(dt * 8.0, 0.0, 1.0)).orthonormalized()
		return
	else:
		# Flug: fester Pilotenstandort, Blick folgt dem Schiff (fester Bildwinkel)
		camera.global_position = camera.global_position.lerp(PILOT_EYE, a)
	if camera.global_position.distance_to(p) > 0.01:
		camera.look_at(p, Vector3.UP)
