import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/game_button.dart';
import '../game_controller.dart';
import '../../services/ads/ads_service.dart';
import '../../services/analytics/analytics_service.dart';

/// Full-screen victory overlay: stars, coins, continue buttons.
class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key, required this.controller, required this.onNext});

  final GameController controller;
  final VoidCallback onNext;

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _starsCtrl;
  late final Animation<double> _pop;
  bool _doubled = false;

  @override
  void initState() {
    super.initState();
    _starsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
    _pop = CurvedAnimation(parent: _starsCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _starsCtrl.dispose();
    super.dispose();
  }

  Future<void> _doubleCoins() async {
    if (_doubled) return;
    final progress = context.read<ProgressStore>();
    final ads = context.read<AdsService>();
    final rewarded = await ads.showRewarded(RewardPlacement.doubleCoins);
    context.read<AnalyticsService>().logRewardedAd('double_coins', rewarded);
    if (!rewarded || !mounted) return;
    progress.addCoins(widget.controller.lastCoins);
    setState(() => _doubled = true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final coins = ctrl.lastCoins;
    final hasNext = ctrl.level.id < 200;

    return Container(
      decoration: const BoxDecoration(gradient: Palette.screenBackdrop),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SoftCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Level Complete!',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        ScaleTransition(
                          scale: _pop,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: _starsCtrl.value >= 0.15 + i * 0.28 ? 1 : 0.25,
                            child: Icon(
                              i < ctrl.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 56,
                              color: Palette.yellow,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${ctrl.moveCount} moves · par ${ctrl.par}',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Palette.inkSoft,
                    ),
                  ),
                  if (ctrl.newUnlocks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🎉 Level ${ctrl.newUnlocks.first} unlocked!',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Palette.green,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Palette.yellow.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Palette.orange),
                        const SizedBox(width: 8),
                        Text(
                          '+$coins coins',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    label: _doubled ? 'Coins doubled!' : 'Double coins (ad)',
                    icon: Icons.bolt_rounded,
                    gradient: Palette.fireGradient,
                    height: 48,
                    fontSize: 16,
                    onPressed: _doubled ? null : _doubleCoins,
                  ),
                  const SizedBox(height: 16),
                  GameButton(
                    label: hasNext ? 'Next Level' : 'You beat all 200 levels!',
                    icon: hasNext ? Icons.arrow_forward_rounded : Icons.emoji_events_rounded,
                    height: 54,
                    fontSize: 19,
                    onPressed: widget.onNext,
                  ),
                  const SizedBox(height: 10),
                  GameButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    gradient: Palette.violetGradient,
                    height: 48,
                    fontSize: 16,
                    onPressed: () {
                      ctrl.restart();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Back to menu',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Palette.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
