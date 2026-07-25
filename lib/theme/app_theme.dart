import 'package:flutter/material.dart';

class AppTheme {
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5FBFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFF3BA7A4);
  static const Color lightAccentSoft = Color(0xFF69C7C3);
  static const Color lightHighlight = Color(0xFF2B7A78);
  static const Color lightTextPrimary = Color(0xFF222222);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightDivider = Color(0xFFE8ECEC);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1B1B1B);
  static const Color darkCard = Color(0xFF202124);
  static const Color darkAccent = Color(0xFF6FD4CF);
  static const Color darkAccentSoft = Color(0xFF87E0DA);
  static const Color darkHighlight = Color(0xFF4FB8B2);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFBBBBBB);
  static const Color darkDivider = Color(0xFF2E2E2E);

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        secondary: lightAccentSoft,
        tertiary: lightHighlight,
        surface: lightCard,
        error: Color(0xFFE57373),
        onPrimary: Colors.white,
        onSecondary: lightTextPrimary,
        onSurface: lightTextPrimary,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
        fontFamily: 'Inter',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: lightDivider),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightDivider),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: lightDivider),
        labelStyle: const TextStyle(color: lightTextPrimary),
        backgroundColor: lightSurface,
      ),
      cardTheme: _cardTheme(false),
      elevatedButtonTheme: _elevatedButtonTheme(false),
      outlinedButtonTheme: _outlinedButtonTheme(false),
      snackBarTheme: _snackBarTheme(false),
      inputDecorationTheme: _inputDecorationTheme(false),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        secondary: darkAccentSoft,
        tertiary: darkHighlight,
        surface: darkCard,
        error: Color(0xFFE57373),
        onPrimary: Color(0xFF102F2D),
        onSecondary: darkTextPrimary,
        onSurface: darkTextPrimary,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
        fontFamily: 'Inter',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: darkDivider),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkDivider),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: darkDivider),
        labelStyle: const TextStyle(color: darkTextPrimary),
        backgroundColor: darkSurface,
      ),
      cardTheme: _cardTheme(true),
      elevatedButtonTheme: _elevatedButtonTheme(true),
      outlinedButtonTheme: _outlinedButtonTheme(true),
      snackBarTheme: _snackBarTheme(true),
      inputDecorationTheme: _inputDecorationTheme(true),
      useMaterial3: true,
    );
  }

  static CardThemeData _cardTheme(bool isDark) {
    return CardThemeData(
      color: isDark ? darkCard : lightCard,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? darkDivider : lightDivider),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? darkAccent : lightAccent,
        foregroundColor: isDark ? const Color(0xFF102F2D) : Colors.white,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? darkAccent : lightHighlight,
        side: BorderSide(color: isDark ? darkDivider : lightDivider),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme(bool isDark) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? darkCard : lightTextPrimary,
      contentTextStyle: TextStyle(
        color: isDark ? darkTextPrimary : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    final borderColor = isDark ? darkDivider : lightDivider;
    final focusedColor = isDark ? darkAccent : lightAccent;

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkSurface : lightSurface,
      hintStyle: TextStyle(
        color: isDark ? darkTextSecondary : lightTextSecondary,
      ),
      labelStyle: TextStyle(
        color: isDark ? darkTextSecondary : lightTextSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.4),
      ),
    );
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static BoxDecoration pageDecoration(BuildContext context) {
    return BoxDecoration(
      color: isDark(context) ? darkBackground : lightBackground,
    );
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color accent(BuildContext context) {
    return isDark(context) ? darkAccent : lightAccent;
  }

  static Color accentSoft(BuildContext context) {
    return isDark(context) ? darkAccentSoft : lightAccentSoft;
  }

  static Color glassBorder(BuildContext context) {
    return isDark(context) ? darkDivider : lightDivider;
  }

  static Color cardColor(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }

  static Color secondarySurface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color highlight(BuildContext context) {
    return isDark(context) ? darkHighlight : lightHighlight;
  }

  static Color reportGradientStart(BuildContext context) {
    return isDark(context) ? darkHighlight : lightAccent;
  }

  static Color reportGradientEnd(BuildContext context) {
    return isDark(context) ? darkAccent : lightAccentSoft;
  }
}
