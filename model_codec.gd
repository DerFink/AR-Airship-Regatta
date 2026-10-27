# 2026-10-27 16:07 – Teilmassen im String (Hülle, Elektronik, Lage/Automatik der Restmasse, Gondelmasse); alte Strings bekommen Standardwerte
# 2026-10-27 15:09 – Leitwerk als Beschreibung im String (tail: Anordnung, Anzahl, Bauart, Fläche, Streckung, Pfeilung …); Flossen-Zuspitzung; ältere Strings ohne tail bleiben lesbar
# 2026-10-27 12:23 – Propellersteigung (pit) im Modell-String; fehlt sie in älteren Strings, gilt 3"
# 2026-10-27 11:08 – Erstversion: Modell als Textstring (LTA1) exportieren/importieren – komprimiert, mit Prüfsumme, Versionskennung und Grenzwertprüfung jedes Werts; Logo nur als Verweis
# =============================================================================
# ModelCodec.gd
# -----------------------------------------------------------------------------
# Wandelt ein komplettes Luftschiff (Hülle, Massen, Flossen, Motoren,
# Gestaltung) in EINE Textzeile und zurück – zum Teilen per Messenger/E-Mail.
#
# Aufbau:   LTA1:<Name>:<Daten>:<Prüfsumme>
#   LTA1        Format-Version 1 (spätere Versionen bleiben lesbar)
#   Name        Modellname, ohne Doppelpunkte, max. 40 Zeichen
#   Daten       JSON → Deflate-komprimiert → Base64 (URL-sicher)
#   Prüfsumme   erste 8 Hex-Zeichen von SHA-256 über die Daten
#
# Beim Import wird JEDER Wert auf sinnvolle Grenzen geprüft und notfalls
# begrenzt, die Anzahl der Bauteile ist gedeckelt und die entpackte Größe
# ebenfalls – ein kaputter oder manipulierter String kann nichts zerstören.
# Logos stehen nur als Dateiname im String; das Bild wird separat geschickt.
# =============================================================================
class_name ModelCodec
extends RefCounted

const PREFIX := "LTA1"
const MAX_FINS := 16
const MAX_MOTORS := 8
const MAX_UNPACKED := 65536

## Grenzwerte je Feld: [min, max]. Werte außerhalb werden begrenzt.
const LIMITS := {
	"m": [0.2, 0.6], "r0": [0.0, 1.0], "r1": [0.0, 0.5], "cp": [0.5, 0.75],
	"ld": [2.0, 12.0], "vol": [0.01, 10000.0],
	"cg_y": [-5.0, 0.0], "trim": [-5.0, 5.0],
	"hm": [0.0, 1000.0], "el": [0.0, 1000.0], "bx": [0.0, 1.0], "mk": [0.0, 50.0],
	"x": [0.0, 1.0], "a": [0.0, 360.0], "area": [0.001, 50.0], "ar": [0.3, 10.0],
	"defl": [0.0, 45.0], "flap": [0.1, 0.6],
	"so": [0.0, 2.0], "tilt": [-90.0, 90.0], "thrust": [0.0, 500.0], "swv": [0.0, 180.0],
	"reff": [0.1, 1.0], "d": [1.0, 30.0], "pit": [1.0, 20.0], "bl": [2, 6], "rpm": [1000.0, 60000.0],
	"v": [0.0, 85.0], "rot": [0.0, 359.0], "tp": [0.2, 1.0], "tx": [0.5, 1.0],
	"tsize": [0.1, 0.6], "tpos": [0.1, 0.9], "lsize": [0.1, 0.8], "lpos": [0.05, 0.9],
}


# =============================================================================
# Export
# =============================================================================
static func encode(ship: AirshipPhysics) -> String:
	var h := ship.hull
	var data := {
		"v": 1,
		"hull": {"m": h.m, "r0": h.r0, "r1": h.r1, "cp": h.cp, "ld": h.length_to_diameter, "vol": h.volume_m3},
		# Massen: Hülle, Elektronik, Lage der unten angeklebten Restmasse
		# (Schwerpunkt wird beim Laden daraus neu berechnet)
		"mass": {"trim": ship.trim_heaviness_n, "hm": ship.hull_mass_kg, "el": ship.electronics_mass_kg,
			"bx": ship.ballast_x, "bauto": ship.ballast_auto_x},
		"fins": [], "motors": [],
	}
	# Symmetrisches Leitwerk als Beschreibung (nicht Flosse für Flosse)
	if ship.tail:
		var t := ship.tail
		data["tail"] = {"lay": int(t.layout), "cnt": t.count, "v": t.v_angle_deg, "rot": t.rotation_deg,
			"k": int(t.kind), "area": t.area_m2, "split": t.split_hv, "ah": t.area_h_m2, "av": t.area_v_m2,
			"ar": t.aspect_ratio, "tp": t.taper, "tx": t.hull_x, "defl": t.max_deflection_deg, "flex": t.pseudo_flex}
	# Freie Flächen (Canards u. Ä.)
	for s in ship.surfaces:
		if s.tail_member and ship.tail:
			continue
		data.fins.append({"n": s.display_name, "k": int(s.kind), "x": s.hull_x, "a": s.hull_angle_deg,
			"area": s.area_m2, "ar": s.aspect_ratio, "defl": s.max_deflection_deg,
			"flap": s.flap_chord_ratio, "flex": s.pseudo_flex, "tp": s.taper})
	for m in ship.motors:
		data.motors.append({"n": m.display_name, "p": m.pair_id, "x": m.hull_x, "a": m.hull_angle_deg,
			"so": m.standoff_m, "tilt": m.swivel_tilt_deg, "thrust": m.max_thrust_n,
			"swv": m.max_swivel_deg, "rev": m.reverse_allowed, "reff": m.reverse_efficiency,
			"d": m.prop_diameter_in, "pit": m.prop_pitch_in, "bl": m.prop_blades, "rpm": m.max_rpm, "dir": m.spin_dir,
			"mk": m.mass_kg})
	var l := ship.livery
	data["look"] = {"col": l.hull_color.to_html(false), "txt": l.text, "tcol": l.text_color.to_html(false),
		"tsize": l.text_size, "tpos": l.text_pos, "logo": l.logo_ref,
		"lsize": l.logo_size, "lpos": l.logo_pos, "both": l.both_sides}

	var raw := JSON.stringify(data).to_utf8_buffer()
	var packed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var b64 := Marshalls.raw_to_base64(packed).replace("+", "-").replace("/", "_").replace("=", "")
	return "%s:%s:%s:%s" % [PREFIX, _clean_name(ship.model_name), b64, _checksum(b64)]


# =============================================================================
# Import – Rückgabe {ok, error, name, data}. data ist bereits geprüft.
# =============================================================================
static func decode(text: String) -> Dictionary:
	var s := text.strip_edges().replace("\n", "").replace(" ", "")
	var parts := s.split(":")
	if parts.size() != 4 or parts[0] != PREFIX:
		return _fail("Kein gültiger Modell-String (erwartet LTA1:Name:Daten:Prüfsumme).")
	if _checksum(parts[2]) != parts[3].to_lower():
		return _fail("Prüfsumme stimmt nicht – der String ist unvollständig oder verändert.")
	var b64 := parts[2].replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var packed := Marshalls.base64_to_raw(b64)
	var raw := packed.decompress_dynamic(MAX_UNPACKED, FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty():
		return _fail("Daten lassen sich nicht entpacken.")
	var data = JSON.parse_string(raw.get_string_from_utf8())
	if not data is Dictionary or int(data.get("v", 0)) != 1:
		return _fail("Unbekannte Datenversion.")
	return {"ok": true, "error": "", "name": _clean_name(parts[1]), "data": _sanitize(data)}


# =============================================================================
# Auf ein Luftschiff anwenden (nach decode)
# =============================================================================
static func apply(ship: AirshipPhysics, name: String, d: Dictionary) -> void:
	var h := GertlerHull.new()
	var hd: Dictionary = d.hull
	h.m = hd.m; h.r0 = hd.r0; h.r1 = hd.r1; h.cp = hd.cp
	h.length_to_diameter = hd.ld; h.volume_m3 = hd.vol
	ship.set_hull(h)
	ship.model_name = name
	ship.trim_heaviness_n = d.mass.trim
	ship.hull_mass_kg = d.mass.hm
	ship.electronics_mass_kg = d.mass.el
	ship.ballast_x = d.mass.bx
	ship.ballast_auto_x = d.mass.bauto

	var fins: Array[ControlSurface] = []
	for f in d.fins:
		var s := AirshipPresets.make_fin(f.n, f.x, f.a, f.area, int(f.k))
		s.aspect_ratio = f.ar; s.max_deflection_deg = f.defl
		s.flap_chord_ratio = f.flap; s.pseudo_flex = f.flex; s.taper = f.tp
		fins.append(s)
	ship.surfaces = fins
	ship.tail = null
	if d.has("tail"):
		var td: Dictionary = d.tail
		var t := TailConfig.new()
		t.layout = td.lay; t.count = td.cnt; t.v_angle_deg = td.v; t.rotation_deg = td.rot
		t.kind = td.k; t.area_m2 = td.area; t.split_hv = td.split
		t.area_h_m2 = td.ah; t.area_v_m2 = td.av; t.aspect_ratio = td.ar; t.taper = td.tp
		t.hull_x = td.tx; t.max_deflection_deg = td.defl; t.pseudo_flex = td.flex
		ship.tail = t

	var mots: Array[VectorMotor] = []
	for m in d.motors:
		var mo := AirshipPresets.make_motor(m.n, m.x, m.a, m.thrust, m.swv, m.tilt)
		mo.pair_id = m.p; mo.standoff_m = m.so
		mo.reverse_allowed = m.rev; mo.reverse_efficiency = m.reff
		mo.prop_diameter_in = m.d; mo.prop_pitch_in = m.pit; mo.prop_blades = int(m.bl); mo.max_rpm = m.rpm
		mo.spin_dir = int(m.dir)
		mo.mass_kg = m.mk
		mots.append(mo)
	ship.motors = mots

	var l := Livery.new()
	var lk: Dictionary = d.look
	l.hull_color = Color.html(lk.col); l.text = lk.txt; l.text_color = Color.html(lk.tcol)
	l.text_size = lk.tsize; l.text_pos = lk.tpos; l.logo_ref = lk.logo
	l.logo_size = lk.lsize; l.logo_pos = lk.lpos; l.both_sides = lk.both
	ship.livery = l
	ship.rebuild_mass_properties()


# =============================================================================
# Hilfsfunktionen
# =============================================================================
static func _checksum(b64: String) -> String:
	return b64.sha256_text().left(8)


static func _clean_name(n: String) -> String:
	var c := n.replace(":", " ").strip_edges().left(40)
	return c if c != "" else "Ohne Namen"


static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "error": msg, "name": "", "data": {}}


## Zahl lesen und auf LIMITS[key] begrenzen; fehlt sie, gilt der Standardwert.
static func _num(src: Dictionary, key: String, def: float) -> float:
	var v = src.get(key, def)
	var f := float(v) if (v is float or v is int) else def
	if LIMITS.has(key):
		f = clampf(f, LIMITS[key][0], LIMITS[key][1])
	return f


static func _txt(src: Dictionary, key: String, def: String, max_len: int) -> String:
	var v = src.get(key, def)
	return str(v).left(max_len) if v is String else def


static func _flag(src: Dictionary, key: String, def: bool) -> bool:
	var v = src.get(key, def)
	return v if v is bool else def


static func _color(src: Dictionary, key: String, def: String) -> String:
	var v := _txt(src, key, def, 8)
	return v if Color.html_is_valid(v) else def


## Liefert ein vollständig geprüftes Daten-Dictionary (nur bekannte Felder).
static func _sanitize(d: Dictionary) -> Dictionary:
	var hd: Dictionary = d.get("hull", {}) if d.get("hull") is Dictionary else {}
	var md: Dictionary = d.get("mass", {}) if d.get("mass") is Dictionary else {}
	var out := {
		"hull": {"m": _num(hd, "m", 0.4), "r0": _num(hd, "r0", 0.5), "r1": _num(hd, "r1", 0.0),
			"cp": _num(hd, "cp", 0.65), "ld": _num(hd, "ld", 5.0), "vol": _num(hd, "vol", 0.25)},
		# ältere Strings ohne Teilmassen bekommen die Standardwerte
		"mass": {"trim": _num(md, "trim", 0.05), "hm": _num(md, "hm", 0.086), "el": _num(md, "el", 0.030),
			"bx": _num(md, "bx", 0.45), "bauto": _flag(md, "bauto", true)},
		"fins": [], "motors": [],
	}
	var fins = d.get("fins", [])
	if fins is Array:
		for f in fins.slice(0, MAX_FINS):
			if not f is Dictionary: continue
			out.fins.append({"n": _txt(f, "n", "Flosse", 32), "k": clampi(int(_num(f, "k", 0)), 0, 2),
				"x": _num(f, "x", 0.9), "a": _num(f, "a", 0.0), "area": _num(f, "area", 0.08),
				"ar": _num(f, "ar", 1.5), "defl": _num(f, "defl", 25.0), "flap": _num(f, "flap", 0.3),
				"flex": _flag(f, "flex", false), "tp": _num(f, "tp", 1.0)})
	var td = d.get("tail")
	if td is Dictionary:
		out["tail"] = {"lay": clampi(int(_num(td, "lay", 0)), 0, 4), "cnt": clampi(int(_num(td, "cnt", 4)), 1, 8),
			"v": _num(td, "v", 45.0), "rot": _num(td, "rot", 0.0), "k": clampi(int(_num(td, "k", 0)), 0, 2),
			"area": _num(td, "area", 0.08), "split": _flag(td, "split", false),
			"ah": _num(td, "ah", 0.08), "av": _num(td, "av", 0.08), "ar": _num(td, "ar", 1.5),
			"tp": _num(td, "tp", 1.0), "tx": _num(td, "tx", 0.9), "defl": _num(td, "defl", 25.0),
			"flex": _flag(td, "flex", false)}
	var mots = d.get("motors", [])
	if mots is Array:
		for m in mots.slice(0, MAX_MOTORS):
			if not m is Dictionary: continue
			out.motors.append({"n": _txt(m, "n", "Motor", 32), "p": _txt(m, "p", "", 16),
				"x": _num(m, "x", 0.25), "a": _num(m, "a", 90.0), "so": _num(m, "so", 0.08),
				"tilt": _num(m, "tilt", 0.0), "thrust": _num(m, "thrust", 1.2), "swv": _num(m, "swv", 60.0),
				"rev": _flag(m, "rev", true), "reff": _num(m, "reff", 0.55), "d": _num(m, "d", 5.0),
				"pit": _num(m, "pit", 3.0), "bl": _num(m, "bl", 2), "rpm": _num(m, "rpm", 18000.0),
				"dir": -1 if _num(m, "dir", 1) < 0 else 1, "mk": _num(m, "mk", 0.030)})
	var lk: Dictionary = d.get("look", {}) if d.get("look") is Dictionary else {}
	var logo := _txt(lk, "logo", "", 40)
	# Logo-Verweis darf nur ein schlichter Dateiname sein (kein Pfad!)
	if not logo.is_valid_filename() or not logo.ends_with(".png"):
		logo = ""
	out["look"] = {"col": _color(lk, "col", "dfe5ea"), "txt": _txt(lk, "txt", "", 24),
		"tcol": _color(lk, "tcol", "1b2128"), "tsize": _num(lk, "tsize", 0.3), "tpos": _num(lk, "tpos", 0.5),
		"logo": logo, "lsize": _num(lk, "lsize", 0.45), "lpos": _num(lk, "lpos", 0.25),
		"both": _flag(lk, "both", true)}
	return out
