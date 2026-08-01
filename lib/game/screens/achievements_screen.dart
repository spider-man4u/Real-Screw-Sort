import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/coin_bar.dart';
import '../audio/audio_manager.dart';

/// Achievements list (PDR section 18): count, requirements, unlocked state.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const _iconById = {
    'first_level': Icons.flag_rounded,
    'levels_25': Icons.military_tech_rounded,
    'levels_50': Icons.workspace_premium_rounded,
    'levels_100': Icons.emoji_events_rounded,
    'no_hint': Icons.psychology_rounded,
    'screws_1000': Icons.settings_rounded,
    'login_7': Icons.calendar_month_rounded,
    'perfect_50': Icons.star_rounded,
    'first_purchase': Icons.shopping_bag_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final unlocked = progress.achievements;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Palette.screenBackdrop),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _backButton(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Achievements  ${unlocked.length}/${ProgressStore.achievementTitles.length}',
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Palette.ink,
                        ),
                      ),
                    ),
                    CoinBar(onTap: () => Navigator.pushNamed(context, '/shop')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    for (final entry in ProgressStore.achievementTitles.entries)
                      _achievementCard(
                        context,
                        id: entry.key,
                        title: entry.value,
                        done: unlocked.contains(entry.key),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _achievementCard(
    BuildContext context, {
    required String id,
    required String title,
    required bool done,
  }) {
    final color = done ? Palette.green : Palette.metal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconById[id] ?? Icons.emoji_events_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                Text(
                  done ? 'Completed' : 'Keep playing to unlock',
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
          Icon(
            done ? Icons.check_circle_rounded : Icons.lock_rounded,
            color: done ? Palette.green : const Color(0xFFB9BFD6),
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          context.read<AudioManager>().click();
          Navigator.pop(context);
        },
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_rounded, color: Palette.ink),
        ),
      ),
    );
  }
}
