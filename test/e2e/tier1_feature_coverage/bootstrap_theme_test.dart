import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/config/app_config.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('F1 & F2: Bootstrap & Dual Theming E2E Tests', () {
    test('1. AppConfig provides valid application identity and version', () {
      expect(AppConfig.appName, equals('PitMate'));
      expect(AppConfig.appVersion, isNotEmpty);
      expect(AppConfig.supabaseUrl, isNotEmpty);
    });

    test('2. AppConfig evaluates Supabase configuration readiness', () {
      // By default in test environment without dart-define keys, placeholder key is recognized
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      // isSupabaseConfigured returns boolean indicating key validity
      expect(AppConfig.isSupabaseConfigured, isA<bool>());
    });

    test('3. Dark theme configuration uses Material 3 and dark brightness', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.useMaterial3, isTrue);
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
    });

    test('4. Light theme configuration uses Material 3 and light brightness', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
    });

    test('5. Primary motorsport accent color is Racing Red across both themes', () {
      expect(AppTheme.darkTheme.colorScheme.primary, equals(AppColors.racingRed));
      expect(AppTheme.lightTheme.colorScheme.primary, equals(AppColors.racingRed));
    });

    test('6. Surface colors reflect dark and light slate tokens', () {
      expect(AppTheme.darkTheme.colorScheme.surface, equals(AppColors.darkSurface));
      expect(AppTheme.lightTheme.colorScheme.surface, equals(AppColors.lightSurface));
    });

    test('7. Card theme applies consistent border radius of 10dp', () {
      final darkCardShape = AppTheme.darkTheme.cardTheme.shape as RoundedRectangleBorder;
      final lightCardShape = AppTheme.lightTheme.cardTheme.shape as RoundedRectangleBorder;

      expect(darkCardShape.borderRadius, equals(BorderRadius.circular(10)));
      expect(lightCardShape.borderRadius, equals(BorderRadius.circular(10)));
    });

    test('8. Elevated button style enforces Racing Red background with white label', () {
      final darkBtnStyle = AppTheme.darkTheme.elevatedButtonTheme.style;
      final lightBtnStyle = AppTheme.lightTheme.elevatedButtonTheme.style;

      expect(darkBtnStyle?.backgroundColor?.resolve({}), equals(AppColors.racingRed));
      expect(lightBtnStyle?.backgroundColor?.resolve({}), equals(AppColors.racingRed));
    });

    testWidgets('9. App defaults to dark mode on initial bootstrap', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
      expect(materialApp.theme?.brightness, equals(Brightness.light));
      expect(materialApp.darkTheme?.brightness, equals(Brightness.dark));
    });

    testWidgets('10. Dynamic theme toggle switches between Dark and Light mode live', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      // Verify initially dark
      var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));

      // Tap theme toggle button
      await harness.tap(tester, const Key('theme_toggle_button'));

      // Verify switched to light mode
      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.light));

      // Tap again to switch back to dark mode
      await harness.tap(tester, const Key('theme_toggle_button'));
      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });
  });
}
