import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/levels/level_catalog.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/coin_bar.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/game_button.dart';
import '../audio/audio_manager.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../rendering/board_painter.dart';
import '../rendering/themes.dart';
import 'victory_screen.dart';
import '../../services/ads/ads_service.dart';
import '../../services/analytics/analytics_service.dart';

/// The core gameplay screen: HUD + physics board + overlays.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameController _ctrl;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  String _themeKey = 'workshop';
  final String _skinKey = 'classic';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final levelId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
    final catalog = context.read<LevelCatalog>();
    final progress = context.read<ProgressStore>();
    final level = catalog.level(levelId);
    _themeKey = level.theme;
    _ctrl = GameController(
      level: level,
      progress: progress,
      audio: context.read<AudioManager>(),
      analytics: context.read<AnalyticsService>(),
      themeKey: _themeKey,
      skinKey: _skinKey,
    )..init();
    _ctrl.addListener(_onCtrl);
    _ticker!.start();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ticker?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt > 0 && _ctrl.tick(dt)) {
      setState(() {});
    }
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------ interactions

  void _onTapUp(TapUpDetails details, Size boardSize, Offset origin, double cell) {
    final local = details.localPosition;
    if (local.dx < origin.dx || local.dy < origin.dy) return;
    final col = ((local.dx - origin.dx) / cell).floor();
    final row = ((local.dy - origin.dy) / cell).floor();
    final level = _ctrl.level;
    if (col < 0 || row < 0 || col >= level.cols || row >= level.rows) return;
    if (_ctrl.phase != GamePhase.playing) return;
    _ctrl.tapCell(Cell(col, row));
  }

  Future<void> _hint() async {
    if (_ctrl.phase != GamePhase.playing) return;
    final progress = context.read<ProgressStore>();
    final analytics = context.read<AnalyticsService>();
    if (!progress.hasFreeHints) {
      final ad = context.read<AdsService>();
      final rewarded = await ad.showRewarded(RewardPlacement.hint);
      analytics.logRewardedAd('hint', rewarded);
      if (!rewarded || !mounted) return;
      progress.addHints(1);
    }
    if (!mounted) return;
    if (_ctrl.requestHint()) {
      analytics.logEvent('hint_used');
    } else {
      showToast(context, 'No hint available');
    }
  }

  Future<void> _undo() async {
    final progress = context.read<ProgressStore>();
    final analytics = context.read<AnalyticsService>();
    if (!progress.hasFreeUndos) {
      final ad = context.read<AdsService>();
      final rewarded = await ad.showRewarded(RewardPlacement.undo);
      analytics.logRewardedAd('undo', rewarded);
      if (!rewarded || !mounted) return;
      progress.addUndos(1);
    }
    if (!mounted) return;
    final ok = _ctrl.undo();
    if (!ok) {
      showToast(context, 'One-way screws cannot be undone!');
    }
  }

  Future<void> _pause() async {
    final paused = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(controller: _ctrl),
    );
    if (paused == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _restart() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Restart level?',
      message: 'All progress in this level will be lost.',
      confirmLabel: 'Restart',
    );
    if (ok && mounted) {
      _ctrl.restart();
      context.read<AudioManager>().tick();
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final level = _ctrl.level;
    final phase = _ctrl.phase;

    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _backgroundFor(_themeKey),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _hud(context, progress, level),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cell = _boardCell(constraints);
                        final origin = _boardOrigin(constraints, cell);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) => _onTapUp(d, constraints.biggest, origin, cell),
                          child: CustomPaint(
                            size: constraints.biggest,
                            painter: BoardPainter(BoardPaintData(
                              level: level,
                              board: _ctrl.board,
                              world: _ctrl.world,
                              cell: cell,
                              origin: origin,
                              fx: _ctrl.fx,
                              sparks: _ctrl.sparks,
                              highlightScrew: _ctrl.highlightScrew,
                              shake: _ctrl.shake,
                              themeKey: _themeKey,
                              skinKey: _skinKey,
                            )),
                          ),
                        );
                      },
                    ),
                  ),
                  _bottomBar(context, progress),
                ],
              ),
            ),
          ),
        ),
        if (phase == GamePhase.won)
          VictoryScreen(
            controller: _ctrl,
            onNext: _next,
          ),
        if (phase == GamePhase.lost)
          Positioned.fill(
            child: _LoseOverlay(
              controller: _ctrl,
              onUndo: _undo,
              onRestart: _restart,
            ),
          ),
      ],
    );
  }

  void _next() {
    final id = _ctrl.level.id;
    _maybeInterstitial();
    Navigator.of(context).pushReplacementNamed('/game', arguments: id + 1);
  }

  Future<void> _maybeInterstitial() async {
    final prefs = context.read<ProgressStore>().prefs;
    if (prefs.noAds) return;
    prefs.adCount = prefs.adCount + 1;
    if (prefs.adCount % 3 == 0) {
      await context.read<AdsService>().showInterstitial();
    }
  }

  List<Color> _backgroundFor(String themeKey) {
    final t = themeForKey(themeKey);
    return [t.background, t.background.withValues(alpha: 0.6), Palette.snow];
  }

  double _boardCell(BoxConstraints constraints) {
    final level = _ctrl.level;
    final w = constraints.maxWidth - 24;
    final h = constraints.maxHeight - 12;
    return (w / level.cols < h / level.rows ? w / level.cols : h / level.rows)
        .clamp(24.0, 78.0)
        .toDouble();
  }

  Offset _boardOrigin(BoxConstraints constraints, double cell) {
    final level = _ctrl.level;
    final boardW = level.cols * cell;
    final boardH = level.rows * cell;
    return Offset(
      (constraints.maxWidth - boardW) / 2,
      (constraints.maxHeight - boardH) / 2,
    );
  }

  // ------------------------------------------------------------------- HUD
  Widget _hud(BuildContext context, ProgressStore progress, LevelDef level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          CircleActionButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              context.read<AudioManager>().click();
              Navigator.pop(context);
            },
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${level.id}',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                Text(
                  level.targetPlateId != null
                      ? 'Free the golden panel'
                      : 'Free all panels',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Palette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          CoinBar(onTap: () => Navigator.pushNamed(context, '/shop')),
          const SizedBox(width: 8),
          CircleActionButton(
            icon: Icons.lightbulb_rounded,
            badge: '${progress.hints}',
            onPressed: _hint,
            color: Palette.orange,
            size: 42,
          ),
          const SizedBox(width: 8),
          CircleActionButton(
            icon: Icons.undo_rounded,
            badge: '${progress.undos}',
            onPressed: _undo,
            color: Palette.blue,
            size: 42,
          ),
          const SizedBox(width: 8),
          CircleActionButton(
            icon: Icons.pause_rounded,
            onPressed: _pause,
            color: Palette.purple,
            size: 42,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- bottom bar
  Widget _bottomBar(BuildContext context, ProgressStore progress) {
    final ctrl = _ctrl;
    final hand = ctrl.board.handScrew;
    final handScrew = hand != null ? ctrl.level.screws[hand] : null;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _stat(context, Icons.handyman_rounded, 'Moves', '${ctrl.moveCount}'),
          const SizedBox(width: 12),
          _stat(
            context,
            Icons.star_rounded,
            'Par',
            '${ctrl.par}',
            color: Palette.yellow,
          ),
          const Spacer(),
          if (handScrew == null)
            const Text(
              'Tap screws to remove them',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Palette.inkSoft,
              ),
            )
          else
            GestureDetector(
              onTap: ctrl.canUndo ? () => _ctrl.slotHand() : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: Palette.blueGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: screwColors[handScrew.color! % screwColors.length],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Return to slot',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label, String value,
      {Color color = Palette.blue}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
      ],
    );
  }
}

/// Pause dialog: resume / restart / quit.
class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paused', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            height: 50,
            fontSize: 17,
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Restart',
            icon: Icons.refresh_rounded,
            gradient: Palette.fireGradient,
            height: 50,
            fontSize: 17,
            onPressed: () {
              controller.restart();
              Navigator.pop(context, false);
            },
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Quit to menu',
            icon: Icons.home_rounded,
            gradient: Palette.violetGradient,
            height: 50,
            fontSize: 17,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}

/// Deadlock overlay: offer undo or restart.
class _LoseOverlay extends StatelessWidget {
  const _LoseOverlay({
    required this.controller,
    required this.onUndo,
    required this.onRestart,
  });

  final GameController controller;
  final VoidCallback onUndo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
          child: SoftCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_dissatisfied_rounded, size: 56, color: Palette.orange),
                const SizedBox(height: 12),
                const Text(
                  'No moves left!',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Undo a move or restart the level.',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Palette.inkSoft,
                  ),
                ),
                const SizedBox(height: 18),
                GameButton(
                  label: 'Undo',
                  icon: Icons.undo_rounded,
                  height: 50,
                  fontSize: 17,
                  onPressed: onUndo,
                ),
                const SizedBox(height: 10),
                GameButton(
                  label: 'Restart',
                  icon: Icons.refresh_rounded,
                  gradient: Palette.fireGradient,
                  height: 50,
                  fontSize: 17,
                  onPressed: onRestart,
                ),
              ],
            ),
          ),
        ),
      );
  }
}
