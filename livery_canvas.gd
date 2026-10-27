# 2026-10-27 11:08 – Erstversion: malt die Gestaltung (Farbe, Schriftzug, Logo, beidseitig) in eine Textur für die Hülle; Seitenverhältnis folgt L/D, damit nichts verzerrt
# =============================================================================
# LiveryCanvas.gd  (SubViewport, Kind von AirshipVisual)
# -----------------------------------------------------------------------------
# Eine kleine 2D-Szene, deren Bild als Textur auf die Hülle gelegt wird.
# Abbildung (passt zu den UV-Koordinaten in GertlerHull.build_mesh):
#   waagrecht  = Länge: links Heck, rechts Nase
#   senkrecht  = einmal um die Hülle, Naht unten;
#                rechte Seite bei 75 % der Höhe, linke bei 25 %
#   Die linke Seite wird um 180° gedreht gemalt, damit sie von außen
#   richtig herum lesbar ist.
# Neu gemalt wird nur bei Änderungen (UPDATE_ONCE) – kostet im Flug nichts.
# =============================================================================
class_name LiveryCanvas
extends SubViewport

const TEX_WIDTH := 1024

var livery: Livery
var _bg := ColorRect.new()
var _root := Node2D.new()


func _init() -> void:
	transparent_bg = false
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_bg)
	add_child(_root)


## Neu malen für Gestaltung l und Schlankheitsgrad L/D.
func repaint(l: Livery, length_to_diameter: float) -> void:
	livery = l
	var h := int(round(TEX_WIDTH * PI / length_to_diameter))
	size = Vector2i(TEX_WIDTH, h)
	_bg.size = Vector2(size)
	_bg.color = l.hull_color
	for c in _root.get_children(): c.queue_free()

	var px_per_d := float(TEX_WIDTH) / length_to_diameter      # Pixel je Durchmesser
	var sides := [0.75, 0.25] if l.both_sides else [0.75]
	for v in sides:
		var flip: bool = v < 0.5
		var logo := l.load_logo()
		if logo:
			var tr := TextureRect.new()
			tr.texture = logo
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var s := px_per_d * l.logo_size
			tr.size = Vector2(s, s)
			_place(tr, l.logo_pos, v, h, flip)
		if l.text != "":
			var lb := Label.new()
			lb.text = l.text
			lb.add_theme_font_size_override("font_size", maxi(8, int(px_per_d * l.text_size)))
			lb.add_theme_color_override("font_color", l.text_color)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lb.size = lb.get_minimum_size()
			_place(lb, l.text_pos, v, h, flip)
	render_target_update_mode = SubViewport.UPDATE_ONCE


## Element zentriert an Längsposition pos (0 = Nase) und Höhe v setzen.
func _place(c: Control, pos: float, v: float, h: int, flip: bool) -> void:
	var holder := Node2D.new()
	holder.position = Vector2((1.0 - pos) * TEX_WIDTH, v * h)
	holder.rotation = PI if flip else 0.0
	_root.add_child(holder)
	holder.add_child(c)
	c.position = -c.size * 0.5
