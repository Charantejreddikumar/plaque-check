import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/theme/app_theme.dart';
import 'package:plaquecheck/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeProvider initializes with given theme mode', () {
      final provider = ThemeProvider(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('ThemeProvider setThemeMode updates theme state', () async {
      final provider = ThemeProvider(ThemeMode.light);
      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('AppTheme builds dark and light theme data', () {
      final darkTheme = AppTheme.dark;
      final lightTheme = AppTheme.light;

      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.brightness, Brightness.light);
    });
  });
}
