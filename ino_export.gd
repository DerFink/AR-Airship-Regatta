# 2026-11-11 14:50 – Hinweise für die Anzeige übersetzt (note_ui); Kopfzeile im Sketch bleibt Deutsch
# 2026-11-11 13:30 – Parametrisch: Mischer (Mode 1 und Mode 2/3), Servo-Ausgänge und Motoren werden aus der Leitwerks- und Antriebskonfiguration des Modells erzeugt; optional Kanalzuordnung des Senders
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


## Servo-Ausgänge des Teensy (Index 1…7 → Pin), wie im Chewie-Sketch
const SERVO_PINS := [0, 7, 6, 8, 9, 10, 11, 12]
## ESC-Ausgänge (Index 1…6 → Pin)
const ESC_PINS := [0, 0, 1, 2, 3, 4, 5]
## Logische Kanäle im Sketch (getDesState & Co.) für jede Funktion
const LOGICAL_CH := {"thr": 1, "pitch": 5, "yaw": 6, "roll": 7, "zero": 12, "mode": 13, "arm": 14}


## Passt der Aufbau des Modells zum Sketch? Leer = ja, sonst Hinweistext.
static func check(ship: AirshipPhysics, fc: FlightController = null) -> String:
	var notes := []
	if fc:
		var n := fc.actuator_table().size()
		if n > 7:
			notes.append(I18n.t("%d Servos nötig, der Teensy-Sketch hat 7 Servo-Ausgänge – die übrigen werden nicht angesteuert.") % n)
	if ship.motors.size() > 6:
		notes.append(I18n.t("Mehr als 6 Motoren – nur 6 ESC-Ausgänge."))
	if not ship.fc_teensy:
		notes.append(I18n.t("Im Modell ist kein Teensy eingebaut – der Sketch wird trotzdem erzeugt."))
	return " ".join(notes)


## Hinweis aus build() für die Anzeige übersetzen (im Sketch selbst bleibt er Deutsch).
static func note_ui(n: String) -> String:
	for prefix in ["Mischer aus dem Modell erzeugt: ", "Kanalzuordnung: "]:
		if n.begins_with(prefix):
			return I18n.t(prefix) + n.substr(prefix.length()).replace(" Grad)", "°)").replace(" umgekehrt", I18n.t(" umgekehrt"))
	var re := RegEx.create_from_string("^(\\d+) Motoren auf ESC-Pins (.*)$")
	var m := re.search(n)
	if m:
		return I18n.t("%d Motoren auf ESC-Pins %s") % [int(m.get_string(1)), m.get_string(2)]
	return I18n.t(n)


## Sketch erzeugen. Rückgabe {"text", "changed": [Liste "NAME alt → neu"], "missing": [...]}.
## opts: {"mixer": true = Mischer/Ausgänge aus dem Modell erzeugen,
##        "channels": {funktion: [kanal, umkehr]} oder leer = Kanäle wie Vorlage}
static func build(fc: FlightController, model_name: String, opts := {}) -> Dictionary:
	# Vorlage hat Windows-Zeilenenden (CRLF): intern mit LF arbeiten, am Ende wieder CRLF
	var src := FileAccess.get_file_as_string(TEMPLATE).replace("\r\n", "\n")
	var notes := []
	if opts.get("mixer", false) and fc.airship:
		src = _gen_mixer(src, fc, notes)
	if not (opts.get("channels", {}) as Dictionary).is_empty():
		src = _gen_channels(src, opts.channels, notes)
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
	var what := ("Reglerwerte aus dem Simulator eingesetzt – " + ", ".join(changed)) if not changed.is_empty() else "Reglerwerte = Vorlage BETA 1.4"
	if not notes.is_empty():
		what += "; " + "; ".join(notes)
	var head := "// %s | Aenderungen: Export aus RC Airship Regatta %s, Modell \"%s\": %s. VOR DEM ERSTFLUG: Bodentest (Propeller ab) - jede Flosse/jeden Schwenker auf Richtung pruefen" % [
		stamp.left(16), BuildInfo.VERSION, model_name, what]
	return {"text": (head + "\n" + "\n".join(lines)).replace("\n", "\r\n"), "changed": changed, "missing": missing, "notes": notes}


# =============================================================================
# Parametrischer Mischer: ersetzt im Sketch die fest verdrahteten Zeilen für
# s1…s5 durch Zeilen für jedes Stellglied des Modells (gleiche Formeln wie im
# Chewie-Sketch, Winkel und Richtungen aus FlightController.actuator_table()).
# Für Chewie entsteht genau dieselbe Rechnung wie in BETA 1.4.
# =============================================================================
static func _gen_mixer(src: String, fc: FlightController, notes: Array) -> String:
	var acts := fc.actuator_table().slice(0, 7)
	var ship := fc.airship
	var k := acts.size()
	# Motor-Schwenker: der Sketch spiegelt die linke Seite mechanisch (Servo
	# andersherum eingebaut); im Simulator steckt das in invert_swivel → zurückrechnen
	for a in acts:
		if a.kind == "motor" and a.x < -0.01:
			a.s = -a.s
	var desc := PackedStringArray()
	for i in k:
		desc.append("s%d=Pin %d %s (%d Grad)" % [i + 1, SERVO_PINS[i + 1], acts[i].name, roundi(acts[i].n)])
	notes.append("Mischer aus dem Modell erzeugt: " + ", ".join(desc))
	var deg := func(v: float) -> String: return "%.1ff" % v
	# --- Mode 1 (direkt) ---
	var m1 := PackedStringArray()
	m1.append("void mixServosDirect() {")
	m1.append("  //DESCRIPTION: Mode 1 - Knueppel direkt auf die Servos, keine Regelung (erzeugt aus dem Modell, RC Airship Regatta)")
	m1.append("  //Rolle (Kunstflug): linker Knueppel links/rechts (Kanal 7), mit Totband")
	m1.append("  float rollStick = yawLStick_des/maxYaw;                                  //-1 .. 1")
	m1.append("  float rollCmd = 0.0f;")
	m1.append("  if (fabsf(rollStick) > MODE1_ROLL_DEADBAND) {")
	m1.append("    float over = (fabsf(rollStick) - MODE1_ROLL_DEADBAND)/(1.0f - MODE1_ROLL_DEADBAND);")
	m1.append("    rollCmd = MODE1_ROLL_SIGN*((rollStick > 0.0f) ? over : -over);")
	m1.append("  }")
	for i in k:
		var a: Dictionary = acts[i]
		var sn := _sgn(sin(deg_to_rad(a.n)))
		var cs := _sgn(cos(deg_to_rad(a.n)))
		var sv := "s%d" % (i + 1)
		if a.kind == "fin":
			# Leitwerk: s = Mitte − Nick·sgn(sin n) − Gier·sgn(cos n) − Rolle
			m1.append("  %s_command_scaled = %s_center + %s*( %s*mode1_stick_pitch_tail*pitch_des %s*mode1_stick_yaw_tail*yaw_des %s*mode1_roll_tail*rollCmd ); //%s (Pin %d)" % [
				sv, sv, _n(a.s), _n(-sn, true), _n(-cs, true), _n(-a.r, true), a.name, SERVO_PINS[i + 1]])
		else:
			# Schwenker: s = Mitte + dir·(Nick·sgn(sin n) + Gier·sgn(cos n) + Rolle)
			m1.append("  %s_command_scaled = %s_center + motor_servo_dir*%s*( %s*mode1_stick_pitch_motor*pitch_des %s*mode1_stick_yaw_motor*yaw_des %s*MOTOR_ROLL_SIGN*mode1_roll_motor*rollCmd ); //%s (Pin %d)" % [
				sv, sv, _n(a.s), _n(sn * a.wp, true), _n(cs * a.wy, true), _n(a.wy, true), a.name, SERVO_PINS[i + 1]])
	m1.append("}")
	src = _replace_function(src, "void mixServosDirect() {", "\n".join(m1))
	# --- Mode 2/3 (stabilisiert): nur die Ausgabezeilen am Ende ersetzen ---
	var m2 := PackedStringArray()
	m2.append("  //Ausgabe je Stellglied (erzeugt aus dem Modell): Winkel n fest fuer Knueppel, n + Rollwinkel fuer die Stabilisierung")
	for i in k:
		var a: Dictionary = acts[i]
		var sv := "s%d" % (i + 1)
		var nn: String = deg.call(a.n)
		var aa := "(%s %s roll_IMU)*DEG2RAD" % [nn, "+" if a.rot > 0 else "-"]
		if a.kind == "fin":
			m2.append("  %s_command_scaled = %s_center + %s*( - tailPitchStick*sin(%s*DEG2RAD) - tailPitchStab*sin(%s) - tailYaw*cos(%s*DEG2RAD) %s*tailRoll ); //%s (Pin %d)" % [
				sv, sv, _n(a.s), nn, aa, nn, _n(-a.r, true), a.name, SERVO_PINS[i + 1]])
		else:
			m2.append("  %s_command_scaled = %s_center + motor_servo_dir*%s*( %s*motorPitchStick*sin(%s*DEG2RAD) %s*motorPitchStab*sin(%s) + swivelScale*(%s*motorYaw*cos(%s*DEG2RAD) %s*motorRoll) ); //%s (Pin %d)" % [
				sv, sv, _n(a.s), _n(a.wp), nn, _n(a.wp, true), aa, _n(a.wy), nn, _n(a.wy, true), a.name, SERVO_PINS[i + 1]])
	var i0 := src.find("  s1_command_scaled = s1_center + motor_servo_dir*( motorPitchStick*sin(n2)")
	var i1 := src.find("\n}", i0)
	if i0 > 0 and i1 > i0:
		src = src.substr(0, i0) + "\n".join(m2) + src.substr(i1)
	else:
		notes.append("WARNUNG: Ausgabezeilen Mode 2/3 nicht gefunden")
	# --- Gesamt-Ausschlag je Modus: Zeilen für alle Stellglieder ---
	var t := PackedStringArray()
	for i in k:
		t.append("  s%d_command_scaled = s%d_center + throwScale*(s%d_command_scaled - s%d_center);" % [i + 1, i + 1, i + 1, i + 1])
	var j0 := src.find("  s1_command_scaled = s1_center + throwScale*")
	var j1 := src.find("s5_command_scaled - s5_center);", j0)
	if j0 > 0 and j1 > j0:
		src = src.substr(0, j0) + "\n".join(t) + src.substr(j1 + "s5_command_scaled - s5_center);".length())
	# --- Roll-Wirkung der Leitwerke: Mittel von sin² über alle Flossen ---
	var fsum := 0.0
	var fcnt := 0
	for a in acts:
		if a.kind == "fin":
			fsum += pow(sin(deg_to_rad(a.n)), 2.0); fcnt += 1
	if fcnt > 0:
		src = src.replace("const float ROLL_AUTH_FACTOR = 0.5;", "const float ROLL_AUTH_FACTOR = %s;" % _fmt(snappedf(fsum / fcnt, 0.0001)))
	# --- Mittelstellungen für s6/s7 und Anzahl Stellglieder ---
	var cfg := "const int SERVO_ACT_COUNT = %d;             // Anzahl Servos fuer Flossen + Schwenker (erzeugt aus dem Modell)" % k
	if k >= 6: cfg += "\nfloat s6_center = 0.50;"
	if k >= 7: cfg += "\nfloat s7_center = 0.50;"
	var c0 := src.find("float s5_center")
	var c1 := src.find("\n", c0)
	src = src.substr(0, c1 + 1) + cfg + "\n" + src.substr(c1 + 1)
	# --- Servo-Ausgabe: Schleife über alle Stellglieder statt fest 1…5 ---
	var cmd := ["0.0f"]
	var cen := ["0.0f"]
	for i in range(1, 8):
		cmd.append("s%d_command_scaled" % i)
		cen.append(("s%d_center" % i) if i <= maxi(k, 5) else "0.5f")
	src = src.replace("  float cmd[6]    = {0.0f, s1_command_scaled, s2_command_scaled, s3_command_scaled, s4_command_scaled, s5_command_scaled}; //Index 1..5",
		"  float cmd[8]    = {%s}; //Index 1..7" % ", ".join(cmd))
	src = src.replace("  float center[6] = {0.0f, s1_center, s2_center, s3_center, s4_center, s5_center};",
		"  float center[8] = {%s};" % ", ".join(cen))
	src = src.replace("  for (int i = 1; i <= 5; i++) {\n    if (idle) {", "  for (int i = 1; i <= SERVO_ACT_COUNT; i++) {\n    if (idle) {")
	if k >= 6:
		src = src.replace("  servoOut(6, s6_command_scaled); //Servo 6 und 7: unveraendert\n", "" if k >= 6 else "")
	if k >= 7:
		src = src.replace("  servoOut(7, s7_command_scaled);\n", "")
	src = src.replace("(idx <= 5) ? SERVO_PWM_MIN_US : 900, (idx <= 5) ? SERVO_PWM_MAX_US : 2100", "(idx <= SERVO_ACT_COUNT) ? SERVO_PWM_MIN_US : 900, (idx <= SERVO_ACT_COUNT) ? SERVO_PWM_MAX_US : 2100")
	src = src.replace("(idx <= 5) ? SERVO_PWM_MIN_US : 900.0f", "(idx <= SERVO_ACT_COUNT) ? SERVO_PWM_MIN_US : 900.0f")
	src = src.replace("(idx <= 5) ? SERVO_PWM_MAX_US : 2100.0f", "(idx <= SERVO_ACT_COUNT) ? SERVO_PWM_MAX_US : 2100.0f")
	# --- Motoren: alle bekommen dasselbe Gas (kein Differenzschub, Gas nur vom Piloten) ---
	var nm := mini(ship.motors.size(), 6)
	if nm != 2:
		var mm := PackedStringArray()
		mm.append("  //Motor Mix (erzeugt: %d Motoren, alle mit demselben Gas)" % nm)
		mm.append("  float thr_all = motorsEnabled ? thro_des : MOTOR_STOP_THRO;")
		for i in range(1, 7):
			var trim := "motor1_trim + " if i == 1 else ("motor2_trim + " if i == 2 else "")
			mm.append("  m%d_command_scaled = %s;" % [i, (trim + "thr_all") if i <= nm else "MOTOR_STOP_THRO"])
		var q0 := src.find("  //Motor Mix\n  if (motorsEnabled) {")
		var q1 := src.find("m6_command_scaled = MOTOR_STOP_THRO;", q0)
		if q0 > 0 and q1 > q0:
			src = src.substr(0, q0) + "\n".join(mm) + src.substr(q1 + "m6_command_scaled = MOTOR_STOP_THRO;".length())
		notes.append("%d Motoren auf ESC-Pins %s" % [nm, ", ".join(ESC_PINS.slice(1, nm + 1).map(func(p): return str(p)))])
	return src


# =============================================================================
# Kanalzuordnung: SBUS-Kanäle des Senders auf die logischen Kanäle des
# Sketches legen (Gas 1, Höhe 5, Seite 6, Rolle 7, IMU-Null 12, Modus 13,
# Motorfreigabe 14). Umkehr nur für Knüppel (Schalter behalten ihre Logik).
# =============================================================================
static func _gen_channels(src: String, ch: Dictionary, notes: Array) -> String:
	var srcmap := []
	var rev := []
	for i in 17:
		srcmap.append(i); rev.append(0)
	var desc := PackedStringArray()
	for fn in LOGICAL_CH:
		if not ch.has(fn): continue
		var phys: int = clampi(int(ch[fn][0]), 1, 16)
		srcmap[LOGICAL_CH[fn]] = phys
		if fn in ["thr", "pitch", "yaw", "roll"] and ch[fn][1]:
			rev[LOGICAL_CH[fn]] = 1
		desc.append("%s=CH%d%s" % [fn, phys, " umgekehrt" if rev[LOGICAL_CH[fn]] else ""])
	# Kanäle, die durch die Zuordnung „frei“ würden, bekommen ihre eigene Quelle
	var block := PackedStringArray()
	block.append("      //Kanalzuordnung aus RC Airship Regatta (Sender): logischer Kanal k <- SBUS-Kanal CH_SRC[k], CH_REV = umkehren")
	block.append("      static const int CH_SRC[17] = {%s};" % ", ".join(srcmap.map(func(v): return str(v))))
	block.append("      static const int CH_REV[17] = {%s};" % ", ".join(rev.map(func(v): return str(v))))
	block.append("      float rawCh[17];")
	block.append("      for (int c = 1; c <= 16; c++) rawCh[c] = sbusChannels[c - 1] * scale + bias;")
	block.append("      float mapped[17];")
	block.append("      for (int c = 1; c <= 16; c++) { float v = rawCh[CH_SRC[c]]; mapped[c] = CH_REV[c] ? (3000.0f - v) : v; }")
	for c in range(1, 17):
		block.append("      channel_%d_pwm = mapped[%d];" % [c, c])
	var a0 := src.find("      channel_1_pwm = sbusChannels[0] * scale + bias;")
	var a1 := src.find("      channel_16_pwm = sbusChannels[15] * scale + bias;", a0)
	if a0 > 0 and a1 > a0:
		var e := src.find("\n", a1)
		src = src.substr(0, a0) + "\n".join(block) + src.substr(e)
		notes.append("Kanalzuordnung: " + ", ".join(desc))
	else:
		notes.append("WARNUNG: SBUS-Kanalblock nicht gefunden – Kanäle wie Vorlage")
	return src


## Ganze Funktion (ab Kopfzeile bis zur schließenden Klammer am Zeilenanfang) ersetzen.
static func _replace_function(src: String, head: String, body: String) -> String:
	var i0 := src.find(head)
	if i0 < 0: return src
	var i1 := src.find("\n}\n", i0)
	if i1 < 0: return src
	return src.substr(0, i0) + body + src.substr(i1 + 2)


## Faktor für den Code: "1.0f"/"-1.0f"; mit sign=true als "+1.0f"/"-1.0f".
static func _n(v: float, sign := false) -> String:
	if absf(v) < 1e-6: v = 0.0                       # kein „-0.0f“
	var t := "%.1ff" % v
	if sign and v >= 0.0: t = "+" + t
	return t


static func _sgn(x: float) -> float:
	return 0.0 if absf(x) < 1e-6 else signf(x)


## Zahl ohne überflüssige Nullen, immer mit Dezimalpunkt (C++ float).
static func _fmt(v: float) -> String:
	var t := ("%.6f" % v).rstrip("0")
	if t.ends_with("."): t += "0"
	return t


## Datei speichern bzw. im Browser herunterladen. Rückgabe: Ort für die Anzeige.
static func save(text: String, file_name: String) -> String:
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "text/plain")
		return I18n.t("Download: ") + file_name
	var dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if dir == "" or not DirAccess.dir_exists_absolute(dir) or OS.has_feature("mobile"):
		dir = ProjectSettings.globalize_path("user://export")
		DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(file_name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return I18n.t("Speichern fehlgeschlagen")
	f.store_string(text)
	f.close()
	return path
