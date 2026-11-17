#!/usr/bin/env python3
"""ガチャの「ゲットできた」音を、合成して作る(自作のため、ライセンスの問題がない)。
使い方: python3 tools/make_gatya_sounds.py   (numpy と ffmpeg が必要)
出力: asset_sources/sound/se/get_character.wav(通常) と get_rare.wav(★4・5用。長く豪華)
そのあと tools/convert_sounds.sh で assets/sounds/*.mp3 にする。
音: ベル系の音(倍音つき)で、上がっていくアルペジオ→和音の余韻→きらめき。
"""
import subprocess, tempfile, wave, os
import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def bell(freq, dur, vel=1.0, decay=4.0):
    t = np.arange(int(SR * dur)) / SR
    # ベルらしい倍音(非整数倍を混ぜる)
    parts = [(1, 1.0), (2, 0.5), (3, 0.28), (4.2, 0.18), (5.4, 0.1)]
    y = sum(a * np.sin(2 * np.pi * freq * k * t) * np.exp(-decay * (1 + 0.3 * k) * t / dur * 1.0) for k, a in parts)
    attack = np.minimum(1, t / 0.004)  # クリックを避ける短い立ち上がり
    return vel * y * attack


def place(out, sig, start):
    i = int(start * SR)
    out[i:i + len(sig)] += sig[:len(out) - i]


def sparkle(out, start, n, lo, hi, span, vel=0.18):
    for _ in range(n):
        f = hz(rng.integers(lo, hi))
        place(out, bell(f, 0.35, vel * rng.uniform(0.5, 1), decay=6), start + rng.uniform(0, span))


def make(notes, chord, total, sparkles):
    out = np.zeros(int(SR * total))
    for i, (m, st) in enumerate(notes):
        place(out, bell(hz(m), 0.9, 0.7 + 0.04 * i, decay=3.5), st)
    t0 = notes[-1][1] + 0.12
    for m in chord:  # 最後の和音(長めの余韻)
        place(out, bell(hz(m), total - t0, 0.55, decay=3.0), t0)
    for args in sparkles:
        sparkle(out, *args)
    # 軽いエコー
    d = int(0.13 * SR)
    out[d:] += 0.28 * out[:-d]
    out /= np.max(np.abs(out)) / 0.89  # 最大を約-1dBに
    fade = int(0.05 * SR)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


def save(name, sig):
    with tempfile.TemporaryDirectory() as d:
        w = os.path.join(d, 'x.wav')
        with wave.open(w, 'wb') as f:
            f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
            f.writeframes((sig * 32767).astype(np.int16).tobytes())
        dst = f'asset_sources/sound/se/{name}.wav'  # このffmpegにはoggの符号化が無いので、wavで置く
        subprocess.run(['ffmpeg', '-v', 'fatal', '-y', '-i', w, '-ac', '2', dst], check=True)
        print(dst, f'{len(sig) / SR:.2f}s')


# 通常: C長調のアルペジオ(ド・ミ・ソ・高いド)→ ドミソドの和音
save('get_character', make(
    [(72, 0.00), (76, 0.09), (79, 0.18), (84, 0.27)], [72, 76, 79, 84, 88], 1.7,
    [(0.35, 5, 84, 100, 0.8)]))
# レア(★4・5): 長い上昇 → 高い和音。きらめきを多めに
save('get_rare', make(
    [(60, 0.00), (64, 0.08), (67, 0.16), (72, 0.24), (76, 0.32), (79, 0.40), (84, 0.50), (88, 0.62)],
    [72, 76, 79, 84, 88, 91], 2.8,
    [(0.55, 14, 86, 108, 1.6)]))
