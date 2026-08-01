import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/levels/level_catalog.dart';
import '../../data/progress/progress_store.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/iap/iap_service.dart';
import '../../widgets/coin_bar.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/game_button.dart';
import '../audio/audio_manager.dart';

/// Shop: IAP products (mock grants instantly) + themes & skins.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _busy = false;

  Future<void> _buy(IapProduct product) async {
    if (_busy) return;
    setState(() => _busy = true);
    final iap = context.read<IapService>();
    final progress = context.read<ProgressStore>();
    final audio = context.read<AudioManager>();
    final ok = await iap.purchase(product);
    if (ok && mounted) {
      audio.coin();
      switch (product.id) {
        case 'remove_ads':
          progress.setNoAds();
        case 'coins_small':
          progress.addCoins(500);
        case 'coins_large':
          progress.addCoins(3000);
        case 'starter_pack':
          progress.addCoins(200);
          progress.addHints(5);
          progress.addUndos(5);
        case 'theme_pack':
          for (final t in LevelCatalog.themeList) {
            progress.unlockTheme(t);
          }
        case 'skin_pack':
          for (final s in LevelCatalog.skinList) {
            progress.unlockSkin(s);
          }
      }
      progress.checkAchievements();
      context.read<AnalyticsService>().logEvent('iap_${product.id}');
      showToast(context, '${product.name} purchased!');
    } else if (mounted) {
      showToast(context, 'Purchases are not available in this build yet');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();

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
                        'Shop',
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Palette.ink,
                        ),
                      ),
                    ),
                    CoinBar(onTap: () {}),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _sectionTitle('Packs'),
                    for (final product in iapProducts) _productCard(product),
                    const SizedBox(height: 20),
                    _sectionTitle('Backgrounds'),
                    for (final theme in LevelCatalog.themeList)
                      _themeCard(theme, progress),
                    const SizedBox(height: 20),
                    _sectionTitle('Screw Skins'),
                    for (final skin in LevelCatalog.skinList) _skinCard(skin, progress),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Palette.inkSoft,
          ),
        ),
      );

  Widget _productCard(IapProduct product) {
    final iap = context.read<IapService>();
    final owned = iap.isPurchased(product.id);
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: Palette.blueGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(product.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                Text(
                  product.description,
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
          GameButton(
            label: owned ? 'Owned' : product.price,
            height: 40,
            fontSize: 14,
            gradient: owned ? Palette.violetGradient : Palette.fireGradient,
            onPressed: owned ? null : () => _buy(product),
          ),
        ],
      ),
    );
  }

  Widget _themeCard(String theme, ProgressStore progress) {
    final owned = progress.hasTheme(theme);
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _swatch(theme),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              LevelCatalog.themeNames[theme] ?? theme,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
              ),
            ),
          ),
          GameButton(
            label: owned ? 'Equipped' : '400',
            height: 40,
            fontSize: 14,
            gradient: owned ? Palette.blueGradient : Palette.violetGradient,
            onPressed: owned ? null : () => _buyTheme(progress, theme),
          ),
        ],
      ),
    );
  }

  Future<void> _buyTheme(ProgressStore progress, String theme) async {
    if (!progress.buy(400)) {
      showToast(context, 'Not enough coins');
      return;
    }
    progress.unlockTheme(theme);
    showToast(context, 'Theme unlocked!');
  }

  Widget _skinCard(String skin, ProgressStore progress) {
    final owned = progress.hasSkin(skin);
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _skinSwatch(skin),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              LevelCatalog.skinNames[skin] ?? skin,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
              ),
            ),
          ),
          GameButton(
            label: owned ? 'Equipped' : '300',
            height: 40,
            fontSize: 14,
            gradient: owned ? Palette.blueGradient : Palette.violetGradient,
            onPressed: owned ? null : () => _buySkin(progress, skin),
          ),
        ],
      ),
    );
  }

  Future<void> _buySkin(ProgressStore progress, String skin) async {
    if (!progress.buy(300)) {
      showToast(context, 'Not enough coins');
      return;
    }
    progress.unlockSkin(skin);
    showToast(context, 'Skin unlocked!');
  }

  List<Color> _swatch(String theme) => switch (theme) {
        'workshop' => [const Color(0xFFD9A05F), const Color(0xFF8E5F30)],
        'construction' => [const Color(0xFFF59E0B), const Color(0xFF92400E)],
        'space' => [const Color(0xFF9CA3AF), const Color(0xFF0B1220)],
        'temple' => [const Color(0xFFEFD9B0), const Color(0xFFA98E5E)],
        'ice' => [const Color(0xFFE1F5FE), const Color(0xFF81D4FA)],
        'steampunk' => [const Color(0xFFC08552), const Color(0xFF6B4522)],
        'cyber' => [const Color(0xFF8B5CF6), const Color(0xFF4C1D95)],
        'volcano' => [const Color(0xFFFF8A65), const Color(0xFFA63D24)],
        _ => [Palette.blue, Palette.blueDeep],
      };

  List<Color> _skinSwatch(String skin) => switch (skin) {
        'classic' => [const Color(0xFFDDE3EE), const Color(0xFF6E7891)],
        'gold' => [const Color(0xFFFFE082), const Color(0xFFC07F00)],
        'blue' => [const Color(0xFFB3D4FF), const Color(0xFF1F3FA8)],
        'pink' => [const Color(0xFFFFC1E3), const Color(0xFFB73A72)],
        'robot' => [const Color(0xFFB2F0CE), const Color(0xFF14764F)],
        _ => [Palette.metal, Palette.ink],
      };

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
