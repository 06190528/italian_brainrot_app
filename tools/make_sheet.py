"""asset_sources/characters/NN_slug/ の素材を、ゲーム用スプライトシートに変換し、
assets/images/characters/cNNN.png と assets/data/characters.json を作る。

使い方:
    python3 tools/make_sheet.py            # 全キャラ
    python3 tools/make_sheet.py 3 10 55    # 指定した id だけ(characters.json は全キャラ分を作り直す)
    python3 tools/make_sheet.py --json     # 画像は作らず characters.json だけ作り直す

入力(キャラのディレクトリ内。優先順位):
    ① src.gif / src.webp(アニメ+透過)  ② src.mp4(緑背景。chromakeyで抜く)  ③ 透過の静止画(src*.webp/png。擬似アニメ)
    ディレクトリに prefer_static という空ファイルを置くと、②を使わず ③(src_alt1.webp)を使う。
    メモ(characters.csv の note)に "chromakey 0xRRGGBB sim0.18" があれば、その色・類似度で抜く。
規格: 1フレーム FRAME px の正方形、COLS 列、最大 MAX_FRAMES フレーム、FPS コマ/秒。
依存: Pillow, ffmpeg。
"""
import csv, json, math, re, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageSequence

FRAME, COLS, MAX_FRAMES, FPS = 160, 6, 24, 10
MAX_SECONDS = MAX_FRAMES / FPS
DEFAULT_KEY, DEFAULT_SIM = "0x38FF14", 0.18

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "asset_sources/characters"
OUT = ROOT / "assets/images/characters"


def load_rows():
    rows = {}
    with open(ROOT / "asset_sources/characters.csv", newline="") as f:
        for r in csv.DictReader(f):
            rows[int(r["id"])] = r
    return rows


def frames_from_pil(path):
    im = Image.open(path)
    out, t, step = [], 0.0, 1.0 / FPS
    next_t = 0.0
    for fr in ImageSequence.Iterator(im):
        dur = (fr.info.get("duration") or 100) / 1000.0
        if t >= next_t - 1e-6:
            out.append(fr.convert("RGBA"))
            next_t += step
        t += dur
        if t > MAX_SECONDS:
            break
    return out


def best_window(path, key):
    """緑背景(キー色)の画素が多い区間の開始秒を返す。導入シーンや場面転換を避けるため。"""
    kr, kg, kb = int(key[2:4], 16), int(key[4:6], 16), int(key[6:8], 16)
    sr = 4  # 解析は 4コマ/秒
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-vf", f"fps={sr},scale=64:36", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True, check=True).stdout
    fs = 64 * 36 * 3
    fracs = []
    for i in range(len(raw) // fs):
        px = raw[i * fs:(i + 1) * fs]
        n = 0
        for j in range(0, fs, 3):
            if (px[j] - kr) ** 2 + (px[j + 1] - kg) ** 2 + (px[j + 2] - kb) ** 2 < 90 ** 2:
                n += 1
        fracs.append(n / (64 * 36))
    w = max(1, int(MAX_SECONDS * sr))
    if len(fracs) <= w:
        return 0.0
    best, best_i = -1.0, 0
    for i in range(len(fracs) - w + 1):
        win = fracs[i:i + w]
        score = sum(win) / w + 0.5 * min(win)  # 平均が高く、途中で途切れない区間
        if score > best:
            best, best_i = score, i
    return best_i / sr


def frames_from_video(path, key, sim, tmp):
    start = best_window(path, key)
    pat = str(tmp / "f_%03d.png")
    vf = f"fps={FPS},chromakey={key}:{sim}:0.04,format=rgba"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{start:.2f}", "-t", str(MAX_SECONDS), "-i", str(path), "-vf", vf, pat], check=True)
    return [Image.open(p).convert("RGBA") for p in sorted(tmp.glob("f_*.png"))][:MAX_FRAMES]


def pseudo_anim(im, n=12):
    """静止画に、上下の弾みとつぶれを付けた n コマを作る(同じ画像の変形)。"""
    w, h = im.size
    frames = []
    for i in range(n):
        k = math.sin(2 * math.pi * i / n)
        sx, sy = 1 - 0.04 * k, 1 + 0.04 * k
        fw, fh = max(1, int(w * sx)), max(1, int(h * sy))
        r = im.resize((fw, fh), Image.LANCZOS)
        canvas = Image.new("RGBA", (w, h + 12), (0, 0, 0, 0))
        canvas.paste(r, ((w - fw) // 2, h + 12 - fh - int(6 * (1 + k))), r)
        frames.append(canvas)
    return frames


def bbox_union(frames):
    box = None
    for f in frames:
        a = f.getchannel("A").point(lambda v: 255 if v > 12 else 0)
        b = a.getbbox()
        if b:
            box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    return box


def to_square(frames):
    box = bbox_union(frames)
    if box is None:
        raise RuntimeError("透明なフレームしかない")
    side = max(box[2] - box[0], box[3] - box[1])
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    margin = int(side * 0.04)
    half = side / 2 + margin
    crop = (int(cx - half), int(cy - half), int(cx + half), int(cy + half))
    out = []
    for f in frames:
        sq = Image.new("RGBA", (crop[2] - crop[0], crop[3] - crop[1]), (0, 0, 0, 0))
        sq.paste(f, (-crop[0], -crop[1]))
        out.append(sq.resize((FRAME, FRAME), Image.LANCZOS))
    return out


def make(cid, row, d):
    kind = None
    tmpdir = tempfile.TemporaryDirectory()
    tmp = Path(tmpdir.name)
    anim = [p for p in (d / "src.gif", d / "src.webp") if p.exists()]
    if (d / "prefer_static").exists():  # 動画の抜きが悪いキャラ: src_alt* の透過静止画を使う
        anim = []
    if anim:
        fr = frames_from_pil(anim[0])
        kind = "anim"
        if len(fr) < 2:
            fr, kind = pseudo_anim(fr[0]), "static"
    elif (d / "src.mp4").exists() and not (d / "prefer_static").exists():
        m = re.search(r"chromakey (0x[0-9A-Fa-f]{6})(?: sim([0-9.]+))?", row.get("note", ""))
        key = m.group(1) if m else DEFAULT_KEY
        sim = m.group(2) if m and m.group(2) else DEFAULT_SIM
        fr, kind = frames_from_video(d / "src.mp4", key, sim, tmp), "video"
    else:
        still = sorted([p for p in d.glob("src*") if p.suffix.lower() in (".webp", ".png")],
                       key=lambda p: (p.name != "src_alt1.webp" and (d / "prefer_static").exists(), p.name))
        if not still:
            raise RuntimeError("素材が無い")
        im = Image.open(still[0]).convert("RGBA")
        fr, kind = pseudo_anim(im), "static"
    sq = to_square(fr)
    n = len(sq)
    rows_n = math.ceil(n / COLS)
    sheet = Image.new("RGBA", (COLS * FRAME, rows_n * FRAME), (0, 0, 0, 0))
    for i, f in enumerate(sq):
        sheet.paste(f, ((i % COLS) * FRAME, (i // COLS) * FRAME))
    out = OUT / f"c{cid:03d}.png"
    sheet.save(out, optimize=True)
    tmpdir.cleanup()
    return kind, n, rows_n, out.stat().st_size


def write_json(rows):
    chars = []
    for cid in sorted(rows):
        r = rows[cid]
        f = OUT / f"c{cid:03d}.png"
        if not f.exists():
            continue
        im = Image.open(f)
        cols = im.width // FRAME
        rows_n = im.height // FRAME
        meta = json.loads((ROOT / "asset_sources/.sheet_meta.json").read_text()) if (ROOT / "asset_sources/.sheet_meta.json").exists() else {}
        frames = meta.get(str(cid), {}).get("frames", cols * rows_n)
        chars.append({"id": cid, "slug": r["slug"], "name": r["name"], "rarity": int(r.get("rarity") or 1),
                      "sheet": f"characters/c{cid:03d}.png", "cols": cols, "rows": rows_n,
                      "frames": frames, "stepTime": round(1.0 / FPS, 4)})
    (ROOT / "assets/data").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/data/characters.json").write_text(json.dumps({"characters": chars}, ensure_ascii=False, indent=1))
    print("characters.json:", len(chars), "体")


def main():
    args = sys.argv[1:]
    rows = load_rows()
    dirs = {int(p.name[:2]): p for p in SRC.iterdir() if p.is_dir() and p.name[:2].isdigit()}
    OUT.mkdir(parents=True, exist_ok=True)
    meta_path = ROOT / "asset_sources/.sheet_meta.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    if "--json" not in args:
        ids = [int(a) for a in args] or sorted(dirs)
        # 新しい素材で作り直すとき、古い仮キャラ(placeholder)のシートを消す
        for cid in ids:
            if cid not in dirs or cid not in rows:
                continue
            try:
                kind, n, rn, size = make(cid, rows[cid], dirs[cid])
                meta[str(cid)] = {"frames": n, "kind": kind}
                print(f"{cid:3d} {rows[cid]['slug']:34s} {kind:6s} {n:2d}f {COLS}x{rn} {size//1024}KB")
            except Exception as e:
                print(f"{cid:3d} {rows[cid]['slug']:34s} 失敗: {e}")
        meta_path.write_text(json.dumps(meta))
    write_json(rows)


if __name__ == "__main__":
    main()
