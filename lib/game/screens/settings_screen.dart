import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/game_button.dart';
import '../audio/audio_manager.dart';

/// Settings: sound, music, vibration toggles (PDR section 16).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  children: [
                    _backButton(context),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Palette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _toggleCard(
                      context,
                      icon: Icons.volume_up_rounded,
                      title: 'Sound effects',
                      value: progress.soundOn,
                      onChanged: (v) {
                        progress.setSound(v);
                        audio.setSoundEnabled(v);
                        if (v) audio.click();
                      },
                    ),
                    _toggleCard(
                      context,
                      icon: Icons.music_note_rounded,
                      title: 'Music',
                      value: progress.musicOn,
                      onChanged: progress.setMusic,
                    ),
                    _toggleCard(
                      context,
                      icon: Icons.vibration_rounded,
                      title: 'Vibration',
                      value: progress.vibrationOn,
                      onChanged: progress.setVibration,
                    ),
                    _infoCard(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle:
                          'Real Screw Sort v1.0.0\nScrew your way through 200 levels of '
                          'real physics puzzles.',
                    ),
                    const SizedBox(height: 8),
                    GameButton(
                      label: 'Reset progress',
                      icon: Icons.delete_forever_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A80), Color(0xFFE53935)],
                      ),
                      height: 50,
                      fontSize: 16,
                      onPressed: () => _reset(context, progress),
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

  Widget _toggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Palette.blue,
        activeTrackColor: Palette.blueSky,
        secondary: Icon(icon, color: Palette.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Palette.purple),
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
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Palette.inkSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context, ProgressStore progress) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
          'Coins, stars, unlocks and achievements will be wiped. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Palette.red)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await progress.prefs.wipeAll();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
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
