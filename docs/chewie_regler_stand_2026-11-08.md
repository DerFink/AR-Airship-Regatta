<!-- 2026-11-09 14:45 – Punkt 5 Nick-Schutz ergänzt -->
<!-- 2026-11-08 20:30 – Erstversion: Stand Regler und Simulator-Modell von Chewie als Prompt -->
# Chewie – Stand Regler und Simulator-Modell (08.11.2026)

Prompt zum Weiterarbeiten. In eine neue Sitzung einfügen, zusammen mit der aktuellen
.ino (Chewie_SBUS_dRehmFlight_Teensy_BETA_1_3_20261001.ino, Stand 04.11.2026).

---

**Aufgabe an Claude:** Du arbeitest am Flugregler meines Rennluftschiffs „Chewie“
(Teensy 4.0, dRehmFlight, MPU6050, SBUS, Taranis X9D mit EdgeTX). Im Simulator
AR-Airship-Regatta (Godot 4.3, Repository DerFink/AR-Airship-Regatta, Datei
flight_controller.gd) ist der Regler 1:1 aus der .ino nachgebaut und um die unten
genannten Punkte erweitert. Diese Erweiterungen sind im Simulator erprobt, aber noch
NICHT in die .ino übertragen. Übertrage sie erst nach meiner Freigabe. Schreibe in
die erste Zeile jeder geänderten Datei einen Kommentar mit Zeitstempel und kurzer
Liste der Änderungen, und kommentiere den Code so, dass klar ist, wofür jeder
Abschnitt zuständig ist. Gas wird nie vom Regler verändert (Pilot muss bei Gefahr
sofort abschalten können), kein Differenzschub.

## 1. Chewie (Modell im Simulator)

| Größe | Wert |
|---|---|
| Hülle | 0,25 m³, L/D 6 (L ≈ 2,6 m, Ø ≈ 0,43 m), Octax, 85 g |
| Gesamtmasse | 260 g, ≈ 1 % schwerer als der Auftrieb (Restmasse unten an der Hülle) |
| Leitwerk | 3 Pendelflossen (λ, gleichmäßig verteilt: oben 0°, unten ±120° ⇒ 30° unter der Waagrechten), je ≈ 10 g, ±50°, 0,036 m² je Flosse, Seitenverhältnis 1 |
| Motoren | 2 × GEPRC SpeedX2 1804 2450 KV, 4"-Propeller, gegenläufig, vorn bei 0,25 L seitlich unten (45° unter der Waagrechten), Rückwärtsschub |
| Schwenk | Achse radial durch den Motorfuß ⇒ Schub schwenkt ENTLANG der Hülle, ±45°; Schwenkmechanismus ≈ 23 g |
| Schub | Annahme 7 N je Motor bei Vollgas, Schub ∝ Gashebel², Hochlaufzeit 30 ms |

Physik-Annahmen, die nötig waren, damit der Simulator wie der echte Chewie fliegt:
- Munk-Moment auf 60 % der Potentialtheorie abgemindert (Grenzschicht am Heck). Mit 100 %
  schwang Chewie mit den echten Reglerwerten in Nick um ±20°.
- Flossen an der Hülle: wirksame Streckung doppelt (Hülle als Spiegelwand) und
  Rumpf-Flossen-Interferenz 1,3. Ohne das lief Chewie nicht geradeaus.
- Schwenk entlang der Hülle erzeugt beim Gieren ein Rollmoment (≈ 0,3 Nm je N Schub bei
  vollem Schwenk). Das ist die Ursache für Rollen und scheinbares Hochnicken in Kurven.

## 2. Regler = .ino (unverändert übernommen)

- Modi auf Kanal 13: Mode 1 Direkt (mixServosDirect), Mode 2, Mode 3.
- controlANGLE(): PID in Grad, Ausgang × 0,01, D auf die Kreiselrate.
  Nick Kp 0,6 / Ki 0,4 / Kd 0,15; Roll Kp 0,6 / Ki 0,1 / Kd 0,45; i_limit 25.
- Mischer: Servo = Mitte ± (Nick·sin n + Gier·cos n + Roll), Einbauwinkel 60°/300°
  (untere Flossen bzw. Motorschwenker) und 180° (obere Flosse); Stabilisierung mit
  n + Rollwinkel; Gesamt-Ausschlag Mode 1: 1,0, Mode 2/3: 0,5.
- tail_pitch_gain 2, motor_pitch_gain 2, roll_vs_pitch 1,5, ROLL_AUTH_FACTOR 0,5,
  motor_roll_gain 1,0, MOTOR_ROLL_SIGN −1, stick_pitch_tail 0,015, stick_pitch_motor 0,02.
- Mode 2: Gier nur Vorsteuerung (stick_yaw_motor 0,016, stick_yaw_tail 0,005), maxYaw 160,
  Nick-Sollwinkel ±30°.
- Mode 3: Gierrate bis 180 °/s, P-Regler Kp_yaw_m3 0,4 (blendet hinter Totband 0,05 über
  0,15 Knüppelweg ein), Vorsteuerung 0,0125 / 0,00625, yaw_loop_motor 0,6 / tail 0,5;
  Nickrate 45 °/s, Sollwinkel ±30°, Vorlauf max. 15°, Rückkehr 20 °/s.

## 3. Erweiterungen im Simulator (noch nicht in der .ino)

1. **Gierschwenk mit dem Gas zurücknehmen** (wichtigste Änderung):
   `lever = |Gashebel|` (0…1 oberhalb der Mitte),
   `scale = 1` bis `yaw_swivel_full_lever = 0,22`, darüber `scale = (0,22 / lever)²`.
   Nur der Gieranteil der Motorschwenker (inkl. motorRoll) wird mit `scale` multipliziert;
   Nick über die Schwenker und das Leitwerk bleiben unverändert. Damit bleibt die seitliche
   Schubkraft konstant statt mit dem Gas zu wachsen.
   Ergebnis (5 s voller Seitenknüppel, Mode 2/3): Wenderadius bei jedem Gas ≤ 2,0 m;
   Rollen 16° (20 %), ≤ 40° (30 %), ≈ 20° (45 %), < 10° ab 60 %; vorher kippte Chewie
   ab ≈ 45 % Gas auf die Seite und die Kurve lief verkehrt.
2. **Mode 3: Vorlauf-Grenze nur bei bewegtem Höhenknüppel.** In rateModeUpdate die Zeile
   `pitchSetpointM3 = constrain(pitchSetpointM3, pitch_IMU − LEAD, pitch_IMU + LEAD)` nur
   ausführen, wenn |Höhenknüppel| > Totband, und erst danach auf ±maxPitch begrenzen.
   Vorher zog sie den Sollwinkel mit nach oben, wenn die Nase von selbst stieg (Vollgas in
   der Kurve ⇒ Hochnicken).
3. **Mode 3: Gierdämpfer bei Knüppel in der Mitte:**
   `yawRatePID += (1 − weight) · 0,01 · Kd_yaw_m3 · (−GyroZ)`, Kd_yaw_m3 = 0,4
   (schwächer als der Nick-Dämpfer). Blendet aus, wenn der Drehratenregler einblendet.
4. **Expo auf dem Seitenknüppel:** `(1 − e)·x + e·x³`, e = 0,3 (oder im Sender einstellen,
   dann hier 0).

5. **Nick-Schutz (Mode 2/3, Sicherheit):** Die Knüppel-Vorsteuerung (stick_pitch_tail/motor ·
   Sollwinkel + gain · 0,01 · Kp · Sollwinkel) gibt einen festen Ausschlag, die Stabilisierung
   zieht nur Richtung 0°. Bei gehaltenem Höhenknüppel stellte sich dadurch ≈ 60° Nick ein
   (Flossen überzogen, Schub zeigt nach oben/unten → „steuerlos“).
   Abhilfe: `over = |pitch_IMU| − maxPitch`; wenn `over > 0` und Knüppel in dieselbe Richtung,
   Vorsteuerung (pitch_des und pitch_PID_sp) mit `k = constrain(1 − over / 10, 0, 1)` multiplizieren.
   Gegenrichtung wirkt voll, Gas unberührt.
   Simulator, Knüppel 1,5 s voll, Mode 3: max. Nick vorher 60–63°, jetzt 35° (100 % Gas),
   36° (60 %), 44° (30 %); Mode 2: 37° / 41° / 49°.
   Am echten Chewie zusätzlich prüfen: Lageschätzung (Madgwick) bei starker Beschleunigung
   und in Kurven, Messbereich des Kreisels (±250 °/s?).

## 4. Offene Punkte

- Gasverhalten: Der echte Chewie ist am Gas deutlich agiler als der Simulator. Zu prüfen:
  Schubkurve (∝ Gashebel² ?) und Höchstschub (7 N je Motor angenommen).
- Rollen um 30 % Gas noch bis ≈ 40° (echter Chewie < 10°).
- Bei 60 % Schub dreht Chewie nach dem Loslassen des Seitenknüppels in Mode 2 noch langsam
  weiter (≈ 25 °/s); der echte fliegt stabiler geradeaus.
