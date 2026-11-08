"""仮キャラ(色つきの丸+番号)の画像と assets/data/characters.json を作る。
使い方: python3 tools/make_placeholders.py [個数=51]
本物の素材が届いたら tools/make_sheet.py で置き換える(同じ id・同じファイル名 c000.png ...)。
フレーム仕様: 256x256, cols x rows のスプライトシート。仮キャラは 1 フレーム。
"""
import colorsys, json, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

N = int(sys.argv[1]) if len(sys.argv) > 1 else 51
root = Path(__file__).resolve().parent.parent
out = root / "assets/images/characters"
out.mkdir(parents=True, exist_ok=True)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 96)
except Exception:
    font = ImageFont.load_default()
chars = []
for i in range(N):
    r, g, b = [int(c * 255) for c in colorsys.hsv_to_rgb((i * 0.618) % 1, 0.6, 0.95)]
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((12, 12, 244, 244), fill=(r, g, b, 255), outline=(40, 40, 40, 255), width=8)
    t = str(i)
    w = d.textlength(t, font=font)
    d.text((128 - w / 2, 80), t, fill=(30, 30, 30, 255), font=font)
    im.save(out / f"c{i:03d}.png")
    chars.append({"id": i, "slug": f"placeholder-{i}", "name": f"Brainrot #{i}",
                  "rarity": 1 + i * 5 // N, "sheet": f"characters/c{i:03d}.png",
                  "cols": 1, "rows": 1, "frames": 1, "stepTime": 0.1})
(root / "assets/data").mkdir(parents=True, exist_ok=True)
(root / "assets/data/characters.json").write_text(json.dumps({"characters": chars}, ensure_ascii=False, indent=1))
print("wrote", N, "placeholders")
