import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';

import 'models/e2e_user_profile.dart';
import 'models/e2e_customer.dart';
import 'models/e2e_vehicle.dart';
import 'repositories/fake_auth_repository.dart';
import 'repositories/fake_customer_repository.dart';
import 'repositories/fake_vehicle_repository.dart';
import 'app_builder.dart';

/// Test screen size presets for responsive testing.
class ScreenSizes {
  const ScreenSizes._();

  static const Size desktop = Size(1280, 800);
  static const Size tablet = Size(800, 1024);
  static const Size mobile = Size(390, 844);
}

/// Primary E2E Test Harness coordinator.
class E2ETestHarness {
  final FakeAuthRepository authRepo;
  final FakeCustomerRepository customerRepo;
  final FakeVehicleRepository vehicleRepo;

  E2ETestHarness({
    FakeAuthRepository? authRepo,
    FakeCustomerRepository? customerRepo,
    FakeVehicleRepository? vehicleRepo,
    UserProfile? initialUser,
    List<Customer>? initialCustomers,
    List<Vehicle>? initialVehicles,
  })  : authRepo = authRepo ?? FakeAuthRepository(initialUser: initialUser),
        customerRepo =
            customerRepo ?? FakeCustomerRepository(initialCustomers: initialCustomers),
        vehicleRepo =
            vehicleRepo ?? FakeVehicleRepository(initialVehicles: initialVehicles);

  static void ensureInitialized() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  /// Pumps the test application with full GoRouter, Riverpod ProviderScope, and responsive viewport.
  Future<void> pumpApp(
    WidgetTester tester, {
    Size screenSize = ScreenSizes.desktop,
    UserProfile? initialUser,
    ThemeMode initialTheme = ThemeMode.dark,
    String initialRoute = RoutePaths.login,
  }) async {
    ensureInitialized();
    // Set viewport dimensions
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (initialUser != null) {
      authRepo.setCurrentUser(initialUser);
    }

    final builder = TestAppBuilder(
      authRepo: authRepo,
      customerRepo: customerRepo,
      vehicleRepo: vehicleRepo,
      initialThemeMode: initialTheme,
      initialRoute: initialRoute,
    );

    await tester.pumpWidget(builder.build());
    await tester.pumpAndSettle();
  }

  /// Changes the viewport size and pumps a frame.
  Future<void> setScreenSize(WidgetTester tester, Size newSize) async {
    tester.view.physicalSize = newSize;
    await tester.pumpAndSettle();
  }

  /// Enters text into a field identified by Key.
  Future<void> enterText(WidgetTester tester, Key key, String text) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Field with key "$key" not found.');
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Programmatically navigates to a route using active GoRouter.
  Future<void> goTo(WidgetTester tester, String location) async {
    final element = tester.element(find.byType(Scaffold).first);
    GoRouter.of(element).go(location);
    await tester.pumpAndSettle();
  }

  /// Taps a button or widget identified by Key or Finder.
  Future<void> tap(WidgetTester tester, dynamic target) async {
    final Finder finder;
    if (target is Finder) {
      finder = target;
    } else if (target is Key) {
      finder = find.byKey(target);
    } else {
      throw ArgumentError('target must be a Key or Finder.');
    }
    expect(finder, findsOneWidget, reason: 'Target "$target" not found.');
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}
