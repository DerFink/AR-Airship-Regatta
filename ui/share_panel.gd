# 2026-10-28 00:15 – Import meldet model_applied (PID-Vorgaben übernehmen)
# 2026-10-27 12:22 – Fix: Vollbild-Anker mit set_anchors_and_offsets_preset (vorher blieb die Fläche 0 px groß → Knüppel und Menüs landeten oben links)
# 2026-10-27 11:08 – Erstversion: Teilen-Dialog nach freigegebenem Entwurf – Modell-String anzeigen/kopieren, eingefügten String prüfen und laden, eigenes Modell speichern, Hinweis aufs separat zu schickende Logo
# =============================================================================
# SharePanel.gd
# -----------------------------------------------------------------------------
#   ┌ Modell teilen ─────────────────────────┐ ┌ Hinweise ──────────┐
#   │ Name [ Chewie            ]             │ │ Logo separat       │
#   │ ┌ LTA1:Chewie:eJyr…:7F3A ┐            │ │ mitschicken: …png  │
#   │ └────────────────────────┘            │ │                    │
#   │ [Kopieren] [Einfügen und laden]        │ │ Admin: Zeile in    │
#   │ [In „Eigene“ speichern]  ✓ Prüfsumme ok │ │ models/sammlung…   │
#   └────────────────────────────────────────┘ └────────[Schließen]┘
# =============================================================================
class_name SharePanel
extends Control

signal closed
signal model_loaded
signal ui_action(kind: String)

var ship: AirshipPhysics
var _name: LineEdit
var _code: TextEdit
var _banner: PanelContainer
var _logo_hint: Label


func setup(airship: AirshipPhysics) -> void:
	ship = airship


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UITheme.space("lg")
	var bg := ColorRect.new()
	bg.color = UITheme.color("backdrop")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var row := UITheme.make_hbox("md")
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, m)

	# ===================== links: String ====================================
	var left := UITheme.make_panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.0
	row.add_child(left)
	var col := UITheme.make_vbox("sm")
	left.add_child(col)
	col.add_child(UITheme.make_title("Modell teilen"))
	var nrow := UITheme.make_hbox("sm")
	var nl := UITheme.make_label("Name", "MutedLabel")
	nl.custom_minimum_size.x = 60
	nrow.add_child(nl)
	_name = LineEdit.new()
	_name.max_length = 40
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.custom_minimum_size.y = UITheme.size("control_height")
	_name.text_changed.connect(func(t): ship.model_name = t; _export())
	nrow.add_child(_name)
	col.add_child(nrow)
	_code = TextEdit.new()
	_code.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_code.custom_minimum_size.y = 120
	_code.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mono := SystemFont.new()                 # Festbreitenschrift für den String
	mono.font_names = PackedStringArray(["monospace"])
	_code.add_theme_font_override("font", mono)
	col.add_child(_code)
	var brow := UITheme.make_hbox("xs")
	var copy := UITheme.make_button("Kopieren")
	copy.pressed.connect(_on_copy)
	var paste := UITheme.make_button("Einfügen und laden")
	paste.pressed.connect(_on_paste_load)
	var save := UITheme.make_button("In „Eigene“ speichern")
	save.pressed.connect(_on_save)
	for b in [copy, paste, save]: brow.add_child(b)
	col.add_child(brow)
	_banner = UITheme.make_banner()
	col.add_child(_banner)

	# ===================== rechts: Hinweise ================================
	var right := UITheme.make_panel(260)
	row.add_child(right)
	var rcol := UITheme.make_vbox("sm")
	right.add_child(rcol)
	rcol.add_child(UITheme.make_title("Hinweise"))
	_logo_hint = UITheme.make_label("")
	_logo_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcol.add_child(_logo_hint)
	var admin := UITheme.make_label("Für die Sammlung: String an den Admin schicken. Er fügt ihn als Zeile in models/sammlung.txt ein, das Logo kommt nach models/logos/.", "MutedLabel")
	admin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rcol.add_child(admin)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(spacer)
	var close := UITheme.make_button("Schließen")
	close.pressed.connect(func(): closed.emit())
	rcol.add_child(close)

	visibility_changed.connect(_on_visibility)


func _on_visibility() -> void:
	if visible:
		_name.text = ship.model_name
		_export()
		UITheme.set_banner(_banner, "")


## Aktuelles Modell als String ins Textfeld schreiben.
func _export() -> void:
	_code.text = ModelCodec.encode(ship)
	var ref := ship.livery.logo_ref
	if ref == "":
		_logo_hint.text = "Kein Logo – der String enthält alles."
	else:
		_logo_hint.text = "Logo separat mitschicken: Datei „%s“ (liegt im App-Ordner logos)." % ref


func _on_copy() -> void:
	DisplayServer.clipboard_set(_code.text)
	UITheme.set_banner(_banner, "Kopiert – jetzt per Messenger oder E-Mail verschicken.", "success")
	ui_action.emit("ok")


## String aus der Zwischenablage (oder dem Textfeld) prüfen und laden.
func _on_paste_load() -> void:
	var txt := DisplayServer.clipboard_get()
	if not txt.strip_edges().begins_with(ModelCodec.PREFIX):
		txt = _code.text                     # Fallback: selbst ins Feld eingefügt
	var r := ModelCodec.decode(txt)
	if not r.ok:
		UITheme.set_banner(_banner, r.error, "danger")
		ui_action.emit("warn")
		return
	ModelCodec.apply(ship, r.name, r.data)
	ship.model_applied.emit()          # PID-Vorgaben des Modells übernehmen
	_name.text = ship.model_name
	_export()
	var msg := "Geladen: %s · %d Flossen, %d Motoren." % [r.name, r.data.fins.size(), r.data.motors.size()]
	var level := "success"
	if ship.livery.logo_missing():
		msg += " Logo „%s“ fehlt – im Baukasten unter Gestaltung laden." % ship.livery.logo_ref
		level = "warning"
	UITheme.set_banner(_banner, msg, level)
	ui_action.emit("ok")
	model_loaded.emit()


func _on_save() -> void:
	if ModelLibrary.save_own(_code.text):
		UITheme.set_banner(_banner, "Gespeichert – steht jetzt in der Modellauswahl unter „Eigene“.", "success")
		ui_action.emit("ok")
	else:
		UITheme.set_banner(_banner, "Speichern hat nicht geklappt.", "danger")
		ui_action.emit("warn")
