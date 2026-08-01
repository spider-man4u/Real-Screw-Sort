import '../../game/engine/models.dart';
import 'handcrafted.dart';
import 'level_generator.dart';

/// The full level list: 30 handcrafted + procedurally generated up to
/// [totalLevels]. Generated levels are created lazily and cached.
class LevelCatalog {
  LevelCatalog({this.totalLevels = 200});

  static const int handcraftedCount = 30;

  final int totalLevels;

  final Map<int, LevelDef> _cache = {};

  static GenParams paramsFor(int id) {
    if (id <= 50) return difficultyBands[0];
    if (id <= 150) return difficultyBands[1];
    return difficultyBands[2];
  }

  LevelDef level(int id) {
    if (id < 1 || id > totalLevels) {
      throw ArgumentError('level id out of range: $id');
    }
    final cached = _cache[id];
    if (cached != null) return cached;
    if (id <= handcraftedCount) {
      return _cache[id] = handcraftedLevels[id - 1];
    }
    final generator = LevelGenerator(paramsFor(id), seed: id * 7919 + 13);
    return _cache[id] = generator.generate(id);
  }

  int get unlockedFloor => 1;

  /// Names of the difficulty chapters (PDR structure).
  static const chapters = [
    'Tutorial', 'Easy', 'Medium', 'Hard', 'Expert', 'Master',
  ];

  /// All background themes, first is free.
  static const themeList = [
    'workshop', 'construction', 'space', 'temple',
    'ice', 'steampunk', 'cyber', 'volcano',
  ];

  /// Screw skins, first is free.
  static const skinList = ['classic', 'gold', 'blue', 'pink', 'robot'];

  /// Display names for the themes (keys of [themeList]).
  static const themeNames = {
    'workshop': 'Workshop',
    'construction': 'Construction Site',
    'space': 'Space Station',
    'temple': 'Ancient Temple',
    'ice': 'Ice World',
    'steampunk': 'Steampunk Factory',
    'cyber': 'Cyber City',
    'volcano': 'Volcano',
  };

  /// Display names for the skins (keys of [skinList]).
  static const skinNames = {
    'classic': 'Classic',
    'gold': 'Gold',
    'blue': 'Blue',
    'pink': 'Pink',
    'robot': 'Robot',
  };

  static int chapterForLevel(int id) {
    if (id <= 30) return 0;
    if (id <= 50) return 1;
    if (id <= 150) return 2;
    if (id <= 350) return 3;
    if (id <= 700) return 4;
    return 5;
  }
}
