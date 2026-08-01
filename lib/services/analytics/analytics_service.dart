/// Analytics abstraction (PDR section 20). The mock logs to the console and
/// tracks counters in memory; a real implementation (Firebase etc.) can
/// replace it without touching game code.
abstract class AnalyticsService {
  void logEvent(String name, {Map<String, Object?> params = const {}});

  void logLevelStart(int level);

  void logLevelComplete(int level, int moves, int stars, bool usedHint);

  void logLevelFail(int level);

  void logRewardedAd(String placement, bool rewarded);

  void dispose();
}

class MockAnalyticsService implements AnalyticsService {
  final Map<String, int> _counts = {};

  int count(String name) => _counts[name] ?? 0;

  @override
  void logEvent(String name, {Map<String, Object?> params = const {}}) {
    _counts[name] = count(name) + 1;
    // ignore: avoid_print
    print('[analytics] $name $params');
  }

  @override
  void logLevelStart(int level) => logEvent('level_start', params: {'level': level});

  @override
  void logLevelComplete(int level, int moves, int stars, bool usedHint) =>
      logEvent('level_complete', params: {
        'level': level,
        'moves': moves,
        'stars': stars,
        'used_hint': usedHint,
      });

  @override
  void logLevelFail(int level) => logEvent('level_fail', params: {'level': level});

  @override
  void logRewardedAd(String placement, bool rewarded) =>
      logEvent('rewarded_ad', params: {'placement': placement, 'rewarded': rewarded});

  @override
  void dispose() {}
}
