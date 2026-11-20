import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 4 Scenario 4: Theme Toggle & Responsive Breakpoints Real-World Workflow', () {
    testWidgets('Theme toggle persists across window resize and responsive navigation shell transitions', (tester) async {
      final harness = E2ETestHarness();

      // Step 1: Start on Desktop viewport in Dark mode
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.desktop,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      // Verify Desktop layout & Dark theme
      expect(find.byKey(const Key('desktop_sidebar')), findsOneWidget);
      expect(find.byKey(const Key('mobile_bottom_nav')), findsNothing);

      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.dark));

      // Step 2: Toggle theme to Light mode
      await harness.tap(tester, const Key('theme_toggle_button'));
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.light));

      // Step 3: Resize window to Mobile viewport (< 600dp)
      await harness.setScreenSize(tester, ScreenSizes.mobile);

      // Verify layout converted to Mobile Bottom Navigation
      expect(find.byKey(const Key('mobile_bottom_nav')), findsOneWidget);
      expect(find.byKey(const Key('desktop_sidebar')), findsNothing);

      // Verify Light theme is preserved
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.light));

      // Step 4: Toggle theme back to Dark mode on mobile
      await harness.tap(tester, const Key('theme_toggle_button'));
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.dark));

      // Step 5: Resize window to Tablet viewport (600 - 1023dp)
      await harness.setScreenSize(tester, ScreenSizes.tablet);

      // Verify layout converted to Navigation Rail
      expect(find.byKey(const Key('tablet_nav_rail')), findsOneWidget);
      expect(find.byKey(const Key('mobile_bottom_nav')), findsNothing);
      expect(find.byKey(const Key('desktop_sidebar')), findsNothing);

      // Verify Dark theme is preserved
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.dark));
    });
  });
}
