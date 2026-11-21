import sys; sys.path.insert(0, "/Users/kitano/pj/tools/chrome-hub")
from hub import connect
url = sys.argv[1]
with connect("playstore") as ctx:
    page = ctx.new_page()
    try:
        page.goto(url, wait_until="domcontentloaded")
        page.wait_for_timeout(6000)
        print(page.url)
        print(page.inner_text("body")[:2500])
    finally:
        page.close()
