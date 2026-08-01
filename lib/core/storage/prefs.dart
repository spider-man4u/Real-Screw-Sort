import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper around SharedPreferences.
class AppPrefs {
  AppPrefs._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> load() async =>
      AppPrefs._(await SharedPreferences.getInstance());

  static const _kCoins = 'coins';
  static const _kUnlocked = 'unlocked_level';
  static const _kStars = 'stars_';
  static const _kSound = 'sound_on';
  static const _kMusic = 'music_on';
  static const _kVibration = 'vibration_on';
  static const _kNoAds = 'no_ads';
  static const _kTheme = 'theme_';
  static const _kSkin = 'skin_';
  static const _kDailyIndex = 'daily_index';
  static const _kDailyClaimed = 'daily_claimed';
  static const _kDailyLast = 'daily_last_claim';
  static const _kScrewsRemoved = 'screws_removed';
  static const _kLevelsPlayed = 'levels_played';
  static const _kHintsUsed = 'hints_used';
  static const _kHints = 'hints';
  static const _kUndos = 'undos';
  static const _kPerfects = 'perfects';
  static const _kPurchased = 'purchased_';
  static const _kAchievements = 'achievements';
  static const _kTutorialSeen = 'tutorial_seen';
  static const _kAdCount = 'ad_count';
  static const _kLoginStreak = 'login_streak';
  static const _kLastLogin = 'last_login';

  int get coins => _prefs.getInt(_kCoins) ?? 0;

  set coins(int v) => _prefs.setInt(_kCoins, v);

  int get unlockedLevel => _prefs.getInt(_kUnlocked) ?? 1;

  set unlockedLevel(int v) => _prefs.setInt(_kUnlocked, v);

  int starsFor(int level) => _prefs.getInt('$_kStars$level') ?? 0;

  void setStars(int level, int stars) => _prefs.setInt('$_kStars$level', stars);

  bool get soundOn => _prefs.getBool(_kSound) ?? true;

  set soundOn(bool v) => _prefs.setBool(_kSound, v);

  bool get musicOn => _prefs.getBool(_kMusic) ?? true;

  set musicOn(bool v) => _prefs.setBool(_kMusic, v);

  bool get vibrationOn => _prefs.getBool(_kVibration) ?? true;

  set vibrationOn(bool v) => _prefs.setBool(_kVibration, v);

  bool get noAds => _prefs.getBool(_kNoAds) ?? false;

  set noAds(bool v) => _prefs.setBool(_kNoAds, v);

  bool hasTheme(String theme) => _prefs.getBool('$_kTheme$theme') ?? theme == 'workshop';

  void unlockTheme(String theme) => _prefs.setBool('$_kTheme$theme', true);

  bool hasSkin(String skin) => _prefs.getBool('$_kSkin$skin') ?? skin == 'classic';

  void unlockSkin(String skin) => _prefs.setBool('$_kSkin$skin', true);

  int get dailyIndex => _prefs.getInt(_kDailyIndex) ?? 0;

  set dailyIndex(int v) => _prefs.setInt(_kDailyIndex, v);

  bool get dailyClaimedToday => _prefs.getBool('$_kDailyClaimed${_todayKey()}') ?? false;

  set dailyClaimedToday(bool v) => _prefs.setBool('$_kDailyClaimed${_todayKey()}', v);

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  int get screwsRemoved => _prefs.getInt(_kScrewsRemoved) ?? 0;

  set screwsRemoved(int v) => _prefs.setInt(_kScrewsRemoved, v);

  int get levelsPlayed => _prefs.getInt(_kLevelsPlayed) ?? 0;

  set levelsPlayed(int v) => _prefs.setInt(_kLevelsPlayed, v);

  int get hintsUsed => _prefs.getInt(_kHintsUsed) ?? 0;

  set hintsUsed(int v) => _prefs.setInt(_kHintsUsed, v);

  int get hints => _prefs.getInt(_kHints) ?? 3;

  set hints(int v) => _prefs.setInt(_kHints, v);

  int get undos => _prefs.getInt(_kUndos) ?? 3;

  set undos(int v) => _prefs.setInt(_kUndos, v);

  int get perfects => _prefs.getInt(_kPerfects) ?? 0;

  set perfects(int v) => _prefs.setInt(_kPerfects, v);

  bool purchased(String id) => _prefs.getBool('$_kPurchased$id') ?? false;

  void markPurchased(String id) => _prefs.setBool('$_kPurchased$id', true);

  Set<String> get achievements => _prefs.getStringList(_kAchievements)?.toSet() ?? {};

  set achievements(Set<String> v) => _prefs.setStringList(_kAchievements, v.toList());

  bool get tutorialSeen => _prefs.getBool(_kTutorialSeen) ?? false;

  set tutorialSeen(bool v) => _prefs.setBool(_kTutorialSeen, v);

  int get adCount => _prefs.getInt(_kAdCount) ?? 0;

  set adCount(int v) => _prefs.setInt(_kAdCount, v);

  int get loginStreak => _prefs.getInt(_kLoginStreak) ?? 1;

  set loginStreak(int v) => _prefs.setInt(_kLoginStreak, v);

  int get lastLoginDay => _prefs.getInt(_kLastLogin) ?? 0;

  set lastLoginDay(int v) => _prefs.setInt(_kLastLogin, v);

  /// Wipes all stored progress (used by "Reset progress" in settings).
  Future<void> wipeAll() async {
    await _prefs.clear();
    await _prefs.reload();
  }
}
