# 2026-11-16 15:45 – Läuft weiter statt nach 6,5 s zu enden; step_now() setzt weitere Sprünge in den laufenden Flug; Neustart mit der Fahrt vom letzten Mal (1 s Anlauf); Plot bekommt nur die letzte Sekunde vor dem Sprung
# 2026-11-16 12:40 – Erstversion: Prüfstand für die Sprungantwort im Reglermenü – eine Kopie des Luftschiffs fliegt in einer eigenen, unsichtbaren Physikwelt geradeaus, dann kommt der Sprung (vorher stand das echte Schiff im Menü still → blaue Ist-Linie blieb flach)
# =============================================================================
# StepBench.gd  (Kind des Reglermenüs)
# -----------------------------------------------------------------------------
# Warum: Im Reglermenü steht das Luftschiff (aus dem Baukasten kommend) ohne
# Fahrt am Start. Ohne Anströmung bewirken Ruder nichts – der Sprung wurde
# gezeichnet (grau), die gemessene Lage (blau) blieb aber gerade.
#
# Ablauf von run(axis, amount):
#   1. Eigene Physikwelt (SubViewport mit eigener World3D, zeichnet nichts)
#   2. Kopie des Luftschiffs (über den Modell-Code) + eigener Flugcontroller
#      mit denselben Modi, PID-Werten und allgemeinen Einstellungen
#   3. Anlauf: TEST_THROTTLE Gas, Schiff wird PRE_ROLL Sekunden waagrecht
#      geradeaus geführt (Linie läuft schon mit – Ruhelage vor dem Sprung)
#   4. Sprung für STEP_TIME Sekunden; danach fliegt die Kopie einfach weiter,
#      weitere Sprünge mit step_now() landen in der laufenden Antwort
#   5. stop() (Menü zu) entfernt die Welt; run() startet neu (z. B. nach Änderung)
# Das Gas setzt hier der Prüfstand fest (nur Simulation, kein echter Regler).
# Die Messwerte kommen über das Signal loop_sample der Kopie – genau wie beim
# echten Flugcontroller.
# =============================================================================
class_name StepBench
extends Node

## Messwert der Kopie (wie FlightController.loop_sample)
signal sample(axis: int, setpoint: float, measurement: float)
## Sprung beginnt jetzt (Fahrt in m/s)
signal step_started(speed: float)

const TEST_THROTTLE := 0.6     ## Gas im Prüfstand (Anteil von Vollgas)
const PRE_ROLL_FIRST := 2.5    ## s Anlauf beim ersten Start (Fahrt muss erst entstehen)
const PRE_ROLL := 1.0          ## s Anlauf bei Neustart (Fahrt vom letzten Durchgang)
const SHOW_PRE := 1.0          ## s vor dem Sprung, die im Plot zu sehen sind
const STEP_TIME := 3.0         ## s Dauer des Sprungs

var _vp: SubViewport
var _ship: AirshipPhysics
var _fc: FlightController
var _t := 0.0
var _pre := PRE_ROLL_FIRST
var _stepped := false
var _axis := 0
var _amount := 0.0
## Fahrt am Ende des letzten Anlaufs (m/s) – Neustarts beginnen damit
var _last_speed := 0.0


## Läuft gerade ein Durchgang?
func busy() -> bool:
	return _vp != null


## Durchgang (neu) starten: Kopie von src_fc.airship mit den Einstellungen von
## src_fc, Anlauf, dann Sprung. Danach fliegt die Kopie weiter, bis stop().
func run(src_fc: FlightController, axis: int, amount: float) -> void:
	stop()
	if src_fc == null or src_fc.airship == null:
		return
	_axis = axis
	_amount = amount
	_t = 0.0
	_stepped = false
	_pre = PRE_ROLL if _last_speed > 0.5 else PRE_ROLL_FIRST
	# 1. eigene Physikwelt – nichts wird gezeichnet
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = Vector2i(2, 2)
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	# 2. Kopie des Luftschiffs über den Modell-Code (gleiche Bauteile, Massen, Trimm)
	_ship = AirshipPhysics.new()
	ShipRender3D.copy_of(src_fc.airship).call(_ship)
	_vp.add_child(_ship)
	_ship.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 50, 0))   # frei im Raum, Nase −Z
	_ship.linear_velocity = Vector3(0, 0, -maxf(_last_speed, 2.0))             # Fahrt vom letzten Mal
	_ship.angular_velocity = Vector3.ZERO
	# eigener Flugcontroller mit denselben Einstellungen wie der echte
	_fc = FlightController.new()
	_fc.airship = _ship
	_ship.add_child(_fc)                     # _ready lädt die gespeicherten Einstellungen
	_fc.modes = src_fc.modes.duplicate(true)
	_fc.params = src_fc.params.duplicate(true)
	for k in FlightController.GENERAL_KEYS:
		_fc.set(k, src_fc.get(k))
	_fc.mode_index = src_fc.mode_index
	_fc.armed = true
	# 3. Anlauf: festes Gas, alle anderen Knüppel in der Mitte
	_fc.cmd_throttle = TEST_THROTTLE
	_fc.cmd_pitch = 0.0
	_fc.cmd_yaw = 0.0
	_fc.cmd_aux = 0.0
	# Messwerte erst SHOW_PRE s vor dem Sprung weitergeben (Plot zeigt Ruhelage + Antwort)
	_fc.loop_sample.connect(func(a, sp, pv):
		if _t >= _pre - SHOW_PRE: sample.emit(a, sp, pv))


## Weiteren Sprung in den laufenden Flug setzen (ohne Neustart).
func step_now(axis: int, amount: float) -> void:
	if _fc == null or not _stepped:
		return
	_axis = axis
	_amount = amount
	_fc.trigger_step(axis, amount, STEP_TIME)
	step_started.emit(_ship.airspeed)


## Durchgang beenden (Menü zu) – die unsichtbare Welt wird entfernt.
func stop() -> void:
	if _vp:
		_vp.queue_free()
	_vp = null
	_ship = null
	_fc = null


func _physics_process(dt: float) -> void:
	if _vp == null or _fc == null:
		return
	_t += dt
	_fc.cmd_throttle = TEST_THROTTLE        # Gas bleibt fest (nur Simulation)
	# Anlauf „eingespannt“: das Schiff wird waagrecht geradeaus geführt, nur die
	# Fahrt baut sich auf. So beginnt jeder Sprung aus ruhigem Geradeausflug –
	# auch im Modus Direkt, in dem es sonst ohne Pilot hochnicken würde.
	if not _stepped:
		var speed := maxf(-_ship.linear_velocity.z, 0.0)
		var rid := _ship.get_rid()
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM,
			Transform3D(Basis.IDENTITY, Vector3(0, 50, _ship.global_position.z)))
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3(0, 0, -speed))
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)
	# 4. nach dem Anlauf: Sprung auslösen – danach fliegt die Kopie weiter
	if not _stepped and _t >= _pre:
		_stepped = true
		_last_speed = maxf(-_ship.linear_velocity.z, 0.0)
		_fc.trigger_step(_axis, _amount, STEP_TIME)
		step_started.emit(_ship.airspeed)
	# die Kopie fliegt weit weg – zurück an den Ursprung, damit Zahlen klein bleiben
	if _stepped and _ship.global_position.length() > 2000.0:
		var tr := _ship.global_transform
		tr.origin = Vector3(0, 50, 0)
		PhysicsServer3D.body_set_state(_ship.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, tr)
