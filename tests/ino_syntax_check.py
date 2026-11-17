#!/usr/bin/env python3
# 2026-11-17 20:45 – Erstversion: erzeugten Teensy-Sketch mit g++ auf Syntax und Typen prüfen (Arduino-Ersatzköpfe in tests/ino_stub)
# =============================================================================
# Die Arduino-IDE schreibt vor dem Übersetzen für jede Funktion eine Vorab-
# Deklaration (Prototyp) an den Anfang. Das macht dieses Skript nach und lässt
# dann g++ mit -fsyntax-only laufen. Teensy-Bibliotheken (Wire, SBUS, MPU6050 …)
# sind durch leere Ersatzklassen in tests/ino_stub ersetzt – geprüft wird also
# nur, ob der Code des Sketches selbst fehlerfrei ist, nicht die Hardware.
#   python3 tests/ino_syntax_check.py <sketch.ino> [weitere …]
# Ausgabe je Datei „OK“ oder die Fehlermeldungen; Rückgabe 1 bei Fehlern.
# =============================================================================
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
STUB = os.path.join(HERE, "ino_stub")

# Funktionskopf am Zeilenanfang: Rückgabetyp, Name, (Parameter) und „{“ (auch in der nächsten Zeile)
HEAD = re.compile(r"^((?:static\s+|inline\s+)*(?:unsigned\s+|signed\s+|const\s+)*[A-Za-z_][\w:<>]*[\s\*&]+)([A-Za-z_]\w*)\s*\(([^;{}]*)\)\s*(\{|$)", re.M)
KEYWORDS = {"if", "for", "while", "switch", "return", "else", "do", "sizeof"}


def prototypes(src: str) -> str:
    out = []
    for m in HEAD.finditer(src):
        rtype, name, args, brace = m.group(1).strip(), m.group(2), m.group(3), m.group(4)
        if name in KEYWORDS or rtype.split()[-1] in KEYWORDS or name in ("setup", "loop"):
            continue
        if brace == "":
            # „{“ steht in der nächsten Zeile?
            rest = src[m.end():m.end() + 40].lstrip()
            if not rest.startswith("{"):
                continue
        args = re.sub(r"\s+", " ", args)
        out.append(f"{rtype} {name}({args});")
    return "\n".join(dict.fromkeys(out))


def check(path: str) -> bool:
    src = open(path, encoding="utf-8", errors="replace").read().replace("\r\n", "\n")
    protos = prototypes(src)
    # Prototypen vor die erste Funktion setzen (nach allen globalen Variablen davor
    # wäre zu spät für Aufrufe in setup(); die IDE setzt sie ebenfalls dorthin)
    first = re.search(r"^void setup\(\)", src, re.M)
    pos = first.start() if first else 0
    code = src[:pos] + "\n// --- Prototypen (wie die Arduino-IDE) ---\n" + protos + "\n" + src[pos:]
    with tempfile.NamedTemporaryFile("w", suffix=".cpp", delete=False, encoding="utf-8") as t:
        t.write(code)
        tmp = t.name
    r = subprocess.run(["g++", "-std=gnu++17", "-fsyntax-only", "-Wno-narrowing", "-I", STUB,
                        "-include", os.path.join(STUB, "Arduino.h"), "-x", "c++", tmp],
                       capture_output=True, text=True)
    os.unlink(tmp)
    errs = [l for l in r.stderr.splitlines() if " error: " in l]
    if errs:
        print(f"FEHLER {path}:")
        for l in errs[:25]:
            print("  " + l.split(".cpp:", 1)[-1])
        return False
    print(f"OK {path}")
    return True


if __name__ == "__main__":
    ok = all([check(p) for p in sys.argv[1:]])
    sys.exit(0 if ok else 1)
