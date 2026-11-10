# 2026-11-11 02:50 – Erstversion: Ladeanzeige – ein kleines Luftschiff fliegt die Acht (statt Sanduhr), darunter „Lädt …“; blendet sich am Ende weich aus
# =============================================================================
# LoadingOverlay.gd
# -----------------------------------------------------------------------------
# Liegt beim Start über allem, solange main.gd Welt, Luftschiff (Modelldaten)
# und Oberfläche aufbaut. Gezeichnet wird alles mit _draw() – ohne Bilder,
# damit die Anzeige sofort da ist.
#   Acht   = Lemniskate von Bernoulli (wie im App-Icon)
#   Schiff = silberne Hülle mit Flosse, fliegt tangential an der Acht entlang
# =============================================================================
class_name LoadingOverlay
extends Control

const BG := Color("0f1a33")
const LINE := Color("ff7a3c")
var _t := 0.0                      ## Laufparameter auf der Acht
var _fade := -1.0                  ## < 0: sichtbar; sonst Ausblend-Zeit
var _label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP          # während des Ladens nichts antippen
	_label = Label.new()
	_label.text = "Lädt …"
	_label.add_theme_color_override("font_color", Color(0.85, 0.89, 0.96))
	_label.add_theme_font_size_override("font_size", 22)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


## Laden fertig: in 0,4 s ausblenden und entfernen.
func finish() -> void:
	_fade = 0.0


## Punkt auf der Acht (Lemniskate) für Parameter t, Halbachse a.
static func lem(a: float, t: float) -> Vector2:
	var s := sin(t)
	var c := cos(t)
	var d := 1.0 + s * s
	return Vector2(a * c / d, -a * s * c / d)


func _process(dt: float) -> void:
	_t += dt * 1.6
	if _fade >= 0.0:
		_fade += dt
		modulate.a = clampf(1.0 - _fade / 0.4, 0.0, 1.0)
		if _fade >= 0.4:
			queue_free()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var a := minf(size.x, size.y) * 0.22
	var c := size * 0.5 - Vector2(0, a * 0.15)
	# Acht
	var pts := PackedVector2Array()
	for i in 121:
		pts.append(c + lem(a, TAU * i / 120.0))
	draw_polyline(pts, LINE, maxf(a * 0.07, 4.0), true)
	# Luftschiff an der Acht, Nase in Flugrichtung
	var p := c + lem(a, _t)
	var q := c + lem(a, _t + 0.01)
	var ang := (q - p).angle()
	var L := a * 0.75
	draw_set_transform(p, ang, Vector2.ONE)
	# Hülle: Tropfen (vorn rund, hinten spitz) aus dem Gertler-ähnlichen Profil
	var hull := PackedVector2Array()
	var R := L / 12.0                                   # L/D = 6
	for side in [-1.0, 1.0]:
		for k in 25:
			var i := k if side < 0.0 else 24 - k
			var x := float(i) / 24.0                    # 0 = Nase, 1 = Heck
			var r := R * sqrt(maxf(0.0, 1.0 - pow((x - 0.4) / 0.4, 2.0))) if x < 0.4 else R * (1.0 - pow((x - 0.4) / 0.6, 2.0))
			hull.append(Vector2(L * 0.5 - x * L, side * r))
	# Flosse oben am Heck
	draw_colored_polygon(PackedVector2Array([Vector2(-L * 0.36, 0), Vector2(-L * 0.42, -L * 0.15),
		Vector2(-L * 0.5, -L * 0.15), Vector2(-L * 0.48, 0)]), Color("eef2f6"))
	draw_colored_polygon(hull, Color("cfd6de"))
	# Glanzstreifen der Silberfolie
	draw_line(Vector2(L * 0.35, -L * 0.04), Vector2(-L * 0.3, -L * 0.04), Color(1, 1, 1, 0.8), maxf(L * 0.025, 1.5), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Text unter der Acht
	_label.size = Vector2(size.x, 30)
	_label.position = Vector2(0, c.y + a * 0.75)
