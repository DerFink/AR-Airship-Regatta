#!/usr/bin/env python3
# 2026-11-11 15:30 – Erstversion: baut i18n/ui_texte.txt aus tools/i18n_src/teil*.py und prüft jede Zeile (8 Spalten, gleiche %-Platzhalter, keine Doppelten)
# =============================================================================
# build_i18n_table.py
# -----------------------------------------------------------------------------
# Übersetzungen werden in tools/i18n_src/teilN.py gepflegt (Python-Listen sind
# leichter zu lesen und zu bearbeiten als eine Tabelle mit Tabulatoren).
#   python3 tools/build_i18n_table.py   → schreibt i18n/ui_texte.txt
# =============================================================================
import glob, os, re, runpy, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PH = re.compile(r"%(?:%|[-+ 0]*\d*(?:\.\d+)?[dfsx])")


def main():
    rows, seen, errors = [], {}, []
    for path in sorted(glob.glob(os.path.join(ROOT, "tools", "i18n_src", "teil*.py"))):
        for e in runpy.run_path(path)["E"]:
            name = os.path.basename(path)
            if len(e) != 8:
                errors.append("%s: %d statt 8 Spalten: %s" % (name, len(e), e[0][:50]))
                continue
            if e[0] in seen:
                errors.append("%s: doppelt (auch in %s): %s" % (name, seen[e[0]], e[0][:50]))
                continue
            seen[e[0]] = name
            want = sorted(PH.findall(e[0]))
            for col in e[1:]:
                if "\t" in col:
                    errors.append("%s: Tabulator im Text: %s" % (name, col[:50]))
                if sorted(PH.findall(col)) != want:
                    errors.append("%s: Platzhalter passen nicht: %r → %r" % (name, e[0][:40], col[:60]))
            rows.append(e)
    for err in errors:
        print("FEHLER", err)
    if errors:
        return 1
    os.makedirs(os.path.join(ROOT, "i18n"), exist_ok=True)
    out = os.path.join(ROOT, "i18n", "ui_texte.txt")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# Erzeugt von tools/build_i18n_table.py – nicht von Hand ändern, sondern tools/i18n_src/teil*.py\n")
        f.write("# de\ten\tfr\tes\tit\tcs\tpl\tzh_TW\n")
        for e in rows:
            f.write("\t".join(c.replace("\n", "\\n") for c in e) + "\n")
    print("%d Texte → %s" % (len(rows), os.path.relpath(out, ROOT)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
