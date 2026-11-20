import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/consent.dart';
import '../core/audio_service.dart';
import '../data/character.dart';
import '../data/user_data.dart';
import '../features/home/home_screen.dart';
import 'providers.dart';

class BrainrotApp extends StatelessWidget {
  const BrainrotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Italian Brainrot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// 起動時に必要なものを読み込んで、ルートのウィジェットを返す(テストからも使う)。
Future<Widget> buildApp({UserData? initialUser, List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (_) {} // 向きの固定に失敗しても続ける
  Flame.images.prefix = 'assets/images/';
  try {
    await AudioService.instance.init();
  } catch (_) {} // 音が使えなくても続ける
  final chars = await CharacterRepository.load();
  UserData user;
  try {
    user = initialUser ?? await UserDataStore().load();
  } catch (_) {
    user = UserData.initial(); // 保存データを読めなくても、初期状態で起動する
  }
  AudioService.instance.enabled = user.soundOn;
  unawaited(AdsConsent.start()); // 同意を取ってから広告を初期化する(起動は待たない)
  return ProviderScope(
    overrides: [
      charactersProvider.overrideWithValue(chars),
      initialUserDataProvider.overrideWithValue(user),
      ...overrides,
    ],
    child: const BrainrotApp(),
  );
}
