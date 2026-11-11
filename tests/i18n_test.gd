# 2026-11-11 16:00 – Erstversion: prüft Übersetzungstabelle, Dezimalzeichen je Sprache und die Seite „Grundlagen“ in allen Sprachen
extends SceneTree

func _initialize() -> void:
	var ok := true
	I18n.setup()
	for lang in I18n.LANGS:
		I18n.set_language(lang, false)
		# Seite „Grundlagen“: 5 Reiter, Hinweis auf KI im letzten
		var t := AboutPanel.load_texts(lang)
		if t.size() != 5:
			print("FEHLER about_%s: %d Reiter" % [lang, t.size()]); ok = false
		elif not ("Claude" in t[4]):
			print("FEHLER about_%s: KI-Hinweis fehlt" % lang); ok = false
	var cases := {"fr": ["Hülle", "Enveloppe", "1,25"], "en": ["Hülle", "Hull", "1.25"], "zh_TW": ["Hülle", "艇身", "1.25"],
		"pl": ["Kopieren", "Kopiuj", "1,25"], "de": ["Hülle", "Hülle", "1,25"]}
	for lang in cases:
		I18n.set_language(lang, false)
		var c: Array = cases[lang]
		if I18n.t(c[0]) != c[1]:
			print("FEHLER %s: %s → %s" % [lang, c[0], I18n.t(c[0])]); ok = false
		if I18n.dec("%.2f" % 1.25) != c[2]:
			print("FEHLER %s: Dezimal %s" % [lang, I18n.dec("%.2f" % 1.25)]); ok = false
	# Formatierte Texte mit Platzhaltern
	I18n.set_language("es", false)
	var s := I18n.t("Runde %d/%d · %s") % [2, 3, "0:12,3"]
	if s != "Vuelta 2/3 · 0:12,3":
		print("FEHLER es: ", s); ok = false
	I18n.set_language("de", false)
	print("i18n_test: ", "OK" if ok else "FEHLER")
	if not ok:
		push_error("SCRIPT ERROR: Übersetzung fehlerhaft")   # lässt den CI-Lauf scheitern
	print("ENDE")
	quit(0 if ok else 1)
