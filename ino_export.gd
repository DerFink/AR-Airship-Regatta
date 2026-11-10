# 2026-11-11 11:20 – Erstversion: Teensy-Sketch (.ino) aus dem Simulator erzeugen – Vorlage ist Chewies dRehmFlight-Stand BETA 1.4; die Reglerwerte des Simulators werden in die passenden Variablen eingesetzt, oben steht eine Kopfzeile mit Zeitstempel und Liste der Änderungen
# =============================================================================
# InoExport.gd
# -----------------------------------------------------------------------------
# Vorlage: res://ino/chewie_beta_1_4.ino.txt (Endung .txt, damit Godot sie in
# die App packt). Sie passt zum Aufbau von Chewie: 3 Leitwerksflossen
# (λ, Servos an Pin 8/9/10), 2 Schwenkmotoren (Servos Pin 6/7, ESC Pin 4/5),
# SBUS-Empfänger, MPU6050.
#
# Ersetzt werden NUR Zahlenwerte in Zeilen der Form
#     float NAME = WERT;      bzw.   float A = 1, B = 2, C = 3;
# Alles andere (Pins, Failsafe, Motorfreigabe, Gas nur vom Piloten) bleibt
# unverändert. Welche Simulator-Größe in welche .ino-Variable geht, steht in
# MAP (Achse/Schlüssel → Variablenname).
# =============================================================================
class_name InoExport
extends RefCounted

const TEMPLATE := "res://ino/chewie_beta_1_4.ino.txt"

## [Achse (PITCH/ROLL/YAW) oder "gen", Schlüssel im Simulator, Variable im .ino]
const MAP := [
	["pitch", "Kp", "Kp_m2"], ["pitch", "Ki", "Ki_m2"], ["pitch", "Kd", "Kd_m2"],
	["roll", "Kp", "Kp_roll_m2"], ["roll", "Ki", "Ki_roll_m2"], ["roll", "Kd", "Kd_roll_m2"],
	["roll", "roll_vs_pitch", "roll_vs_pitch"],
	["yaw", "stick_yaw_motor", "stick_yaw_motor"], ["yaw", "stick_yaw_tail", "stick_yaw_tail"],
	["yaw", "stick_yaw_motor_m3", "stick_yaw_motor_m3"], ["yaw", "stick_yaw_tail_m3", "stick_yaw_tail_m3"],
	["yaw", "Kp_yaw_m3", "Kp_yaw_m3"], ["yaw", "Ki_yaw_m3", "Ki_yaw_m3"], ["yaw", "Kd_yaw_m3", "Kd_yaw_m3"],
	["yaw", "yaw_rate_max", "MODE3_YAW_RATE_MAX_DPS"],
	["yaw", "yaw_loop_motor_m3", "yaw_loop_motor_m3"], ["yaw", "yaw_loop_tail_m3", "yaw_loop_tail_m3"],
	["gen", "servo_throw_m1", "servo_throw_m1"], ["gen", "servo_throw_m23", "servo_throw_m2"],
	["gen", "servo_throw_m23", "servo_throw_m3"],
	["gen", "tail_pitch_gain", "tail_pitch_gain_m2"], ["gen", "motor_pitch_gain", "motor_pitch_gain_m2"],
	["gen", "motor_roll_gain", "motor_roll_gain"], ["gen", "motor_roll_sign", "MOTOR_ROLL_SIGN"],
	["gen", "stick_pitch_motor", "stick_pitch_motor"], ["gen", "stick_pitch_tail", "stick_pitch_tail"],
	["gen", "mode1_stick_pitch_motor", "mode1_stick_pitch_motor"], ["gen", "mode1_stick_yaw_motor", "mode1_stick_yaw_motor"],
	["gen", "mode1_stick_pitch_tail", "mode1_stick_pitch_tail"], ["gen", "mode1_stick_yaw_tail", "mode1_stick_yaw_tail"],
	["gen", "mode1_roll_tail", "mode1_roll_tail"], ["gen", "mode1_roll_motor", "mode1_roll_motor"],
	["gen", "pitch_max_deg", "maxPitch"], ["gen", "pitch_max_deg", "MODE3_PITCH_ANGLE_MAX"],
	["gen", "pitch_rate_dps", "MODE3_PITCH_RATE_MAX_DPS"], ["gen", "pitch_return_dps", "MODE3_PITCH_RETURN_DPS"],
	["gen", "pitch_lead_deg", "MODE3_PITCH_LEAD_MAX"], ["gen", "pitch_protect_band_deg", "MODE3_PITCH_PROTECT_BAND"],
	["gen", "yaw_expo", "MODE3_YAW_EXPO"], ["gen", "yaw_swivel_full_lever", "MODE3_YAW_SWIVEL_FULL_LEVER"],
]


## Passt der Aufbau des Modells zur Vorlage? Leer = ja, sonst Hinweistext.
static func check(ship: AirshipPhysics) -> String:
	var fins := 0
	for s in ship.surfaces:
		if s.tail_member: fins += 1
	if fins != 3 or ship.motors.size() != 2:
		return "Die .ino-Vorlage passt zum Aufbau von Chewie (3 Leitwerksflossen, 2 Schwenkmotoren). Dieses Modell hat %d Flossen und %d Motoren – Werte werden trotzdem eingesetzt, die Pinbelegung bitte prüfen." % [fins, ship.motors.size()]
	if not ship.fc_teensy:
		return "Im Modell ist kein Teensy eingebaut – der Sketch wird trotzdem erzeugt."
	return ""


## Sketch erzeugen. Rückgabe {"text", "changed": [Liste "NAME alt → neu"], "missing": [...]}.
static func build(fc: FlightController, model_name: String) -> Dictionary:
	var src := FileAccess.get_file_as_string(TEMPLATE)
	if src == "":
		return {"text": "", "changed": [], "missing": ["Vorlage fehlt"]}
	var lines := src.split("\n")
	var changed := []
	var missing := []
	for e in MAP:
		var v: float
		if e[0] == "gen":
			v = float(fc.get(e[1]))
		else:
			var ax: int = {"pitch": FlightController.Axis.PITCH, "roll": FlightController.Axis.ROLL, "yaw": FlightController.Axis.YAW}[e[0]]
			v = float(fc.params[ax][e[1]])
		var name: String = e[2]
		var found := false
		var re := RegEx.new()
		# NAME = Zahl  (am Zeilenanfang nach "float"/"const float" oder nach einem Komma)
		re.compile("(^\\s*(?:const\\s+)?float\\s+(?:[^;]*,\\s*)?|,\\s*)(" + name + ")(\\s*=\\s*)(-?[0-9]*\\.?[0-9]+(?:[eE]-?[0-9]+)?)")
		for i in lines.size():
			var m := re.search(lines[i])
			if m == null:
				continue
			var old := m.get_string(4)
			var neu := _fmt(v)
			if absf(float(old) - v) > 1e-9:
				lines[i] = lines[i].substr(0, m.get_start(4)) + neu + lines[i].substr(m.get_end(4))
				changed.append("%s %s → %s" % [name, old, neu])
			found = true
			break
		if not found:
			missing.append(name)
	var stamp := Time.get_datetime_string_from_system(false, true).replace("T", " ")
	var head := "// %s | Aenderungen: Export aus RC Airship Regatta %s, Modell \"%s\": %s" % [
		stamp.left(16), BuildInfo.VERSION, model_name,
		("Reglerwerte aus dem Simulator eingesetzt – " + ", ".join(changed)) if not changed.is_empty() else "keine Werte geaendert (Simulator = Vorlage BETA 1.4)"]
	return {"text": head + "\n" + "\n".join(lines), "changed": changed, "missing": missing}


## Zahl ohne überflüssige Nullen, immer mit Dezimalpunkt (C++ float).
static func _fmt(v: float) -> String:
	var t := ("%.6f" % v).rstrip("0")
	if t.ends_with("."): t += "0"
	return t


## Datei speichern bzw. im Browser herunterladen. Rückgabe: Ort für die Anzeige.
static func save(text: String, file_name: String) -> String:
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "text/plain")
		return "Download: " + file_name
	var dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if dir == "" or not DirAccess.dir_exists_absolute(dir) or OS.has_feature("mobile"):
		dir = ProjectSettings.globalize_path("user://export")
		DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(file_name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Speichern fehlgeschlagen"
	f.store_string(text)
	f.close()
	return path
