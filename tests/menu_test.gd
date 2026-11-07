# 2026-11-07 21:10 – Erstversion: Menü der Flugansicht (Einträge, Version) und Auswertung der Update-Antwort ohne Netz
extends SceneTree
var main: Node
var f := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_dt: float) -> bool:
	f += 1
	if f == 10:
		var hud: FlightHUD = main.hud
		hud._menu.show_menu()
	if f == 14:
		var m: MainMenu = main.hud._menu
		var names := []
		for b in m._grid.get_children(): names.append((b as Button).text)
		print("Menü sichtbar=%s, Einträge: %s" % [m.visible, ", ".join(names)])
		print("Fußzeile: ", m._ver.text, " | Menü ", m._panel.size, " Bildschirm ", m.size)
		# Eintrag „Bestenliste“ antippen → Menü zu, Bestenliste offen
		(m._grid.get_child(3) as Button).emit_signal("pressed")
	if f == 18:
		print("Nach „Bestenliste“: Menü sichtbar=%s, Ansicht=%d (5 = Bestenliste)" % [main.hud._menu.visible, main.view])
		var r := Updater.parse_release({"tag_name": "android-build-42", "assets": [{"name": "ar-airship-regatta.apk", "browser_download_url": "https://example.invalid/a.apk"}]})
		print("Update-Antwort: Build %d, APK %s" % [r.build, r.url])
		print("ENDE")
		return true
	return false
