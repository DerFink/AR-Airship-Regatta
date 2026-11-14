# 2026-11-14 11:20 – Versionsnummer unten; 7× tippen zeigt den versteckten Schalter „Testmodelle zeigen“
# 2026-11-12 10:40 – Schalter fürs Platzen entfernt: die Hülle platzt immer ab 20 km/h (Grundregel)
# 2026-11-12 10:05 – Regler „Platzt ab“ entfernt; Schalter heißt „Hülle platzt bei Aufprall ab 20 km/h“
# 2026-11-11 14:40 – Schalter „Hülle platzt bei zu hartem Aufprall“ und Grenzgeschwindigkeit
# 2026-11-11 17:00 – Erstversion: Fenster „Einstellungen“ – Musik und Motorklang an/aus mit Lautstärke, Bodenspur an/aus, Zugang zu Steuerung & Regler
# =============================================================================
# SettingsPanel.gd
# -----------------------------------------------------------------------------
#   ┌ Einstellungen ───────────────────────────── [Schließen] ┐
#   │ Ton                                                      │
#   │  [✓] Musik            ────●──────  70 %                  │
#   │  [✓] Motorklang       ─────────●  100 %                  │
#   │ Anzeige                                                  │
#   │  [✓] Spur (Acht auf dem Boden)                           │
#   │ [Steuerung & Regler …]                                   │
#   └──────────────────────────────────────────────────────────┘
# Alle Werte über AppSettings (sofort wirksam, dauerhaft gespeichert).
# =============================================================================
class_name SettingsPanel
extends Control

signal closed
signal controls_requested          ## Steuerung & Regler (Stick-Mode, alles zurücksetzen)

var _panel: PanelContainer
var _test_toggle: CheckButton       ## versteckter Schalter „Testmodelle zeigen“
var _taps := 0                        ## Tipps auf die Versionsnummer in Folge
var _tap_time := 0                    ## Zeitpunkt des letzten Tipps (ms)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.14, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = UITheme.make_panel(620)
	add_child(_panel)
	var box := UITheme.make_vbox("md")
	_panel.add_child(box)
	var head := UITheme.make_hbox("sm")
	var t := UITheme.make_title("Einstellungen")
	t.add_theme_font_size_override("font_size", 26)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var b_close := UITheme.make_button("Schließen")
	b_close.pressed.connect(func(): AppSettings.save(); closed.emit())
	head.add_child(b_close)
	box.add_child(head)

	box.add_child(UITheme.make_title("Ton"))
	box.add_child(_toggle("Musik", AppSettings.music_on, func(on): AppSettings.music_on = on; AppSettings.save()))
	box.add_child(UITheme.make_slider_row("Lautstärke Musik", 0.0, 100.0, 1.0, AppSettings.music_vol * 100.0,
		func(v): AppSettings.music_vol = v / 100.0; AppSettings.apply(), "%d %%"))
	box.add_child(_toggle("Motorklang", AppSettings.motor_on, func(on): AppSettings.motor_on = on; AppSettings.save()))
	box.add_child(UITheme.make_slider_row("Lautstärke Motoren", 0.0, 100.0, 1.0, AppSettings.motor_vol * 100.0,
		func(v): AppSettings.motor_vol = v / 100.0; AppSettings.apply(), "%d %%"))
	box.add_child(UITheme.make_title("Anzeige"))
	box.add_child(_toggle("Spur auf dem Boden (Acht mit Richtungspfeilen)", AppSettings.track_on,
		func(on): AppSettings.track_on = on; AppSettings.save()))
	box.add_child(UITheme.make_title("Steuerung"))
	var b_ctl := UITheme.make_button("Steuerung & Regler (Knüppel-Mode, alles zurücksetzen) …")
	b_ctl.pressed.connect(func(): AppSettings.save(); controls_requested.emit())
	box.add_child(b_ctl)
	# --- Versionsnummer; 7× tippen schaltet den versteckten Schalter frei ---
	# „Testmodelle zeigen“ (z. B. Chewie27) ist nur für Entwicklung und Vergleich
	# gedacht und erscheint erst nach dem Freischalten (oder wenn er schon an ist).
	_test_toggle = _toggle("Testmodelle zeigen (z. B. Chewie27, nicht für die Bestenliste)",
		AppSettings.show_test_models, func(on): AppSettings.show_test_models = on; AppSettings.save())
	_test_toggle.visible = AppSettings.show_test_models
	box.add_child(_test_toggle)
	var ver := UITheme.make_button(BuildInfo.text())
	ver.flat = true
	ver.add_theme_color_override("font_color", UITheme.color("text_muted"))
	ver.pressed.connect(_on_version_tap)
	box.add_child(ver)
	resized.connect(_layout)
	_layout.call_deferred()


func _toggle(text: String, on: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = on
	c.toggled.connect(cb)
	return c


func _layout() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = (size - _panel.size) * 0.5


## Tipp auf die Versionsnummer: 7 Tipps (Abstand je unter 1,5 s) zeigen den
## Schalter „Testmodelle zeigen“.
func _on_version_tap() -> void:
	var now := Time.get_ticks_msec()
	_taps = _taps + 1 if now - _tap_time < 1500 else 1
	_tap_time = now
	if _taps >= 7 and not _test_toggle.visible:
		_test_toggle.visible = true
		_layout.call_deferred()
