#!/usr/bin/env python3
"""Synthesises the game's sound effects into assets/sounds/.

Pure standard library, deterministic (fixed seed), so the files can be
regenerated at any time:

    python3 tool/make_sounds.py

Writes 22050 Hz mono 16-bit WAVs:
  drumroll.wav   a snare roll that swells, then a crash
  zaghrouta.wav  a joyful ululation trill
  trombone.wav   the sad trombone: wah, wah, wah, waaah
"""

import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'sounds')


def write(name, samples):
    """Normalises to 90% full scale and writes a 16-bit mono WAV."""
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.9 * 32767 / peak
    # Short fades so the file never starts or ends on a click.
    fade = int(0.005 * RATE)
    data = bytearray()
    for i, s in enumerate(samples):
        edge = min(1.0, i / fade, (len(samples) - 1 - i) / fade)
        data += struct.pack('<h', int(max(-32767, min(32767, s * scale * edge))))
    path = os.path.join(OUT, name)
    with wave.open(path, 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(data))
    print(f'{path}: {len(samples) / RATE:.2f} s, {os.path.getsize(path) // 1024} KB')


def lowpass(samples, amount):
    """One-pole low-pass; amount near 1 keeps more highs."""
    out, prev = [], 0.0
    for s in samples:
        prev += amount * (s - prev)
        out.append(prev)
    return out


def drumroll(rng):
    roll = 0.95
    total = roll + 0.4
    n = int(total * RATE)
    out = [0.0] * n
    # Snare hits every ~38 ms, alternating hands, swelling from soft to loud.
    t = 0.0
    hand = 0
    while t < roll:
        start = int(t * RATE)
        loud = 0.25 + 0.75 * (t / roll) ** 1.6
        loud *= 0.85 if hand else 1.0
        length = int(0.07 * RATE)
        for i in range(length):
            if start + i >= n:
                break
            env = math.exp(-i / (0.018 * RATE))
            noise = rng.uniform(-1, 1)
            body = math.sin(2 * math.pi * 190 * i / RATE) * 0.5
            out[start + i] += loud * env * (noise * 0.8 + body * 0.4)
        t += 0.038 + rng.uniform(-0.003, 0.003)
        hand ^= 1
    # The final hit: a low thump plus a long crash-cymbal hiss.
    start = int(roll * RATE)
    prev = 0.0
    for i in range(n - start):
        x = i / RATE
        thump = math.sin(2 * math.pi * (110 - 50 * min(1, x / 0.15)) * x) * math.exp(-x / 0.12)
        noise = rng.uniform(-1, 1)
        hiss = noise - prev  # a crude high-pass for a brighter crash
        prev = noise
        crash = hiss * math.exp(-x / 0.22)
        out[start + i] += 1.3 * thump + 0.9 * crash
    return lowpass(out, 0.75)


def zaghrouta(rng):
    total = 1.8
    n = int(total * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        x = i / RATE
        p = x / total
        # Rising then falling pitch contour, with the fast tongue trill on top.
        base = 950 + 300 * math.sin(math.pi * min(1.0, p * 1.15))
        trill_rate = 12.5 + 1.5 * math.sin(2 * math.pi * 0.7 * x)
        trill = math.sin(2 * math.pi * trill_rate * x)
        freq = base * (1 + 0.06 * trill) + rng.uniform(-4, 4)
        phase += 2 * math.pi * freq / RATE
        # A voice, not a beep: a few harmonics that fall off.
        voice = math.sin(phase) + 0.45 * math.sin(2 * phase) + 0.2 * math.sin(3 * phase) + 0.08 * math.sin(4 * phase)
        flutter = 0.6 + 0.4 * (0.5 + 0.5 * trill)
        # Quick rise, long hold, then a falling tail.
        env = min(1.0, x / 0.12) * (1.0 if p < 0.7 else max(0.0, 1 - (p - 0.7) / 0.3) ** 1.3)
        breath = rng.uniform(-1, 1) * 0.04
        out.append(env * (voice * flutter + breath))
    return lowpass(out, 0.6)


def trombone(rng):
    # Four descending notes; the last one is long and wobbles.
    notes = [(311.1, 0.30), (293.7, 0.30), (277.2, 0.30), (261.6, 0.70)]
    out = []
    phase = 0.0
    for index, (pitch, length) in enumerate(notes):
        last = index == len(notes) - 1
        n = int(length * RATE)
        for i in range(n):
            x = i / RATE
            freq = pitch
            if last:
                # Vibrato that widens, and a droop at the very end.
                freq *= 1 + (0.012 + 0.025 * x / length) * math.sin(2 * math.pi * 5.5 * x)
                freq *= 1 - 0.05 * max(0.0, (x - length * 0.6) / (length * 0.4))
            else:
                freq *= 1 - 0.015 * x / length
            phase += 2 * math.pi * freq / RATE
            # The "wah": the mute opens then closes, brightening the tone.
            open_ = math.sin(math.pi * min(1.0, x / length)) ** 0.6
            bright = 0.35 + 0.65 * open_
            brass = sum((bright ** (k - 1)) * math.sin(k * phase) / k ** 0.8 for k in range(1, 8))
            attack = min(1.0, x / 0.03)
            release = min(1.0, (length - x) / 0.05)
            out.append(brass * attack * release * (0.55 + 0.45 * open_))
    return lowpass(out, 0.5)


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(7)
    write('drumroll.wav', drumroll(rng))
    write('zaghrouta.wav', zaghrouta(rng))
    write('trombone.wav', trombone(rng))


if __name__ == '__main__':
    main()
