import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Notifier managing reactive application theme mode with profile persistence.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Watch profile's themeMode preference if authenticated
    final authState = ref.watch(authSessionProvider);
    final profile = authState.profile;
    final themePref = profile?.themeMode.toLowerCase();

    if (themePref == 'light') {
      return ThemeMode.light;
    } else if (themePref == 'system') {
      return ThemeMode.system;
    }
    // Default to dark theme across all roles
    return ThemeMode.dark;
  }

  /// Toggle between dark and light modes.
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;

    final modeString = newMode == ThemeMode.light ? 'light' : 'dark';
    await ref.read(authSessionProvider.notifier).updateThemeMode(modeString);
  }

  /// Explicitly set theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final String modeString = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await ref.read(authSessionProvider.notifier).updateThemeMode(modeString);
  }
}

/// Global provider exposing the active [ThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
