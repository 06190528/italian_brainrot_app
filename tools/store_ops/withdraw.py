import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
base=ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p=ctx.new_page()
    try:
        ct._goto(p, base+"/publishing", 10000)
        p.get_by_text("変更を削除").first.click(); p.wait_for_timeout(3000)
        ov=p.locator("#default-acx-overlay-container")
        print("DIALOG", ct._txt(p,"#default-acx-overlay-container")[:900])
        ov.get_by_role("button", name=re.compile("変更を削除|削除")).last.click(); p.wait_for_timeout(8000)
        print("AFTER", ct._txt(p)[300:2200])
    finally:
        p.close()
