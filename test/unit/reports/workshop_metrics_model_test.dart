import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/reports/models/workshop_metrics_model.dart';

void main() {
  group('WorkshopDailyMetrics Tests', () {
    test('fromJson deserializes daily metrics properly', () {
      final json = {
        'report_date': '2026-11-24',
        'active_orders_count': 5,
        'completed_today_count': 2,
        'total_bays': 5,
        'bays_occupied': 1,
        'bay_occupancy_rate': 20.0,
        'settled_revenue_cents': 150000,
        'outstanding_receivables_cents': 25000,
      };

      final metrics = WorkshopDailyMetrics.fromJson(json);

      expect(metrics.activeOrdersCount, 5);
      expect(metrics.completedTodayCount, 2);
      expect(metrics.totalBays, 5);
      expect(metrics.baysOccupied, 1);
      expect(metrics.bayOccupancyRate, 20.0);
      expect(metrics.settledRevenueCents, 150000);
      expect(metrics.settledRevenue, 1500.0);
      expect(metrics.outstandingReceivablesCents, 25000);
      expect(metrics.outstandingReceivables, 250.0);

      final encoded = metrics.toJson();
      expect(encoded['active_orders_count'], 5);
      expect(encoded['settled_revenue_cents'], 150000);
    });
  });

  group('WorkshopMonthlyMetrics Tests', () {
    test('fromJson deserializes monthly financial and operational metrics', () {
      final json = {
        'month_start': '2026-11-01',
        'month_end': '2026-11-30',
        'total_orders_completed': 14,
        'gross_revenue_cents': 600000,
        'parts_cogs_cents': 150000,
        'labor_revenue_cents': 400000,
        'gross_margin_cents': 450000,
        'top_consumed_parts': [
          {
            'sku': 'SYN-OIL-5W30',
            'name': 'Synthetic 5W-30 Oil',
            'units_consumed': 20,
            'total_cogs_cents': 50000,
          }
        ],
        'mechanic_workload': [
          {
            'mechanic_id': 'mech-1',
            'full_name': 'Toto Wolf',
            'completed_tasks_count': 10,
            'total_incentive_cents': 80000,
          }
        ],
      };

      final metrics = WorkshopMonthlyMetrics.fromJson(json);

      expect(metrics.totalOrdersCompleted, 14);
      expect(metrics.grossRevenueCents, 600000);
      expect(metrics.grossRevenue, 6000.0);
      expect(metrics.partsCogsCents, 150000);
      expect(metrics.partsCogs, 1500.0);
      expect(metrics.laborRevenue, 4000.0);
      expect(metrics.grossMargin, 4500.0);
      expect(metrics.grossMarginPercentage, 75.0);

      expect(metrics.topConsumedParts.length, 1);
      expect(metrics.topConsumedParts.first.sku, 'SYN-OIL-5W30');
      expect(metrics.topConsumedParts.first.totalCogs, 500.0);

      expect(metrics.mechanicWorkload.length, 1);
      expect(metrics.mechanicWorkload.first.fullName, 'Toto Wolf');
      expect(metrics.mechanicWorkload.first.totalIncentive, 800.0);
    });
  });
}
