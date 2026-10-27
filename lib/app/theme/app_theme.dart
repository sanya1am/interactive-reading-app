import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const background = Color(0xFFF6F0E6);
  static const surface = Color(0xFFFCF9F3);
  static const primary = Color(0xFF456B57);
  static const primaryDark = Color(0xFF355443);
  static const ink = Color(0xFF26231F);
  static const muted = Color(0xFF777168);
  static const outline = Color(0xFFE5DDD0);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: ink,
      outline: outline,
      surfaceContainerLow: const Color(0xFFFAF6EF),
      surfaceContainerHighest: const Color(0xFFEDE6DA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      dividerColor: outline,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline),
        ),
      ),

      floatingActionButtonTheme:
      const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEDE7DC),
        selectedColor: primary,
        labelStyle: const TextStyle(color: ink),
        secondaryLabelStyle:
        const TextStyle(color: Colors.white),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      textSelectionTheme:
      const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x55456B57),
        selectionHandleColor: primary,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle:
        const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'serif',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: ink,
        ),
      ),
    );
  }
}