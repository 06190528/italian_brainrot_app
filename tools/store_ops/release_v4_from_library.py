"""指定トラックに、新しいリリース(ライブラリの versionCode 4)を作って、保存する(審査・公開には送らない。公開の概要にたまる)。
使い方: cd ~/pj/tools/chrome-hub && HUB_OWN_TAB=1 .venv/bin/python <このファイル> <トラック: internal-testing | production | open-testing | <数字のトラックID>> [--yes]
  --yes が無ければ、「新しいリリースを作成」を押して、AABを選ぶところまで(保存しない)。
書き込み: --yes の時、下書きの保存(外には出ない。公開は、公開の概要の「審査に送信」で行う)"""
import sys, re; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
import closed_testing as ct
TRACK = sys.argv[1]; YES = "--yes" in sys.argv
NOTES = "広告を子供向けの設定にそろえ、ランキングの名前を自動で作る名前に変更しました。安定性の改善も含みます。"
base = ct._base("italianbrainrot")
with connect("playstore") as ctx:
    p = ctx.new_page()
    try:
        ct._goto(p, f"{base}/tracks/{TRACK}", 9000)
        print("track:", re.sub(r"\s+", " ", p.inner_text("body"))[:500])
        btn = p.locator("[debug-id=create-android-release-button]").first
        if btn.is_disabled(): raise SystemExit("「新しいリリースを作成」が無効(未保存の下書きがある可能性)")
        btn.click()
        p.get_by_text("App Bundle のアップロード").first.wait_for(timeout=60000); p.wait_for_timeout(4000)
        while p.locator("button:has-text('clear')").count():
            p.locator("button:has-text('clear')").first.click(); p.wait_for_timeout(1500)
        p.get_by_text("ライブラリから追加").first.click(); p.wait_for_timeout(4000)
        ov = p.locator("#default-acx-overlay-container")
        row = ov.locator("tr, [role=row]").filter(has_text=re.compile(r"拡張\s+4\s+1\.0\.0")).first
        row.locator("mat-checkbox").first.click(); p.wait_for_timeout(1000)
        ov.get_by_role("button", name="リリースに追加").click(); p.wait_for_timeout(5000)
        body = lambda: re.sub(r"\s+", " ", p.evaluate("document.body.textContent"))
        print("新しいApp Bundle:", re.findall(r"新しい App Bundle.{0,200}", body())[:1])
        if not YES:
            print("--yes が無いので、ここで止める(保存しない)"); raise SystemExit(0)
        p.locator("input[aria-label='リリース名']").first.fill("1.0.0 (4)")
        p.locator("textarea[aria-label='リリースノート']").first.fill(f"<ja-JP>\n{NOTES}\n</ja-JP>"); p.wait_for_timeout(1000)
        p.evaluate("document.querySelectorAll('#google-hats-survey').forEach(e => e.remove())")
        p.get_by_role("button", name="未公開として保存").first.click(); p.wait_for_timeout(6000)
        p.get_by_role("button", name="次へ").first.click(); p.wait_for_timeout(7000)
        print(re.sub(r"\s+", " ", p.inner_text("body"))[:1200])
        p.get_by_role("button", name="保存", exact=True).click(); p.wait_for_timeout(8000)
        print("保存した(公開の概要にたまる)")
    finally:
        p.close()
