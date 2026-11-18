import 'package:flutter/foundation.dart';

/// Telemetry metrics for workshop administration reporting.
@immutable
class ReportTelemetryData {
  final DateTime startDate;
  final DateTime endDate;
  final IntakeBreakdown intakeBreakdown;
  final FinancialSummary financialSummary;
  final List<StatusDistributionItem> statusDistribution;
  final List<VolumeTimelineItem> volumeTimeline;
  final List<MechanicWorkloadItem> mechanicWorkload;

  const ReportTelemetryData({
    required this.startDate,
    required this.endDate,
    required this.intakeBreakdown,
    required this.financialSummary,
    required this.statusDistribution,
    required this.volumeTimeline,
    required this.mechanicWorkload,
  });

  factory ReportTelemetryData.fromJson(Map<String, dynamic> json) {
    final range = json['date_range'] as Map<String, dynamic>? ?? {};
    final intake = json['intake_breakdown'] as Map<String, dynamic>? ?? {};
    final finance = json['financial_summary'] as Map<String, dynamic>? ?? {};
    final statusList = (json['status_distribution'] as List<dynamic>? ?? []);
    final timelineList = (json['volume_timeline'] as List<dynamic>? ?? []);
    final workloadList = (json['mechanic_workload'] as List<dynamic>? ?? []);

    return ReportTelemetryData(
      startDate: range['start_date'] != null
          ? DateTime.tryParse(range['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: range['end_date'] != null
          ? DateTime.tryParse(range['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      intakeBreakdown: IntakeBreakdown.fromJson(intake),
      financialSummary: FinancialSummary.fromJson(finance),
      statusDistribution: statusList
          .map((e) => StatusDistributionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      volumeTimeline: timelineList
          .map((e) => VolumeTimelineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      mechanicWorkload: workloadList
          .map((e) => MechanicWorkloadItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date_range': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        'intake_breakdown': intakeBreakdown.toJson(),
        'financial_summary': financialSummary.toJson(),
        'status_distribution':
            statusDistribution.map((e) => e.toJson()).toList(),
        'volume_timeline': volumeTimeline.map((e) => e.toJson()).toList(),
        'mechanic_workload': mechanicWorkload.map((e) => e.toJson()).toList(),
      };
}

/// Breakdown of vehicle intake origins.
/// Explicitly isolates legacy_unknown so it is never conflated with walk-ins.
@immutable
class IntakeBreakdown {
  final int totalOrders;
  final int bookingCount;
  final int walkInCount;
  final int legacyUnknownCount;

  const IntakeBreakdown({
    required this.totalOrders,
    required this.bookingCount,
    required this.walkInCount,
    required this.legacyUnknownCount,
  });

  double get bookingPercentage =>
      totalOrders == 0 ? 0.0 : (bookingCount / totalOrders) * 100;

  double get walkInPercentage =>
      totalOrders == 0 ? 0.0 : (walkInCount / totalOrders) * 100;

  double get legacyUnknownPercentage =>
      totalOrders == 0 ? 0.0 : (legacyUnknownCount / totalOrders) * 100;

  factory IntakeBreakdown.fromJson(Map<String, dynamic> json) {
    return IntakeBreakdown(
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      bookingCount: (json['booking_count'] as num?)?.toInt() ?? 0,
      walkInCount: (json['walk_in_count'] as num?)?.toInt() ?? 0,
      legacyUnknownCount:
          (json['legacy_unknown_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_orders': totalOrders,
        'booking_count': bookingCount,
        'walk_in_count': walkInCount,
        'legacy_unknown_count': legacyUnknownCount,
      };
}

/// Financial summary clearly distinguishing estimated pipeline from settled revenue.
@immutable
class FinancialSummary {
  final double estimatedTotal;
  final double settledTotal;
  final int settledOrdersCount;
  final int pendingSettlementCount;

  const FinancialSummary({
    required this.estimatedTotal,
    required this.settledTotal,
    required this.settledOrdersCount,
    required this.pendingSettlementCount,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble() ?? 0.0,
      settledTotal: (json['settled_total'] as num?)?.toDouble() ?? 0.0,
      settledOrdersCount:
          (json['settled_orders_count'] as num?)?.toInt() ?? 0,
      pendingSettlementCount:
          (json['pending_settlement_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'estimated_total': estimatedTotal,
        'settled_total': settledTotal,
        'settled_orders_count': settledOrdersCount,
        'pending_settlement_count': pendingSettlementCount,
      };
}

/// Count of orders per service lifecycle status.
@immutable
class StatusDistributionItem {
  final String status;
  final int count;

  const StatusDistributionItem({
    required this.status,
    required this.count,
  });

  factory StatusDistributionItem.fromJson(Map<String, dynamic> json) {
    return StatusDistributionItem(
      status: json['status']?.toString() ?? 'unknown',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'count': count,
      };
}

/// Daily timeline item for service order volume.
@immutable
class VolumeTimelineItem {
  final String date;
  final int totalCount;
  final int completedCount;

  const VolumeTimelineItem({
    required this.date,
    required this.totalCount,
    required this.completedCount,
  });

  factory VolumeTimelineItem.fromJson(Map<String, dynamic> json) {
    return VolumeTimelineItem(
      date: json['date']?.toString() ?? '',
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'total_count': totalCount,
        'completed_count': completedCount,
      };
}

/// Mechanic workload telemetry.
@immutable
class MechanicWorkloadItem {
  final String mechanicId;
  final String mechanicName;
  final String employeeCode;
  final String specialization;
  final int assignedCount;
  final int activeCount;
  final int completedCount;

  const MechanicWorkloadItem({
    required this.mechanicId,
    required this.mechanicName,
    required this.employeeCode,
    required this.specialization,
    required this.assignedCount,
    required this.activeCount,
    required this.completedCount,
  });

  factory MechanicWorkloadItem.fromJson(Map<String, dynamic> json) {
    return MechanicWorkloadItem(
      mechanicId: json['mechanic_id']?.toString() ?? '',
      mechanicName: json['mechanic_name']?.toString() ?? 'Unknown Mechanic',
      employeeCode: json['employee_code']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? 'General',
      assignedCount: (json['assigned_count'] as num?)?.toInt() ?? 0,
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mechanic_id': mechanicId,
        'mechanic_name': mechanicName,
        'employee_code': employeeCode,
        'specialization': specialization,
        'assigned_count': assignedCount,
        'active_count': activeCount,
        'completed_count': completedCount,
      };
}
