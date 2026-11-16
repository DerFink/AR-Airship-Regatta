# 2026-11-16 15:50 – Prüfstand läuft jetzt weiter: Auswertung 4 s nach dem Sprung, dann stop()
# 2026-11-16 12:45 – Erstversion: Prüfstand der Sprungantwort – die Ist-Lage (blau) muss sich nach dem Sprung bewegen (für Direkt, Angle und ohne FC)
extends SceneTree
var ok := true
var bench: StepBench
var fc: FlightController
var ship: AirshipPhysics
var pv_before := 0.0
var pv_max := -999.0
var pv_min := 999.0
var started := false
var done := false
var frames := 0
var case_i := 0
var t_step := -1
const CASES := [[1, true], [0, true], [0, false]]   # [Modus, FC eingebaut]

func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FlightController.SETTINGS_PATH))
	ship = AirshipPhysics.new()
	AirshipPresets.chewie(ship)
	ship.freeze = true                       # echtes Schiff steht (wie im Menü)
	root.add_child(ship)
	fc = FlightController.new()
	fc.airship = ship
	ship.add_child(fc)
	bench = StepBench.new()
	root.add_child(bench)
	bench.sample.connect(_on_sample)
	bench.step_started.connect(func(sp): started = true; t_step = frames; print("  Sprung bei %.1f km/h, Lage vorher %.2f°" % [sp * 3.6, pv_before]))
	_start()

func _start() -> void:
	var c: Array = CASES[case_i]
	fc.mode_index = c[0]
	ship.fc_teensy = c[1]
	started = false; done = false; t_step = -1; pv_max = -999.0; pv_min = 999.0
	print("Fall Modus %d, FC %s" % [c[0], str(c[1])])
	bench.run(fc, FlightController.Axis.PITCH, 15.0)

func _on_sample(axis: int, sp: float, pv: float) -> void:
	if axis != FlightController.Axis.PITCH: return
	pv = rad_to_deg(pv)                     # Signal liefert Bogenmaß
	if not started: pv_before = pv
	else:
		pv_max = maxf(pv_max, pv); pv_min = minf(pv_min, pv)

func _on_done() -> void:
	var swing := maxf(absf(pv_max - pv_before), absf(pv_min - pv_before))
	print("  Ist-Lage nach Sprung: %.2f … %.2f° (Ausschlag %.1f°)" % [pv_min, pv_max, swing])
	if swing < 3.0:
		print("FEHLER Ist-Lage bewegt sich kaum"); ok = false
	case_i += 1
	if case_i >= CASES.size():
		done = true
	else:
		_start()

func _physics_process(_dt: float) -> bool:
	frames += 1
	# 4 s nach dem Sprung auswerten (die Kopie fliegt weiter, bis stop())
	if started and t_step >= 0 and frames - t_step > 240 and not done:
		bench.stop()
		t_step = -1
		_on_done()
	if done or frames > 60 * 30:
		if not done: print("FEHLER Zeitüberschreitung"); ok = false
		print("OK" if ok else "FEHLGESCHLAGEN")
		print("ENDE")
		quit(0 if ok else 1)
		return true
	return false
