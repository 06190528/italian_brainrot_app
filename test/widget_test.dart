import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:italian_brainrot_app/data/user_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UserData: 保存形式の往復', () {
    final d = UserData.initial().copyWith(coin: 33, owned: {0, 5}, current: 5);
    final r = UserData.fromJson(d.toJson());
    expect(r.coin, 33);
    expect(r.owned, {0, 5});
    expect(r.current, 5);
  });

  test('UserDataNotifier: コインと解放', () async {
    SharedPreferences.setMockInitialValues({});
    final n = UserDataNotifier(UserDataStore(), UserData.initial(), 51);
    expect(n.spendCoins(10), true);
    expect(n.state.coin, 10);
    expect(n.spendCoins(11), false);
    expect(n.unlock(7), true);
    expect(n.unlock(7), false); // ダブり
    expect(n.state.coin, 15);
    n.select(7);
    expect(n.state.current, 7);
    n.select(9); // 未所持は選べない
    expect(n.state.current, 7);
  });

  test('ハード解放はノーマル300点クリア後', () {
    final n = UserDataNotifier(UserDataStore(), UserData.initial(), 51);
    expect(n.state.hardUnlocked, false);
    n.addRecord(1, 300);
    expect(n.state.hardUnlocked, true);
  });
}
