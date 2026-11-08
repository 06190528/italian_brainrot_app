import test from 'node:test';
import assert from 'node:assert/strict';
import { cleanName, composeRanking, thresholds, toEntries, TOP_N } from './aggregate.mjs';

test('toEntries: 降順・0点除外・tagはID末尾4桁', () => {
  const e = toEntries([
    { id: 'aaaa1111', name: 'A', score: 5 },
    { id: 'bbbb2222', name: 'B', score: 0 },
    { id: 'cccc3333', name: 'C', score: 9 },
    { id: 'dddd4444', name: 'D', score: 'x' },
  ]);
  assert.deepEqual(e.map((x) => [x.name, x.score, x.tag]), [['C', 9, '3333'], ['A', 5, '1111']]);
});

test('cleanName: 制御文字を除き、12文字まで、空ならPlayer', () => {
  assert.equal(cleanName('  a\u0000b\n '), 'ab');
  assert.equal(cleanName('あいうえおかきくけこさしすせ'), 'あいうえおかきくけこさし');
  assert.equal(cleanName('   '), 'Player');
  assert.equal(cleanName(undefined), 'Player');
});

test('composeRanking: 上位100まで。scores / cum を渡した方だけ入る', () => {
  const entries = Array.from({ length: 150 }, (_, i) => ({ name: 'n', score: 1000 - i, tag: 't' }));
  const r = composeRanking({ now: new Date('2026-11-09T00:00:00Z'), total: 150, entries, scores: entries.map((e) => e.score) });
  assert.equal(r.top.length, TOP_N);
  assert.equal(r.scores.length, 150);
  assert.equal(r.cum, undefined);
  assert.equal(r.updatedAt, '2026-11-09T00:00:00.000Z');
  const r2 = composeRanking({ now: new Date(), total: 9, entries: [], cum: [[1, 9]] });
  assert.deepEqual(r2.cum, [[1, 9]]);
  assert.equal(r2.scores, undefined);
});

test('thresholds: 昇順で重複なし、1から始まる', () => {
  const t = thresholds();
  assert.equal(t[0], 1);
  for (let i = 1; i < t.length; i++) assert.ok(t[i] > t[i - 1]);
});
