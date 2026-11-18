import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/report_remote_datasource.dart';
import '../../data/models/report_telemetry.dart';
import '../../data/repositories/report_repository.dart';
import 'supabase_provider.dart';

/// Provider for [ReportRemoteDataSource].
final reportRemoteDataSourceProvider =
    Provider<ReportRemoteDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseReportRemoteDataSource(client);
});

/// Provider for [ReportRepository].
final reportRepositoryProvider = Provider<ReportRepository?>((ref) {
  final dataSource = ref.watch(reportRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseReportRepository(dataSource);
});

/// Notifier managing active date range boundaries for reports telemetry.
class ReportDateRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  void setRange(DateTimeRange range) {
    state = range;
  }
}

/// Provider for selected date range filter.
final reportDateRangeFilterProvider =
    NotifierProvider<ReportDateRangeNotifier, DateTimeRange>(
  ReportDateRangeNotifier.new,
);

/// FutureProvider that fetches report telemetry based on the active date range.
final reportTelemetryProvider = FutureProvider<ReportTelemetryData>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(reportDateRangeFilterProvider);

  if (repository == null) {
    // Return empty telemetry if unconfigured/offline
    return ReportTelemetryData(
      startDate: range.start,
      endDate: range.end,
      intakeBreakdown: const IntakeBreakdown(
        totalOrders: 0,
        bookingCount: 0,
        walkInCount: 0,
        legacyUnknownCount: 0,
      ),
      financialSummary: const FinancialSummary(
        estimatedTotal: 0.0,
        settledTotal: 0.0,
        settledOrdersCount: 0,
        pendingSettlementCount: 0,
      ),
      statusDistribution: const [],
      volumeTimeline: const [],
      mechanicWorkload: const [],
    );
  }

  return repository.getTelemetry(
    startDate: range.start,
    endDate: range.end,
  );
});
