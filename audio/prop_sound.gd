# 2026-11-09 14:00 – Feiner: 44,1 kHz statt 22 kHz; Rauschen als eigene, 4 s lange Schleife (vorher wiederholte sich das Rauschen mit der 1-s-Tonschleife – bei hoher Drehzahl mehrmals pro Sekunde hörbar als grobes Muster)
# 2026-11-09 13:45 – Klang nicht mehr Abtastwert für Abtastwert im Skript erzeugt (im Browser abgehackt und verzögert), sondern beim Start einmal als Schleife berechnet; im Flug nur noch Tonhöhe und Lautstärke nachgeführt. Rückwärtslauf als zweite Schleife (mehr Rauschen, Flattern), weich überblendet
# 2026-10-27 11:08 – Erstversion: prozedurales Propellergeräusch (Quadcopter-Klang) je Motor, abhängig von Propellergröße, Blattzahl, Drehzahl und Drehrichtung; räumlich am Motor; ohne Drehzahl absolute Stille
# =============================================================================
# PropSound.gd  (ein Knoten je Motor, sitzt an der Motorposition)
# -----------------------------------------------------------------------------
# Erzeugt den Klang selbst – keine Sounddateien, also lizenzfrei.
#
# Woraus sich der typische Quadcopter-Klang zusammensetzt:
#   1. Blattfolge-Ton: jedes Blatt "schlägt" einmal pro Umdrehung durch die
#      Luft → Grundton f = Drehzahl/60 · Blattzahl, plus Obertöne (Summen).
#   2. Motor-Pfeifen: der Elektromotor schaltet 7× pro Umdrehung um
#      (14 Magnetpole) → leiser, hoher Ton.
#   3. Rauschen: verwirbelte Luft, tiefpassgefiltert.
#   4. Schwebung: zwei gegenläufige Motoren drehen nie exakt gleich schnell –
#      die Drehrichtung verstimmt den Ton minimal, das erzeugt das bekannte
#      "Wabern" eines Multikopters.
#
# Umsetzung (schnell, auch im Browser):
#   Beim Start wird EINE Sekunde Klang bei einer festen Bezugs-Tonhöhe
#   (Blattfolge F_REF = 200 Hz) berechnet. Alle Töne haben in dieser Sekunde
#   eine ganze Zahl von Schwingungen → die Schleife läuft ohne Knacksen.
#   Im Flug ändert sich nur:
#     pitch_scale = tatsächliche Blattfolge-Frequenz / F_REF
#     volume_db   = Lautstärke aus Drehzahl und Propellergröße
#   Die Audio-Engine spielt die Schleife selbst ab – kein Skript pro Abtastwert.
#   Rückwärtslauf (Propeller gegen sein Profil: mehr Rauschen, Flattern) ist
#   eine zweite Schleife in einem zweiten Player; beide werden überblendet.
# =============================================================================
class_name PropSound
extends AudioStreamPlayer3D

const SAMPLE_RATE := 44100          ## volle Auflösung (hohe Drehzahl = Tonhöhe bis ×4)
const LOOP_FRAMES := 44100          ## 1 s Tonschleife (Ton ist periodisch, Wiederholung unhörbar)
const NOISE_FRAMES := 176400        ## 4 s Rauschschleife (Wiederholung nicht als Muster hörbar)
const F_REF := 200.0                ## Blattfolge-Ton der Schleife (Hz)
const POLE_PAIRS := 7.0             ## typischer Außenläufer (14 Pole)
const RPM_TAU := 0.03               ## Trägheit der Drehzahl-Anzeige im Klang (s)

## Fertige Schleifen je Blattzahl und Richtung zwischenspeichern (alle Motoren teilen sie)
static var _cache := {}

var motor: VectorMotor
var _rev_player: AudioStreamPlayer3D   ## zweite Tonschleife für den Rückwärtslauf
var _noise_player: AudioStreamPlayer3D ## Luftrauschen (eigene, lange Schleife)
var _rpm := 0.0                        ## geglättete Drehzahl (vermeidet Sprünge)
var _rev_mix := 0.0                    ## 0 = vorwärts, 1 = rückwärts (weich überblendet)
var _gain_fwd := 1.0                   ## gleicht die Normierung der Schleifen aus (gleiche Lautstärke wie vorher)
var _gain_rev := 1.0
var _noise_gain := 1.0


func setup(m: VectorMotor) -> void:
	motor = m


func _ready() -> void:
	# Größere Propeller sind weiter hörbar
	unit_size = 2.0 + motor.prop_diameter_in * 0.4
	max_db = 3.0
	attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	stream = _loop(motor.prop_blades, false)
	_gain_fwd = _cache["%d_false_g" % motor.prop_blades]
	volume_db = -80.0
	# Rückwärts-Schleife: gleicher Ort, gleiche Abstrahlung
	_rev_player = AudioStreamPlayer3D.new()
	_rev_player.unit_size = unit_size
	_rev_player.max_db = max_db
	_rev_player.attenuation_model = attenuation_model
	_rev_player.stream = _loop(motor.prop_blades, true)
	_gain_rev = _cache["%d_true_g" % motor.prop_blades]
	_rev_player.volume_db = -80.0
	add_child(_rev_player)
	# Rauschen: eigene lange Schleife, folgt der Drehzahl ebenfalls über die Tonhöhe
	_noise_player = AudioStreamPlayer3D.new()
	_noise_player.unit_size = unit_size
	_noise_player.max_db = max_db
	_noise_player.attenuation_model = attenuation_model
	_noise_player.stream = _noise_loop()
	_noise_gain = _cache["noise_g"]
	_noise_player.volume_db = -80.0
	add_child(_noise_player)
	# Beide laufen dauernd (stumm im Stillstand) – so gibt es beim Anlaufen
	# keinen Startverzug.
	play()
	_rev_player.play()
	_noise_player.play(randf() * 3.5)               # versetzt starten: die Motoren rauschen nicht gleich


## Jedes Bild: Tonhöhe und Lautstärke an die Drehzahl anpassen.
func _process(dt: float) -> void:
	if motor == null:
		return
	# Drehzahl weich nachführen (Propeller hat Trägheit)
	_rpm += (motor.rpm() - _rpm) * (1.0 - exp(-dt / RPM_TAU))
	_rev_mix = move_toward(_rev_mix, 1.0 if motor.is_reversing() else 0.0, dt * 8.0)
	if _rpm < 30.0:
		volume_db = -80.0                       # Stillstand = Stille
		_rev_player.volume_db = -80.0
		_noise_player.volume_db = -80.0
		return
	# Tonhöhe: Blattfolge-Frequenz, Drehrichtung verstimmt minimal (Schwebung)
	var detune := 1.0 + 0.012 * float(motor.spin_dir)
	var f_blade := _rpm / 60.0 * float(motor.prop_blades) * detune
	var ps := clampf(f_blade / F_REF, 0.05, 8.0)
	pitch_scale = ps
	_rev_player.pitch_scale = ps
	_noise_player.pitch_scale = ps
	# Lautstärke: steigt mit Drehzahl (≈ Leistung) und Propellergröße
	var size_gain := clampf(pow(motor.prop_diameter_in / 5.0, 1.2), 0.4, 3.0) * 0.45
	var level := pow(_rpm / motor.max_rpm, 1.5) * size_gain
	# Anteile wie in der Erstversion: Ton (1 − Rauschanteil) · 0,5, Rauschen Anteil · 2;
	# Rauschanteil vorwärts 0,35, rückwärts 0,6
	var noise_share := lerpf(0.35, 0.6, _rev_mix)
	volume_db = linear_to_db(maxf(level * 0.5 * 0.65 * _gain_fwd * (1.0 - _rev_mix), 1e-4))
	_rev_player.volume_db = linear_to_db(maxf(level * 0.5 * 0.4 * _gain_rev * _rev_mix, 1e-4))
	_noise_player.volume_db = linear_to_db(maxf(level * 2.0 * noise_share * _noise_gain, 1e-4))


## Eine Sekunde Ton bei F_REF berechnen (einmal je Blattzahl/Richtung).
## Enthält Blattfolge-Ton und Motor-Pfeifen; das Rauschen kommt aus _noise_loop().
static func _loop(blades: int, reverse: bool) -> AudioStreamWAV:
	var key := "%d_%s" % [blades, reverse]
	if _cache.has(key):
		return _cache[key]
	# Ganze Zahl von Schwingungen je Schleife → nahtloser Übergang
	var n_blade := F_REF * LOOP_FRAMES / SAMPLE_RATE                      # 200 Schwingungen
	var n_motor := roundf(n_blade * POLE_PAIRS / float(blades))          # Motor-Pfeifen
	var raw := PackedFloat32Array()
	raw.resize(LOOP_FRAMES)
	for i in LOOP_FRAMES:
		var ph := float(i) / LOOP_FRAMES
		var p := TAU * n_blade * ph
		# 1) Blattfolge-Ton mit abnehmenden Obertönen
		var tone := sin(p) + 0.5 * sin(2.0 * p) + 0.25 * sin(3.0 * p) + 0.12 * sin(4.0 * p)
		# 2) leises Motor-Pfeifen
		tone += 0.08 * sin(TAU * n_motor * ph)
		# Rückwärts: leichtes Flattern (Strömung reißt am Profil ab)
		if reverse:
			tone *= 1.0 + 0.3 * sin(PI * fposmod(n_blade * ph, 1.0))
		raw[i] = tone
	_cache[key] = _to_wav(raw, key)
	return _cache[key]


## Luftrauschen: 4 s tiefpassgefiltertes Rauschen (Grenze folgt der Blattfolge
## F_REF und wandert über pitch_scale mit der Drehzahl mit). Für alle Motoren gleich.
static func _noise_loop() -> AudioStreamWAV:
	if _cache.has("noise"):
		return _cache["noise"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var a := clampf(F_REF * 6.0 / SAMPLE_RATE, 0.005, 0.9)
	var noise := PackedFloat32Array()
	noise.resize(NOISE_FRAMES)
	for i in NOISE_FRAMES: noise[i] = rng.randf_range(-1.0, 1.0)
	# Filter vorab einschwingen (Ende der Schleife), damit die Nahtstelle nicht springt
	var lp := 0.0
	for i in range(NOISE_FRAMES - 4000, NOISE_FRAMES):
		lp += (noise[i] - lp) * a
	var raw := PackedFloat32Array()
	raw.resize(NOISE_FRAMES)
	for i in NOISE_FRAMES:
		lp += (noise[i] - lp) * a
		raw[i] = lp
	_cache["noise"] = _to_wav(raw, "noise")
	return _cache["noise"]


## Als 16-Bit-Mono-Schleife speichern (auf ±0,9 normiert). Der Faktor zurück auf
## die ursprüngliche Lautstärke steht in _cache[key + "_g"].
static func _to_wav(raw: PackedFloat32Array, key: String) -> AudioStreamWAV:
	var peak := 0.0
	for v in raw: peak = maxf(peak, absf(v))
	var n := raw.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var norm := 0.9 / maxf(peak, 1e-6)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(raw[i] * norm, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	_cache[key + "_g"] = peak / 0.9
	return wav
