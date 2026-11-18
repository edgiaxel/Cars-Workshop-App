import '../datasources/report_remote_datasource.dart';
import '../models/report_telemetry.dart';

/// Repository interface for reporting and workshop telemetry.
abstract class ReportRepository {
  Future<ReportTelemetryData> getTelemetry({
    required DateTime startDate,
    required DateTime endDate,
  });
}

class SupabaseReportRepository implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  SupabaseReportRepository(this._remoteDataSource);

  @override
  Future<ReportTelemetryData> getTelemetry({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _remoteDataSource.getTelemetry(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
