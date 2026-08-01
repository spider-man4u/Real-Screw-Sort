import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// PDR palette: blue, yellow, orange, purple, white - modern & playful.
class Palette {
  Palette._();

  static const ink = Color(0xFF1C2550);
  static const inkSoft = Color(0xFF4A5485);
  static const blue = Color(0xFF3B6BFF);
  static const blueDeep = Color(0xFF2A4BD7);
  static const blueSky = Color(0xFF6FA3FF);
  static const yellow = Color(0xFFFFC93C);
  static const orange = Color(0xFFFF8A3D);
  static const orangeDeep = Color(0xFFF26A2E);
  static const purple = Color(0xFF8E5BFF);
  static const purpleDeep = Color(0xFF6E3DF0);
  static const green = Color(0xFF2ECB8C);
  static const red = Color(0xFFFF5D6C);
  static const snow = Color(0xFFF7F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const wood = Color(0xFFB9894F);
  static const woodDark = Color(0xFF8E5F30);
  static const metal = Color(0xFF8B93A9);

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueSky, blue, blueDeep],
  );

  static const fireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [yellow, orange, orangeDeep],
  );

  static const violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, purpleDeep],
  );

  static const glassWhite = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFEEF2FF)],
  );

  static const screenBackdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF0FF), Color(0xFFFDF0E7)],
  );
}

class AppTheme {
  AppTheme._();

  static const _font = 'Baloo2';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.blue,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: Palette.blue,
        secondary: Palette.orange,
        tertiary: Palette.purple,
        surface: Palette.surface,
        onSurface: Palette.ink,
        error: Palette.red,
      ),
      scaffoldBackgroundColor: Palette.snow,
      fontFamily: _font,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _font,
        bodyColor: Palette.ink,
        displayColor: Palette.ink,
      ).copyWith(
        displayLarge: const TextStyle(
          fontFamily: _font,
          fontSize: 44,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: Palette.ink,
        ),
        headlineMedium: const TextStyle(
          fontFamily: _font,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Palette.ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: _font,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Palette.ink,
        ),
        titleMedium: const TextStyle(
          fontFamily: _font,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Palette.ink,
        ),
        bodyLarge: const TextStyle(
          fontFamily: _font,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Palette.ink,
        ),
        bodyMedium: const TextStyle(
          fontFamily: _font,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Palette.inkSoft,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Palette.ink,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 12,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Palette.ink,
        contentTextStyle: const TextStyle(
          fontFamily: _font,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
