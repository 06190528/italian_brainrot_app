import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../data/character.dart';

enum GameMode {
  normal(1),
  hard(2);

  final int id;
  const GameMode(this.id);
}

enum Dir { up, down, left, right, none }

/// 画面(HUD)が購読する、プレイ中の状態。
class GameSession {
  final score = ValueNotifier<int>(0);
  final feverCount = ValueNotifier<int>(0);
  final fever = ValueNotifier<bool>(false);
  final deathblows = ValueNotifier<int>(1);
  final active = ValueNotifier<bool>(false);

  void reset() {
    score.value = 0;
    feverCount.value = 0;
    fever.value = false;
    deathblows.value = 1;
    active.value = false;
  }
}

/// ルール(元アプリ saibai_men_app と同じ):
/// - スワイプでキャラを動かす。敵は画面の端から端へ横切る。
/// - 敵に触れたらゲームオーバー。触れずに画面外へ出せばスコア+1。
/// - 15点ごとにアイテムが降ってくる(必殺技が1回使える)。
/// - 一定数かわすとフィーバー(敵に1回触れても壊れるだけ)。
class BrainrotGame extends FlameGame with PanDetector {
  final GameMode mode;
  final List<CharacterDef> characters;
  final int playerId;
  final GameSession session;
  final void Function(int score) onGameOver;
  final void Function(int score) onClear;

  BrainrotGame({
    required this.mode,
    required this.characters,
    required this.playerId,
    required this.session,
    required this.onGameOver,
    required this.onClear,
  });

  final _rng = Random();
  // ignore: library_private_types_in_public_api
  final List<_Enemy> enemies = [];
  // ignore: library_private_types_in_public_api
  final List<_Item> items = [];
  // ignore: library_private_types_in_public_api
  late final _Player player;

  // 難易度(startで初期化)
  double enemySpeed = 0;
  double spawnInterval = 1.2;
  int enemyKinds = 3;
  double _timer = 0;
  bool _over = false;

  /// テスト用: false にすると、敵が自動で出ない。
  @visibleForTesting
  bool autoSpawn = true;

  int get _speedStepEvery => mode == GameMode.normal ? 20 : 30;
  int get feverNeeded => mode == GameMode.normal ? 20 : 50;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await add(_Background(await Flame.images.load('bg/play.jpg')));
    player = _Player(characters[playerId]);
    await add(player);
    player.position = size / 2;
    _initDifficulty();
    debugInstance = this;
  }

  @override
  void onRemove() {
    if (identical(debugInstance, this)) debugInstance = null;
    super.onRemove();
  }

  void _initDifficulty() {
    final base = min(size.x, size.y) / (mode == GameMode.normal ? 4 : 3);
    enemySpeed = base;
    spawnInterval = mode == GameMode.normal ? 2.0 : 1.2;
    enemyKinds = min(3, characters.length);
    // 自分より番号の大きい敵が出始めるように、最低でも自分の番号+1まで広げる
    if (playerId >= enemyKinds && enemyKinds < characters.length - 1) {
      enemyKinds = min(playerId + 1, characters.length - 1);
    }
    player.speed = enemySpeed * 1.3;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      player.position.clamp(Vector2.zero(), size);
    }
  }

  // ---- 操作 ----
  @override
  void onPanUpdate(DragUpdateInfo info) {
    final d = info.delta.global;
    if (d.length < 1) return;
    setDirection(d.x.abs() > d.y.abs()
        ? (d.x > 0 ? Dir.right : Dir.left)
        : (d.y > 0 ? Dir.down : Dir.up));
  }

  void setDirection(Dir d) => player.direction = d;

  // ---- 進行 ----
  void start() {
    _over = false;
    _initDifficulty();
    session.reset();
    session.active.value = true;
    player.position = size / 2;
    player.direction = Dir.none;
    player.visible = true;
  }

  void pause() {
    session.active.value = false;
    pauseEngine();
  }

  void resume() {
    resumeEngine();
    session.active.value = true;
  }

  /// 広告を見て続きから。敵を全部消して、その場で再開する。
  void continueGame() {
    _over = false;
    _clearEnemies(explode: false);
    player.visible = true;
    session.active.value = true;
    session.fever.value = false;
    session.feverCount.value = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!session.active.value || _over || !autoSpawn) return;
    _timer += dt;
    if (_timer >= spawnInterval) {
      _timer = 0;
      addEnemy();
    }
  }

  void addEnemy() {
    if (enemies.length >= 10 || characters.length < 2) return;
    var kind = _rng.nextInt(enemyKinds);
    var guard = 0;
    while (kind == playerId && guard++ < 20) {
      kind = _rng.nextInt(enemyKinds);
    }
    final side = _rng.nextInt(4);
    late Vector2 pos;
    late Dir dir;
    switch (side) {
      case 0:
        pos = Vector2(_rng.nextDouble() * size.x, 0);
        dir = Dir.down;
      case 1:
        pos = Vector2(_rng.nextDouble() * size.x, size.y);
        dir = Dir.up;
      case 2:
        pos = Vector2(0, _rng.nextDouble() * size.y);
        dir = Dir.right;
      default:
        pos = Vector2(size.x, _rng.nextDouble() * size.y);
        dir = Dir.left;
    }
    _spawn(kind, pos, dir);
  }

  void _spawn(int kind, Vector2 pos, Dir dir) {
    final e = _Enemy(characters[kind], dir, enemySpeed)..position = pos;
    enemies.add(e);
    add(e);
  }

  /// テスト用: 決まった位置・向きに敵を出す。
  @visibleForTesting
  static BrainrotGame? debugInstance;

  @visibleForTesting
  void debugSpawnEnemy(Vector2 pos, Dir dir, {int? kind}) =>
      _spawn(kind ?? (playerId == 0 ? 1 : 0), pos, dir);

  @visibleForTesting
  Vector2 get debugPlayerPosition => player.position.clone();

  void _addItem() {
    final it = _Item(enemySpeed * 0.5)..position = Vector2(_rng.nextDouble() * size.x, 0);
    items.add(it);
    add(it);
  }

  void _clearEnemies({required bool explode}) {
    for (final e in List<_Enemy>.from(enemies)) {
      if (explode) add(_Explosion(e.position.clone(), small: true));
      e.removeFromParent();
    }
    enemies.clear();
  }

  // ---- イベント ----
  void _enemyPassed(_Enemy e) {
    enemies.remove(e);
    final s = session.score.value + 1;
    session.score.value = s;
    if (!session.fever.value) {
      session.feverCount.value++;
    } else if (s % 4 == 0) {
      addEnemy(); // フィーバー中はたくさん出る
    }
    if (s % 49 == 0) {
      for (var i = 0; i < 6; i++) {
        addEnemy();
      }
    }
    if (s % _speedStepEvery == _speedStepEvery - 1) {
      enemySpeed *= 1.05;
      spawnInterval *= 0.93;
      for (final x in enemies) {
        x.speed = enemySpeed;
      }
      player.speed = enemySpeed * 1.3;
    } else if (s % 15 == 5) {
      _addItem();
      if (enemyKinds < characters.length - 1) enemyKinds++;
    }
    _afterScore();
  }

  void _afterScore() {
    if (mode == GameMode.normal && session.score.value >= normalGoalScore) {
      _finish(clear: true);
      return;
    }
    if (!session.fever.value && session.feverCount.value >= feverNeeded) {
      session.fever.value = true;
      AudioService.instance.playBgm('fever_bgm.mp3', volume: 1.0);
    }
  }

  void _playerTouched(_Enemy e) {
    enemies.remove(e);
    e.removeFromParent();
    if (session.fever.value) {
      // フィーバー終了(爆発して、また最初から溜める)
      add(_Explosion(player.position.clone()));
      AudioService.instance.explosion();
      session.fever.value = false;
      session.feverCount.value = 0;
      AudioService.instance.playBgm('bgm.mp3');
    } else {
      _finish(clear: false);
    }
  }

  void _itemTaken(_Item it) {
    items.remove(it);
    it.removeFromParent();
    session.deathblows.value++;
    AudioService.instance.item();
  }

  void specialMove() {
    if (session.deathblows.value < 1 || !session.active.value) return;
    session.deathblows.value--;
    final n = enemies.length;
    _clearEnemies(explode: true);
    session.score.value += n;
    if (!session.fever.value) session.feverCount.value += n;
    AudioService.instance.special();
    _afterScore();
  }

  void _finish({required bool clear}) {
    if (_over) return;
    _over = true;
    session.active.value = false;
    _clearEnemies(explode: false);
    for (final i in List<_Item>.from(items)) {
      i.removeFromParent();
    }
    items.clear();
    if (!clear) {
      add(_Explosion(player.position.clone()));
      player.visible = false;
      AudioService.instance.explosion();
    }
    final s = session.score.value;
    if (clear) {
      onClear(s);
    } else {
      onGameOver(s);
    }
  }
}

// ---------------- 部品 ----------------

class _Background extends Component with HasGameReference<BrainrotGame> {
  final Image image;
  _Background(this.image) : super(priority: -10);

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final scale = max(s.x / image.width, s.y / image.height);
    final w = image.width * scale, h = image.height * scale;
    final dst = Rect.fromLTWH((s.x - w) / 2, (s.y - h) / 2, w, h);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium);
  }
}

class _Player extends SpriteAnimationComponent with HasGameReference<BrainrotGame> {
  final CharacterDef def;
  Dir direction = Dir.none;
  double speed = 0;
  bool visible = true;

  _Player(this.def) : super(anchor: Anchor.center, priority: 5);

  @override
  Future<void> onLoad() async {
    animation = await def.loadAnimation();
    size = Vector2.all(game.size.y / 13);
  }

  @override
  void render(Canvas canvas) {
    if (visible) super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.session.active.value) return;
    final v = _vec(direction) * (speed * dt);
    position.add(v);
    final half = size.x / 2;
    position.x = position.x.clamp(half, game.size.x - half);
    position.y = position.y.clamp(half, game.size.y - half);
  }
}

Vector2 _vec(Dir d) => switch (d) {
      Dir.up => Vector2(0, -1),
      Dir.down => Vector2(0, 1),
      Dir.left => Vector2(-1, 0),
      Dir.right => Vector2(1, 0),
      Dir.none => Vector2.zero(),
    };

class _Enemy extends SpriteAnimationComponent with HasGameReference<BrainrotGame> {
  final CharacterDef def;
  final Dir dir;
  double speed;

  _Enemy(this.def, this.dir, this.speed) : super(anchor: Anchor.center, priority: 3);

  @override
  Future<void> onLoad() async {
    animation = await def.loadAnimation();
    size = Vector2.all(game.size.y / 15);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.session.active.value) return;
    final p = game.player;
    final hit = (size.x + p.size.x) * 0.3;
    if (position.distanceTo(p.position) <= hit) {
      game._playerTouched(this);
      return;
    }
    position.add(_vec(dir) * (speed * dt));
    final s = game.size;
    if (position.x < -1 || position.x > s.x + 1 || position.y < -1 || position.y > s.y + 1) {
      removeFromParent();
      game._enemyPassed(this);
    }
  }
}

class _Item extends PositionComponent with HasGameReference<BrainrotGame> {
  final double speed;
  double _t = 0;
  _Item(this.speed) : super(anchor: Anchor.center, priority: 4);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(game.size.y / 20);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!game.session.active.value) return;
    position.y += speed * dt;
    if (position.distanceTo(game.player.position) <= (size.x + game.player.size.x) * 0.35) {
      game._itemTaken(this);
    } else if (position.y > game.size.y + size.y) {
      game.items.remove(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2 * (1 + 0.1 * sin(_t * 8));
    canvas.drawCircle(c, r * 1.3, Paint()..color = const Color(0x55FFD54F));
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5 + _t;
      final pt = c + Offset(cos(a) * rad, sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC107));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFB26A00));
  }
}

class _Explosion extends PositionComponent with HasGameReference<BrainrotGame> {
  final bool small;
  double _t = 0;
  _Explosion(Vector2 pos, {this.small = false}) : super(position: pos, anchor: Anchor.center, priority: 8);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.6) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / 0.6).clamp(0.0, 1.0);
    final base = game.size.y / (small ? 22 : 9);
    final r = base * (0.3 + k);
    final a = ((1 - k) * 255).toInt();
    canvas.drawCircle(Offset.zero, r, Paint()..color = Color.fromARGB(a, 255, 140, 0));
    canvas.drawCircle(Offset.zero, r * 0.6, Paint()..color = Color.fromARGB(a, 255, 235, 59));
    canvas.drawCircle(Offset.zero, r * 0.25, Paint()..color = Color.fromARGB(a, 255, 255, 255));
  }
}
