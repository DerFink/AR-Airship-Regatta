# 2026-11-11 16:10 – Erstversion: Bildschirmfotos einer Sprache (Argumente --lang=fr --shots=<Ordner>, braucht echte Grafik) – Start, Modell & Bau, Baukasten, Signalfluss, Grundlagen, Flug
extends SceneTree
var main: Node
var f := 0
var shots := ""
var lang := "fr"

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots = a.substr(8)
		if a.begins_with("--lang="): lang = a.substr(7)
	I18n.set_language(lang, true)      # gespeichert, weil main.gd die gespeicherte Sprache lädt
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _shot(name: String) -> void:
	if shots == "": return
	root.get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [shots, lang, name])

func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	if f == 20: _shot("start"); main.start_screen.build_requested.emit()
	if f == 34: _shot("hub"); main.hub.edit_requested.emit()
	if f == 60:
		_shot("builder")
		var tabs: TabContainer = main.builder._left.get_child(0)
		tabs.current_tab = 1
	if f == 70:
		_shot("builder_tail")
		var tabs: TabContainer = main.builder._left.get_child(0)
		tabs.current_tab = 3
		main.builder._show_flow()
	if f == 80:
		_shot("flow")
		main.builder._flow_win.visible = false
		main.builder.closed.emit()
	if f == 86: main.hub.home_requested.emit()
	if f == 90: main.start_screen.about_requested.emit()
	if f == 96:
		main.about._show(4); 
	if f == 100: _shot("about_license"); main.about._show(0)
	if f == 104: _shot("about_physics"); main.about.closed.emit()
	if f == 108: main.start_screen.build_requested.emit()
	if f == 114: main.hub._on_fly()
	if f == 130:
		_shot("fly"); I18n.set_language("de", true); print("ENDE"); return true
	return false
