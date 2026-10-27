# 2026-10-27 10:42 – Erstversion: virtueller Knüppel mit Multitouch, Totzone, Selbstzentrierung je Achse, Maus-Ersatz für Desktop, Farben aus UITheme
# =============================================================================
# TouchStick.gd
# -----------------------------------------------------------------------------
# Ein Onscreen-Knüppel. Zwei Instanzen (links/rechts) können gleichzeitig
# bedient werden, weil jeder Knüppel sich "seinen" Finger merkt
# (Touch-Index) und nur dessen Bewegungen auswertet.
#
# Ausgabe: value (−1..+1 je Achse), Y nach OBEN positiv wie beim RC-Sender.
# Selbstzentrierend je Achse einstellbar: Beim Loslassen springt die Achse
# auf 0 zurück (Gas-Mitte = Stopp, passend zu Regler mit Vor-/Rückwärtsschub).
# =============================================================================
class_name TouchStick
extends Control

signal value_changed(value: Vector2)

@export var self_center_x := true
@export var self_center_y := true
@export_range(0.0, 0.3, 0.01) var dead_zone := 0.06
## Beschriftung unter dem Knüppel, z. B. "Nick · Gier".
@export var caption := "":
	set(v): caption = v; queue_redraw()

var value := Vector2.ZERO
var _finger := -1           ## Touch-Index, der diesen Knüppel gerade bedient
var _mouse_down := false    ## Desktop: Maus statt Finger


func _ready() -> void:
	var d := UITheme.size("stick_diameter")
	custom_minimum_size = Vector2(d, d + UITheme.font_size("caption") + UITheme.space("sm"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Eingaben kommen über _input


func _ring_center() -> Vector2:
	var d := float(UITheme.size("stick_diameter"))
	return Vector2(size.x * 0.5, d * 0.5)

func _radius() -> float:
	return UITheme.size("stick_diameter") * 0.5


# -----------------------------------------------------------------------------
# Eingaben global abfangen, damit mehrere Finger parallel funktionieren
# -----------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1 and _hit(event.position):
			_finger = event.index
			_update_from(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			_release()
	elif event is InputEventScreenDrag and event.index == _finger:
		_update_from(event.position)
		get_viewport().set_input_as_handled()
	# Maus (nur Desktop/Editor, wenn kein Touch-Gerät)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not DisplayServer.is_touchscreen_available():
		if event.pressed and _hit(event.position):
			_mouse_down = true
			_update_from(event.position)
		elif not event.pressed and _mouse_down:
			_mouse_down = false
			_release()
	elif event is InputEventMouseMotion and _mouse_down:
		_update_from(event.position)


## Liegt der Punkt (Bildschirm) im Greifbereich? Etwas größer als der Ring.
func _hit(p: Vector2) -> bool:
	var local := get_global_transform_with_canvas().affine_inverse() * p
	return local.distance_to(_ring_center()) <= _radius() * 1.3


func _update_from(screen_pos: Vector2) -> void:
	var local := get_global_transform_with_canvas().affine_inverse() * screen_pos
	var v := (local - _ring_center()) / _radius()
	v = v.limit_length(1.0)
	v.y = -v.y                                 # Bildschirm-Y zeigt nach unten
	# Totzone je Achse, danach neu skalieren, damit der volle Weg erhalten bleibt
	for i in 2:
		var a := absf(v[i])
		v[i] = 0.0 if a < dead_zone else signf(v[i]) * (a - dead_zone) / (1.0 - dead_zone)
	_set_value(v)


func _release() -> void:
	var v := value
	if self_center_x: v.x = 0.0
	if self_center_y: v.y = 0.0
	_set_value(v)


func _set_value(v: Vector2) -> void:
	if v != value:
		value = v
		value_changed.emit(v)
		queue_redraw()


# -----------------------------------------------------------------------------
# Zeichnen: Ring, Fadenkreuz, Knopf, Beschriftung – alles aus UITheme
# -----------------------------------------------------------------------------
func _draw() -> void:
	var c := _ring_center()
	var r := _radius()
	draw_arc(c, r, 0.0, TAU, 64, UITheme.color("stick_ring"), 2.0, true)
	var faint := Color(UITheme.color("stick_ring"), 0.35)
	draw_line(c - Vector2(r * 0.85, 0), c + Vector2(r * 0.85, 0), faint, 1.0)
	draw_line(c - Vector2(0, r * 0.85), c + Vector2(0, r * 0.85), faint, 1.0)
	var knob := c + Vector2(value.x, -value.y) * r
	draw_circle(knob, r * 0.32, Color(UITheme.color("surface_alt"), 0.85))
	draw_arc(knob, r * 0.32, 0.0, TAU, 48, UITheme.color("stick_knob"), 2.0, true)
	if caption != "":
		var f := get_theme_default_font()
		var fs := UITheme.font_size("caption")
		var w := f.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(f, Vector2(c.x - w * 0.5, r * 2.0 + UITheme.space("sm") + fs),
			caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.color("text_muted"))
