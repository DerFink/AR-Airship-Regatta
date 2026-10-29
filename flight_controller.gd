# 2026-10-29 01:53 – Mischer mit Priorität Nick > Gier > Roll; Standardwerte = Chewie-Abstimmung
# 2026-10-29 01:44 – Neu als Kaskadenregler in Erdachsen (Variante 3): Winkel-P → Drehraten-PID mit Anti-Windup und gefiltertem D, Begrenzungen als Sollwertgrenzen (Nickband ±5°/±40°, max. Drehraten), Roll geregelt (Geregelt) oder frei mit einstellbarer Dämpfung (Luftschiff), Schwenker fürs Nicken begrenzt, Gas-Anpassung; Modus „Geregelt ohne Vektor“ entfällt; Einstellungen Version 5
# 2026-10-29 01:13 – Nick-Schutz statt Test-Anschlag (Ruhe ±5°, mit Höhensteuerung bis ±40°, Schutzanteil mit Vorrang und voller Stellstärke; nicht in Direkt); kein Differenzschub mehr
# 2026-10-28 15:12 – Startmodus „Geregelt“; settings_outdated (Einstellungen Version 4)
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
# Virtueller Flugcontroller im Stil eines Teensy-FC (dRehmFlight-Prinzip),
# aufgebaut als KASKADENREGLER IN ERDACHSEN – so, dass er 1:1 auf den Teensy
# übertragen werden kann:
#
#   Knüppel ─► Sollwerte ─► äußerer Kreis ─► innerer Kreis ─► Erdachsen→Körper ─► Mischer
#              (Nicklage,    Winkelfehler ×     Drehraten-PID       (Lage aus IMU)     Leitwerk +
#               Gierrate)    Winkel-P = Soll-    (P, I, D, Anti-                        Schwenkmotoren
#                            Drehrate (begrenzt) Windup, Gas-Anpassung)
#
# Modi (3-Stufen-Schalter):
#   DIRECT      Knüppel gehen ungeregelt an den Mischer
#   STABILIZED  „Geregelt“:   Nicklage und Rolllage (auf 0°) geregelt, Gierrate geregelt
#   AIRSHIP     „Luftschiff“: wie Geregelt, aber Roll FREI – nur leicht gedämpft
#               (Rolldämpfung einstellbar, 0 = ganz frei)
#
# Warum Erdachsen? Ist das Schiff gerollt, wirkt ein Seitenleitwerk nicht mehr
# als Seitenleitwerk und ein Schwenkmotor nicht mehr in Gierrichtung. Der
# Regler rechnet deshalb „Nase hoch gegen den Horizont“ und „drehen um die
# Senkrechte“ und dreht diese Wünsche mit der aktuellen Lage ins Schiff. Der
# Mischer gibt jedem Stellglied genau den Anteil, den es in dieser Lage
# beitragen kann – auch bei 45° oder 90° Rollen.
#
# Begrenzungen sind SOLLWERT-Grenzen (kein zweiter Regelkreis, der gegen den
# PID arbeitet):
#   – Nicklage: ohne Höhensteuerung 0° mit Ruheband ±5°; mit Höhensteuerung
#     bis ±40°. Außerhalb des Bandes zieht ein stärkerer Winkel-P zurück.
#   – Nick- und Rollrate: begrenzt (max_rate_dps je Achse)
#   – Schwenkmotoren: fürs Nicken nur bis swivel_pitch_max_deg (sonst drückt
#     der nach unten zeigende Schub das Schiff zu Boden)
#
# Robustheit gegen Bauabweichungen: I-Anteil mit Anti-Windup (friert ein,
# wenn der Ausgang am Anschlag steht), gefiltertes D auf die gemessene Rate,
# Gas-Anpassung (ohne Fahrtmesser ist das Gas das Maß für die Ruderwirkung).
#
# Achsen-Konvention (Körpersystem): Nick hoch = +X-Moment,
# Gier rechts = −Y-Moment, Roll rechts = −Z-Moment.
# =============================================================================
class_name FlightController
extends Node

signal mode_changed(mode: int)
## Für die Live-Sprungantwort im PID-Menü (Nick/Roll: Winkel, Gier: Rate).
signal loop_sample(axis: int, setpoint: float, measurement: float)

enum Mode { DIRECT, STABILIZED, AIRSHIP }
## Namen für Schalter und Menüs
const MODE_NAMES := ["Direkt", "Geregelt", "Luftschiff"]
enum Axis { ROLL, PITCH, YAW }
const AXIS_KEYS := {Axis.ROLL: "roll", Axis.PITCH: "pitch", Axis.YAW: "yaw"}

const SETTINGS_PATH := "user://flight_controller.cfg"
## Version 5 = Kaskadenregler (ältere Dateien: Reglerwerte werden ersetzt)
const SETTINGS_VERSION := 5
## true = keine oder ältere Einstellungsdatei → Modell-Vorgaben übernehmen
var settings_outdated := true

@export var airship: AirshipPhysics
@export var mode: Mode = Mode.STABILIZED:     ## Start in „Geregelt“
	set(v): mode = v; _reset_integrators(); mode_changed.emit(v)
## Stick-Belegung. Gier liegt IMMER auf dem rechten Knüppel (links/rechts).
##   Mode 2 (Standard): links hoch/runter = Gas,  rechts hoch/runter = Nick
##   Mode 1:            links hoch/runter = Nick, rechts hoch/runter = Gas
@export_range(1, 2, 1) var stick_mode: int = 2

@export_group("Mischer")
## Stärke des Leitwerks (Ruder, Pendel, Canards): 1,0 = voller Ausschlag.
@export_range(0.0, 1.0, 0.05) var tail_gain: float = 1.0
## Stärke der Schwenkmotoren: 1,0 = voller Schwenkweg.
@export_range(0.0, 1.0, 0.05) var vec_gain: float = 0.4
## Höchster Schwenkwinkel, den die Motoren fürs NICKEN verwenden dürfen (°).
## Gieren darf den vollen Schwenkweg nutzen.
@export_range(0.0, 120.0, 1.0) var swivel_pitch_max_deg: float = 80.0
## Gas-Anpassung: Reglerausgang ∝ 1 / Gas (bezogen auf 50 %), begrenzt auf
## 0,5…2. Mehr Gas = mehr Fahrt und Schub = stärkere Wirkung → weniger Ausschlag.
@export var throttle_scaling: bool = false    ## im Simulator ohne besser

@export_group("Nick-Sollwert")
## Ruheband: ohne Höhensteuerung darf die Nase ±pitch_rest_deg pendeln
@export_range(1.0, 20.0, 1.0) var pitch_rest_deg: float = 5.0
## Maximale Nicklage bei vollem Knüppel
@export_range(10.0, 60.0, 1.0) var pitch_max_deg: float = 40.0
## Winkel-P außerhalb des Bandes (zieht kräftiger zurück)
@export_range(0.0, 20.0, 0.5) var protect_gain: float = 6.0
@export var pitch_protect_on: bool = true
## Totzone des Nick-Knüppels: darunter gilt „keine Höhensteuerung“
@export_range(0.0, 0.3, 0.01) var pitch_deadband: float = 0.05
## So lange braucht der Sollwert von 0 bis zum Maximalwinkel (und zurück), s
@export_range(0.1, 5.0, 0.1) var pitch_return_s: float = 1.0

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
var cmd_pitch := 0.0
var cmd_yaw := 0.0
var cmd_aux := 0.0       ## linker Knüppel links/rechts – derzeit unbelegt
var _sp_pitch := 0.0     ## geglätteter Nick-Sollwert (rad)


# =============================================================================
# Reglerwerte je Achse (für Geregelt und Luftschiff gemeinsam)
#   ang_p     äußerer Kreis: Winkelfehler (rad) → Soll-Drehrate (rad/s)
#   rate_p/i/d innerer Kreis: Drehratenfehler (rad/s) → Stellwert (−1…1)
#   max_rate  höchste Soll-Drehrate (°/s)
#   ff        Gier: Vorsteuerung (Knüppel direkt auf den Stellwert)
#   damp_free Roll: Anteil des Raten-P im Modus Luftschiff (Rolldämpfung)
# =============================================================================
var params := {        # Standard = für Chewie ermittelte Werte
	Axis.PITCH: {"ang_p": 4.0, "rate_p": 2.0, "rate_i": 0.2, "rate_d": 0.05, "max_rate": 35.0},
	Axis.ROLL:  {"ang_p": 4.0, "rate_p": 1.0, "rate_i": 0.2, "rate_d": 0.05, "max_rate": 30.0, "damp_free": 0.3},
	Axis.YAW:   {"rate_p": 0.7, "rate_i": 0.1, "rate_d": 0.0, "max_rate": 40.0, "ff": 0.0},
}

## Schieberegler-Tabelle fürs PID-Menü (je Achse); das UI baut sich daraus auf.
const UI_PARAMS := {
	Axis.PITCH: [
		{"term": "ang_p", "label": "Winkel P", "min": 0.0, "max": 10.0, "step": 0.1},
		{"term": "rate_p", "label": "Rate P", "min": 0.0, "max": 5.0, "step": 0.05},
		{"term": "rate_i", "label": "Rate I", "min": 0.0, "max": 3.0, "step": 0.05},
		{"term": "rate_d", "label": "Rate D", "min": 0.0, "max": 1.0, "step": 0.01},
		{"term": "max_rate", "label": "max. °/s", "min": 5.0, "max": 120.0, "step": 1.0},
	],
	Axis.ROLL: [
		{"term": "ang_p", "label": "Winkel P", "min": 0.0, "max": 10.0, "step": 0.1},
		{"term": "rate_p", "label": "Rate P", "min": 0.0, "max": 5.0, "step": 0.05},
		{"term": "rate_i", "label": "Rate I", "min": 0.0, "max": 3.0, "step": 0.05},
		{"term": "rate_d", "label": "Rate D", "min": 0.0, "max": 1.0, "step": 0.01},
		{"term": "max_rate", "label": "max. °/s", "min": 5.0, "max": 120.0, "step": 1.0},
		{"term": "damp_free", "label": "Dämpfung Luftschiff", "min": 0.0, "max": 1.0, "step": 0.05},
	],
	Axis.YAW: [
		{"term": "rate_p", "label": "Rate P", "min": 0.0, "max": 5.0, "step": 0.05},
		{"term": "rate_i", "label": "Rate I", "min": 0.0, "max": 3.0, "step": 0.05},
		{"term": "rate_d", "label": "Rate D", "min": 0.0, "max": 1.0, "step": 0.01},
		{"term": "max_rate", "label": "max. °/s", "min": 10.0, "max": 180.0, "step": 1.0},
		{"term": "ff", "label": "Vorsteuerung", "min": 0.0, "max": 1.5, "step": 0.05},
	],
}


# =============================================================================
# Drehraten-PID (innerer Kreis)
#   P und I auf den Ratenfehler, D auf die ÄNDERUNG der gemessenen Rate
#   (gefiltert – kein Sprung bei Sollwertänderungen).
#   Anti-Windup: Stand der Ausgang beim letzten Schritt am Anschlag und würde
#   der Fehler ihn weiter hineintreiben, wird nicht weiter integriert.
# =============================================================================
class RatePID:
	var i_limit := 0.4          ## max. Anteil des Integrators am Ausgang
	var d_filter_hz := 15.0
	var _integral := 0.0
	var _d_rate := 0.0
	var _prev_meas := NAN
	var _saturated := 0.0       ## Vorzeichen der letzten Sättigung (0 = frei)

	func reset() -> void:
		_integral = 0.0; _d_rate = 0.0; _prev_meas = NAN; _saturated = 0.0

	func update(sp: float, meas: float, p: float, i: float, d: float, dt: float) -> float:
		var err := sp - meas
		if dt <= 0.0:
			return 0.0
		if not (_saturated != 0.0 and signf(err) == _saturated):
			_integral = clampf(_integral + err * i * dt, -i_limit, i_limit)
		var dmeas := 0.0 if is_nan(_prev_meas) else (meas - _prev_meas) / dt
		_prev_meas = meas
		var a := clampf(dt * TAU * d_filter_hz, 0.0, 1.0)
		_d_rate = lerpf(_d_rate, dmeas, a)
		var u := p * err + _integral - d * _d_rate
		_saturated = signf(u) if absf(u) >= 1.0 else 0.0
		return clampf(u, -1.0, 1.0)

var _rpid := {Axis.ROLL: RatePID.new(), Axis.PITCH: RatePID.new(), Axis.YAW: RatePID.new()}


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
	var xf := airship.global_transform if airship.is_inside_tree() else airship.transform
	var b := xf.basis.orthonormalized()
	if mode == Mode.DIRECT:
		_mix(Vector3(cmd_pitch, 0, 0), Vector3(0, -cmd_yaw, 0), Vector3.ZERO, false)   # ungeregelt, Körperachsen
		return

	# --- Lage und Drehraten in Erdachsen ------------------------------------
	var nose := -b.z                                  # Nase (Welt)
	var axis_p := nose.cross(Vector3.UP)              # Drehung um diese Achse = Nase hoch
	if axis_p.length() < 0.05:                        # Nase senkrecht: Querachse nehmen
		axis_p = b.x
	axis_p = axis_p.normalized()
	var w := airship.angular_velocity                 # Welt, rad/s
	var pitch := asin(clampf(nose.y, -1.0, 1.0))      # Nase hoch = +
	var roll := atan2(-b.x.y, b.y.y)                  # rechts hängend = +
	var rate_p := w.dot(axis_p)
	var rate_r := w.dot(nose)                         # Roll rechts = +
	var rate_y := -w.y                                # Gier rechts = +

	# --- Nick: Sollwert → Soll-Nickrate (äußerer Kreis) --------------------
	var P: Dictionary = params[Axis.PITCH]
	var sp_pitch := _pitch_setpoint(dt)
	var err_p := sp_pitch - pitch
	var rs_p: float = P.ang_p * err_p
	if pitch_protect_on:                              # außerhalb des Bandes: kräftiger zurück
		var rest := deg_to_rad(pitch_rest_deg)
		var excess := pitch - clampf(pitch, sp_pitch - rest, sp_pitch + rest)
		rs_p -= protect_gain * excess
	var mr_p := deg_to_rad(P.max_rate)
	rs_p = clampf(rs_p, -mr_p, mr_p)

	# --- Roll: Geregelt → auf 0°, Luftschiff → nur Dämpfung -----------------
	var R: Dictionary = params[Axis.ROLL]
	var rs_r := 0.0
	var roll_p_scale := 1.0
	if mode == Mode.STABILIZED:
		var mr_r := deg_to_rad(R.max_rate)
		rs_r = clampf(R.ang_p * (0.0 - roll), -mr_r, mr_r)
	else:
		roll_p_scale = R.damp_free

	# --- Gier: Knüppel = Soll-Gierrate ---------------------------------------
	var Y: Dictionary = params[Axis.YAW]
	var rs_y := cmd_yaw * deg_to_rad(Y.max_rate)

	# --- Innerer Kreis: Drehraten-PID -----------------------------------------
	var u_p: float = _rpid[Axis.PITCH].update(rs_p, rate_p, P.rate_p, P.rate_i, P.rate_d, dt)
	var u_r := 0.0
	if mode == Mode.STABILIZED:
		u_r = _rpid[Axis.ROLL].update(rs_r, rate_r, R.rate_p, R.rate_i, R.rate_d, dt)
	else:
		u_r = _rpid[Axis.ROLL].update(0.0, rate_r, R.rate_p * roll_p_scale, 0.0, 0.0, dt)
	var u_y: float = _rpid[Axis.YAW].update(rs_y, rate_y, Y.rate_p, Y.rate_i, Y.rate_d, dt)
	u_y = clampf(u_y + Y.ff * cmd_yaw, -1.0, 1.0)

	# Gas-Anpassung (ohne Fahrtmesser): mehr Gas → stärkere Wirkung → weniger Ausschlag
	if throttle_scaling:
		var k := 1.0 / clampf(absf(cmd_throttle) / 0.5, 0.5, 2.0)
		u_p = clampf(u_p * k, -1.0, 1.0)
		u_r = clampf(u_r * k, -1.0, 1.0)
		u_y = clampf(u_y * k, -1.0, 1.0)

	loop_sample.emit(Axis.PITCH, sp_pitch, pitch)
	loop_sample.emit(Axis.ROLL, 0.0, roll)
	loop_sample.emit(Axis.YAW, rs_y, rate_y)

	# --- Erdachsen → Körpersystem, dann Mischer -----------------------------
	# Nick um die waagrechte Querachse, Gier um die Senkrechte (rechts = −Y),
	# Roll um die Längsachse (rechts = Drehung um die Nase).
	# Jede Achse einzeln ins Körpersystem drehen – der Mischer verteilt sie mit
	# Priorität (Nick vor Gier vor Roll).
	var bt := b.transposed()
	_mix(bt * (axis_p * u_p), bt * (Vector3.DOWN * u_y), bt * (nose * u_r), true)


# =============================================================================
# Nick-Sollwert: Totzone, Maximalwinkel, weicher Verlauf
#   Knüppel in der Totzone → 0°; sonst linear bis ±pitch_max_deg.
#   Der Sollwert ändert sich höchstens mit pitch_max_deg / pitch_return_s.
# =============================================================================
func _pitch_setpoint(dt: float) -> float:
	var target := 0.0
	var mag := absf(cmd_pitch)
	if mag > pitch_deadband:
		target = signf(cmd_pitch) * (mag - pitch_deadband) / (1.0 - pitch_deadband) * deg_to_rad(pitch_max_deg)
	var rate := deg_to_rad(pitch_max_deg) / maxf(pitch_return_s, 0.05)
	_sp_pitch = move_toward(_sp_pitch, target, rate * dt)
	return _sp_pitch


# =============================================================================
# Mischer – Leitwerk und Schwenkmotoren getrennt, OHNE Fahrtmessung
# -----------------------------------------------------------------------------
# Jede Gruppe (Leitwerk/Canards bzw. Schwenkmotoren) bekommt den kompletten
# Momentenwunsch und verteilt ihn geometrisch auf ihre Stellglieder
# (Pseudo-Inverse): 100 % Wunsch = voller Ausschlag der Gruppe.
#   Ruder   = tail_gain · Anteil Leitwerk
#   Schwenk = vec_gain · (Gieranteil + Nickanteil, dieser begrenzt auf
#             ±swivel_pitch_max_deg)
# t_p, t_y, t_r = Nick-, Gier- und Rollwunsch, schon ins Körpersystem gedreht
# (bei Schräglage hat z. B. der Nickwunsch auch Gier-Anteile im Schiff).
# limit_swivel_pitch = Schwenkweg fürs Nicken begrenzen (nicht im Direkt-Modus).
# =============================================================================
func _mix(t_p: Vector3, t_y: Vector3, t_r: Vector3, limit_swivel_pitch := false) -> void:
	var cg := airship.cg_offset
	var fin_cols: Array[Vector3] = []
	for srf in airship.surfaces:
		fin_cols.append(srf.moment_per_rad(cg) * deg_to_rad(srf.max_deflection_deg))
	var mot_cols: Array[Vector3] = []
	for mot in airship.motors:
		# Schub MIT Vorzeichen: bei Rückwärtsschub kehrt sich die Schwenkwirkung um.
		var ref := mot.signed_thrust_estimate(cmd_throttle)
		mot_cols.append(mot.moment_per_rad_swivel(cg, ref) * deg_to_rad(mot.max_swivel_deg))
	# Prioritäten: Nick vor Gier vor Roll. Jede Achse wird einzeln verteilt;
	# reicht der Ausschlag nicht für alle, wird zuerst Roll, dann Gier
	# zurückgenommen – die Nicklage (= Höhe) hat immer Vorrang.
	var f_p := _scaled(_allocate(fin_cols, t_p), tail_gain)
	var f_y := _scaled(_allocate(fin_cols, t_y), tail_gain)
	var f_r := _scaled(_allocate(fin_cols, t_r), tail_gain)
	var u_fin := _prio_combine([f_p, f_y, f_r])

	var m_p := _allocate(mot_cols, t_p)
	if limit_swivel_pitch:                              # Schwenk fürs Nicken begrenzen
		for i in m_p.size():
			var lim := clampf(swivel_pitch_max_deg / maxf(airship.motors[i].max_swivel_deg, 1.0), 0.0, 1.0)
			m_p[i] = clampf(m_p[i], -lim, lim)
	var u_mot := _prio_combine([_scaled(m_p, vec_gain), _scaled(_allocate(mot_cols, t_y), vec_gain),
		_scaled(_allocate(mot_cols, t_r), vec_gain)])

	for i in airship.surfaces.size():
		airship.surfaces[i].command = clampf(u_fin[i], -1.0, 1.0)
	for i in airship.motors.size():
		var mot: VectorMotor = airship.motors[i]
		mot.swivel_cmd = clampf(u_mot[i], -1.0, 1.0)
		mot.throttle_cmd = clampf(cmd_throttle, -1.0, 1.0)   # alle Motoren gleich


static func _scaled(u: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var o := u.duplicate()
	for i in o.size(): o[i] *= k
	return o


## Summiert Ausschlag-Anteile nach Priorität: der erste Anteil zählt voll
## (nur begrenzt), jeder weitere wird so weit verkleinert, dass kein
## Stellglied über ±1 kommt.
static func _prio_combine(parts: Array) -> PackedFloat32Array:
	var acc: PackedFloat32Array = (parts[0] as PackedFloat32Array).duplicate()
	for i in acc.size(): acc[i] = clampf(acc[i], -1.0, 1.0)
	for pi in range(1, parts.size()):
		var add: PackedFloat32Array = parts[pi]
		var k := 1.0
		for i in acc.size():
			if absf(add[i]) < 1e-6: continue
			var room := (1.0 - acc[i]) if add[i] > 0.0 else (-1.0 - acc[i])
			k = minf(k, clampf(room / add[i], 0.0, 1.0))
		for i in acc.size(): acc[i] += k * add[i]
	return acc


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
	for a in _rpid:
		_rpid[a].reset()


# =============================================================================
# Parameter lesen/schreiben (PID-Menü) und Modell-Vorgaben
# =============================================================================
func set_param(axis: Axis, term: String, value: float) -> void:
	params[axis][term] = value
	save_settings()

func get_param(axis: Axis, term: String) -> float:
	return params[axis][term]


## Modell-Standardwerte übernehmen:
##   {"pitch": {ang_p, rate_p, …}, "roll": {…}, "yaw": {…},
##    "mix": [Leitwerk, Schwenk], "swv_pitch": Grad}
## Fehlende Werte bleiben wie sie sind. Wird gespeichert.
func apply_model_gains(gains: Dictionary) -> void:
	if gains.is_empty():
		return
	for a in AXIS_KEYS:
		var g = gains.get(AXIS_KEYS[a])
		if g is Dictionary:
			for term in g:
				if params[a].has(term):
					params[a][term] = float(g[term])
	if gains.get("mix") is Array and gains.mix.size() == 2:
		tail_gain = gains.mix[0]; vec_gain = gains.mix[1]
	if gains.has("swv_pitch"):
		swivel_pitch_max_deg = float(gains.swv_pitch)
	_reset_integrators()
	save_settings()


# =============================================================================
# Dauerhaft speichern / laden (überlebt App-Neustart)
# =============================================================================
const GENERAL_KEYS := ["stick_mode", "tail_gain", "vec_gain", "swivel_pitch_max_deg", "throttle_scaling",
	"pitch_rest_deg", "pitch_max_deg", "protect_gain", "pitch_protect_on"]

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for a in params:
		for term in params[a]:
			cfg.set_value(AXIS_KEYS[a], term, params[a][term])
	for k in GENERAL_KEYS:
		cfg.set_value("general", k, get(k))
	cfg.set_value("general", "version", SETTINGS_VERSION)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	settings_outdated = int(cfg.get_value("general", "version", 1)) < SETTINGS_VERSION
	stick_mode = cfg.get_value("general", "stick_mode", stick_mode)
	if settings_outdated:
		return                    # alte Reglerwerte passen nicht zum neuen Regler
	for a in params:
		for term in params[a]:
			params[a][term] = cfg.get_value(AXIS_KEYS[a], term, params[a][term])
	for k in GENERAL_KEYS:
		set(k, cfg.get_value("general", k, get(k)))
