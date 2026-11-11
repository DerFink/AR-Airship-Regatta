# 2026-11-11 07:05 – Motoren als Flachmotor mit Servo (wie im 3D-Modell)
# 2026-11-11 01:20 – Flossen und Motoren genau aus den Modelldaten (Trapez wie im 3D-Modell: Wurzel-/Endtiefe aus Fläche, Streckung und Zuspitzung, Hinterkante gerade, Wurzel folgt der Hüllenkontur); Motoren mit Gondel und Propellerkreis an ihrer Einbaulage; Restmasse und Nutzlast; Material aus der Gestaltung; keine erfundene Gondel mehr
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
	# Motoren (mit Propellerkreis), Restmasse und Nutzlast können tiefer/höher reichen
	for mo in ship.motors:
		var pr := (mo.prop_diameter_in * 0.0254 * 0.5 + 0.01) * k
		fin_up = maxf(fin_up, mo.position.y * k + pr)
		fin_dn = maxf(fin_dn, -mo.position.y * k + pr)
	var kk0 := pow(maxf(ship.bottom_mass_kg, 0.001) / 2000.0 / 4.5, 1.0 / 3.0)
	fin_dn = maxf(fin_dn, (-ship.bottom_mass_pos.y + kk0) * k)
	if ship.payload_mass_kg > 0.0005:
		var e0 := pow(ship.payload_mass_kg / 1000.0, 1.0 / 3.0)
		fin_up = maxf(fin_up, (ship.payload_pos.y + e0) * k)
		fin_dn = maxf(fin_dn, (-ship.payload_pos.y + e0) * k)
	var up := maxf(R, fin_up) + pad
	var dn := maxf(R, fin_dn) + pad
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
	# --- Aussehen (Material aus der Gestaltung) ---
	var liv := ship.livery
	var foil := liv.material == "folie" or liv.material == "gold"
	var base := liv.base_color()
	var hull_fill := "url(#hg)" if foil else "#" + base.to_html(false)
	var fin_fill := "#" + liv.fin_base_color().to_html(false)
	var g0 := base.lightened(0.6)
	var g1 := base
	var g2 := base.darkened(0.3)
	var defs := ('<defs><linearGradient id="hg" gradientUnits="userSpaceOnUse" x1="0" y1="%.1f" x2="0" y2="%.1f">' % [cy - R, cy + R]
		+ '<stop offset="0" stop-color="#%s"/><stop offset=".25" stop-color="#%s"/><stop offset=".42" stop-color="#%s"/>' % [g0.to_html(false), g1.to_html(false), g0.to_html(false)]
		+ '<stop offset=".62" stop-color="#%s"/><stop offset=".82" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>' % [g2.to_html(false), g1.to_html(false), g2.darkened(0.15).to_html(false)]
		+ '<clipPath id="hc"><path d="%s"/></clipPath></defs>' % hp)
	# Körpersystem → Bild: z (Länge, −cb = Nase) → x nach rechts, y (oben) → nach oben
	var cb := hull.cb_from_nose
	var P := func(z: float, y: float) -> String:
		return "%.1f %.1f" % [pad + (z + cb) * k, cy - y * k]
	# --- Flossen: Trapez wie in AirshipVisual._fin_mesh ---
	# Von rechts gesehen liegen Flossen mit d.x < 0 hinter der Hülle, sonst davor.
	var back := ""
	var front := ""
	for f in ship.surfaces:
		var a := deg_to_rad(f.hull_angle_deg)
		var dy := cos(a)
		var dx := sin(a)
		var span := f.span_m()
		var mean_c := f.area_m2 / span
		var c_r := 2.0 * mean_c / (1.0 + f.taper)
		var c_t := c_r * f.taper
		var zc := f.hull_x * Lm - cb                       # Flossenmitte (Körper-z)
		var te := zc + c_r * 0.5                          # Hinterkante (gerade)
		var rc := hull.radius_at(f.hull_x)
		var el := ""
		if absf(dy) < 0.08:
			# waagrechte Flosse: von der Seite nur als Kante sichtbar
			el = '<path d="M%s L%s L%s L%s Z" fill="%s" stroke="#7f8a95" stroke-width="0.6"/>' % [
				P.call(te - c_r, 0.006), P.call(te, 0.006), P.call(te, -0.006), P.call(te - c_r, -0.006), fin_fill]
		else:
			var fp := PackedStringArray()
			for i in 7:                                   # Wurzel entlang der Hüllenkontur
				var z := lerpf(te - c_r, te, float(i) / 6.0)
				var xr := clampf((z + cb) / Lm, 0.0, 1.0)
				fp.append(P.call(z, dy * hull.radius_at(xr)))
			fp.append(P.call(te, dy * (rc + span)))       # Spitze hinten
			fp.append(P.call(te - c_t, dy * (rc + span))) # Spitze vorn
			el = '<path d="M%s Z" fill="%s" stroke="#7f8a95" stroke-width="0.6"/>' % [" L".join(fp), fin_fill]
		if dx < -0.05: back += el
		else: front += el
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
	# --- Motoren an ihrer Einbaulage: Gondel (wie im 3D-Modell 9 cm × Ø 5,5 cm)
	#     in Schubrichtung und Propellerkreis (Durchmesser aus den Daten) ---
	var parts := ""
	var parts_back := ""
	for mo in ship.motors:
		var td := mo.thrust_direction.normalized()
		var dir2 := Vector2(td.z, td.y)                   # Schubrichtung in der Seitenansicht
		if dir2.length() < 0.05: dir2 = Vector2(-1, 0)
		dir2 = dir2.normalized()
		var c := mo.position
		# Flachmotor wie im 3D-Modell: Glocke (Länge bh, Ø 2·br) vorn, Servo dahinter
		var br := clampf(mo.prop_diameter_in * 0.0029, 0.008, 0.04)
		var bh := br * 1.05
		var nrm := Vector2(-dir2.y, dir2.x)
		var c2 := Vector2(c.z, c.y)
		var q := [c2 + dir2 * bh + nrm * br, c2 + dir2 * bh - nrm * br, c2 - nrm * br * 1.2, c2 + nrm * br * 1.2]
		var qs := PackedStringArray()
		for v in q: qs.append(P.call(v.x, v.y))
		var body := '<path d="M%s Z" fill="#2d3239"/>' % " L".join(qs)
		if mo.max_swivel_deg > 0.0:
			var sv := [c2 - nrm * br * 0.95, c2 + nrm * br * 0.95, c2 - dir2 * br * 2.2 + nrm * br * 0.95, c2 - dir2 * br * 2.2 - nrm * br * 0.95]
			var ss := PackedStringArray()
			for v in sv: ss.append(P.call(v.x, v.y))
			body += '<path d="M%s Z" fill="#1f6fb5"/>' % " L".join(ss)
		var pr := mo.prop_diameter_in * 0.0254 * 0.5
		var pc := c2 + dir2 * (bh + br * 0.3)
		var prop := '<path d="M%s L%s" stroke="#2d3239" stroke-opacity=".55" stroke-width="%.1f" stroke-linecap="round"/>' % [
			P.call(pc.x + nrm.x * pr, pc.y + nrm.y * pr), P.call(pc.x - nrm.x * pr, pc.y - nrm.y * pr), maxf(1.0, 0.006 * k)]
		if c.x < -0.01: parts_back += body + prop
		else: parts += body + prop
	# --- Restmasse (Akku, Ballast, Elektronik) und Nutzlast ---
	var vol := maxf(ship.bottom_mass_kg, 0.001) / 2000.0
	var kk := pow(vol / 4.5, 1.0 / 3.0)
	var bp := ship.bottom_mass_pos
	parts += '<path d="M%s L%s L%s L%s Z" fill="#3a3f48"/>' % [P.call(bp.z - 1.5 * kk, bp.y), P.call(bp.z + 1.5 * kk, bp.y),
		P.call(bp.z + 1.5 * kk, bp.y - kk), P.call(bp.z - 1.5 * kk, bp.y - kk)]
	if ship.payload_mass_kg > 0.0005:
		var e := pow(ship.payload_mass_kg / 1000.0, 1.0 / 3.0)
		var pp := ship.payload_pos + Vector3(sin(deg_to_rad(ship.payload_angle_deg)), cos(deg_to_rad(ship.payload_angle_deg)), 0) * e * 0.5
		parts += '<path d="M%s L%s L%s L%s Z" fill="#e0a43a"/>' % [P.call(pp.z - e * 0.5, pp.y - e * 0.5), P.call(pp.z + e * 0.5, pp.y - e * 0.5),
			P.call(pp.z + e * 0.5, pp.y + e * 0.5), P.call(pp.z - e * 0.5, pp.y + e * 0.5)]
	var txt := ""
	if label != "":
		txt = '<text x="%.1f" y="%.1f" font-size="%.1f" fill="#4c5560" font-family="sans-serif" letter-spacing="1">%s</text>' % [
			pad + 0.46 * L, cy + 0.01 * L, 0.028 * L, label.xml_escape()]
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %.1f">' % [width_px, int(H), width_px, H]
		+ defs + back + parts_back + '<path d="%s" fill="%s" stroke="#8a949f" stroke-width="0.7"/>' % [hp, hull_fill]
		+ '<g clip-path="url(#hc)">' + creases + '</g>' + front + parts + txt + '</svg>')
