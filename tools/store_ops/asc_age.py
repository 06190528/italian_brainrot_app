import sys, json, re, tomllib; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from pathlib import Path
from hub import connect
import sites.appstore_version as av
asc=json.loads(open("/Users/kitano/pj/tools/chrome-hub/state/italianbrainrot.json").read())["asc_app"]["asc_app_id"]
ans=tomllib.loads(Path("/Users/kitano/pj/tools/chrome-hub/specs/italianbrainrot.toml").read_text())["asc"]["age_rating"]
with connect(av.PROFILE) as ctx:
    p=ctx.new_page(); p.on("dialog", lambda d: d.accept())
    try:
        p.goto(av.BASE.format(app_id=asc)+"/info", wait_until="domcontentloaded")
        p.wait_for_timeout(15000)
        entry=p.get_by_role("button", name="年齢制限指定を設定")
        if entry.count()==0:
            entry=p.locator("xpath=//*[normalize-space(text())='アプリの年齢制限指定']/following::*[normalize-space(text())='編集'][1]").first
        entry.click()
        d=p.locator("[role=dialog]"); d.get_by_role("button", name="次へ").wait_for(timeout=20000)
        for n,step in enumerate(av.AGE_RATING_STEPS):
            rows=d.locator("tr")
            for k in range(rows.count()):
                text=rows.nth(k).inner_text(); radios=rows.nth(k).locator("input[type=radio]")
                key=next((v for w,v in step if w in text), None)
                if key and radios.count()>=2: radios.nth(av._age_index(ans[key])).check(force=True)
            nxt=d.get_by_role("button", name="次へ")
            if not nxt.is_enabled():
                print("STEP",n,"BLOCKED")
                for k in range(rows.count()):
                    r=rows.nth(k); rd=r.locator("input[type=radio]")
                    print("  ROW", re.sub(r"\s+"," ",r.inner_text())[:110], "| checked:", [rd.nth(i).is_checked() for i in range(rd.count())])
                print("  HEAD", re.sub(r"\s+"," ",d.first.inner_text())[:500]); break
            nxt.click(); p.wait_for_timeout(1800)
        else:
            print("ALL STEPS OK", re.sub(r"\s+"," ",d.first.inner_text())[-400:])
        d.get_by_role("button", name="キャンセル").click()
    finally: p.close()
