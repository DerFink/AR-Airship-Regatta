#!/usr/bin/env python3
# 2026-11-10 20:10 – Erstversion: erzeugt fonts/cjk_tc_subset.otf – nur die chinesischen Zeichen, die in den Übersetzungen vorkommen
# Quelle: Noto Sans CJK TC (SIL Open Font License). Aufruf im Projektordner:
#   python3 tools/make_cjk_font.py [Pfad zur NotoSansCJK-Regular.ttc]
# Danach neu exportieren. Neue chinesische Texte → Skript erneut laufen lassen.
import re, sys, glob
from fontTools.ttLib import TTCollection
from fontTools import subset

src = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
text = ""
for f in ["i18n.gd"] + glob.glob("ui/*.gd") + glob.glob("docs/about/*.md"):
    try:
        text += open(f, encoding="utf-8").read()
    except OSError:
        pass
chars = sorted({c for c in text if ord(c) >= 0x2E80} | set("０１２３４５６７８９：，。（）、！？「」・"))
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
