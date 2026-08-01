import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';

import '../core/theme/app_theme.dart';
import '../data/progress/progress_store.dart';
import '../game/audio/audio_manager.dart';
import '../game/engine/board.dart';
import '../game/engine/models.dart';
import '../game/engine/solver.dart';
import '../game/physics/soft_body.dart';
import '../game/physics/vec2.dart';
import '../game/physics/world.dart';
import '../game/rendering/board_painter.dart';
import '../game/rendering/themes.dart';
import '../services/analytics/analytics_service.dart';

enum GamePhase { playing, won, lost }

/// Drives one level: logical board + physics world + effects.
class GameController extends ChangeNotifier {
  GameController({
    required this.level,
    required this.progress,
    required this.audio,
    required this.analytics,
    this.themeKey,
    this.skinKey,
  });

  final LevelDef level;
  final ProgressStore progress;
  final AudioManager audio;
  final AnalyticsService analytics;
  final String? themeKey;
  final String? skinKey;

  late final BoardState board;
  late final PhysicsWorld world;
  GamePhase phase = GamePhase.playing;

  final List<ScrewFx> fx = [];
  final List<Spark> sparks = [];
  Offset shake = Offset.zero;
  int? highlightScrew;
  bool usedHint = false;

  int? _par;
  bool _completed = false;
  Timer? _shakeTimer;
  DateTime _lastImpact = DateTime.fromMillisecondsSinceEpoch(0);

  int get par => _par ??= level.parMoves ?? _computePar();

  int _computePar() => BoardSolver(level).solve()?.length ?? level.screws.length * 2;

  int get moveCount => board.moveCount;

  int get stars => _starsFor(moveCount);

  int _starsFor(int moves) {
    final p = par;
    if (moves <= p) return 3;
    if (moves <= p + 3) return 2;
    return 1;
  }

  /// Setup: physics bodies, pins, and impact feedback.
  void init() {
    world = PhysicsWorld(cols: level.cols, rows: level.rows);
    final plates = level.plates;
    for (final plate in plates) {
      final noCollide = <int>{
        for (final other in plates)
          if (other.id != plate.id && plate.rect.overlaps(other.rect)) other.id,
      };
      world.addBody(
        x: plate.rect.x,
        y: plate.rect.y,
        w: plate.rect.w,
        h: plate.rect.h,
        gravityScale: plate.heavy ? 1.6 : 1.0,
        noCollideWith: noCollide,
      );
    }
    world.onImpact = _onImpact;
    board = BoardState(level);
    syncPins();
    analytics.logLevelStart(level.id);
  }

  /// Re-pins every body from the logical board (used after undo/restart).
  void syncPins() {
    for (final plate in level.plates) {
      final body = world.bodyById(plate.id);
      if (body == null) continue;
      for (final p in body.particles) {
        p.pins.clear();
      }
      for (final s in level.screws) {
        if (s.plateId == plate.id && !board.screwGone(s.id)) {
          world.pin(body, _anchor(s));
        }
      }
    }
  }

  Vec2 _anchor(Screw s) => Vec2(s.cell.x + 0.5, s.cell.y + 0.5);

  // ------------------------------------------------------------------ input

  /// Attempts to remove the screw at [cell]. Returns true when a move happened.
  bool tapCell(Cell cell) {
    if (phase != GamePhase.playing) return false;
    final screw = level.screws.where((s) => s.cell == cell).toList();
    if (screw.isEmpty) return false;
    for (final s in screw) {
      if (board.screwGone(s.id)) continue;
      if (board.isHidden(s)) {
        audio.metal();
        return false;
      }
      return removeScrew(s.id);
    }
    return false;
  }

  bool removeScrew(int screwId) {
    final result = board.removeScrew(screwId);
    if (result == null) {
      audio.error();
      _shake(0.05);
      return false;
    }
    final screw = board.screwById(screwId);
    audio.unscrew();
    fx.add(ScrewFx(
      cell: screw.cell,
      color: screw.isColor
          ? screwColors[screw.color! % screwColors.length]
          : Palette.metal,
    ));
    highlightScrew = null;
    _handleDetaches(result);
    _afterMove();
    return true;
  }

  bool slotHand() {
    final result = board.slotHand();
    if (result == null) {
      audio.error();
      return false;
    }
    audio.metal();
    highlightScrew = null;
    _afterMove();
    return true;
  }

  void _handleDetaches(ApplyResult result) {
    for (final plate in result.detached) {
      final body = world.bodyById(plate.id);
      if (body != null) world.release(body);
      final center = Offset(plate.rect.cx + 0.5, plate.rect.cy + 0.5);
      if (plate.heavy || result.smashed.isNotEmpty) {
        audio.heavy();
        _shake(0.45);
        _burst(center, 26, Palette.orange, unit: true);
        _burst(center, 18, const Color(0xFFFFD54F), unit: true);
      } else {
        audio.drop();
        _shake(0.22);
        _burst(center, 14, themeColorFor(plate.id), unit: true);
      }
    }
    for (final s in result.smashed) {
      audio.metal();
      fx.add(ScrewFx(cell: s.cell, color: Palette.orange));
      _burst(_anchor(s).toOffset(), 10, Palette.orange, unit: true);
    }
  }

  Color themeColorFor(int plateId) {
    const colors = [
      Color(0xFFD9A05F), Color(0xFFB97F42), Color(0xFF8B5CF6),
      Color(0xFFFF8A3D), Color(0xFF2ECB8C),
    ];
    return colors[plateId % colors.length];
  }

  void _afterMove() {
    if (board.isWon) {
      _win();
      return;
    }
    if (board.isStuck) {
      phase = GamePhase.lost;
      analytics.logLevelFail(level.id);
      audio.error();
      notifyListeners();
      return;
    }
    progress.addScrewRemoved();
    notifyListeners();
  }

  // ------------------------------------------------------------------ win

  void _win() {
    phase = GamePhase.won;
    audio.victory();
    final center = Offset(level.cols / 2, 1.0);
    _burst(center, 30, Palette.yellow, unit: true);
    _burst(center, 24, Palette.blue, unit: true);
    _burst(center, 18, Palette.orange, unit: true);
    if (!_completed) {
      _completed = true;
      final s = stars;
      final unlocked = progress.completeLevel(level.id, s, moveCount);
      final coins = 20 + s * 10;
      progress.addCoins(coins);
      progress.checkAchievements(wonWithoutHint: !usedHint && s == 3);
      analytics.logLevelComplete(level.id, moveCount, s, usedHint);
      lastCoins = coins;
      newUnlocks = unlocked;
    }
    notifyListeners();
  }

  int lastCoins = 0;
  List<int> newUnlocks = [];

  // ------------------------------------------------------------------ tools

  bool get canUndo => board.canUndo && phase == GamePhase.playing;

  bool undo() {
    if (!canUndo) return false;
    if (!progress.hasFreeUndos) {
      audio.error();
      return false;
    }
    progress.useUndo();
    final ok = board.undo();
    if (!ok) {
      audio.error();
      return false;
    }
    audio.tick();
    phase = GamePhase.playing;
    highlightScrew = null;
    syncPins();
    notifyListeners();
    return true;
  }

  /// Asks the solver for a move and highlights it. Returns false when no hint
  /// is available (level unsolvable or no hint credits).
  bool requestHint() {
    if (phase != GamePhase.playing) return false;
    final solver = BoardSolver(level);
    final state = _solverState();
    final move = solver.firstMove(
      fromRemovedMask: state.$1,
      fromHand: state.$2,
    );
    if (move == null || move.screwId == null) return false;
    usedHint = true;
    progress.useHint();
    progress.hintsUsed = progress.prefs.hintsUsed + 1;
    audio.pop();
    highlightScrew = move.screwId;
    notifyListeners();
    return true;
  }

  (int, int?) _solverState() {
    var mask = 0;
    for (final s in level.screws) {
      if (board.screwGone(s.id) && s.id != board.handScrew) {
        mask |= 1 << s.id;
      }
    }
    return (mask, board.handScrew);
  }

  void restart() {
    board = BoardState(level);
    phase = GamePhase.playing;
    _completed = false;
    _par = null;
    fx.clear();
    sparks.clear();
    highlightScrew = null;
    usedHint = false;
    world.reset();
    syncPins();
    notifyListeners();
  }

  // ------------------------------------------------------------ effects loop

  /// Advances effects; call from the game ticker. Returns true when repaint.
  bool tick(double dt) {
    world.step(dt);
    var dirty = false;
    for (final f in fx.toList()) {
      f.progress += dt * 2.2;
      f.angle += dt * 14;
      if (f.progress >= 1) fx.remove(f);
      dirty = true;
    }
    for (final s in sparks.toList()) {
      s.life -= dt;
      s.pos += s.vel * dt;
      s.vel = s.vel * (1 - dt * 3);
      if (s.life <= 0) sparks.remove(s);
      dirty = true;
    }
    if (shake != Offset.zero) {
      _shakeTimer ??= Timer(const Duration(milliseconds: 220), () {
        shake = Offset.zero;
        _shakeTimer = null;
        notifyListeners();
      });
    }
    return dirty || world.bodies.any((b) => b.released);
  }

  void _onImpact(SoftBody body, double speed) {
    final now = DateTime.now();
    if (now.difference(_lastImpact) < const Duration(milliseconds: 120)) return;
    _lastImpact = now;
    if (body.gravityScale > 1.2) {
      audio.heavy();
      _shake(0.5);
    } else {
      audio.bump();
      _shake(0.15);
    }
  }

  void _shake(double intensity) {
    final rnd = Random();
    shake = Offset(
      (rnd.nextDouble() - 0.5) * intensity,
      (rnd.nextDouble() - 0.5) * intensity,
    );
    notifyListeners();
  }

  void _burst(Offset center, int count, Color color, {bool unit = false}) {
    final rnd = Random();
    for (var i = 0; i < count; i++) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = 1.5 + rnd.nextDouble() * 3.5;
      sparks.add(Spark(
        pos: center,
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 1),
        life: 0.5 + rnd.nextDouble() * 0.5,
        maxLife: 1.0,
        color: color,
      ));
    }
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    super.dispose();
  }
}
