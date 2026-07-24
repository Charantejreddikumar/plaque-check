import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._themeMode);

  static const _preferenceKey = 'theme_mode';

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_preferenceKey);
    return ThemeProvider(_themeModeFromString(value));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, mode.name);
  }

  static ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }
}

class ThemeProviderScope extends InheritedNotifier<ThemeProvider> {
  const ThemeProviderScope({
    super.key,
    required ThemeProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static ThemeProvider of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(scope != null, 'ThemeProviderScope not found in widget tree.');
    return scope!.notifier!;
  }
}
