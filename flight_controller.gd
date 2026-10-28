# 2026-10-28 08:51 – Testhilfe Nick begrenzen (Standard an, ±5°), gespeichert; Weitergabe an die Physik
# 2026-10-28 07:53 – Mischer ohne Fahrtabhängigkeit (kein Fahrtmesser am echten Modell): Leitwerk und Schwenkmotoren je eigene Zuordnung, Stärke getrennt (tail_gain, vec_gain); Mischmodi und Ausschlag-max ersetzt; Einstellungen Version 3
# 2026-10-28 00:15 – Mode 4 „Luftschiff“ (Roll frei/ungedämpft, Nick gegen Horizont, Gier um die Senkrechte, in die Schräglage umgerechnet); MODE_NAMES; apply_model_gains() für PID-Vorgaben je Modell
# 2026-10-27 23:28 – Ruderausschlag standardmäßig 100 % (vorher 50 %, ältere Einstellungsdateien übernehmen ihn nicht); Differenzschub relativ zum Gas ohne Rückwärtslauf; Mischer blendet nach Vorwärtsfahrt; Gier mit Vorsteuerung; D-Anteil Nick/Roll 1,0 und Reglerbereich bis 3,0
# 2026-10-27 12:41 – Nick-Knüppel umgedreht wie beim RC-Sender: nach vorn = Nase runter, ziehen = Nase hoch
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
#   AIRSHIP           Mode 4 „Luftschiff“: Roll frei und ungedämpft (Krängung
#                             egal); Nicklage gegen den Horizont und Drehrate um
#                             die SENKRECHTE werden geregelt und in die aktuelle
#                             Schräglage umgerechnet → jede Flosse bekommt den
#                             Ausschlag, der das gewünschte Moment liefert
#
# Der Mischer verteilt die gewünschten Drehmomente automatisch anhand der
# Bauteil-Geometrie auf alle Stellglieder – egal wo im Baukasten sie sitzen.
# Leitwerk und Schwenkmotoren arbeiten immer beide (keine Fahrtmessung nötig);
# ihre Stärke ist getrennt einstellbar (tail_gain, vec_gain).
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

enum Mode { DIRECT, STABILIZED, STABILIZED_NO_VEC, AIRSHIP }
## Namen für Schalter und Menüs
const MODE_NAMES := ["Direkt", "Geregelt", "Geregelt ohne Vektor", "Luftschiff"]
enum Axis { ROLL, PITCH, YAW }

const SETTINGS_PATH := "user://flight_controller.cfg"
## Version der gespeicherten Einstellungen. Ab 2 gilt der volle Ruderausschlag
## als Standard – ältere Dateien (mit 50 %) übernehmen ihn nicht mehr.
const SETTINGS_VERSION := 3

@export var airship: AirshipPhysics
@export var mode: Mode = Mode.DIRECT:
	set(v): mode = v; _reset_integrators(); mode_changed.emit(v)
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
## Stärke des Leitwerks (Ruder, Pendel, Canards): 1,0 = voller Ausschlag
## bei vollem Wunsch. Unabhängig von den Schwenkmotoren einstellbar.
@export_range(0.0, 1.0, 0.05) var tail_gain: float = 1.0
## Stärke der Schwenkmotoren: 1,0 = voller Schwenkweg bei vollem Wunsch.
@export_range(0.0, 1.0, 0.05) var vec_gain: float = 1.0
@export_group("Test")
## Testhilfe: Nickwinkel des Schiffs hart begrenzen (siehe AirshipPhysics).
@export var pitch_limit_on: bool = true
@export_range(1.0, 45.0, 1.0) var pitch_limit_deg: float = 5.0
## Differenzschub für Gier als Anteil des aktuellen Gases (0,3 = ±30 %).
## Wirkt nur relativ zum Gas: Gas 0 → kein Differenzschub, und ein Motor
## wird dadurch nie in den Rückwärtslauf gedrückt (Drehen auf der Stelle).
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
			# D kräftig: dämpft das Nicken/Rollen (am echten Chewie war D am Anschlag nötig)
			Axis.ROLL:  PID.new(0.9, 0.10, 1.00),
			Axis.PITCH: PID.new(0.9, 0.10, 1.00),
			Axis.YAW:   PID.new(0.4, 0.05, 0.00),
		}
	# Mode 3 startet etwas weicher
	pids[Mode.STABILIZED_NO_VEC][Axis.ROLL].kp = 0.7
	pids[Mode.STABILIZED_NO_VEC][Axis.PITCH].kp = 0.7


## Modell-Standardwerte übernehmen (z. B. für Chewie erflogene/ermittelte PIDs).
## gains: {"pitch": [kp, ki, kd], "roll": [...], "yaw": [...]} – gilt für die
## geregelten Modi (Geregelt, Luftschiff); optional "mix": [Leitwerk, Schwenk]
## als Stärken 0…1. Wird gespeichert.
func apply_model_gains(gains: Dictionary) -> void:
	if gains.is_empty():
		return
	var axes := {"roll": Axis.ROLL, "pitch": Axis.PITCH, "yaw": Axis.YAW}
	if gains.has("mix"):                                   # [Leitwerk, Schwenk]
		tail_gain = gains.mix[0]; vec_gain = gains.mix[1]
	for key in gains:
		if not axes.has(key):
			continue
		var g: Array = gains[key]
		for m in [Mode.STABILIZED, Mode.AIRSHIP]:
			var p: PID = pids[m][axes[key]]
			p.kp = g[0]; p.ki = g[1]; p.kd = g[2]
			p.reset()
	save_settings()


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
	# Nick wie beim RC-Sender: Knüppel nach vorn (hoch) = Nase runter,
	# Knüppel zu sich ziehen = Nase hoch. Deshalb das Minus.
	if stick_mode == 1:
		cmd_pitch = -left.y; cmd_throttle = right.y
	else:                                 # Mode 2 (Standard)
		cmd_throttle = left.y; cmd_pitch = -right.y


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
	airship.pitch_limit_enabled = pitch_limit_on       # Test-Anschlag an die Physik geben
	airship.pitch_limit_deg = pitch_limit_deg
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
	elif mode == Mode.AIRSHIP:
		_airship_mode(b, dt, pitch)
		return
	else:
		var pid_set: Dictionary = pids[mode]
		var sp_pitch := cmd_pitch * deg_to_rad(max_angle_deg)
		var sp_roll := cmd_roll * deg_to_rad(max_angle_deg)
		var sp_yaw := cmd_yaw * deg_to_rad(max_yaw_rate_dps)
		u_pitch = pid_set[Axis.PITCH].update(sp_pitch - pitch, rate_pitch, dt)
		u_roll = pid_set[Axis.ROLL].update(sp_roll - roll, rate_roll, dt)
		# Gier: Vorsteuerung (Stick direkt) + Ratenregler für die Korrektur –
		# so bekommt man auch bei kleinem P sofort die volle Drehwirkung
		u_yaw = clampf(cmd_yaw + pid_set[Axis.YAW].update(sp_yaw - rate_yaw, 0.0, dt), -1.0, 1.0)
		loop_sample.emit(Axis.PITCH, sp_pitch, pitch)
		loop_sample.emit(Axis.ROLL, sp_roll, roll)
		loop_sample.emit(Axis.YAW, sp_yaw, rate_yaw)

	# Wunsch-Drehmoment im Körpersystem (Vorzeichen siehe Kopfkommentar)
	var tau_cmd := Vector3(u_pitch, -u_yaw, -u_roll)
	_mix(tau_cmd)


# =============================================================================
# Mode 4 „Luftschiff“: Regelung in Erd-Achsen, Roll frei
# -----------------------------------------------------------------------------
#   Nickachse  = waagrechte Querachse (Nase × oben) – Nase hoch/runter gegen
#                den Horizont, egal wie stark das Schiff gekrängt ist
#   Gierachse  = Senkrechte der Erde
#   Rollachse  = nicht geregelt, nicht gedämpft
# Die Wunschmomente werden ins Körpersystem gedreht. Ist das Schiff z. B.
# 40° gekrängt, liefert der Mischer „Nase hoch“ teils über die Höhen-, teils
# über die Seitenflossen – genau so, wie die Flossen jetzt im Raum stehen.
# =============================================================================
func _airship_mode(b: Basis, dt: float, pitch: float) -> void:
	var pid_set: Dictionary = pids[Mode.AIRSHIP]
	var nose := -b.z                                  # Nase in Weltkoordinaten
	var axis_pitch := nose.cross(Vector3.UP)          # Nase hoch = Drehung um diese Achse
	if axis_pitch.length() < 0.05:                    # Schiff steht senkrecht: Querachse nehmen
		axis_pitch = b.x
	axis_pitch = axis_pitch.normalized()
	var w := airship.angular_velocity                 # Welt
	var rate_pitch := w.dot(axis_pitch)
	var rate_yaw := -w.y                              # Gier rechts = +
	var sp_pitch := cmd_pitch * deg_to_rad(max_angle_deg)
	var sp_yaw := cmd_yaw * deg_to_rad(max_yaw_rate_dps)
	var u_pitch: float = pid_set[Axis.PITCH].update(sp_pitch - pitch, rate_pitch, dt)
	var u_yaw := clampf(cmd_yaw + pid_set[Axis.YAW].update(sp_yaw - rate_yaw, 0.0, dt), -1.0, 1.0)
	loop_sample.emit(Axis.PITCH, sp_pitch, pitch)
	loop_sample.emit(Axis.YAW, sp_yaw, rate_yaw)
	# Wunschmoment in Welt (Gier rechts = Drehung um −Y), dann ins Körpersystem
	var tau_world := axis_pitch * u_pitch + Vector3.DOWN * u_yaw
	_mix(b.transposed() * tau_world)


# =============================================================================
# Mischer – Leitwerk und Schwenkmotoren getrennt, OHNE Fahrtmessung
# -----------------------------------------------------------------------------
# Am echten Modell gibt es keinen Fahrtmesser, deshalb hängt hier nichts von
# der Geschwindigkeit ab. Jede Gruppe (Leitwerk/Canards bzw. Schwenkmotoren)
# bekommt den kompletten Momentenwunsch und verteilt ihn geometrisch auf ihre
# Stellglieder (Pseudo-Inverse): 100 % Wunsch = voller Ausschlag der Gruppe.
# Danach skaliert je Gruppe ein eigener Stärke-Regler:
#     Ruder  = tail_gain · Anteil Leitwerk
#     Schwenk = vec_gain · Anteil Schwenkmotoren
# =============================================================================
func _mix(tau_cmd: Vector3) -> void:
	var cg := airship.cg_offset

	# --- Wirkvektoren je Gruppe (Moment bei Vollausschlag, Betrag egal) -----
	var fin_cols: Array[Vector3] = []
	for srf in airship.surfaces:
		fin_cols.append(srf.moment_per_rad(cg) * deg_to_rad(srf.max_deflection_deg))
	var mot_cols: Array[Vector3] = []
	for mot in airship.motors:
		# Schub MIT Vorzeichen: bei Rückwärtsschub kehrt sich die Schwenkwirkung um,
		# der Mischer schwenkt dann automatisch in die Gegenrichtung.
		var ref := mot.signed_thrust_estimate(cmd_throttle)
		mot_cols.append(mot.moment_per_rad_swivel(cg, ref) * deg_to_rad(mot.max_swivel_deg))
	var u_fin := _allocate(fin_cols, tau_cmd)
	var u_mot := _allocate(mot_cols, tau_cmd)

	# --- Ausgänge setzen --------------------------------------------------
	for i in airship.surfaces.size():
		airship.surfaces[i].command = clampf(tail_gain * u_fin[i], -1.0, 1.0)
	for i in airship.motors.size():
		var mot: VectorMotor = airship.motors[i]
		mot.swivel_cmd = clampf(vec_gain * u_mot[i], -1.0, 1.0)
		# Gas + Differenzschub für Gier: bei Gier rechts schiebt der linke
		# Motor (side = −1) stärker, der rechte schwächer.
		var side := signf(mot.position.x - cg.x)
		# Relativ zum Gas und ohne Vorzeichenwechsel (kein ungewollter Rückwärtslauf)
		var t_cmd := cmd_throttle * (1.0 + side * yaw_diff_thrust * tau_cmd.y)
		mot.throttle_cmd = clampf(t_cmd, -1.0, 1.0)     # Faktor 0,7…1,3 → Vorzeichen bleibt

	# Mode 3: Schwenker folgen direkt dem Nick-Stick (nicht geregelt)
	if mode == Mode.STABILIZED_NO_VEC:
		for mot in airship.motors:
			mot.swivel_cmd = clampf(cmd_pitch * vec_gain, -1.0, 1.0)


## Verteilt einen Momentenwunsch (je Achse −1..+1) auf eine Gruppe von
## Stellgliedern mit Wirkvektoren cols. Rückgabe: Ausschläge (−1..+1, vor
## der Begrenzung). Autorität je Achse = Summe der Beträge → 100 % Wunsch
## fordert die ganze Gruppe; Achsen, auf die die Gruppe nicht wirkt, bleiben 0.
##     u = Bᵀ·(B·Bᵀ + λI)⁻¹ · τ
static func _allocate(cols: Array[Vector3], tau_cmd: Vector3) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(cols.size())
	if cols.is_empty():
		return out
	var authority := Vector3.ZERO
	for c in cols:
		authority += c.abs()
	var tau := tau_cmd * authority
	var m00 := 0.0; var m01 := 0.0; var m02 := 0.0
	var m11 := 0.0; var m12 := 0.0; var m22 := 0.0
	for c in cols:
		m00 += c.x * c.x; m01 += c.x * c.y; m02 += c.x * c.z
		m11 += c.y * c.y; m12 += c.y * c.z; m22 += c.z * c.z
	var lam := 1e-9 + 1e-3 * (m00 + m11 + m22)
	var M := Basis(Vector3(m00 + lam, m01, m02), Vector3(m01, m11 + lam, m12), Vector3(m02, m12, m22 + lam))
	var y := M.inverse() * tau
	for i in cols.size():
		out[i] = cols[i].dot(y)
	return out


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
	{"term": "kd", "label": "D", "min": 0.0, "max": 3.0, "step": 0.01},
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
	cfg.set_value("general", "tail_gain", tail_gain)
	cfg.set_value("general", "vec_gain", vec_gain)
	cfg.set_value("test", "pitch_limit_on", pitch_limit_on)
	cfg.set_value("test", "pitch_limit_deg", pitch_limit_deg)
	cfg.set_value("general", "version", SETTINGS_VERSION)
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
	# Stärken erst ab Version 3 (vorher gab es den fahrtabhängigen Mischer)
	if int(cfg.get_value("general", "version", 1)) >= SETTINGS_VERSION:
		tail_gain = cfg.get_value("general", "tail_gain", tail_gain)
		vec_gain = cfg.get_value("general", "vec_gain", vec_gain)
	pitch_limit_on = cfg.get_value("test", "pitch_limit_on", pitch_limit_on)
	pitch_limit_deg = cfg.get_value("test", "pitch_limit_deg", pitch_limit_deg)
