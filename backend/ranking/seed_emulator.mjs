// エミュレータ専用: テスト用のスコアを入れる。 使い方: node seed_emulator.mjs [人数=300]
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { randomBytes } from 'node:crypto';

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('エミュレータ以外には実行しない');
initializeApp({ projectId: process.env.GCLOUD_PROJECT });
const db = getFirestore();
const n = Number(process.argv[2] ?? 300);
let batch = db.batch();
for (let i = 0; i < n; i++) {
  const score = i % 50 === 0 ? 0 : Math.floor(Math.pow(Math.random(), 3) * 400) + 1; // 0点も混ぜる
  batch.set(db.collection('scores').doc(randomBytes(16).toString('hex')), { name: `Player${i}`, score });
  if (i % 400 === 399) { await batch.commit(); batch = db.batch(); }
}
await batch.commit();
console.log('seeded', n);
