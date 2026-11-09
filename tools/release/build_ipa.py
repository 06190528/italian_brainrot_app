"""iOSのリリースビルド(.ipa)を作る。署名は、App Store ConnectのAPIキー(.p8)による自動署名(Xcodeへのログイン不要)。

使い方:
    python3 tools/release/build_ipa.py <spec.toml> <アプリのフォルダ>
例:
    python3 tools/release/build_ipa.py ~/pj/tools/chrome-hub/specs/italianbrainrot.toml .
入力: spec の [build.ios_upload](api_key_path / key_id / issuer_id)。チームIDは、Xcodeプロジェクトの DEVELOPMENT_TEAM。
前提: 配布用の証明書(Apple Distribution)が、キーチェーンにあること(Xcode → Settings → Accounts → Manage Certificates)。書き出しは、APIキーで失敗したら、Xcodeのアカウントで再試行する。
手順: flutter build ios --release --no-codesign(Dart側のビルド)→ xcodebuild archive → xcodebuild -exportArchive(-allowProvisioningUpdates +APIキー)
出力: <アプリ>/build/ios/ipa/*.ipa(spec の [build].ipa に、そのパスを記入する)
注意: キー・IDは、画面に出さない(ログにも書かない)。
"""
import plistlib
import re
import subprocess
import sys
import tomllib
from pathlib import Path

FVM_FLUTTER = Path.home() / "fvm/versions/3.35.4/bin/flutter"
ENV = {"DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer"}


def run(cmd, cwd):
    import os
    r = subprocess.run(cmd, cwd=cwd, env={**os.environ, **ENV}, capture_output=True, text=True)
    return r


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    spec = tomllib.load(open(sys.argv[1], "rb"))["build"]["ios_upload"]
    app = Path(sys.argv[2]).resolve()
    key = str(Path(spec["api_key_path"]).expanduser())
    auth = ["-allowProvisioningUpdates", "-authenticationKeyPath", key, "-authenticationKeyID", spec["key_id"], "-authenticationKeyIssuerID", spec["issuer_id"]]
    team = re.search(r"DEVELOPMENT_TEAM = (\w+);", (app / "ios/Runner.xcodeproj/project.pbxproj").read_text()).group(1)
    flutter = str(FVM_FLUTTER) if FVM_FLUTTER.exists() else "flutter"

    print("1/3 flutter build ios (Dart側)")
    r = run([flutter, "build", "ios", "--release", "--no-codesign", "--no-pub"], app)
    if r.returncode:
        sys.exit("ERROR flutter build ios:\n" + r.stdout[-2000:] + r.stderr[-1000:])
    archive = app / "build/ios/Runner.xcarchive"
    print("2/3 xcodebuild archive(署名つき)")
    r = run(["xcodebuild", "-workspace", "ios/Runner.xcworkspace", "-scheme", "Runner", "-configuration", "Release", "-destination", "generic/platform=iOS",
             "-archivePath", str(archive), "archive", *auth], app)
    if r.returncode:
        sys.exit("ERROR archive:\n" + "\n".join((r.stdout + r.stderr).splitlines()[-25:]))
    opts = app / "build/ios/ExportOptions.plist"
    opts.write_bytes(plistlib.dumps({"method": "app-store-connect", "teamID": team, "signingStyle": "automatic", "uploadSymbols": True}))
    print("3/3 xcodebuild -exportArchive(.ipa)")
    out = app / "build/ios/ipa"
    export = ["xcodebuild", "-exportArchive", "-archivePath", str(archive), "-exportPath", str(out), "-exportOptionsPlist", str(opts)]
    r = run([*export, *auth], app)
    if r.returncode:  # APIキーが「App管理」だと、配布用のプロファイルの自動作成が拒否される。その場合は、Xcodeにサインイン済みのアカウントで、もう一度試す
        print("  APIキーでの書き出しに失敗。Xcodeのアカウントで再試行")
        r = run([*export, "-allowProvisioningUpdates"], app)
    if r.returncode:
        sys.exit("ERROR export:\n" + "\n".join((r.stdout + r.stderr).splitlines()[-25:]))
    for f in sorted(out.glob("*.ipa")):
        print(f"出力: {f} ({f.stat().st_size // 1024 // 1024}MB)")


if __name__ == "__main__":
    main()
