import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:real_screw_sort/core/storage/prefs.dart';
import 'package:real_screw_sort/data/levels/handcrafted.dart';
import 'package:real_screw_sort/data/levels/level_catalog.dart';
import 'package:real_screw_sort/data/progress/progress_store.dart';
import 'package:real_screw_sort/game/audio/audio_manager.dart';
import 'package:real_screw_sort/game/game_controller.dart';
import 'package:real_screw_sort/services/analytics/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameController.init sets up board and physics without throwing', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPrefs.load();
    final level = handcraftedLevels.first;
    final ctrl = GameController(
      level: level,
      progress: ProgressStore(prefs, LevelCatalog()),
      audio: AudioManager(poolSize: 0),
      analytics: MockAnalyticsService(),
    );

    expect(ctrl.init, returnsNormally,
        reason: 'init() must not read `board` before it is created');
    expect(ctrl.board, isNotNull);
    expect(ctrl.world.bodies.length, level.plates.length);
    expect(ctrl.phase, GamePhase.playing);

    ctrl.dispose();
  });

  test('GameController.init pins every screw on its plate body', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPrefs.load();
    final level = handcraftedLevels.first;
    final ctrl = GameController(
      level: level,
      progress: ProgressStore(prefs, LevelCatalog()),
      audio: AudioManager(poolSize: 0),
      analytics: MockAnalyticsService(),
    )..init();

    final pinCount = ctrl.world.bodies
        .map((b) => b.particles.where((p) => p.pins.isNotEmpty).length)
        .fold(0, (a, b) => a + b);
    expect(pinCount, level.screws.length,
        reason: 'every screw must pin a particle on its body');

    ctrl.dispose();
  });
}
