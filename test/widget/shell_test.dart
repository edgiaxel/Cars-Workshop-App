import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/shared/layouts/admin_shell.dart';
import 'package:pitmate/shared/layouts/customer_shell.dart';
import 'package:pitmate/shared/layouts/mechanic_shell.dart';
import 'package:pitmate/shared/layouts/responsive_scaffold.dart';
import 'package:pitmate/shared/models/user_profile.dart';
import 'package:pitmate/shared/models/user_role.dart';

void main() {
  const sampleItems = [
    NavigationItem(label: 'Home', icon: Icons.home, route: '/home'),
    NavigationItem(label: 'Bays', icon: Icons.build, route: '/bays'),
    NavigationItem(label: 'Fleet', icon: Icons.directions_car, route: '/fleet'),
    NavigationItem(label: 'Reports', icon: Icons.bar_chart, route: '/reports'),
    NavigationItem(label: 'Config', icon: Icons.settings, route: '/config'),
    NavigationItem(label: 'Extra', icon: Icons.more_horiz, route: '/extra'),
  ];

  const adminProfile = UserProfile(
    id: 'usr-admin-1',
    role: UserRole.admin,
    fullName: 'Lead Supervisor Marcus',
    email: 'marcus@pitmate.dev',
  );

  Widget createShellWidget({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('ResponsiveScaffold Layout Breakpoint Tests', () {
    testWidgets('Desktop layout (width >= 1024) renders sidebar, branding, and theme footer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? navigatedRoute;

      await tester.pumpWidget(
        createShellWidget(
          child: ResponsiveScaffold(
            title: 'Diagnostic Center',
            navigationItems: sampleItems,
            currentPath: '/home',
            userProfile: adminProfile,
            onNavigate: (route) => navigatedRoute = route,
            body: const Text('Desktop Content Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Desktop workshop branding
      expect(find.text('PitMate'), findsOneWidget);
      expect(find.text('Automotive Workshop OS'), findsOneWidget);

      // User profile header
      expect(find.text('Lead Supervisor Marcus'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Navigation items visible in sidebar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Bays'), findsOneWidget);
      expect(find.text('Fleet'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Config'), findsOneWidget);
      expect(find.text('Extra'), findsOneWidget);

      // Body rendered
      expect(find.text('Desktop Content Body'), findsOneWidget);

      // Navigation tap
      await tester.tap(find.text('Bays'));
      expect(navigatedRoute, equals('/bays'));

      // Theme toggle footer button exists
      expect(find.byTooltip('Toggle Theme Mode'), findsOneWidget);
    });

    testWidgets('Tablet layout (600 <= width < 1024) renders NavigationRail without full sidebar', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? navigatedRoute;

      await tester.pumpWidget(
        createShellWidget(
          child: ResponsiveScaffold(
            title: 'Tablet Viewport',
            navigationItems: sampleItems,
            currentPath: '/fleet',
            onNavigate: (route) => navigatedRoute = route,
            body: const Text('Tablet Content Area'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // NavigationRail is present on tablet
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('PitMate Automotive Workshop OS'), findsNothing);

      // Tapping rail destination calls onNavigate
      await tester.tap(find.byIcon(Icons.build));
      expect(navigatedRoute, equals('/bays'));
    });

    testWidgets('Mobile layout (width < 600) renders AppBar and NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? navigatedRoute;

      await tester.pumpWidget(
        createShellWidget(
          child: ResponsiveScaffold(
            title: 'Mobile Viewport',
            navigationItems: sampleItems,
            currentPath: '/home',
            onNavigate: (route) => navigatedRoute = route,
            body: const Text('Mobile Content Area'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile AppBar and NavigationBar present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Mobile Viewport'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Mobile limits navigation bar to 5 items when > 5 provided
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, equals(5));

      // Sidebar and NavigationRail are not present on mobile
      expect(find.byType(NavigationRail), findsNothing);

      // Navigation tap
      await tester.tap(find.text('Bays'));
      expect(navigatedRoute, equals('/bays'));
    });
  });

  group('Role Shell Scaffolds Tests', () {
    testWidgets('AdminShell renders all 8 admin destinations on desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? targetRoute;

      await tester.pumpWidget(
        createShellWidget(
          child: AdminShell(
            currentPath: '/admin',
            userProfile: adminProfile,
            onNavigate: (route) => targetRoute = route,
            body: const Text('Admin Main View'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Workshop Floor'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Vehicles'), findsOneWidget);
      expect(find.text('Mechanics'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Inventory'));
      expect(targetRoute, equals('/admin/inventory'));
    });

    testWidgets('AdminShell on mobile width restricts to 5 primary tabs', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const AdminShell(
            currentPath: '/admin',
            body: Text('Admin Mobile Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, equals(5));

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Workshop'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('MechanicShell renders technician destinations', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? targetRoute;

      await tester.pumpWidget(
        createShellWidget(
          child: MechanicShell(
            currentPath: '/mechanic',
            userProfile: const UserProfile(
              id: 'mech-1',
              role: UserRole.mechanic,
              fullName: 'Tech Lewis',
            ),
            onNavigate: (route) => targetRoute = route,
            body: const Text('Mechanic Bay View'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Work'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Inspections'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Tech Lewis'), findsOneWidget);
      expect(find.text('Mechanic'), findsOneWidget);

      await tester.tap(find.text('Tasks'));
      expect(targetRoute, equals('/mechanic/tasks'));
    });

    testWidgets('CustomerShell renders customer portal destinations', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? targetRoute;

      await tester.pumpWidget(
        createShellWidget(
          child: CustomerShell(
            currentPath: '/customer',
            userProfile: const UserProfile(
              id: 'cust-1',
              role: UserRole.customer,
              fullName: 'Max Verstappen',
            ),
            onNavigate: (route) => targetRoute = route,
            body: const Text('Customer Garage View'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Garage'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Max Verstappen'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);

      await tester.tap(find.text('Garage'));
      expect(targetRoute, equals('/customer/garage'));
    });
  });

  group('Subpath Navigation Selection & Tablet Overflow Hardening', () {
    testWidgets('AdminShell subpath /admin/customers/create selects Customers navigation item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const AdminShell(
            currentPath: '/admin/customers/create',
            body: Text('Create Customer Page'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Customers icon is selected (Icons.people), Overview is not (Icons.dashboard_outlined)
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsNothing);
    });

    testWidgets('MechanicShell subpath /mechanic/tasks/42 selects Tasks navigation item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const MechanicShell(
            currentPath: '/mechanic/tasks/42',
            body: Text('Task Detail Page'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tasks icon is selected (Icons.assignment), My Work is not (Icons.home_repair_service_outlined)
      expect(find.byIcon(Icons.assignment), findsOneWidget);
      expect(find.byIcon(Icons.home_repair_service_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home_repair_service), findsNothing);
    });

    testWidgets('CustomerShell subpath /customer/garage/car-1 selects Garage navigation item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const CustomerShell(
            currentPath: '/customer/garage/car-1',
            body: Text('Car Detail Page'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Garage icon is selected (Icons.garage), Home is not (Icons.home_outlined)
      expect(find.byIcon(Icons.garage), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('Tablet NavigationRail selects correct destination on subpath navigation', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const AdminShell(
            currentPath: '/admin/customers/create',
            body: Text('Admin Tablet Customers Subpath'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      // In AdminShell, index 2 is Customers ('/admin/customers')
      expect(rail.selectedIndex, equals(2));
    });

    testWidgets('Mobile NavigationBar selects correct destination on subpath navigation', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const AdminShell(
            currentPath: '/admin/customers/create',
            body: Text('Admin Mobile Customers Subpath'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      // In adminMobileItems, index 2 is Customers ('/admin/customers')
      expect(navBar.selectedIndex, equals(2));
    });

    testWidgets('NavigationRail on short tablet viewport height (800x350) renders without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: ResponsiveScaffold(
            title: 'Diagnostic Center',
            navigationItems: sampleItems.sublist(0, 3),
            currentPath: '/home',
            body: const Text('Short Viewport Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byTooltip('Toggle Theme'), findsOneWidget);
    });

    testWidgets('MechanicShell on short tablet viewport height (800x350) renders without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createShellWidget(
          child: const MechanicShell(
            currentPath: '/mechanic',
            body: Text('Mechanic Short Viewport'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byTooltip('Toggle Theme'), findsOneWidget);
    });
  });
}
