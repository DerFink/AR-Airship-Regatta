# 2026-11-11 16:30 – Erzeugt audio/werkstatt_gitarre.ogg (eigene Komposition, gemeinfrei nutzbar wie der übrige Code: MIT). Danach: Lautheit auf RMS 0,104 angleichen, Spitzen weich begrenzen, mit ffmpeg nach OGG Vorbis (q4) wandeln
# Werkstatt-Musik „Wüste“: langsame, hallige E-Gitarre (eigene Komposition, prozedural), E-Moll-Pentatonik, ~52 BPM,
# Bordun auf E, einzelne gezogene Töne (Bendings) mit Vibrato, Tremolo, Röhren-Verzerrung, Bandecho, langer Hall; nahtlos schleifbar
import numpy as np, wave
from scipy.signal import fftconvolve, butter, sosfilt
SR = 44100
BPM = 52
beat = 60 / BPM
bar = 4 * beat
rng = np.random.default_rng(11)
def hz(m): return 440 * 2 ** ((m - 69) / 12)

def guitar(f0, dur, vel=1.0, bend=0.0, bend_at=0.25, bend_t=0.35, vib=0.0, trem=0.0, pick=0.18, decay=1.0):
    """E-Gitarren-Ton additiv: Obertöne mit Tonabnehmer-Kammfilter, höhere klingen schneller ab.
    bend = Halbtöne nach oben, ab bend_at s in bend_t s; vib = Vibrato-Tiefe (Halbtöne)."""
    n = int(dur * SR); t = np.arange(n) / SR
    semis = np.zeros(n)
    if bend:
        semis += bend * np.clip((t - bend_at) / bend_t, 0, 1) ** 0.7
    if vib:
        semis += vib * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - bend_at - bend_t) / 0.4, 0, 1)
    f = f0 * 2 ** (semis / 12)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.zeros(n)
    for k in range(1, 16):
        if f0 * k > 9000: break
        a = abs(np.sin(np.pi * k * pick)) / k ** 1.05
        s += a * np.sin(k * ph + rng.uniform(0, 6.28)) * np.exp(-t * (0.9 + 0.35 * k ** 0.9) * decay)
    # Anschlag: kurzes Plektrum-Rauschen
    nz = rng.normal(0, 1, n) * np.exp(-t * 60) * 0.03            # Plektrum leiser (weicher Anschlag)
    env = np.minimum(1, t / 0.035) ** 1.5                         # weicher Einsatz (35 ms, wie mit dem Daumen gezupft)
    rel = np.clip((dur - t) / 0.3, 0, 1)
    s = (s + nz) * env * rel * vel
    if trem:
        s *= 1 - trem * (0.5 + 0.5 * np.sin(2 * np.pi * 4.3 * t))
    return s

def amp(x, drive=2.2):
    """Röhrenverstärker grob: Hochpass, weiche Sättigung, Box (Tiefpass), etwas Mitten."""
    x = sosfilt(butter(2, 80, 'high', fs=SR, output='sos'), x)
    y = np.tanh(drive * x) / np.tanh(drive)
    y = sosfilt(butter(2, 3000, "low", fs=SR, output="sos"), y)   # dunklere Box: weniger Härte
    mid = sosfilt(butter(2, [500, 1400], 'band', fs=SR, output='sos'), y)
    return y + 0.4 * mid

cycles = 2
section = bar * 8                     # 8 Takte je Durchgang
L = int(SR * section * cycles)
gtr = np.zeros(L + SR * 8)
drone = np.zeros(L + SR * 8)
def put(buf, sig, start):
    i = int(max(0, start) * SR); buf[i:i + len(sig)] += sig[:max(0, len(buf) - i)]

E2, B2, E3, G3, A3, B3, D4, E4, G4, A4 = 40, 47, 52, 55, 57, 59, 62, 64, 67, 69
# Bordun: tiefes E (+ Quinte) als lange, anschwellende Rückkopplung
for c in range(cycles):
    t0 = c * section
    for m, g in ((E2, 0.5), (B2, 0.25), (E3, 0.12)):
        n = int((section + 3) * SR); t = np.arange(n) / SR
        sw = (0.6 + 0.4 * np.sin(2 * np.pi * t / (section) - 1.2)) * np.minimum(1, t / 3) * np.clip((section + 3 - t) / 3, 0, 1)
        s = sum(np.sin(2 * np.pi * hz(m) * k * t * (1 + 0.0015 * np.sin(0.3 * t))) / k ** 1.4 for k in range(1, 6))
        put(drone, s * sw * g, t0)
# Leere E-Saite angeschlagen am Anfang jedes Durchgangs und in Takt 5
for c in range(cycles):
    for b in (0, 4):
        put(gtr, guitar(hz(E2), 7.0, 0.9, trem=0.35, decay=0.45) + guitar(hz(B2), 7.0, 0.5, trem=0.35, decay=0.5), c * section + b * bar)
# Melodie: sparsam, Pausen, Bendings (Zeitpunkt in Schlägen, Ton, Länge, Bending, Vibrato)
phr1 = [(1.0, B3, 3.0, 0, 0.15), (3.0, D4, 2.5, 0, 0), (4.0, E4, 5.0, 0, 0.25),
        (9.0, G4, 2.0, 0, 0), (10.0, A4, 4.5, -2 * 0, 0.2), (13.5, E4, 3.0, 0, 0),
        (17.0, D4, 4.0, 2, 0.25), (21.5, B3, 2.5, 0, 0), (22.5, A3, 4.0, 0, 0.15),
        (26.0, G3, 5.0, 2, 0.3)]
phr2 = [(1.0, E4, 2.5, 0, 0), (2.0, G4, 4.0, 2, 0.3), (6.5, E4, 2.0, 0, 0), (7.5, D4, 4.0, 0, 0.2),
        (11.0, B3, 2.0, 0, 0), (12.0, D4, 5.0, 1, 0.2), (17.0, A3, 3.0, 0, 0), (18.5, B3, 4.0, 0, 0.2),
        (23.0, E4, 3.0, 2, 0.3), (26.5, B3, 5.0, 0, 0.15)]
for c, phr in enumerate((phr1, phr2)):
    for (b, m, d, bd, vb) in phr:
        tt = c * section + b * beat + rng.normal(0, 0.02)
        put(gtr, guitar(hz(m), d + 1.5, rng.uniform(0.55, 0.75), bend=bd, bend_at=0.12, bend_t=0.45, vib=vb, decay=0.8), tt)
# Akkord-Anschläge (leise, gezupft nacheinander): C (Takt 3) und D (Takt 7)
for c in range(cycles):
    for b, chord in ((2, [48, 55, 60, 64]), (6, [50, 57, 62, 66])):
        for i, m in enumerate(chord):
            put(gtr, guitar(hz(m), 6.0, 0.32, trem=0.25, decay=0.6), c * section + b * bar + 2 * beat + i * 0.07)

g = amp(gtr * 0.55, drive=1.8)
# Bandecho: 3/8-Schlag-Verzögerung, gedämpfte Wiederholungen
d = int(0.375 * beat * 2 * SR)
echo = np.zeros_like(g)
fb = g.copy()
for k in range(1, 5):
    fb = sosfilt(butter(1, 2500, 'low', fs=SR, output='sos'), fb) * 0.42
    echo[d * k:] += fb[:len(g) - d * k]
g = g + echo
# Langer Hall (≈ 4,5 s), stereo
n = int(4.8 * SR); t = np.arange(n) / SR
irs = []
for _ in range(2):
    ir = sosfilt(butter(2, 4200, 'low', fs=SR, output='sos'), rng.normal(0, 1, n) * np.exp(-t * 1.45))
    irs.append(ir / np.sqrt(np.sum(ir ** 2)))
dry = np.stack([g * 0.95 + drone * 0.18, g * 0.85 + drone * 0.18], 1)
pan_g = np.stack([g * 0.75, g * 1.0], 1)
wet = np.stack([fftconvolve(pan_g[:, ch] + drone * 0.3, irs[ch])[:len(g)] for ch in range(2)], 1)
mix = 0.55 * dry + 0.7 * wet
loop = mix[:L].copy(); tail = mix[L:]
loop[:len(tail)] += tail[:L]
loop = sosfilt(butter(2, 30, 'high', fs=SR, output='sos'), loop, axis=0)
loop *= 0.5 / np.max(np.abs(loop))
with wave.open('wueste.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((loop * 32767).astype(np.int16).tobytes())
print("Länge %.1f s, RMS %.3f" % (L / SR, np.sqrt(np.mean(loop ** 2))))
