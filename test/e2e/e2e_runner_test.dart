import 'package:flutter_test/flutter_test.dart';

import 'harness/test_harness.dart';
import 'tier1_feature_coverage/bootstrap_theme_test.dart' as t1_bootstrap_theme;
import 'tier1_feature_coverage/responsive_shells_test.dart' as t1_responsive_shells;
import 'tier1_feature_coverage/auth_roles_test.dart' as t1_auth_roles;
import 'tier1_feature_coverage/customer_registry_test.dart' as t1_customer_registry;
import 'tier1_feature_coverage/vehicle_registry_garage_test.dart' as t1_vehicle_registry;

import 'tier2_boundary_corner/boundary_inputs_test.dart' as t2_boundary_inputs;

import 'tier3_cross_feature/cross_feature_combinations_test.dart' as t3_cross_feature;

import 'tier4_real_world/admin_walkin_intake_scenario_test.dart' as t4_admin_walkin;
import 'tier4_real_world/customer_registration_garage_scenario_test.dart' as t4_customer_reg;
import 'tier4_real_world/role_access_security_scenario_test.dart' as t4_role_access;
import 'tier4_real_world/theme_persistence_responsive_scenario_test.dart' as t4_theme_persist;
import 'tier4_real_world/guest_conversion_scenario_test.dart' as t4_guest_conv;

/// Master E2E Runner aggregating all Milestone M1 requirement suites across Tiers 1-4.
void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('=== PitMate Milestone M1 E2E Master Test Suite ===', () {
    group('Tier 1: Feature Coverage (F1 - F8)', () {
      t1_bootstrap_theme.main();
      t1_responsive_shells.main();
      t1_auth_roles.main();
      t1_customer_registry.main();
      t1_vehicle_registry.main();
    });

    group('Tier 2: Boundary Value Analysis & Corner Inputs', () {
      t2_boundary_inputs.main();
    });

    group('Tier 3: Cross-Feature Interactions & Invariants', () {
      t3_cross_feature.main();
    });

    group('Tier 4: End-to-End Real-World Scenarios', () {
      t4_admin_walkin.main();
      t4_customer_reg.main();
      t4_role_access.main();
      t4_theme_persist.main();
      t4_guest_conv.main();
    });
  });
}
