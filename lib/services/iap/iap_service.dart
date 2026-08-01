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

/// Abstract store interface; mock implementation grants instantly.
abstract class IapService {
  /// Purchases a product. Returns true on success.
  Future<bool> purchase(IapProduct product);

  bool isPurchased(String productId);

  void dispose();
}

/// In-app demo store: everything is granted immediately with a fancy dialog.
class MockIapService implements IapService {
  MockIapService(this._onPurchased);

  final void Function(IapProduct product) _onPurchased;

  final Set<String> _owned = {};

  @override
  bool isPurchased(String productId) => _owned.contains(productId);

  @override
  Future<bool> purchase(IapProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (product.id == 'remove_ads') {
      _owned.add('remove_ads');
      _onPurchased(product);
      return true;
    }
    _owned.add(product.id);
    _owned.add('anything');
    _onPurchased(product);
    return true;
  }

  @override
  void dispose() {}
}
