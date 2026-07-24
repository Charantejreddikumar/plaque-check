import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FBFF),
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: const Color(0xFF3B82F6),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
        fontFamily: 'Inter',
      ),
      dividerTheme: const DividerThemeData(color: Color(0x4D0EA5E9)),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFF8FBFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x660EA5E9)),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0x660EA5E9)),
        labelStyle: const TextStyle(color: Color(0xFF0F172A)),
        backgroundColor: Colors.white.withValues(alpha: 0.72),
      ),
      inputDecorationTheme: _inputDecorationTheme(false),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xFF60A5FA),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xFFF8FAFC),
        displayColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
      ),
      dividerTheme: const DividerThemeData(color: Color(0x4DFFFFFF)),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x59FFFFFF)),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0x59FFFFFF)),
        labelStyle: const TextStyle(color: Color(0xFFF8FAFC)),
        backgroundColor: Colors.white.withValues(alpha: 0.10),
      ),
      inputDecorationTheme: _inputDecorationTheme(true),
      useMaterial3: true,
    );
  }

  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.34)
        : const Color(0xFF0EA5E9).withValues(alpha: 0.46);
    final focusedColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF0EA5E9);

    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: isDark ? 0.10 : 0.72),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor, width: 1.15),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: focusedColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.4),
      ),
    );
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static BoxDecoration pageDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark(context)
            ? const [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0EA5E9)]
            : const [Color(0xFFF8FBFF), Color(0xFFEEF7FF), Color(0xFFE0F2FE)],
      ),
    );
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  }

  static Color accent(BuildContext context) {
    return isDark(context) ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);
  }

  static Color accentSoft(BuildContext context) {
    return isDark(context) ? const Color(0xFF60A5FA) : const Color(0xFF38BDF8);
  }

  static Color glassBorder(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.30)
        : const Color(0xFF0EA5E9).withValues(alpha: 0.34);
  }

  static Color reportGradientStart(BuildContext context) {
    return isDark(context) ? const Color(0xFF2563EB) : const Color(0xFF60A5FA);
  }

  static Color reportGradientEnd(BuildContext context) {
    return isDark(context) ? const Color(0xFF0EA5E9) : const Color(0xFF3B82F6);
  }
}
