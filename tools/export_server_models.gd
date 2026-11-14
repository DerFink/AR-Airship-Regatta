# 2026-11-14 11:20 – Testmodelle (Quelle „Test“) nicht exportieren
# 2026-11-11 19:30 – Erstversion: schreibt server/rc-airship/models.json (Fingerabdruck, Name und Boxmaß der Standardmodelle) für die Online-Bestenliste
# =============================================================================
# export_server_models.gd
# -----------------------------------------------------------------------------
# Nur unveränderte Standardmodelle werden online gewertet. Der Server erkennt
# sie am Fingerabdruck (ModelCodec.fingerprint) und rechnet die gewertete Zeit
# mit dem hier gespeicherten Boxmaß selbst aus. Nach jeder Änderung an den
# Standardmodellen ausführen und models.json neu hochladen:
#   godot --headless --path . -s tools/export_server_models.gd
# (Der Test server_models_test prüft, ob die Datei noch passt.)
# =============================================================================
extends SceneTree

var main: Node
var f := 0
var out := {}
var idx := 0
var names: Array = []

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	if names.is_empty():
		for e in AirshipPresets.list():
			if e.source != "Eigene" and e.source != "Test": names.append(e)
	if f % 3 != 0: return false
	if idx < names.size():
		var e: Dictionary = names[idx]
		e.build.call(main.ship)
		main.ship.config_changed.emit()
		main.visual.rebuild()
		var a: AABB = main.visual.local_aabb()
		out[ModelCodec.fingerprint(main.ship)] = {"name": e.name,
			"box": [snappedf(a.size.z, 0.001), snappedf(a.size.x, 0.001), snappedf(a.size.y, 0.001)]}
		idx += 1
		return false
	var path := ProjectSettings.globalize_path("res://server/rc-airship/models.json")
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_string(JSON.stringify(out, "  ", true))
	fa.close()
	print("models.json: ", out.size(), " Modelle → ", path)
	return true
