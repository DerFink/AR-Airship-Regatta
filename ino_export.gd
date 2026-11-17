# 2026-11-17 20:45 – Differenzschub (Nick/Gier/Roll der Piloten-Knüppel) wird in den Teensy-Sketch übernommen (Freigabe 17.11.), Warnhinweis im Export
# 2026-11-17 21:10 – Modus-Tabelle: 1–5 Flugmodi parametrisch, PID je Modus/Achse, Mischtabellen je Modus, Motoren aus/Gas-Anteil/Grundstellung, Drehgeber S1–S4 (ohne Differenzschub); für Chewie-Standard unverändert
# 2026-11-17 09:00 – Zweite Kopfzeile im erzeugten Sketch: Lizenzhinweis GPL-3.0 (dRehmFlight), nur Kommentar
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
## Logische Kanäle für die Drehgeber S1–S4 (frei in der Vorlage), nur mit Kanalzuordnung
const GEBER_LOGICAL := [8, 9, 10, 11]
## Art je Flugmodus im Sketch (flightMode): 1 Direkt, 2 Angle, 3 Horizon, 4 PID je Achse
const ART_CODE := {"direkt": 1, "angle": 2, "horizon": 3, "pid": 4}
## Reihenfolge der Vorlage am Schalter Kanal 13 (oben, Mitte, unten)
const LEGACY_ARTS := ["direkt", "angle", "horizon"]


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
	# Flugmodi, PID je Modus, Mischtabellen, Motoren je Modus oder Drehgeber im
	# Modell? Dann wird die Modus-Tabelle erzeugt (braucht den erzeugten Mischer).
	# Sonst bleibt alles wie in der Vorlage (Chewie: Direkt/Angle/Horizon).
	var table := fc.airship != null and needs_mode_table(fc)
	if (opts.get("mixer", false) or table) and fc.airship:
		src = _gen_mixer(src, fc, notes, table)
	if not (opts.get("channels", {}) as Dictionary).is_empty():
		src = _gen_channels(src, opts.channels, notes, table)
	if table:
		src = _gen_modes(src, fc, opts.get("channels", {}), notes)
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
	# Lizenzhinweis (nur Kommentar): der Sketch beruht auf dRehmFlight (GPL-3.0)
	head += "\n// Lizenz: GNU GPL Version 3 - beruht auf dRehmFlight von Nicholas Rehm (github.com/nickrehm/dRehmFlight); Simulator: github.com/DerFink/AR-Airship-Regatta"
	return {"text": (head + "\n" + "\n".join(lines)).replace("\n", "\r\n"), "changed": changed, "missing": missing, "notes": notes}


# =============================================================================
# Parametrischer Mischer: ersetzt im Sketch die fest verdrahteten Zeilen für
# s1…s5 durch Zeilen für jedes Stellglied des Modells (gleiche Formeln wie im
# Chewie-Sketch, Winkel und Richtungen aus FlightController.actuator_table()).
# Für Chewie entsteht genau dieselbe Rechnung wie in BETA 1.4.
# =============================================================================
static func _gen_mixer(src: String, fc: FlightController, notes: Array, table := false) -> String:
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
	if table:
		m2.append("  //Rollausgleich (je Modus, MODE_ROLL_COMP): dann verteilt auch der Knueppel mit n + Rollwinkel")
		m2.append("  bool rcMode = MODE_ROLL_COMP[modeSlot];")
	for i in k:
		var a: Dictionary = acts[i]
		var sv := "s%d" % (i + 1)
		var aa := "(%s %s roll_IMU)*DEG2RAD" % [deg.call(a.n), "+" if a.rot > 0 else "-"]
		# Knueppelwinkel: fest n, mit Rollausgleich n + Rollwinkel (nur Modus-Tabelle)
		var nn: String = deg.call(a.n) if not table else "(rcMode ? (%s %s roll_IMU) : %s)" % [deg.call(a.n), "+" if a.rot > 0 else "-", deg.call(a.n)]
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
static func _gen_channels(src: String, ch: Dictionary, notes: Array, gebers := false) -> String:
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
	# Drehgeber S1–S4 (nur mit Modus-Tabelle): logische Kanaele 8–11, siehe GEBER_CH
	if gebers:
		for g in 4:
			var gk := "s%d" % (g + 1)
			if ch.has(gk) and int(ch[gk][0]) > 0:
				srcmap[GEBER_LOGICAL[g]] = clampi(int(ch[gk][0]), 1, 16)
				desc.append("S%d=CH%d" % [g + 1, int(ch[gk][0])])
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



# =============================================================================
# Modus-Tabelle (17.11.2026): Flugmodi des Modells parametrisch in den Sketch
# -----------------------------------------------------------------------------
# Was übernommen wird (je Flugmodus, 1–5 Stück, Schalter Kanal 13):
#   - Art: Direkt, Angle, Horizon (Regler der Vorlage) oder PID je Achse
#   - Name (für die serielle Ausgabe), Rollausgleich
#   - Mischtabelle für Flossen und Schwenker (Nick, Gier, Roll, Grundstellung,
#     Drehgeber S1–S4) – Direkt mit eigener Tabelle und PID
#   - PID je Achse: an/aus, Lage oder Drehrate, Kp, Ki, Kd, Grenze
#   - Motoren: aus in diesem Modus, Gas-Anteil, Grundstellung + Drehgeber
# Seit 1.6.1 auch Differenzschub (Nick/Gier/Roll der Knüppel des Piloten auf
# die Motoren, Freigabe Projektinhaber 17.11.2026). Der PID-Regler verändert
# den Schub weiterhin nicht; Kanal 14 bleibt Notaus.
# Für Chewie mit Standardwerten wird nichts davon erzeugt (Sketch wie bisher).
# =============================================================================

## Braucht das Modell die Modus-Tabelle? (sonst Sketch wie die Vorlage)
static func needs_mode_table(fc: FlightController) -> bool:
	var ship := fc.airship
	var modes: Array = fc.modes
	if modes.size() > 3:
		return true
	for i in modes.size():
		var m: Dictionary = modes[i]
		var art := str(m.get("art", "direkt"))
		if art != LEGACY_ARTS[i] or bool(m.get("roll_comp", false)):
			return true
		if m.get("mix") is Dictionary:
			return true
	if ship.mix_manual and fc.manual_mix_valid():
		return true
	return _table_has_extras(ship.mix_table)


## Enthält eine Tabelle Motorzeilen oder Grundstellung/Drehgeber?
static func _table_has_extras(t: Dictionary) -> bool:
	for key in t:
		var k := str(key)
		if k.begins_with("t") or k.begins_with("x") or k.begins_with("e"):
			return true
	return false


## Mischtabelle eines Modus für die Motoren (wie active_table im Simulator)
static func _motor_table(fc: FlightController, m: Dictionary) -> Dictionary:
	return m.get("mix") if m.get("mix") is Dictionary else fc.airship.mix_table


## Mischtabelle eines Modus für Flossen/Schwenker; {} = Mischer nach Einbaulage (Vorlage)
static func _servo_table(fc: FlightController, m: Dictionary) -> Dictionary:
	var art := str(m.get("art", "direkt"))
	if art == "pid":
		return fc._table_for(m)                      # eigene, „Mischer einstellen“ oder Vorschlag
	if art == "direkt":
		var own = m.get("mix")
		if own is Dictionary and fc._table_valid(own):
			return own
		if fc.airship.mix_manual and fc.manual_mix_valid():
			return fc.airship.mix_table
	return {}


## Zahl als C++-float
static func _f(v: float) -> String:
	return _fmt(snappedf(v, 0.00001)) + "f"


## Text für einen C-String (Name des Modus)
static func _cstr(t: String) -> String:
	return "\"" + t.replace("\\", "/").replace("\"", "'").left(20) + "\""


static func _gen_modes(src: String, fc: FlightController, ch: Dictionary, notes: Array) -> String:
	var ship := fc.airship
	var modes: Array = fc.modes.slice(0, 5)
	var n := modes.size()
	var acts := fc.actuator_table().slice(0, 7)
	var k := acts.size()
	var nm := mini(ship.motors.size(), 6)
	# Spiegelung der linken Schwenker wie in _gen_mixer (Servo andersherum eingebaut)
	var mirror := []
	for a in acts:
		mirror.append(-1.0 if a.kind == "motor" and a.x < -0.01 else 1.0)
	# Rolldrehung wie roll_rotate im Simulator: Spiegelung m der ersten Flosse
	var m_roll := 1.0
	for a in acts:
		if a.kind == "fin":
			m_roll = -float(a.rot)
			break
	var arts := []
	var names := []
	var rc := []
	var use_tab := []
	var mix := []
	var ext := []
	var pid := {"on": [], "ang": [], "kp": [], "ki": [], "kd": [], "max": []}
	var mot_off := []
	var mot_gas := []
	var mot_ext := []
	var diff_modes := []                        ## Modi mit Differenzschub (Nick/Gier/Roll auf Motoren)
	var run_idle := []                          ## Modi, in denen Motoren mit Grundstellung laufen (Gas auf Stopp)
	var geber_used := [false, false, false, false]
	for m in modes:
		var art := str(m.get("art", "direkt"))
		arts.append(ART_CODE.get(art, 1))
		names.append(_cstr(str(m.get("name", "Modus"))))
		rc.append("true" if bool(m.get("roll_comp", false)) else "false")
		# --- Servos ---
		var tab := _servo_table(fc, m)
		use_tab.append("false" if tab.is_empty() else "true")
		var rows := []
		var erows := []
		for i in k:
			var key: String = acts[i].key
			var w = tab.get(key)
			var e = tab.get("e" + key)
			var kk: Array = w if w is Array and w.size() >= 3 else [0.0, 0.0, 0.0]
			rows.append("{%s, %s, %s}" % [_f(kk[0] / 100.0), _f(kk[1] / 100.0), _f(kk[2] / 100.0)])
			var ee: Array = e if e is Array and e.size() >= 5 else [0.0, 0.0, 0.0, 0.0, 0.0]
			erows.append("{%s}" % ", ".join(ee.slice(0, 5).map(func(x): return _f(float(x) / 100.0))))
			for g in 4:
				if absf(float(ee[g + 1])) > 0.01 and not tab.is_empty(): geber_used[g] = true
		mix.append("{" + ", ".join(rows) + "}")
		ext.append("{" + ", ".join(erows) + "}")
		# --- PID je Achse (Reihenfolge Nick, Rolle, Gier) ---
		var axes: Dictionary = m.get("axes", FlightController.default_axes()) if art == "pid" else {}
		var row := {"on": [], "ang": [], "kp": [], "ki": [], "kd": [], "max": []}
		for ax in ["pitch", "roll", "yaw"]:
			var a: Dictionary = axes.get(ax, {})
			row.on.append("true" if bool(a.get("on", false)) else "false")
			row.ang.append("true" if str(a.get("kind", "rate")) == "angle" and ax != "yaw" else "false")
			row.kp.append(_f(float(a.get("Kp", 0.0)))); row.ki.append(_f(float(a.get("Ki", 0.0))))
			row.kd.append(_f(float(a.get("Kd", 0.0)))); row.max.append(_f(float(a.get("max", 30.0))))
		for key in row:
			pid[key].append("{" + ", ".join(row[key]) + "}")
		# --- Motoren ---
		var mt := _motor_table(fc, m)
		var off := []
		var gas := []
		var mex := []
		for j in 6:
			var x := j < nm and bool(mt.get("x%d" % j, false))
			off.append("true" if x else "false")
			var t = mt.get("t%d" % j)
			var e = mt.get("et%d" % j)
			# Schub = (Gas·Gas% + Nick·Nick% + Gier·Gier% + Roll·Roll%) – Knüppel des Piloten (wie motor_throttle)
			var kk := [1.0, 0.0, 0.0, 0.0]
			if t is Array and t.size() >= 4:
				kk = [float(t[0]) / 100.0, float(t[1]) / 100.0, float(t[2]) / 100.0, float(t[3]) / 100.0]
				if j < nm and not x and absf(kk[1]) + absf(kk[2]) + absf(kk[3]) > 0.0001 and not diff_modes.has(str(m.get("name", ""))):
					diff_modes.append(str(m.get("name", "")))
			if j >= nm: kk = [0.0, 0.0, 0.0, 0.0]
			gas.append("{%s}" % ", ".join(kk.map(func(v): return _f(v))))
			var ee: Array = e if e is Array and e.size() >= 5 else [0.0, 0.0, 0.0, 0.0, 0.0]
			mex.append("{%s}" % ", ".join(ee.slice(0, 5).map(func(v): return _f(float(v) / 100.0))))
			if j < nm and not x and absf(float(ee[0])) > 0.5 and not run_idle.has(str(m.get("name", ""))):
				run_idle.append(str(m.get("name", "")))
			for g in 4:
				if j < nm and absf(float(ee[g + 1])) > 0.01: geber_used[g] = true
		mot_off.append("{" + ", ".join(off) + "}")
		mot_gas.append("{" + ", ".join(gas) + "}")
		mot_ext.append("{" + ", ".join(mex) + "}")
	# Drehgeber: Kanal (mit Kanalzuordnung: logischer Kanal 8–11, sonst SBUS-Kanal direkt)
	var gch := []
	var ginv := []
	for g in 4:
		var gk := "s%d" % (g + 1)
		var phys := int(ch[gk][0]) if ch.has(gk) else 0
		gch.append(str(GEBER_LOGICAL[g] if phys > 0 else 0))
		ginv.append(_f(-1.0 if ch.has(gk) and bool(ch[gk][1]) else 1.0))
		if geber_used[g] and phys <= 0:
			notes.append("WARNUNG: Drehgeber S%d wird gemischt, ist aber keinem Senderkanal zugeordnet (Sender kalibrieren)" % (g + 1))
	if ch.is_empty() and geber_used.has(true):
		notes.append("WARNUNG: Drehgeber werden gemischt – bitte mit Kanalzuordnung exportieren")
	# Failsafe-Modus: erster Angle-Modus, sonst die Mittelstellung
	var fs := arts.find(2)
	# --- globaler Block ---
	var g := PackedStringArray()
	g.append("//--- MODUSTABELLE-BLOCK-BEGIN (erzeugt aus RC Airship Regatta)")
	g.append("//========================================================================================================================//")
	g.append("//  FLUGMODI DES MODELLS: Schalter Kanal 13 wird in MODE_COUNT gleich breite Stufen geteilt, oben (2000 us) = Modus 1.")
	g.append("//  Art: 1 = Direkt, 2 = Angle, 3 = Horizon (Regler wie Vorlage), 4 = PID je Achse (Lage oder Drehrate, Werte unten).")
	g.append("//  Direkt mit eigener Mischtabelle und PID mischen ueber MODE_MIX (Nick, Gier, Roll; -1..1 = voller Ausschlag des Bauteils).")
	g.append("//  Motoren: MOT_OFF = in diesem Modus aus, MOT_MIX = Anteile {Gas, Nick, Gier, Roll} der Knueppel des Piloten,")
	g.append("//  MOT_EXT = Grundstellung + Drehgeber S1..S4. Der PID-Regler veraendert den Schub nicht. Notaus: Kanal 14.")
	g.append("//  VOR DEM ERSTFLUG: Bodentest je Modus (Propeller ab).")
	g.append("//========================================================================================================================//")
	g.append("const int   MODE_COUNT = %d;" % n)
	g.append("const int   MODE_ART[MODE_COUNT]       = {%s};" % ", ".join(arts.map(func(v): return str(v))))
	g.append("const char* MODE_NAME[MODE_COUNT]      = {%s};" % ", ".join(names))
	g.append("const bool  MODE_ROLL_COMP[MODE_COUNT] = {%s};" % ", ".join(rc))
	g.append("const bool  MODE_USE_TABLE[MODE_COUNT] = {%s}; //Direkt/PID: Mischtabelle statt Mischer nach Einbaulage" % ", ".join(use_tab))
	g.append("const int   MODE_FAILSAFE_SLOT = %d;    //Modus bei Funkausfall (-1 = Schalterstellung); Motoren sind dann ohnehin aus" % fs)
	g.append("//Mischtabelle [Modus][Servo] = {Nick, Gier, Roll}; Servo-Reihenfolge wie s1..s%d" % k)
	g.append("const float MODE_MIX[MODE_COUNT][SERVO_ACT_COUNT][3] = {%s};" % ", ".join(mix))
	g.append("//Grundstellung und Drehgeber [Modus][Servo] = {Grundstellung, S1, S2, S3, S4}")
	g.append("const float MODE_EXT[MODE_COUNT][SERVO_ACT_COUNT][5] = {%s};" % ", ".join(ext))
	var maxd := []
	var tdir := []
	var swv := []
	for i in k:
		maxd.append(_f(float(acts[i].max)))
		tdir.append(_f(mirror[i]))
		swv.append("true" if acts[i].kind == "motor" else "false")
	g.append("const float SERVO_MAX_DEG[SERVO_ACT_COUNT]   = {%s}; //voller Ausschlag des Bauteils (Grad)" % ", ".join(maxd))
	g.append("const float SERVO_TABLE_DIR[SERVO_ACT_COUNT] = {%s}; //Richtung (linke Schwenker gespiegelt eingebaut)" % ", ".join(tdir))
	g.append("const bool  SERVO_IS_SWIVEL[SERVO_ACT_COUNT] = {%s};" % ", ".join(swv))
	g.append("const float ROLL_ROT_M = %s;                 //Drehsinn fuer den Rollausgleich (wie Simulator)" % _f(m_roll))
	g.append("//PID je Modus und Achse {Nick, Rolle, Gier} (nur Art 4): an, Lage (sonst Drehrate), Kp, Ki, Kd, Grenze (Grad bzw. Grad/s)")
	g.append("const bool  PID_ON[MODE_COUNT][3]    = {%s};" % ", ".join(pid.on))
	g.append("const bool  PID_ANGLE[MODE_COUNT][3] = {%s};" % ", ".join(pid.ang))
	g.append("const float PID_KP[MODE_COUNT][3]    = {%s};" % ", ".join(pid.kp))
	g.append("const float PID_KI[MODE_COUNT][3]    = {%s};" % ", ".join(pid.ki))
	g.append("const float PID_KD[MODE_COUNT][3]    = {%s};" % ", ".join(pid.kd))
	g.append("const float PID_MAX[MODE_COUNT][3]   = {%s};" % ", ".join(pid.max))
	g.append("//Motoren je Modus (ESC m1..m6)")
	g.append("const int   MOTOR_COUNT = %d;" % nm)
	g.append("const bool  MOT_OFF[MODE_COUNT][6]    = {%s};" % ", ".join(mot_off))
	g.append("const float MOT_MIX[MODE_COUNT][6][4] = {%s}; //{Gas, Nick, Gier, Roll}" % ", ".join(mot_gas))
	g.append("const float MOT_EXT[MODE_COUNT][6][5] = {%s};" % ", ".join(mot_ext))
	g.append("//Drehgeber S1..S4: Kanal (0 = nicht belegt) und Richtung")
	g.append("const int   GEBER_CH[4]  = {%s};" % ", ".join(gch))
	g.append("const float GEBER_DIR[4] = {%s};" % ", ".join(ginv))
	g.append("int   modeSlot = 0;                    //gewaehlter Modus (0 .. MODE_COUNT-1)")
	g.append("float pidInt[3]  = {0.0f, 0.0f, 0.0f}; //PID-Modus: Integrale {Nick, Rolle, Gier}")
	g.append("float pidPrev[3] = {0.0f, 0.0f, 0.0f}; //PID-Modus: Drehrate im letzten Loop (D bei Drehratenregelung)")
	g.append("float pidOut[3]  = {0.0f, 0.0f, 0.0f}; //PID-Modus: Ausgang {Nick, Rolle, Gier} (-1..1)")
	g.append("//--- MODUSTABELLE-BLOCK-END")
	g.append("")
	var gs := src.find("\nvoid setup() {")
	if gs < 0:
		notes.append("WARNUNG: setup() nicht gefunden – Modus-Tabelle fehlt")
		return src
	src = src.substr(0, gs + 1) + "\n".join(g) + "\n" + src.substr(gs + 1)
	# --- Moduswahl ---
	var fm := PackedStringArray()
	fm.append("void determineFlightMode() {")
	fm.append("  //DESCRIPTION: Kanal 13 in MODE_COUNT Stufen teilen (oben = Modus 1) und die Art des Modus setzen (erzeugt, RC Airship Regatta)")
	fm.append("  int slot = (int)floorf((2000.0f - (float)channel_13_pwm)/1000.0f*MODE_COUNT);")
	fm.append("  slot = constrain(slot, 0, MODE_COUNT - 1);")
	fm.append("  if (radioFailsafe && MODE_FAILSAFE_SLOT >= 0) slot = MODE_FAILSAFE_SLOT;")
	fm.append("  int newMode = imuOK ? MODE_ART[slot] : 1;       //ohne IMU nur Direktsteuerung")
	fm.append("  if (newMode != flightMode || slot != modeSlot) {")
	fm.append("    resetControllers();                            //keine Integrator-Spruenge beim Umschalten")
	fm.append("    adaptResetDetector();                          //Lern-Erkennung neu starten")
	fm.append("    for (int a = 0; a < 3; a++) { pidInt[a] = 0.0f; pidOut[a] = 0.0f; }")
	fm.append("    flightMode = newMode;")
	fm.append("    modeSlot = slot;")
	fm.append("    Serial.print(\"Modus \"); Serial.print(slot + 1); Serial.print(\": \"); Serial.println(MODE_NAME[slot]);")
	fm.append("  }")
	fm.append("  applyModeGains();")
	fm.append("}")
	src = _replace_function(src, "void determineFlightMode() {", "\n".join(fm))
	# --- Loop: PID-Modus statt controlANGLE ---
	var lp_old := "  if (flightMode != 1) {\n    controlANGLE(); //Stabilize on angle setpoint\n  }"
	var lp_new := "  if (flightMode == 2 || flightMode == 3) {\n    controlANGLE(); //Stabilize on angle setpoint\n  }\n  else if (flightMode == 4) {\n    controlPIDMode(); //PID je Achse (Modus-Tabelle)\n  }"
	if src.find(lp_old) < 0:
		notes.append("WARNUNG: Regleraufruf im loop() nicht gefunden")
	src = src.replace(lp_old, lp_new)
	# --- Mixer: Servos je Modus, Motoren aus der Tabelle ---
	var sm_old := "  //Servo Mix\n  if (flightMode == 1) {\n    mixServosDirect();\n  }"
	var sm_new := "  //Servo Mix (Modus-Tabelle: PID und Direkt mit eigener Tabelle mischen ueber MODE_MIX)\n  if (flightMode == 4) {\n    mixServosTable(pidOut[0], pidOut[2], pidOut[1]);\n  }\n  else if (flightMode == 1) {\n    if (MODE_USE_TABLE[modeSlot]) mixServosTableDirect();\n    else mixServosDirect();\n  }"
	if src.find(sm_old) < 0:
		notes.append("WARNUNG: Servo-Mix in controlMixer() nicht gefunden")
	src = src.replace(sm_old, sm_new)
	var th_old := "  float throwScale = (flightMode == 1) ? servo_throw_m1 : ((flightMode == 3) ? servo_throw_m3 : servo_throw_m2);"
	var th_new := "  //Tabellen-Modi: Tabelle gibt den Ausschlag schon in Bruchteilen des vollen Ausschlags vor (kein zusaetzlicher Faktor)\n  float throwScale = (flightMode == 4 || (flightMode == 1 && MODE_USE_TABLE[modeSlot])) ? 1.0f : ((flightMode == 1) ? servo_throw_m1 : ((flightMode == 3) ? servo_throw_m3 : servo_throw_m2));"
	if src.find(th_old) < 0:
		notes.append("WARNUNG: throwScale in controlMixer() nicht gefunden")
	src = src.replace(th_old, th_new)
	# Motor-Mix ersetzen (Vorlage: 2 Motoren; _gen_mixer: n Motoren mit gleichem Gas)
	var q0 := src.find("  //Motor Mix")
	var q1 := src.find("m6_command_scaled = MOTOR_STOP_THRO;", q0)
	if q0 > 0 and q1 > q0:
		src = src.substr(0, q0) + "  //Motor Mix (Modus-Tabelle: Motor aus, Gas-Anteil, Grundstellung + Drehgeber; Schub nur vom Piloten)\n  mixMotorsTable();" + src.substr(q1 + "m6_command_scaled = MOTOR_STOP_THRO;".length())
	else:
		notes.append("WARNUNG: Motor-Mix nicht gefunden")
	# --- neue Funktionen vor determineFlightMode ---
	var f := PackedStringArray()
	f.append("//--- MODUSTABELLE-FUNKTIONEN-BEGIN (erzeugt aus RC Airship Regatta)")
	f.append("float geberVal(int g) {")
	f.append("  //DESCRIPTION: Drehgeber S1..S4 als -1..1 (Mitte 1500 us), 0 wenn nicht belegt")
	f.append("  if (GEBER_CH[g] <= 0) return 0.0f;")
	f.append("  return GEBER_DIR[g]*constrain(((float)getChannelPwm(GEBER_CH[g]) - 1500.0f)/500.0f, -1.0f, 1.0f);")
	f.append("}")
	f.append("")
	f.append("float extPart(const float* e, float v, float &off) {")
	f.append("  //DESCRIPTION: Grundstellung e[0] und Drehgeber e[1..4] auf den Knueppelanteil v anwenden (wie _ext im Simulator)")
	f.append("  off = constrain(e[0], -1.0f, 1.0f);")
	f.append("  for (int g = 0; g < 4; g++) v += e[g + 1]*geberVal(g);")
	f.append("  return v;")
	f.append("}")
	f.append("")
	f.append("float groupFactor(const float* off, const float* v, const bool* use, int count) {")
	f.append("  //DESCRIPTION: gemeinsame Desaturierung: kleinster Faktor, mit dem kein Ausgang anschlaegt (Verhaeltnisse bleiben)")
	f.append("  float f = 1.0f;")
	f.append("  for (int i = 0; i < count; i++) {")
	f.append("    if (!use[i] || fabsf(v[i]) < 1e-6f) continue;")
	f.append("    float room = (v[i] > 0.0f) ? (1.0f - off[i]) : (1.0f + off[i]);")
	f.append("    if (fabsf(v[i]) > room) f = fminf(f, fmaxf(room, 0.0f)/fabsf(v[i]));")
	f.append("  }")
	f.append("  return f;")
	f.append("}")
	f.append("")
	f.append("void rollRotate(float &p, float &y) {")
	f.append("  //DESCRIPTION: Rollausgleich - Hoehen- und Seitenbefehl in die Achsen des gerollten Luftschiffs drehen")
	f.append("  float a = ROLL_ROT_M*roll_IMU*DEG2RAD;")
	f.append("  float p2 = p*cosf(a) - y*sinf(a);")
	f.append("  float y2 = p*sinf(a) + y*cosf(a);")
	f.append("  p = p2; y = y2;")
	f.append("}")
	f.append("")
	f.append("void mixServosTable(float p, float y, float r) {")
	f.append("  //DESCRIPTION: Mischtabelle des Modus auf alle Servos (p, y, r: -1..1). Flossen einzeln begrenzt, Schwenker gemeinsam.")
	f.append("  float* cmd[8]    = {%s};" % ", ".join(["nullptr"] + range(1, 8).map(func(i): return ("&s%d_command_scaled" % i) if i <= k else "nullptr")))
	f.append("  float* center[8] = {%s};" % ", ".join(["nullptr"] + range(1, 8).map(func(i): return ("&s%d_center" % i) if i <= k else "nullptr")))
	f.append("  float off[SERVO_ACT_COUNT], v[SERVO_ACT_COUNT];")
	f.append("  for (int i = 0; i < SERVO_ACT_COUNT; i++) {")
	f.append("    const float* w = MODE_MIX[modeSlot][i];")
	f.append("    v[i] = extPart(MODE_EXT[modeSlot][i], w[0]*p + w[1]*y + w[2]*r, off[i]);")
	f.append("  }")
	f.append("  float fs = groupFactor(off, v, SERVO_IS_SWIVEL, SERVO_ACT_COUNT);")
	f.append("  for (int i = 0; i < SERVO_ACT_COUNT; i++) {")
	f.append("    float c = SERVO_IS_SWIVEL[i] ? constrain(off[i] + v[i]*fs, -1.0f, 1.0f) : constrain(off[i] + v[i], -1.0f, 1.0f);")
	f.append("    float dir = SERVO_IS_SWIVEL[i] ? motor_servo_dir*SERVO_TABLE_DIR[i] : SERVO_TABLE_DIR[i];")
	f.append("    *cmd[i + 1] = *center[i + 1] + dir*c*SERVO_MAX_DEG[i]/180.0f;   //Ausschlag in Grad -> 0..1 (0..180 Grad)")
	f.append("  }")
	f.append("}")
	f.append("")
	f.append("void mixServosTableDirect() {")
	f.append("  //DESCRIPTION: Direkt mit Mischtabelle - Knueppel (-1..1) ohne Regler, Rolle mit Totband wie Mode 1")
	f.append("  float p = pitch_des/maxPitch;")
	f.append("  float y = yaw_des/maxYaw;")
	f.append("  float rollStick = yawLStick_des/maxYaw;")
	f.append("  float r = 0.0f;")
	f.append("  if (fabsf(rollStick) > MODE1_ROLL_DEADBAND) {")
	f.append("    float over = (fabsf(rollStick) - MODE1_ROLL_DEADBAND)/(1.0f - MODE1_ROLL_DEADBAND);")
	f.append("    r = MODE1_ROLL_SIGN*((rollStick > 0.0f) ? over : -over);")
	f.append("  }")
	f.append("  if (MODE_ROLL_COMP[modeSlot]) rollRotate(p, y);")
	f.append("  mixServosTable(p, y, r);")
	f.append("}")
	f.append("")
	f.append("void controlPIDMode() {")
	f.append("  //DESCRIPTION: Art 4 - je Achse Lage oder Drehrate regeln (wie der PID-Modus im Simulator)")
	f.append("  //  Lage:     Soll = Knueppel * Grenze (Grad),   Fehler = Soll - Winkel,    D auf die Drehrate")
	f.append("  //  Drehrate: Soll = Knueppel * Grenze (Grad/s), Fehler = Soll - Kreisel,  D auf die Drehbeschleunigung")
	f.append("  //  Ausgang = 0.01*(Kp*Fehler + Ki*Integral - Kd*D), begrenzt auf -1..1; Achse aus = Knueppel direkt")
	f.append("  float d = constrain(dt, 0.0001f, 0.05f);")
	f.append("  float rollStick = MODE1_ROLL_SIGN*yawLStick_des/maxYaw;")
	f.append("  if (fabsf(rollStick) <= MODE1_ROLL_DEADBAND) rollStick = 0.0f;")
	f.append("  float stick[3] = {pitch_des/maxPitch, rollStick, yaw_des/maxYaw};     //Nick, Rolle, Gier")
	f.append("  float angle[3] = {pitch_IMU, roll_IMU, 0.0f};")
	f.append("  float rate[3]  = {GyroY, GyroX, YAW_RATE_SIGN*GyroZ};")
	f.append("  for (int a = 0; a < 3; a++) {")
	f.append("    if (!PID_ON[modeSlot][a]) {")
	f.append("      pidInt[a] = 0.0f;")
	f.append("      pidOut[a] = stick[a];")
	f.append("      pidPrev[a] = rate[a];")
	f.append("      continue;")
	f.append("    }")
	f.append("    bool useAngle = PID_ANGLE[modeSlot][a] && a != 2;                       //Gier nur als Drehrate")
	f.append("    float sp = stick[a]*PID_MAX[modeSlot][a];")
	f.append("    float err = sp - (useAngle ? angle[a] : rate[a]);")
	f.append("    if (motorsEnabled) pidInt[a] = constrain(pidInt[a] + err*d, -i_limit, i_limit); //am Boden nichts aufsammeln")
	f.append("    float dterm = useAngle ? rate[a] : (rate[a] - pidPrev[a])/d;")
	f.append("    pidPrev[a] = rate[a];")
	f.append("    pidOut[a] = constrain(0.01f*(PID_KP[modeSlot][a]*err + PID_KI[modeSlot][a]*pidInt[a] - PID_KD[modeSlot][a]*dterm), -1.0f, 1.0f);")
	f.append("  }")
	f.append("  if (MODE_ROLL_COMP[modeSlot]) rollRotate(pidOut[0], pidOut[2]);")
	f.append("}")
	f.append("")
	f.append("void mixMotorsTable() {")
	f.append("  //DESCRIPTION: Motoren je Modus - aus, Anteile von Gas/Nick/Gier/Roll, Grundstellung + Drehgeber; alle gemeinsam desaturiert.")
	f.append("  //Gas -1..1 (Mitte = Stopp, 3D-ESC). Ohne Freigabe (Kanal 14) oder im Failsafe: alle auf Stopp.")
	f.append("  //Nick/Gier/Roll: rohe Knueppel des Piloten (Kanal 5/6/7, wie im Simulator), nicht der Reglerausgang")
	f.append("  float thr = 2.0f*thro_des - 1.0f;")
	f.append("  float stP = constrain(((float)channel_5_pwm - 1500.0f)/500.0f, -1.0f, 1.0f);")
	f.append("  float stY = constrain(((float)channel_6_pwm - 1500.0f)/500.0f, -1.0f, 1.0f);")
	f.append("  float stR = MODE1_ROLL_SIGN*constrain(((float)channel_7_pwm - 1500.0f)/500.0f, -1.0f, 1.0f);")
	f.append("  float off[6], v[6];")
	f.append("  bool use[6];")
	f.append("  for (int j = 0; j < 6; j++) {")
	f.append("    use[j] = (j < MOTOR_COUNT) && !MOT_OFF[modeSlot][j];")
	f.append("    off[j] = 0.0f; v[j] = 0.0f;")
	f.append("    const float* k = MOT_MIX[modeSlot][j];")
	f.append("    if (use[j]) v[j] = extPart(MOT_EXT[modeSlot][j], k[0]*thr + k[1]*stP + k[2]*stY + k[3]*stR, off[j]);")
	f.append("  }")
	f.append("  float f = groupFactor(off, v, use, 6);")
	f.append("  float out[6];")
	f.append("  for (int j = 0; j < 6; j++) out[j] = use[j] ? constrain(off[j] + v[j]*f, -1.0f, 1.0f) : 0.0f;")
	f.append("  float trim[6] = {motor1_trim, motor2_trim, 0.0f, 0.0f, 0.0f, 0.0f};")
	f.append("  float* m[6] = {&m1_command_scaled, &m2_command_scaled, &m3_command_scaled, &m4_command_scaled, &m5_command_scaled, &m6_command_scaled};")
	f.append("  for (int j = 0; j < 6; j++) {")
	f.append("    bool run = motorsEnabled && use[j];")
	f.append("    *m[j] = (j < MOTOR_COUNT ? trim[j] : 0.0f) + MOTOR_STOP_THRO + (run ? 0.5f*out[j] : 0.0f);   //0.5 = Stopp")
	f.append("  }")
	f.append("}")
	f.append("//--- MODUSTABELLE-FUNKTIONEN-END")
	f.append("")
	var fd := src.find("void determineFlightMode() {")
	src = src.substr(0, fd) + "\n".join(f) + "\n" + src.substr(fd)
	# Hinweise
	var desc := PackedStringArray()
	for i in n:
		desc.append("%d=%s (%s)" % [i + 1, str(modes[i].get("name", "")), str(modes[i].get("art", ""))])
	notes.append("Flugmodi aus dem Modell (Kanal 13 in %d Stufen, oben = 1): %s" % [n, ", ".join(desc)])
	if not diff_modes.is_empty():
		notes.append("ACHTUNG: Im Modus %s steuern Nick/Gier/Roll den Schub mit (Differenzschub) – Motoren können auch bei Gas auf Stopp laufen, sobald ein Knüppel ausgeschlagen ist (Kanal 14 = Notaus)" % ", ".join(diff_modes))
	if not run_idle.is_empty():
		notes.append("ACHTUNG: Im Modus %s haben Motoren eine Grundstellung – sie laufen bei freigegebenem Kanal 14 auch mit Gas auf Stopp (Drehgeber bzw. Kanal 14 = Notaus)" % ", ".join(run_idle))
	return src
