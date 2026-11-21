<!-- 2026-11-22 00:25 – Aerarium: Idee Mehrspieler-Event (bis 20+ Luftschiffe in Echtzeit), Datenrate und Server notiert -->
<!-- 2026-11-17 23:10 – Servos: Datenblatt EMAX ES9251 II, Stellkraft-Grenze als Prüfpunkt -->
<!-- 2026-11-17 23:05 – Erstversion: Backlog (notiert, noch nicht freigegeben) – Realismus-Punkte aus der Prüfung vom 17.11., Location „Aerarium“, Restpunkte der offenen Liste -->
# Backlog – RC Airship Regatta

Hier stehen Punkte, die **notiert, aber nicht freigegeben** sind. Umgesetzt wird
erst nach ausdrücklicher Freigabe durch den Projektinhaber. Sortiert nach
Wichtigkeit; Stand 17.11.2026 (Version 1.6.2).

---

## Hoch – Sicherheit am echten Luftschiff

### Teensy-Sketch mit Modus-Tabelle am echten Teensy prüfen
Der Sketch mit Modus-Tabelle (1.6.0) und Differenzschub (1.6.1) ist bisher nur
mit g++ und Ersatzbibliotheken übersetzt und gegen den Simulator gerechnet.
- In der Arduino-IDE für den Teensy 4.0 übersetzen.
- Bodentest ohne Propeller: jeden Modus, jedes Ruder, jeden Schwenker, jede
  Motorrichtung, Notaus über Kanal 14 – auch bei Differenzschub.

---

## Nächste Version

### Location „Aerarium“ (Idee Erich Fink, 10.11.2026; Details in `docs/ideen.md`)
- Ort identisch mit der Halle FN.
- Mehrere Luftschiffe fliegen autonom und sehr langsam im Kreis.
- Einige in Fischform; andere ziehen Helium-Ballone in Fischform hinter sich her.
- Andere ziehen ein silbernes Band hinter sich her (ca. 1 cm breit, 10 m lang).

#### Idee: Mehrspieler-Event im Aerarium (notiert 22.11.2026)
- Zeitlich begrenztes Event: bis zu 20 Luftschiffe oder mehr fliegen gleichzeitig
  in Echtzeit, jeder Mensch steuert sein eigenes.
- Prinzip: Jedes Gerät rechnet die Physik des eigenen Luftschiffs. Es sendet
  Position, Lage, Geschwindigkeit, Drehrate und Ruder an einen Server, der an alle
  verteilt. Fremde Luftschiffe werden geglättet und vorausberechnet dargestellt
  (aus Geschwindigkeit und Drehrate bis zum nächsten Paket).
- Die autonomen Fisch-Luftschiffe laufen nach der Uhrzeit und sind bei allen gleich,
  ohne Netz.
- Datenrate: 1 Hz reicht nur zum gemütlichen Zuschauen; Kurven werden dann eckig
  und Positionen hinken 1–2 s nach. 5 Hz reicht zum gemeinsamen Fliegen,
  10 Hz für Rennen oder Berührungen. Menge bei 20 Schiffen und 10 Hz: je Gerät
  etwa 20 kB/s Empfang, unkritisch.
- Server: Für Echtzeit ist ein dauerhaft laufendes Programm mit WebSocket nötig.
  Der Strato-Webspace (PHP) kann das vermutlich nicht. Bei einem zeitlich begrenzten
  Event reicht ein Server, der nur während des Events läuft, z. B. ein stundenweise
  gemieteter kleiner Server oder ein Docker-Container auf einer Synology.
  Notlösung PHP mit Abfrage 1×/s: 20 Anfragen pro Sekunde auf Strato, Grenzen des
  Tarifs prüfen.
- Vorher festlegen: nur gemeinsam fliegen oder auch Rennen; Berührungen ja/nein;
  Raumcode für das Event; Anzeige von Namen nur mit Einwilligung (Datenschutz).

---

## Realismus (Prüfung vom 17.11.2026)

Messung: Chewie in enger Kurve (Seitenknüppel voll, 8 s). Seit 1.3.0 (volle
6×6-Massenmatrix) nickt Chewie weniger (Angle: Spanne 19° → 15° bei 60 % Gas,
34° → 27° bei Vollgas; Horizon 19° → 12° bzw. 33° → 20°). Die 6×6-Gleichungen
sind korrekt (Energieerhaltung ohne äußere Kräfte über 5 s: Abweichung 0,000 %).

### A) Lagesensor wie echt (größter Unterschied)
Der Simulator gibt dem Regler die **wahre** Lage. Der echte Teensy schätzt sie
mit dem Madgwick-Filter aus Kreisel und Beschleunigungsmesser; in Kurven misst
der Beschleunigungsmesser die Fliehkraft mit, die Schätzung kippt langsam mit,
Angle regelt auf einen schiefen Horizont. Dazu Rauschen und Nullpunktdrift.
- Madgwick aus dRehmFlight 1:1 übertragen, Beschleunigungsmesser mit Fliehkraft,
  Rauschen und Drift.

### B) Servos
Stellgeschwindigkeit ist begrenzt (Flossen 500 °/s ≈ 0,12 s/60°, Schwenker
400 °/s ≈ 0,15 s/60°), es fehlen aber Totzeit, Spiel und Totband.
- Etwa 15 ms Totzeit und 0,5° Spiel.
- Stellgeschwindigkeit an Chewies echte Servos anpassen. Chewie hat **EMAX ES9251 II**
  (digital, 4 g, Kunststoffgetriebe, 4,8–6,0 V): **0,09 s/60° bei 4,8 V (≈ 670 °/s),
  0,07 s/60° bei 6,0 V (≈ 860 °/s)**, Stellkraft **0,25 / 0,3 kgf·cm** (≈ 2,5 / 2,9 N·cm).
  Die echten Servos sind also schneller als im Simulator (Flossen 500 °/s,
  Schwenker 400 °/s; bei 5 V vom BEC etwa 700 °/s). Offen: Sitzen an den
  Motorschwenkern dieselben Servos?
- **Stellkraft-Grenze** (neu zu prüfen): 0,25 kgf·cm ist wenig. Bei Pendelflossen
  (≈ 19 × 19 cm) hängt das Rückstellmoment vom Abstand Drehachse – Druckpunkt
  ab; bei höherer Fahrt könnte das Servo den vollen Ausschlag nicht mehr halten
  (Ausschlag wird von der Luft zurückgedrückt). Für das Modell nötig: Lage der
  Drehachse der Flossen und Hebelverhältnis der Anlenkung.

### C) Abgleich mit dem echten Chewie (dauert noch)
Auffällig im Simulator:
- **Rolllage in Kurven** 23–45° (6×6), echter Chewie in Mode 2 nie über 10°.
  Möglicher Grund: Die mitbewegte Luft der Flossen wird nach Streifentheorie
  gerechnet (m = ρ·π/4·c²·b) – für kurze, breite Flossen (Streckung 0,6) ist sie
  in Wirklichkeit deutlich kleiner.
- **Vollgas geradeaus:** ≈ 18 m/s (65 km/h) und Nickschwingung ±25–30° mit
  ≈ 3 s Periode in Angle – vermutlich zu schnell (Schubabfall mit der Fahrt,
  Widerstand prüfen).
- **Albacore** überschlägt sich in Direkt mit voller Seite.
- **Gas:** Der echte Chewie ist am Gas deutlich agiler.
- Bekannte Daten des echten Chewie (aus den Gesprächen): Bestzeit ca. 20 s pro
  Runde; Wenderadius unter 1,5 m; Rollen in Mode 2 nie über 10°; D-Anteil auf
  Maximum nötig, um Nick zu dämpfen; Schubhebel typisch 30 %, Spitzen 70 %, vor
  Kurven 10–20 %, Vollgas so gut wie nie; dreht mit ca. 20 % Schub auf der Stelle.
- Noch nötig: geschätzte Höchstgeschwindigkeit, Rolllage in der engen Kurve
  bei bekanntem Schub.

### D) Luft in der Halle (optional)
Keine Zugluft, keine Thermik im Simulator.

---

## Niedrig

- Am echten Gerät testen: Vorlesen im Tutorial (Android, Browser),
  „Zuschneiden & speichern“ der Aufnahme in einem echten Browser.
- **Profil-Diagramm** (seit 12.11. notiert, Herkunft unklar – vermutlich
  Auftrieb über Anstellwinkel der gewählten Flossenform im Baukasten):
  klären oder streichen.
- **Troponaut** (nur wenn der Kollege es braucht): EdgeTX-Mischtabellen für den
  echten Sender passend zum Simulator; Crabbing (Seitwärtsflug über
  Differenzschub) auch im Modus Cruise.
- CI-Testliste: `menu_test` gibt es nicht mehr (stört nicht).

---

## Erledigt bzw. gestrichen (17.11.2026)
- Sender nach Werkseinstellung der Kalibrierung, Kalibrierung im Browser nach
  Abstecken – funktioniert.
- Test Build 104 – gestrichen.
- Echte Flossengröße und Flossengewicht von Chewie – stimmt.
- Bestenliste im laufenden Quartal (alte Physik) – irrelevant.
- GPL und Apple App Store – nicht wichtig.
- Lizenztext der chinesischen Schrift (`fonts/OFL.txt`), Teensy-Sketch mit
  Modus-Tabelle – erledigt in 1.6.0.
