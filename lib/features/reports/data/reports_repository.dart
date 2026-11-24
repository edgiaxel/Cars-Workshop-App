import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/reports/models/workshop_metrics_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

class ReportsRepository {
  ReportsRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  /// Fetches daily workshop analytics via RPC `get_workshop_daily_metrics`
  Future<WorkshopDailyMetrics> fetchDailyMetrics([DateTime? date]) async {
    final reportDate = date ?? DateTime.now();
    final formattedDate =
        '${reportDate.year.toString().padLeft(4, '0')}-${reportDate.month.toString().padLeft(2, '0')}-${reportDate.day.toString().padLeft(2, '0')}';

    final response = await _supabase.rpc(
      'get_workshop_daily_metrics',
      params: {'report_date': formattedDate},
    );

    if (response is Map<String, dynamic>) {
      return WorkshopDailyMetrics.fromJson(response);
    }
    return WorkshopDailyMetrics.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Fetches monthly workshop financial & operational metrics via RPC `get_workshop_monthly_metrics`
  Future<WorkshopMonthlyMetrics> fetchMonthlyMetrics([DateTime? month]) async {
    final targetMonth = month ?? DateTime.now();
    final formattedMonth =
        '${targetMonth.year.toString().padLeft(4, '0')}-${targetMonth.month.toString().padLeft(2, '0')}-01';

    final response = await _supabase.rpc(
      'get_workshop_monthly_metrics',
      params: {'report_month': formattedMonth},
    );

    if (response is Map<String, dynamic>) {
      return WorkshopMonthlyMetrics.fromJson(response);
    }
    return WorkshopMonthlyMetrics.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
