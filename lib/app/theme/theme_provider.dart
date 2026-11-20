import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier managing application [ThemeMode] (dark, light, system).
/// Defaults to [ThemeMode.dark] reflecting PitMate's motorsport visual direction.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  /// Sets the explicit theme mode.
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  /// Toggles between dark and light theme modes.
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Global provider for application [ThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
