import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../core/art.dart';
import '../../core/ads/reward_ad.dart';
import '../../core/audio_service.dart';
import '../../core/skill_widgets.dart';
import '../../core/strings.dart';
import '../../data/collection_bonus.dart';
import '../../data/ranking_service.dart';
import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../data/skill.dart';
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
    final coins = coinsForScore(score, ref.read(userDataProvider).owned.length);
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
    // プレイ中・ポーズ中は、iOSのスワイプバック(端からのスワイプ)・戻るキーで前の画面に戻らない。
    // 画面のボタンの Navigator.pop は、これの影響を受けない
    return PopScope(
      canPop: phase == _Phase.ready || phase == _Phase.over || phase == _Phase.clear,
      child: Scaffold(
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
    ));
  }

  Widget _hud() {
    return Stack(children: [
      Positioned(
        top: 8,
        left: 8,
        child: RoundIconButton(key: const Key('pauseButton'), icon: Icons.pause, onPressed: _pause),
      ),
      // スキル(割れたバリアは、再生までの進み具合を出す)
      Positioned(
        bottom: 24,
        left: 8,
        child: ListenableBuilder(
          listenable: Listenable.merge([session.barrier, session.barrierProgress]),
          builder: (_, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkillChip(skill: game.skill),
            if (game.skill.type == SkillType.barrier)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
                child: SizedBox(
                  width: 90,
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      key: const Key('barrierBar'),
                      value: session.barrier.value ? 1 : session.barrierProgress.value,
                      backgroundColor: Colors.black45,
                      color: const Color(0xFF29B6F6),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
      // かわした数・目標・フィーバーのゲージを、上の中央のパネルにまとめる
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ListenableBuilder(
            listenable: Listenable.merge([session.score, session.feverCount, session.fever]),
            builder: (_, __) {
              final w = MediaQuery.of(context).size.width;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${session.score.value}',
                      key: const Key('scoreText'),
                      style: TextStyle(fontSize: w * 0.07, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
                  if (widget.mode == GameMode.normal)
                    Text(S.goalScore(normalGoalScore), style: TextStyle(fontSize: w * 0.03, fontWeight: FontWeight.bold, color: Colors.white70)),
                  _FeverBar(
                    value: session.fever.value ? 1 : (session.feverCount.value / game.feverNeeded).clamp(0.0, 1.0),
                    fever: session.fever.value,
                  ),
                ]),
              );
            },
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
                      color: const Color(0xFF3949AB),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      const StarIcon(size: 52),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Text('$n', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13)),
                        ),
                      ),
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
          const SizedBox(height: 16),
          SkillCard(key: const Key('readySkill'), skill: game.skill, dark: true),
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
            if (collectionBonusPercent(ref.read(userDataProvider).owned.length) > 0)
              Text(S.collectionBonusApplied(collectionBonusPercent(ref.read(userDataProvider).owned.length)),
                  key: const Key('bonusApplied'), style: const TextStyle(fontSize: 13, color: Colors.black54)),
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

/// フィーバーのゲージ。
class _FeverBar extends StatelessWidget {
  final double value;
  final bool fever;
  const _FeverBar({required this.value, required this.fever});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = w * 0.03;
    return Column(children: [
      if (fever) OutlinedText(S.fever, fontSize: 22, color: Colors.orangeAccent),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          key: const Key('feverBar'),
          width: w * 0.3,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(h / 2), color: Colors.orange),
            ),
          ),
        ),
        Icon(Icons.local_fire_department, size: w * 0.1, color: Colors.deepOrange),
      ]),
    ]);
  }
}
