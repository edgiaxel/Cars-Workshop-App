import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_telemetry.dart';

/// Contract for reporting telemetry remote data access against Supabase.
abstract class ReportRemoteDataSource {
  Future<ReportTelemetryData> getTelemetry({
    required DateTime startDate,
    required DateTime endDate,
  });
}

class SupabaseReportRemoteDataSource implements ReportRemoteDataSource {
  final SupabaseClient _client;

  SupabaseReportRemoteDataSource(this._client);

  @override
  Future<ReportTelemetryData> getTelemetry({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startIso = startDate.toIso8601String();
    final endIso = endDate.toIso8601String();

    try {
      // 1. Primary path: Server-side secured aggregate RPC
      final response = await _client.rpc(
        'get_admin_reports_telemetry',
        params: {
          'p_start_date': startIso,
          'p_end_date': endIso,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return ReportTelemetryData.fromJson(response);
      }
    } catch (_) {
      // Fall through to client-side RLS aggregation fallback if RPC fails or is unmigrated
    }

    // 2. Fallback path: Direct RLS-backed aggregate calculation
    return _fetchFallbackTelemetry(startDate, endDate);
  }

  Future<ReportTelemetryData> _fetchFallbackTelemetry(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startIso = startDate.toIso8601String();
    final endIso = endDate.toIso8601String();

    // Query service orders in date range
    final ordersResponse = await _client
        .from('service_orders')
        .select()
        .gte('created_at', startIso)
        .lte('created_at', endIso)
        .order('created_at', ascending: true);

    final orders = (ordersResponse as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    int totalOrders = orders.length;
    int bookingCount = 0;
    int walkInCount = 0;
    int legacyCount = 0;

    double estimatedTotal = 0.0;
    double settledTotal = 0.0;
    int settledCount = 0;
    int pendingSettlementCount = 0;

    final Map<String, int> statusCounts = {};
    final Map<String, Map<String, int>> dailyCounts = {};

    for (final order in orders) {
      final origin = order['intake_origin']?.toString() ?? 'legacy_unknown';
      if (origin == 'booking') {
        bookingCount++;
      } else if (origin == 'walk_in') {
        walkInCount++;
      } else {
        // Explicitly isolate legacy_unknown
        legacyCount++;
      }

      final est = (order['estimated_total'] as num?)?.toDouble() ?? 0.0;
      final fin = (order['final_total'] as num?)?.toDouble();
      final status = order['status']?.toString() ?? 'pending';

      estimatedTotal += est;
      if ((status == 'completed' || status == 'closed') && fin != null) {
        settledTotal += fin;
        settledCount++;
      } else if (status != 'completed' &&
          status != 'closed' &&
          status != 'cancelled') {
        pendingSettlementCount++;
      }

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      final createdAtStr = order['created_at']?.toString();
      if (createdAtStr != null) {
        final dateKey = createdAtStr.substring(0, 10);
        final entry = dailyCounts.putIfAbsent(
          dateKey,
          () => {'total': 0, 'completed': 0},
        );
        entry['total'] = entry['total']! + 1;
        if (status == 'completed' || status == 'closed') {
          entry['completed'] = entry['completed']! + 1;
        }
      }
    }

    final statusList = statusCounts.entries
        .map((e) => StatusDistributionItem(status: e.key, count: e.value))
        .toList();

    final timelineList = dailyCounts.entries
        .map(
          (e) => VolumeTimelineItem(
            date: e.key,
            totalCount: e.value['total']!,
            completedCount: e.value['completed']!,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Fetch mechanics for workload
    List<MechanicWorkloadItem> mechanicWorkload = [];
    try {
      final mechanicsResponse =
          await _client.from('mechanics').select('*, profiles(full_name)');
      final mechanics = (mechanicsResponse as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();

      for (final m in mechanics) {
        final mechanicId = m['id']?.toString() ?? '';
        final profile = m['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name']?.toString() ?? 'Mechanic';
        final code = m['employee_code']?.toString() ?? '';
        final spec = m['specialization']?.toString() ?? 'General';

        // Count assignments
        final assigned = orders.where((o) => o['mechanic_id'] == mechanicId);
        final assignedCount = assigned.length;
        final activeCount = assigned.where((o) {
          final s = o['status']?.toString();
          return s != 'completed' && s != 'closed' && s != 'cancelled';
        }).length;
        final completedOrderCount = assigned.where((o) {
          final s = o['status']?.toString();
          return s == 'completed' || s == 'closed';
        }).length;

        mechanicWorkload.add(
          MechanicWorkloadItem(
            mechanicId: mechanicId,
            mechanicName: name,
            employeeCode: code,
            specialization: spec,
            assignedCount: assignedCount,
            activeCount: activeCount,
            completedCount: completedOrderCount,
          ),
        );
      }
    } catch (_) {
      // Mechanics query fallback
    }

    return ReportTelemetryData(
      startDate: startDate,
      endDate: endDate,
      intakeBreakdown: IntakeBreakdown(
        totalOrders: totalOrders,
        bookingCount: bookingCount,
        walkInCount: walkInCount,
        legacyUnknownCount: legacyCount,
      ),
      financialSummary: FinancialSummary(
        estimatedTotal: estimatedTotal,
        settledTotal: settledTotal,
        settledOrdersCount: settledCount,
        pendingSettlementCount: pendingSettlementCount,
      ),
      statusDistribution: statusList,
      volumeTimeline: timelineList,
      mechanicWorkload: mechanicWorkload,
    );
  }
}
