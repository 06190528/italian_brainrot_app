"""Alphaの未公開リリース(prepare画面)に、ライブラリの versionCode 4 を追加して、名前・ノートを入れ、保存まで行う。
`alpha_v4.py` が「バージョン コード 4 はすでに使用されています」で上げられない時用(破棄した下書きのAABがライブラリに残っている)。
使い方: cd ~/pj/tools/chrome-hub && HUB_OWN_TAB=1 .venv/bin/python <このファイル> <リリース番号(prepareのURLの数字)>
書き込み: あり(下書きの保存。審査には送らない)"""
import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
REL = sys.argv[1]
NOTES = "広告を子供向けの設定にそろえ、ランキングの名前を自動で作る名前に変更しました。安定性の改善も含みます。"
base = ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p = ctx.new_page()
    try:
        ct._goto(p, f"{base}/tracks/4701203365123825249/releases/{REL}/prepare", 9000)
        body = lambda: re.sub(r"\s+", " ", p.evaluate("document.body.textContent"))
        while p.locator("button:has-text('clear')").count():  # 失敗したアップロードの残骸を消す
            p.locator("button:has-text('clear')").first.click(); p.wait_for_timeout(1500)
        p.get_by_text("ライブラリから追加").first.click(); p.wait_for_timeout(4000)
        ov = p.locator("#default-acx-overlay-container")
        row = ov.locator("tr, [role=row]").filter(has_text=re.compile(r"拡張\s+4\s+1\.0\.0")).first
        row.locator("mat-checkbox").first.click()
        p.wait_for_timeout(1000)
        ov.get_by_role("button", name="リリースに追加").click(); p.wait_for_timeout(5000)
        print("bundles:", re.findall(r"\b\d+ \(\d+\.\d+\.\d+\)", body())[:6])
        p.locator("input[aria-label='リリース名']").first.fill("1.0.0 (4)")
        p.locator("textarea[aria-label='リリースノート']").first.fill(f"<ja-JP>\n{NOTES}\n</ja-JP>")
        p.wait_for_timeout(1000)
        p.evaluate("document.querySelectorAll('#google-hats-survey').forEach(e => e.remove())")
        p.get_by_role("button", name="未公開として保存").first.click(); p.wait_for_timeout(6000)
        p.get_by_role("button", name="次へ").first.click(); p.wait_for_timeout(6000)
        print(re.sub(r"\s+", " ", p.inner_text("body"))[:900])
        p.get_by_role("button", name="保存", exact=True).click(); p.wait_for_timeout(8000)
        print("saved to overview")
    finally:
        p.close()
