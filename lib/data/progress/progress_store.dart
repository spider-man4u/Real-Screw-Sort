import 'package:flutter/foundation.dart';

import '../core/storage/prefs.dart';
import '../data/levels/level_catalog.dart';

/// One entry of the daily reward calendar (PDR section 17).
class DailyReward {
  const DailyReward(this.day, this.label, this.amount, this.icon);

  final int day;
  final String label;
  final int amount;
  final String icon;
}

const List<DailyReward> dailyRewards = [
  DailyReward(1, 'Coins', 100, '🪙'),
  DailyReward(2, 'Hint', 2, '💡'),
  DailyReward(3, 'Undo', 2, '↩️'),
  DailyReward(4, 'Coins', 200, '🪙'),
  DailyReward(5, 'Theme Fragment', 1, '🎨'),
  DailyReward(6, 'Booster Pack', 1, '⚡'),
  DailyReward(7, 'Premium Chest', 1, '🎁'),
];

/// Global player state: coins, unlocks, stars, settings, achievements.
/// Single ChangeNotifier the whole UI listens to.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this.prefs, this.catalog);

  final AppPrefs prefs;
  final LevelCatalog catalog;

  int get coins => prefs.coins;

  int get unlockedLevel => prefs.unlockedLevel;

  int starsFor(int level) => prefs.starsFor(level);

  bool get soundOn => prefs.soundOn;

  bool get musicOn => prefs.musicOn;

  bool get vibrationOn => prefs.vibrationOn;

  bool get noAds => prefs.noAds;

  int get hints => prefs.hints;

  int get undos => prefs.undos;

  int get screwsRemoved => prefs.screwsRemoved;

  int get hintsUsed => prefs.hintsUsed;

  set hintsUsed(int v) {
    prefs.hintsUsed = v;
    notifyListeners();
  }

  int get perfects => prefs.perfects;

  Set<String> get achievements => prefs.achievements;

  void addCoins(int n) {
    prefs.coins = coins + n;
    notifyListeners();
  }

  void spendCoins(int n) {
    prefs.coins = maxInt(0, coins - n);
    notifyListeners();
  }

  int maxInt(int a, int b) => a > b ? a : b;

  bool buy(int cost) {
    if (coins < cost) return false;
    spendCoins(cost);
    return true;
  }

  void useHint() {
    if (prefs.hints > 0) {
      prefs.hints = prefs.hints - 1;
      notifyListeners();
    }
  }

  void addHints(int n) {
    prefs.hints = hints + n;
    notifyListeners();
  }

  void useUndo() {
    if (prefs.undos > 0) {
      prefs.undos = undos - 1;
      notifyListeners();
    }
  }

  void addUndos(int n) {
    prefs.undos = undos + n;
    notifyListeners();
  }

  bool get hasFreeHints => prefs.hints > 0;

  bool get hasFreeUndos => prefs.undos > 0;

  /// Records a finished level. Returns the level ids newly unlocked.
  List<int> completeLevel(int levelId, int stars, int moves) {
    final prev = prefs.starsFor(levelId);
    final newUnlocks = <int>[];
    if (stars > prev) {
      prefs.setStars(levelId, stars);
      if (stars == 3) prefs.perfects = perfects + 1;
    }
    if (levelId >= unlockedLevel && levelId < catalog.totalLevels) {
      prefs.unlockedLevel = levelId + 1;
      newUnlocks.add(levelId + 1);
    }
    if (levelId == catalog.totalLevels) {
      prefs.unlockedLevel = catalog.totalLevels;
    }
    prefs.levelsPlayed = prefs.levelsPlayed + 1;
    notifyListeners();
    return newUnlocks;
  }

  void addScrewRemoved() {
    prefs.screwsRemoved = screwsRemoved + 1;
  }

  void unlockTheme(String theme) {
    prefs.unlockTheme(theme);
    notifyListeners();
  }

  void unlockSkin(String skin) {
    prefs.unlockSkin(skin);
    notifyListeners();
  }

  bool hasTheme(String theme) => prefs.hasTheme(theme);

  bool hasSkin(String skin) => prefs.hasSkin(skin);

  void setNoAds() {
    prefs.noAds = true;
    notifyListeners();
  }

  void setSound(bool v) {
    prefs.soundOn = v;
    notifyListeners();
  }

  void setMusic(bool v) {
    prefs.musicOn = v;
    notifyListeners();
  }

  void setVibration(bool v) {
    prefs.vibrationOn = v;
    notifyListeners();
  }

  // ---- daily rewards ----

  bool get canClaimDaily {
    if (prefs.dailyClaimedToday) return false;
    // reset streak if more than one day passed
    final now = DateTime.now();
    final last = DateTime.fromMillisecondsSinceEpoch(prefs.lastLoginDay);
    if (prefs.lastLoginDay != 0 && now.difference(last).inDays > 1) {
      prefs.loginStreak = 1;
    }
    return true;
  }

  int get dailyStreak => prefs.loginStreak;

  void claimDaily() {
    if (!canClaimDaily) return;
    final reward = dailyRewards[(prefs.dailyIndex) % dailyRewards.length];
    switch (reward.icon) {
      case '💡':
        addHints(reward.amount);
      case '↩️':
        addUndos(reward.amount);
      case '🎨':
        // theme fragment: unlock the next locked theme
        for (final t in catalog.themeList) {
          if (!hasTheme(t)) {
            unlockTheme(t);
            break;
          }
        }
      case '🎁':
        addCoins(500);
      default:
        addCoins(reward.amount);
    }
    prefs.dailyClaimedToday = true;
    prefs.dailyIndex = (prefs.dailyIndex + 1) % dailyRewards.length;
    prefs.lastLoginDay = DateTime.now().millisecondsSinceEpoch;
    prefs.loginStreak = prefs.loginStreak + 1;
    notifyListeners();
  }

  // ---- achievements ----

  static const Map<String, String> achievementTitles = {
    'first_level': 'First Step',
    'levels_25': 'Getting Started',
    'levels_50': 'Screw Master',
    'levels_100': 'Centurion',
    'no_hint': 'Pure Skill',
    'screws_1000': 'Screw Collector',
    'login_7': 'Loyal Player',
    'perfect_50': 'Perfect Ten',
    'first_purchase': 'Big Spender',
  };

  void checkAchievements({int? completedLevel, bool? wonWithoutHint}) {
    final ac = prefs.achievements;
    void grant(String id) {
      if (!ac.contains(id)) {
        ac.add(id);
        prefs.achievements = ac;
      }
    }

    if (prefs.levelsPlayed >= 1) grant('first_level');
    if (prefs.levelsPlayed >= 25) grant('levels_25');
    if (prefs.levelsPlayed >= 50) grant('levels_50');
    if (prefs.levelsPlayed >= 100) grant('levels_100');
    if (prefs.screwsRemoved >= 1000) grant('screws_1000');
    if (prefs.loginStreak >= 7) grant('login_7');
    if (prefs.perfects >= 50) grant('perfect_50');
    if (wonWithoutHint ?? false) grant('no_hint');
    if (prefs.purchased('anything')) grant('first_purchase');
    if (ac.isNotEmpty) {
      prefs.achievements = ac;
      notifyListeners();
    }
  }

  int get achievementsCount => prefs.achievements.length;

  void refreshDailyStreak() {
    prefs.lastLoginDay = DateTime.now().millisecondsSinceEpoch;
  }
}
