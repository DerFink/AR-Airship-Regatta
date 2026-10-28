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
# Rennablauf (fliegender Start):
#   WARTEN  – Schiff schwebt 1 m hinter dem vorderen Pylon. Überquert der Bug
#             die Linie des vorderen Pylons, startet die Zeit (Runde 1).
#   LAUF    – Bug überquert die Linie des hinteren Pylons → hinterer Pylon grün.
#             Danach Linie des vorderen Pylons → hinterer Pylon wieder rot,
#             Runde fertig. Nach 3 Runden: Zeit steht (ZIEL).
# Jedes Überqueren zählt, egal in welcher Höhe und ob innerhalb des Rechtecks.
# =============================================================================
class_name Course
extends Node3D

## Runde begonnen/fertig, Zeit gestartet/gestoppt → HUD neu beschriften
signal race_changed

enum Race { WAIT, RUN, DONE }

const CUP_NAME := "FN Hugo Eckener Cup"
const CUP_DISTANCE := 18.0
const MIN_DISTANCE := 5.0
const MAX_DISTANCE := 50.0
const PYLON_HEIGHT := 5.0
const FIELD_MARGIN := 3.5        ## Rechteck reicht so weit vor/hinter die Pylone
const FIELD_WIDTH := 20.0
const LINE_WIDTH := 0.10
const START_BEHIND := 1.0        ## Bug steht so weit hinter der Linie des vorderen Pylons
const START_HEIGHT := 4.0
const LAPS := 3
const SETTINGS_PATH := "user://strecke.cfg"

const COLOR_RED := Color("e5534b")
const COLOR_GREEN := Color("3fb27f")

## 0 = FN Hugo Eckener Cup (18 m), 1 = frei einstellbar
var preset := 0
## Abstand bei „frei“ (m)
var free_distance := 25.0

var race := Race.WAIT
var lap := 0                     ## laufende Runde (1…LAPS)
var time_s := 0.0
var far_green := false

var _far_mat := StandardMaterial3D.new()
var _prev_nose_x := NAN


func _ready() -> void:
	load_settings()
	rebuild()


## Aktueller Pylonabstand in m.
func distance() -> float:
	return CUP_DISTANCE if preset == 0 else free_distance


## Name für die Anzeige.
func title() -> String:
	return CUP_NAME if preset == 0 else "Freie Strecke %d m" % roundi(free_distance)


# =============================================================================
# Pylone und Rechteck aufbauen (bei jeder Abstandsänderung)
# =============================================================================
func rebuild() -> void:
	for c in get_children(): c.queue_free()
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


## Startlage des Schiffs: Bug 1 m hinter der Linie des vorderen Pylons,
## Nase Richtung hinterer Pylon (+X), freischwebend in 4 m Höhe.
func start_transform(ship: AirshipPhysics) -> Transform3D:
	var x := -START_BEHIND - ship.hull.cb_from_nose
	return Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(x, START_HEIGHT, 0.0))


# =============================================================================
# Rennen
# =============================================================================
func reset_race() -> void:
	race = Race.WAIT
	lap = 0
	time_s = 0.0
	_set_far_green(false)
	_prev_nose_x = NAN
	race_changed.emit()


## Jeden Physikschritt mit der Bug-Position (Welt-X) aufrufen.
func track(nose_x: float, dt: float) -> void:
	if race == Race.RUN:
		time_s += dt
	if is_nan(_prev_nose_x):
		_prev_nose_x = nose_x
		return
	var d := distance()
	var crossed_far := (_prev_nose_x - d) * (nose_x - d) < 0.0
	var crossed_near := _prev_nose_x * nose_x < 0.0
	var forward_near := _prev_nose_x < 0.0 and nose_x >= 0.0
	_prev_nose_x = nose_x
	# Hinterer Pylon: jedes Überqueren schaltet auf grün
	if crossed_far and not far_green:
		_set_far_green(true)
	if crossed_near:
		match race:
			Race.WAIT:
				if forward_near:                      # fliegender Start
					race = Race.RUN
					lap = 1
					time_s = 0.0
					race_changed.emit()
			Race.RUN:
				if far_green:                         # zurück am vorderen Pylon: Runde fertig
					_set_far_green(false)
					if lap >= LAPS:
						race = Race.DONE
					else:
						lap += 1
					race_changed.emit()
			Race.DONE:
				if far_green: _set_far_green(false)


func _set_far_green(on: bool) -> void:
	far_green = on
	_far_mat.albedo_color = COLOR_GREEN if on else COLOR_RED


## Text für die Anzeige im HUD.
func race_text() -> String:
	match race:
		Race.WAIT: return "Start: vorderen Pylon passieren"
		Race.RUN: return "Runde %d/%d · %s" % [lap, LAPS, format_time(time_s)]
		_: return "Ziel · %s" % format_time(time_s)


static func format_time(t: float) -> String:
	var m := int(t / 60.0)
	var s := t - m * 60.0
	return ("%d:%04.1f" % [m, s]).replace(".", ",")


# =============================================================================
# Einstellungen
# =============================================================================
func set_course(new_preset: int, new_free_distance: float) -> void:
	preset = clampi(new_preset, 0, 1)
	free_distance = clampf(new_free_distance, MIN_DISTANCE, MAX_DISTANCE)
	save_settings()
	rebuild()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("strecke", "preset", preset)
	cfg.set_value("strecke", "frei_abstand", free_distance)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	preset = clampi(int(cfg.get_value("strecke", "preset", preset)), 0, 1)
	free_distance = clampf(float(cfg.get_value("strecke", "frei_abstand", free_distance)), MIN_DISTANCE, MAX_DISTANCE)
