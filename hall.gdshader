// 2026-11-10 14:00 – Erstversion: Muster der Halle (nachgebildet nach Fotos der Windreiter-Halle) für Wände und Glasdach
// =============================================================================
// hall.gdshader
// -----------------------------------------------------------------------------
// Zeichnet das Aussehen der Hallenflächen direkt in Metern, damit eine einzige
// Fläche je Wand reicht – egal wie groß die Halle ist.
//   kind = 0  Wand (von unten nach oben):
//             0 – 3,6 m   Glastüren mit Sprossen (Erdgeschoss)
//             3,6 – 4,2   Deckenkante
//             4,2 – 7,4   1. Galerie: dunkler Innenraum, Geländer
//             7,4 – 8,0   Deckenkante
//             8,0 – 11,2  2. Galerie mit Geländer
//             11,2 – 16,5 weiße Wand mit Lüftungsdüsen
//             16,5 – 20,5 Band mit blau-violetten Horizont-Wandbildern
//             darüber     weiß bis zum Dach
//             (die weißen Säulen sind eigene 3D-Körper, siehe course.gd)
//   kind = 1  Glasdach: Holzbalken-Raster (6 m) mit Glaspyramiden (Diagonalen)
// size_m = Breite und Höhe der Fläche in Metern (UV 0…1 → Meter)
// =============================================================================
shader_type spatial;
render_mode cull_back;

uniform vec2 size_m = vec2(40.0, 25.0);
uniform int kind = 0;

// Geländer: dünne senkrechte Stäbe und ein Handlauf (dunkelgrau)
float railing(vec2 m, float y0) {
	float h = m.y - y0;
	if (h < 0.0 || h > 1.05) return 0.0;
	float post = step(fract(m.x / 0.14), 0.12);          // Stäbe alle 14 cm
	float top = step(abs(h - 1.0), 0.04);                // Handlauf
	float bottom = step(abs(h - 0.08), 0.03);
	return max(max(post, top), bottom);
}

void fragment() {
	vec2 m = vec2(UV.x * size_m.x, (1.0 - UV.y) * size_m.y);   // Meter: x längs, y nach oben
	vec3 white = vec3(0.80, 0.80, 0.79);
	vec3 col = white;
	float rough = 0.75;
	float emit = 0.0;

	if (kind == 1) {
		// ---------------- Glasdach ----------------
		vec2 c = m / 6.0;
		vec2 f = fract(c);
		float beam = step(min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * 6.0, 0.18);   // Holzbalken 36 cm
		float diag = step(min(abs(f.x - f.y), abs(f.x + f.y - 1.0)) * 6.0, 0.05);      // Grate der Pyramiden
		float bar = step(min(fract(m.x / 1.5), fract(m.y / 1.5)) * 1.5, 0.04);        // feine Sprossen
		vec3 sky = mix(vec3(0.55, 0.75, 0.95), vec3(0.85, 0.93, 1.0), 0.5 + 0.5 * sin(m.x * 0.07 + m.y * 0.05));
		col = sky;
		emit = 0.55;
		col = mix(col, vec3(0.80, 0.82, 0.85), max(diag, bar * 0.7));
		col = mix(col, vec3(0.78, 0.58, 0.34), beam);                                    // Holz
		emit *= (1.0 - beam);
		rough = mix(0.1, 0.8, beam);
	} else {
		// ---------------- Wand ----------------
		float y = m.y;
		if (y < 3.6) {
			// Glastüren: Glas, Sprossen alle 1,5 m, Querholm bei 2,6 m
			col = mix(vec3(0.30, 0.37, 0.43), vec3(0.55, 0.66, 0.74), y / 3.6);
			float mull = step(fract(m.x / 1.5) * 1.5, 0.07) + step(abs(y - 2.6), 0.05);
			col = mix(col, vec3(0.20, 0.22, 0.25), clamp(mull, 0.0, 1.0));
			rough = 0.15;
		} else if (y < 4.2 || (y > 7.4 && y < 8.0)) {
			col = white;                                                                  // Deckenkanten
		} else if (y < 11.2) {
			// Galerien: dunkler Innenraum, oben etwas heller (Licht), Geländer
			float y0 = y < 7.4 ? 4.2 : 8.0;
			col = mix(vec3(0.42, 0.44, 0.47), vec3(0.70, 0.71, 0.72), clamp((y - y0) / 3.2, 0.0, 1.0));
			col = mix(col, vec3(0.32, 0.33, 0.35), railing(m, y0));
		} else if (y < 16.5) {
			col = white;
			// Reihe runder Lüftungsdüsen knapp unter den Wandbildern
			vec2 v = vec2(fract(m.x / 2.0) * 2.0 - 1.0, y - 15.7);
			col = mix(col, vec3(0.62, 0.64, 0.66), step(length(v), 0.16));
		} else if (y < 20.5) {
			// Wandbilder: 7 m breit, 1 m weißer Rahmen dazwischen
			float px = fract(m.x / 8.0) * 8.0;
			if (px > 0.5 && px < 7.5) {
				float t = (y - 16.5) / 4.0;                                               // 0 unten … 1 oben
				vec3 navy = vec3(0.08, 0.10, 0.36);
				vec3 blue = vec3(0.18, 0.28, 0.72);
				vec3 violet = vec3(0.42, 0.30, 0.62);
				vec3 glow = vec3(0.95, 0.88, 0.62);
				col = mix(navy, blue, smoothstep(0.0, 0.40, t));
				col = mix(col, glow, exp(-pow((t - 0.48) * 14.0, 2.0)));                  // heller Horizont
				col = mix(col, violet, smoothstep(0.55, 0.75, t));
				col = mix(col, vec3(0.12, 0.12, 0.45), smoothstep(0.80, 1.0, t));
				col *= 0.92 + 0.08 * sin(y * 40.0 + sin(m.x * 0.8) * 3.0);               // feine Pinselstreifen
				rough = 0.5;
			}
		}
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	EMISSION = col * emit;
}
