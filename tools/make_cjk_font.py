#!/usr/bin/env python3
# 2026-11-11 15:50 – Auch die Übersetzungsdateien i18n/*.txt (Oberfläche und Seite „Grundlagen“)
# 2026-11-11 00:30 – Auch Symbole, die der Standardschrift fehlen (Pfeile, ●, ✓, ▶, ▾, ₀₁₂, ∝ …), aus allen .gd-Dateien
# 2026-11-10 20:10 – Erstversion: erzeugt fonts/cjk_tc_subset.otf – nur die chinesischen Zeichen, die in den Übersetzungen vorkommen
# Quelle: Noto Sans CJK TC (SIL Open Font License). Aufruf im Projektordner:
#   python3 tools/make_cjk_font.py [Pfad zur NotoSansCJK-Regular.ttc]
# Danach neu exportieren. Neue chinesische Texte → Skript erneut laufen lassen.
import re, sys, glob
from fontTools.ttLib import TTCollection
from fontTools import subset

src = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
text = ""
for f in glob.glob("*.gd") + glob.glob("ui/*.gd") + glob.glob("docs/about/*.md") + glob.glob("i18n/*.txt"):
    try:
        text += open(f, encoding="utf-8").read()
    except OSError:
        pass
# Symbole: Pfeile, Formen, Häkchen, tiefgestellte Ziffern, Mathematik (fehlen in Godots Standardschrift)
SYM = lambda c: 0x2070 <= ord(c) <= 0x209F or 0x2190 <= ord(c) <= 0x22FF or 0x2500 <= ord(c) <= 0x27BF
chars = sorted({c for c in text if ord(c) >= 0x2E80 or SYM(c)} | set("０１２３４５６７８９：，。（）、！？「」・"))
coll = TTCollection(src)
font = None
for f in coll.fonts:
    name = f["name"].getDebugName(1) or ""
    if name.endswith("CJK TC"):
        font = f
        break
font = font or coll.fonts[0]
opts = subset.Options()
opts.layout_features = ["*"]
sub = subset.Subsetter(opts)
sub.populate(text="".join(chars))
sub.subset(font)
font.save("fonts/cjk_tc_subset.otf")
print("Zeichen:", len(chars), "→ fonts/cjk_tc_subset.otf")
