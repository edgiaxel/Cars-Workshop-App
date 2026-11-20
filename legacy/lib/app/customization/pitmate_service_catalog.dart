import 'package:flutter/material.dart';

/// Specification for controlled service offerings in PitMate.
class ServiceCategoryItem {
  const ServiceCategoryItem({
    required this.id,
    required this.name,
    required this.description,
    this.icon = Icons.build_circle_outlined,
    this.estimatedHours = 1.0,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final double estimatedHours;
}

/// PitMate Canonical Service Catalog adhering to CUSTOMIZATION.md.
///
/// Provides controlled service categories, display order, and default estimates.
abstract class PitmateServiceCatalog {
  static const List<ServiceCategoryItem> categories = [
    ServiceCategoryItem(
      id: 'routine_maintenance',
      name: 'Routine Maintenance',
      description: 'Oil, fluid changes, multi-point safety inspection and filters',
      icon: Icons.oil_barrel_outlined,
      estimatedHours: 1.5,
    ),
    ServiceCategoryItem(
      id: 'diagnostics',
      name: 'Electrical & Diagnostics',
      description: 'ECU fault code analysis, sensor calibration, wiring diagnostics',
      icon: Icons.troubleshoot_outlined,
      estimatedHours: 2.0,
    ),
    ServiceCategoryItem(
      id: 'brakes_suspension',
      name: 'Brakes & Suspension',
      description: 'Pads, rotors, caliper servicing, dampers, bushings and alignment',
      icon: Icons.disc_full_outlined,
      estimatedHours: 2.5,
    ),
    ServiceCategoryItem(
      id: 'powertrain',
      name: 'Engine & Transmission',
      description: 'Major powertrain overhaul, clutch replacement, timing belts',
      icon: Icons.engineering_outlined,
      estimatedHours: 4.0,
    ),
    ServiceCategoryItem(
      id: 'track_prep',
      name: 'Motorsport & Track Preparation',
      description: 'Geometry setup, telemetry verification, brake fluid flush',
      icon: Icons.speed,
      estimatedHours: 3.0,
    ),
  ];

  static ServiceCategoryItem findById(String id) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.first,
    );
  }
}
