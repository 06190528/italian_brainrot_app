import sys, json; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from pathlib import Path
from hub import connect
from sites.playstore_content import PROFILE, _open
from sites.playstore_datasafety import SLUG
app = json.loads(Path("/Users/kitano/pj/tools/chrome-hub/state/italianbrainrot.json").read_text())["play_app"]["play_app_id"]
out = Path(sys.argv[1])
with connect(PROFILE) as ctx:
    page = ctx.new_page()
    try:
        _open(page, app, SLUG, "データ セーフティ")
        with page.expect_download(timeout=30000) as dl:
            page.get_by_text("CSV にエクスポート", exact=True).locator("visible=true").first.click()
        dl.value.save_as(out)
    finally:
        page.close()
print("saved", out)
