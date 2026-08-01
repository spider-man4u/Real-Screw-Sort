import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../data/progress/progress_store.dart';

/// Coin counter pill shown in the top bar.
class CoinBar extends StatelessWidget {
  const CoinBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProgressStore>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0xFFFFE082), Color(0xFFF5B301)]),
              ),
              child: const Icon(Icons.attach_money_rounded, size: 18, color: Palette.ink),
            ),
            const SizedBox(width: 6),
            Text(
              '${store.coins}',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
