import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
base=ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p=ctx.new_page()
    try:
        ct._goto(p, base+"/publishing", 10000)
        b=p.get_by_role("button", name=re.compile("件の変更を審査に送信")).first
        print("SEND enabled:", b.is_enabled())
        # the v4 release row / details
        ct._goto(p, base+"/app-content/ad-id-declaration", 7000)
        print("ADID", [i.is_checked() for i in p.locator("input[type=radio]").all()])
    finally:
        p.close()
