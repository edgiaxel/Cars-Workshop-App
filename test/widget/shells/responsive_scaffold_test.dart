import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';

void main() {
  const navItems = [
    RoleNavItem(label: 'Dashboard', icon: Icons.dashboard),
    RoleNavItem(label: 'Vehicles', icon: Icons.directions_car, badge: '2'),
    RoleNavItem(label: 'Settings', icon: Icons.settings),
  ];

  Widget buildTestScaffold({
    int currentIndex = 0,
    ValueChanged<int>? onNavIndexChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ResponsiveRoleScaffold(
        roleTitle: 'Workshop Dispatch',
        userName: 'Marcus T.',
        userSubtitle: 'Workshop Director',
        telemetryNotice: '4/5 BAYS ACTIVE',
        currentIndex: currentIndex,
        onNavIndexChanged: onNavIndexChanged,
        navItems: navItems,
        body: const Center(child: Text('Main Content Area')),
      ),
    );
  }

  group('ResponsiveRoleScaffold', () {
    testWidgets('renders persistent sidebar and top status bar on desktop (>= 900px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      int? selectedIndex;
      await tester.pumpWidget(
        buildTestScaffold(
          currentIndex: 0,
          onNavIndexChanged: (i) => selectedIndex = i,
        ),
      );
      await tester.pumpAndSettle();

      // Verify desktop layout elements
      expect(find.text('Main Content Area'), findsOneWidget);
      expect(find.text('Marcus T.'), findsOneWidget);
      expect(find.text('Workshop Director'), findsOneWidget);
      expect(find.text('4/5 BAYS ACTIVE'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Vehicles'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify no BottomNavigationBar on desktop
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Tap on navigation item in sidebar
      await tester.tap(find.text('Vehicles'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
    });

    testWidgets('renders top header and bottom nav bar on mobile (< 900px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      int? selectedIndex;
      await tester.pumpWidget(
        buildTestScaffold(
          currentIndex: 0,
          onNavIndexChanged: (i) => selectedIndex = i,
        ),
      );
      await tester.pumpAndSettle();

      // Verify mobile elements
      expect(find.text('Main Content Area'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('WORKSHOP DISPATCH'), findsOneWidget);

      // Tap on bottom nav bar item
      await tester.tap(find.text('Vehicles'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
    });

    testWidgets('caps bottom navigation bar items to at most 4 on mobile even when navItems has 13 items', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final thirteenItems = List.generate(
        13,
        (i) => RoleNavItem(label: 'Item $i', icon: Icons.star, path: '/item-$i'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResponsiveRoleScaffold(
            roleTitle: 'Admin',
            userName: 'Admin',
            currentIndex: 0,
            navItems: thirteenItems,
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.items.length, lessThanOrEqualTo(4));
    });

    testWidgets('renders avatar button on desktop and mobile', (tester) async {
      // Desktop
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScaffold());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('desktop_scaffold_avatar_button')), findsOneWidget);

      // Mobile
      tester.view.physicalSize = const Size(320, 600);
      await tester.pumpWidget(buildTestScaffold());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile_scaffold_avatar_button')), findsOneWidget);
    });
  });
}
