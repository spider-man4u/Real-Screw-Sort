import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Big rounded gradient button used everywhere.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient = Palette.blueGradient,
    this.height = 56,
    this.fontSize = 20,
    this.foregroundColor = Colors.white,
    this.shadow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final double height;
  final double fontSize;
  final Color foregroundColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize + 4, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: foregroundColor,
          ),
        ),
      ],
    );
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : const LinearGradient(
          colors: [Color(0xFFC6CBE0), Color(0xFFB0B6CE)],
        ),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: shadow && enabled
            ? [
                BoxShadow(
                  color: (gradient == Palette.blueGradient
                          ? Palette.blue
                          : gradient == Palette.fireGradient
                              ? Palette.orange
                              : Palette.purple)
                      .withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: SizedBox(height: height, child: Center(child: content)),
    );

    return enabled
        ? GestureDetector(
            onTap: onPressed,
            child: decorated,
          )
        : Opacity(opacity: 0.55, child: decorated);
  }
}

/// Small circular icon action button (HUD buttons).
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.color = Palette.ink,
    this.backgroundColor = Colors.white,
    this.enabled = true,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color color;
  final Color backgroundColor;
  final bool enabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: size * 0.52),
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Palette.orange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Baloo2',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A card with soft shadow used across screens.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
