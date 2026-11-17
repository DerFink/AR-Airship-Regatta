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
| `airship_presets.gd` | Standardmodelle (Chewie, Albacore), Hilfsfunktionen `make_fin`, `make_motor` |
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
- `mode` (Regelart) und `mode_index` (Modus des Piloten) sind getrennt; `mode_cfg()` liefert `{}`, wenn die Regelart von außen gesetzt wurde.
- **Demo-Flug (seit 0.32)** fliegt im gewählten Modus des Piloten (vorher fest Mode 3). Ohne Nick-Lageregelung (Direkt, ohne FC, PID ohne Nick-Lage) hält `autopilot.gd/_pilot_pitch()` die Nicklage selbst wie ein Pilot (KP 0,08 Knüppel/°, KD 0,015 Knüppel/(°/s); KD 0,005 platzte). In Direkt wird der Seitenknüppel auf 30 % begrenzt (sonst verliert die Demo die Bahn). Neue PID-Modi haben eine Gier-Sollrate von **150 °/s** (110 °/s reichte für die enge Acht nicht, 250 °/s platzte). Gemessene Demo-Zeiten Chewie: Direkt 14,4 s · Angle 15,6 s · Horizon 16,1 s · PID 17,9 s.
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
- **Einzelmotor und Canard-Paare** (seit 0.33): Antrieb hat „+ Motorpaar“ und „+ Einzelmotor“ (mittig, Lage oben / unten / Heck; Heck = Längsachse an der Heckspitze wie bei der Albacore). Canards: „+ Canard-Paar“ (rechts 90° / links 270°, gleiche `pair_id`, alle Werte gelten für beide, Winkel gespiegelt) und „+ Einzel-Canard“ (oben); Streckung und Pfeilung je Canard einstellbar. `pair_id` der Canards steht nur bei Paaren im Modell-String (`"p"`), damit ältere Fingerabdrücke gleich bleiben.
- **Testmodelle** (seit 0.32): erscheinen nur, wenn in den Einstellungen 7× auf die Versionsnummer getippt und „Testmodelle zeigen“ eingeschaltet wurde (`AppSettings.show_test_models`, `[entwicklung]`). Quelle „Test“ – nie in Bestenliste und `models.json`. **Chewie27** = Chewie, wie bis 11.11. gerechnet: Hülle fest 85 g (Folienwert wird passend gerechnet), Flossen je 10 g von Hand, Wunsch-Flugmodus Horizon (Meta `mode_art`, `main.gd/_apply_model_mode()` wählt bzw. ergänzt den Modus).
- Admin-Sammlung: String als Zeile in `models/sammlung.txt` (Zeile `# Autor: … | Team: … | Beschreibung: …` darüber), Logo nach `models/logos/`.

---

## 9. Rennen und Bestenliste

- Strecke **FN Hugo Eckener Cup**: Acht um zwei Pylone im Abstand **18 m** (`CUP_DISTANCE`); daneben „frei“ mit eigenem Abstand (5–500 m, Location Halle oder Wiese), 3 Runden, fliegender Start, Kontrollpunkte (falsche Pylonseite = ungültig).
- **F7B-Wertung:** `L_ref = ∛(L·B·H·π/6)`, `gewertet = gemessen × √(L_ref / 1 m)` (bis 1.0.0 fälschlich `× L_ref`) mit dem Boxmaß über alles (Flossen, Motoren, Akku zählen mit). Der **Rennfaktor** steht in der Modellliste und bei den Kennwerten. Sortiert wird nach gewerteter Zeit, damit kleine, langsamere Schiffe eine Chance haben.
- **Lokal** (`leaderboard.gd`, `user://bestenliste.json`): 100 Plätze je Strecke und Quartal; zum Quartalsende kommen die 10 Besten nach „Best Forever“.
- **Online** (`leaderboard_online.gd` → `https://flinkfink.de/rc-airship/api.php`): PHP 8 + MySQL bei Strato. Der Server rechnet die gewertete Zeit selbst, prüft Fingerabdruck, Rundenzeiten (≥ 2 s, Summe passt) und begrenzt Einträge je Stunde; IP nur als gesalzener Kurzwert. `admin.php`: Einträge/Piloten löschen (Passwort, CSRF). Ohne Netz zeigt die App die Liste des Geräts.
- **Einwilligung (seit 0.34):** Online eingetragen wird nur nach Zustimmung im Fenster `ui/consent_dialog.gd` (Text mit dem Betreiber abgestimmt, `LeaderboardOnline.CONSENT_TEXT`). Fassung `CONSENT_VERSION` = 1 in App **und** `lib.php` – bei Textänderung beide erhöhen, dann fragt die App neu. „Nur auf diesem Gerät“ schaltet das Online-Eintragen aus. Einstellungen → „Online-Bestenliste“: Schalter (aus = Widerruf) und „Meine Online-Einträge löschen“ (über zufällige Geräte-Kennung, auf dem Server nur gesalzen/gekürzt). Speicherdauer **2 Jahre** (`KEEP_DAYS`, automatisch in `cleanup()`).
- **Besucherzähler:** `api.php?action=hit` bei jedem Start (nicht in Tests); Tabelle `hits` nur mit Tag, Plattform, Anzahl. Anzeige in `admin.php`.
- **Sicherheit:** Admin-Anmeldung 15 min gesperrt nach 5 Fehlversuchen (Tabelle `login_fail`); `display_errors` aus; `Options -Indexes`. `einrichtung.php` legt `config.php` im Browser an (prüft die Datenbank, speichert nur den Passwort-Hash) und ist danach gesperrt.
- **Impressum/Datenschutz:** `server/rc-airship/impressum.html`, `datenschutz.html`; verlinkt auf der Startseite (unten rechts), in den Einstellungen und im Einwilligungsfenster. PayPal: `paypal.me/LuftschiffFink`.
- **Stand Online-Stellen:** alles vorbereitet; Schritte für Strato und WinSCP in `server/ANLEITUNG.md`.

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
| 14.11. | 0.32.0 | Demo fliegt im eingestellten Flugmodus (auch Direkt, mit eigener Nick-Haltung); Gier-Sollrate neuer PID-Modi 150 °/s; verstecktes Testmodell Chewie27 (alter Chewie, Horizon). |
| 14.11. | 0.33.0 | Einzelmotor (oben/unten/Heck); Canards mit Streckung und Pfeilung, symmetrische Canard-Paare und Einzel-Canards. |
| 14.11. | 0.33.1 | Fehler: Motor/Canard ließ sich nach Import nicht mehr öffnen (Eintrag blieb markiert, item_selected feuerte nicht) → Listen reagieren auf jedes Antippen (item_clicked). |
| 14.11. | 0.34.0 | Online-Gang vorbereitet: Einwilligung vor dem ersten Online-Eintrag, eigene Einträge löschen, 2 Jahre Speicherdauer, Besucherzähler im Admin, Login-Sperre, Einrichtungsseite, Impressum und Datenschutz (Links in der App), PayPal paypal.me/LuftschiffFink. |
| 15.11. | 0.34.1 | Fehler: Sender steuerte nicht (Schalter gingen). Ursache: Tasten werden direkt abgefragt; ein „w“/„s“/Pfeil – auch beim Tippen von Namen – schaltete dauerhaft auf Tastatur. Jetzt nur in der Flugansicht ohne Textfeld-Fokus, und Bewegung am Sender gibt die Steuerung zurück. |
| 15.11. | 0.35.0 | Vollbild-Knopf (Startseite oben rechts und Flugansicht; Browser außer iPhone, PC); obere Knopfreihe im Flug verkleinert sich, wenn sie nicht passt. |
| 15.11. | 0.35.1 | Fehler grünes Flackern (Browser, Handy stark): Hallenboden lag nur 4 mm über dem Gras → Z-Fighting. Gras in der Halle jetzt 20 cm tiefer, Kamera near 0,1 m. Erster Build mit automatischem Upload nach flinkfink.de. |
| 15.11. | 0.36.0 | Browser-Ton: Standard „Säuseln“ (nur Rauschschleife, `PropSound.whisper`, Stufe 0), als Strom gemischt (Web-Audio-Samples ignorieren Lautstärke/Tonhöhe); Tonpuffer 150 ms statt 80 ms; Einstellung „Motorklang fein“ (nur Browser). Ursache des abgehackten Tons: Browser-Version ohne Threads mischt im Bildtakt. |
| 15.11. | 0.36.1 | Säuseln höher (Tonhöhe 1,2–2,6) und deutlich lauter (×4, bis +9 dB). |
| 15.11. | 0.37.0 | Neue Halle nach Foto: Glasdach 18 m (heller), Säulenreihe 10 m hinter der Feldlinie (fest, dunkler Bodenstrich), dahinter rundum 5 m tiefe Laufgänge auf zwei Ebenen (0–5, 5–10 m; Zwischendecke und Glasgeländer 1,1 m fest), darüber geschlossene Wand mit Wandbildern und großen Plakaten; kleine Plakate an den Glastüren der Außenwand. Knopf „Aus ‚Eigene‘ löschen“ (zweimal tippen). Zuletzt benutztes Luftschiff wird gespeichert (`user://aktuelles_modell.txt`) und beim Start geladen – vorher war nach Neuladen immer Chewie da. |
| 15.11. | 0.37.1 | Baukasten rechts: Knopf „In ‚Eigene‘ speichern“ über Einstellungen; Kennwerte scrollen, damit die Knöpfe auf niedrigen Bildschirmen sichtbar bleiben. |
| 16.11. | 0.38.0 | Bestenliste nur noch online (keine Liste auf dem Gerät, kein „Liste löschen“; nur der Name wird gemerkt); Hinweise, warum eine Zeit nicht eingetragen wurde; Einwilligung „Nicht eintragen“. Vorschaubilder (Modell & Bau, Startseite) als echtes 3D-Bild wie auf dem Flugfeld (`ui/ship_render3d.gd`, SubViewport je Modell, gemerkt je Modell-Code). |
| 16.11. | 0.38.1 | Sammlung: Modell „Example“ (0,10 m³, L/D 4,5, 4 Flossen ×, 2 Motoren) fest aufgenommen; Fingerabdruck in `models.json` (Bestenliste). |
| 16.11. | 0.38.2 | Bestenliste nur mit Standard-Pylonabstand (Halle Cup 18 m, Wiese 200 m; `Course.is_ranked()`, Server nimmt nur `cup`/`wiese_200.0`): Hinweis vor dem Start, unter dem Pylonabstand und im Ziel. Zurücksetzen: „Strecke“ eigener Punkt (vorausgewählt), Knüppelbelegung getrennt. „Keine Verbindung“ zeigt die Ursache in Klammern (Fehlersuche). |
| 16.11. | 0.38.3 | Sammlung: Modell „Picard“ (eingesandt als „Chewie“, umbenannt, damit es nicht mit dem Standard-Chewie verwechselt wird; 0,25 m³, L/D 6, Kreuzleitwerk 4 × 361 cm², 2 feste Motoren, Teensy-FC). |
| 16.11. | 0.38.4 | Fehler: Pylonabstand zurück auf 18 m blieb „frei“ (keine Wertung) → 18 m in der Halle schaltet wieder auf den Cup. Knopf „Szenario zurücksetzen“ in Modell & Bau über dem Pylonabstand. |
| 16.11. | 0.38.5 | Fehler „8/200“ im Browser: Strato packt JSON mit gzip, der Browser entpackt, Godot versuchte es nochmal (BODY_DECOMPRESS_FAILED) – Zeiten waren gespeichert, die App meldete „nicht eingetragen“ und die Liste kam nie. `accept_gzip = false` in `leaderboard_online.gd` (Updater im Browser ebenso), `.htaccess` packt JSON nicht mehr. |
| 16.11. | 0.39.0 | Sammlung: „Velocita“ (eingesandt als „Velocita - Nachempfunden von Erich“; Name gekürzt, Rest als Beschreibung). Auswahl ohne „(Sammlung)“ im Namen, feste Reihenfolge `AirshipPresets.ORDER`: Picard, Velocita, Schubi, Chewie, Example, Albacore; eigene Modelle danach. |
| 16.11. | 0.39.1 | „Albacore“ heißt jetzt „Albacore“ (Auswahl, Standardname, Über-Texte, models.json). |
| 16.11. | 0.40.0 | Physik: Wirbelauftrieb bei kleiner Streckung (Polhamus, `ControlSurface.vortex_weight()`: voll bei wirksamer Streckung ≤ 1, aus ab 4) und späterer Abriss (+25° bei kleiner Streckung). Beispiel Depron-Flosse Streckung 0,8: bei 20° ≈ +40 %, bei 30° ≈ +50 % Kraft, Höchstauftrieb ≈ 1,4 bei 35°. Neue PID-Modi halten jetzt auch die Rolllage (sonst kippte Chewie in der Demo in der engen Kurve weg). Demo-Zeiten Chewie: Direkt 14,3 s, Angle 15,4 s, Horizon 16,0 s, PID 18,6 s; Albacore Direkt 22,4 s. Wertung vorher/nachher nicht ganz vergleichbar. |
| 16.11. | 0.41.0 | Findings 16.11.: Sender-Kalibrierung mit Wahl „Gas Mitte = Stopp (mit Rückwärts)“ / „Unten = Stopp (ohne Rückwärts)“ und Knopf „Nullpunkte übernehmen“ (mit ✓-Rückmeldung); Logogröße bis 1,5; Rundenanzeige ohne dunklen Kasten (weiße Schrift mit Schatten); Flugspur 5 cm über dem Boden; ohne FC werden Regler-Modi (Angle/Horizon/PID) in der Flugansicht ausgeblendet; Sprungantwort über Prüfstand (`StepBench`: Kopie des Schiffs fliegt unsichtbar 2 s geradeaus mit 60 % Gas, dann Sprung 3 s – vorher blieb die Ist-Linie flach, weil das Schiff im Menü stillstand); Baukasten rechte Spalte nach Skizze: Name und Kurzbeschreibung oben (antippen = ändern), Volumen mit Maßen, Rennfaktor F7B, Kasten „Massen“ (Hülle, LTW n × g, Antrieb n × g, … Trimm), Modellauswahl und „Kennwerte“ entfernt, Knöpfe kleiner. |
| 16.11. | 0.41.1 | Schubi in der Sammlung (Reihenfolge Picard, Velocita, Schubi, Chewie, Example, Albacore); models.json für die Bestenliste aktualisiert. |
| 16.11. | 0.42.0 | Menüs deutlich flacher: Knöpfe/Felder 32 statt 52 px (`UITheme.MENU_HEIGHT`, `menu_height()`), wenig Innenabstand, Schieberegler einzeilig; Flugansicht-Knöpfe bleiben groß. Mischer mit Flugmodi ohne Regler: Anzahl Flugmodi, Name, eigene Tabelle je Direkt-Modus (erster Direkt-Modus = Grundtabelle), Regler-Modi ausgegraut. Antrieb aus Datenblatt: Stator, kV, Propeller, Zellen → Drehzahl und Standschub (`VectorMotor.estimate`: n = 0,8·kV·4,2 V·Zellen, T = Ct·ρ·n²·D⁴, Ct ≈ (0,07 + 0,09·P/D)·(Blätter/2)^0,6); kV 0 = Schub von Hand wie bisher. Chewie: 1804 2450 kV, HQProp T4×2×3 → ≈ 5,8 N statt 7 N je Motor, ≈ 32 900 U/min – Chewie-Zeiten vorher/nachher nicht vergleichbar; models.json neu. |
| 16.11. | 0.42.1 | Wiese (outdoor): Vorgabe-Pylonabstand 100 m statt 200 m; gewertet wird nur noch `wiese_100.0` (App und api.php); wer noch auf der alten Vorgabe 200 m stand, wird einmalig auf 100 m umgestellt. |
| 16.11. | 0.42.2 | Startseite „Support me“; Browser-Update: Prüfabfrage ohne gzip (lud vorher nie neu); PID-Werte bis 10; Sprungantwort: Prüfstand fliegt weiter bis Menü zu, weitere Sprünge in die laufende Antwort, jede Änderung (Werte, Modus, Achse, Sprunghöhe) startet nach 0,4 s von vorn (`FlightController.settings_saved`), Plot 8 s; „Modell & Bau“: Knopf „Auf Werkseinstellung zurücksetzen“ mit Hinweis bei abweichendem geladenem Modell (z. B. altes Chewie mit 7 N); Picard mit Chewie-Motoren (1804 2450 kV, T4×2×3), models.json neu. |
| 16.11. | 0.42.3 | Tastatur: Gas läuft ohne W/S langsam auf 0 zurück (0,3 je Sekunde, Vollgas → 0 in gut 3 s; Nick/Gier 4 je Sekunde); X setzt weiter sofort auf 0. |
| 16.11. | 0.42.4 | Handy-Browser: Textfelder (z. B. Pilotenname nach dem Rennen) öffnen das Eingabefenster des Browsers (`WebTextInput`, window.prompt) – die Bildschirmtastatur von Godot erschien im Browser nicht. |
| 16.11. | 0.42.5 | Antrieb: kV bis 50 000 (z. B. BetaFPV 1102 mit 22 000 kV), Drehzahl bis 200 000 U/min; Lastdrehzahl hängt von der Statorgröße ab (`VectorMotor.load_factor`: 1804 → 0,80, 1102 → ≈ 0,59; abgeglichen an 1102 22 000 kV, 1S, 40-mm-Dreiblatt ≈ 45 g). Chewie unverändert (≈ 5,8 N). |
| 16.11. | 0.42.6 | Antrieb: Stator-Feld ohne grauen Platzhalter (wirkte gesperrt); neue Motorpaare/Einzelmotoren übernehmen Stator, kV, Propeller und Masse des ersten Motors mit kV-Angabe; neues Paar öffnet gleich im Editor. |
| 16.11. | 0.43.0 | Mischer: Schub je Motor (Zeile „Schub …“: Gas/Nick/Gier/Roll in % des Vollschubs, Tabellenschlüssel `t<i>`, Motor je Modus aus = `x<i>`; `FlightController.motor_throttle`), z. B. Drehen/Seitwärts mit Schub oder senkrecht hoch mit 4 Motoren – nur aus den Knüppeln des Piloten, der Regler ändert den Schub nie (Regel „kein Differenzschub“ für den Simulator auf Wunsch aufgehoben, echter Chewie/.ino unverändert); alle Modi im Mischer wählbar (Regler-Modus ohne FC → Direkt, mit FC per Knopf); Tabelle waagrecht scrollbar, lange Texte umbrechen. |
| 16.11. | 0.44.0 | Komplexe Modelle: Geber S1–S4 (freie Senderkanäle mit eigenem Namen in der Kalibrierung, „–“ = nicht belegt; ohne Sender Tasten Q/E und Z/C oder Schieber am rechten Rand, nur sichtbar, wenn der Modus den Geber nutzt). Mischer: Spalte Grundstellung und Spalten S1…S4 für Ruder, Schwenker und Schub (`e<Ausgang>` = [Grundstellung, S1…S4]); Desaturierung je Gruppe (alle Motoren bzw. alle Schwenker mit gemeinsamem Faktor, Grundstellung bleibt, Verhältnisse bleiben). Neuer Test `geber_test`. |
| 16.11. | 0.44.1 | Mischer-Findings: Modusname wird beim Tippen übernommen (Knopf zeigt ihn sofort); Tabelle in jedem Modus bearbeitbar – die erste Änderung legt die eigene Tabelle des Modus an; ohne FC wird die Modusart nicht mehr umgestellt (Modi gelten für alle Luftschiffe), jeder Modus fliegt dann manuell mit seiner Tabelle; Flugansicht zeigt ohne FC wieder alle Modi. |
| 16.11. | 0.45.0 | Flugmodi je Luftschiff (`ship.flight_modes`, im Modell-String unter `modes`, nicht im Fingerabdruck; Regler arbeitet über `adopt_ship_modes` direkt auf der Liste). Reiter Steuerung: Abschnitt „Flugmodi“ – Anzahl 1–5, FC eingebaut, je Modus Name und „gesteuert über“ Mischer/FC mit FC-Art (Angle/Horizon/PID); Vorschlag für neue Modelle Direkt/Angle/Horizon, Chewie behält Direkt/Angle; Mischer-Fenster ohne Anzahl/Name. Elastisches Leitwerk: Stärke einstellbar („Restausschlag bei 30 km/h“, `TailConfig.flex_compliance`, Codec `fxc`). Chewie: LTW Streckung 0,6, Pfeilung 0,5, elastisch (≈ 30 % Restausschlag bei 30 km/h), Schriftzug „CHEWIE“ groß. Albacore: Heckmotor wie Chewie (1804 2450 kV, T4×2×3). Presets leeren die Kurzbeschreibung des vorigen Modells. models.json neu (Chewie, Albacore). |
| 16.11. | 1.0.0 | **Erste offizielle Veröffentlichung** (Stand 0.45.0, ohne weitere Änderungen): Flugsimulation mit Munk-Moment und virtuellen Massen, Baukasten mit Flugmodi je Luftschiff, Mischer mit Grundstellung/Gebern/Schub je Motor, PID-Regler mit Prüfstand, Online-Bestenliste, Browser- und Android-Version. |
| 16.11. | 1.0.1 | Fehler F7B-Wertung behoben: `L_ref = V_ref^(1/3)`, `gewertet = Zeit × √(L_ref / 1 m)` = Zeit × V_ref^(1/6) (vorher Zeit × V_ref^(1/3)). App (Course.race_factor/scored_time, Formelzeile, Rennfaktor) und Server (lib.php `scored`). Vorhandene Online-Einträge werden beim ersten Serveraufruf einmalig umgerechnet (neuer Faktor = √alter Faktor; Spalte `f7b` merkt sich das). |
| 17.11. | 1.1.0 | Physik „genau“ (Einstellungen, `AppSettings.physics_full`): volle 6×6-Massenmatrix um das Auftriebszentrum – M_RB mit Schwerpunkt-Kopplung m·S(r_G) und vollem Trägheitstensor (Deviationsmomente der Punktmassen), M_A = Hülle (k1, k2, k′) + Flossen als ebene Platten (m_f = ρ·π/4·c²·b, Rang-1 mit u = [n; p×n]); Kirchhoff M·ν̇ = [F − ω×p₁; T − ω×p₂ − v×p₁], Munk-Anteil weiter mit munk_factor; Cholesky nur bei Umbau, ≈ 11 µs je Schritt. Sonderfall (r_G = 0, keine Flossen) = bisherige Diagonale (Test `mass6_test`). Watchdog/vereinfacht → Diagonale. Vorerst ohne Wertung in der Bestenliste. |
| 17.11. | 1.2.0 | Rennen als Film aufnehmen (nur Browser): Knopf „●“ oben rechts in der Flugansicht (`ui/race_recorder.gd`, zeigt „● REC m:ss“), Einstellungen „Aufnahme beim Rennstart automatisch starten“ und „Ton mit aufnehmen“ (`AppSettings.rec_auto/rec_audio`, [aufnahme]). Aufnahme in `web/ar-recorder.js` (CI bindet es als `ar-recorder-<Nr>.js` in `ar-<Nr>.html` ein): Canvas-`captureStream(30)` + Spielton (AudioNode.connect wird zusätzlich auf einen MediaStream geleitet), MediaRecorder MP4 (H.264), sonst WebM. Marken Start/Runde n/Ziel, Ende 3 s nach dem Ziel. Danach Schneidefenster: Vorschau, Zeitleiste mit Griffen (rasten an Marken ein), Verwerfen / Ganz speichern / Zuschneiden & speichern (Ausschnitt wird einmal abgespielt und neu aufgenommen). Dateiname `<Modell>_<Strecke>_<Zeit>`. |
| 17.11. | 1.3.0 | Volle 6×6-Massenmatrix ist jetzt das einzige Physikmodell (`mass_matrix_full = true`, Schalter „Physik genau“ und `AppSettings.physics_full` entfernt, Rennen zählen wieder für die Bestenliste; Watchdog/vereinfacht rechnet weiter mit der Diagonale). „Grundlagen des Simulators“ (8 Sprachen): Bewegungsgleichung M·dν/dt = [F − ω×p1; T − ω×p2 − v×p1], virtuelle Masse der Flossen, Munk-Anteil, F7B-Formel mit L_ref = V_ref^(1/3), Abschnitt „Standardmodelle“ entfernt, Export-Hinweis ohne „Standardmodell“. Lizenz: GPL-3.0 statt MIT, weil Flugcontroller (`flight_controller.gd`, nachgebaut aus Chewies Teensy-Code) und Sketch-Vorlage auf dRehmFlight (GPL-3.0) beruhen – `LICENSE` (GPL-Volltext), `NOTICE.md` (Fremdbestandteile), README, Seite „Über / Lizenz“ mit Quelltext-Link und Gewährleistungsausschluss, Lizenzzeile im erzeugten Sketch. Fehler behoben: `Course.rebuild()` löschte beim Wechsel Halle ↔ Wiese auch die Bodenspur (CourseTrack) – Test `track_test`. |
| 17.11. | 1.4.0 | Tutorial „Erste Schritte“ (`ui/tutorial.gd`, nach Entwurf 3): kleiner Knopf „▶ Tutorial“ oben rechts auf der Startseite (blinkt beim Laden 3× kurz), 6 Karten (Luftschiff wählen, Fernbedienung, fliegender Start, Acht, Bestenliste, selbst bauen) mit passender Ansicht; gemeinter Knopf mit pulsierendem gelbem Rahmen (Rechtecke aus `main.gd` → `tutorial.targets`), bei der Acht pulsiert die Bodenspur (`CourseTrack.attention`); im Flug liegt die Karte oben (unten die Knüppel), Klicks außerhalb der Karte gehen durch. Enter = Weiter, Esc = Überspringen. Vorlesen über `DisplayServer.tts_*` (Projekteinstellung `audio/general/text_to_speech`), Stimme in der eingestellten Sprache, Schalter auf der Karte (`AppSettings.tut_voice`, Standard aus). Tastatur: Rolle auf A/D, Demo von A auf T, Beschriftung „Gas · Rolle (W/S A/D)“. Fehler behoben: Mischer-Fenster baute sich beim Moduswechsel nicht neu auf (selbstaufrufendes Lambda sah nur die leere Anfangsfunktion) – jetzt `_refill_mixer()`. Tests `mixer_ui_test`, `tutorial_test`. |
| 17.11. | 1.4.1 | Fehler behoben: `AirshipPresets._reset_common()` setzte `mix_manual`/`mix_table` nicht zurück – der Mischer des zuletzt bearbeiteten Modells (z. B. PigLeg, Schub umgedreht) blieb beim Laden von Chewie und bei „Auf Werkseinstellung zurücksetzen“ stehen, Chewie galt dann als verändert (keine Bestenliste). Test `preset_reset_test`. |
| 17.11. | 1.5.0 | Zugangscodes für private Modelle und Admin: Server-Tabellen `access_codes` (Code im Klartext, damit in der Verwaltung immer sichtbar; Notiz, Rolle gruppe/admin, aktiv, zuletzt benutzt, Abrufe), `private_models` (Modell-String + Angabenzeile je Code), `code_fail` (8 Fehlversuche je IP-Hash → 15 min Sperre). `api.php` action `unlock` → Rolle, Gruppe, Modelle (Admin: alle). `admin.php` Bereich „Zugangscodes“: anlegen (Code XXXX-XXXX-XXXX ohne 0/O/1/I), Modelle je Code bearbeiten, sperren/entsperren, löschen. App: `access_codes.gd` (Code, Rolle, Modelle in `user://zugang.cfg` / `user://private_modelle.txt`, beim Start mit Internet neu geladen, gesperrt → vom Gerät entfernt), Einstellungen → „Zugang“, private Modelle (Quelle „Privat“) nur mit Code in „Modell & Bau“ mit Schloss, Bearbeiten/Export/Teilen erlaubt, nie in der Bestenliste (Server lehnt unbekannte Fingerabdrücke ohnehin ab; App meldet „private Modelle zählen nicht“). „Teensy-Sketch erzeugen“ nur mit Admin-Code. Datenschutzerklärung: neuer Abschnitt 6. CI: `tests/server_access_test.sh` (PHP + SQLite) im Job i18n, Android-Job wartet darauf; `access_test`. |
| 17.11. | 1.5.1 | Baukasten: Modell verschieben – Scrollrad gedrückt (oder Umschalt + linke Maustaste) ziehen, auf Touch 2 Finger gemeinsam schieben; Modell folgt der Maus 1:1 (`main._orbit_pan` in Vielfachen des Kameraabstands, Grenze 85 % der halben Bildbreite/-höhe), „Ansicht zurücksetzen“ und Wechsel in den Baukasten setzen zurück. Bedienhinweis je Touch/Maus. Test `pan_test`. |

Die vollständige Liste steht im Git-Verlauf (`git log`); jede Datei hat in den ersten Zeilen ihre eigene Änderungschronik.

### Verworfene Ansätze (damit sie nicht erneut versucht werden)
- **Eigene Reglerarten** „Geregelt“, „Luftschiff“, „Gedämpft“ und Kaskadenregler in Erdachsen (0.5–0.9.5): ersetzt durch den Teensy-Nachbau, weil Simulator und echtes Schiff dieselben Werte brauchen.
- **Differenzschub** für Gier: ausgeschlossen (Gas nur beim Piloten).
- **Acro-Modus:** schwer umzusetzen, weil man dem Pendelmoment aktiv entgegenwirken müsste.
- **Pauschale Reynoldszahl 10⁵:** ersetzt durch Re je Flosse.
- **Platzen abschaltbar / einstellbare Grenze:** ersetzt durch feste 20 km/h.

---

## 14. Offene Punkte (Stand 14.11.2026)

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
