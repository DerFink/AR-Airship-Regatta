# 2026-11-11 11:50 – Erstversion: Signalflussbild des Reglers – wird aus den eingeschalteten Bausteinen und dem Aufbau des Modells (Flossen, Motoren) automatisch gezeichnet
# =============================================================================
# FlowDiagram.gd
# -----------------------------------------------------------------------------
#   Eingänge          Bausteine (an = farbig, aus = grau gestrichelt)    Ausgänge
#   ┌────────────┐    ┌──────────────────┐     ┌─────────┐    ┌──────────────┐
#   │ Knüppel    │──▶ │ Vorsteuerung     │──▶  │         │──▶ │ Flosse oben  │
#   │ IMU (Lage) │──▶ │ Nick-PID …       │──▶  │ Mischer │──▶ │ Schwenker …  │
#   │ Gas        │────────────────────────────────────────────▶│ ESC (Pilot)  │
#   └────────────┘    └──────────────────┘     └─────────┘    └──────────────┘
# =============================================================================
class_name FlowDiagram
extends Control

var ship: AirshipPhysics
const C_ON := Color("2f7de1")
const C_OFF := Color("4a5563")
const C_SAFE := Color("3fb27f")
const C_IO := Color("e0a43a")


func _ready() -> void:
	custom_minimum_size = Vector2(520, 420)


func _draw() -> void:
	var font := get_theme_default_font()
	var fs := 13
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("141b25"))
	# --- Spalten ---
	var x_in := 8.0
	var w_in := w * 0.17
	var x_blk := w * 0.24
	var w_blk := w * 0.33
	var x_mix := w * 0.62
	var w_mix := w * 0.1
	var x_out := w * 0.78
	var w_out := w - x_out - 8.0
	# Eingänge
	var ins := ["Knüppel Nick", "Knüppel Gier", "IMU Lage/Rate", "Modus-Schalter", "Gas (Pilot)"]
	var in_y := {}
	for i in ins.size():
		var r := Rect2(x_in, 12.0 + i * (h - 24.0) / ins.size(), w_in, 30)
		_box(r, ins[i], C_IO, font, fs, false)
		in_y[ins[i]] = r.get_center().y
	# Bausteine (ohne die Sicherheits-Bausteine, die stehen unten)
	var blks := []
	var safes := []
	for b in FcBlocks.BLOCKS:
		if b.get("safety", false): safes.append(b)
		elif b.id != "mix": blks.append(b)
	var step := (h - 90.0) / blks.size()
	var mix_r := Rect2(x_mix, h * 0.18, w_mix, h * 0.5)
	for i in blks.size():
		var b: Dictionary = blks[i]
		var on := FcBlocks.is_on(b.id)
		var r := Rect2(x_blk, 10.0 + i * step, w_blk, step - 6.0)
		_box(r, b.name, C_ON if on else C_OFF, font, fs, not on)
		# Eingang → Baustein (Knüppel für Vorsteuerung/Rate/Expo, IMU für Regler)
		var src := "IMU Lage/Rate"
		if b.id in ["ff", "rate", "expo", "protect"]: src = "Knüppel Nick" if b.id != "expo" else "Knüppel Gier"
		if b.id == "swv_back": src = "Gas (Pilot)"
		_arrow(Vector2(x_in + w_in, in_y[src]), Vector2(x_blk, r.get_center().y), (C_ON if on else C_OFF).darkened(0.2))
		if on:
			_arrow(Vector2(x_blk + w_blk, r.get_center().y), Vector2(x_mix, clampf(r.get_center().y, mix_r.position.y + 6, mix_r.end.y - 6)), C_ON.darkened(0.2))
	_box(mix_r, "Mischer\n(Einbau-\nwinkel)", C_ON, font, fs, false)
	# Ausgänge aus dem Modell
	var outs := []
	if ship:
		for s in ship.surfaces:
			if s.tail_member or not s.sail_member:
				outs.append("Flosse %d°" % roundi(s.hull_angle_deg))
		for m in ship.motors:
			outs.append("Schwenker %s" % ("rechts" if m.position.x > 0 else "links"))
		for m in ship.motors:
			outs.append("ESC %s" % ("rechts" if m.position.x > 0 else "links"))
	var oy := 10.0
	var oh := (h - 20.0) / maxf(outs.size(), 1.0)
	for i in outs.size():
		var r := Rect2(x_out, oy + i * oh, w_out, oh - 5.0)
		var esc: bool = (outs[i] as String).begins_with("ESC")
		_box(r, outs[i], C_IO, font, fs - 1, false)
		if esc:
			# Gas geht am Regler vorbei direkt auf die ESCs
			# unten herum, an allen Bausteinen vorbei
			var ga := Vector2(x_in + w_in, in_y["Gas (Pilot)"])
			var gb := Vector2(x_out, r.get_center().y)
			var gx0 := x_in + w_in + 12.0
			var gx1 := x_out - 14.0
			draw_polyline(PackedVector2Array([ga, Vector2(gx0, ga.y), Vector2(gx0, h - 5.0), Vector2(gx1, h - 5.0), Vector2(gx1, gb.y), gb]), C_SAFE, 1.5, true)
			draw_colored_polygon(PackedVector2Array([gb, gb - Vector2(7, -4), gb - Vector2(7, 4)]), C_SAFE)
		else:
			_arrow(Vector2(mix_r.end.x, mix_r.get_center().y), Vector2(x_out, r.get_center().y), C_ON.darkened(0.2))
	# Sicherheit (fest)
	var sx := x_blk
	var sy := h - 66.0
	draw_string(font, Vector2(sx, sy + 12), "Fest eingebaut (nicht abschaltbar):", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("97a4b2"))
	for i in safes.size():
		var r := Rect2(sx + i * (w_blk * 1.4 / safes.size()), sy + 20.0, w_blk * 1.4 / safes.size() - 6.0, 40.0)
		_box(r, safes[i].name, C_SAFE, font, fs - 2, false)


func _box(r: Rect2, text: String, col: Color, font: Font, fs: int, dashed: bool) -> void:
	draw_rect(r, Color(col, 0.18 if not dashed else 0.06))
	if dashed:
		var p := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for i in 4:
			draw_dashed_line(p[i], p[i + 1], col, 1.5, 5.0)
	else:
		draw_rect(r, col, false, 1.5)
	var lines := text.split("\n")
	var lh := fs + 2.0
	var y0 := r.get_center().y - lh * lines.size() * 0.5 + fs * 0.85
	for i in lines.size():
		draw_string(font, Vector2(r.position.x + 4, y0 + i * lh), lines[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8, fs,
			Color("e6ebf0") if not dashed else Color("7d8794"))


## mid_x: wo die Linie senkrecht läuft (Standard: Mitte zwischen a und b)
func _arrow(a: Vector2, b: Vector2, col: Color, mid_x := -1.0) -> void:
	var mid := (a.x + b.x) * 0.5 if mid_x < 0.0 else mid_x
	var pts := PackedVector2Array([a, Vector2(mid, a.y), Vector2(mid, b.y), b])
	draw_polyline(pts, col, 1.5, true)
	var d := Vector2(1, 0)
	draw_colored_polygon(PackedVector2Array([b, b - d * 7 + Vector2(0, 4), b - d * 7 - Vector2(0, 4)]), col)
