import 'package:flutter_test/flutter_test.dart';
import 'package:italian_brainrot_app/data/collection_bonus.dart';

void main() {
  test('ボーナスの段階(境界)', () {
    expect(collectionBonusPercent(1), 0);
    expect(collectionBonusPercent(9), 0);
    expect(collectionBonusPercent(10), 10);
    expect(collectionBonusPercent(24), 10);
    expect(collectionBonusPercent(25), 20);
    expect(collectionBonusPercent(50), 30);
    expect(collectionBonusPercent(80), 40);
    expect(collectionBonusPercent(109), 40);
    expect(collectionBonusPercent(110), 50);
  });

  test('次のボーナスまでの数', () {
    expect(nextCollectionBonus(1), (remaining: 9, percent: 10));
    expect(nextCollectionBonus(10), (remaining: 15, percent: 20));
    expect(nextCollectionBonus(109), (remaining: 1, percent: 50));
    expect(nextCollectionBonus(110), isNull);
  });

  test('コインだけが増え、スコアは変わらない', () {
    expect(coinsForScore(300, 1), 30);
    expect(coinsForScore(300, 10), 33);
    expect(coinsForScore(300, 110), 45);
    expect(coinsForScore(9, 110), 0);
    expect(coinsForScore(0, 50), 0);
  });
}
