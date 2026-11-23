import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/mechanic/data/models/mechanic_compensation_model.dart';

void main() {
  group('MechanicCompensationProfile Model Tests', () {
    test('Deserializes compensation profile JSON properly with standard database columns', () {
      final json = {
        'mechanic_id': 'mech-1',
        'monthly_base_salary_cents': 850000000,
        'standard_incentive_percent': '15.00',
        'updated_at': '2026-11-23T08:30:00Z',
        'profiles': {
          'full_name': 'Max Verstappen',
        },
      };

      final profile = MechanicCompensationProfile.fromJson(json);

      expect(profile.mechanicId, equals('mech-1'));
      expect(profile.baseSalaryCents, equals(850000000));
      expect(profile.incentivePercentage, equals(15.0));
      expect(profile.defaultLeadSharePercentage, equals(70.0));
      expect(profile.mechanicName, equals('Max Verstappen'));
    });
  });

  group('MechanicEarningAllocation Model Tests', () {
    test('Deserializes earning allocation with joined task and order info', () {
      final json = {
        'id': 'alloc-1',
        'earning_id': 'earn-1',
        'mechanic_id': 'mech-1',
        'allocated_cents': 210000,
        'share_percentage': 70.0,
        'role_in_task': 'lead',
        'created_at': '2026-11-23T09:00:00Z',
        'mechanic_earnings': {
          'service_order_tasks': {
            'title': 'Brake Rotor & Pad Replacement',
          },
          'service_orders': {
            'order_number': 'SO-2026-0001',
          },
        },
      };

      final alloc = MechanicEarningAllocation.fromJson(json);

      expect(alloc.id, equals('alloc-1'));
      expect(alloc.allocatedCents, equals(210000));
      expect(alloc.sharePercentage, equals(70.0));
      expect(alloc.roleInTask, equals('lead'));
      expect(alloc.isLead, isTrue);
      expect(alloc.taskTitle, equals('Brake Rotor & Pad Replacement'));
      expect(alloc.orderNumber, equals('SO-2026-0001'));
    });
  });

  group('MechanicPayrollAdjustment Model Tests', () {
    test('Identifies bonus and deduction adjustment types correctly', () {
      final bonus = MechanicPayrollAdjustment(
        id: 'adj-1',
        mechanicId: 'mech-1',
        amountCents: 500000,
        adjustmentType: 'bonus',
        reason: 'Monthly performance KPI exceeded',
        createdAt: DateTime.now(),
      );

      final deduction = MechanicPayrollAdjustment(
        id: 'adj-2',
        mechanicId: 'mech-1',
        amountCents: 150000,
        adjustmentType: 'deduction',
        reason: 'Pneumatic wrench calibration fee',
        createdAt: DateTime.now(),
      );

      expect(bonus.isBonus, isTrue);
      expect(bonus.isDeduction, isFalse);

      expect(deduction.isBonus, isFalse);
      expect(deduction.isDeduction, isTrue);
    });
  });
}
