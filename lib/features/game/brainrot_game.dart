import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../core/art.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../data/character.dart';
import '../../data/skill.dart';

enum GameMode {
  normal(1),
  hard(2);

  final int id;
  const GameMode(this.id);
}

enum Dir { up, down, left, right, none }

/// 敵の動き。直進のほかに、蛇行(波を描いて横切る)と追尾(自機を通り過ぎるまで、横から寄ってくる)がある。
enum EnemyType { straight, wavy, chaser }

/// 画面(HUD)が購読する、プレイ中の状態。
class GameSession {
  final score = ValueNotifier<int>(0);
  final feverCount = ValueNotifier<int>(0);
  final fever = ValueNotifier<bool>(false);
  final deathblows = ValueNotifier<int>(1);
  final barrier = ValueNotifier<bool>(false); // バリア(泡)があるか
  final barrierProgress = ValueNotifier<double>(0); // 再生までの進み具合(0〜1)
  final active = ValueNotifier<bool>(false);

  void reset() {
    score.value = 0;
    feverCount.value = 0;
    fever.value = false;
    deathblows.value = 1;
    barrier.value = false;
    barrierProgress.value = 0;
    active.value = false;
  }
}

/// ルール:
/// - スワイプでキャラを動かす。敵は画面の端から端へ横切る(直進・蛇行・追尾の3種類)。
/// - 敵に触れたらゲームオーバー(バリアがあれば、1回かばう)。触れずに画面外へ出せばスコア+1。
/// - 一定数かわすごとに、アイテムの星が降ってくる(必殺技が1回使える。間隔は、スキル「ラッキードロップ」で短くなる)。
/// - 一定数かわすとフィーバー(敵に1回触れても壊れるだけ)。
/// - 出撃キャラのスキル(バリア・マグネット・フィーバーブースト・ラッキードロップ・ちびボディ)が、ゲームに効く。
class BrainrotGame extends FlameGame with PanDetector {
  final GameMode mode;
  final List<CharacterDef> characters;
  final int playerId;
  final GameSession session;
  final void Function(int score) onGameOver;
  final void Function(int score) onClear;

  /// false にすると、スキルを使わない(難易度のシミュレーションで、差を測るため)。
  final bool useSkill;

  BrainrotGame({
    required this.mode,
    required this.characters,
    required this.playerId,
    required this.session,
    required this.onGameOver,
    required this.onClear,
    this.useSkill = true,
  });

  /// 出撃キャラのスキル。
  late final Skill skill = characters[playerId].skill;
  bool _has(SkillType t) => useSkill && skill.type == t;

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
  int get _baseFever => mode == GameMode.normal ? 20 : 50;
  int get feverNeeded => _has(SkillType.feverBoost) ? skill.feverNeeded(_baseFever) : _baseFever;

  /// アイテムが出る間隔(かわした数)。ラッキードロップで短くなる。
  int get itemEvery => _has(SkillType.luckyDrop) ? skill.itemEvery : Skill.defaultItemEvery;

  /// 自機の大きさの倍率(ちびボディで小さくなる)。
  double get bodyScale => _has(SkillType.miniBody) ? skill.bodyScale : 1.0;

  /// マグネットの半径(px)。0なら無し。
  double get magnetRadiusPx => _has(SkillType.magnet) ? skill.magnetRadius * size.x : 0;

  // バリア: 泡が割れた直後の無敵(秒)
  double _invuln = 0;
  bool get invulnerable => _invuln > 0;
  int _barrierProgress = 0;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    // 初回のデコードで、プレイ中に読み込みが走らないよう、先に読み込む(読み込み中の部品を、更新の途中で外すと例外になる)
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
    _invuln = 0;
    _barrierProgress = 0;
    session.barrier.value = _has(SkillType.barrier);
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
    _invuln = 1.0; // 続きの直後に、すぐ触れて終わらないように
    _clearEnemies(explode: false);
    player.visible = true;
    session.active.value = true;
    session.fever.value = false;
    session.feverCount.value = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt > 0 && session.active.value && _invuln > 0) _invuln = max(0, _invuln - dt);
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
    _spawn(kind, pos, dir, type: _pickType());
  }

  /// 敵の動きを、スコアで決める(0〜4点は直進だけ / 5〜14点は蛇行30% / 15点以降は蛇行25%・追尾15%)。
  EnemyType _pickType() {
    final s = session.score.value;
    if (s < 5) return EnemyType.straight;
    final r = _rng.nextDouble();
    if (s < 15) return r < 0.30 ? EnemyType.wavy : EnemyType.straight;
    if (r < 0.15 && enemies.where((e) => e.type == EnemyType.chaser).length < 2) return EnemyType.chaser;
    if (r >= 0.15 && r < 0.40) return EnemyType.wavy;
    return EnemyType.straight;
  }

  void _spawn(int kind, Vector2 pos, Dir dir, {EnemyType type = EnemyType.straight}) {
    final e = _Enemy(characters[kind], dir, enemySpeed, type)..position = pos;
    enemies.add(e);
    add(e);
  }

  /// テスト用: 決まった位置・向きに敵を出す。
  @visibleForTesting
  static BrainrotGame? debugInstance;

  @visibleForTesting
  void debugSpawnEnemy(Vector2 pos, Dir dir, {int? kind, EnemyType type = EnemyType.straight}) =>
      _spawn(kind ?? (playerId == 0 ? 1 : 0), pos, dir, type: type);

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
    }
    if (s % itemEvery == 5 && s % _speedStepEvery != _speedStepEvery - 1) _addItem();
    if (s % 15 == 5 && s % _speedStepEvery != _speedStepEvery - 1) {
      if (enemyKinds < min(characters.length - 1, maxEnemyKinds)) enemyKinds++;
    }
    _advanceBarrier(1);
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
    } else if (session.barrier.value) {
      // バリアが、1回かばってくれる(割れた直後の1秒は、無敵)
      session.barrier.value = false;
      _barrierProgress = 0;
      session.barrierProgress.value = 0;
      _invuln = 1.0;
      add(_Explosion(player.position.clone(), small: true));
      AudioService.instance.hitSoft();
    } else {
      _finish(clear: false);
    }
  }

  /// バリアの再生: n体かわすごとに進み、必要数に達したら泡が戻る(割れている間だけ)。
  void _advanceBarrier(int n) {
    if (!_has(SkillType.barrier) || session.barrier.value) return;
    _barrierProgress += n;
    final need = skill.barrierRegen;
    if (_barrierProgress >= need) {
      _barrierProgress = 0;
      session.barrier.value = true;
    }
    session.barrierProgress.value = session.barrier.value ? 0 : _barrierProgress / need;
  }

  @visibleForTesting
  EnemyType debugPickType() => _pickType();

  @visibleForTesting
  double debugAddItem(Vector2 pos) {
    final it = _Item(enemySpeed * 0.5)..position = pos;
    items.add(it);
    add(it);
    return pos.distanceTo(player.position);
  }

  @visibleForTesting
  double debugItemDistance() => items.isEmpty ? -1 : items.first.position.distanceTo(player.position);

  @visibleForTesting
  void debugAdvanceBarrier(int n) => _advanceBarrier(n);

  @visibleForTesting
  void debugTick(double seconds) {
    const dt = 1 / 60;
    for (var t = 0.0; t < seconds; t += dt) {
      update(dt);
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
    _advanceBarrier(n);
    AudioService.instance.special();
    _afterScore();
  }

  void _finish({required bool clear}) {
    if (_over) return;
    _over = true;
    _invuln = 0; // 結果画面の後ろで、自機が点滅し続けないように
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

  // フィーバー中のオーラ(コード描画)。別のコンポーネントにせず、キャラの描画の一部にする
  double _auraT = 0;

  @override
  Future<void> onLoad() async {
    animation = await def.loadAnimation();
    final g = findGame(); // 読み込み中に外されたら、何もしない
    if (g == null) return;
    size = Vector2.all(g.size.y / 13 * game.bodyScale);
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final c = Offset(size.x / 2, size.y / 2);
    // 割れた直後の無敵の間は、点滅する
    if (game.invulnerable && (_auraT * 12).floor().isOdd) return;
    super.render(canvas);
    if (game.session.fever.value) paintAura(canvas, c, size.x * 1.1, _auraT);
    if (game.session.barrier.value) paintBarrier(canvas, c, size.x * 0.85, _auraT);
    final m = game.magnetRadiusPx;
    if (m > 0) paintMagnetRing(canvas, c, m, _auraT);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _auraT += dt;
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
  final EnemyType type;
  double speed; // 基準の速さ(速度段階で上がる)。種類ごとの係数は、下の forwardMul で掛ける

  _Enemy(this.def, this.dir, this.speed, this.type) : super(anchor: Anchor.center, priority: 3);

  Vector2? _base; // 蛇行の中心線の位置
  double _trav = 0; // 蛇行: 進んだ距離
  double _age = 0;
  bool _passedPlayer = false; // 追尾: 自機を通り過ぎたら、直進に戻る

  double get forwardMul => switch (type) {
        EnemyType.straight => 1.0,
        EnemyType.wavy => 0.9,
        EnemyType.chaser => 0.8,
      };

  Vector2 get _fwd => _vec(dir);
  Vector2 get _perp => Vector2(_fwd.y.abs(), _fwd.x.abs());
  double get _amp => game.size.y * 0.04;
  double get _lambda => game.size.y * 0.45;

  /// 追尾: 自機との横のずれ(進行方向に直角な向きの差)。
  double get _lateralGap => (game.player.position - position).dot(_perp);

  /// いまの速度ベクトル(ボットが、先を予測するのに使う)。
  Vector2 get velocity {
    final f = _fwd * (speed * forwardMul);
    switch (type) {
      case EnemyType.straight:
        return f;
      case EnemyType.wavy:
        final k = 2 * pi / _lambda;
        return f + _perp * (_amp * k * cos(k * _trav) * speed * forwardMul);
      case EnemyType.chaser:
        final g = _lateralGap;
        if (_passedPlayer || g.abs() < 4) return f;
        return f + _perp * (g.sign * speed * 0.3);
    }
  }

  @override
  Future<void> onLoad() async {
    animation = await def.loadAnimation();
    final g = findGame(); // 読み込み中に外されたら(ゲームオーバー・必殺技)、何もしない
    if (g == null) return;
    size = Vector2.all(g.size.y / 15);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final c = Offset(size.x / 2, size.y / 2);
    switch (type) {
      case EnemyType.straight:
        break;
      case EnemyType.wavy:
        paintEnemyRing(canvas, c, size.x * 0.62, const Color(0xCCAB47BC), _age);
      case EnemyType.chaser:
        paintEnemyRing(canvas, c, size.x * 0.62, const Color(0xCCE53935), _age);
        if (_age < 0.6) paintBang(canvas, Offset(c.dx, -size.y * 0.35), size.y * 0.5);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt == 0 || !game.session.active.value) return; // update(0) では進めない(上と同じ理由)
    _age += dt;
    final p = game.player;
    final hit = (size.x + p.size.x) * 0.3;
    if (!game.invulnerable && position.distanceTo(p.position) <= hit) {
      game._playerTouched(this);
      return;
    }
    final fwd = _fwd, perp = _perp;
    switch (type) {
      case EnemyType.straight:
        position.add(fwd * (speed * dt));
      case EnemyType.wavy:
        final step = speed * forwardMul * dt;
        final base = (_base ??= position.clone());
        base.add(fwd * step);
        _trav += step;
        position.setFrom(base + perp * (_amp * sin(2 * pi * _trav / _lambda)));
        // 横にはみ出して、画面の端で「通過」と判定されないように、横の座標は画面の中に収める
        if (perp.x > 0) {
          position.x = position.x.clamp(0.0, game.size.x);
        } else {
          position.y = position.y.clamp(0.0, game.size.y);
        }
      case EnemyType.chaser:
        position.add(fwd * (speed * forwardMul * dt));
        if (!_passedPlayer && (position - p.position).dot(fwd) >= 0) _passedPlayer = true;
        if (!_passedPlayer) {
          final g = _lateralGap;
          if (g.abs() >= 4) position.add(perp * (g.sign * min(speed * 0.3 * dt, g.abs())));
        }
    }
    // 画面の外へ出たか(進行方向だけで判定する)
    final s = game.size;
    final out = switch (dir) {
      Dir.down => position.y > s.y + 1,
      Dir.up => position.y < -1,
      Dir.right => position.x > s.x + 1,
      Dir.left => position.x < -1,
      Dir.none => false,
    };
    if (out) {
      removeFromParent();
      game._enemyPassed(this);
    }
  }
}

/// 落ちてくるアイテム(金の星。コード描画)。取ると必殺技が1回増える。
class _Item extends PositionComponent with HasGameReference<BrainrotGame> {
  final double speed;
  double _t = 0;
  _Item(this.speed) : super(anchor: Anchor.center, priority: 4) {
    size = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    final g = findGame();
    if (g == null) return;
    size = Vector2.all(g.size.x / 8);
  }

  @override
  void render(Canvas canvas) => paintStar(canvas, Offset(size.x / 2, size.y / 2), size.x * 0.4, rot: _t * 2);

  @override
  void update(double dt) {
    super.update(dt);
    if (dt == 0 || !game.session.active.value) return; // update(0) では進めない
    _t += dt;
    final m = game.magnetRadiusPx;
    final toPlayer = game.player.position - position;
    if (m > 0 && toPlayer.length < m) {
      // マグネット: 範囲に入ったアイテムを、敵の1.2倍の速さで自機へ引き寄せる
      position.add(toPlayer.normalized() * (game.enemySpeed * 1.2 * dt));
    } else {
      position.y += speed * dt;
    }
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
