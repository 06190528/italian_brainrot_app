// Firestore に依存しない、順位表JSONの組み立て(テストしやすいように分けてある)。

export const TOP_N = 100;
/** この人数以下なら、全員のスコアを JSON に入れる(順位が正確になる) */
export const SMALL_LIMIT = Number(process.env.RANKING_SMALL_LIMIT ?? 5000);
export const NAME_MAX = 12;

/** 概算用のしきい値(スコア以上の人数を数える点)。細かく→粗く */
export function thresholds() {
  const t = [];
  for (let i = 1; i <= 50; i++) t.push(i);
  for (let i = 55; i <= 200; i += 5) t.push(i);
  for (let i = 210; i <= 1000; i += 10) t.push(i);
  for (let i = 1100; i <= 10000; i += 100) t.push(i);
  for (let i = 11000; i <= 100000; i += 1000) t.push(i);
  return t;
}

export function cleanName(name) {
  const s = String(name ?? '').replace(/[\u0000-\u001f\u007f]/g, '').trim();
  return Array.from(s).slice(0, NAME_MAX).join('') || 'Player';
}

/** docs: [{id, name, score}]。降順に並べて、上位とタグ(IDの末尾4桁)を作る */
export function toEntries(docs) {
  return docs
    .filter((d) => Number.isInteger(d.score) && d.score > 0)
    .sort((a, b) => b.score - a.score)
    .map((d) => ({ name: cleanName(d.name), score: d.score, tag: String(d.id).slice(-4) }));
}

/**
 * @param {object} p
 * @param {Date} p.now
 * @param {number} p.total        score>0 の人数
 * @param {Array}  p.entries      降順の上位(全員でも可)
 * @param {number[]} [p.scores]   少人数のとき: 全員のスコア(降順)
 * @param {number[][]} [p.cum]    多人数のとき: [しきい値, そのスコア以上の人数]
 */
export function composeRanking({ now, total, entries, scores, cum }) {
  const out = { version: 1, updatedAt: now.toISOString(), total, top: entries.slice(0, TOP_N) };
  if (scores) out.scores = scores;
  if (cum) out.cum = cum;
  return out;
}
