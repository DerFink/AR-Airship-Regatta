<!-- 2026-11-12 22:45 – Erstversion: Projektdokumentation (was gebaut wurde, warum, wo im Code, bekannte Fallen, offene Punkte) – Stand 0.31.1 -->
# RC Airship Regatta – Projektdokumentation

**Stand:** 12.11.2026 · Version **0.31.1** (Android-Code 84) · Repository `DerFink/AR-Airship-Regatta` · Godot **4.3**

Diese Datei hält fest, **was** gebaut wurde, **warum** es so gebaut wurde und **wo** es im Code steht. Sie soll helfen, nach einer längeren Pause Fehler zu finden und weiterzuarbeiten, ohne die Vorgeschichte neu herausfinden zu müssen.

Ergänzende Dateien:
- `docs/chewie_regler_stand_2026-11-08.md` – Stand des echten Chewie-Reglers (Teensy-Code Beta 1.4) und der Physik-Annahmen.
- `server/ANLEITUNG.md` – Einrichtung der Website und Online-Bestenliste bei Strato.
- `docs/ideen.md` – nur notierte Ideen, nicht geplant.
- `README.md` – Kurzanleitung für Nutzer (App laden, Bedienung, Übersetzungen).

---

## 1. Worum es geht

Ein Open-Source-Simulator (MIT-Lizenz) für **DIY-Rennluftschiffe** (Prallluftschiffe mit Helium, Hallenrennen nach F7B-Reglement). Zielgruppe: Modellflieger und Maker. Läuft als Android-App, im Browser und am PC.

Kernteile:
- **6-DOF-Flugphysik** mit virtuellen Massen und Munk-Moment.
- **Baukasten**: Gertler-Hülle, Leitwerk, Motoren, Massen, Optik; Modelle als Text-String teilbar.
- **Virtueller Flugcontroller**, nachgebaut nach dem echten Teensy-Regler des Luftschiffs **Chewie** (dRehmFlight), dazu frei einstellbare Flugmodi.
- **Rennstrecke** (Acht um zwei Pylone, 3 Runden), Bestenliste lokal und online.
- Steuerung mit Bildschirmknüppeln, Tastatur oder echtem Sender (Taranis per USB).

Vorbild und Testfall ist **Chewie**, das echte Rennluftschiff des Projektinhabers (aerarium e.V.): 0,25 m³, L/D 6, λ-Leitwerk mit drei Pendelflossen, zwei schwenkbare Bugmotoren, Teensy 4.0 mit MPU-6050, Taranis X9D.

---

## 2. Feste Regeln (vom Projektinhaber vorgegeben)

Diese Regeln gelten für jede Änderung:

1. **Das Gas wird nie vom Regler verändert.** Der Pilot muss bei Gefahr (Menschen im Weg) sofort abschalten können. Deshalb gibt es **keinen Differenzschub** und keinen Regler am Gas, in keinem Modus.
2. **Änderungen an der .ino (echter Teensy) nur nach ausdrücklicher Freigabe.** Simulator-Erweiterungen werden erst im Simulator erprobt.
3. **Neue Funktionen, Änderungen und Darstellungen erst nach Freigabe**; Darstellungen vorher als Entwurfsbild zeigen.
4. **Erste Zeile jeder geänderten Datei:** Kommentar mit Zeitstempel und kurzer Änderungsliste (auch in der .ino). Code ausführlich kommentieren, damit klar ist, wofür jeder Abschnitt da ist.
5. **`server/rc-airship/config.php` niemals auf GitHub** (Datenbank-Zugang, Admin-Passwort).
6. Quelltexte der Oberfläche sind **Deutsch**; Übersetzungen kommen aus Tabellen (siehe Abschnitt 10).

---

## 3. Arbeitsablauf (Bauen, Testen, Veröffentlichen)

### Entwickeln
- Godot **4.3 Standard** (nicht .NET). Projekt: `project.godot`.
- Nach neuen Klassen (`class_name`): einmal `godot --headless --editor --quit --path .` (Klassen-Cache).
- Tests ohne Grafik: `godot --headless --path . -s tests/<name>.gd`. Tests drucken `ENDE` am Schluss.
- Screenshots ohne Bildschirm: `xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . -s <skript>`.

### Version erhöhen (bei jeder Auslieferung)
1. `build_info.gd`: `const VERSION := "0.x.y"`.
2. `export_presets.cfg`: `version/code` (+1) und `version/name` – in beiden Presets.
3. Erste-Zeile-Kommentare in den geänderten Dateien.
4. Commit-Nachricht: `0.x.y: Kurzbeschreibung` + Liste der Änderungen.

### CI (GitHub Actions, `.github/workflows/android.yml`)
Bei jedem Push auf `main`:
1. **i18n**-Job: `tools/check_i18n.py` (läuft separat, weil im Godot-Container kein Python ist).
2. **android**-Job: Import, Headless-Tests, APK, Browser-Version, Paket für Strato, Release `android-build-<Laufnummer>` mit `ar-airship-regatta.apk` und `rc-airship-web.zip`.
3. **web**-Job: Browser-Version auf GitHub Pages.
4. **strato**-Job: nur, wenn die Repository-Variable `STRATO_UPLOAD = ja` gesetzt ist (Upload per SFTP, Secrets `STRATO_SFTP_HOST/USER/PASS`).

Die Tests in der CI: `smoke_test chewie_test v03_test tail_test airship_mode_test maneuver_test course_test ui_test menu_test i18n_test crash_test stickmode_test leaderboard_test modes_test`. (`menu_test.gd` gibt es nicht mehr – der Eintrag läuft ins Leere, ohne die CI zu stoppen; bei Gelegenheit aus der Liste nehmen.)
- Ein Test gilt als bestanden, wenn er bis `ENDE` lief – Godot 4.3 hängt headless manchmal beim Beenden.
- Fehlschlag = `SCRIPT ERROR` oder `Parse Error` in der Ausgabe.
- Die CI läuft **ohne feste Bildrate**: Tests, die Zeit messen, zählen Physikschritte (`_physics_process`), nicht Bilder.

### Wo die App liegt
- APK: `https://github.com/DerFink/AR-Airship-Regatta/releases/latest/download/ar-airship-regatta.apk`
- Browser: GitHub Pages; geplant `https://flinkfink.de/rc-airship/` (Strato, siehe `server/ANLEITUNG.md`).

---

## 4. Aufbau des Codes

Szene: `main.tscn` mit `main.gd` als Wurzel. Darunter Halle/Wiese, Strecke, das Luftschiff (`AirshipPhysics`, darin `AirshipVisual`, `FlightController`, `BoxGauge`) und eine UI-Ebene mit allen Fenstern. `main.gd` schaltet die Ansichten (`View`: START, HUB, FLY, BUILD, PID, SHARE, LEADER, ABOUT, SETTINGS) und verbindet die Signale.

| Datei | Aufgabe |
|---|---|
| `airship_physics.gd` | 6-DOF-Physik (eigener Integrator), Massen/Schwerpunkt/Trägheit, Aufprall und Platzen |
| `gertler_hull.gd` | Hüllenform nach Gertler (DTMB Series 58), Volumen, Oberfläche, virtuelle Massen k1/k2 |
| `control_surface.gd` | eine Flosse/Canard: Auftrieb (Helmbold, Profil, Reynolds), Ruderklappe/Pendel, Gewichtsvorschlag |
| `tail_config.gd` | symmetrisches Leitwerk (+, ×, Y, λ, gleichmäßig 2–10) bzw. Flossen einzeln |
| `tail_validator.gd` | Leitwerksgrößen-Check (Leitwerksvolumen V_H, Stabilitätsmaß, Warnbanner) |
| `vector_motor.gd` | Motor mit Schwenk, Schub, Propeller, Rückwärtsschub, Hochlaufzeit |
| `battery.gd` | Akku-Modell (Spannung unter Last, Kapazität, leer = Motoren aus) |
| `flight_controller.gd` | virtueller Flugcontroller: Teensy-Regler, Flugmodi, Mischer, Sprung, Signalfluss-Abfrage |
| `fc_blocks.gd` | Bausteine des Reglers (an/aus) |
| `ino_export.gd` | Teensy-Sketch (.ino) aus dem Modell erzeugen (Vorlage `ino/chewie_beta_1_4.ino.txt`) |
| `joystick_input.gd` | Sender per USB: Kalibrierung, Kanalzuordnung, Schalter SF/SC/SH |
| `airship_presets.gd` | Standardmodelle (Chewie, Albacore Standard), Hilfsfunktionen `make_fin`, `make_motor` |
| `model_codec.gd` | Modell-String (Export/Import), lesbare Eckdaten, Fingerabdruck |
| `model_library.gd` | Modellsammlung (Admin `models/sammlung.txt`, eigene `user://meine_modelle.txt`) |
| `airship_visual.gd` | 3D-Darstellung (Hülle, Flossen mit Klappe, Motoren, Restmasse, Akku, Platzen) |
| `livery.gd`, `livery_canvas.gd` | Optik: Farben, Material, Schriftzug, Logo (auch aufs Leitwerk) |
| `box_gauge.gd` | Boxmaß-Ecke im Baukasten (durchsichtige Wände, Maßzahlen) |
| `course.gd`, `course_track.gd` | Strecke (Acht, Kontrollpunkte, Runden, F7B-Wertung), Bodenspur |
| `autopilot.gd` | Demo-Flug |
| `leaderboard.gd`, `leaderboard_online.gd` | Bestenliste lokal (Quartal, Best Forever) und online |
| `app_settings.gd`, `i18n.gd`, `updater.gd`, `performance_watchdog.gd`, `ar_toggle.gd` | Einstellungen, Sprache, Update-Suche, FPS-Wächter, AR-Schalter |
| `ui/*.gd` | alle Fenster; Design-System `ui/ui_theme.gd` + `ui/theme_tokens.json` |
| `audio/` | Propellerklang (synthetisch), Werkstatt-Töne/Musik |
| `server/rc-airship/` | PHP-Schnittstelle der Online-Bestenliste, Admin-Seite |
| `tools/` | Übersetzungen, Schrift-Teilmenge, QR-Code, Rennoptimierung (`race_opt.gd`), `export_server_models.gd` |
| `tests/` | Headless-Tests |

---

## 5. Physik – was gerechnet wird und warum

**Eigener Integrator** (`custom_integrator`): Godots RigidBody3D kennt nur eine Masse für alle Richtungen. Ein Luftschiff schiebt quer viel mehr Luft mit als längs (virtuelle Massen, ATTAS-Ansatz). Godot übernimmt deshalb nur die Kollisionen; die Bewegung rechnet `airship_physics.gd` selbst:

```
(m + Ma)·a = F + Ma·(ω × v) − ω × (Ma·v)
(I + Ia)·ω̇ = T − ω × ((I + Ia)·ω) − v × (Ma·v)      ← letzter Term = Munk-Moment
```
Körpersystem: Ursprung im Auftriebszentrum, −Z = Nase, +Y = oben, +X = rechts.

Annahmen, die nötig waren, damit der Simulator wie der echte Chewie fliegt (Details in `chewie_regler_stand_…md`):
- **Munk-Moment × 0,6** (`munk_factor`): die Grenzschicht am Heck mindert es. Mit 1,0 schwang Chewie mit den echten Reglerwerten ±20° in Nick.
- **Flossen an der Hülle:** wirksame Streckung doppelt (Hülle wirkt als Spiegelwand), Rumpf-Flossen-Interferenz 1,3. Sonst lief Chewie nicht geradeaus.
- **Flossenprofile:** Platte oder NACA 00xx, Abriss und Widerstand abhängig von der **Reynoldszahl je Flosse** (nicht pauschal 10⁵).
- **Schwenk entlang der Hülle** erzeugt beim Gieren ein Rollmoment – Ursache für Rollen in Kurven; deshalb die Gierschwenk-Rücknahme mit dem Gas (Abschnitt 6).

**Massen** (seit 0.29, Wunsch des Projektinhabers):
- **Hülle** wird berechnet: Oberfläche × Folie (Standard **27 g/m²**) × 1,07 (2 % Nähte + 5 % Ränder und Ventil). Chewie: 2,74 m² → 79 g.
- **Flossen/Canards:** Vorschlag = Depron **120 g/m²** (Brettchen 1 Lage, profiliert 2 Lagen) + Pauschale 2–5 g für Servo/Anlenkung/Versteifung (linear 150–600 cm²). Ein eingetragenes eigenes Gewicht ersetzt den Vorschlag; der Vorschlag bleibt ausgegraut sichtbar.
- **Restmasse** (Akku + Ballast) gleicht automatisch aus, sodass das Schiff etwas schwerer als der Auftrieb ist (`trim_heaviness_n`) und waagrecht hängt. Der Akku kann eine **eigene Lage** bekommen.
- Bug-/Hecklastigkeit wird im Baukasten als Pendeln und ab 2° als roter Hinweis gezeigt.

**Aufprall und Platzen** (0.22, 0.28.1): Das Schiff prallt wie ein Ball ab. Ab **20 km/h Fahrt** (pauschal, egal aus welcher Richtung) platzt die Hülle – **Grundregel, nicht abschaltbar**. Die Nähte laufen längs; die Hülle reißt am Heck, eine Druckwelle läuft nach hinten, die Hülle fällt vom Heck zur Nase zusammen. `repair()` macht sie beim Wechsel in Baukasten/Menüs wieder heil.

**Akku:** 4S 300 mAh (Chewie), Spannung unter Last mit Innenwiderstand, Schub ∝ (V/V0)². Leer = keine Motoren.

---

## 6. Flugcontroller

### 6.1 Chewie-Regler (Teensy-Nachbau)
`flight_controller.gd` rechnet wie Chewies Teensy-Code (dRehmFlight, Beta 1.3/1.4), damit Einstellungen zwischen Simulator und Luftschiff übertragbar sind: gleiche Namen, Einheiten und Werte (`Kp_m2`, `tail_pitch_gain_m2`, Einbauwinkel 60°/300°/180° …). Regelarten:
- **Direkt** (Teensy Mode 1): Knüppel über den Mischer, kein Regler.
- **Angle** (Mode 2): Nick und Roll in der Lage geregelt (Nick-Sollwinkel ±30°), Gier direkt.
- **Horizon** (Mode 3): wie Angle, Höhenknüppel = Nickrate, Gier als PID-Drehratenregler (max. 110 °/s).

Simulator-Erweiterungen (teilweise in die .ino Beta 1.4 übernommen, siehe Regler-Stand): Nick-Schutz ab maxPitch, Gierschwenk-Rücknahme ab 22 % Gas, Expo am Seitenknüppel, Vorlauf-Grenze nur bei bewegtem Knüppel.

### 6.2 Eigene Flugmodi (seit 0.31)
- 1–5 Modi, Standard **2 (Direkt + Angle)**; gespeichert in `user://flight_controller.cfg`, Abschnitt `[modi]`.
- Jeder Modus: Name, **Art** `direkt` / `angle` / `horizon` / `pid`, **Rollausgleich** an/aus, bei Direkt optional eigene Mischtabelle.
- Art `pid`: je Achse geregelt ja/nein, **Lage oder Drehrate** (Gier nur Drehrate), eigene Kp/Ki/Kd und Sollwert bei vollem Knüppel. Ausgang = 0,01·(Kp·e + Ki·∫e − Kd·D), dann Rollausgleich, dann Mischtabelle.
- `mode` (Regelart) und `mode_index` (Modus des Piloten) sind getrennt: Der Demo-Flug setzt die Regelart direkt; `mode_cfg()` liefert dann `{}`.
- **Sender:** Der Modus-Kanal (Standard SC) wird in so viele gleich große Bereiche geteilt, wie Modi angelegt sind. Ab 4 Modi braucht man einen Mehrstufen-Schalter oder Drehregler.

### 6.3 Rollausgleich
Wunsch: Bei 90° Rollen ist aus dem Seitenruder ein Höhenruder geworden; derselbe Seitenausschlag würde das Schiff nicken lassen (sichtbar in engen, schnellen Kurven). Lösung `roll_rotate()`: Höhen- und Seitenbefehl werden mit dem Rollwinkel gedreht (wie die Stabilisierung im Teensy-Code mit „Einbauwinkel n + Rollwinkel“). Bei 90° übernimmt das Höhenleitwerk die Seite und umgekehrt. Geprüft: 90° gerollt, Seite rechts → mit Ausgleich dreht das Schiff nach rechts, ohne Ausgleich nickt es und dreht falsch. Braucht den Lagesensor (IMU MPU-6050), wirkt also nur mit eingebautem FC.

### 6.4 Mischer
- **Nach Einbaulage** (automatisch, wie Teensy `mixServosDirect`): `_mix_direct()`; Vorzeichen jeder Flosse werden einmal aus der Geometrie bestimmt (`_calibrate()`), am echten Modell per Bodentest.
- **Von Hand** (seit 0.30): Tabelle Ausgang × (Nick, Gier, Roll) in % des Vollausschlags (`ship.mix_table`, Schlüssel `s<i>` = Fläche, `m<i>` = Motorschwenker). „Vorschlag aus Einbaulage“ fragt den automatischen Mischer mit vollen Knüppeln ab (`suggest_mix()`). Passt die Tabelle nicht mehr zu den Bauteilen, gilt wieder der automatische Mischer.
- Ohne eingebauten FC gibt es nur Direkt.

### 6.5 Werkzeuge im Reglermenü
- **Sprung auslösen** (`trigger_step`): verschiebt den Sollwert einer Achse für 3 s; Kennwerte Anstieg/Überschwingen/Einschwingzeit und Fahrt beim Auslösen. Nur im Flug sinnvoll (ohne Fahrt wirken die Ruder kaum).
- **Signalfluss** (`ui/signal_flow.gd`): `probe_outputs()` rechnet einen Reglerschritt mit einem Impuls, ohne den Zustand zu verändern (Integrale, Befehle, Modus werden zurückgesetzt; `_quiet` verhindert Signale, die sonst das Menü neu aufbauen würden).

### 6.6 Teensy-Sketch
`ino_export.gd` erzeugt aus dem Modell eine .ino auf Basis von `ino/chewie_beta_1_4.ino.txt` (Mischer, Servo-Ausgänge, optional Kanalzuordnung). Seit 0.30 nur noch unter „Admin“ im Reiter Steuerung. **Kennt nur Direkt/Angle/Horizon** – eigene PID-Modi werden noch nicht exportiert. Vor dem Erstflug immer Bodentest ohne Propeller.

---

## 7. Eingabe

### Stickmodes (Nomenklatur heli-planet.com)
`STICK_LAYOUT` = Funktion auf [links waagrecht, links senkrecht, rechts waagrecht, rechts senkrecht]:
- Mode 1: Gier, Nick | Rolle, Gas
- Mode 2: Gier, Gas | Rolle, Nick
- Mode 3: Rolle, Nick | Gier, Gas
- **Mode 4 (Standard): Rolle, Gas | Gier, Nick**

Sender, Tastatur und Demo liefern **Funktionen** (`set_stick_functions`); die Bildschirmknüppel zeigen sie je nach Stickmode an.

**Fallstrick – Speicherstand der Stickmodes** (`stick_nomenklatur` in der cfg):
- < 2: alte Nummerierung (2 = Gas links → Mode 4, 1 → Mode 3).
- < 4: einmalig Mode 4 (0.23–0.25: Sender hatte über die Menünavigation Mode 1 gewählt).
- 4 und Mode 1: einmalig Mode 4 (0.26.0 schrieb den alten Rohwert 1 zurück).
- 5: aktueller Stand.
Der Nutzer hatte noch „Mode 3“ aus der Zeit vor der Umstellung gespeichert – „Gas rechts“ war deshalb kein Programmfehler. Abhilfe: Baukasten → **Zurücksetzen** (Knüppelbelegung) oder Kalibrierfenster.

### Sender (Taranis per USB)
- Gerätesuche nach Namen (FrSky, EdgeTX …) bzw. meisten ausgelenkten Achsen; alle 0,5 s neu (Browser meldet Geräte erst nach Bewegung).
- Schalter: **SF oben = scharf**, SC = Modus, **SH (Kanal 7) oben = Zurücksetzen**.
- Kalibrierung (Min/Mitte/Max, Umkehr, Kanalzuordnung mit „Anlernen“) in `user://sender_kalibrierung.cfg`.
- Sender bedient keine Menüs (Joypad aus allen `ui_*`-Aktionen entfernt), sonst wählte er versehentlich Mode 1.
- Failsafe: Sender weg → Motoren aus; App im Hintergrund → Motoren aus.

---

## 8. Baukasten und Modell-String

- Baukasten öffnet mit **Hülle**; Zahlenfelder mit −/+ (`ui/number_field.gd`), Schieberegler nur für **Lagen**. Kleinere Schrift (`UITheme.compact_theme()`).
- Reiter: Hülle (Name, Beschreibung, Form, Massen) · Leitwerk (Anordnung, 2–10 Flossen, Bauart, Klappentiefe, Flossen einzeln, Profil, Gewicht) · Antrieb (Akku, Motorpaare, schwenkbar per Haken, Abstand zur Hülle, Propeller in Zoll/cm/mm ab 2 cm) · Steuerung (Mischer, FC einbauen, Regler, Bausteine, Admin) · Optik.
- **Zurücksetzen** (seit 0.29.1): Luftschiff, Regler, Sender, Knüppelbelegung + Strecke einzeln wählbar; Bestenliste, eigene Modelle, Sprache bleiben.
- **Modell-String** `LTA1:Name:<Base64(Deflate(JSON))>:<Prüfsumme>`. Seit 0.30 stehen davor **lesbare Eckdaten**; `decode()` beginnt beim letzten `LTA1:`. Logos werden separat als PNG verschickt.
- `_sanitize()` prüft und begrenzt jeden Wert (fremde Strings sind ungeprüfte Eingaben).
- **Fingerabdruck** (`fingerprint()`): Bauart ohne Name und Optik. Nur unveränderte Standardmodelle kommen in die Online-Bestenliste. **Nach jeder Änderung an Physik-Feldern oder Presets** `tools/export_server_models.gd` laufen lassen (aktualisiert `server/rc-airship/models.json`); der `leaderboard_test` schlägt sonst fehl.
- Admin-Sammlung: String als Zeile in `models/sammlung.txt` (Zeile `# Autor: … | Team: … | Beschreibung: …` darüber), Logo nach `models/logos/`.

---

## 9. Rennen und Bestenliste

- Strecke **FN Hugo Eckener Cup**: Acht um zwei Pylone im Abstand **18 m** (`CUP_DISTANCE`); daneben „frei“ mit eigenem Abstand (5–500 m, Location Halle oder Wiese), 3 Runden, fliegender Start, Kontrollpunkte (falsche Pylonseite = ungültig).
- **F7B-Wertung:** `gewertet = gemessen × ∛(L·B·H·π/6)` mit dem Boxmaß über alles (Flossen, Motoren, Akku zählen mit). Der **Rennfaktor** steht in der Modellliste und bei den Kennwerten. Sortiert wird nach gewerteter Zeit, damit kleine, langsamere Schiffe eine Chance haben.
- **Lokal** (`leaderboard.gd`, `user://bestenliste.json`): 100 Plätze je Strecke und Quartal; zum Quartalsende kommen die 10 Besten nach „Best Forever“.
- **Online** (`leaderboard_online.gd` → `https://flinkfink.de/rc-airship/api.php`): PHP 8 + MySQL bei Strato. Der Server rechnet die gewertete Zeit selbst, prüft Fingerabdruck, Rundenzeiten (≥ 2 s, Summe passt) und begrenzt Einträge je Stunde; IP nur als gesalzener Kurzwert. `admin.php`: Einträge/Piloten löschen (Passwort, CSRF). Ohne Netz zeigt die App die Liste des Geräts.
- **Stand Online-Stellen:** vorbereitet, aber **noch nicht hochgeladen** (Schritte in `server/ANLEITUNG.md`). Vorher Impressum und Datenschutz für flinkfink.de.

---

## 10. Oberfläche, Sprachen, Schrift

- Design-System: `ui/theme_tokens.json` (Farben, Abstände, Schriftgrößen) → `UITheme.build_theme()`. Hauptknöpfe mit `make_primary_button()` (fett, blauer Rand).
- **8 Sprachen** (de, en, fr, es, it, cs, pl, zh_TW). Ablauf: `tools/i18n_src/teil*.py` pflegen → `python3 tools/build_i18n_table.py` → `i18n/ui_texte.txt`; prüfen mit `python3 tools/check_i18n.py`. Seite „Grundlagen“: `i18n/about_<sprache>.txt`, Reiter durch `@@@` getrennt.
- Texte mit Zahlen: `I18n.t("… %d …") % wert`, Dezimalkomma mit `I18n.dec()`.
- Chinesische Schrift ist eine Teilmenge: nach neuen Texten `python3 tools/make_cjk_font.py`, dann Godot-Import und `tools/check_glyphs.gd`. **Fehlende Zeichen** (z. B. ⚙ ⟳ ∛) zeigen Kästchen → SVG-Symbole bzw. `^(1/3)` verwenden.
- Sprache beim ersten Start vom Gerät/Browser.

---

## 11. Ton

- Propellerklang synthetisch (`audio/`), im Browser als vorberechnete Schleifen.
- **Browser-Eigenheit:** Godot 4.3 spielt im Web „Samples“ und ignoriert dort spätere Lautstärkeänderungen → keine Überblendungen im Browser. `default_bus_layout.tres` muss die Busse beim Start bereitstellen; `output_latency.web = 80`.
- Werkstatt-Musik überall außer im Flug, Musik −26 dB.

---

## 12. Bekannte Fallen bei der Fehlersuche

| Erscheinung | Ursache / Abhilfe |
|---|---|
| Nach Tests `corrupted size vs prev_size` / Abbruch beim Beenden | Godot 4.3 headless, harmlos |
| Test misst andere Zeiten in der CI | CI ohne `--fixed-fps`: in `_physics_process` zählen |
| `Parse Error … function signature doesn't match the parent` | eigene Methode heißt wie eine Godot-Methode (`_get`, `_set`) → umbenennen |
| `Cannot infer the type` | `:=` bei untypisierten Werten → Typ angeben (`var x: int = …`) |
| Lambda mit Standardwert per `Callable.call()` mit weniger Argumenten | alle Argumente übergeben |
| Fenster zu groß nach Neuaufbau | `queue_free()` zählt noch mit → vorher `remove_child()` |
| Neue Klasse unbekannt | `godot --headless --editor --quit` (Klassen-Cache) |
| `leaderboard_test`: models.json veraltet | `tools/export_server_models.gd` ausführen |
| Gas rechts / falscher Stickmode | alter Speicherstand (Abschnitt 7), Zurücksetzen |
| Sender steuert nicht | Kalibrierung/Umkehr/Zuordnung prüfen (Werkseinstellung der Kalibrierung löscht auch die Umkehr) |
| Kalibrierung im Browser weg | Browser-Speicher nicht dauerhaft (`OS.is_userfs_persistent()`), Hinweis erscheint |
| Lautstärke im Browser ändert sich nicht | Web-Samples (Abschnitt 11) |
| Gespeicherte Einstellungen | `user://flight_controller.cfg` (Regler, Modi, Stickmode), `einstellungen.cfg`, `sender_kalibrierung.cfg`, `bausteine.cfg`, `strecke.cfg`, `akku.cfg`, `sprache.cfg`, `bestenliste.json`, `meine_modelle.txt`, `logos/` |
| Regler-Einstellungen nach Update „weg“ | `SETTINGS_VERSION` erhöht → alte Werte werden absichtlich nicht übernommen |

---

## 13. Verlauf (Kurzfassung mit Gründen)

| Datum | Versionen | Was und warum |
|---|---|---|
| 27.10. | 0.3–0.4 | Erster Simulator: Physik, Baukasten, FC, Klang, Modell-Strings, Android-Build. Chewie als Startmodell mit echten Daten (λ 19×19 cm, GEPRC 1804, 4"). Nick-Knüppel wie am RC-Sender. Pilotensicht vom festen Standort. |
| 28.10. | 0.5–0.7 | Strecke FN Hugo Eckener Cup, Acht mit Kontrollpunkten, Rundenzeiten. PID-Vorgaben je Modell. |
| 29.10. | 0.8–0.9 | Bestenliste, Nick-Schutz, Kaskadenregler-Versuche (später verworfen). **Kein Differenzschub** (Sicherheit). |
| 07.11. | 0.9.6–0.10 | **Regler 1:1 aus Chewies Teensy-Code** statt eigener Regler – damit Werte übertragbar sind. Munk 0,6, Flossen-Interferenz 1,3, Schwenk entlang der Hülle. Browser-Version. |
| 08.11. | 0.10.1–0.11 | Taranis per USB (SF/SC/SH), Expo, Gierschwenk-Rücknahme ab 22 % Gas (Wenderadius ≤ 2 m, kein Umkippen). Chewie 260 g. Rennoptimierung `race_opt.gd`. |
| 09.11. | 0.11.2–0.13 | Demo-Flug, Halle mit Wänden, Sender kalibrieren, Nick-Schutz (kein Hochbäumen auf 60°), Mode 3 Gier als PID. |
| 10.11. | 0.13.4–0.19 | Halle nachgebildet, Akku-Modell, neuer Name **RC Airship Regatta**, Startseite, Modell & Bau, Sprachen-Grundlagen, Regler-Bausteine, .ino-Export, Werkstatt-Musik. |
| 11.11. | 0.20–0.28 | Flossenprofile + Reynolds, **8 Sprachen**, Plakate, Aufprall/Platzen, **Stickmode 1–4 (Standard 4)**, Rennanzeige mit F7B, neue Startseite, Bestenliste nach gewerteter Zeit, Flugmodi Direkt · Angle · Horizon, Trimm-Anzeige, Online-Bestenliste vorbereitet. |
| 12.11. | 0.28.1–0.31.1 | Platzen fest ab 20 km/h; Baukasten mit Zahlenfeldern, berechnete Massen, Rennfaktor, Weiterfliegen; Zurücksetzen; Reiter Steuerung mit Mischer von Hand; lesbarer Export; **frei einstellbare Flugmodi (1–5)**, Rollausgleich, Sprung auslösen, interaktiver Signalfluss, Flossen einzeln, kleinere Schrift. |

Die vollständige Liste steht im Git-Verlauf (`git log`); jede Datei hat in den ersten Zeilen ihre eigene Änderungschronik.

### Verworfene Ansätze (damit sie nicht erneut versucht werden)
- **Eigene Reglerarten** „Geregelt“, „Luftschiff“, „Gedämpft“ und Kaskadenregler in Erdachsen (0.5–0.9.5): ersetzt durch den Teensy-Nachbau, weil Simulator und echtes Schiff dieselben Werte brauchen.
- **Differenzschub** für Gier: ausgeschlossen (Gas nur beim Piloten).
- **Acro-Modus:** schwer umzusetzen, weil man dem Pendelmoment aktiv entgegenwirken müsste.
- **Pauschale Reynoldszahl 10⁵:** ersetzt durch Re je Flosse.
- **Platzen abschaltbar / einstellbare Grenze:** ersetzt durch feste 20 km/h.

---

## 14. Offene Punkte (Stand 12.11.2026)

**Zu prüfen / Rückmeldung des Projektinhabers ausstehend**
- Build 104 (0.31.1) testen: Flugmodi, Rollausgleich, Signalfluss, Flossen einzeln, Mischer von Hand.
- Sender steuert nicht (nach „Werkseinstellung“ der Kalibrierung): nach Zurücksetzen + neuer Kalibrierung prüfen.
- Echte Flossengröße von Chewie (Höhe × Tiefe) – Darstellung „Faktor 10 zu klein?“ prüfen (Simulator: 361 cm² je Flosse ≈ 19 × 19 cm).
- Kalibrierung bleibt im Browser nach Abstecken erhalten?

**Entscheidungen offen**
- Admin-Knopf „Teensy-Sketch erzeugen“ mit Code schützen oder nur Hinweis?
- Lizenzdateien (GPL/OFL-Texte für Schriften), Profil-Diagramm, Chewie-Flossengewicht, variable Modi in der .ino.

**Aufgaben**
- Online-Stellen auf flinkfink.de (SSL, MySQL, Upload, `config.php`, Admin-Passwort-Hash), dazu **Impressum und Datenschutz**.
- **paypal.me**-Name anlegen (bisher Spenden-Link mit E-Mail) und QR-Code neu erzeugen (`tools/make_support_qr.py`).
- .ino-Export für eigene PID-Modi und Rollausgleich (erst nach Freigabe).
- Physik-Abgleich mit dem echten Chewie (aus dem Regler-Stand): Gasverhalten (echter Chewie agiler), Rollen bei ~30 % Gas bis 40° (echt < 10°), Weiterdrehen nach Loslassen bei 60 % Schub.
- Ideen: Location „Aerarium“ mit autonomen Fisch-Luftschiffen (`docs/ideen.md`), In-App-Abfrage bei neuer Version, Besucherstatistik.
