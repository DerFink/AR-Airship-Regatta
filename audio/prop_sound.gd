# 2026-10-27 11:08 – Erstversion: prozedurales Propellergeräusch (Quadcopter-Klang) je Motor, abhängig von Propellergröße, Blattzahl, Drehzahl und Drehrichtung; räumlich am Motor; ohne Drehzahl absolute Stille
# =============================================================================
# PropSound.gd  (ein Knoten je Motor, sitzt an der Motorposition)
# -----------------------------------------------------------------------------
# Erzeugt den Klang in Echtzeit – keine Sounddateien, also lizenzfrei.
#
# Woraus sich der typische Quadcopter-Klang zusammensetzt:
#   1. Blattfolge-Ton: jedes Blatt "schlägt" einmal pro Umdrehung durch die
#      Luft → Grundton f = Drehzahl/60 · Blattzahl, plus Obertöne (Summen).
#   2. Motor-Pfeifen: der Elektromotor schaltet 7× pro Umdrehung um
#      (14 Magnetpole) → leiser, hoher Ton.
#   3. Rauschen: verwirbelte Luft, tiefpassgefiltert, je nach Drehzahl heller.
#   4. Schwebung: zwei gegenläufige Motoren drehen nie exakt gleich schnell –
#      die Drehrichtung verstimmt den Ton minimal, das erzeugt das bekannte
#      "Wabern" eines Multikopters.
#
# Größere Propeller drehen langsamer (tieferer Ton) und sind lauter.
# Rückwärts laufend arbeitet der Propeller gegen sein Profil: mehr Rauschen,
# leichtes Flattern.
# =============================================================================
class_name PropSound
extends AudioStreamPlayer3D

const SAMPLE_RATE := 22050.0       ## reicht für den Klang, schont das Handy
const POLE_PAIRS := 7.0            ## typischer Außenläufer (14 Pole)

var motor: VectorMotor
var _playback: AudioStreamGeneratorPlayback
var _rpm := 0.0                    ## geglättete Drehzahl (vermeidet Knackser)
var _ph_blade := 0.0
var _ph_motor := 0.0
var _noise_lp := 0.0
var _rng := RandomNumberGenerator.new()


func setup(m: VectorMotor) -> void:
	motor = m


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.12
	stream = gen
	# Größere Propeller sind weiter hörbar
	unit_size = 2.0 + motor.prop_diameter_in * 0.4
	max_db = 3.0
	attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_rng.seed = hash(motor.display_name)
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_dt: float) -> void:
	if _playback == null or motor == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return

	var target := motor.rpm()
	var rev := motor.is_reversing()
	# Lautstärke: steigt mit Drehzahl (≈ Leistung) und Propellergröße
	var size_gain := clampf(pow(motor.prop_diameter_in / 5.0, 1.2), 0.4, 3.0) * 0.45
	var detune := 1.0 + 0.012 * float(motor.spin_dir)   # Schwebung zwischen den Motoren
	var noise_share := 0.6 if rev else 0.35

	for i in frames:
		# Drehzahl weich nachführen (Propeller hat Trägheit)
		_rpm += (target - _rpm) * 0.0015
		if _rpm < 30.0:
			_playback.push_frame(Vector2.ZERO)          # Stillstand = Stille
			continue
		var rev_s := _rpm / 60.0
		var f_blade := rev_s * float(motor.prop_blades) * detune
		var f_motor := rev_s * POLE_PAIRS * detune
		_ph_blade = fposmod(_ph_blade + f_blade / SAMPLE_RATE, 1.0)
		_ph_motor = fposmod(_ph_motor + f_motor / SAMPLE_RATE, 1.0)
		var p := TAU * _ph_blade
		# 1) Blattfolge-Ton mit abnehmenden Obertönen
		var tone := sin(p) + 0.5 * sin(2.0 * p) + 0.25 * sin(3.0 * p) + 0.12 * sin(4.0 * p)
		# 2) leises Motor-Pfeifen
		tone += 0.08 * sin(TAU * _ph_motor)
		# 3) Luftrauschen, Tiefpass folgt der Drehzahl
		var a := clampf(f_blade * 6.0 / SAMPLE_RATE, 0.02, 0.9)
		_noise_lp += (_rng.randf_range(-1.0, 1.0) - _noise_lp) * a
		var s := tone * (1.0 - noise_share) * 0.5 + _noise_lp * noise_share * 2.0
		# Rückwärts: leichtes Flattern (Strömung reißt am Profil ab)
		if rev:
			s *= 1.0 + 0.3 * sin(PI * _ph_blade)
		var level := pow(_rpm / motor.max_rpm, 1.5) * size_gain
		s = clampf(s * level, -1.0, 1.0)
		_playback.push_frame(Vector2(s, s))
