import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/report_telemetry.dart';

void main() {
  group('Phase 6 — Report Telemetry Models & Aggregation Contracts', () {
    test('IntakeBreakdown calculates percentages and keeps legacy_unknown isolated', () {
      const breakdown = IntakeBreakdown(
        totalOrders: 100,
        bookingCount: 50,
        walkInCount: 30,
        legacyUnknownCount: 20,
      );

      expect(breakdown.bookingPercentage, equals(50.0));
      expect(breakdown.walkInPercentage, equals(30.0));
      expect(breakdown.legacyUnknownPercentage, equals(20.0));

      // Explicit invariant: walk-ins do not include legacy_unknown
      expect(breakdown.walkInCount, equals(30));
      expect(breakdown.legacyUnknownCount, equals(20));
      expect(breakdown.bookingCount + breakdown.walkInCount + breakdown.legacyUnknownCount,
          equals(breakdown.totalOrders));
    });

    test('IntakeBreakdown handles zero total orders gracefully without division by zero', () {
      const breakdown = IntakeBreakdown(
        totalOrders: 0,
        bookingCount: 0,
        walkInCount: 0,
        legacyUnknownCount: 0,
      );

      expect(breakdown.bookingPercentage, equals(0.0));
      expect(breakdown.walkInPercentage, equals(0.0));
      expect(breakdown.legacyUnknownPercentage, equals(0.0));
    });

    test('FinancialSummary distinguishes settled realized revenue from pipeline estimates', () {
      const finance = FinancialSummary(
        estimatedTotal: 50000000.0,
        settledTotal: 32000000.0,
        settledOrdersCount: 15,
        pendingSettlementCount: 8,
      );

      expect(finance.estimatedTotal, equals(50000000.0));
      expect(finance.settledTotal, equals(32000000.0));
      expect(finance.settledOrdersCount, equals(15));
      expect(finance.pendingSettlementCount, equals(8));
      // Invariant: settled revenue is not estimated
      expect(finance.settledTotal, isNot(equals(finance.estimatedTotal)));
    });

    test('ReportTelemetryData serialization and deserialization preserves all metric fields', () {
      final sampleJson = {
        'date_range': {
          'start_date': '2026-10-01T00:00:00.000Z',
          'end_date': '2026-10-31T23:59:59.000Z',
        },
        'intake_breakdown': {
          'total_orders': 40,
          'booking_count': 25,
          'walk_in_count': 12,
          'legacy_unknown_count': 3,
        },
        'financial_summary': {
          'estimated_total': 85000000.0,
          'settled_total': 62000000.0,
          'settled_orders_count': 28,
          'pending_settlement_count': 12,
        },
        'status_distribution': [
          {'status': 'completed', 'count': 28},
          {'status': 'in_progress', 'count': 8},
          {'status': 'blocked', 'count': 4},
        ],
        'volume_timeline': [
          {'date': '2026-10-15', 'total_count': 10, 'completed_count': 7},
          {'date': '2026-10-16', 'total_count': 15, 'completed_count': 12},
        ],
        'mechanic_workload': [
          {
            'mechanic_id': 'm1',
            'mechanic_name': 'Alex Pratama',
            'employee_code': 'TECH-01',
            'specialization': 'Powertrain',
            'assigned_count': 20,
            'active_count': 5,
            'completed_count': 15,
          }
        ],
      };

      final telemetry = ReportTelemetryData.fromJson(sampleJson);

      expect(telemetry.startDate.year, equals(2026));
      expect(telemetry.intakeBreakdown.totalOrders, equals(40));
      expect(telemetry.intakeBreakdown.bookingCount, equals(25));
      expect(telemetry.intakeBreakdown.walkInCount, equals(12));
      expect(telemetry.intakeBreakdown.legacyUnknownCount, equals(3));
      expect(telemetry.financialSummary.settledTotal, equals(62000000.0));
      expect(telemetry.financialSummary.settledOrdersCount, equals(28));
      expect(telemetry.financialSummary.pendingSettlementCount, equals(12));
      expect(telemetry.statusDistribution.length, equals(3));
      expect(telemetry.volumeTimeline.length, equals(2));
      expect(telemetry.mechanicWorkload.first.mechanicName, equals('Alex Pratama'));
      expect(telemetry.mechanicWorkload.first.assignedCount, equals(20));

      // Check round-trip serialization
      final encoded = telemetry.toJson();
      expect(encoded['intake_breakdown']['walk_in_count'], equals(12));
      expect(encoded['intake_breakdown']['legacy_unknown_count'], equals(3));
    });
  });
}
