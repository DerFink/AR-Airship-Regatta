# 2026-11-17 21:55 – Karte „Bestenliste“ nennt die Aufnahme (● oben rechts, Browser)
# 2026-11-17 09:55 – Karten im Flug oben (unten liegen die Knüppel), Signal step_changed für die pulsierende Acht
# 2026-11-17 09:30 – Erstversion: Tutorial „Erste Schritte“ nach freigegebenem Entwurf 3 – 6 Karten über der echten Oberfläche, gemeinter Bereich leuchtet gelb, Vorlesen über die Sprachausgabe des Geräts
# =============================================================================
# Tutorial.gd  (liegt ganz oben über allen Ansichten)
# -----------------------------------------------------------------------------
#   ┌ 2 · Mit Fernbedienung ──────────────────────── [🔈] ┐
#   │ Am besten fliegt es sich mit deinem RC-Sender: …     │
#   │ ●●○○○○              [Zurück] [Überspringen] [Weiter] │
#   └──────────────────────────────────────────────────────┘
# Ablauf: Start über den Knopf „Tutorial“ auf der Startseite (nie von selbst).
# Jede Karte sagt, welche Ansicht sie braucht (Startseite oder Flug) – main.gd
# schaltet um. Der gemeinte Bereich wird mit einem pulsierenden gelben Rahmen
# markiert; die Rechtecke liefern Funktionen aus main.gd (targets). Bei der
# Acht pulsiert stattdessen die Bodenspur selbst (Signal step_changed).
# Während der Flug-Karten kann man weiterfliegen: nur die Karte fängt Klicks,
# alles andere geht durch. Tasten: Enter = Weiter, Esc = Überspringen
# (Leertaste ist im Flug „Armed“).
# Vorlesen: DisplayServer.tts_* = Sprachausgabe des Geräts/Browsers in der
# eingestellten Sprache. Gibt es keine Stimme für die Sprache, bleibt es still.
# Nichts im Tutorial verändert Modell, Einstellungen oder Bestenliste.
# =============================================================================
class_name Tutorial
extends Control

signal view_requested(name: String)      ## "start" oder "fly"
signal finished
signal step_changed(target: String)      ## markierter Bereich der Karte ("" = beendet)

## Die 6 Karten: Titel, Text, benötigte Ansicht, markierter Bereich (Schlüssel in targets)
const STEPS := [
	{"title": "Luftschiff wählen", "text": "Unter „Modell & Bau“ Luftschiff und Ort aussuchen, dann „Fliegen“.", "view": "start", "target": "start_main"},
	{"title": "Mit Fernbedienung", "text": "Am besten fliegt es sich mit deinem RC-Sender: per USB anschließen (Joystick-Modus) und unter „Modell & Bau“ → „Sender kalibrieren“ einrichten.", "view": "start", "target": "start_build"},
	{"title": "Fliegender Start", "text": "Gas geben und an Pylon 1 vorbeifliegen – die Zeit startet von selbst.", "view": "fly", "target": "race_hint"},
	{"title": "Die Acht fliegen", "text": "Folge der orangen Acht in Pfeilrichtung um beide Pylone. Gelb zeigt, wohin es weitergeht.", "view": "fly", "target": "eight"},
	{"title": "Bestenliste", "text": "Nach 3 Runden Namen eintragen. Kleine Luftschiffe bekommen einen Zeitbonus. Im Browser kannst du den Flug mit ● oben rechts als Film aufnehmen und danach zuschneiden.", "view": "fly", "target": "race_panel"},
	{"title": "Selbst bauen", "text": "Unter „Modell & Bau“ → „Eigenbau“ eigene Luftschiffe bauen und mit „Teilen“ weitergeben.", "view": "start", "target": "start_build"},
]
const COLOR_HL := Color("ffb000")         ## Rahmenfarbe der Markierung
const CARD_W := 560.0                     ## Kartenbreite (auf dem Handy schmaler)

## Markierte Bereiche: Schlüssel → Callable, die ein Array aus Rect2 (Bildschirm) liefert
var targets: Dictionary = {}

var _step := 0
var _card: PanelContainer
var _title: Label
var _text: Label
var _dots: Label
var _b_back: Button
var _b_skip: Button
var _b_next: Button
var _b_voice: Button
var _rects: Array = []                    ## aktuell markierte Rechtecke
var _t := 0.0                             ## Zeit fürs Pulsieren


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE       # Klicks gehen durch (Fliegen nebenher)
	visible = false
	# --- Karte ---
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.08, 0.11, 0.15, 0.96), Color(1, 1, 1, 0.16), 14, UITheme.space("md")))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var v := UITheme.make_vbox("sm")
	_card.add_child(v)
	# Kopf: Titel + Lautsprecher
	var head := UITheme.make_hbox("sm")
	_title = UITheme.make_title("")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(_title)
	_b_voice = UITheme.make_button("")
	_b_voice.tooltip_text = I18n.t("Vorlesen an/aus")
	_b_voice.add_theme_constant_override("icon_max_width", 24)
	_b_voice.pressed.connect(_toggle_voice)
	head.add_child(_b_voice)
	v.add_child(head)
	# Text
	_text = UITheme.make_label("")
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_text)
	# Fuß: Punkte + Knöpfe
	var foot := UITheme.make_hbox("sm")
	_dots = UITheme.make_label("")
	_dots.add_theme_color_override("font_color", COLOR_HL)
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(_dots)
	_b_back = UITheme.make_button("Zurück")
	_b_back.pressed.connect(func(): _go(_step - 1))
	_b_skip = UITheme.make_button("Überspringen")
	_b_skip.pressed.connect(stop)
	_b_next = UITheme.make_primary_button("Weiter")
	_b_next.pressed.connect(func(): _go(_step + 1))
	for b in [_b_back, _b_skip, _b_next]: foot.add_child(b)
	v.add_child(foot)
	resized.connect(_layout)


## Tutorial von vorn starten (Knopf „Tutorial“ auf der Startseite).
func start() -> void:
	visible = true
	_go(0)


## Tutorial beenden (Überspringen, Schließen, Esc) – zurück auf die Startseite.
func stop() -> void:
	_tts_stop()
	visible = false
	_rects = []
	queue_redraw()
	step_changed.emit("")
	view_requested.emit("start")
	finished.emit()


## Zu Karte i wechseln (nach der letzten: beenden).
func _go(i: int) -> void:
	if i >= STEPS.size():
		stop()
		return
	_step = clampi(i, 0, STEPS.size() - 1)
	var s: Dictionary = STEPS[_step]
	view_requested.emit(s.view)
	step_changed.emit(s.target)
	_title.text = "%d · %s" % [_step + 1, I18n.t(s.title)]
	_text.text = I18n.t(s.text)
	var dots := ""
	for k in STEPS.size():
		dots += "●" if k <= _step else "○"
	_dots.text = dots
	_b_back.visible = _step > 0
	var last := _step == STEPS.size() - 1
	_b_skip.text = I18n.t("Schließen") if last else I18n.t("Überspringen")
	_b_next.text = I18n.t("Los geht’s") if last else I18n.t("Weiter")
	_update_voice_icon()
	_layout.call_deferred()
	if AppSettings.tut_voice:
		_speak()


## Karte setzen: Startseite rechts neben dem Menü, im Flug unten in der Mitte.
func _layout() -> void:
	if not visible: return
	var vp := size
	var w := minf(CARD_W, vp.x - 32.0)
	_card.custom_minimum_size = Vector2(w, 0)
	_card.size = Vector2(w, 0)                       # Höhe aus dem Inhalt
	var h := _card.get_combined_minimum_size().y
	var s: Dictionary = STEPS[_step]
	if s.view == "start" and vp.x >= 900.0:
		_card.position = Vector2(vp.x * 0.42, vp.y * 0.36)
		_card.position.x = minf(_card.position.x, vp.x - w - 16.0)
	elif s.view == "start":
		_card.position = Vector2((vp.x - w) * 0.5, vp.y - h - 24.0)
	else:
		# Flug: oben in der Mitte unter der Knopfreihe – unten liegen die Knüppel
		_card.position = Vector2((vp.x - w) * 0.5, 150.0)
	_card.size = Vector2(w, h)


func _process(dt: float) -> void:
	if not visible: return
	_t += dt
	# markierte Bereiche jedes Bild neu holen (Kamera bewegt sich, Fenster ändert Größe)
	var key: String = STEPS[_step].target
	_rects = targets[key].call() if targets.has(key) and (targets[key] as Callable).is_valid() else []
	queue_redraw()


## Gelber, pulsierender Rahmen um jeden markierten Bereich.
func _draw() -> void:
	var a := 0.55 + 0.45 * sin(_t * 5.0)
	for r in _rects:
		var rr: Rect2 = (r as Rect2).grow(6.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.draw_center = false
		sb.border_color = Color(COLOR_HL, a)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		sb.shadow_color = Color(COLOR_HL, 0.35 * a)
		sb.shadow_size = 10
		draw_style_box(sb, rr)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_go(_step + 1)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			stop()
			get_viewport().set_input_as_handled()


# =============================================================================
# Vorlesen (Sprachausgabe des Geräts bzw. Browsers)
# =============================================================================
func _toggle_voice() -> void:
	AppSettings.tut_voice = not AppSettings.tut_voice
	AppSettings.save()
	_update_voice_icon()
	if AppSettings.tut_voice: _speak()
	else: _tts_stop()


func _update_voice_icon() -> void:
	_b_voice.icon = load("res://textures/lautsprecher.svg" if AppSettings.tut_voice else "res://textures/lautsprecher_aus.svg")


## Stimme für die eingestellte Sprache (leer = keine vorhanden).
static func _voice_for(lang: String) -> String:
	var code := lang.split("_")[0]                    # zh_TW → zh
	var voices := DisplayServer.tts_get_voices_for_language(code)
	if lang == "zh_TW":                               # Taiwan/Hongkong bevorzugen
		for vid in voices:
			if "TW" in vid or "HK" in vid or "Hant" in vid: return vid
	return voices[0] if voices.size() > 0 else ""


func _speak() -> void:
	_tts_stop()
	var voice := _voice_for(I18n.current)
	if voice == "":
		return                                       # keine Stimme auf diesem Gerät: still
	var s: Dictionary = STEPS[_step]
	DisplayServer.tts_speak(I18n.t(s.title) + ". " + I18n.t(s.text).replace("→", ","), voice, 80)


func _tts_stop() -> void:
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
