# 2026-11-09 10:00 – Menüpunkt „Demo-Flug“
# 2026-11-08 18:00 – Zeile „Sender“ im Menü: verbundenes Gerät (grün) oder „Kein Sender – Bildschirmknüppel“
# 2026-11-07 21:10 – Erstversion: Menü in der Flugansicht nach freigegebenem Entwurf (zweispaltig: Modell wählen, Bau, Strecke, Bestenliste, PID / Flugcontroller, AR, Zurücksetzen; Fußzeile mit Version und „Nach Update suchen“)
# =============================================================================
# MainMenu.gd
# -----------------------------------------------------------------------------
# Öffnet sich über dem Flugbild (der Flug läuft weiter). Antippen außerhalb
# des Menüs schließt es.
#
#   ┌──────────────────────────────────────────────┐
#   │ [Modell wählen   Chewie] [Bau              ] │
#   │ [Strecke  FN Hugo …    ] [Bestenliste      ] │
#   │ [PID / Flugcontroller  ] [AR            aus] │
#   │ [Zurücksetzen (Start)  ]                     │
#   │ Version 0.9.7 (Build 32)  [Nach Update suchen]│
#   └──────────────────────────────────────────────┘
#
# Jeder Eintrag schließt das Menü und meldet sich per Signal; die Flugansicht
# (FlightHUD) reicht die Signale an main.gd weiter.
# =============================================================================
class_name MainMenu
extends Control

signal model_requested
signal builder_requested
signal course_requested
signal leaderboard_requested
signal pid_requested
signal ar_requested
signal reset_requested
signal demo_requested
signal closed

## Liefert die Zusatzangaben rechts in den Einträgen (Modellname, Strecke, AR).
## Wird von der Flugansicht gesetzt: func() -> {"model": …, "course": …, "ar": bool}
var info_source: Callable

var _panel: PanelContainer
var _grid: GridContainer
var _ver: Label
var _dev: Label                   ## Zeile „Sender: …“ bzw. „Kein Sender – Bildschirmknüppel“
var _status: Label
var _btn_update: Button
var _updater: Updater


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP          # Tippen außerhalb fängt das Menü ab
	# Abgedunkelter Hintergrund – Antippen schließt das Menü
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			hide_menu())
	add_child(bg)

	_panel = UITheme.make_panel(440)
	add_child(_panel)
	var box := UITheme.make_vbox("sm")
	_panel.add_child(box)
	# Zwei Spalten, damit das Menü auf dem Handy in die Höhe passt
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", UITheme.space("sm"))
	_grid.add_theme_constant_override("v_separation", UITheme.space("sm"))
	box.add_child(_grid)

	# Zeile „Sender“: welches Gerät steuert (Taranis per USB) oder Bildschirmknüppel
	_dev = UITheme.make_label("", "MutedLabel")
	_dev.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dev.custom_minimum_size.x = 400
	box.add_child(_dev)

	# Fußzeile: Version und Update-Suche
	var foot := UITheme.make_hbox("sm")
	_ver = UITheme.make_label(BuildInfo.text(), "MutedLabel")
	_ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_ver)
	_btn_update = UITheme.make_button("Nach Update suchen")
	_btn_update.pressed.connect(_on_update_pressed)
	foot.add_child(_btn_update)
	box.add_child(foot)
	# Ergebnis der Update-Suche (leer, solange nicht gesucht wurde)
	_status = UITheme.make_label("", "MutedLabel")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 400
	_status.visible = false
	box.add_child(_status)

	_updater = Updater.new()
	add_child(_updater)
	_updater.status.connect(_on_update_status)

	resized.connect(_layout)
	visible = false


## Menü öffnen: Einträge mit aktuellen Angaben neu aufbauen.
func show_menu() -> void:
	_fill()
	_status.visible = _status.text != ""
	visible = true
	_layout.call_deferred()


func hide_menu() -> void:
	if visible:
		visible = false
		closed.emit()


# Einträge aufbauen. Rechts im Knopf steht die Zusatzangabe (gedämpft).
func _fill() -> void:
	for c in _grid.get_children(): c.queue_free()
	var info: Dictionary = info_source.call() if info_source.is_valid() else {}
	var joy: String = info.get("joy", "")
	if joy != "":
		_dev.text = "● Sender: %s    SF oben = scharf · SC = Modus · SH = Zurücksetzen" % joy
		_dev.modulate = Color(0.55, 0.9, 0.65)          # grün = verbunden
	else:
		_dev.text = "Kein Sender – Bildschirmknüppel"
		_dev.modulate = Color(1, 1, 1)
	_add("Modell wählen", info.get("model", ""), model_requested)
	_add("Bau", "", builder_requested)
	_add("Strecke", info.get("course", ""), course_requested)
	_add("Bestenliste", "", leaderboard_requested)
	_add("PID / Flugcontroller", "", pid_requested)
	_add("AR", "an" if info.get("ar", false) else "aus", ar_requested)
	_add("Zurücksetzen (an den Start)", "", reset_requested)
	_add("Demo-Flug", "Chewie, schnellste Runde", demo_requested)


## Ein Menüeintrag: Text links, Zusatzangabe rechts; Tippen schließt das Menü
## und sendet das Signal.
func _add(text: String, extra: String, sig: Signal) -> void:
	var b := UITheme.make_button(text)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.x = 210
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if extra != "":
		var l := UITheme.make_label(extra, "MutedLabel")
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.position.x -= UITheme.space("md")
		l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		l.clip_text = true
		l.custom_minimum_size.x = 0
		b.add_child(l)
	b.pressed.connect(func():
		hide_menu()
		sig.emit())
	_grid.add_child(b)


func _on_update_pressed() -> void:
	_btn_update.disabled = true
	_updater.check()


## Meldungen der Update-Suche anzeigen.
## done = Suche beendet (Knopf wieder freigeben).
func _on_update_status(text: String, done: bool) -> void:
	_status.text = text
	_status.visible = text != ""
	if done:
		_btn_update.disabled = false
	_layout.call_deferred()


## Menü oben rechts unter dem Menü-Knopf platzieren.
func _layout() -> void:
	var m := float(UITheme.space("lg"))
	_panel.size = _panel.get_combined_minimum_size()
	var top := m + UITheme.size("control_height") + m * 0.5
	_panel.position = Vector2(size.x - _panel.size.x - m, minf(top, maxf(0.0, size.y - _panel.size.y - m)))
