class WorkshopDailyMetrics {
  const WorkshopDailyMetrics({
    required this.reportDate,
    required this.activeOrdersCount,
    required this.completedTodayCount,
    required this.totalBays,
    required this.baysOccupied,
    required this.bayOccupancyRate,
    required this.settledRevenueCents,
    required this.outstandingReceivablesCents,
  });

  factory WorkshopDailyMetrics.fromJson(Map<String, dynamic> json) {
    return WorkshopDailyMetrics(
      reportDate: json['report_date'] != null
          ? DateTime.parse(json['report_date'].toString())
          : DateTime.now(),
      activeOrdersCount: (json['active_orders_count'] as num?)?.toInt() ?? 0,
      completedTodayCount: (json['completed_today_count'] as num?)?.toInt() ?? 0,
      totalBays: (json['total_bays'] as num?)?.toInt() ?? 5,
      baysOccupied: (json['bays_occupied'] as num?)?.toInt() ?? 0,
      bayOccupancyRate: (json['bay_occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      settledRevenueCents: (json['settled_revenue_cents'] as num?)?.toInt() ?? 0,
      outstandingReceivablesCents:
          (json['outstanding_receivables_cents'] as num?)?.toInt() ?? 0,
    );
  }

  final DateTime reportDate;
  final int activeOrdersCount;
  final int completedTodayCount;
  final int totalBays;
  final int baysOccupied;
  final double bayOccupancyRate;
  final int settledRevenueCents;
  final int outstandingReceivablesCents;

  double get settledRevenue => settledRevenueCents / 100.0;
  double get outstandingReceivables => outstandingReceivablesCents / 100.0;

  Map<String, dynamic> toJson() => {
        'report_date': reportDate.toIso8601String().split('T').first,
        'active_orders_count': activeOrdersCount,
        'completed_today_count': completedTodayCount,
        'total_bays': totalBays,
        'bays_occupied': baysOccupied,
        'bay_occupancy_rate': bayOccupancyRate,
        'settled_revenue_cents': settledRevenueCents,
        'outstanding_receivables_cents': outstandingReceivablesCents,
      };
}

class TopPartMetric {
  const TopPartMetric({
    required this.sku,
    required this.name,
    required this.unitsConsumed,
    required this.totalCogsCents,
  });

  factory TopPartMetric.fromJson(Map<String, dynamic> json) {
    return TopPartMetric(
      sku: json['sku'] as String? ?? 'N/A',
      name: json['name'] as String? ?? 'Unknown Part',
      unitsConsumed: (json['units_consumed'] as num?)?.toInt() ?? 0,
      totalCogsCents: (json['total_cogs_cents'] as num?)?.toInt() ?? 0,
    );
  }

  final String sku;
  final String name;
  final int unitsConsumed;
  final int totalCogsCents;

  double get totalCogs => totalCogsCents / 100.0;

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'name': name,
        'units_consumed': unitsConsumed,
        'total_cogs_cents': totalCogsCents,
      };
}

class MechanicWorkloadMetric {
  const MechanicWorkloadMetric({
    required this.mechanicId,
    required this.fullName,
    required this.completedTasksCount,
    required this.totalIncentiveCents,
  });

  factory MechanicWorkloadMetric.fromJson(Map<String, dynamic> json) {
    return MechanicWorkloadMetric(
      mechanicId: json['mechanic_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Mechanic',
      completedTasksCount: (json['completed_tasks_count'] as num?)?.toInt() ?? 0,
      totalIncentiveCents: (json['total_incentive_cents'] as num?)?.toInt() ?? 0,
    );
  }

  final String mechanicId;
  final String fullName;
  final int completedTasksCount;
  final int totalIncentiveCents;

  double get totalIncentive => totalIncentiveCents / 100.0;

  Map<String, dynamic> toJson() => {
        'mechanic_id': mechanicId,
        'full_name': fullName,
        'completed_tasks_count': completedTasksCount,
        'total_incentive_cents': totalIncentiveCents,
      };
}

class WorkshopMonthlyMetrics {
  const WorkshopMonthlyMetrics({
    required this.monthStart,
    required this.monthEnd,
    required this.totalOrdersCompleted,
    required this.grossRevenueCents,
    required this.partsCogsCents,
    required this.laborRevenueCents,
    required this.grossMarginCents,
    this.topConsumedParts = const [],
    this.mechanicWorkload = const [],
  });

  factory WorkshopMonthlyMetrics.fromJson(Map<String, dynamic> json) {
    final topPartsRaw = json['top_consumed_parts'] as List<dynamic>? ?? [];
    final workloadRaw = json['mechanic_workload'] as List<dynamic>? ?? [];

    return WorkshopMonthlyMetrics(
      monthStart: json['month_start'] != null
          ? DateTime.parse(json['month_start'].toString())
          : DateTime.now(),
      monthEnd: json['month_end'] != null
          ? DateTime.parse(json['month_end'].toString())
          : DateTime.now(),
      totalOrdersCompleted: (json['total_orders_completed'] as num?)?.toInt() ?? 0,
      grossRevenueCents: (json['gross_revenue_cents'] as num?)?.toInt() ?? 0,
      partsCogsCents: (json['parts_cogs_cents'] as num?)?.toInt() ?? 0,
      laborRevenueCents: (json['labor_revenue_cents'] as num?)?.toInt() ?? 0,
      grossMarginCents: (json['gross_margin_cents'] as num?)?.toInt() ?? 0,
      topConsumedParts: topPartsRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => TopPartMetric.fromJson(e))
          .toList(),
      mechanicWorkload: workloadRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => MechanicWorkloadMetric.fromJson(e))
          .toList(),
    );
  }

  final DateTime monthStart;
  final DateTime monthEnd;
  final int totalOrdersCompleted;
  final int grossRevenueCents;
  final int partsCogsCents;
  final int laborRevenueCents;
  final int grossMarginCents;
  final List<TopPartMetric> topConsumedParts;
  final List<MechanicWorkloadMetric> mechanicWorkload;

  double get grossRevenue => grossRevenueCents / 100.0;
  double get partsCogs => partsCogsCents / 100.0;
  double get laborRevenue => laborRevenueCents / 100.0;
  double get grossMargin => grossMarginCents / 100.0;

  double get grossMarginPercentage {
    if (grossRevenueCents <= 0) return 0.0;
    return (grossMarginCents / grossRevenueCents) * 100.0;
  }

  Map<String, dynamic> toJson() => {
        'month_start': monthStart.toIso8601String().split('T').first,
        'month_end': monthEnd.toIso8601String().split('T').first,
        'total_orders_completed': totalOrdersCompleted,
        'gross_revenue_cents': grossRevenueCents,
        'parts_cogs_cents': partsCogsCents,
        'labor_revenue_cents': laborRevenueCents,
        'gross_margin_cents': grossMarginCents,
        'top_consumed_parts': topConsumedParts.map((e) => e.toJson()).toList(),
        'mechanic_workload': mechanicWorkload.map((e) => e.toJson()).toList(),
      };
}
