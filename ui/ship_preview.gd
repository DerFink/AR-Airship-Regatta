# 2026-11-10 19:40 – Erstversion: Seitenansicht eines Luftschiffs als Bild, gezeichnet aus den Modelldaten (Gertler-Hülle, Flossen, Motoren, Gondel, Aussehen) – für Startseite, Modellliste, Icon-Ladeanzeige
# =============================================================================
# ShipPreview.gd
# -----------------------------------------------------------------------------
# Baut ein SVG der Seitenansicht (Nase links) und wandelt es in eine Textur:
#   – Hülle: Gertler-Profil des Modells (radius_at), also L/D, Nasenradius usw.
#     genau wie im Simulator
#   – Flossen: aus ship.surfaces (Längslage hull_x, Umfangswinkel, Fläche,
#     Streckung). Sichtbar ist die Höhe span·|cos(Winkel)|; die Wurzel reicht bis
#     zur Mittellinie in die Hülle hinein → keine Lücke zur Hülle
#   – Motoren und Gondel als kleine dunkle Körper
#   – Aussehen: Silberfolie (Glanzverlauf mit Falten) oder Farbe aus der Livery
# Kein 3D-Rendering nötig, daher auch für lange Listen schnell.
# =============================================================================
class_name ShipPreview
extends RefCounted

## Gemerkte Vorschaubilder je Modellname und Größe (Listen bauen sich oft neu auf)
static var _cache := {}


## Vorschau eines Modells, das erst gebaut werden muss (build: Callable(ship)).
## Das Hilfs-Luftschiff wird danach wieder freigegeben.
static func texture_for_build(key: String, build: Callable, width_px: int) -> Texture2D:
	var ck := "%s_%d" % [key, width_px]
	if _cache.has(ck):
		return _cache[ck]
	var s := AirshipPhysics.new()
	build.call(s)
	var tex := texture(s, width_px)
	s.free()
	_cache[ck] = tex
	return tex


## Vorschau eines vorhandenen Luftschiffs (z. B. des gerade geflogenen).
static func texture(ship: AirshipPhysics, width_px: int, label := "") -> Texture2D:
	var img := Image.new()
	var svg_text := svg(ship, width_px, label)
	if img.load_svg_from_string(svg_text, 1.0) != OK:
		return null
	return ImageTexture.create_from_image(img)


## Das SVG selbst (Breite width_px, Höhe passend zur Form).
static func svg(ship: AirshipPhysics, width_px: int, label := "") -> String:
	var hull := ship.hull
	var Lm := hull.length_m
	var pad := width_px * 0.04
	var L := width_px - 2.0 * pad                     # Länge der Hülle in Pixeln
	var k := L / Lm                                    # Pixel je Meter
	# Höhe: größter Radius + längste Flosse oben/unten
	var fin_up := 0.0
	var fin_dn := 0.0
	for f in ship.surfaces:
		var c := cos(deg_to_rad(f.hull_angle_deg))
		var reach := (hull.radius_at(f.hull_x) + f.span_m() * absf(c)) * k
		if c > 0.01: fin_up = maxf(fin_up, reach)
		elif c < -0.01: fin_dn = maxf(fin_dn, reach)
	var R := hull.diameter_m * 0.5 * k
	var up := maxf(R, fin_up) + pad
	var dn := maxf(R * 1.12, fin_dn) + pad
	var H := up + dn
	var cy := up
	# --- Hüllenumriss aus dem Gertler-Profil ---
	var pts := PackedStringArray()
	var n := 80
	for i in n + 1:
		var x := float(i) / n
		pts.append("%.1f %.1f" % [pad + x * L, cy - hull.radius_at(x) * k])
	for i in range(n, -1, -1):
		var x := float(i) / n
		pts.append("%.1f %.1f" % [pad + x * L, cy + hull.radius_at(x) * k])
	var hp := "M" + " L".join(pts) + "Z"
	# --- Aussehen ---
	var mat_name: String = str(ship.livery.get("material")) if ship.livery.get("material") != null else "folie"
	var foil := mat_name == "folie"
	var hull_fill := "url(#hg)"
	if not foil:
		hull_fill = "#" + ship.livery.hull_color.to_html(false)
	var fin_fill := "#eef2f6"
	if ship.livery.get("fin_color") != null:
		fin_fill = "#" + (ship.livery.get("fin_color") as Color).to_html(false)
	var defs := ('<defs><linearGradient id="hg" gradientUnits="userSpaceOnUse" x1="0" y1="%.1f" x2="0" y2="%.1f">' % [cy - R, cy + R]
		+ '<stop offset="0" stop-color="#ffffff"/><stop offset=".25" stop-color="#cfd6de"/><stop offset=".42" stop-color="#f7f9fb"/>'
		+ '<stop offset=".62" stop-color="#9aa5b1"/><stop offset=".82" stop-color="#dfe5ea"/><stop offset="1" stop-color="#7d8794"/></linearGradient>'
		+ '<clipPath id="hc"><path d="%s"/></clipPath></defs>' % hp)
	# --- Flossen (hinter der Hülle: nach unten zeigende; vor der Hülle: nach oben) ---
	var back := ""
	var front := ""
	for f in ship.surfaces:
		var c := cos(deg_to_rad(f.hull_angle_deg))
		if absf(c) < 0.05:
			continue                                   # waagrechte Flosse: in der Seitenansicht nur ein Strich
		var span := f.span_m() * k
		var chord := sqrt(f.area_m2 / maxf(f.aspect_ratio, 0.1)) * k
		var xc := pad + f.hull_x * L
		var x0 := xc - chord * 0.5
		var x1 := xc + chord * 0.5
		var r0 := hull.radius_at(clampf((x0 - pad) / L, 0, 1)) * k
		var r1 := hull.radius_at(clampf((x1 - pad) / L, 0, 1)) * k
		var sgn := -1.0 if c > 0 else 1.0                # oben = negative SVG-y
		var h := absf(c)
		# Wurzel von der Mittellinie aus (steckt in der Hülle), Spitze leicht gepfeilt
		var path := "M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [
			x0, cy, x0, cy + sgn * r0 * h,
			x0 + chord * 0.35, cy + sgn * (r0 + span) * h,
			x1, cy + sgn * (r1 + span) * h, x1, cy]
		var el := '<path d="%s" fill="%s" stroke="#aab4be" stroke-width="0.6"/>' % [path, fin_fill]
		if c > 0: front += el
		else: back += el
	# --- Falten der Silberfolie ---
	var creases := ""
	if foil:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var m := int(L / 9.0)
		for i in m:
			var x := 0.04 + 0.92 * float(i) / m
			var r := hull.radius_at(x) * k
			var px := pad + x * L
			creases += '<path d="M%.1f %.1f q1 %.1f 0 %.1f" stroke="#ffffff" stroke-opacity=".5" stroke-width=".7" fill="none"/>' % [
				px, cy - r, r, 2.0 * r * rng.randf_range(0.5, 0.95)]
	# --- Motoren und Gondel (dunkel, unten an der Hülle) ---
	var parts := ""
	for mo in ship.motors:
		var mx := pad + mo.hull_x * L
		var my := cy - mo.position.y * k
		parts += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="2" fill="#2d3239"/>' % [mx - 0.02 * L, my - 0.01 * L, 0.04 * L, 0.02 * L]
	parts += '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="2" fill="#3a3f48"/>' % [
		pad + 0.43 * L, cy + hull.radius_at(0.46) * k - 0.012 * L, 0.065 * L, 0.024 * L]
	var txt := ""
	if label != "":
		txt = '<text x="%.1f" y="%.1f" font-size="%.1f" fill="#4c5560" font-family="sans-serif" letter-spacing="1">%s</text>' % [
			pad + 0.46 * L, cy + 0.01 * L, 0.028 * L, label.xml_escape()]
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %.1f">' % [width_px, int(H), width_px, H]
		+ defs + back + '<path d="%s" fill="%s" stroke="#8a949f" stroke-width="0.7"/>' % [hp, hull_fill]
		+ '<g clip-path="url(#hc)">' + creases + '</g>' + front + parts + txt + '</svg>')
