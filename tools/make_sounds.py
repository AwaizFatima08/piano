#!/usr/bin/env python3
"""Synthesizes every sound in Rainbow Keys into assets/sounds/*.wav.

All sounds are made from scratch here (sine/triangle/square waves, noise and
envelopes), so there are no third-party samples to license or attribute.

    python3 tools/make_sounds.py

Output: 32 kHz mono 16-bit WAV, peak-normalised to -3 dBFS (the app adds its
own volume and loudest-volume limit on top).
"""
import os
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
NOTES = [60, 62, 64, 65, 67, 69, 71, 72]  # C4..C5, one per key
rng = np.random.default_rng(7)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(dur, attack=0.004, decay=1.0):
    """Fast attack, exponential decay (decay = time to fall about 60 dB)."""
    t = t_axis(dur)
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-6.9 * t / decay)


def osc(kind, freq, dur):
    """freq may be a number or an array (for glides); returns the waveform."""
    t = t_axis(dur)
    f = np.asarray(freq, dtype=float)
    if f.ndim and len(f) < len(t):  # a short glide holds its last frequency
        f = np.concatenate([f, np.full(len(t) - len(f), f[-1])])
    f = np.broadcast_to(f, t.shape)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == 'sine':
        return np.sin(ph)
    if kind == 'tri':
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if kind == 'square':
        return np.sign(np.sin(ph)) * 0.6
    if kind == 'saw':
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    raise ValueError(kind)


def glide(f1, f2, dur):
    return f1 * (f2 / f1) ** (t_axis(dur) / dur)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def onepole_lp(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def bandpass(x, lo, hi):
    return onepole_lp(x, hi) - onepole_lp(x, lo)


def highpass(x, cutoff):
    return x - onepole_lp(x, cutoff)


def mix(*parts, dur=None):
    n = max(len(p) for p, _ in parts) if dur is None else int(SR * dur)
    out = np.zeros(n)
    for p, at in parts:
        s = int(SR * at)
        seg = p[: max(0, n - s)]
        out[s:s + len(seg)] += seg
    return out


def save(name, x, gain_db=0.0):
    x = np.asarray(x, dtype=float)
    fade = min(len(x), int(SR * 0.01))
    x[-fade:] *= np.linspace(1, 0, fade)
    peak = np.max(np.abs(x)) or 1
    x = x / peak * 10 ** ((-3 + gain_db) / 20)
    data = (x * 32767).astype('<i2').tobytes()
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


# ---------- instruments (one file per key) ----------

def piano(f):
    d = 1.8
    x = (osc('tri', f, d) * env(d, 0.004, 1.6)
         + 0.6 * osc('sine', f * 1.002, d) * env(d, 0.004, 2.0)
         + 0.3 * osc('sine', f * 2, d) * env(d, 0.004, 0.8)
         + 0.12 * osc('sine', f * 3, d) * env(d, 0.003, 0.45))
    x += 0.06 * bandpass(noise(d), 1500, 4000) * env(d, 0.001, 0.03)
    return x


def xylo(f):
    f *= 2
    d = 0.8
    return (osc('sine', f, d) * env(d, 0.002, 0.55)
            + 0.25 * osc('sine', f * 3, d) * env(d, 0.002, 0.12)
            + 0.08 * osc('sine', f * 6.3, d) * env(d, 0.001, 0.05)
            + 0.1 * bandpass(noise(d), 2000, 6000) * env(d, 0.001, 0.015))


def musicbox(f):
    f *= 2
    d = 2.0
    return (osc('sine', f, d) * env(d, 0.002, 1.8)
            + 0.22 * osc('sine', f * 2, d) * env(d, 0.002, 0.6)
            + 0.14 * osc('sine', f * 3.01, d) * env(d, 0.002, 0.35)
            + 0.05 * osc('tri', f * 4, d) * env(d, 0.001, 0.15))


def space(f):
    d = 1.0
    t = t_axis(d)
    vib = 1 + 0.02 * np.sin(2 * np.pi * 6 * t) * np.clip((t - 0.08) / 0.1, 0, 1)
    freq = np.minimum(f, f * 0.92 + f * 0.08 * t / 0.05) * vib  # little "bwoop" into the note
    x = osc('square', freq, d) + 0.4 * osc('saw', freq / 2, d)
    x = onepole_lp(x, min(5000, f * 6))
    return x * env(d, 0.01, 0.9)


# ---------- drums ----------

def kick():
    d = 0.45
    return (osc('sine', glide(160, 45, d), d) * env(d, 0.002, 0.42)
            + 0.15 * bandpass(noise(d), 1000, 5000) * env(d, 0.001, 0.01))


def snare():
    d = 0.25
    return (0.7 * highpass(noise(d), 1500) * env(d, 0.001, 0.2)
            + 0.5 * osc('tri', glide(200, 150, d), d) * env(d, 0.001, 0.1))


def clap():
    d = 0.3
    burst = lambda dd: bandpass(noise(dd), 900, 2500) * env(dd, 0.001, dd)
    return mix((burst(0.02), 0), (burst(0.02), 0.012), (burst(0.02), 0.024),
               (0.6 * bandpass(noise(0.25), 900, 2500) * env(0.25, 0.002, 0.18), 0.03), dur=d)


def hat():
    d = 0.12
    return highpass(noise(d), 7000) * env(d, 0.001, 0.07)


def crash():
    d = 1.5
    return (highpass(noise(d), 5000) * env(d, 0.002, 1.3)
            + 0.4 * bandpass(noise(d), 3000, 9000) * env(d, 0.002, 0.7))


def tom(f1, f2):
    d = 0.5
    return osc('sine', glide(f1, f2, d), d) * env(d, 0.002, 0.45)


def bell():
    d = 0.5
    x = osc('square', 560, d) + osc('square', 845, d)
    return bandpass(x, 500, 1400) * env(d, 0.001, 0.35)


# ---------- silly sounds ----------

def boing():
    d = 0.6
    t = t_axis(d)
    freq = glide(180, 420, d) + 70 * np.sin(2 * np.pi * 14 * t) * (1 - t / d)
    return osc('sine', freq, d) * env(d, 0.005, 0.6)


def pop():
    d = 0.15
    return (osc('sine', glide(300, 1400, 0.07), d) * env(d, 0.002, 0.09)
            + 0.3 * bandpass(noise(d), 1500, 3500) * env(d, 0.001, 0.02))


def quack():
    one = lambda: bandpass(osc('saw', glide(420, 300, 0.15), 0.15), 700, 1800) * env(0.15, 0.01, 0.15)
    return mix((one(), 0), (one(), 0.19), dur=0.4)


def zap():
    d = 0.35
    return onepole_lp(osc('square', glide(1800, 120, d), d), 5000) * env(d, 0.002, 0.33)


def bubbles():
    parts = []
    for k in range(6):
        f = rng.uniform(260, 520)
        parts.append((osc('sine', glide(f, f * 2.5, 0.06), 0.06) * env(0.06, 0.003, 0.06), k * 0.07))
    return mix(*parts, dur=0.5)


def whistle(f1, f2, d):
    t = t_axis(d)
    freq = glide(f1, f2, d) * (1 + 0.025 * np.sin(2 * np.pi * 7 * t))
    a = np.clip(t / 0.03, 0, 1) * np.clip((d - t) / 0.08, 0, 1)
    return osc('sine', freq, d) * a


def trill():
    parts = [(osc('sine', 1250 if k % 2 else 950, 0.05) * env(0.05, 0.003, 0.05), k * 0.045) for k in range(10)]
    return mix(*parts, dur=0.5)


# ---------- rewards ----------

def arpeggio(notes, step, tail=1.2):
    parts = [(musicbox(mtof(m))[: int(SR * tail)], i * step) for i, m in enumerate(notes)]
    sparkle = [(0.4 * osc('sine', mtof(96 + (k % 3) * 4), 0.08) * env(0.08, 0.002, 0.08), 0.05 + k * 0.06) for k in range(6)]
    return mix(*parts, *sparkle)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [('piano', piano), ('xylo', xylo), ('box', musicbox), ('space', space)]:
        for i, m in enumerate(NOTES):
            save(f'{name}_{i}', fn(mtof(m)))
    for name, x in [('kick', kick()), ('snare', snare()), ('clap', clap()), ('hat', hat()),
                    ('crash', crash()), ('tomlow', tom(140, 80)), ('tomhigh', tom(260, 170)), ('bell', bell())]:
        save('drum_' + name, x)
    # Sustained whistles sound far louder than short hits at the same peak, so they get -10 dB.
    for name, x, g in [('boing', boing(), 0), ('pop', pop(), 0), ('quack', quack(), 0), ('zap', zap(), 0),
                       ('bubbles', bubbles(), 0), ('up', whistle(500, 1800, 0.5), -10),
                       ('down', whistle(1600, 300, 0.6), -10), ('trill', trill(), 0)]:
        save('silly_' + name, x, g)
    save('cheer', arpeggio([72, 76, 79, 84], 0.08))
    save('fanfare', arpeggio([67, 72, 76, 79, 76, 79, 84], 0.13, tail=1.6))
    print('wrote', len(os.listdir(OUT)), 'files to', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
