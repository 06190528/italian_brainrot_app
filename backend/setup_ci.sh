#!/bin/bash
# ランキング集計ジョブ(GitHub Actions)用の、読み取り専用サービスアカウントを作り、
# 鍵を GitHub の Secret(FIREBASE_SERVICE_ACCOUNT)に登録する。1回だけ実行する。
#
# 事前: gcloud auth login(ブラウザ) / gh auth login 済みであること。
# 使い方: backend/setup_ci.sh
# 鍵ファイルは一時ファイルに作り、登録したらすぐ消す(リポジトリには残らない)。
set -euo pipefail
PROJECT="${PROJECT:-italian-brainrot-p3vkon}"
REPO="${REPO:-06190528/italian_brainrot_app}"
SA_NAME="ranking-job"
SA="$SA_NAME@$PROJECT.iam.gserviceaccount.com"
KEY="$(mktemp -t ranking-sa).json"
trap 'rm -f "$KEY"' EXIT

gcloud services enable iam.googleapis.com --project "$PROJECT"
gcloud iam service-accounts describe "$SA" --project "$PROJECT" >/dev/null 2>&1 || \
  gcloud iam service-accounts create "$SA_NAME" --display-name "Ranking job (read-only)" --project "$PROJECT"
# Firestore の読み取りだけ(書き込み・削除はできない)
gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA" --role roles/datastore.viewer --condition=None >/dev/null
gcloud iam service-accounts keys create "$KEY" --iam-account "$SA" --project "$PROJECT"
gh secret set FIREBASE_SERVICE_ACCOUNT --repo "$REPO" < "$KEY"
echo "OK: Secret FIREBASE_SERVICE_ACCOUNT を登録しました。Actions の ranking を手動実行して確認してください。"
