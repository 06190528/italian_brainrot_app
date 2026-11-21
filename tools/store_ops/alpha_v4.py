import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
from sites.playstore_release import _set_file
AAB="/Users/kitano/pj/italian_brainrot_app/build/app/outputs/bundle/release/app-release.aab"
NOTES="広告を子供向けの設定にそろえ、ランキングの名前を自動で作る名前に変更しました。安定性の改善も含みます。"
NEW="4 (1.0.0)"
base=ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p=ctx.new_page()
    try:
        tid=ct.alpha_track_id(p, base)
        ct._goto(p, f"{base}/tracks/{tid}")
        btn=p.locator("[debug-id=create-android-release-button]").first
        if btn.is_disabled(): raise RuntimeError("button disabled")
        btn.click()
        p.get_by_text("App Bundle のアップロード").first.wait_for(timeout=60000)
        p.wait_for_timeout(3000)
        while p.locator("button:has-text('clear')").count():
            p.locator("button:has-text('clear')").first.click(); p.wait_for_timeout(1500)
        body=lambda: re.sub(r"\s+"," ",p.evaluate("document.body.textContent"))
        if NEW not in body():
            _set_file(p, "input[type=file]", AAB)
        for _ in range(80):
            p.wait_for_timeout(3000)
            if NEW in body(): break
        else: raise RuntimeError("upload not finished")
        print("uploaded", NEW)
        # 旧版の行(4以外)をリリースから外す
        for _ in range(5):
            old=p.locator("tr, [role=row]").filter(has_text=re.compile(r"\b[0-3] \(\d+\.\d+\.\d+\)")).filter(has_not_text=NEW).filter(has=p.locator("material-icon", has_text="more_vert"))
            if not old.count(): break
            old.last.locator("material-icon").filter(has_text="more_vert").first.click(); p.wait_for_timeout(1500)
            p.locator("#default-acx-overlay-container").get_by_text("「app bundle」を削除").first.click(); p.wait_for_timeout(3000)
        nb=p.locator("input[aria-label='リリース名']").first
        nb.fill("1.0.0 (4)")
        p.locator("textarea[aria-label='リリースノート']").first.fill(f"<ja-JP>\n{NOTES}\n</ja-JP>")
        p.wait_for_timeout(1000)
        p.evaluate("document.querySelectorAll('#google-hats-survey').forEach(e => e.remove())")
        print("bundles on page:", re.findall(r"\b\d+ \(\d+\.\d+\.\d+\)", body())[:6])
        p.get_by_role("button", name="未公開として保存").first.click(); p.wait_for_timeout(6000)
        p.get_by_role("button", name="次へ").first.click(); p.wait_for_timeout(6000)
        print(re.sub(r"\s+"," ",p.inner_text("body"))[:900])
        p.get_by_role("button", name="保存", exact=True).click(); p.wait_for_timeout(8000)
        print("saved to overview")
    finally:
        p.close()
