<!-- 2026-11-12 22:50 – Verweis auf docs/PROJEKTDOKU.md -->
# RC Airship Regatta

Open-Source-Simulator für DIY-Rennluftschiffe (Godot 4, Android/iOS/Desktop).
Baukasten mit Gertler-Hüllengenerator, 6-DOF-Physik mit Munk-Moment und
virtuellen Massen, virtueller Teensy-Flugcontroller, Modelle als Textstring teilbar.

## App öffnen

### Android – fertige APK (ohne PC)
GitHub baut bei jeder Änderung automatisch eine neue APK. Auf dem Handy im Browser öffnen:

**https://github.com/DerFink/AR-Airship-Regatta/releases/latest/download/ar-airship-regatta.apk**

Herunterladen, antippen, „Installation aus dieser Quelle erlauben“ bestätigen. Updates einfach drüber installieren.
(Debug-signiert: zum Ausprobieren gedacht, nicht für den Play Store.)

### Am PC (am schnellsten)
1. Godot **4.3** (Standard-Version, nicht .NET) von https://godotengine.org/download laden – eine Datei, keine Installation.
2. Diesen Ordner entpacken, Godot starten, **Importieren** → `project.godot` wählen → **Importieren und bearbeiten**.
3. **F5** drückt „Projekt starten“. Die Knüppel lassen sich mit der Maus bedienen.

### Android – selbst bauen (Alternative)
1. In Godot: *Editor → Export-Vorlagen verwalten → Herunterladen*.
2. Android-SDK und OpenJDK 17 installieren, Pfade in *Editor → Editoreinstellungen → Export → Android* eintragen (Godot erzeugt den Debug-Schlüssel selbst).
3. *Projekt → Exportieren → Hinzufügen → Android*.
4. Am Handy Entwickleroptionen + USB-Debugging aktivieren, per USB verbinden.
5. Oben rechts im Editor auf das Android-Symbol („Remote Debug“) – die App wird installiert und startet. Alternativ **Projekt exportieren** → APK.

### Auf dem iPhone
Export aus Godot als Xcode-Projekt, dann auf einem Mac in Xcode signieren (Apple-ID) und aufs Gerät spielen.

## Bedienung
- Linker Knüppel hoch/runter: **Gas** – Mitte = Stopp, unten = Rückwärtsschub (wenn im Baukasten erlaubt)
- Rechter Knüppel: hoch/runter **Nick**, links/rechts **Gier**
- Oben: Modi · Autopilot · Perspektive · Zurücksetzen · Arm-Schalter (Disarmed/Armed) · Menü (→ Modell & Bau)

## Modelle teilen
Baukasten → **Teilen** → *Kopieren*: Der String (`LTA1:Name:…:Prüfsumme`) enthält das komplette Modell.
Ein Logo wird **separat** als PNG mitgeschickt (Dateiname steht im Teilen-Dialog).

**Admin:** eingesandte Strings als neue Zeile in `models/sammlung.txt`, Logos nach `models/logos/`.
Nach dem nächsten Build stehen sie in jeder App in der Modellauswahl.

## Aussehen anpassen
Alle Farben, Abstände, Rundungen und Schriftgrößen stehen in `ui/theme_tokens.json`.

## Tests (ohne Grafik)
```
godot --headless --path . -s tests/smoke_test.gd
godot --headless --path . -s tests/chewie_test.gd
godot --headless --path . -s tests/v03_test.gd
godot --headless --path . -s tests/ui_test.gd
```

## Übersetzungen
Die Oberfläche gibt es in Deutsch, Englisch, Französisch, Spanisch, Italienisch, Tschechisch, Polnisch und Chinesisch (traditionell). Quelltexte im Code sind Deutsch.
- Kurze Texte: `tools/i18n_src/teil*.py` pflegen, dann `python3 tools/build_i18n_table.py` → `i18n/ui_texte.txt`
- Seite „Grundlagen“: `i18n/about_<sprache>.txt` (Reiter durch `@@@` getrennt)
- Prüfen, ob etwas fehlt: `python3 tools/check_i18n.py` (läuft auch bei jedem Build mit)
- Neue chinesische Zeichen: `python3 tools/make_cjk_font.py`

## Ordner
| Pfad | Inhalt |
| --- | --- |
| `*.gd` (Wurzel) | Physik, Hülle, Bauteile, Flugcontroller, Presets, Modell-String |
| `ui/` | Oberfläche und Design-System |
| `audio/` | Propellerklang, ruhige Baukasten-Töne (prozedural, keine Sounddateien) |
| `models/` | Modellsammlung des Admins |
| `i18n/` | Übersetzungen (Oberfläche und Seite „Grundlagen“) |
| `tools/` | Hilfsskripte (Übersetzungen, Schrift, Musik) |
| `tests/` | Headless-Tests |

## Für Entwickler
Was gebaut wurde, warum, wo es im Code steht und bekannte Fallen: **`docs/PROJEKTDOKU.md`**.

## Lizenz
MIT – siehe `LICENSE`. Eingesandte Logos bleiben Eigentum ihrer Urheber.

## Mit KI erstellt
Dieses Programm wurde nur dank KI erstellt: Code, Physikmodell und Texte sind im Dialog mit Claude (KI von Anthropic) entstanden. KI kann Fehler machen – bitte Ergebnisse prüfen, besonders exportierte Teensy-Sketche: vor dem Erstflug immer einen Bodentest mit abgenommenen Propellern machen.
