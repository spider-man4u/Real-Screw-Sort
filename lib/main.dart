import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/prefs.dart';
import 'services/ads/ads_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/iap/iap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load();
  final analytics = MockAnalyticsService();
  final iap = MockIapService((product) {
    analytics.logEvent('iap_purchase', params: {'product': product.id});
  });

  runApp(
    AppShell(
      prefs: prefs,
      ads: MockAdsService(navigatorKey: appNavigatorKey),
      iap: iap,
      analytics: analytics,
    ),
  );
}
