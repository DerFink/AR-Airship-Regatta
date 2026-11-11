#!/usr/bin/env python3
# 2026-11-11 17:40 – Erstversion: QR-Code für „Support“ (PayPal) als textures/support_qr.png
# =============================================================================
# make_support_qr.py
# -----------------------------------------------------------------------------
# Erzeugt den QR-Code mit dem Link aus support.gd (SUPPORT_URL). Nach jeder
# Änderung des Links einmal ausführen:
#   python3 tools/make_support_qr.py
# QR-Encoder: tools/qrcodegen.py (Project Nayuki, MIT-Lizenz).
# =============================================================================
import os, re, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qrcodegen import QrCode

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(ROOT, "ui", "support_popup.gd"), encoding="utf-8").read()
url = re.search(r'const SUPPORT_URL := "([^"]+)"', src).group(1)
qr = QrCode.encode_text(url, QrCode.Ecc.MEDIUM)
border, scale = 2, 10
n = qr.get_size() + 2 * border
img = Image.new("L", (n * scale, n * scale), 255)
px = img.load()
for y in range(qr.get_size()):
    for x in range(qr.get_size()):
        if qr.get_module(x, y):
            for dy in range(scale):
                for dx in range(scale):
                    px[(x + border) * scale + dx, (y + border) * scale + dy] = 0
img.save(os.path.join(ROOT, "textures", "support_qr.png"))
print("QR %d×%d Module für %s" % (qr.get_size(), qr.get_size(), url))
