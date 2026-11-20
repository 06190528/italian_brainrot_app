# Playサポートへの問い合わせ文面(広告IDの申告エラーで、審査に送信できない件)

作成: 2026-11-21。状況の記録も兼ねる。送信は、Play Console の「ヘルプ → お問い合わせ」から(ユーザーが行う)。

## 状況(事実)
- 公開の概要の「審査にまだ送信されていない変更」(6件: v4=1.0.0(4)・トラック再開・テスター・フィードバック先・対象年齢・データセーフティ)に、「1 件の問題がすべての変更に影響しています: 広告 ID の申告が不完全です」と出て、「審査に送信」が押せない。
- 広告IDの申告(アプリのコンテンツ → 広告 ID)は「いいえ」で保存済み(開き直して確認。未保存の変更なし)。アプリのコンテンツ一覧の「要注意」は0件。
- 試したこと: ①「はい」→「いいえ」と保存し直し ②審査中のv3を「変更を削除」して全変更を未送信にまとめ直し ③クイックチェック(約14分)の完了を待つ。どれでも解消しない。
- v4のAABは、`com.google.android.gms.permission.AD_ID` を `tools:node="remove"` で外してある(広告IDを使わない。対象年齢に13歳未満を含むため)。

## 文面(日本語)
件名: 広告IDの申告は「いいえ」で保存済みなのに、公開の概要で「申告が不完全」と表示され、変更を審査に送信できません

アプリ: イタリアンブレインロット大戦争(com.okinnnikudekao.italianbrainrot)
公開の概要に「広告 ID の申告が不完全です」というエラーが出て、クローズドテスト(Alpha)の1.0.0(4)を含む変更を審査に送信できません。
・アプリのコンテンツの「広告 ID」は「いいえ」で保存済みで、「要注意」の項目はありません。
・1.0.0(4)のAABは、AD_ID権限をマニフェストで削除しています(13歳未満を含む対象年齢のため、広告IDを使用しません)。
・申告の保存し直し、審査中の変更の削除、クイックチェックの完了待ちを試しましたが、エラーは消えません。
エラーの原因と、解消方法を教えてください。

## 文面(英語)
Subject: Ad ID declaration is saved as "No", but Publishing overview says it is incomplete and blocks sending changes for review
App: com.okinnnikudekao.italianbrainrot
The Publishing overview shows "Advertising ID declaration is incomplete" and the "Send changes for review" button is disabled (Closed testing - Alpha, release 1.0.0 (4)). The Ad ID declaration under App content is saved as "No" and there are no pending App content items. The AAB removes the AD_ID permission via manifest merge (target audience includes children under 13). I re-saved the declaration, deleted the in-review changes and waited for the quick check to finish; the error remains. Please tell me what causes it and how to clear it.
