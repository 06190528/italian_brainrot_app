import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
base=ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p=ctx.new_page()
    try:
        ct._goto(p, base+"/publishing", 10000)
        p.get_by_text("問題を表示").first.click(); p.wait_for_timeout(4000)
        print(ct._txt(p,"#default-acx-overlay-container")[:2500])
    finally:
        p.close()
