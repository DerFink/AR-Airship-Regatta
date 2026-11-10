# 2026-11-10 23:45 – Ohne eingebauten Teensy (Baukasten) gilt immer „Direkt“
# 2026-11-10 11:45 – Mode 3: maximale Gierrate 110 °/s statt 180 °/s (Wunsch Nutzer); gespeicherte 180 werden beim Laden auf 110 umgestellt
# 2026-11-09 16:00 – SIM_OPT neu für Mode 3 mit Gier-PID
# 2026-11-09 15:20 – Mode 3: Gier als vollständiger PID-Drehratenregler (Kp/Ki/Kd_yaw_m3, immer aktiv, Sollrate 0 bei Knüppel Mitte ⇒ hält die Richtung; ersetzt Einblenden und Gierdämpfer); Höhenknüppel loslassen ⇒ Sollwinkel sofort 0 (wie Mode 2); Einstellungen Version 11
# 2026-11-09 14:35 – Nick-Schutz (Mode 2/3): geht die Lage über maxPitch hinaus, wird die Knüppel-Vorsteuerung in diese Richtung über pitch_protect_band_deg (10°) ausgeblendet – vorher stellte sich bei gehaltenem Höhenknüppel ≈ 60° Nick ein (Flossen überzogen, „steuerlos“); Gas bleibt unberührt
# 2026-11-09 14:00 – SIM_OPT: robuste Werte (Böen, Knüppelverzögerung, Boden)
# 2026-11-09 13:00 – SIM_OPT: neue Werte aus der Optimierung in echtem Mode 3 mit Boden
# 2026-11-09 10:20 – Reglerwahl „Teensy“ / „Sim-optimiert“ (preset, SIM_OPT, apply_preset); Wahl wird gespeichert
# 2026-11-08 20:00 – Gierschwenk ab 22 % Gas mit (Grenze/Gas)² zurückgenommen (Wenderadius ≤ 2 m, kein Umkippen bei Vollgas); Mode 3: Vorlauf-Grenze nur bei bewegtem Höhenknüppel
# 2026-11-08 16:20 – Expo auf dem Seitenknüppel (yaw_expo 0,3, im PID-Menü unter Mischer einstellbar)
# 2026-11-08 15:25 – Mode 3: sanfter Gierdämpfer bei Knüppel Mitte (Kd_yaw_m3 0,4 – bei 60 % Schub blieben mit 0,2 noch ±23 °/s Pendeln; blendet aus, wenn der Drehratenregler einblendet)
# 2026-11-07 23:00 – Regelung 1:1 aus Chewies Teensy-Code (Chewie_SBUS_dRehmFlight_Teensy_BETA_1_3, Stand 04.11.2026) übernommen: controlANGLE (PID Nick/Roll in Grad, ×0,01), rateModeUpdate (Mode 3), mixServosStabilized / mixServosDirect mit Einbauwinkeln 60/300/180°, Rollwinkel-Drehung der Stabilisierung, Gesamt-Ausschlag 0,5 (Mode 2/3), Motorschwenker an der Roll-Regelung (MOTOR_ROLL_SIGN), Mode-1-Rolle auf dem linken Knüppel; alle Werte heißen wie im Teensy-Code; eigene Gierdämpfung und Allokations-Mischer entfallen; Einstellungen Version 10
# 2026-11-07 22:10 – Gierdämpfung bei losgelassenem Seitenknüppel in Mode 2/3 (Chewie drehte sonst endlos weiter), begrenzt auf ±30 % Ausschlag, blendet beim Steuern aus; Einstellungen Version 9
# 2026-11-07 20:45 – Nur noch drei Modi wie am echten Chewie (Kanal 13): Direkt, Mode 2, Mode 3 nach dRehmFlight-Code (Chewie_SBUS_dRehmFlight_Teensy_BETA_1_3); Geregelt, Luftschiff und Gedämpft entfallen; Gier mit getrennten Anteilen Leitwerk/Motorschwenk (Mode 2: 0,6/1,28; Mode 3: Vorsteuerung 0,85/1,125 + Drehratenregler 0,0014/0,0011 je °/s); Nick Mode 2 = Sollwinkel ±30°, Mode 3 = Nickrate 45 °/s; Roll über einfachen Feder-Dämpfer; Gas-Anpassung und Nick-Ruheband entfallen; Einstellungen Version 8
# 2026-10-29 07:45 – Modus 4 „Gedämpft“: Nicklage wie Geregelt, Roll über einfachen Feder-Dämpfer, Gier-Knüppel voll ohne Gas-Anpassung und ohne Drehratengrenze (Dämpfung nur beim Loslassen), eigene Schwenkstärke Gier (swivel_damped)
# 2026-10-29 03:38 – reset_to_defaults(): Werkseinstellung + Modell-Vorgaben
# 2026-10-29 03:23 – Gier: Knüppel direkt + Dämpfung statt Gierraten-Regelung (Knüppelstärke, Dämpfung); Einstellungen Version 7
# 2026-10-29 02:43 – Standard Gier = Renn-Abstimmung; Einstellungen Version 6 (Vorgaben werden einmalig neu geladen)
# 2026-10-29 02:25 – eigene Schwenkstärke fürs Gieren (vec_yaw_gain, Modell-Vorgabe mix_yaw)
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
# Nachbau des echten Flugcontrollers von Chewie (Teensy 4.0, dRehmFlight,
# Datei Chewie_SBUS_dRehmFlight_Teensy_BETA_1_3_20261001.ino, Stand 04.11.2026).
# Rechenweg, Einheiten und Werte sind dieselben wie im Teensy-Code, damit
# Einstellungen zwischen Simulator und Luftschiff übertragbar sind:
#
#   getDesState()   Knüppel → pitch_des (±maxPitch = 30°), yaw_des (±maxYaw = 160 °/s)
#   rateModeUpdate  nur Mode 3: Höhenknüppel = Nickrate (45 °/s) → Nick-Sollwinkel,
#                   Seitenknüppel = Gierrate (180 °/s) → P-Drehratenregler (yawRatePID)
#   controlANGLE()  Mode 2/3: PID auf Nick- und Rollwinkel (Grad), D auf die
#                   Drehrate (Kreisel), Ausgang ×0,01 (≈ −1…1)
#   Mischer         Servo = Mitte ± (Nick·sin(n) + Gier·cos(n) + Roll) mit den
#                   Einbauwinkeln n = 60°/300° (untere Flossen bzw. Motorschwenker)
#                   und 180° (obere Flosse); Stabilisierung mit n + Rollwinkel
#   Gesamt-Ausschlag Mode 1: 1,0 · Mode 2/3: 0,5 (servo_throw)
#   Servo-Weg       0…1 = 0…180° Servo; im Simulator: Ausschlag in Grad = Weg·180,
#                   begrenzt auf den mechanischen Anschlag des Bauteils
#
# Modi wie der 3-Stufen-Schalter auf Kanal 13:
#   DIRECT  Mode 1: Knüppel direkt auf die Servos (mixServosDirect), Rolle für
#           Kunstflug auf dem linken Knüppel links/rechts
#   MODE2   Mode 2: Knüppel = Vorsteuerung (Nick-Sollwinkel ±30°, Gier direkt),
#           Nick- und Roll-Regler aktiv (Roll stärker gedämpft, Motorschwenker
#           helfen beim Rollen), KEINE Gier-Regelung
#   MODE3   Mode 3: wie Mode 2, Höhe = Nickrate, Seite = Gierrate mit Regler
#
# Vorzeichen: Die Einbaurichtung der Servos ist am echten Modell durch Bodentests
# festgelegt. Im Simulator wird sie einmal aus der Geometrie bestimmt (Nick-Befehl
# muss die Nase heben, Gier-Befehl nach rechts drehen, Roll-Befehl nach rechts
# rollen) – die Zahlenwerte bleiben die des Teensy-Codes.
# Gas: wird NIE geregelt (Pilot kann bei Gefahr sofort abschalten).
# =============================================================================
class_name FlightController
extends Node

signal mode_changed(mode: int)
## Für die Live-Sprungantwort im PID-Menü (Nick/Roll: Winkel, Gier: Rate).
signal loop_sample(axis: int, setpoint: float, measurement: float)

enum Mode { DIRECT, MODE2, MODE3 }
## Namen für Schalter und Menüs
const MODE_NAMES := ["Direkt", "Mode 2", "Mode 3"]
## Kurzbeschreibung je Modus (Banner beim Umschalten)
const MODE_HINTS := [
	"Direkt (Mode 1): Knüppel direkt auf Ruder und Motorschwenk, Rolle auf dem linken Knüppel",
	"Mode 2: Nick und Roll geregelt · Höhe = Nickwinkel bis ±30° · Seite direkt",
	"Mode 3: wie Mode 2 · Höhe = Nickrate 45 °/s · Seite = Gierrate bis 180 °/s",
]
enum Axis { ROLL, PITCH, YAW }
const AXIS_KEYS := {Axis.ROLL: "roll", Axis.PITCH: "pitch", Axis.YAW: "yaw"}

const SETTINGS_PATH := "user://flight_controller.cfg"
## Version 11 = Mode-3-Gier als PID (Kd_yaw_m3 hat eine neue Bedeutung)
## Version 10 = Regelung aus dem Teensy-Code (ältere Dateien: Werte werden ersetzt)
const SETTINGS_VERSION := 11
## true = keine oder ältere Einstellungsdatei → Modell-Vorgaben übernehmen
var settings_outdated := true

@export var airship: AirshipPhysics
@export var mode: Mode = Mode.MODE2:     ## Start in „Mode 2“
	set(v):
		mode = v
		_reset_integrators()                   # resetControllers(): keine Integrator-Sprünge
		_pitch_sp_m3 = 0.0
		mode_changed.emit(v)
## Stick-Belegung. Gier liegt IMMER auf dem rechten Knüppel (links/rechts).
##   Mode 2 (Standard): links hoch/runter = Gas,  rechts hoch/runter = Nick
##   Mode 1:            links hoch/runter = Nick, rechts hoch/runter = Gas
@export_range(1, 2, 1) var stick_mode: int = 2

# --- Nick-Sollwert (Teensy: maxPitch und MODE3_PITCH_*) -------------------------
## Größter Nick-Sollwinkel bei vollem Knüppel (maxPitch, Mode 2) bzw. Grenze des
## Sollwinkels in Mode 3 (MODE3_PITCH_ANGLE_MAX), Grad
@export_range(10.0, 60.0, 1.0) var pitch_max_deg: float = 30.0
## Mode 3: Nickrate bei vollem Knüppel (MODE3_PITCH_RATE_MAX_DPS), °/s
@export_range(5.0, 120.0, 1.0) var pitch_rate_dps: float = 45.0
## Mode 3: Rückkehr des Sollwinkels auf 0° beim Loslassen (MODE3_PITCH_RETURN_DPS), °/s
@export_range(0.0, 90.0, 1.0) var pitch_return_dps: float = 20.0
## Mode 3: Sollwinkel höchstens so weit vor dem echten Nickwinkel (MODE3_PITCH_LEAD_MAX), Grad
@export_range(1.0, 45.0, 1.0) var pitch_lead_deg: float = 15.0

const MAX_YAW := 160.0            ## maxYaw: Seitenknüppel voll = 160 (°/s-Einheit der Vorsteuerung)
const M3_DEADBAND := 0.05         ## MODE3_STICK_DEADBAND
const M3_YAW_FADE := 0.15         ## MODE3_YAW_LOOP_FADE
const I_LIMIT := 25.0             ## i_limit (Grad·s)
const ROLL_AUTH_FACTOR := 0.5     ## (sin²60 + sin²300 + sin²180) / 3 bei drei Flossen (Lambda)
const MODE1_ROLL_DEADBAND := 0.15 ## Mode 1: Totband der Rolle auf dem linken Knüppel
## Einbauwinkel der Motorschwenker im Teensy-Mischer (rechts 60°, links 300°)
const N_MOTOR_RIGHT := 60.0
const N_MOTOR_LEFT := 300.0

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
var cmd_aux := 0.0       ## linker Knüppel links/rechts: Rolle in Mode 1 (Teensy: Kanal 7)

# Reglerzustand (wie im Teensy-Code)
var _int_roll := 0.0
var _int_pitch := 0.0
var _pitch_sp_m3 := 0.0  ## pitchSetpointM3 (Grad)
var _int_yaw := 0.0      ## Mode 3: Integral des Gierraten-Fehlers (°/s · s)
var _gyro_yaw_prev := 0.0
var _yaw_acc_f := 0.0    ## gefilterte Drehbeschleunigung (°/s²) für den D-Anteil
## Mode 3 Gier-Integral begrenzen (°/s · s) – Ki 1 ⇒ höchstens 0,3 Servoweg
const I_LIMIT_YAW := 30.0


# =============================================================================
# Reglerwerte – Namen und Werte wie im Teensy-Code (Stand 04.11.2026)
#   Nick  Kp/Ki/Kd          Kp_m2 / Ki_m2 / Kd_m2 (Winkel in Grad, D auf GyroY)
#   Roll  Kp/Ki/Kd          Kp_roll_m2 / Ki_roll_m2 / Kd_roll_m2
#         roll_vs_pitch     Roll-Wirkung der Leitwerke relativ zu Nick
#   Gier  stick_yaw_motor/tail        Mode 2 Vorsteuerung (Servoweg je °/s-Knüppelwert)
#         stick_yaw_motor/tail_m3     Mode 3 Vorsteuerung
#         Kp_yaw_m3                   Mode 3 Drehratenregler P (×0,01 je °/s Fehler)
#         Ki_yaw_m3                   Mode 3 Drehratenregler I (×0,01 je °/s·s, nicht im Teensy-Code)
#         Kd_yaw_m3                   Mode 3 Drehratenregler D auf die gemessene
#                                     Drehbeschleunigung (×0,01 je °/s², nicht im Teensy-Code)
#         yaw_rate_max                MODE3_YAW_RATE_MAX_DPS
#         yaw_loop_motor/tail_m3      Mode 3 Regler → Servoweg
# =============================================================================
var params := {
	Axis.PITCH: {"Kp": 0.6, "Ki": 0.4, "Kd": 0.15},
	Axis.ROLL:  {"Kp": 0.6, "Ki": 0.1, "Kd": 0.45, "roll_vs_pitch": 1.5},
	Axis.YAW:   {"stick_yaw_motor": 0.016, "stick_yaw_tail": 0.005,
				 "stick_yaw_motor_m3": 0.0125, "stick_yaw_tail_m3": 0.00625,
				 "Kp_yaw_m3": 1.8, "Ki_yaw_m3": 0.8, "Kd_yaw_m3": 0.03, "yaw_rate_max": 110.0, "yaw_loop_motor_m3": 0.6, "yaw_loop_tail_m3": 0.5},
}

## Schieberegler-Tabelle fürs PID-Menü (je Achse); das UI baut sich daraus auf.
## "fmt" (optional) = Anzeigeformat des Werts.
const UI_PARAMS := {
	Axis.PITCH: [
		{"term": "Kp", "label": "Kp (Kp_m2)", "min": 0.0, "max": 3.0, "step": 0.01},
		{"term": "Ki", "label": "Ki (Ki_m2)", "min": 0.0, "max": 2.0, "step": 0.01},
		{"term": "Kd", "label": "Kd (Kd_m2)", "min": 0.0, "max": 2.0, "step": 0.01},
	],
	Axis.ROLL: [
		{"term": "Kp", "label": "Kp (Kp_roll_m2)", "min": 0.0, "max": 3.0, "step": 0.01},
		{"term": "Ki", "label": "Ki (Ki_roll_m2)", "min": 0.0, "max": 2.0, "step": 0.01},
		{"term": "Kd", "label": "Kd (Kd_roll_m2)", "min": 0.0, "max": 2.0, "step": 0.01},
		{"term": "roll_vs_pitch", "label": "roll_vs_pitch", "min": 0.0, "max": 3.0, "step": 0.05},
	],
	Axis.YAW: [
		{"term": "stick_yaw_motor", "label": "Mode 2 stick_yaw_motor", "min": 0.0, "max": 0.05, "step": 0.0005, "fmt": "%.4f"},
		{"term": "stick_yaw_tail", "label": "Mode 2 stick_yaw_tail", "min": 0.0, "max": 0.05, "step": 0.0005, "fmt": "%.4f"},
		{"term": "stick_yaw_motor_m3", "label": "Mode 3 stick_yaw_motor_m3", "min": 0.0, "max": 0.05, "step": 0.00025, "fmt": "%.5f"},
		{"term": "stick_yaw_tail_m3", "label": "Mode 3 stick_yaw_tail_m3", "min": 0.0, "max": 0.05, "step": 0.00025, "fmt": "%.5f"},
		{"term": "Kp_yaw_m3", "label": "Mode 3 Kp_yaw_m3", "min": 0.0, "max": 2.0, "step": 0.01},
		{"term": "Ki_yaw_m3", "label": "Mode 3 Ki_yaw_m3", "min": 0.0, "max": 2.0, "step": 0.01},
		{"term": "Kd_yaw_m3", "label": "Mode 3 Kd_yaw_m3", "min": 0.0, "max": 0.2, "step": 0.002, "fmt": "%.3f"},
		{"term": "yaw_rate_max", "label": "Mode 3 Gierrate voll (°/s)", "min": 30.0, "max": 360.0, "step": 5.0},
		{"term": "yaw_loop_motor_m3", "label": "Mode 3 yaw_loop_motor_m3", "min": 0.0, "max": 2.0, "step": 0.05},
		{"term": "yaw_loop_tail_m3", "label": "Mode 3 yaw_loop_tail_m3", "min": 0.0, "max": 2.0, "step": 0.05},
	],
}

# --- Mischer-Werte (wie im Teensy-Code, gelten für alle Achsen) ---------------
var servo_throw_m1 := 1.0          ## Gesamt-Ausschlag Mode 1
var servo_throw_m23 := 0.5         ## Gesamt-Ausschlag Mode 2 und 3 (servo_throw_m2/_m3)
var tail_pitch_gain := 2.0         ## tail_pitch_gain_m2: Servoweg Leitwerke je PID-Einheit Nick
var motor_pitch_gain := 2.0        ## motor_pitch_gain_m2: Servoweg Motorschwenker je PID-Einheit Nick
var motor_roll_gain := 1.0         ## motor_roll_gain: Servoweg Motorschwenker je PID-Einheit Roll (0 = aus)
var motor_roll_sign := -1.0        ## MOTOR_ROLL_SIGN: −1 = Rollen rechts-hoch → Schwenker wie Gier links
var stick_pitch_motor := 0.02      ## Vorsteuerung Nick Motorschwenker (Mode 2/3)
var stick_pitch_tail := 0.015      ## Vorsteuerung Nick Leitwerke (Mode 2/3)
## Nick-Schutz (nicht im Teensy-Code, 09.11.2026): ab maxPitch wird die
## Knüppel-Vorsteuerung in Richtung der Lage über diese Spanne (Grad) auf 0
## ausgeblendet. 0 = aus (verhält sich wie der Teensy-Code).
var pitch_protect_band_deg := 10.0
var mode1_stick_pitch_motor := 0.02
var mode1_stick_yaw_motor := 0.004
var mode1_stick_pitch_tail := 0.02
var mode1_stick_yaw_tail := 0.005
var mode1_roll_tail := 0.25        ## Mode 1: Rolle → Leitwerke (alle gleichsinnig)
var mode1_roll_motor := 0.0        ## Mode 1: Rolle → Motorschwenker (0 = aus)
## Expo auf dem Seitenknüppel (alle Modi): 0 = linear, 1 = ganz weich um die Mitte.
## Wie am RC-Sender: Ausgabe = (1 − e)·x + e·x³ – Vollausschlag bleibt 100 %.
var yaw_expo := 0.3
## Gashebel, bis zu dem der Gierschwenk voll wirkt (0,22 ≈ 5 % Schub); darüber
## wird er mit (Grenze/Gas)² zurückgenommen. 1,0 = nie zurücknehmen (wie Teensy-Code).
var yaw_swivel_full_lever := 0.22
var yaw_swivel_scale := 1.0        ## aktueller Faktor (Anzeige/Test)

## Mischer-Werte fürs PID-Menü (Feld, Beschriftung, min, max, Schritt, Format)
const MIX_PARAMS := [
	["yaw_expo", "Expo Seitenknüppel (Gier)", 0.0, 1.0, 0.05, "%.2f"],
	["yaw_swivel_full_lever", "Gierschwenk voll bis Gas", 0.05, 1.0, 0.01, "%.2f"],
	["servo_throw_m23", "Gesamt-Ausschlag Mode 2/3", 0.1, 1.0, 0.05, "%.2f"],
	["servo_throw_m1", "Gesamt-Ausschlag Mode 1", 0.1, 1.0, 0.05, "%.2f"],
	["tail_pitch_gain", "tail_pitch_gain_m2", 0.0, 5.0, 0.1, "%.1f"],
	["motor_pitch_gain", "motor_pitch_gain_m2", 0.0, 5.0, 0.1, "%.1f"],
	["motor_roll_gain", "motor_roll_gain", 0.0, 3.0, 0.05, "%.2f"],
	["stick_pitch_tail", "stick_pitch_tail", 0.0, 0.05, 0.0005, "%.4f"],
	["stick_pitch_motor", "stick_pitch_motor", 0.0, 0.05, 0.0005, "%.4f"],
	["pitch_protect_band_deg", "Nick-Schutz ab maxPitch (°, 0 = aus)", 0.0, 30.0, 1.0, "%.0f"],
]


## Reglerwahl: "teensy" = Werte aus der .ino (Werkseinstellung + Modell-Vorgaben),
## "sim" = dieselben Werte, darüber die in der Rennoptimierung gefundenen (SIM_OPT).
var preset := "teensy"
## Im Simulator optimierte Reglerwerte (Rennoptimierung 09.11.2026 nachmittags, Chewie Mode 3 mit
## Gier-PID; mit Boden, Böen und 0–2 Schritten Knüppelverzögerung). Die maximale Gierrate
## gehört nicht dazu – sie bleibt Sache des Piloten. Schlüssel "achse.wert" = PID-Parameter,
## sonst allgemeine Einstellung.
const SIM_OPT := {"pitch.Kp": 1.455, "pitch.Kd": 0.271, "roll.Kp": 0.808, "roll.Kd": 0.12,
	"yaw_swivel_full_lever": 0.378, "yaw.Kp_yaw_m3": 0.975, "yaw.Ki_yaw_m3": 0.416,
	"yaw.Kd_yaw_m3": 0.016, "yaw.yaw_loop_motor_m3": 0.668, "yaw.yaw_loop_tail_m3": 0.201}
const PRESET_NAMES := {"teensy": "Teensy", "sim": "Sim-optimiert"}

## Werkseinstellungen (beim Erzeugen gemerkt, vor dem Laden gespeicherter Werte)
var _factory := {}


func _ready() -> void:
	_factory = {"params": params.duplicate(true), "general": {}}
	for k in GENERAL_KEYS:
		_factory.general[k] = get(k)
	load_settings()


## Alle Flugcontroller-Einstellungen auf Werkseinstellung zurück, danach die
## Vorgaben des aktuellen Modells (model_gains) – und speichern.
func reset_to_defaults(model_gains: Dictionary) -> void:
	if _factory.is_empty():
		return
	params = _factory.params.duplicate(true)
	for k in _factory.general:
		set(k, _factory.general[k])
	preset = "teensy"                          # Werkseinstellung = Teensy-Werte
	mode = Mode.MODE2
	_reset_integrators()
	apply_model_gains(model_gains)     # speichert auch
	save_settings()


## Reglerwahl umschalten: Werkseinstellung + Modell-Vorgaben, bei "sim" zusätzlich
## SIM_OPT darüber. Modus und Armed bleiben, wie sie sind. Wird gespeichert.
## Hinweis: eigene Änderungen aus dem PID-Menü werden dabei überschrieben.
func apply_preset(name: String, model_gains: Dictionary) -> void:
	if _factory.is_empty():
		return
	preset = name if PRESET_NAMES.has(name) else "teensy"
	params = _factory.params.duplicate(true)
	for k in _factory.general:
		if k != "stick_mode":                 # Knüppelbelegung gehört dem Piloten
			set(k, _factory.general[k])
	apply_model_gains(model_gains)
	if preset == "sim":
		apply_overrides(SIM_OPT)
	_reset_integrators()
	save_settings()


## Einzelwerte setzen ("achse.wert" oder allgemeine Einstellung) – ohne Speichern.
## Wird auch vom Demo-Flug benutzt.
func apply_overrides(values: Dictionary) -> void:
	for key in values:
		var parts := str(key).split(".")
		if parts.size() == 2:
			var ax: int = {"roll": Axis.ROLL, "pitch": Axis.PITCH, "yaw": Axis.YAW}[parts[0]]
			params[ax][parts[1]] = float(values[key])
		else:
			set(str(key), float(values[key]))


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
	cmd_yaw = expo(right.x, yaw_expo)     # Gier: immer rechts, links/rechts, mit Expo
	cmd_aux = left.x                      # Mode 1: Rolle
	# Nick wie beim RC-Sender: Knüppel nach vorn (hoch) = Nase runter,
	# Knüppel zu sich ziehen = Nase hoch. Deshalb das Minus.
	if stick_mode == 1:
		cmd_pitch = -left.y; cmd_throttle = right.y
	else:                                 # Mode 2 (Standard)
		cmd_throttle = left.y; cmd_pitch = -right.y


## Expo wie am RC-Sender: feinfühlig um die Mitte, Vollausschlag unverändert.
static func expo(x: float, e: float) -> float:
	x = clampf(x, -1.0, 1.0)
	return (1.0 - e) * x + e * x * x * x


## Beschriftung der Knüppel für das HUD (passt sich dem Stick-Mode an).
func stick_labels() -> Array[String]:
	if stick_mode == 1:
		return ["Nick", "Gas · Gier"]
	return ["Gas", "Nick · Gier"]


# =============================================================================
# Regelschleife (läuft vor dem Physikschritt des Luftschiffs)
# =============================================================================
func _physics_process(dt: float) -> void:
	if airship == null or dt <= 0.0:
		return
	var xf := airship.global_transform if airship.is_inside_tree() else airship.transform
	var b := xf.basis.orthonormalized()

	# --- IMU: Lage in Grad, Drehraten (Kreisel, körperfest) in °/s -------------
	var nose := -b.z
	var pitch_imu := rad_to_deg(asin(clampf(nose.y, -1.0, 1.0)))      # Nase hoch = +
	var roll_imu := rad_to_deg(atan2(-b.x.y, b.y.y))                   # rechts hängend = +
	var w_b := b.transposed() * airship.angular_velocity                  # Körpersystem
	var gyro_roll := rad_to_deg(-w_b.z)                                 # Roll rechts = +
	var gyro_pitch := rad_to_deg(w_b.x)                                 # Nase hoch = +
	var gyro_yaw := rad_to_deg(-w_b.y)                                  # Gier rechts = +

	# --- getDesState(): Knüppel → Sollwerte -----------------------------------
	var pitch_des := clampf(cmd_pitch, -1.0, 1.0) * pitch_max_deg      # ±maxPitch (Grad)
	var yaw_des := clampf(cmd_yaw, -1.0, 1.0) * MAX_YAW                # ±maxYaw

	if mode == Mode.DIRECT or not airship.fc_teensy:   # ohne Teensy kein Regler
		_mix_direct(pitch_des, yaw_des)
		loop_sample.emit(Axis.PITCH, deg_to_rad(pitch_des), deg_to_rad(pitch_imu))
		loop_sample.emit(Axis.ROLL, 0.0, deg_to_rad(roll_imu))
		loop_sample.emit(Axis.YAW, 0.0, deg_to_rad(gyro_yaw))
		return

	# --- rateModeUpdate(): nur Mode 3 -------------------------------------------
	var yaw_rate_pid := 0.0
	var Y: Dictionary = params[Axis.YAW]
	if mode == Mode.MODE3:
		var d := clampf(dt, 0.0, 0.05)
		var stick_p := pitch_des / pitch_max_deg                       # −1 … 1
		if absf(stick_p) > M3_DEADBAND:
			_pitch_sp_m3 += stick_p * pitch_rate_dps * d               # Sollwinkel wandert mit der Knüppel-Drehrate
		else:
			# Höhenknüppel losgelassen (09.11.2026, Wunsch Nutzer): Sollwinkel sofort 0 –
			# die Nase geht wie in Mode 2 gleich auf Waagrecht zurück (Teensy-Code: mit
			# pitch_return_dps = 20 °/s langsam zurück)
			_pitch_sp_m3 = 0.0
		# Vorlauf-Grenze nur bei bewegtem Höhenknüppel (08.11.2026): im Teensy-Code wirkte sie
		# immer und zog den Sollwinkel mit nach oben, wenn die Nase von selbst hochging
		# (Vollgas in der Kurve); danach erst auf ±maxPitch begrenzen
		if absf(stick_p) > M3_DEADBAND:
			_pitch_sp_m3 = clampf(_pitch_sp_m3, pitch_imu - pitch_lead_deg, pitch_imu + pitch_lead_deg)
		_pitch_sp_m3 = clampf(_pitch_sp_m3, -pitch_max_deg, pitch_max_deg)
		pitch_des = _pitch_sp_m3                                         # ab hier arbeitet alles mit diesem Sollwinkel
		# Gier: PID-Drehratenregler (09.11.2026, Wunsch Nutzer). Immer aktiv:
		# Knüppel → Sollrate (± yaw_rate_max), Knüppel Mitte → Sollrate 0, d. h. der
		# Regler bremst jede Drehung ab und hält mit dem I-Anteil die Richtung
		# (vorher: P-Regler erst ab 5–20 % Knüppelweg eingeblendet, in der Mitte nur
		# ein Dämpfer). D wirkt auf die gemessene Drehbeschleunigung (kein Sprung
		# beim Knüppelausschlag), 20-ms-Tiefpass gegen Kreiselrauschen.
		var stick_y := yaw_des / MAX_YAW
		if not armed:
			_int_yaw = 0.0                                               # am Boden/ohne Motoren nichts aufsammeln
		var err_yaw: float = stick_y * Y.yaw_rate_max - gyro_yaw
		_int_yaw = clampf(_int_yaw + err_yaw * d, -I_LIMIT_YAW, I_LIMIT_YAW)
		if d > 0.0:
			var acc := (gyro_yaw - _gyro_yaw_prev) / d
			_yaw_acc_f += (acc - _yaw_acc_f) * clampf(d / 0.02, 0.0, 1.0)
		_gyro_yaw_prev = gyro_yaw
		yaw_rate_pid = 0.01 * (Y.Kp_yaw_m3 * err_yaw + Y.Ki_yaw_m3 * _int_yaw - Y.Kd_yaw_m3 * _yaw_acc_f)

	# --- controlANGLE(): PID Roll und Nick (Grad, ×0,01) ------------------------
	var R: Dictionary = params[Axis.ROLL]
	var P: Dictionary = params[Axis.PITCH]
	var err_roll := 0.0 - roll_imu                                       # Roll-Sollwert immer 0 (USE_ROLL_STICK = false)
	_int_roll = clampf(_int_roll + err_roll * dt, -I_LIMIT, I_LIMIT)
	var roll_pid: float = 0.01 * (R.Kp * err_roll + R.Ki * _int_roll - R.Kd * gyro_roll)
	var err_pitch := pitch_des - pitch_imu
	_int_pitch = clampf(_int_pitch + err_pitch * dt, -I_LIMIT, I_LIMIT)
	var pitch_pid: float = 0.01 * (P.Kp * err_pitch + P.Ki * _int_pitch - P.Kd * gyro_pitch)
	var pitch_pid_sp: float = 0.01 * P.Kp * pitch_des                    # Knüppelanteil (lageunabhängig verteilt)

	loop_sample.emit(Axis.PITCH, deg_to_rad(pitch_des), deg_to_rad(pitch_imu))
	loop_sample.emit(Axis.ROLL, 0.0, deg_to_rad(roll_imu))
	loop_sample.emit(Axis.YAW, deg_to_rad(yaw_des / MAX_YAW * Y.yaw_rate_max) if mode == Mode.MODE3 else 0.0, deg_to_rad(gyro_yaw))

	# --- controlMixer() / mixServosStabilized() ---------------------------------
	var ys_m: float = Y.stick_yaw_motor_m3 if mode == Mode.MODE3 else Y.stick_yaw_motor
	var ys_t: float = Y.stick_yaw_tail_m3 if mode == Mode.MODE3 else Y.stick_yaw_tail
	var yl_m: float = Y.yaw_loop_motor_m3 * yaw_rate_pid
	var yl_t: float = Y.yaw_loop_tail_m3 * yaw_rate_pid
	var roll_gain: float = tail_pitch_gain * ROLL_AUTH_FACTOR * R.roll_vs_pitch
	var pitch_stab := pitch_pid - pitch_pid_sp                           # Regleranteil ohne Knüppel
	# Nick-Schutz (09.11.2026): Die Vorsteuerung gibt einen festen Ausschlag je
	# Sollwinkel, die Stabilisierung zieht nur Richtung 0°. Bei gehaltenem Knüppel
	# hielten sich beide erst bei ≈ 60° Nick die Waage – Flossen überzogen, Schub
	# zeigt nach oben/unten, das Schiff wirkt steuerlos. Deshalb: liegt die Lage
	# über maxPitch und zeigt der Knüppel in dieselbe Richtung, wird die
	# Vorsteuerung über pitch_protect_band_deg linear auf 0 zurückgenommen.
	# In die Gegenrichtung wirkt der Knüppel immer voll; das Gas bleibt unberührt.
	var over := absf(pitch_imu) - pitch_max_deg
	if pitch_protect_band_deg > 0.0 and over > 0.0 and signf(pitch_imu) == signf(pitch_des):
		var k_ff := clampf(1.0 - over / pitch_protect_band_deg, 0.0, 1.0)
		pitch_des *= k_ff
		pitch_pid_sp *= k_ff
		# pitch_stab (oben berechnet) bleibt: er enthält keinen Knüppelanteil
	var motor_pitch_stick := stick_pitch_motor * pitch_des + motor_pitch_gain * pitch_pid_sp
	var motor_pitch_stab := motor_pitch_gain * pitch_stab
	var tail_pitch_stick := stick_pitch_tail * pitch_des + tail_pitch_gain * pitch_pid_sp
	var tail_pitch_stab := tail_pitch_gain * pitch_stab
	var motor_yaw := ys_m * yaw_des + yl_m
	var tail_yaw := ys_t * yaw_des + yl_t
	var tail_roll := roll_gain * roll_pid
	var motor_roll := motor_roll_sign * motor_roll_gain * roll_pid       # gleichsinnig an beiden Schwenkern (wie Gier)
	# Gierschwenk mit dem Gas zurücknehmen (08.11.2026): Der Schwenk entlang der Hülle
	# rollt das Schiff mit Kraft ∝ Schub. Bis yaw_swivel_full_lever voller Schwenk,
	# darüber Faktor (Grenze/Gas)², so bleibt die seitliche Schubkraft gleich groß.
	# Simulator: Wenderadius in Mode 2/3 bei jedem Gas ≤ 2 m, Rollen ≤ 40°.
	var lever := absf(cmd_throttle)
	yaw_swivel_scale = 1.0 if lever <= yaw_swivel_full_lever else pow(yaw_swivel_full_lever / lever, 2.0)

	_calibrate()
	# Leitwerke: s = Mitte − (NickKnüppel·sin n + NickStab·sin(n+Roll) + Gier·cos n + Roll)
	for i in airship.surfaces.size():
		var srf: ControlSurface = airship.surfaces[i]
		var c: Dictionary = _fin_cal[i]
		if not c.active:
			srf.command = 0.0
			continue
		var n: float = c.n
		var a: float = n + c.m * roll_imu
		var delta: float = -(tail_pitch_stick * sin(deg_to_rad(n)) + tail_pitch_stab * sin(deg_to_rad(a)) \
				+ tail_yaw * cos(deg_to_rad(n)) + c.r * tail_roll)
		srf.command = _servo_to_cmd(c.s * delta, servo_throw_m23, srf.max_deflection_deg)
	# Motorschwenker: s = Mitte + dir·(NickKnüppel·sin n + NickStab·sin(n+Roll) + Gier·cos n + Roll)
	for i in airship.motors.size():
		var mot: VectorMotor = airship.motors[i]
		var c: Dictionary = _mot_cal[i]
		var n: float = c.n
		var a: float = n + c.m * roll_imu
		var dp: float = motor_pitch_stick * sin(deg_to_rad(n)) * c.wp + motor_pitch_stab * sin(deg_to_rad(a)) * c.wp
		var dy: float = (motor_yaw * cos(deg_to_rad(n)) + motor_roll) * c.wy
		dy *= yaw_swivel_scale                                          # Gierschwenk ab yaw_swivel_full_lever zurücknehmen
		var delta: float = dp + dy
		mot.swivel_cmd = _servo_to_cmd(c.s * delta, servo_throw_m23, mot.max_swivel_deg)
		mot.throttle_cmd = clampf(cmd_throttle, -1.0, 1.0)   # Gas nur vom Piloten, alle Motoren gleich


## Mode 1 (mixServosDirect): Knüppel direkt auf die Servos, Rolle auf dem linken Knüppel.
func _mix_direct(pitch_des: float, yaw_des: float) -> void:
	var roll_stick := clampf(cmd_aux, -1.0, 1.0)
	var roll_cmd := 0.0
	if absf(roll_stick) > MODE1_ROLL_DEADBAND:                       # nur bei bewusstem Ausschlag
		var over := (absf(roll_stick) - MODE1_ROLL_DEADBAND) / (1.0 - MODE1_ROLL_DEADBAND)
		roll_cmd = signf(roll_stick) * over
	_calibrate()
	for i in airship.surfaces.size():
		var srf: ControlSurface = airship.surfaces[i]
		var c: Dictionary = _fin_cal[i]
		if not c.active:
			srf.command = 0.0
			continue
		var n: float = deg_to_rad(c.n)
		# s3 = Mitte + Nick − Gier, s4 = Mitte − Nick − Gier, s5 = Mitte + Gier  ⇒ Vorzeichen von sin/cos des Einbauwinkels
		var delta: float = -(mode1_stick_pitch_tail * pitch_des * _sgn(sin(n)) + mode1_stick_yaw_tail * yaw_des * _sgn(cos(n))) \
				- c.r * mode1_roll_tail * roll_cmd
		srf.command = _servo_to_cmd(c.s * delta, servo_throw_m1, srf.max_deflection_deg)
	for i in airship.motors.size():
		var mot: VectorMotor = airship.motors[i]
		var c: Dictionary = _mot_cal[i]
		var n: float = deg_to_rad(c.n)
		var delta: float = mode1_stick_pitch_motor * pitch_des * _sgn(sin(n)) * c.wp \
				+ (mode1_stick_yaw_motor * yaw_des * _sgn(cos(n)) + motor_roll_sign * mode1_roll_motor * roll_cmd) * c.wy
		mot.swivel_cmd = _servo_to_cmd(c.s * delta, servo_throw_m1, mot.max_swivel_deg)
		mot.throttle_cmd = clampf(cmd_throttle, -1.0, 1.0)


## Servoweg (Teensy: Anteil von 0…1 = 0…180°) mit Gesamt-Ausschlag → Stellbefehl
## des Bauteils (−1…1 = ± mechanischer Anschlag).
static func _servo_to_cmd(delta: float, throw: float, max_deg: float) -> float:
	return clampf(delta * throw * 180.0 / maxf(max_deg, 1.0), -1.0, 1.0)


static func _sgn(x: float) -> float:
	return 0.0 if absf(x) < 1e-6 else signf(x)


# =============================================================================
# Einbauwinkel und Einbaurichtung bestimmen (am echten Modell: Bodentests)
#   Leitwerke: n = 180° ± Umfangswinkel der Flosse (Teensy: oben 180°, unten 60°/300°).
#     Gesucht sind Spiegelung m und Einbaurichtung s, für die ein Nick-Befehl die
#     Nase hebt und ein Gier-Befehl nach rechts dreht; r legt die Rollrichtung fest
#     (Roll-Befehl rollt nach rechts).
#   Motorschwenker im Paar: n = 60° (rechts) / 300° (links) wie im Teensy-Code;
#     ein einzelner Motor schwenkt je nach Achse nur Nick oder nur Gier.
# Neu berechnet, wenn sich die Bauteile ändern (Modellwechsel, Baukasten).
# =============================================================================
var _fin_cal: Array = []
var _mot_cal: Array = []
var _cal_key := ""

func _calibrate() -> void:
	var key := "%d/%d/%s" % [airship.surfaces.size(), airship.motors.size(), str(airship.cg_offset)]
	for s in airship.surfaces: key += "/%s%s%.1f" % [str(s.position), str(s.normal), s.hull_angle_deg]
	for m in airship.motors: key += "/%s%s" % [str(m.position), str(m.swivel_axis)]
	if key == _cal_key and _fin_cal.size() == airship.surfaces.size() and _mot_cal.size() == airship.motors.size():
		return
	_cal_key = key
	var cg := airship.cg_offset
	# --- Leitwerke (nur bewegliche Flossen des Leitwerks; Canards/Turm bleiben in Ruhe)
	var fins: Array[int] = []
	for i in airship.surfaces.size():
		var s: ControlSurface = airship.surfaces[i]
		if s.tail_member and not s.sail_member:
			fins.append(i)
	var best := {"score": -INF, "m": 1.0, "s": 1.0}
	for m in [1.0, -1.0]:
		for sg in [1.0, -1.0]:
			var mp := Vector3.ZERO; var my := Vector3.ZERO
			for i in fins:
				var s: ControlSurface = airship.surfaces[i]
				var n := deg_to_rad(fposmod(180.0 + m * s.hull_angle_deg, 360.0))
				var mr := s.moment_per_rad(cg)
				mp += mr * (sg * -sin(n))          # Nick-Befehl +1
				my += mr * (sg * -cos(n))          # Gier-Befehl +1
			var score := (mp.x / maxf(mp.length(), 1e-9)) + (-my.y / maxf(my.length(), 1e-9))
			if score > best.score:
				best = {"score": score, "m": m, "s": sg}
	# Rollrichtung: alle Flossen gleichsinnig (−Roll) muss nach rechts rollen (−Z)
	var mroll := Vector3.ZERO
	for i in fins:
		mroll += airship.surfaces[i].moment_per_rad(cg) * (best.s * -1.0)
	var r := 1.0 if -mroll.z >= 0.0 else -1.0
	_fin_cal = []
	for i in airship.surfaces.size():
		var s: ControlSurface = airship.surfaces[i]
		_fin_cal.append({"active": fins.has(i), "n": fposmod(180.0 + best.m * s.hull_angle_deg, 360.0),
			"m": best.m, "s": best.s, "r": r})
	# --- Motorschwenker
	_mot_cal = []
	for mot in airship.motors:
		var mr := mot.moment_per_rad_swivel(cg, 1.0)
		var side := signf(mot.position.x) if absf(mot.position.x) > 0.01 else 0.0
		var c := {"n": 0.0, "m": 1.0, "s": 1.0, "wp": 1.0, "wy": 1.0}
		if side != 0.0:
			# Paar: Teensy-Winkel 60° rechts / 300° links; Vorzeichen so, dass Nick hebt und Gier rechts dreht
			c.n = N_MOTOR_RIGHT if side > 0.0 else N_MOTOR_LEFT
			var sn := sin(deg_to_rad(c.n))
			c.s = signf(mr.x * sn) if absf(mr.x) > 1e-6 else 1.0      # Nick-Befehl hebt die Nase
			# Gier: gleiche Richtung an beiden Motoren; Einbaurichtung des Gieranteils getrennt prüfen
			c.wy = signf(-mr.y * c.s) if absf(mr.y) > 1e-6 else 0.0
			# Rolllagen-Drehung: Teensy-Winkel n ≈ 180° − Umfangswinkel (rechts 135° → 45° ≈ 60°),
			# also dreht n beim Rollen nach rechts rückwärts
			c.m = -1.0
		else:
			# einzelner Motor: schwenkt nur in der Ebene, in der er wirkt
			if absf(mr.x) >= absf(mr.y):
				c.n = 90.0; c.s = signf(mr.x); c.wy = 0.0
			else:
				c.n = 0.0; c.s = signf(-mr.y); c.wp = 0.0
		_mot_cal.append(c)


func _reset_integrators() -> void:
	_int_roll = 0.0
	_int_pitch = 0.0
	_int_yaw = 0.0
	_yaw_acc_f = 0.0


# =============================================================================
# Parameter lesen/schreiben (PID-Menü) und Modell-Vorgaben
# =============================================================================
func set_param(axis: Axis, term: String, value: float) -> void:
	params[axis][term] = value
	save_settings()

func get_param(axis: Axis, term: String) -> float:
	return params[axis][term]


## Modell-Standardwerte übernehmen:
##   {"pitch": {Kp, Ki, Kd}, "roll": {…}, "yaw": {…}, "mix": {Feldname: Wert, …}}
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
	var mx = gains.get("mix")
	if mx is Dictionary:
		for k in mx:
			if k in GENERAL_KEYS:
				set(k, float(mx[k]))
	_reset_integrators()
	save_settings()


# =============================================================================
# Dauerhaft speichern / laden (überlebt App-Neustart)
# =============================================================================
const GENERAL_KEYS := ["stick_mode", "pitch_max_deg", "pitch_rate_dps", "pitch_return_dps", "pitch_lead_deg",
	"servo_throw_m1", "servo_throw_m23", "tail_pitch_gain", "motor_pitch_gain", "motor_roll_gain", "motor_roll_sign",
	"stick_pitch_motor", "stick_pitch_tail", "mode1_stick_pitch_motor", "mode1_stick_yaw_motor",
	"mode1_stick_pitch_tail", "mode1_stick_yaw_tail", "mode1_roll_tail", "mode1_roll_motor", "yaw_expo", "yaw_swivel_full_lever",
	"pitch_protect_band_deg"]

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for a in params:
		for term in params[a]:
			cfg.set_value(AXIS_KEYS[a], term, params[a][term])
	for k in GENERAL_KEYS:
		cfg.set_value("general", k, get(k))
	cfg.set_value("general", "preset", preset)
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
	preset = str(cfg.get_value("general", "preset", "teensy"))
	# 10.11.2026: alte Werkseinstellung 180 °/s → neue 110 °/s (eigene andere Werte bleiben)
	if is_equal_approx(float(params[Axis.YAW].yaw_rate_max), 180.0):
		params[Axis.YAW].yaw_rate_max = 110.0
