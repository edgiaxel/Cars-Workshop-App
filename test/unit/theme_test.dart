import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/theme_provider.dart';

void main() {
  group('ThemeModeNotifier Tests', () {
    test('defaults to ThemeMode.dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, equals(ThemeMode.dark));
    });

    test('setThemeMode updates state explicitly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('toggleTheme toggles between dark and light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('toggleTheme switches system or light to dark or vice-versa', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });
  });
}
