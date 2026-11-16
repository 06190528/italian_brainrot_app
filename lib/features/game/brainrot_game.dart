import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
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
    // 初回のデコードで、プレイ中に読み込みが走らないよう、先に読み込む(読み込み中の部品を、更新の途中で外すと例外になる)
    await Flame.images.loadAll(['orig/energy_bullet.png', 'orig/ki_sprite.png']);
    await add(_Background());
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
    if (dt == 0 || !session.active.value || _over || !autoSpawn) return;
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
    // 出現位置は、プレイヤーから離す(真横に出て、避けられずに即死するのを防ぐ)
    late Vector2 pos;
    late Dir dir;
    for (var tries = 0; tries < 8; tries++) {
      switch (_rng.nextInt(4)) {
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
      if (pos.distanceTo(player.position) >= size.y / 5) break;
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
      if (enemyKinds < min(characters.length - 1, maxEnemyKinds)) enemyKinds++;
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
      AudioService.instance.playBgm(AudioService.bgmFever, volume: 1.0);
    }
  }

  void _playerTouched(_Enemy e) {
    enemies.remove(e);
    e.removeFromParent();
    if (session.fever.value) {
      // フィーバー終了(爆発して、また最初から溜める)
      add(_Explosion(player.position.clone()));
      AudioService.instance.hitSoft();
      AudioService.instance.explosion();
      session.fever.value = false;
      session.feverCount.value = 0;
      AudioService.instance.playBgm(AudioService.bgmMain);
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
      AudioService.instance.hit();
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

/// 暖色の石畳を、コードで描く(画像は使わない)。縦に2枚つなげて流す(速さは敵の半分)。
/// 石の並びは、起動時に1度だけ、画面に対する割合(0〜1)で決める(画面サイズが変わっても崩れない)。
class _Background extends Component with HasGameReference<BrainrotGame> {
  static const _rows = 14;
  final List<(Rect, Color)> _stones = [];
  double _y = 0; // 0〜画面の高さ
  _Background() : super(priority: -10) {
    final rng = Random(7);
    for (var r = 0; r < _rows; r++) {
      // 行ごとに、石の幅をばらけさせ、右端でちょうど1.0になるようにそろえる
      final widths = <double>[];
      var sum = 0.0;
      while (sum < 1.0) {
        final w = 0.16 + rng.nextDouble() * 0.14;
        widths.add(w);
        sum += w;
      }
      final k = 1.0 / sum;
      var x = 0.0;
      for (final w in widths) {
        final tone = rng.nextDouble();
        final color = Color.lerp(const Color(0xFFD9A35F), const Color(0xFFB9783D), tone)!;
        _stones.add((Rect.fromLTWH(x, r / _rows, w * k, 1 / _rows), color));
        x += w * k;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt == 0 || !game.session.active.value) return;
    _y = (_y + game.enemySpeed * 0.5 * dt) % game.size.y;
  }

  @override
  void render(Canvas canvas) {
    final s = game.size;
    canvas.clipRect(Rect.fromLTWH(0, 0, s.x, s.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), Paint()..color = const Color(0xFF5A3B22)); // 目地
    final fill = Paint();
    for (final dy in [_y, _y - s.y]) {
      for (final (r, c) in _stones) {
        final rect = Rect.fromLTWH(r.left * s.x, dy + r.top * s.y, r.width * s.x, r.height * s.y).deflate(2);
        fill.color = c;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), fill);
      }
    }
  }
}

class _Player extends SpriteAnimationComponent with HasGameReference<BrainrotGame> {
  final CharacterDef def;
  Dir direction = Dir.none;
  double speed = 0;
  bool visible = true;

  _Player(this.def) : super(anchor: Anchor.center, priority: 5);

  // フィーバー中のオーラ(元アプリの KiEffect: ki_sprite.png の9コマ)。別のコンポーネントにせず、キャラの描画の一部にする
  SpriteAnimationTicker? _aura;
  Vector2 _auraSize = Vector2.zero();

  @override
  Future<void> onLoad() async {
    animation = await def.loadAnimation();
    final g = findGame(); // 読み込み中に外されたら、何もしない
    if (g == null) return;
    size = Vector2.all(g.size.y / 13);
    final img = await Flame.images.load('orig/ki_sprite.png');
    final sheet = SpriteSheet(image: img, srcSize: Vector2(img.width.toDouble(), img.height / 9));
    _aura = sheet.createAnimation(row: 0, stepTime: 0.08, from: 0, to: 8, loop: true).createTicker();
    _auraSize = Vector2(g.size.x / 4 * 2, g.size.y / 4);
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    super.render(canvas);
    final aura = _aura;
    if (aura != null && game.session.fever.value) {
      // 元アプリと同じ位置: オーラの下端の中央を、キャラの中心の、キャラ1体分下に合わせる
      aura.getSprite().render(canvas,
          position: Vector2(size.x / 2 - _auraSize.x / 2, size.y * 1.5 - _auraSize.y), size: _auraSize);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _aura?.update(dt);
    // GameWidget は再描画の組み立て中に update(0) を呼ぶ。そこでは何も進めない(状態を変えるとエラーになる)
    if (dt == 0 || !game.session.active.value) return;
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
  final Dir dir; // 進行方向(シミュレーションからも読む)
  double speed;

  _Enemy(this.def, this.dir, this.speed) : super(anchor: Anchor.center, priority: 3);

  @override
  Future<void> onLoad() async {
    animation = await def.loadAnimation();
    final g = findGame(); // 読み込み中に外されたら(ゲームオーバー・必殺技)、何もしない
    if (g == null) return;
    size = Vector2.all(g.size.y / 15);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt == 0 || !game.session.active.value) return; // update(0) では進めない(上と同じ理由)
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

/// 落ちてくるアイテム(元アプリの Deathblow: energy_bullet.png の16コマ)。
class _Item extends SpriteAnimationComponent with HasGameReference<BrainrotGame> {
  final double speed;
  _Item(this.speed) : super(anchor: Anchor.center, priority: 4);

  @override
  Future<void> onLoad() async {
    final img = await Flame.images.load('orig/energy_bullet.png');
    final g = findGame();
    if (g == null) return;
    size = Vector2.all(g.size.x / 8);
    final sheet = SpriteSheet(image: img, srcSize: Vector2(274.3, 270));
    animation = sheet.createAnimation(row: 0, stepTime: 0.1, from: 0, to: 15);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt == 0 || !game.session.active.value) return; // update(0) では進めない
    position.y += speed * dt;
    if (position.distanceTo(game.player.position) <= (size.length / 2 + game.player.size.length / 2) / 1.7) {
      game._itemTaken(this);
    } else if (position.y > game.size.y + size.y) {
      game.items.remove(this);
      removeFromParent();
    }
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
