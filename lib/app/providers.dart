import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/character.dart';
import '../data/ranking_service.dart';
import '../data/user_data.dart';

/// main() で読み込んだ値を override して使う。
final charactersProvider = Provider<List<CharacterDef>>((ref) => throw UnimplementedError());
final initialUserDataProvider = Provider<UserData>((ref) => throw UnimplementedError());

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier(
    UserDataStore(),
    ref.read(initialUserDataProvider),
    ref.read(charactersProvider).length,
  );
});

final rankingServiceProvider = Provider<RankingService>((ref) => RankingService(HttpRankingTransport()));
