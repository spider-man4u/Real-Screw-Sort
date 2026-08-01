import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/storage/prefs.dart';
import 'core/theme/app_theme.dart';
import 'data/levels/level_catalog.dart';
import 'data/progress/progress_store.dart';
import 'game/audio/audio_manager.dart';
import 'game/screens/achievements_screen.dart';
import 'game/screens/daily_rewards_screen.dart';
import 'game/screens/game_screen.dart';
import 'game/screens/home_screen.dart';
import 'game/screens/level_select_screen.dart';
import 'game/screens/settings_screen.dart';
import 'game/screens/shop_screen.dart';
import 'game/screens/splash_screen.dart';
import 'services/ads/ads_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/iap/iap_service.dart';

/// Global navigator key: lets services (ads overlays) push routes anywhere.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Composition root: wires services + stores and owns navigation.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.prefs,
    required this.ads,
    required this.iap,
    required this.analytics,
  });

  final AppPrefs prefs;
  final AdsService ads;
  final IapService iap;
  final AnalyticsService analytics;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ProgressStore _progress;
  late final LevelCatalog _catalog;
  late final AudioManager _audio;

  @override
  void initState() {
    super.initState();
    _catalog = LevelCatalog(totalLevels: 200);
    _progress = ProgressStore(widget.prefs, _catalog);
    _audio = AudioManager()..setSoundEnabled(widget.prefs.soundOn);
    widget.analytics.logEvent('app_start');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _progress),
        Provider<LevelCatalog>.value(value: _catalog),
        Provider<AudioManager>.value(value: _audio),
        Provider<AdsService>.value(value: widget.ads),
        Provider<IapService>.value(value: widget.iap),
        Provider<AnalyticsService>.value(value: widget.analytics),
      ],
      child: MaterialApp(
        title: 'Real Screw Sort',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: AppTheme.light(),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/': (_) => const HomeScreen(),
          '/levels': (_) => const LevelSelectScreen(),
          '/game': (_) => const GameScreen(),
          '/shop': (_) => const ShopScreen(),
          '/achievements': (_) => const AchievementsScreen(),
          '/daily': (_) => const DailyRewardsScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
