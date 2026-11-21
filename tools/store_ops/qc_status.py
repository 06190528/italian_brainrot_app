import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
base=ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p=ctx.new_page()
    try:
        ct._goto(p, base+"/publishing", 10000)
        t=ct._txt(p)
        m=re.search(r"残り約 ?\d+ ?分", t)
        q=re.search(r"(\d+ 件の問題を表示|問題は見つかりませんでした|問題は検出されませんでした)", t)
        print("STATUS", m.group(0) if m else "no-remaining", "|", q.group(0) if q else "no-issue-text", "|", "send-btn" if re.search("件の変更を審査に送信", t) else "no-send")
    finally:
        p.close()
