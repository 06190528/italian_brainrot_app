"""キャラのスプライトシートを正規化する(中心ずれ・コマごとの大きさのばらつきを補正)。
使い方:
  python3 tools/normalize_chars.py            # 診断のみ(dry-run)。問題のあるシートだけ1行ずつ出す
  python3 tools/normalize_chars.py --apply    # 補正して上書き(元は assets/images/characters_orig/ に退避)
  python3 tools/normalize_chars.py --sheet    # 補正前後のコンタクトシートを scratch に出す(--apply と併用可)
補正: 1) 各コマの大きさ(bbox長辺)をシートの中央値に揃える(比率維持・セルに収める)
      2) 各コマのbbox中心をセル中心に合わせる
閾値: SCALE_TOL(大きさ差) / OFF_TOL(中心ずれ、セル幅に対する割合)
"""
import json, sys, os, shutil, statistics as st
from PIL import Image
R='assets/images/'; SCALE_TOL=0.08; OFF_TOL=0.03
apply='--apply' in sys.argv
chars=json.load(open('assets/data/characters.json'))['characters']
def analyze(c):
    im=Image.open(R+c['sheet']).convert('RGBA'); cols,rows,n=c['cols'],c['rows'],c['frames']
    cw,ch=im.width//cols,im.height//rows; fr=[]
    for i in range(n):
        x,y=(i%cols)*cw,(i//cols)*ch
        cell=im.crop((x,y,x+cw,y+ch)); bb=cell.getchannel('A').point(lambda a:255 if a>8 else 0).getbbox()
        fr.append((cell,bb))
    return im,cw,ch,fr
bad=0; out=[]
for c in chars:
    im,cw,ch,fr=analyze(c); cols=c['cols']
    dims=[max(b[2]-b[0],b[3]-b[1]) if b else 0 for _,b in fr]
    med=st.median([d for d in dims if d]) or 1
    sdev=max(abs(d/med-1) for d in dims if d)
    odev=max(max(abs((b[0]+b[2])/2-cw/2)/cw,abs((b[1]+b[3])/2-ch/2)/ch) for _,b in fr if b)
    if sdev>SCALE_TOL or odev>OFF_TOL:
        bad+=1; print(f"c{c['id']:03d} scale±{sdev:.0%} off {odev:.1%} cell {cw}x{ch}")
    if apply and (sdev>SCALE_TOL or odev>OFF_TOL):
        new=Image.new('RGBA',im.size,(0,0,0,0))
        for i,(cell,bb) in enumerate(fr):
            if not bb: continue
            crop=cell.crop(bb); w,h=crop.size; s=med/max(w,h)
            s=min(s,cw/w,ch/h)  # セルに収める
            if abs(s-1)<0.02: s=1
            if s!=1: crop=crop.resize((max(1,round(w*s)),max(1,round(h*s))),Image.LANCZOS)
            x,y=(i%cols)*cw,(i//cols)*ch
            new.paste(crop,(x+(cw-crop.width)//2,y+(ch-crop.height)//2))
        os.makedirs(R+'characters_orig',exist_ok=True)
        bk=R+'characters_orig/'+os.path.basename(c['sheet'])
        if not os.path.exists(bk): shutil.copy(R+c['sheet'],bk)
        new.save(R+c['sheet'],lossless=True,quality=100,method=6)
print(f"対象 {bad}/{len(chars)} シート"+(" (補正済み)" if apply else " (dry-run)"))
