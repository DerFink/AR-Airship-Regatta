#!/usr/bin/env python3
# 2026-11-11 14:30 – Erstversion: meldet sichtbare deutsche Texte im Code, die noch keine Übersetzung haben
# =============================================================================
# check_i18n.py
# -----------------------------------------------------------------------------
# Sucht in allen .gd-Dateien nach Texten in Anführungszeichen, die nach
# Anzeige-Text aussehen (Wörter, Leerzeichen, Umlaute), und vergleicht sie mit
# den Übersetzungstabellen (i18n.gd und i18n/ui_texte.txt).
#   python3 tools/check_i18n.py            → Liste der fehlenden Texte, Exit 0
#   python3 tools/check_i18n.py --strict   → Exit 1, wenn etwas fehlt (CI)
#   python3 tools/check_i18n.py --list     → alle gefundenen Texte (Datei<TAB>Text)
# Falsch erkannte Texte (Code, Dateinamen …) kommen in tools/i18n_ignore.txt.
# =============================================================================
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Dateien, deren Texte nie angezeigt werden (Testskripte, Werkzeuge)
SKIP_DIRS = {"tests", "tools", ".godot", "addons", "ino", "docs"}
# Texte im Sketch-Generator: nur die Hinweise sind Anzeige-Text, der Rest ist C++
LIT = re.compile(r'(?<![\w&])"((?:[^"\\\n]|\\.)*)"')
WORD = re.compile(r"[A-Za-zÄÖÜäöüß]{3,}")


def load_known():
    """Alle deutschen Quelltexte, für die es eine Übersetzung gibt."""
    known = set()
    src = open(os.path.join(ROOT, "i18n.gd"), encoding="utf-8").read()
    body = src.split("const TEXTS := {", 1)[1].split("\n}\n", 1)[0]
    for m in re.finditer(r'^\t"((?:[^"\\]|\\.)*)":', body, re.M):
        known.add(m.group(1).encode().decode("unicode_escape").encode("latin1").decode("utf-8"))
    path = os.path.join(ROOT, "i18n", "ui_texte.txt")
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if line.startswith("#") or "\t" not in line:
                continue
            known.add(line.split("\t", 1)[0].replace("\\n", "\n"))
    return known


def load_ignore():
    p = os.path.join(ROOT, "tools", "i18n_ignore.txt")
    if not os.path.exists(p):
        return set()
    return {l.rstrip("\n").replace("\\n", "\n") for l in open(p, encoding="utf-8") if l.strip() and not l.startswith("#")}


def looks_like_text(s: str) -> bool:
    """Grobe Erkennung von Anzeige-Text (lieber zu viel als zu wenig)."""
    if not WORD.search(s):
        return False
    if s.startswith(("res://", "user://", "http", "#", "%s_", "ui_")):
        return False
    if re.fullmatch(r"[a-z0-9_./:\-]+", s):          # Bezeichner, Pfade, Schlüssel
        return False
    if re.fullmatch(r"[A-Za-z0-9_]+", s) and not re.search(r"[ÄÖÜäöüß]", s) and s[0].islower():
        return False
    if re.search(r"//|\w\*\w|_command_scaled", s):                   # C++-Zeilen des Sketches
        return False
    if re.search(r"[;{}]\s*$|^\s*(void|float|int|const|#define|if \(|for \()", s):  # C++-Schnipsel
        return False
    return True


def scan():
    found = []
    for dp, dn, fn in os.walk(ROOT):
        dn[:] = [d for d in dn if d not in SKIP_DIRS and not d.startswith(".")]
        for f in sorted(fn):
            if not f.endswith(".gd"):
                continue
            rel = os.path.relpath(os.path.join(dp, f), ROOT)
            if rel in ("i18n.gd",):
                continue
            for line in open(os.path.join(dp, f), encoding="utf-8"):
                code = line.split(" #", 1)[0] if not line.lstrip().startswith("#") else ""
                if "push_warning" in code or "print(" in code or "push_error" in code:
                    continue
                for m in LIT.finditer(code):
                    s = m.group(1).replace('\\"', '"').replace("\\n", "\n").replace("\\t", "\t")
                    if looks_like_text(s):
                        found.append((rel, s))
    return found


def main():
    found = scan()
    if "--list" in sys.argv:
        for rel, s in found:
            print("%s\t%s" % (rel, s.replace("\n", "\\n")))
        return 0
    known, ign = load_known(), load_ignore()
    seen, missing = set(), []
    for rel, s in found:
        if s in known or s in ign or s in seen:
            continue
        seen.add(s)
        missing.append((rel, s))
    for rel, s in missing:
        print("FEHLT  %-28s %s" % (rel, s.replace("\n", "\\n")))
    print("%d Texte ohne Übersetzung" % len(missing))
    return 1 if missing and "--strict" in sys.argv else 0


if __name__ == "__main__":
    sys.exit(main())
