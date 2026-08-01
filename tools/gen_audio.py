#!/usr/bin/env python3
"""Synthesize all game sound effects as WAVs (16-bit mono 44.1kHz) with stdlib only."""
import math
import os
import random
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def env(i, n, attack=0.01, release=0.3):
    t = i / n
    a = min(1.0, i / max(1, int(n * attack)))
    r = min(1.0, (n - i) / max(1, int(n * release)))
    return max(0.0, min(a, r)) ** 1.5


def tone(freq, dur, vol=0.5, decay=4.0, attack=0.005, release=0.15, shape="sine", sweep=0.0):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq * math.pow(2.0, sweep * i / n)
        phase += 2 * math.pi * f / SR
        if shape == "sine":
            s = math.sin(phase)
        elif shape == "triangle":
            s = 2 / math.pi * math.asin(math.sin(phase))
        elif shape == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        else:
            s = math.sin(phase) + 0.5 * math.sin(2 * phase) + 0.25 * math.sin(3 * phase)
        e = env(i, n, attack, release) * math.exp(-decay * i / n)
        out.append(vol * e * s)
    return out


def noise(dur, vol=0.4, lowpass=0.15, decay=6.0, attack=0.002, release=0.2, seed=7):
    rnd = random.Random(seed)
    n = int(SR * dur)
    out = []
    lp = 0.0
    for i in range(n):
        lp += lowpass * (rnd.uniform(-1, 1) - lp)
        e = env(i, n, attack, release) * math.exp(-decay * i / n)
        out.append(vol * e * lp)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = []
    for i in range(n):
        v = sum(t[i] if i < len(t) else 0.0 for t in tracks)
        out.append(max(-1.0, min(1.0, v)))
    return out


def fade_out(sig, ms=30):
    n = min(int(SR * ms / 1000), len(sig))
    if n <= 0:
        return sig
    out = list(sig)
    for i in range(n):
        out[-1 - i] *= i / n
    return out


def write(name, sig):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            int(max(-1.0, min(1.0, s)) * 32767).to_bytes(2, "little", signed=True)
            for s in sig
        )
        w.writeframes(frames)
    print(f"wrote {path} ({len(sig) / SR:.2f}s)")


write("click.wav", fade_out(tone(1800, 0.06, 0.35, decay=20, release=0.25) + tone(2400, 0.03, 0.15, decay=30)))
write("tick.wav", fade_out(tone(1200, 0.04, 0.3, decay=25)))
write("pop.wav", fade_out(tone(900, 0.07, 0.4, decay=14, sweep=0.6) + tone(1400, 0.04, 0.2, decay=25)))
write("unscrew.wav", fade_out(tone(500, 0.28, 0.4, decay=2.5, sweep=0.55, shape="triangle") + tone(760, 0.22, 0.25, decay=3, sweep=0.45)))
write("metal.wav", fade_out(tone(3300, 0.05, 0.25, decay=18) + noise(0.05, 0.15, lowpass=0.3, decay=18, seed=3)))
write("drop.wav", fade_out(mix(tone(120, 0.4, 0.8, decay=5, shape="sine"), noise(0.22, 0.5, lowpass=0.08, decay=7, seed=11))))
write("heavy.wav", fade_out(mix(tone(70, 0.6, 0.9, decay=3.5, shape="sine"), noise(0.4, 0.6, lowpass=0.05, decay=5, seed=13)), ms=60))
write("coin.wav", fade_out(tone(1046, 0.09, 0.4, decay=6) + tone(1568, 0.25, 0.4, decay=4, attack=0.03)))
write("error.wav", fade_out(tone(220, 0.18, 0.4, decay=8, shape="square") + tone(180, 0.16, 0.3, decay=9)))
write("chime.wav", fade_out(mix(
    tone(523, 0.45, 0.35, decay=2.5), tone(659, 0.45, 0.3, decay=2.5, attack=0.05),
    tone(784, 0.5, 0.3, decay=2.5, attack=0.1), tone(1046, 0.7, 0.35, decay=2, attack=0.15)), ms=80))
write("victory.wav", fade_out(mix(
    tone(523, 0.6, 0.3, decay=2), tone(659, 0.6, 0.3, decay=2, attack=0.08),
    tone(784, 0.6, 0.3, decay=2, attack=0.16), tone(1046, 0.6, 0.35, decay=2, attack=0.24),
    tone(1318, 1.1, 0.35, decay=1.6, attack=0.32), tone(1568, 1.1, 0.3, decay=1.4, attack=0.4)), ms=120))
write("bump.wav", fade_out(tone(180, 0.09, 0.5, decay=10) + noise(0.05, 0.25, lowpass=0.2, decay=12, seed=17)))
