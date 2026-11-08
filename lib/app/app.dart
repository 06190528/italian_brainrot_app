import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Flame.images.prefix = 'assets/images/';
  await AudioService.instance.init();
  final chars = await CharacterRepository.load();
  final user = initialUser ?? await UserDataStore().load();
  AudioService.instance.enabled = user.soundOn;
  try {
    MobileAds.instance.initialize();
  } catch (_) {}
  return ProviderScope(
    overrides: [
      charactersProvider.overrideWithValue(chars),
      initialUserDataProvider.overrideWithValue(user),
      ...overrides,
    ],
    child: const BrainrotApp(),
  );
}
