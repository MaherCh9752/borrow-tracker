import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Manages theme mode (light / dark / system) with local persistence.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  /// Returns true if currently in dark mode (accounting for system mode).
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Returns a user-friendly label for the current mode.
  String get currentLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Loads the saved theme preference from SharedPreferences.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(AppConstants.themePreferenceKey);
    _themeMode = _parseMode(saved);
    notifyListeners();
  }

  /// Sets the theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(AppConstants.themePreferenceKey, mode.name);
  }

  /// Cycles: system → light → dark → system.
  Future<void> cycleTheme() async {
    final next = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  ThemeMode _parseMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}
