# 2026-11-14 22:00 – Erstversion: Einwilligung vor dem ersten Online-Eintrag (Text wie abgestimmt, Link Datenschutz, „Einverstanden, online eintragen“ / „Nur auf diesem Gerät“)
# =============================================================================
# ConsentDialog.gd
# -----------------------------------------------------------------------------
#   ┌────────────────────────────────────────────┐
#   │ Online-Bestenliste                         │
#   │ Deine Zeit online eintragen? Gespeichert … │
#   │ Datenschutzerklärung ↗                     │
#   │ [Einverstanden, online eintragen]          │
#   │ [Nur auf diesem Gerät]                     │
#   └────────────────────────────────────────────┘
# Erscheint, wenn eine Zeit eingetragen wird und noch keine Einwilligung in
# der aktuellen Fassung (LeaderboardOnline.CONSENT_VERSION) vorliegt.
#   Einverstanden → Fassung merken, Zeit online eintragen
#   Nur Gerät     → Online-Eintragen aus (in den Einstellungen wieder einschaltbar)
# Fliegen und die Bestenliste auf dem Gerät gehen immer – auch ohne Zustimmung.
# =============================================================================
class_name ConsentDialog
extends Control

## true = eingewilligt, false = nur auf dem Gerät
signal decided(accepted: bool)

var _panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = UITheme.make_panel(520)
	add_child(_panel)
	var v := UITheme.make_vbox("md")
	_panel.add_child(v)
	v.add_child(UITheme.make_title("Online-Bestenliste"))
	var t := UITheme.make_label(I18n.t(LeaderboardOnline.CONSENT_TEXT))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = 480
	v.add_child(t)
	# Link zur Datenschutzerklärung (öffnet den Browser)
	var link := UITheme.make_button("Datenschutzerklärung ↗")
	link.flat = true
	link.alignment = HORIZONTAL_ALIGNMENT_LEFT
	link.add_theme_color_override("font_color", UITheme.color("accent"))
	link.pressed.connect(func(): OS.shell_open(LeaderboardOnline.DATENSCHUTZ_URL))
	v.add_child(link)
	var yes := UITheme.make_primary_button(I18n.t("Einverstanden, online eintragen"))
	yes.pressed.connect(func(): _decide(true))
	v.add_child(yes)
	var no := UITheme.make_button("Nur auf diesem Gerät")
	no.pressed.connect(func(): _decide(false))
	v.add_child(no)
	v.add_child(UITheme.make_label("Du kannst das jederzeit in den Einstellungen ändern und deine Online-Einträge dort löschen.", "MutedLabel"))
	(v.get_child(v.get_child_count() - 1) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resized.connect(_layout)


func open() -> void:
	visible = true
	_layout.call_deferred()


## Entscheidung speichern und melden.
func _decide(accepted: bool) -> void:
	if accepted:
		AppSettings.online_consent = LeaderboardOnline.CONSENT_VERSION
		AppSettings.online_on = true
	else:
		AppSettings.online_consent = 0
		AppSettings.online_on = false
	AppSettings.save()
	visible = false
	decided.emit(accepted)


## Mittig, auf kleinen Bildschirmen verkleinert.
func _layout() -> void:
	if not visible:
		return
	_panel.size = _panel.get_combined_minimum_size()
	var k := minf(1.0, minf((size.x - 16.0) / _panel.size.x, (size.y - 16.0) / _panel.size.y))
	_panel.scale = Vector2(k, k)
	_panel.position = (size - _panel.size * k) * 0.5
