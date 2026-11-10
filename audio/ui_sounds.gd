# 2026-11-11 16:30 – Umbau: Werkstatt-Musik (Gitarre, Datei audio/werkstatt_gitarre.ogg, Schleife) mit weichem Ein-/Ausblenden statt Klangteppich; Glockentöne entfernt (Bedientöne aus; ein leiser Klick ist vorbereitet, CLICK_ON)
# 2026-11-09 13:50 – Ohne Ton (im Flug fast immer) Stille in einem Aufruf statt Abtastwert für Abtastwert – entlastet besonders die Browser-Version
# 2026-10-27 11:08 – Erstversion: ruhige Klänge für den Baukasten (sanfte Glockentöne bei Aktionen, sehr leiser Klangteppich), prozedural erzeugt; im Flug still
# =============================================================================
# UISounds.gd
# -----------------------------------------------------------------------------
#   set_music(on)  Werkstatt-Musik ein-/ausblenden (Bus „Musik“). An auf
#                  Startseite, Modell & Bau, Baukasten, Grundlagen; im Flug aus.
#   chime(kind)    leiser Bedienklick (Bus „Klick“), Name bleibt für die
#                  vorhandenen Signale; kind wird nicht mehr unterschieden
#   set_pad(on)    alter Name für set_music (Baukasten)
# =============================================================================
class_name UISounds
extends Node

const MUSIC := "res://audio/werkstatt_gitarre.ogg"
const MUSIC_DB := -6.0             ## Grundlautstärke der Musik (Feinregelung über den Bus)
const FADE_S := 1.5                ## Ein-/Ausblendzeit
const CLICK_GAP := 0.25            ## Mindestabstand zwischen zwei Klicks (s)
## Bedientöne ganz aus (Glockentöne entfernt, Klick nur bei Bedarf wieder einschalten)
const CLICK_ON := false

var _music := AudioStreamPlayer.new()
var _click := AudioStreamPlayer.new()
var _want := false                 ## Musik soll laufen
var _gain := 0.0                   ## aktuelle Blende 0…1
var _last_click := -10.0


func _ready() -> void:
	AppSettings.load_all()
	var st = load(MUSIC)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	_music.stream = st
	_music.bus = "Musik"
	_music.volume_db = -80.0
	add_child(_music)
	_click.stream = _make_click()
	_click.bus = "Klick"
	_click.volume_db = -22.0
	add_child(_click)


func set_music(on: bool) -> void:
	_want = on
	if on and not _music.playing and _music.stream:
		_music.play()


func set_pad(on: bool) -> void:
	set_music(on)


func chime(_kind: String = "") -> void:
	if not CLICK_ON:
		return                                       # Bedientöne aus (Wunsch Nutzer 10.11.2026)
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_click < CLICK_GAP:
		return
	_last_click = now
	_click.play()


func _process(dt: float) -> void:
	_gain = move_toward(_gain, 1.0 if _want else 0.0, dt / FADE_S)
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(_gain, 0.0001))
	if _gain <= 0.0 and _music.playing and not _want:
		_music.stop()                              # ganz aus: nichts mehr abspielen


## Kurzer, weicher Holzklick (12 ms, gedämpfter Sinus mit etwas Rauschen).
static func _make_click() -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * 0.03)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in n:
		var t := float(i) / sr
		var v := (sin(TAU * 1300.0 * t) * 0.7 + rng.randf_range(-1, 1) * 0.15) * exp(-t * 260.0) * minf(1.0, t / 0.0015)
		data.encode_s16(i * 2, int(clampf(v, -1, 1) * 30000))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = sr
	w.data = data
	return w
