import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/inspections/data/models/inspection_finding_model.dart';

void main() {
  group('FindingCondition enum', () {
    test('fromString parses known conditions', () {
      expect(FindingCondition.fromString('good'), FindingCondition.good);
      expect(FindingCondition.fromString('fair'), FindingCondition.fair);
      expect(FindingCondition.fromString('critical'), FindingCondition.critical);
      expect(FindingCondition.fromString('unknown'), FindingCondition.good);
      expect(FindingCondition.fromString(null), FindingCondition.good);
    });

    test('value and displayName return formatted strings', () {
      expect(FindingCondition.good.value, 'good');
      expect(FindingCondition.good.displayName, 'Good');
      expect(FindingCondition.good.isGood, isTrue);

      expect(FindingCondition.fair.value, 'fair');
      expect(FindingCondition.fair.displayName, 'Fair');
      expect(FindingCondition.fair.isFair, isTrue);

      expect(FindingCondition.critical.value, 'critical');
      expect(FindingCondition.critical.displayName, 'Critical');
      expect(FindingCondition.critical.isCritical, isTrue);
    });
  });

  group('SeverityLevel enum', () {
    test('fromString parses severity strings', () {
      expect(SeverityLevel.fromString('low'), SeverityLevel.low);
      expect(SeverityLevel.fromString('medium'), SeverityLevel.medium);
      expect(SeverityLevel.fromString('urgent'), SeverityLevel.urgent);
      expect(SeverityLevel.fromString(null), SeverityLevel.low);
    });

    test('value and displayName work as expected', () {
      expect(SeverityLevel.low.value, 'low');
      expect(SeverityLevel.low.displayName, 'Low');
      expect(SeverityLevel.low.isLow, isTrue);

      expect(SeverityLevel.medium.value, 'medium');
      expect(SeverityLevel.medium.displayName, 'Medium');
      expect(SeverityLevel.medium.isMedium, isTrue);

      expect(SeverityLevel.urgent.value, 'urgent');
      expect(SeverityLevel.urgent.displayName, 'Urgent');
      expect(SeverityLevel.urgent.isUrgent, isTrue);
    });
  });

  group('InspectionFinding model', () {
    final fixedTime = DateTime.parse('2026-11-23T10:00:00Z');

    test('fromJson parses snake_case database schema correctly', () {
      final json = {
        'id': 'find-101',
        'inspection_id': 'insp-202',
        'category': 'Brakes & Suspension',
        'item_name': 'Front Brake Pads',
        'condition': 'critical',
        'severity': 'urgent',
        'notes': 'Pad thickness 2.5mm',
        'photo_urls': ['https://example.com/p1.jpg', 'https://example.com/p2.jpg'],
        'recommended_action': 'Replace front pads',
        'created_at': fixedTime.toIso8601String(),
      };

      final finding = InspectionFinding.fromJson(json);

      expect(finding.id, 'find-101');
      expect(finding.inspectionId, 'insp-202');
      expect(finding.category, 'Brakes & Suspension');
      expect(finding.itemName, 'Front Brake Pads');
      expect(finding.condition, FindingCondition.critical);
      expect(finding.severity, SeverityLevel.urgent);
      expect(finding.notes, 'Pad thickness 2.5mm');
      expect(finding.photoUrls.length, 2);
      expect(finding.recommendedAction, 'Replace front pads');
      expect(finding.createdAt, fixedTime);
    });

    test('toJson produces valid map matching database columns', () {
      final finding = InspectionFinding(
        id: 'find-1',
        inspectionId: 'insp-1',
        category: 'Powertrain',
        itemName: 'Engine Oil',
        condition: FindingCondition.good,
        severity: SeverityLevel.low,
        notes: 'Oil clean',
        photoUrls: const ['https://img.com/1.jpg'],
        recommendedAction: 'None',
        createdAt: fixedTime,
      );

      final json = finding.toJson();

      expect(json['id'], 'find-1');
      expect(json['inspection_id'], 'insp-1');
      expect(json['category'], 'Powertrain');
      expect(json['item_name'], 'Engine Oil');
      expect(json['condition'], 'good');
      expect(json['severity'], 'low');
      expect(json['notes'], 'Oil clean');
      expect(json['photo_urls'], ['https://img.com/1.jpg']);
      expect(json['recommended_action'], 'None');
    });

    test('copyWith modifies attributes properly', () {
      final finding = InspectionFinding(
        id: 'find-1',
        inspectionId: 'insp-1',
        category: 'Powertrain',
        itemName: 'Engine Oil',
        condition: FindingCondition.good,
        severity: SeverityLevel.low,
        createdAt: fixedTime,
      );

      final updated = finding.copyWith(
        condition: FindingCondition.fair,
        severity: SeverityLevel.medium,
        notes: 'Dark color detected',
      );

      expect(updated.id, 'find-1');
      expect(updated.condition, FindingCondition.fair);
      expect(updated.severity, SeverityLevel.medium);
      expect(updated.notes, 'Dark color detected');
    });

    test('equality and hashCode compare values accurately', () {
      final finding1 = InspectionFinding(
        id: 'f1',
        inspectionId: 'i1',
        category: 'Cat',
        itemName: 'Item',
        condition: FindingCondition.good,
        severity: SeverityLevel.low,
        createdAt: fixedTime,
      );

      final finding2 = InspectionFinding(
        id: 'f1',
        inspectionId: 'i1',
        category: 'Cat',
        itemName: 'Item',
        condition: FindingCondition.good,
        severity: SeverityLevel.low,
        createdAt: fixedTime,
      );

      expect(finding1, equals(finding2));
      expect(finding1.hashCode, equals(finding2.hashCode));
    });
  });
}
