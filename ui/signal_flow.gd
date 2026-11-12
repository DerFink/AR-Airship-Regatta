# 2026-11-13 01:40 – Erstversion: interaktiver Signalfluss nach freigegebenem Entwurf – Flugmodus wählen, Impuls auf Nick, Seite oder Roll geben; der Weg vom Knüppel über Regler, Rollausgleich und Mischer bis zu jedem Ruder und Schwenker leuchtet farbig auf (grün = +, orange = −, Breite = Stärke)
# =============================================================================
# SignalFlow.gd
# -----------------------------------------------------------------------------
#   Modus [Direkt][Angle]…   Impuls [Nick][Seite][Roll]              [Schließen]
#
#   ┌ Knüppel Seite ┐══▶┌ PID Gier (Drehrate) ┐══▶┌ Rollausgleich ┐══▶┌ Mischer ┐══▶ LTW oben +100 %
#   ┌ Knüppel Nick  ┐──▶┌ PID Nick (Lage)     ┐─────────────────────▶│         │──▶ LTW unten r. −50 %
#   ┌ Knüppel Roll  ┐──▶┌ Roll direkt         ┐─────────────────────▶└─────────┘──▶ Schwenker …
#
# Die Werte rechts kommen aus FlightController.probe_outputs(): ein Reglerschritt
# mit dem Impuls (voller Knüppel) in der aktuellen Fluglage, ohne etwas zu
# verändern. Gas läuft nie durch den Regler (bleibt beim Piloten).
# =============================================================================
class_name SignalFlow
extends VBoxContainer

signal closed

var fc: FlightController
var _mode := 0                       ## Index in fc.modes
var _fn := "yaw"                     ## Impuls: "pitch" / "yaw" / "roll"
var _canvas: Control
var _out := {}                       ## Ausgang → Stellbefehl (−1…1)

const C_ON := Color("3ccf7a")        ## positiv
const C_NEG := Color("ff8c1a")       ## negativ
const C_OFF := Color("4a5260")
const C_BOX := Color("20252d")
const C_BOX_ON := Color("253552")
const C_BORDER_ON := Color("3d8bfd")


func _ready() -> void:
	_mode = fc.mode_index
	add_theme_constant_override("separation", UITheme.space("sm"))
	var head := UITheme.make_hbox("sm")
	head.add_child(UITheme.make_title("Signalfluss"))
	head.add_child(UITheme.make_label("Modus", "MutedLabel"))
	var mg := UITheme.make_toggle_group()
	for i in fc.modes.size():
		var b := UITheme.make_button(str(fc.modes[i].get("name", "")), true)
		b.button_group = mg
		b.button_pressed = i == _mode
		var idx := i
		b.pressed.connect(func(): _mode = idx; _update())
		head.add_child(b)
	head.add_child(UITheme.make_label("Impuls", "MutedLabel"))
	var ig := UITheme.make_toggle_group()
	for f in [["Nick", "pitch"], ["Seite", "yaw"], ["Roll", "roll"]]:
		var b := UITheme.make_button(f[0], true)
		b.button_group = ig
		b.button_pressed = f[1] == _fn
		var fn: String = f[1]
		b.pressed.connect(func(): _fn = fn; _update())
		head.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UITheme.make_label("grün = +, orange = −", "MutedLabel"))
	var close := UITheme.make_primary_button(tr("Schließen"))
	close.pressed.connect(func(): closed.emit())
	head.add_child(close)
	add_child(head)
	_canvas = Control.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.custom_minimum_size = Vector2(600, 320)
	_canvas.draw.connect(_draw_flow)
	add_child(_canvas)
	_update()


func _update() -> void:
	_out = fc.probe_outputs(_mode, _fn, 1.0)
	_canvas.queue_redraw()


## Text des Reglerkastens je Achse im gewählten Modus.
func _proc_text(k: String) -> Array:
	var m: Dictionary = fc.modes[_mode]
	var art := str(m.get("art", "direkt"))
	var teensy: bool = fc.airship.fc_teensy
	if art == "direkt" or not teensy:
		return [I18n.t("direkt"), false]
	if art == "angle" or art == "horizon":
		match k:
			"pitch": return [I18n.t("PID Nick (Lage)"), true]
			"roll": return [I18n.t("PID Roll hält 0°"), true]
			"yaw": return [I18n.t("PID Gier (Drehrate)") if art == "horizon" else I18n.t("Gier direkt"), art == "horizon"]
	var a: Dictionary = (m.get("axes", {}) as Dictionary).get(k, {})
	if not bool(a.get("on", false)):
		return [I18n.t("direkt"), false]
	var nm: String = I18n.t({"pitch": "Nick", "roll": "Roll", "yaw": "Gier"}[k])
	var kind := I18n.t("Lage") if str(a.get("kind", "rate")) == "angle" and k != "yaw" else I18n.t("Drehrate")
	return ["PID %s (%s)" % [nm, kind], true]


func _draw_flow() -> void:
	var c := _canvas
	var font := c.get_theme_default_font()
	var fs := 14
	var w := c.size.x
	var h := c.size.y
	var m: Dictionary = fc.modes[_mode]
	var rc := bool(m.get("roll_comp", false)) and fc.airship.fc_teensy
	var rows := ["yaw", "pitch", "roll"]
	var row_name := {"yaw": "Knüppel Seite", "pitch": "Knüppel Nick", "roll": "Knüppel Roll"}
	var bw := w * 0.15
	var bh := 44.0
	var x_in := 4.0
	var x_pid := w * 0.2
	var x_rc := w * 0.4
	var x_mix := w * 0.58
	var x_out := w * 0.78
	var outs := FlightController.mix_outputs(fc.airship)
	var mix_rect := Rect2(x_mix, h * 0.2, w * 0.1, h * 0.6)
	# --- Eingänge und Regler je Achse ---
	for i in rows.size():
		var k: String = rows[i]
		var y := h * (0.18 + 0.3 * i)
		var active := k == _fn
		var col := C_ON if active else C_OFF
		var thick := 6.0 if active else 2.0
		_box(Rect2(x_in, y - bh * 0.5, bw, bh), I18n.t(row_name[k]), active, font, fs)
		var pt: Array = _proc_text(k)
		_box(Rect2(x_pid, y - bh * 0.5, w * 0.17, bh), pt[0], active, font, fs)
		c.draw_line(Vector2(x_in + bw, y), Vector2(x_pid, y), col, thick, true)
		var x_from := x_pid + w * 0.17
		# Rollausgleich: Nick und Seite laufen durch die Umrechnung
		if rc and k != "roll":
			var yr := h * (0.18 + 0.15)
			if i == 0:
				_box(Rect2(x_rc, yr - bh * 0.5, w * 0.14, bh), I18n.t("Rollausgleich"), active or _fn == "pitch", font, fs)
			c.draw_line(Vector2(x_from, y), Vector2(x_rc, yr), col, thick, true)
			if i == 0:
				var any := _fn == "yaw" or _fn == "pitch"
				c.draw_line(Vector2(x_rc + w * 0.14, yr), Vector2(mix_rect.position.x, yr), C_ON if any else C_OFF, 6.0 if any else 2.0, true)
		else:
			var ym := clampf(y, mix_rect.position.y + 10, mix_rect.end.y - 10)
			c.draw_line(Vector2(x_from, y), Vector2(mix_rect.position.x, ym), col, thick, true)
	# --- Mischer ---
	c.draw_rect(mix_rect, C_BOX_ON)
	c.draw_rect(mix_rect, C_BORDER_ON, false, 2.0)
	_text(I18n.t("Mischer"), mix_rect, font, fs)
	# --- Ausgänge ---
	var n := maxi(outs.size(), 1)
	for j in outs.size():
		var o: Dictionary = outs[j]
		var v: float = _out.get(o.key, 0.0)
		var y := h * (0.06 + 0.88 * (j + 0.5) / n)
		var r := Rect2(x_out, y - 20, w - x_out - 4, 40)
		var on := absf(v) > 0.005
		var colr := (C_ON if v > 0.0 else C_NEG) if on else C_OFF
		c.draw_rect(r, Color(colr, 0.18) if on else C_BOX)
		c.draw_rect(r, colr, false, 2.0)
		_text("%s  %+d %%" % [I18n.t(o.name), roundi(v * 100.0)], r, font, fs - 1)
		var ym := mix_rect.position.y + mix_rect.size.y * (j + 0.5) / n
		c.draw_line(Vector2(mix_rect.end.x, ym), Vector2(x_out, y), colr, 1.5 + 6.0 * absf(v) if on else 1.5, true)
	if outs.is_empty():
		_text(I18n.t("Keine Ruder oder schwenkbaren Motoren vorhanden."), Rect2(x_out, h * 0.4, w - x_out, 40), font, fs)
	# Gas: nie durch den Regler
	c.draw_string(font, Vector2(x_in, h - 8), I18n.t("Gas: direkt vom Piloten auf alle Motoren (nie geregelt)"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.color("text_muted"))


func _box(r: Rect2, txt: String, on: bool, font: Font, fs: int) -> void:
	_canvas.draw_rect(r, C_BOX_ON if on else C_BOX)
	_canvas.draw_rect(r, C_BORDER_ON if on else C_OFF, false, 2.0)
	_text(txt, r, font, fs)


## Text mittig in den Kasten; wird kleiner, wenn er nicht passt.
func _text(txt: String, r: Rect2, font: Font, fs: int) -> void:
	var size := fs
	while size > 9 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > r.size.x - 8:
		size -= 1
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	_canvas.draw_string(font, Vector2(r.position.x + (r.size.x - ts.x) * 0.5, r.position.y + r.size.y * 0.5 + ts.y * 0.3),
		txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("e8eaed"))
