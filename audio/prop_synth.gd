# 2026-11-11 16:35 – Bus „Motoren“ (Lautstärke/aus unter Einstellungen)
# 2026-11-11 10:30 – Klang-Sicherung: drei Stufen (static level: 2 Fein = je Motor, 1 Mittel = ein gemeinsamer Klang für alle Motoren, 0 Einfach = Schleife); Aussetzer und Rechenzeit werden an SoundGuard gemeldet, der stufenweise herunterschaltet
# 2026-11-10 17:00 – Erstversion: Propellerklang mit gleitender Tonhöhe – jeder Abtastwert bekommt seine eigene Drehzahl (zwischen zwei Bildern linear übergeblendet), dadurch keine Tonhöhen-Stufen mehr bei schnellem Gasgeben/-wegnehmen; Tabellen statt Sinus-Rechnung (≈ 3 ms Rechenzeit je Sekunde Klang); im Browser automatischer Rückfall auf die Schleife (PropSound), falls die Wiedergabe Aussetzer hat
# =============================================================================
# PropSynth.gd  (ein Knoten je Motor, sitzt an der Motorposition)
# -----------------------------------------------------------------------------
# Gleicher Klang wie PropSound (Blattfolge-Ton mit Obertönen, Motor-Pfeifen,
# Luftrauschen, Schwebung, Flattern beim Rückwärtslauf), aber selbst erzeugt:
#
#   Warum: PropSound verstellt die Tonhöhe einer fertigen Schleife nur einmal
#   pro Bild (60/s). Bei schnellem Gasgeben springt die Drehzahl zwischen zwei
#   Bildern um bis zu 40 % → hörbare Treppe statt Kurve.
#   Hier: Zielwerte (Frequenz, Lautstärke, Rückwärtsanteil) kommen einmal pro
#   Bild; beim Füllen des Tonpuffers wird zwischen altem und neuem Wert für
#   JEDEN Abtastwert linear übergeblendet → Tonhöhe gleitet stufenlos.
#
#   Schnell genug für Handy und Browser: Ton, Motor-Pfeifen, Flattern und
#   Rauschen kommen aus vorberechneten Tabellen (eine Schwingung bzw. 4 s
#   Rauschen); pro Abtastwert nur Tabellen lesen und addieren.
#
#   Klang-Sicherung (SoundGuard): Aussetzer (Puffer läuft leer) und zu viel
#   Rechenzeit werden gemeldet; SoundGuard schaltet dann stufenweise
#   Fein → Mittel → Einfach (Schleife PropSound) herunter.
# =============================================================================
class_name PropSynth
extends AudioStreamPlayer3D

const SAMPLE_RATE := 22050.0
const TABLE_N := 2048               ## Abtastwerte je Schwingung in den Tontabellen
const NOISE_N := 88200              ## 4 s Rauschen bei SAMPLE_RATE
const F_REF := 200.0                ## Rauschtabelle ist auf diese Blattfolge-Frequenz gefiltert
const POLE_PAIRS := 7.0
const BUFFER_S := 0.06              ## Pufferlänge Desktop/Handy (s) = Verzögerung höchstens 60 ms
const BUFFER_S_WEB := 0.10          ## im Browser etwas mehr Puffer gegen Aussetzer
const SKIP_LIMIT := 4000            ## ausgelassene Abtastwerte (≈ 0,2 s) in den ersten Sekunden → Rückfall

## Klangstufe (setzt SoundGuard): 2 = Fein (je Motor ein Klang), 1 = Mittel
## (ein gemeinsamer Klang für alle Motoren), 0 = Einfach (Schleife PropSound)
static var level := 2
## Gemeldete Aussetzer (Puffer lief leer) – SoundGuard schaltet dann herunter
static var underrun := false
## Rechenzeit aller Klangerzeuger seit dem letzten Abholen (µs)
static var usec_acc := 0
## Gemeinsame Tabellen (einmal berechnet)
static var _tone := PackedFloat32Array()     ## Blattfolge-Ton mit Obertönen, eine Schwingung
static var _sine := PackedFloat32Array()     ## reiner Sinus (Motor-Pfeifen)
static var _flut := PackedFloat32Array()     ## Flatter-Hüllkurve (Rückwärtslauf), eine Schwingung
static var _noise := PackedFloat32Array()    ## tiefpassgefiltertes Rauschen

var motor: VectorMotor               ## erster (bzw. einziger) Motor
var motors: Array[VectorMotor] = []  ## alle Motoren dieses Klangs (Mittel: alle)
var _pb: AudioStreamGeneratorPlayback
var _buf := PackedVector2Array()
var _rpm := 0.0                     ## zuletzt übernommene Drehzahl (für Anzeige/Test)
# Zustand der Klangerzeugung (Phasen in Tabellen-Indizes)
var _ph := 0.0
var _phw := 0.0
var _phn := 0.0
# Werte am Ende des letzten Puffers (Start der Überblendung)
var _f0 := 0.0                      ## Blattfolge-Frequenz (Hz)
var _a0 := 0.0                      ## Lautstärke
var _r0 := 0.0                      ## Rückwärtsanteil 0…1
var _age := 0.0                     ## Laufzeit (s) für die Aussetzer-Prüfung
var _fallback: PropSound            ## Schleifen-Klang nach dem Rückfall


func setup(m: VectorMotor) -> void:
	motor = m
	motors = [m]


## Stufe „Mittel“: EIN Klang für alle Motoren (Mittelwert der Drehzahlen).
func setup_shared(ms: Array[VectorMotor]) -> void:
	motors = ms
	motor = ms[0]


func _ready() -> void:
	bus = "Motoren"                     # Lautstärke/aus unter Einstellungen (AppSettings)
	unit_size = 2.0 + motor.prop_diameter_in * 0.4
	max_db = 3.0
	attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	if level == 0:
		_switch_to_loop()
		return
	_make_tables()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = BUFFER_S_WEB if OS.has_feature("web") else BUFFER_S
	stream = gen
	play()
	_pb = get_stream_playback() as AudioStreamGeneratorPlayback
	_phn = randf() * NOISE_N            # Motoren rauschen versetzt


## Jedes Bild: Zielwerte bestimmen und den Tonpuffer auffüllen.
func _process(dt: float) -> void:
	if motor == null or _fallback != null:
		return
	if level == 0:                     # SoundGuard hat auf „Einfach“ geschaltet
		_switch_to_loop()
		return
	if _pb == null:
		return
	# --- Aussetzer melden (SoundGuard schaltet eine Stufe herunter) ---
	_age += dt
	if _age > 1.0 and _pb.get_skips() > SKIP_LIMIT:
		push_warning("Propellerklang: Aussetzer (%d)" % _pb.get_skips())
		underrun = true
		_age = -1e9                     # nur einmal melden
	var t0 := Time.get_ticks_usec()
	# --- Zielwerte für das Ende dieses Puffers ---
	# Mehrere Motoren (Mittel): mittlere Blattfolge-Frequenz, Lautstärken
	# addiert wie unabhängige Quellen (Wurzel der Quadratsumme)
	var f_sum := 0.0
	var w_sum := 0.0
	var a_sq := 0.0
	var r1 := 0.0
	for m in motors:
		var rpm := m.rpm()
		var detune := 1.0 + (0.012 * float(m.spin_dir) if motors.size() == 1 else 0.0)   # Schwebung zwischen Einzelklängen
		var size_gain := clampf(pow(m.prop_diameter_in / 5.0, 1.2), 0.4, 3.0) * 0.45
		var a := pow(rpm / m.max_rpm, 1.5) * size_gain if rpm >= 30.0 else 0.0
		f_sum += rpm / 60.0 * float(m.prop_blades) * detune * (a + 1e-6)
		w_sum += a + 1e-6
		a_sq += a * a
		if m.is_reversing(): r1 = 1.0
	_rpm = motor.rpm()
	_fill(f_sum / w_sum, sqrt(a_sq), r1)
	usec_acc += Time.get_ticks_usec() - t0


## Puffer füllen; Frequenz, Lautstärke und Rückwärtsanteil gleiten vom letzten
## zum neuen Wert über alle Abtastwerte dieses Puffers.
func _fill(f1: float, a1: float, r1: float) -> void:
	var n := _pb.get_frames_available()
	if n <= 0:
		return
	_synth(n, f1, a1, r1)
	_pb.push_buffer(_buf)


## n Abtastwerte in _buf erzeugen (auch für Tests ohne Audiogerät nutzbar).
func _synth(n: int, f1: float, a1: float, r1: float) -> void:
	if _buf.size() != n:
		_buf.resize(n)
	# Stille: ohne Rechnen nachschieben
	if _a0 <= 0.0 and a1 <= 0.0:
		_buf.fill(Vector2.ZERO)
		_f0 = f1; _r0 = r1
		return
	var inv := 1.0 / float(n)
	var df := (f1 - _f0) * inv
	var da := (a1 - _a0) * inv
	# Rückwärtsanteil weich (≈ 0,12 s), nicht schlagartig
	var r_end := move_toward(_r0, r1, float(n) / SAMPLE_RATE * 8.0)
	var dr := (r_end - _r0) * inv
	var f := _f0
	var a := _a0
	var r := _r0
	var k_tab := float(TABLE_N) / SAMPLE_RATE              # Hz → Tabellenschritt je Abtastwert
	var whine := POLE_PAIRS / float(motor.prop_blades)     # Motor-Pfeifen relativ zum Blattfolge-Ton
	var tn := float(TABLE_N)
	var nn := float(NOISE_N)
	# Lokale Verweise sind in GDScript deutlich schneller als Klassen-/static-Felder
	var tone_t := _tone
	var sine_t := _sine
	var flut_t := _flut
	var noise_t := _noise
	var buf := _buf
	var ph := _ph
	var phw := _phw
	var phn := _phn
	var inv_ref := 1.0 / F_REF
	for i in n:
		f += df; a += da; r += dr
		var step := f * k_tab
		ph += step
		if ph >= tn: ph -= tn
		phw += step * whine
		if phw >= tn: phw = fmod(phw, tn)
		phn += f * inv_ref                                # Rauschen folgt der Drehzahl (wie pitch_scale)
		if phn >= nn: phn -= nn
		var ip := int(ph)
		var tone := (tone_t[ip] + 0.08 * sine_t[int(phw)]) * (1.0 + r * flut_t[ip])   # Flattern beim Rückwärtslauf
		var ns := 0.35 + 0.25 * r                          # Rauschanteil vorwärts 0,35, rückwärts 0,6
		var s := a * (tone * (1.0 - ns) * 0.5 + noise_t[int(phn)] * ns * 2.0)
		buf[i] = Vector2(s, s)
	_ph = ph; _phw = phw; _phn = phn
	_f0 = f1; _a0 = a1; _r0 = r_end


## Rückfall: Schleifen-Klang (PropSound) für diesen Motor anlegen, Generator stoppen.
func _switch_to_loop() -> void:
	if _fallback != null:
		return
	stop()
	for m in motors:                   # je Motor eine Schleife (billig: nur Tonhöhe verstellen)
		var ps := PropSound.new()
		ps.setup(m)
		add_child(ps)
		ps.position = m.position - position
		_fallback = ps


## Tabellen einmal berechnen (gemeinsam für alle Motoren).
static func _make_tables() -> void:
	if _tone.size() == TABLE_N:
		return
	_tone.resize(TABLE_N); _sine.resize(TABLE_N); _flut.resize(TABLE_N)
	for i in TABLE_N:
		var p := TAU * float(i) / TABLE_N
		_tone[i] = sin(p) + 0.5 * sin(2.0 * p) + 0.25 * sin(3.0 * p) + 0.12 * sin(4.0 * p)
		_sine[i] = sin(p)
		_flut[i] = 0.3 * sin(PI * float(i) / TABLE_N)      # wie PropSound: 1 + 0,3·sin(π·Phase)
	# Rauschen: Tiefpass mit Grenze passend zu F_REF (wie PropSound), Filter vorab eingeschwungen
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var a := clampf(F_REF * 6.0 / SAMPLE_RATE, 0.005, 0.9)
	var raw := PackedFloat32Array(); raw.resize(NOISE_N)
	for i in NOISE_N: raw[i] = rng.randf_range(-1.0, 1.0)
	var lp := 0.0
	for i in range(NOISE_N - 4000, NOISE_N): lp += (raw[i] - lp) * a
	_noise.resize(NOISE_N)
	for i in NOISE_N:
		lp += (raw[i] - lp) * a
		_noise[i] = lp
