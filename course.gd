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
		Race.RUN: return "Runde %d/%d · %s" % [lap, LAPS, format_time(time_s)]
		_: return "Ziel · %s" % format_time(time_s)


## Zeile unter der Rundenanzeige: nächster Kontrollpunkt und Rundenzeiten
## (fertige Runden, am Ende mit bester Runde).
func lap_text() -> String:
	var parts: Array[String] = []
	if race == Race.WAIT:
		return "Pilotenseite, Richtung Pylon 2"
	if race == Race.RUN:
		parts.append("nächster: " + GATE_NAMES[next_gate])
	var best := 0
	for i in lap_times.size():
		parts.append("R%d %s" % [i + 1, format_time(lap_times[i])])
		if lap_times[i] < lap_times[best]: best = i
	var txt := "   ".join(parts)
	if parts.is_empty(): return ""
	if race == Race.DONE:
		txt += "   · beste: R%d" % (best + 1)
	return txt


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
