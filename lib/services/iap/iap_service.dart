import 'package:flutter/material.dart';

/// A purchasable product (IAP). The mock grants it instantly.
class IapProduct {
  const IapProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    this.description = '',
  });

  final String id;
  final String name;
  final String price;
  final IconData icon;
  final String description;
}

const List<IapProduct> iapProducts = [
  IapProduct(
    id: 'remove_ads',
    name: 'Remove Ads',
    price: '\$2.99',
    icon: Icons.block_rounded,
    description: 'No more ads, ever.',
  ),
  IapProduct(
    id: 'coins_small',
    name: 'Coin Pack S',
    price: '\$0.99',
    icon: Icons.monetization_on_rounded,
    description: '500 coins',
  ),
  IapProduct(
    id: 'coins_large',
    name: 'Coin Pack L',
    price: '\$4.99',
    icon: Icons.monetization_on_rounded,
    description: '3000 coins',
  ),
  IapProduct(
    id: 'starter_pack',
    name: 'Starter Pack',
    price: '\$1.99',
    icon: Icons.rocket_launch_rounded,
    description: '200 coins + 5 hints + 5 undos',
  ),
  IapProduct(
    id: 'theme_pack',
    name: 'Premium Theme Pack',
    price: '\$3.99',
    icon: Icons.palette_rounded,
    description: 'All themes unlocked',
  ),
  IapProduct(
    id: 'skin_pack',
    name: 'Special Screw Skins',
    price: '\$2.49',
    icon: Icons.construction_rounded,
    description: 'All screw skins',
  ),
];

/// Abstract store interface. The shop only grants items when [purchase]
/// succeeds (real billing integration required for that).
abstract class IapService {
  /// Purchases a product. Returns true only after the purchase was
  /// completed and verified by the store. Never auto-grants.
  Future<bool> purchase(IapProduct product);

  bool isPurchased(String productId);

  void dispose();
}

/// Placeholder store used while no store billing integration is wired.
/// It never grants anything: tapping a pack in the shop opens no billing
/// flow and rewards no coins. Simulated purchases live in the developer
/// menu instead of the production purchase path.
class MockIapService implements IapService {
  MockIapService(this._onPurchased);

  final void Function(IapProduct product) _onPurchased;

  final Set<String> _owned = {};

  @override
  bool isPurchased(String productId) => _owned.contains(productId);

  @override
  Future<bool> purchase(IapProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return false;
  }

  @override
  void dispose() {}
}
