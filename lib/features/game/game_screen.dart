import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../core/ads/reward_ad.dart';
import '../../core/audio_service.dart';
import '../../core/strings.dart';
import '../../data/ranking_service.dart';
import '../../core/constants.dart';
import '../../core/widgets.dart';
import 'brainrot_game.dart';

enum _Phase { ready, playing, paused, over, clear }

class GameScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final session = GameSession();
  late final BrainrotGame game;
  _Phase phase = _Phase.ready;
  int finalScore = 0;
  int earnedCoins = 0;
  bool usedContinue = false;

  @override
  void initState() {
    super.initState();
    final chars = ref.read(charactersProvider);
    game = BrainrotGame(
      mode: widget.mode,
      characters: chars,
      playerId: ref.read(userDataProvider).current,
      session: session,
      onGameOver: (s) => _finish(s, clear: false),
      onClear: (s) => _finish(s, clear: true),
    );
    session.fever.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    AudioService.instance.stopBgm();
    super.dispose();
  }

  void _start() {
    setState(() => phase = _Phase.playing);
    game.start();
    AudioService.instance.playBgm(AudioService.bgmMain);
  }

  void _finish(int score, {required bool clear}) {
    final notifier = ref.read(userDataProvider.notifier);
    final coins = score ~/ 10;
    notifier.addCoins(coins);
    notifier.addRecord(widget.mode.id, score);
    if (widget.mode.id == rankingMode) {
      // ランキングへの送信は裏で行う(失敗しても、次にランキングを開いた時に再送する)
      submitPendingRanking(
        user: ref.read(userDataProvider),
        service: ref.read(rankingServiceProvider),
        notifier: notifier,
      );
    }
    AudioService.instance.stopBgm();
    if (clear) AudioService.instance.clear();
    if (!mounted) return;
    setState(() {
      finalScore = score;
      earnedCoins = coins;
      phase = clear ? _Phase.clear : _Phase.over;
    });
  }

  void _pause() {
    game.pause();
    AudioService.instance.pauseBgm();
    setState(() => phase = _Phase.paused);
  }

  void _resume() {
    game.resume();
    AudioService.instance.resumeBgm();
    setState(() => phase = _Phase.playing);
  }

  Future<void> _continueByAd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(S.watchAdToContinue),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.no)),
          TextButton(key: const Key('continueYes'), onPressed: () => Navigator.pop(c, true), child: Text(S.yes)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final shown = await RewardAd.show(() {
      usedContinue = true;
      // 前回のゲームオーバーで貰ったコインを戻す(続きを遊ぶので、終了時に改めて貰う)
      ref.read(userDataProvider.notifier).spendCoins(earnedCoins.clamp(0, ref.read(userDataProvider).coin));
      game.continueGame();
      AudioService.instance.playBgm(AudioService.bgmMain);
      if (mounted) setState(() => phase = _Phase.playing);
    });
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.adNotReady)));
    }
  }

  void _retry() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(mode: widget.mode)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              GameWidget(game: game),
              if (session.fever.value)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orangeAccent, width: 6),
                    ),
                  ),
                ),
              if (phase == _Phase.playing || phase == _Phase.paused) _hud(),
              if (phase == _Phase.ready) _readyOverlay(),
              if (phase == _Phase.paused) _pauseOverlay(),
              if (phase == _Phase.over || phase == _Phase.clear) _resultOverlay(),
            ]),
          ),
          const BannerAdWidget(),
        ]),
      ),
    );
  }

  Widget _hud() {
    return Stack(children: [
      Positioned(
        top: 8,
        left: 8,
        child: RoundIconButton(key: const Key('pauseButton'), icon: Icons.pause, onPressed: _pause),
      ),
      Positioned(
        top: 8,
        left: 0,
        right: 0,
        child: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: session.score,
            builder: (_, s, __) => OutlinedText('$s', key: const Key('scoreText'), fontSize: 44),
          ),
        ),
      ),
      Positioned(
        top: 64,
        left: 16,
        right: 16,
        child: ValueListenableBuilder<int>(
          valueListenable: session.feverCount,
          builder: (_, c, __) => _FeverBar(
            value: session.fever.value ? 1 : (c / game.feverNeeded).clamp(0.0, 1.0),
            fever: session.fever.value,
          ),
        ),
      ),
      Positioned(
        right: 12,
        bottom: 24,
        child: ValueListenableBuilder<int>(
          valueListenable: session.deathblows,
          builder: (_, n, __) => n < 1
              ? const SizedBox.shrink()
              : GestureDetector(
                  key: const Key('specialButton'),
                  onTap: game.specialMove,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.bolt, size: 36, color: Colors.deepOrange),
                      Text('x$n', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                    ]),
                  ),
                ),
        ),
      ),
    ]);
  }

  Widget _readyOverlay() {
    return Container(
      color: Colors.black38,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedText(S.swipeToMove, fontSize: 28),
          const SizedBox(height: 4),
          Icon(Icons.swipe, size: 64, color: Colors.lightBlueAccent.shade100),
          const SizedBox(height: 24),
          BannerButton(key: const Key('startButton'), text: S.start, icon: Icons.play_arrow, onPressed: _start),
          const SizedBox(height: 16),
          BannerButton(key: const Key('readyBack'), text: S.back, icon: Icons.arrow_back, color: Colors.blueGrey, onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedText(S.pause, fontSize: 40),
          const SizedBox(height: 24),
          BannerButton(key: const Key('resumeButton'), text: S.resume, icon: Icons.play_arrow, onPressed: _resume),
          const SizedBox(height: 16),
          BannerButton(key: const Key('pauseHome'), text: S.home, icon: Icons.home, color: Colors.blueGrey, onPressed: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  Widget _resultOverlay() {
    final clear = phase == _Phase.clear;
    final best = ref.watch(userDataProvider).bestScore(widget.mode.id);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            OutlinedText(clear ? S.gameClear : S.gameOver, key: const Key('resultTitle'), fontSize: 32),
            const SizedBox(height: 12),
            Text('${S.score}: $finalScore', key: const Key('resultScore'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
            Text('${S.bestScore}: $best', style: const TextStyle(fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/ui/coin.png', width: 22, height: 22),
              const SizedBox(width: 6),
              Text('${S.coinsEarned} +$earnedCoins', style: const TextStyle(fontSize: 18, color: Colors.black)),
            ]),
            const SizedBox(height: 14),
            if (!clear && !usedContinue) ...[
              BannerButton(key: const Key('continueButton'), text: S.continueByAd, icon: Icons.ondemand_video, width: 260, color: Colors.green, onPressed: _continueByAd),
              const SizedBox(height: 10),
            ],
            BannerButton(key: const Key('resultRetry'), text: S.retry, icon: Icons.replay, width: 260, onPressed: _retry),
            const SizedBox(height: 10),
            BannerButton(key: const Key('resultHome'), text: S.home, icon: Icons.home, width: 260, color: Colors.blueGrey, onPressed: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }
}

class _FeverBar extends StatelessWidget {
  final double value;
  final bool fever;
  const _FeverBar({required this.value, required this.fever});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (fever) OutlinedText(S.fever, fontSize: 22, color: Colors.orangeAccent),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          key: const Key('feverBar'),
          value: value,
          minHeight: 12,
          backgroundColor: Colors.black54,
          valueColor: AlwaysStoppedAnimation(fever ? Colors.redAccent : Colors.orange),
        ),
      ),
    ]);
  }
}
