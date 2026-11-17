#!/usr/bin/env python3
# 2026-11-17 21:30 – Erstversion: erzeugten Teensy-Sketch übersetzen (g++, Arduino-Ersatzköpfe) und seine neuen Funktionen (Modus-Tabelle) mit den Ergebnissen des Simulators vergleichen
# =============================================================================
#   python3 tests/ino_compare.py <sketch.ino> <faelle.json>
# Die Fälle schreibt tests/ino_modes_test.gd: je Fall die Eingaben (Modus,
# Knüppel, Lage, Kreisel, Drehgeber, Gas) und was der Simulator ausgibt
# (Ausschlag je Servo −1…1 des vollen Ausschlags, Schub je Motor −1…1).
# Das Skript hängt an den Sketch ein main() an, das genau diese Eingaben in die
# Variablen des Sketches schreibt, die Funktionen des Sketches aufruft und die
# Ausgaben zurückrechnet. Abweichung > 1e-3 → FEHLER.
# =============================================================================
import json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from ino_syntax_check import prototypes, STUB   # noqa: E402

STUB_DEFS = r'''
// --- Ersatz für Teensy-Funktionen (nur zum Testen am PC) ---
SerialStub Serial, Serial1, Serial2, Serial3, Serial5;
WireStub Wire;
EEPROMStub EEPROM;
unsigned long micros() { return 0; }
unsigned long millis() { return 0; }
void delay(unsigned long) {}
void delayMicroseconds(unsigned int) {}
void pinMode(int, int) {}
void digitalWrite(int, int) {}
int digitalRead(int) { return 0; }
int analogRead(int) { return 0; }
void analogWrite(int, int) {}
void analogWriteFrequency(int, float) {}
void analogWriteResolution(int) {}
unsigned long getRadioPWM(int) { return 1500; }
#include <cstdio>
'''


def L(x) -> str:
    """Zahl als C++-float-Literal (auch für ganze Zahlen aus dem JSON)."""
    return repr(float(x)) + "f"


def main(sketch: str, cases_path: str) -> bool:
    src = open(sketch, encoding="utf-8").read().replace("\r\n", "\n")
    data = json.load(open(cases_path, encoding="utf-8"))
    n_srv = len(data["servo_max"])
    kinds = data["kinds"]
    body = []
    body.append("int main() {")
    body.append("  imuOK = true;")
    body.append("  maxPitch = maxPitch; //Werte der Vorlage")
    for ci, c in enumerate(data["cases"]):
        g = c["geber"]
        body.append("  {")
        body.append(f"    modeSlot = {c['slot']}; flightMode = MODE_ART[modeSlot];")
        # Drehgeber S1..S4 → logische Kanäle 8..11 (GEBER_CH), Richtung GEBER_DIR beachten
        for k in range(4):
            body.append(f"    if (GEBER_CH[{k}] > 0) {{ unsigned long v = (unsigned long)lroundf(1500.0f + 500.0f*GEBER_DIR[{k}]*{L(g[k])}); "
                        f"switch (GEBER_CH[{k}]) {{ case 8: channel_8_pwm = v; break; case 9: channel_9_pwm = v; break; case 10: channel_10_pwm = v; break; case 11: channel_11_pwm = v; break; }} }}")
        if c["kind"] == "direct":
            body.append(f"    pitch_des = {L(c['p'])}*maxPitch; yaw_des = {L(c['y'])}*maxYaw; yawLStick_des = {L(c['r'])}*maxYaw; roll_IMU = {L(c['roll'])};")
            body.append("    mixServosTableDirect();")
        else:
            body.append(f"    pitch_des = {L(c['p'])}*maxPitch; yaw_des = {L(c['y'])}*maxYaw; yawLStick_des = {L(c['r'])}*maxYaw;")
            body.append(f"    pitch_IMU = {L(c['pitch_imu'])}; roll_IMU = {L(c['roll'])}; GyroY = {L(c['gp'])}; GyroX = {L(c['gr'])}; GyroZ = {L(c['gy'])}/YAW_RATE_SIGN;")
            body.append(f"    dt = {L(c['dt'])}; motorsEnabled = true;")
            body.append("    for (int a = 0; a < 3; a++) { pidInt[a] = 0.0f; pidPrev[a] = 0.0f; }")
            body.append("    controlPIDMode();")
            body.append("    mixServosTable(pidOut[0], pidOut[2], pidOut[1]);")
        # Servo-Ausschlag zurückrechnen: c = (s - Mitte)*180/max / Richtung
        cmds = ["s%d_command_scaled" % (i + 1) for i in range(n_srv)]
        cens = ["s%d_center" % (i + 1) for i in range(n_srv)]
        body.append(f'    printf("S {ci}");')
        for i in range(n_srv):
            dirx = f"(SERVO_IS_SWIVEL[{i}] ? motor_servo_dir*SERVO_TABLE_DIR[{i}] : SERVO_TABLE_DIR[{i}])"
            body.append(f'    printf(" %.6f", ({cmds[i]} - {cens[i]})*180.0f/SERVO_MAX_DEG[{i}]/{dirx});')
        body.append('    printf("\\n");')
        # Motoren: Gas -1..1 → thro_des 0..1
        body.append(f"    thro_des = ({L(c['thr'])} + 1.0f)*0.5f; motorsEnabled = true;")
        body.append("    mixMotorsTable();")
        body.append("    float mm[6] = {m1_command_scaled, m2_command_scaled, m3_command_scaled, m4_command_scaled, m5_command_scaled, m6_command_scaled};")
        body.append("    float tr[6] = {motor1_trim, motor2_trim, 0, 0, 0, 0};")
        body.append(f'    printf("M {ci}");')
        body.append(f"    for (int j = 0; j < {len(c['motors'])}; j++) printf(\" %.6f\", (mm[j] - tr[j] - MOTOR_STOP_THRO)/0.5f);")
        body.append('    printf("\\n");')
        body.append("  }")
    # Gegenprobe Richtung (unabhaengig vom Sketch-Inhalt der Tabelle): Simulator-Mischer nach Einbaulage
    # (Ausschlag c je Bauteil) und der erprobte Sketch-Mischer mixServosDirect() (Servostellung) fuer
    # dieselben kleinen Knueppelwerte. Die Umrechnung des Tabellen-Pfads im Sketch
    # (Servo = Mitte + Richtung*c*Max/180) muss genau diese beiden verbinden.
    cross = data.get("geo", [])
    for xi, gcase in enumerate(cross):
        body.append("  {")
        body.append(f"    modeSlot = 0; flightMode = 1; roll_IMU = 0.0f;")
        body.append(f"    pitch_des = {L(gcase['p'])}*maxPitch; yaw_des = {L(gcase['y'])}*maxYaw; yawLStick_des = MODE1_ROLL_SIGN*{L(gcase['stick_r'])}*maxYaw;")
        body.append("    mixServosDirect();")
        body.append(f'    printf("A {xi}");')
        for i in range(n_srv):
            dirx = f"(SERVO_IS_SWIVEL[{i}] ? motor_servo_dir*SERVO_TABLE_DIR[{i}] : SERVO_TABLE_DIR[{i}])"
            # Servoweg mit Gesamt-Ausschlag Mode 1, zurueckgerechnet ueber die Tabellen-Umrechnung des Sketches
            body.append(f'    printf(" %.6f", servo_throw_m1*(s{i + 1}_command_scaled - s{i + 1}_center)*180.0f/SERVO_MAX_DEG[{i}]/{dirx});')
        body.append('    printf("\\n");')
        body.append("  }")
    # Schalter Kanal 13
    for si, s in enumerate(data["switch"]):
        body.append(f"  channel_13_pwm = {s['pwm']}; radioFailsafe = false; determineFlightMode(); printf(\"W {si} %d\\n\", modeSlot);")
    body.append("  return 0;")
    body.append("}")
    first = src.find("\nvoid setup()")
    code = src[:first] + "\n" + prototypes(src) + "\n" + src[first:] + "\n" + "\n".join(body) + "\n"
    with tempfile.TemporaryDirectory() as td:
        cpp = os.path.join(td, "t.cpp")
        exe = os.path.join(td, "t")
        open(cpp, "w", encoding="utf-8").write(STUB_DEFS.replace("#include <cstdio>", "") + "\n")
        # Stub-Definitionen nach dem Sketch (die Ersatzklassen kommen aus Arduino.h)
        open(cpp, "w", encoding="utf-8").write("#include <cstdio>\n" + code + "\n" + STUB_DEFS)
        r = subprocess.run(["g++", "-std=gnu++17", "-O0", "-w", "-I", STUB, "-include", os.path.join(STUB, "Arduino.h"),
                            "-x", "c++", cpp, "-o", exe], capture_output=True, text=True)
        if r.returncode != 0:
            print("FEHLER beim Übersetzen:")
            print("\n".join(l for l in r.stderr.splitlines() if "error" in l)[:3000])
            return False
        out = subprocess.run([exe], capture_output=True, text=True).stdout.splitlines()
    ok = True
    worst = 0.0
    res = {}
    for line in out:
        p = line.split()
        if p and p[0] in "SMWA":
            res[(p[0], int(p[1]))] = [float(x) for x in p[2:]]
    for ci, c in enumerate(data["cases"]):
        for tag, exp in (("S", c["servo"]), ("M", c["motors"])):
            got = res.get((tag, ci))
            if got is None or len(got) != len(exp):
                print(f"FEHLER Fall {ci} {tag}: keine Ausgabe"); ok = False; continue
            for i, (a, b) in enumerate(zip(got, exp)):
                d = abs(a - b)
                worst = max(worst, d)
                if d > 1e-3:
                    print(f"FEHLER Fall {ci} ({c['kind']}, Modus {c['slot'] + 1}) {'Servo' if tag == 'S' else 'Motor'} {i + 1} ({kinds[i] if tag == 'S' else 'ESC'}): Sketch {a:+.4f}, Simulator {b:+.4f}")
                    ok = False
    for si, s in enumerate(data["switch"]):
        got = res.get(("W", si))
        if not got or int(got[0]) != s["slot"]:
            print(f"FEHLER Schalter {s['pwm']} us: Sketch Modus {got}, erwartet {s['slot']}"); ok = False
    worst_x = 0.0
    for xi, gcase in enumerate(cross):
        ga = res.get(("A", xi))
        if not ga:
            print(f"FEHLER Gegenprobe {xi}: keine Ausgabe"); ok = False; continue
        for i, (a, b) in enumerate(zip(ga, gcase["sim"])):
            worst_x = max(worst_x, abs(a - b))
            if abs(a - b) > 2e-3:
                print(f"FEHLER Gegenprobe {xi} Servo {i + 1} ({kinds[i]}): Sketch-Einbaulage {a:+.4f}, Simulator {b:+.4f} – Richtung/Umrechnung der Tabelle passt nicht")
                ok = False
    print(f"Gegenprobe Richtung (Sketch-Mischer nach Einbaulage gegen Simulator): {len(cross)} Fälle, größte Abweichung {worst_x:.2e}")
    print(f"{len(data['cases'])} Fälle, größte Abweichung {worst:.2e}")
    print("ino_compare: " + ("OK" if ok else "FEHLER"))
    return ok


if __name__ == "__main__":
    sys.exit(0 if main(sys.argv[1], sys.argv[2]) else 1)
