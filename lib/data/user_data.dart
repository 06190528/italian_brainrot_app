import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class ScoreRecord {
  final String name;
  final int score;
  final int mode; // 1=ノーマル 2=ハード
  final DateTime at;
  const ScoreRecord(this.name, this.score, this.mode, this.at);

  Map<String, dynamic> toJson() =>
      {'n': name, 's': score, 'm': mode, 't': at.millisecondsSinceEpoch};
  factory ScoreRecord.fromJson(Map<String, dynamic> j) => ScoreRecord(
      j['n'] as String,
      j['s'] as int,
      j['m'] as int,
      DateTime.fromMillisecondsSinceEpoch(j['t'] as int));
}

class UserData {
  final String name;
  final int coin;
  final Set<int> owned;
  final int current;
  final bool soundOn;
  final List<ScoreRecord> records;

  /// ランキング用の、端末ごとの乱数ID(32桁の16進)。末尾4桁だけが順位表のJSONに出る(自分の行の判別用)。
  final String installId;

  /// ランキングに送信済みのハードモードのベスト(0=未送信)。
  final int submittedBest;

  const UserData({
    required this.name,
    required this.coin,
    required this.owned,
    required this.current,
    required this.soundOn,
    required this.records,
    required this.installId,
    this.submittedBest = 0,
  });

  static String newInstallId() {
    final r = Random.secure();
    return List.generate(32, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  factory UserData.initial() => UserData(
        name: 'Player',
        coin: startingCoins,
        owned: const {0},
        current: 0,
        soundOn: true,
        records: const [],
        installId: newInstallId(),
      );

  int bestScore(int mode) => records
      .where((r) => r.mode == mode)
      .fold(0, (m, r) => r.score > m ? r.score : m);

  bool get hardUnlocked => bestScore(1) >= normalGoalScore;

  UserData copyWith({
    String? name,
    int? coin,
    Set<int>? owned,
    int? current,
    bool? soundOn,
    List<ScoreRecord>? records,
    int? submittedBest,
  }) =>
      UserData(
        name: name ?? this.name,
        coin: coin ?? this.coin,
        owned: owned ?? this.owned,
        current: current ?? this.current,
        soundOn: soundOn ?? this.soundOn,
        records: records ?? this.records,
        installId: installId,
        submittedBest: submittedBest ?? this.submittedBest,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'coin': coin,
        'owned': owned.toList()..sort(),
        'current': current,
        'soundOn': soundOn,
        'records': records.map((r) => r.toJson()).toList(),
        'installId': installId,
        'submittedBest': submittedBest,
      };

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
        name: (j['name'] ?? 'Player') as String,
        coin: (j['coin'] ?? 0) as int,
        owned: ((j['owned'] ?? [0]) as List).cast<int>().toSet(),
        current: (j['current'] ?? 0) as int,
        soundOn: (j['soundOn'] ?? true) as bool,
        records: ((j['records'] ?? []) as List)
            .map((e) => ScoreRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        installId: (j['installId'] as String?) ?? newInstallId(),
        submittedBest: (j['submittedBest'] ?? 0) as int,
      );
}

/// 端末への保存。テストでは SharedPreferences.setMockInitialValues で差し替えられる。
class UserDataStore {
  static const _key = 'user_data_v1';

  Future<UserData> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return UserData.initial();
    try {
      return UserData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserData.initial();
    }
  }

  Future<void> save(UserData d) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(d.toJson()));
  }
}

class UserDataNotifier extends StateNotifier<UserData> {
  final UserDataStore _store;
  final int characterCount;
  UserDataNotifier(this._store, UserData initial, this.characterCount)
      : super(initial);

  void _set(UserData d) {
    state = d;
    _store.save(d);
  }

  void addCoins(int n) => _set(state.copyWith(coin: state.coin + n));

  bool spendCoins(int n) {
    if (state.coin < n) return false;
    _set(state.copyWith(coin: state.coin - n));
    return true;
  }

  /// 新規なら true。ダブりは+5コイン。
  bool unlock(int id) {
    if (state.owned.contains(id)) {
      addCoins(5);
      return false;
    }
    _set(state.copyWith(owned: {...state.owned, id}));
    return true;
  }

  void select(int id) {
    if (state.owned.contains(id)) _set(state.copyWith(current: id));
  }

  void markSubmitted(int score) {
    if (score > state.submittedBest) _set(state.copyWith(submittedBest: score));
  }

  void setName(String name) => _set(state.copyWith(name: name));
  void setSound(bool on) => _set(state.copyWith(soundOn: on));

  void addRecord(int mode, int score) {
    final list = [...state.records, ScoreRecord(state.name, score, mode, DateTime.now())]
      ..sort((a, b) => b.score.compareTo(a.score));
    _set(state.copyWith(records: list.take(50).toList()));
  }
}
