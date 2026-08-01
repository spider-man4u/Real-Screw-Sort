import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/coin_bar.dart';
import '../../widgets/game_button.dart';
import '../audio/audio_manager.dart';

/// Main menu (PDR section 14).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final audio = context.read<AudioManager>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Palette.screenBackdrop),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconButton(context, Icons.settings_rounded, '/settings'),
                    CoinBar(onTap: () => _go(context, '/shop')),
                    _iconButton(context, Icons.emoji_events_rounded, '/achievements'),
                  ],
                ),
              ),
              const Spacer(),
              // logo
              Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: Palette.blueGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.blue.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.construction_rounded, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Real Screw Sort',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unscrew. Release. Relax.',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Palette.inkSoft,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    GameButton(
                      label: 'PLAY',
                      icon: Icons.play_arrow_rounded,
                      height: 62,
                      fontSize: 24,
                      onPressed: () {
                        audio.click();
                        _go(context, '/levels');
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GameButton(
                            label: 'Daily Reward',
                            icon: Icons.calendar_month_rounded,
                            height: 52,
                            fontSize: 15,
                            gradient: Palette.fireGradient,
                            onPressed: () {
                              audio.click();
                              _go(context, '/daily');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GameButton(
                            label: 'Shop',
                            icon: Icons.storefront_rounded,
                            height: 52,
                            fontSize: 15,
                            gradient: Palette.violetGradient,
                            onPressed: () {
                              audio.click();
                              _go(context, '/shop');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Level ${progress.unlockedLevel} unlocked',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Palette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(BuildContext context, IconData icon, String route) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          context.read<AudioManager>().click();
          _go(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Palette.ink, size: 24),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }
}
