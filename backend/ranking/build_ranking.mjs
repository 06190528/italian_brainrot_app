// 使い方: node build_ranking.mjs <出力先.json>
// 認証: GOOGLE_APPLICATION_CREDENTIALS(サービスアカウント。読み取り権限だけ)。
//       エミュレータで試す時は FIRESTORE_EMULATOR_HOST と GCLOUD_PROJECT を設定する。
// 読み取りコスト: 少人数(<= 5000)は全件、それ以上は 上位100件 + 集計クエリ(1000件ごとに1読み取り)。
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { SMALL_LIMIT, TOP_N, composeRanking, thresholds, toEntries } from './aggregate.mjs';

const outPath = process.argv[2] ?? 'out/ranking.json';
initializeApp(process.env.GCLOUD_PROJECT ? { projectId: process.env.GCLOUD_PROJECT } : undefined);
const col = getFirestore().collection('scores');

const positive = col.where('score', '>', 0);
const total = (await positive.count().get()).data().count;

let result;
if (total <= SMALL_LIMIT) {
  const snap = await positive.select('name', 'score').get();
  const entries = toEntries(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
  result = composeRanking({ now: new Date(), total, entries, scores: entries.map((e) => e.score) });
} else {
  const snap = await col.orderBy('score', 'desc').limit(TOP_N).select('name', 'score').get();
  const entries = toEntries(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
  const cum = [];
  const ts = thresholds();
  for (let i = 0; i < ts.length; i += 20) {
    const batch = ts.slice(i, i + 20);
    const counts = await Promise.all(batch.map((t) => col.where('score', '>=', t).count().get()));
    batch.forEach((t, k) => cum.push([t, counts[k].data().count]));
  }
  result = composeRanking({ now: new Date(), total, entries, cum });
}

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(result));
console.log(`ranking.json: total=${total}, top=${result.top.length}, ${result.scores ? 'scores' : 'cum'} → ${outPath}`);
