#!/usr/bin/env python3
# 2026-11-11 12:10 – Erstversion: erzeugt textures/aerarium_plakat.png (dunkles Plakat mit dem aerarium-Logo in Originalproportion) aus tools/aerarium_logo_quelle.png
# =============================================================================
# make_plakat.py
# -----------------------------------------------------------------------------
# Das Logo wird nie gestreckt: es behält sein Seitenverhältnis und bekommt
# rundum einen gleich breiten dunklen Rand. Weiß im Original wird durchsichtig,
# die blaue Logofarbe bleibt.
#   python3 tools/make_plakat.py
# =============================================================================
from PIL import Image
import numpy as np, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = (29, 31, 36)                         # Plakat-Hintergrund (dunkelgrau, wie im Entwurf)
src = Image.open(os.path.join(ROOT, "tools", "aerarium_logo_quelle.png")).convert("RGB")
a = np.asarray(src).astype(float)
# Deckkraft aus der „Nicht-Weiße“ des Pixels, Farbe = Logoblau
cover = np.clip((255.0 - a.min(axis=2)) / 255.0 * 1.6, 0, 1)
ys, xs = np.where(cover > 0.05)
box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)   # Logo eng ausschneiden
cover = cover[box[1]:box[3], box[0]:box[2]]
blue = np.array([37, 143, 190], float)
h, w = cover.shape
margin = int(0.12 * h)                    # gleich breiter Rand oben/unten/links/rechts
W, H = w + 2 * margin, h + 2 * margin
img = np.zeros((H, W, 3), float); img[:] = BG
sub = img[margin:margin + h, margin:margin + w]
sub[:] = sub * (1 - cover[..., None]) + blue * cover[..., None]
out = Image.fromarray(img.astype("uint8"))
# auf 1024 px Breite bringen (Seitenverhältnis bleibt)
out = out.resize((1024, round(1024 * H / W)), Image.LANCZOS)
out.save(os.path.join(ROOT, "textures", "aerarium_plakat.png"))
print("Plakat %d × %d px, Seitenverhältnis %.3f" % (out.width, out.height, out.width / out.height))
