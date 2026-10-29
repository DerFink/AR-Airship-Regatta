# 2026-10-29 01:53 – Mischer-Aufruf mit getrennten Achsen
# 2026-10-28 07:53 – nur Schwenkmotoren über tail_gain/vec_gain statt Mischmodus
extends SceneTree
# Tests für Version 0.3:
#   1. Rückwärtsschub: reduzierter Wirkungsgrad, Sperre, Mischer-Vorzeichen
#   2. Modell-String: Rundreise verlustfrei, Prüfsumme, Grenzwerte, Pfad im Logo
#   3. Klang: Propeller erzeugt Samples und schweigt im Stand

func _initialize() -> void:
	# --- 1. Rückwärtsschub --------------------------------------------------
	var m := VectorMotor.new()
	m.armed = true; m.spool_time_s = 0.0; m.max_thrust_n = 2.0; m.reverse_efficiency = 0.5
	m.throttle_cmd = 1.0
	var f_fwd := m.compute_force(0.016).z
	m.throttle_cmd = -1.0
	var f_rev := m.compute_force(0.016).z
	print("Schub vor %.2f N (−Z), rückwärts %.2f N (+Z), Verhältnis %.2f" % [f_fwd, f_rev, -f_rev / f_fwd])
	m.reverse_allowed = false
	print("Rückwärts gesperrt → %.2f N" % m.compute_force(0.016).z)
	m.reverse_allowed = true
	print("Mischer-Referenzschub: vor %.2f · rückwärts %.2f · Mitte %.2f" % [m.signed_thrust_estimate(0.8), m.signed_thrust_estimate(-0.8), m.signed_thrust_estimate(0.0)])

	# Chewie im Rückwärtsgang: Nick-Stick muss die Gondeln GEGENSINNIG zur Vorwärtsfahrt schwenken
	var ship := AirshipPhysics.new()
	AirshipPresets.chewie(ship)
	var fc := FlightController.new()
	fc.airship = ship
	fc.tail_gain = 0.0; fc.vec_gain = 1.0   # nur Schwenkmotoren
	for gas in [0.6, -0.6]:
		fc.set_sticks(Vector2(0, gas), Vector2(0, -1))   # Knüppel ziehen = Nase hoch
		fc._mix(Vector3(fc.cmd_pitch, 0, 0), Vector3.ZERO, Vector3.ZERO)
		print("Gas %+.1f, Nick hoch → Schwenk rechts %+.2f links %+.2f" % [gas, ship.motors[0].swivel_cmd, ship.motors[1].swivel_cmd])

	# --- 2. Modell-String ---------------------------------------------------
	ship.livery.text = "CHEWIE"
	ship.livery.hull_color = Color("e5534b")
	ship.livery.logo_ref = "abc123def0.png"
	ship.hull.volume_m3 = 0.4
	ship.motors[0].reverse_efficiency = 0.7
	ship.motors[1].reverse_efficiency = 0.7
	var code := ModelCodec.encode(ship)
	print("String (%d Zeichen): %s…%s" % [code.length(), code.left(28), code.right(9)])
	var r := ModelCodec.decode(code)
	print("Dekodiert: ok=%s Name=%s" % [r.ok, r.name])
	var ship2 := AirshipPhysics.new()
	ModelCodec.apply(ship2, r.name, r.data)
	var code2 := ModelCodec.encode(ship2)
	print("Rundreise identisch: ", code == code2)
	print("  Volumen %.2f · Flossen %d · Motoren %d · Rückw.-Wirkung %.2f · Paar %s · Schrift %s · Logo %s · Logo fehlt: %s" % [
		ship2.hull.volume_m3, ship2.surfaces.size(), ship2.motors.size(), ship2.motors[0].reverse_efficiency,
		ship2.motors[0].pair_id, ship2.livery.text, ship2.livery.logo_ref, ship2.livery.logo_missing()])
	var mid := code.length() / 2                       # ein Zeichen mitten in den Daten ändern
	var broken := code.substr(0, mid) + ("B" if code[mid] != "B" else "C") + code.substr(mid + 1)
	print("Veränderter String: ", ModelCodec.decode(broken).error)
	print("Müll: ", ModelCodec.decode("hallo welt").error)

	# Manipulierte Werte + Pfad im Logo-Verweis → begrenzt bzw. verworfen
	var evil := {"v": 1, "hull": {"vol": 1e9, "ld": -3}, "fins": [], "motors": [{"thrust": 99999, "reff": 7}],
		"look": {"logo": "../../etc/passwd.png", "txt": "X".repeat(200)}}
	var raw := JSON.stringify(evil).to_utf8_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	var b64 := Marshalls.raw_to_base64(raw).replace("+", "-").replace("/", "_").replace("=", "")
	var re := ModelCodec.decode("LTA1:Boese:%s:%s" % [b64, b64.sha256_text().left(8)])
	print("Manipuliert: ok=%s vol=%s ld=%s schub=%s reff=%s logo='%s' textlänge=%d" % [re.ok, re.data.hull.vol, re.data.hull.ld,
		re.data.motors[0].thrust, re.data.motors[0].reff, re.data.look.logo, re.data.look.txt.length()])

	# Sammlung: speichern und wieder auflisten
	print("Eigenes Modell gespeichert: ", ModelLibrary.save_own(code))
	var names := AirshipPresets.list().map(func(e): return e.name)
	print("Modellauswahl: ", names)

	ship.free(); ship2.free(); fc.free()

	# --- 3. Klang -----------------------------------------------------------
	var mot := VectorMotor.new()
	mot.armed = true; mot.spool_time_s = 0.0
	var ps := PropSound.new()
	ps.setup(mot)
	root.add_child(ps)
	set_meta("ps", ps); set_meta("mot", mot)

var _f := 0
func _process(_dt: float) -> bool:
	_f += 1
	var mot: VectorMotor = get_meta("mot")
	var ps: PropSound = get_meta("ps")
	if _f == 2:
		mot.throttle_cmd = 0.7
		mot.compute_force(0.016)
	if _f == 30:
		print("Klang: Drehzahl %.0f U/min, geglättet %.0f, Wiedergabe aktiv=%s" % [mot.rpm(), ps._rpm, ps.playing])
		print("ENDE")
		return true
	return false
