# 2026-10-27 11:08 – Erstversion: Gestaltungsdaten der Hülle (Farbe, Schriftzug, Logo-Verweis, Größe/Lage, beidseitig); Logo-Import mit Verkleinerung und Inhalts-Hash als Dateiname; Logos liegen getrennt vom Modell
# =============================================================================
# Livery.gd  (Gestaltung = "Lackierung" der Hülle)
# -----------------------------------------------------------------------------
# Reine Daten – das Malen übernimmt LiveryCanvas.
#   – Hüllenfarbe
#   – Schriftzug (Text, Farbe, Größe, Lage längs der Hülle)
#   – Logo: NUR ein Verweis (Dateiname). Das Bild wird separat geschickt
#     und in user://logos/ abgelegt – so bleibt der Modell-String kurz.
#     Für die Sammlung legt der Admin Logos in res://models/logos/.
#   – beidseitig: Schrift und Logo links UND rechts
# =============================================================================
class_name Livery
extends Resource

signal changed_look

const LOGO_DIR_USER := "user://logos/"
const LOGO_DIR_ADMIN := "res://models/logos/"

@export var hull_color := Color("dfe5ea"):
	set(v): hull_color = v; changed_look.emit()
@export var text := "":
	set(v): text = v.left(24); changed_look.emit()
@export var text_color := Color("1b2128"):
	set(v): text_color = v; changed_look.emit()
## Schrifthöhe als Anteil des Hüllendurchmessers (0,1–0,6).
@export_range(0.1, 0.6, 0.01) var text_size := 0.30:
	set(v): text_size = v; changed_look.emit()
## Lage der Schriftmitte längs der Hülle: 0 = Nase, 1 = Heck.
@export_range(0.1, 0.9, 0.01) var text_pos := 0.50:
	set(v): text_pos = v; changed_look.emit()
## Dateiname des Logos (z. B. "a3f29c10e2.png"), leer = kein Logo.
@export var logo_ref := "":
	set(v): logo_ref = v; changed_look.emit()
@export_range(0.1, 0.8, 0.01) var logo_size := 0.45:
	set(v): logo_size = v; changed_look.emit()
@export_range(0.05, 0.9, 0.01) var logo_pos := 0.25:
	set(v): logo_pos = v; changed_look.emit()
@export var both_sides := true:
	set(v): both_sides = v; changed_look.emit()


## Logo suchen: zuerst eigene, dann Admin-Sammlung. null = Datei fehlt.
func load_logo() -> Texture2D:
	if logo_ref == "":
		return null
	for dir in [LOGO_DIR_USER, LOGO_DIR_ADMIN]:
		var p: String = dir + logo_ref
		if FileAccess.file_exists(p):
			var img := Image.load_from_file(p)
			if img: return ImageTexture.create_from_image(img)
	return null


## Verweis gesetzt, aber Bild nicht vorhanden → Hinweis im Baukasten.
func logo_missing() -> bool:
	return logo_ref != "" and load_logo() == null


## Bild aus einer gewählten Datei übernehmen: auf max. 512 px verkleinern,
## unter seinem Inhalts-Hash speichern, Dateinamen zurückgeben.
## Gleiches Bild = gleicher Name, egal von wem es kommt – so findet der
## Admin zu einem eingesandten String das passende Logo.
static func import_logo_file(path: String) -> String:
	var img := Image.load_from_file(path)
	if img == null:
		return ""
	var m := maxi(img.get_width(), img.get_height())
	if m > 512:
		var k := 512.0 / m
		img.resize(int(img.get_width() * k), int(img.get_height() * k), Image.INTERPOLATE_LANCZOS)
	var ref := img.save_png_to_buffer().hex_encode().sha256_text().left(10) + ".png"
	DirAccess.make_dir_recursive_absolute(LOGO_DIR_USER)
	img.save_png(LOGO_DIR_USER + ref)
	return ref
