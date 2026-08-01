import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/levels/level_catalog.dart';
import '../../data/progress/progress_store.dart';
import '../../widgets/coin_bar.dart';
import '../audio/audio_manager.dart';

/// Scrollable level grid grouped by chapter (PDR section 6).
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<LevelCatalog>();
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
                        'Levels',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 26,
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
                    for (var chapter = 0; chapter < 6; chapter++)
                      _chapter(
                        context,
                        catalog,
                        progress,
                        audio,
                        chapter,
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

  /// (start, end) per chapter: tutorial, easy, medium, hard.
  static const _ranges = [
    (1, 30),
    (31, 50),
    (51, 150),
    (151, 200),
  ];

  Widget _chapter(
    BuildContext context,
    LevelCatalog catalog,
    ProgressStore progress,
    AudioManager audio,
    int chapter,
  ) {
    if (chapter >= _ranges.length) return const SizedBox.shrink();
    final (start, end) = _ranges[chapter];
    final levels = [for (var id = start; id <= end; id++) id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: Text(
              'Chapter ${chapter + 1} · ${LevelCatalog.chapters[chapter]}',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.inkSoft,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: [
              for (final id in levels)
                _levelCard(context, progress, audio, id, chapter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelCard(
    BuildContext context,
    ProgressStore progress,
    AudioManager audio,
    int id,
    int chapter,
  ) {
    final unlocked = id <= progress.unlockedLevel;
    final stars = progress.starsFor(id);

    return GestureDetector(
      onTap: unlocked
          ? () {
              audio.click();
              Navigator.pushNamed(context, '/game', arguments: id);
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: unlocked ? 1 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            gradient: unlocked
                ? (stars > 0
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Palette.blue, Palette.blueDeep],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFE8EDFB)],
                      ))
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD5DAEA), Color(0xFFC3C9DD)],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Palette.blue.withValues(alpha: unlocked && stars == 0 ? 0.25 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (unlocked)
                Text(
                  '$id',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: stars > 0 ? Colors.white : Palette.ink,
                  ),
                )
              else
                const Icon(Icons.lock_rounded, color: Color(0xFF8A90A8)),
              if (stars > 0)
                Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 12,
                          color: i < stars ? Palette.yellow : Colors.white54,
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

  Widget _backButton(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_rounded, color: Palette.ink),
        ),
      ),
    );
  }
}
