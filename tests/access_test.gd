# 2026-11-17 18:35 – Abmelden/Anmelden und Hinweis zum Teensy-Sketch geprüft
# 2026-11-17 18:50 – Erstversion: Zugangscodes in der App – ohne Code keine privaten Modelle; nach Freischalten in „Modell & Bau“ (Schloss), nie in der Bestenliste; Admin-Rolle zeigt „Teensy-Sketch erzeugen“; Code entfernen räumt auf. Bildschirmfotos mit --shots=<Ordner>
extends SceneTree
# Der Server wird nicht gefragt: Die Antwort von api.php?unlock wird direkt an
# AccessCodes.store() gegeben (den Server prüft tests/server_access_test.sh).

var main: Node
var f := 0
var ok := true
var shots := ""
var secret := ""                 ## Modell-String des privaten Testmodells


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots = a.substr(8)
	I18n.set_language("de", true)
	AccessCodes.clear()
	# privates Testmodell: Chewie mit anderem Namen und längerer Hülle
	var s := AirshipPhysics.new()
	AirshipPresets.chewie(s)
	s.model_name = "Geheimschiff"
	s.hull.length_to_diameter = 6.5
	secret = ModelCodec.encode(s)
	s.free()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _fail(msg: String) -> void:
	print("FEHLER ", msg)
	ok = false


func _names(src: String) -> Array:
	var out := []
	for e in AirshipPresets.list():
		if e.source == src: out.append(e.name)
	return out


func _shot(name: String) -> void:
	if shots != "":
		root.get_viewport().get_texture().get_image().save_png(shots + "/" + name + ".png")


func _process(_dt: float) -> bool:
	if not is_instance_valid(main): return true
	if not main.ready_done: return false
	f += 1
	match f:
		3:
			# --- ohne Code: nichts Privates, kein Admin-Bereich ---
			if not _names("Privat").is_empty(): _fail("private Modelle ohne Code sichtbar")
			if AccessCodes.is_admin(): _fail("Admin ohne Code")
			# --- Gruppe freischalten (Antwort wie vom Server) ---
			AccessCodes.store("ABCD-EFGH-JKLM", {"ok": true, "role": "gruppe", "group": "Troponaut",
				"models": [{"name": "Geheimschiff", "model": secret, "meta": "# Autor: Kollege | Beschreibung: PigLeg-Test", "group": "Troponaut"}]})
			main.settings.access_changed.emit()
			if _names("Privat") != ["Geheimschiff"]: _fail("privates Modell fehlt nach dem Freischalten: %s" % [_names("Privat")])
			if AirshipPresets.meta("Geheimschiff").get("team", "") != "Troponaut": _fail("Gruppe nicht als Team gezeigt")
			# privates Modell laden → zählt nicht für die Bestenliste
			for e in AirshipPresets.list():
				if e.name == "Geheimschiff":
					var t := AirshipPhysics.new()
					e.build.call(t)
					if AirshipPresets.standard_model_of(t) != "": _fail("privates Modell gilt als Standardmodell")
					if AirshipPresets.private_model_of(t) != "Geheimschiff": _fail("privates Modell nicht erkannt")
					t.free()
			if main.builder._admin_nodes[0].visible: _fail("Teensy-Sketch für Gruppe sichtbar")
			main.settings.visible = true
			main.settings._show_access("")
		6:
			print("Einstellungen: ", main.settings._code_status.text)
			if not ("Troponaut" in main.settings._code_status.text): _fail("Stand im Zugang falsch")
			main.settings._scroll.scroll_vertical = 100000
		9:
			_shot("zugang_einstellungen")
			main.settings.visible = false
			main._set_view(main.View.HUB)
		14:
			_shot("zugang_hub")
			# --- Admin ---
			AccessCodes.store("ADMN-ADMN-ADMN", {"ok": true, "role": "admin", "group": "Erich", "models": []})
			main.settings.access_changed.emit()
			if not main.builder._admin_nodes[0].visible: _fail("Teensy-Sketch für Admin unsichtbar")
			# --- Abmelden: Code bleibt, wirkt aber nicht; Anmelden stellt wieder her ---
			main.settings._code_sign.emit_signal("pressed")
			if AccessCodes.is_admin() or not AccessCodes.has_saved_code(): _fail("Abmelden falsch")
			if main.builder._admin_nodes[0].visible: _fail("Teensy-Sketch nach Abmelden sichtbar")
			if not ("Admin" in main.builder._ino_note.text): _fail("Hinweis auf den Admin fehlt")
			AccessCodes.set_signed_in(true)
			main.settings.access_changed.emit()
			if not AccessCodes.is_admin(): _fail("Anmelden stellt den Zugang nicht her")
			# --- Code entfernen ---
			main.settings._code_del.emit_signal("pressed")
			if AccessCodes.has_code() or FileAccess.file_exists(AccessCodes.MODELS_FILE): _fail("Code entfernen räumt nicht auf")
			if not _names("Privat").is_empty(): _fail("private Modelle nach Entfernen sichtbar")
			if main.builder._admin_nodes[0].visible: _fail("Teensy-Sketch nach Entfernen sichtbar")
			print("access_test: " + ("OK" if ok else "FEHLER"))
			print("ENDE")
			if not ok: assert(false, "Zugangscodes fehlerhaft")
			quit(0 if ok else 1)
			return true
	return false
