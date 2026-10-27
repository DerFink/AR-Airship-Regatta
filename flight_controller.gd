# 2026-10-27 11:08 – Mischer nutzt den Schub mit Vorzeichen (Rückwärtsschub kehrt die Schwenkwirkung um) und den reduzierten Rückwärts-Wirkungsgrad
# 2026-10-27 10:33 – Stick-Belegung neu: Gier immer rechter Knüppel X, linker Knüppel X frei (Aux), kein Roll-Stick mehr (Roll nur noch auf 0° stabilisiert); Stick-Modes auf 1/2 reduziert; stick_labels() für das HUD
# 2026-10-27 10:48 – Erstversion: 3 Modi (direkt / geregelt / geregelt ohne Vektor), PID je Achse, Stick-Modes 1–4, geometrischer Mischer Aero↔Vektor, Failsafe, UI-Parametertabelle, Speichern/Laden
# =============================================================================
# FlightController.gd  (als Kind-Node des Luftschiffs)
# -----------------------------------------------------------------------------
# Virtueller Flugcontroller im Stil eines Teensy-FC (dRehmFlight-Prinzip):
#
#   Sticks ──► Sollwerte ──► PID je Achse ──► Mischer ──► Ruder / Motoren
#
# Modi (entsprechen einem 3-Stufen-Schalter):
#   DIRECT            Mode 1: Stickbefehle gehen ungeregelt an den Mischer
#   STABILIZED        Mode 2: Nick/Roll lagegeregelt, Gier drehratengeregelt;
#                             Ruder UND Schwenkmotoren werden genutzt
#   STABILIZED_NO_VEC Mode 3: eigener PID-Satz, Schwenkmotoren NICHT geregelt
#                             (folgen direkt dem Nick-Stick)
#
# Der Mischer verteilt die gewünschten Drehmomente automatisch anhand der
# Bauteil-Geometrie auf alle Stellglieder – egal wo im Baukasten sie sitzen.
# Bei wenig Fahrt verlagert er die Arbeit auf die Schwenkmotoren, weil die
# Ruder dann kaum Wirkung haben.
#
# Achsen-Konvention (Körpersystem): Nick hoch = +X-Moment,
# Gier rechts = −Y-Moment, Roll rechts = −Z-Moment.
# =============================================================================
class_name FlightController
extends Node

signal mode_changed(mode: int)
signal pid_changed(mode: int, axis: int, term: String, value: float)
## Für die Live-Sprungantwort im PID-Menü.
signal loop_sample(axis: int, setpoint: float, measurement: float)

enum Mode { DIRECT, STABILIZED, STABILIZED_NO_VEC }
enum Axis { ROLL, PITCH, YAW }
enum MixMode { BLEND, AERO_ONLY, VECTOR_ONLY }

const SETTINGS_PATH := "user://flight_controller.cfg"

@export var airship: AirshipPhysics
@export var mode: Mode = Mode.DIRECT:
	set(v): mode = v; _reset_integrators(); mode_changed.emit(v)
@export var mix_mode: MixMode = MixMode.BLEND
## Stick-Belegung. Gier liegt IMMER auf dem rechten Knüppel (links/rechts),
## weil aktives Rollen beim Luftschiff keine Rolle spielt.
##   Mode 2 (Standard): links hoch/runter = Gas,  rechts hoch/runter = Nick
##   Mode 1:            links hoch/runter = Nick, rechts hoch/runter = Gas
## Linker Knüppel links/rechts bleibt frei (cmd_aux, z. B. für spätere Funktionen).
@export_range(1, 2, 1) var stick_mode: int = 2

@export_group("Sollwert-Grenzen")
@export var max_angle_deg: float = 30.0        ## Lagemodus: voller Stick = ±30°
@export var max_yaw_rate_dps: float = 60.0     ## voller Stick = ±60 °/s
@export_group("Mischer")
## Fahrt, unter der nur die Motoren steuern / über der nur die Ruder.
@export var blend_speed_low: float = 1.0
@export var blend_speed_high: float = 4.0
## Mindest-Staudruck für die Ruder-Zuordnung, damit Ruder auch im Stand
## ausschlagen (Bodentest). Entspricht ~3 m/s.
@export var alloc_q_floor: float = 5.4
## Ausschlagsbegrenzung aller Ruder (0,5 = 50 %).
@export_range(0.1, 1.0, 0.05) var output_limit: float = 0.5
## Anteil des Gier-Befehls, der als Differenzschub an die Motoren geht.
@export_range(0.0, 1.0, 0.05) var yaw_diff_thrust: float = 0.3

# --- Eingänge -----------------------------------------------------------------
var stick_left := Vector2.ZERO     ## −1..+1, Y nach oben positiv
var stick_right := Vector2.ZERO
var armed := false:
	set(v):
		armed = v
		if airship:
			for m in airship.motors: m.armed = v

# Abgeleitete Pilotbefehle (nach Stick-Mode)
var cmd_throttle := 0.0
var cmd_roll := 0.0      ## bleibt 0: Roll wird nur auf waagrecht stabilisiert
var cmd_pitch := 0.0
var cmd_yaw := 0.0
var cmd_aux := 0.0       ## linker Knüppel links/rechts – derzeit unbelegt


# =============================================================================
# PID-Regler (D-Anteil auf den Messwert/Drehrate wie bei dRehmFlight,
# Anti-Windup durch Begrenzung des I-Anteils, Tiefpass auf D)
# =============================================================================
class PID:
	var kp := 0.0
	var ki := 0.0
	var kd := 0.0
	var i_limit := 0.3          ## max. Anteil des Integrators am Ausgang
	var d_filter_hz := 20.0     ## Tiefpass für den D-Anteil
	var _integral := 0.0
	var _d_state := 0.0

	func _init(p := 0.0, i := 0.0, d := 0.0) -> void:
		kp = p; ki = i; kd = d

	func reset() -> void:
		_integral = 0.0
		_d_state = 0.0

	## error: Soll−Ist; rate: gemessene Drehrate (für D); Rückgabe −1..+1
	func update(error: float, rate: float, dt: float) -> float:
		_integral = clampf(_integral + error * ki * dt, -i_limit, i_limit)
		var a := clampf(dt * TAU * d_filter_hz, 0.0, 1.0)
		_d_state = lerpf(_d_state, rate, a)
		return clampf(kp * error + _integral - kd * _d_state, -1.0, 1.0)


# Ein PID-Satz pro Modus und Achse. DIRECT braucht keinen, hat aber für die
# UI-Konsistenz dieselbe Struktur.
var pids := {}

func _init() -> void:
	for m in Mode.values():
		pids[m] = {
			# Nick und Roll gleich stark gewichtet, Gier schwach (Luftschiff)
			Axis.ROLL:  PID.new(0.9, 0.10, 0.30),
			Axis.PITCH: PID.new(0.9, 0.10, 0.30),
			Axis.YAW:   PID.new(0.4, 0.05, 0.00),
		}
	# Mode 3 startet etwas weicher
	pids[Mode.STABILIZED_NO_VEC][Axis.ROLL].kp = 0.7
	pids[Mode.STABILIZED_NO_VEC][Axis.PITCH].kp = 0.7


func _ready() -> void:
	load_settings()


# =============================================================================
# Failsafe: App im Hintergrund / Fokus weg → Motoren sofort aus
# =============================================================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		armed = false


# =============================================================================
# Stick-Belegung → Gas, Nick, Gier (Gier immer rechter Knüppel X)
# =============================================================================
func set_sticks(left: Vector2, right: Vector2) -> void:
	stick_left = left
	stick_right = right
	cmd_yaw = right.x                     # Gier: immer rechts, links/rechts
	cmd_aux = left.x                      # frei
	cmd_roll = 0.0                        # kein aktives Rollen
	if stick_mode == 1:
		cmd_pitch = left.y; cmd_throttle = right.y
	else:                                 # Mode 2 (Standard)
		cmd_throttle = left.y; cmd_pitch = right.y


## Beschriftung der Knüppel für das HUD (passt sich dem Stick-Mode an).
func stick_labels() -> Array[String]:
	if stick_mode == 1:
		return ["Nick", "Gas · Gier"]
	return ["Gas", "Nick · Gier"]


# =============================================================================
# Regelschleife (läuft vor dem Physikschritt des Luftschiffs)
# =============================================================================
func _physics_process(dt: float) -> void:
	if airship == null:
		return
	var b := airship.global_transform.basis.orthonormalized()
	var w_b := b.transposed() * airship.angular_velocity

	# --- Ist-Lage und Drehraten -------------------------------------------
	var pitch := asin(clampf(-b.z.y, -1.0, 1.0))          # Nase hoch = +
	var roll := atan2(-b.x.y, b.y.y)                       # rechts hängend = +
	var rate_pitch := w_b.x
	var rate_roll := -w_b.z
	var rate_yaw := -w_b.y

	# --- Drehmoment-Wünsche (−1..+1) je Achse ---------------------------
	var u_roll := 0.0
	var u_pitch := 0.0
	var u_yaw := 0.0
	if mode == Mode.DIRECT:
		u_roll = cmd_roll; u_pitch = cmd_pitch; u_yaw = cmd_yaw
	else:
		var pid_set: Dictionary = pids[mode]
		var sp_pitch := cmd_pitch * deg_to_rad(max_angle_deg)
		var sp_roll := cmd_roll * deg_to_rad(max_angle_deg)
		var sp_yaw := cmd_yaw * deg_to_rad(max_yaw_rate_dps)
		u_pitch = pid_set[Axis.PITCH].update(sp_pitch - pitch, rate_pitch, dt)
		u_roll = pid_set[Axis.ROLL].update(sp_roll - roll, rate_roll, dt)
		u_yaw = pid_set[Axis.YAW].update(sp_yaw - rate_yaw, 0.0, dt)   # Ratenregler
		loop_sample.emit(Axis.PITCH, sp_pitch, pitch)
		loop_sample.emit(Axis.ROLL, sp_roll, roll)
		loop_sample.emit(Axis.YAW, sp_yaw, rate_yaw)

	# Wunsch-Drehmoment im Körpersystem (Vorzeichen siehe Kopfkommentar)
	var tau_cmd := Vector3(u_pitch, -u_yaw, -u_roll)
	_mix(tau_cmd)


# =============================================================================
# Geometrischer Mischer (gewichtete Pseudo-Inverse)
# -----------------------------------------------------------------------------
# Jedes Stellglied i hat einen Wirkvektor B_i = Moment bei Vollausschlag.
# Gesucht sind Ausschläge u_i, die das Wunschmoment τ erzeugen:
#     u = W·Bᵀ·(B·W·Bᵀ + λI)⁻¹ · τ
# W gewichtet Ruder gegen Motoren je nach Fahrt und Mischmodus.
# =============================================================================
func _mix(tau_cmd: Vector3) -> void:
	var cg := airship.cg_offset
	var v := airship.airspeed
	var q_alloc := maxf(0.5 * airship.air_density * v * v, alloc_q_floor)

	# Gewichte: wenig Fahrt → Motoren, viel Fahrt → Ruder
	var s := clampf((v - blend_speed_low) / maxf(blend_speed_high - blend_speed_low, 0.01), 0.0, 1.0)
	var w_aero := s + 0.05
	var w_vec := (1.0 - s) + 0.05
	match mix_mode:
		MixMode.AERO_ONLY: w_vec = 0.0; w_aero = 1.0
		MixMode.VECTOR_ONLY: w_aero = 0.0; w_vec = 1.0
	if mode == Mode.STABILIZED_NO_VEC:
		w_vec = 0.0                     # Mode 3: Schwenker nicht im Regelkreis

	# --- Wirkvektoren sammeln -------------------------------------------
	var cols: Array[Vector3] = []
	var weights: Array[float] = []
	for srf in airship.surfaces:
		cols.append(srf.moment_per_rad(cg) * q_alloc * deg_to_rad(srf.max_deflection_deg))
		weights.append(w_aero)
	for mot in airship.motors:
		# Schub MIT Vorzeichen: bei Rückwärtsschub kehrt sich die Schwenkwirkung um,
		# der Mischer schwenkt dann automatisch in die Gegenrichtung.
		var ref := mot.signed_thrust_estimate(cmd_throttle)
		cols.append(mot.moment_per_rad_swivel(cg, ref) * deg_to_rad(mot.max_swivel_deg))
		weights.append(w_vec)

	# Autorität je Achse = Summe der Beträge → Stick 100 % fordert "alles"
	var authority := Vector3.ZERO
	for i in cols.size():
		authority += cols[i].abs() * weights[i]
	var tau := tau_cmd * authority

	# --- M = B·W·Bᵀ + λI  (3×3, symmetrisch) -----------------------------
	var m00 := 0.0; var m01 := 0.0; var m02 := 0.0
	var m11 := 0.0; var m12 := 0.0; var m22 := 0.0
	for i in cols.size():
		var c := cols[i]; var w := weights[i]
		m00 += w * c.x * c.x; m01 += w * c.x * c.y; m02 += w * c.x * c.z
		m11 += w * c.y * c.y; m12 += w * c.y * c.z; m22 += w * c.z * c.z
	var lam := 1e-6 + 1e-3 * (m00 + m11 + m22)
	var M := Basis(Vector3(m00 + lam, m01, m02), Vector3(m01, m11 + lam, m12), Vector3(m02, m12, m22 + lam))
	var y := M.inverse() * tau

	# --- Ausgänge setzen --------------------------------------------------
	var idx := 0
	for srf in airship.surfaces:
		srf.command = clampf(weights[idx] * cols[idx].dot(y), -output_limit, output_limit)
		idx += 1
	for mot in airship.motors:
		var u := weights[idx] * cols[idx].dot(y)
		mot.swivel_cmd = clampf(u, -1.0, 1.0)
		# Gas + Differenzschub für Gier: bei Gier rechts schiebt der linke
		# Motor (side = −1) stärker, der rechte schwächer.
		var side := signf(mot.position.x - cg.x)
		mot.throttle_cmd = clampf(cmd_throttle + side * yaw_diff_thrust * tau_cmd.y, -1.0, 1.0)
		idx += 1

	# Mode 3: Schwenker folgen direkt dem Nick-Stick (nicht geregelt)
	if mode == Mode.STABILIZED_NO_VEC:
		for mot in airship.motors:
			mot.swivel_cmd = clampf(cmd_pitch, -1.0, 1.0)


func _reset_integrators() -> void:
	for m in pids:
		for a in pids[m]:
			pids[m][a].reset()


# =============================================================================
# UI-Anbindung: Tabelle der Schieberegler für das PID-Menü.
# Das UI baut sich aus dieser Liste auf und ruft set_param() auf.
# =============================================================================
const UI_PARAMS := [
	{"term": "kp", "label": "P", "min": 0.0, "max": 3.0, "step": 0.01},
	{"term": "ki", "label": "I", "min": 0.0, "max": 1.0, "step": 0.01},
	{"term": "kd", "label": "D", "min": 0.0, "max": 1.0, "step": 0.01},
	{"term": "i_limit", "label": "I-Grenze", "min": 0.0, "max": 1.0, "step": 0.05},
]

func set_param(m: Mode, axis: Axis, term: String, value: float) -> void:
	pids[m][axis].set(term, value)
	pid_changed.emit(m, axis, term, value)
	save_settings()

func get_param(m: Mode, axis: Axis, term: String) -> float:
	return pids[m][axis].get(term)


# =============================================================================
# Dauerhaft speichern / laden (überlebt App-Neustart)
# =============================================================================
func save_settings() -> void:
	var cfg := ConfigFile.new()
	for m in pids:
		for a in pids[m]:
			for p in UI_PARAMS:
				cfg.set_value("mode_%d_axis_%d" % [m, a], p.term, pids[m][a].get(p.term))
	cfg.set_value("general", "stick_mode", stick_mode)
	cfg.set_value("general", "mix_mode", mix_mode)
	cfg.set_value("general", "output_limit", output_limit)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for m in pids:
		for a in pids[m]:
			for p in UI_PARAMS:
				var key := "mode_%d_axis_%d" % [m, a]
				pids[m][a].set(p.term, cfg.get_value(key, p.term, pids[m][a].get(p.term)))
	stick_mode = cfg.get_value("general", "stick_mode", stick_mode)
	mix_mode = cfg.get_value("general", "mix_mode", mix_mode)
	output_limit = cfg.get_value("general", "output_limit", output_limit)
