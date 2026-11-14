# 2026-11-14 22:15 – PayPal: eigener Link paypal.me/LuftschiffFink statt Spenden-Link mit E-Mail
# 2026-11-11 17:40 – Erstversion: Fenster „Support“ – QR-Code für PayPal, Adresse, Knopf „PayPal öffnen“
# =============================================================================
# SupportPopup.gd
# -----------------------------------------------------------------------------
#   ┌──────────────────────────────┐
#   │ Support                      │
#   │ Dir gefällt der Simulator? … │
#   │        ┌──────────┐          │
#   │        │ QR-Code  │          │   textures/support_qr.png (tools/make_support_qr.py)
#   │        └──────────┘          │
#   │  paypal.me/LuftschiffFink    │
#   │ [PayPal öffnen] [Schließen]  │
#   └──────────────────────────────┘
# Wird der Link geändert (z. B. eigener paypal.me-Link), danach
# python3 tools/make_support_qr.py ausführen.
# =============================================================================
class_name SupportPopup
extends Control

## PayPal-Link (paypal.me des Betreibers). Bei Änderung den QR-Code neu
## erzeugen: python3 tools/make_support_qr.py
const SUPPORT_URL := "https://paypal.me/LuftschiffFink"
const SUPPORT_NAME := "paypal.me/LuftschiffFink"

var _panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	# halbdunkler Hintergrund; Tippen daneben schließt
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: visible = false)
	add_child(bg)
	_panel = UITheme.make_panel(380)
	add_child(_panel)
	var v := UITheme.make_vbox("sm")
	_panel.add_child(v)
	v.add_child(UITheme.make_title("Support"))
	var t := UITheme.make_label("Dir gefällt der Simulator? Spendier mir ein Bier – per PayPal:", "MutedLabel")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = 340
	v.add_child(t)
	var qr := TextureRect.new()
	qr.texture = load("res://textures/support_qr.png")
	qr.custom_minimum_size = Vector2(230, 230)
	qr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	qr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	qr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST    # scharfe Kanten
	v.add_child(qr)
	var name_l := UITheme.make_label(SUPPORT_NAME)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_l)
	var row := UITheme.make_hbox("sm")
	var b_open := UITheme.make_button("PayPal öffnen")
	b_open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_open.pressed.connect(func(): OS.shell_open(SUPPORT_URL))
	var b_close := UITheme.make_button("Schließen")
	b_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_close.pressed.connect(func(): visible = false)
	row.add_child(b_open)
	row.add_child(b_close)
	v.add_child(row)
	resized.connect(_layout)
	visibility_changed.connect(_layout)


func open() -> void:
	visible = true
	_layout.call_deferred()


func _layout() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	var k := minf(1.0, minf((size.x - 16.0) / _panel.size.x, (size.y - 16.0) / _panel.size.y))
	_panel.scale = Vector2(k, k)
	_panel.position = (size - _panel.size * k) * 0.5
