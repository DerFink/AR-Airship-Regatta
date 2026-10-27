# 2026-10-27 11:08 – Erstversion: ruhige Klänge für den Baukasten (sanfte Glockentöne bei Aktionen, sehr leiser Klangteppich), prozedural erzeugt; im Flug still
# =============================================================================
# UISounds.gd
# -----------------------------------------------------------------------------
# Ruhige Töne für den Baukasten – ebenfalls ohne Sounddateien:
#   chime(kind)   sanfter Glockenton (Sinus mit langem Ausklang) aus einer
#                 Pentatonik, damit jede Tonfolge harmonisch klingt
#   set_pad(on)   sehr leiser, langsam atmender Klangteppich (Quinte C–G),
#                 nur solange der Baukasten offen ist
# Im Flugmodus bleibt alles still – dort hört man nur die Motoren.
# Lautstärken stehen oben als Konstanten und lassen sich leicht anpassen.
# =============================================================================
class_name UISounds
extends AudioStreamPlayer

const SAMPLE_RATE := 22050.0
const CHIME_VOLUME := 0.18
const PAD_VOLUME := 0.035
## Pentatonik (C-Dur): klingt in jeder Reihenfolge ruhig
const NOTES := {
	"add": 659.3,      # e''  Bauteil hinzugefügt
	"select": 523.3,   # c''  Auswahl
	"remove": 392.0,   # g'   entfernt
	"ok": 784.0,       # g''  gespeichert / geladen
	"warn": 440.0,     # a'   Hinweis (z. B. instabil)
}

var _playback: AudioStreamGeneratorPlayback
var _voices: Array = []            ## [Frequenz, Phase, Amplitude]
var _pad_on := false
var _pad_gain := 0.0
var _pad_ph := [0.0, 0.0]
var _lfo := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.1
	stream = gen
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func chime(kind: String) -> void:
	var f: float = NOTES.get(kind, 523.3)
	_voices.append([f, 0.0, CHIME_VOLUME])
	if _voices.size() > 6:
		_voices.pop_front()


func set_pad(on: bool) -> void:
	_pad_on = on


func _process(_dt: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var decay := exp(-1.0 / (SAMPLE_RATE * 0.55))     # ca. 0,55 s Ausklang
	for i in frames:
		var s := 0.0
		for v in _voices:
			v[1] = fposmod(v[1] + v[0] / SAMPLE_RATE, 1.0)
			# Grundton + leiser Oberton wie bei einer weichen Glocke
			s += v[2] * (sin(TAU * v[1]) + 0.2 * sin(2.0 * TAU * v[1]))
			v[2] *= decay
		# Klangteppich weich ein-/ausblenden
		_pad_gain = move_toward(_pad_gain, PAD_VOLUME if _pad_on else 0.0, 1.0 / (SAMPLE_RATE * 2.0))
		if _pad_gain > 0.0001:
			_lfo = fposmod(_lfo + 0.08 / SAMPLE_RATE, 1.0)
			_pad_ph[0] = fposmod(_pad_ph[0] + 130.81 / SAMPLE_RATE, 1.0)
			_pad_ph[1] = fposmod(_pad_ph[1] + 196.0 / SAMPLE_RATE, 1.0)
			var breath := 0.7 + 0.3 * sin(TAU * _lfo)
			s += _pad_gain * breath * (sin(TAU * _pad_ph[0]) + 0.7 * sin(TAU * _pad_ph[1]))
		_playback.push_frame(Vector2(s, s))
	# Verklungene Stimmen entfernen
	_voices = _voices.filter(func(v): return v[2] > 0.0005)
