import sys, json, re, tomllib; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from pathlib import Path
from hub import connect
import sites.appstore_version as av
from sites.appstore_privacy import _open, _click_next_until_save, TYPE_LABELS
asc=json.loads(open("/Users/kitano/pj/tools/chrome-hub/state/italianbrainrot.json").read())["asc_app"]["asc_app_id"]
spec=tomllib.loads(Path("/Users/kitano/pj/tools/chrome-hub/specs/italianbrainrot.toml").read_text())
col=spec["declarations"]["asc"]["collected"]
NEW=["USER_ID","GAMEPLAY_CONTENT"]
with connect(av.PROFILE) as ctx:
    p=ctx.new_page(); p.on("dialog", lambda d: d.accept())
    try:
        _open(p, asc); p.wait_for_timeout(3000)
        p.get_by_text("データタイプ", exact=True).first.locator("xpath=following::*[normalize-space(text())='編集'][1]").click(); p.wait_for_timeout(3000)
        d=p.locator("[role=dialog]").first
        d.get_by_role("button", name="次へ").click()
        p.wait_for_selector("#SELECT_CATEGORIES_checkbox_DEVICE_ID", state="attached", timeout=20000)
        print("PRE", [(x.get_attribute("id").replace("SELECT_CATEGORIES_checkbox_",""), x.is_checked()) for x in d.locator("input[type=checkbox]").all() if x.is_checked()])
        for t in NEW: p.locator(f"#SELECT_CATEGORIES_checkbox_{t}").check(force=True)
        print("POST", [x.get_attribute("id").replace("SELECT_CATEGORIES_checkbox_","") for x in d.locator("input[type=checkbox]").all() if x.is_checked()])
        dlg=p.locator("[role=dialog]").first
        (dlg.get_by_role("button", name="保存") if dlg.get_by_role("button", name="保存").count() else dlg.get_by_role("button", name="続ける")).click()
        p.wait_for_timeout(5000)
        ok=p.get_by_role("button", name="OK", exact=True)
        if ok.count(): ok.click(); p.wait_for_timeout(1500)
        for t in NEW:
            link=p.get_by_text(f"{TYPE_LABELS[t]}を設定", exact=True)
            print("LINK", t, link.count())
            if link.count():
                link.click(); p.wait_for_timeout(2500); _click_next_until_save(p, t, col[t])
        body=re.sub(r"\s+"," ",p.inner_text("body")); i=body.find("データタイプ")
        print("AFTER", body[i:i+700])
        print("PUBLISH-BTN", p.get_by_role("button", name="公開", exact=True).count())
    finally: p.close()
