# 2026-11-16 16:45 – Erstversion: Texteingabe im Handy-Browser über das Eingabefenster des Browsers (Godot öffnet dort keine Bildschirmtastatur, auch nicht im Vollbild)
# =============================================================================
# WebTextInput.gd  (ein Knoten in der Hauptszene, nur im Browser auf Touch-Geräten aktiv)
# -----------------------------------------------------------------------------
# Problem: Im Browser auf dem Handy öffnet sich beim Antippen eines Textfelds
# (z. B. Pilotenname nach dem Rennen) keine Tastatur.
# Lösung: Sobald ein Textfeld den Fokus bekommt, fragt der Browser mit seinem
# eigenen Eingabefenster (window.prompt) nach dem Text – dort erscheint die
# Handy-Tastatur zuverlässig. Der eingegebene Text wird ins Feld übernommen und
# wie „Enter“ bestätigt; „Abbrechen“ lässt den alten Text stehen.
# =============================================================================
class_name WebTextInput
extends Node

var _busy := false


func _ready() -> void:
	# nur Browser mit Touchscreen (am PC-Browser gibt es eine echte Tastatur)
	if not OS.has_feature("web") or not DisplayServer.is_touchscreen_available():
		return
	get_viewport().gui_focus_changed.connect(_on_focus)


func _on_focus(c: Control) -> void:
	if _busy:
		return
	if c is LineEdit and (c as LineEdit).editable:
		_ask.call_deferred(c)
	elif c is TextEdit and (c as TextEdit).editable:
		_ask.call_deferred(c)


## Browser-Eingabefenster öffnen und Ergebnis ins Feld schreiben.
func _ask(c: Control) -> void:
	if not is_instance_valid(c):
		return
	_busy = true
	var title: String = I18n.t(c.placeholder_text) if c.placeholder_text != "" else I18n.t("Eingabe")
	var cur: String = c.text
	# Texte als JSON übergeben → sicher gegen Anführungszeichen im Text
	var res = JavaScriptBridge.eval("prompt(%s, %s)" % [JSON.stringify(title), JSON.stringify(cur)])
	if res != null and is_instance_valid(c):
		var t := str(res)
		if c is LineEdit:
			var le := c as LineEdit
			if le.max_length > 0:
				t = t.left(le.max_length)
			le.text = t
			le.text_changed.emit(t)
			le.text_submitted.emit(t)
		else:
			(c as TextEdit).text = t
			(c as TextEdit).text_changed.emit()
	if is_instance_valid(c):
		c.release_focus()                          # Fokus weg, sonst öffnet es sich gleich wieder
	_busy = false
