import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/core/errors/app_exception.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/inspection_finding_model.dart';
import '../models/inspection_model.dart';
import '../models/service_order_telemetry.dart';

/// Abstract contract for inspection data operations.
abstract class IInspectionRepository {
  Future<Result<InspectionModel?>> fetchInspectionByOrderId(String orderId);
  Future<Result<InspectionModel?>> fetchInspectionById(String inspectionId);
  Future<Result<List<InspectionFinding>>> fetchInspectionFindings(String inspectionId);
  Future<Result<InspectionFinding>> saveFinding(InspectionFinding finding);
  Future<Result<void>> deleteFinding(String findingId);
  Future<Result<InspectionModel>> submitInspection(
    String inspectionId,
    String summary, {
    String? mechanicId,
  });
  Future<Result<InspectionModel>> createOrGetInspection(
    String serviceOrderId, {
    String? mechanicId,
  });
  Future<Result<ServiceOrderTelemetry?>> fetchOrderTelemetry(String orderId);
}

/// Supabase implementation of [IInspectionRepository].
class InspectionRepository implements IInspectionRepository {
  final sb.SupabaseClient? _clientOverride;

  InspectionRepository([this._clientOverride]);

  sb.SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<InspectionModel?>> fetchInspectionByOrderId(String orderId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('inspections')
          .select()
          .eq('service_order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) {
        return const Result.success(null);
      }
      return Result.success(InspectionModel.fromJson(res));
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error while fetching inspection: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch inspection for order $orderId: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<InspectionModel?>> fetchInspectionById(String inspectionId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('inspections')
          .select()
          .eq('id', inspectionId)
          .maybeSingle();

      if (res == null) {
        return const Result.success(null);
      }
      return Result.success(InspectionModel.fromJson(res));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch inspection $inspectionId: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<List<InspectionFinding>>> fetchInspectionFindings(String inspectionId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('inspection_findings')
          .select()
          .eq('inspection_id', inspectionId)
          .order('created_at', ascending: true);

      final findings = (res as List)
          .map((item) => InspectionFinding.fromJson(item as Map<String, dynamic>))
          .toList();
      return Result.success(findings);
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch inspection findings: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<InspectionFinding>> saveFinding(InspectionFinding finding) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final data = finding.toJson();
      if (finding.id.isEmpty) {
        data.remove('id');
      }

      final res = await client
          .from('inspection_findings')
          .upsert(data)
          .select()
          .single();

      return Result.success(InspectionFinding.fromJson(res));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to save inspection finding: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<void>> deleteFinding(String findingId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      await client
          .from('inspection_findings')
          .delete()
          .eq('id', findingId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to delete finding $findingId: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<InspectionModel>> submitInspection(
    String inspectionId,
    String summary, {
    String? mechanicId,
  }) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client.rpc(
        'submit_inspection',
        params: {
          'p_inspection_id': inspectionId,
          'p_summary': summary,
          if (mechanicId != null && mechanicId.isNotEmpty) 'p_mechanic_id': mechanicId,
        },
      );

      final map = res is Map<String, dynamic>
          ? res
          : (res is List && res.isNotEmpty ? res.first as Map<String, dynamic> : <String, dynamic>{});
      return Result.success(InspectionModel.fromJson(map));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to submit inspection: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<InspectionModel>> createOrGetInspection(
    String serviceOrderId, {
    String? mechanicId,
  }) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      // 1. Check if existing inspection exists
      final existing = await fetchInspectionByOrderId(serviceOrderId);
      if (existing.isSuccess && existing.dataOrNull != null) {
        return Result.success(existing.dataOrNull!);
      }

      // 2. Create new inspection session
      final now = DateTime.now();
      final insertData = <String, dynamic>{
        'service_order_id': serviceOrderId,
        'mechanic_id': ?mechanicId,
        'status': 'in_progress',
        'started_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final res = await client
          .from('inspections')
          .insert(insertData)
          .select()
          .single();

      return Result.success(InspectionModel.fromJson(res));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to create or get inspection session: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<ServiceOrderTelemetry?>> fetchOrderTelemetry(String orderId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('service_orders')
          .select('*, vehicles(*), customers(*)')
          .eq('id', orderId)
          .maybeSingle();

      if (res == null) {
        return const Result.success(null);
      }

      return Result.success(ServiceOrderTelemetry.fromJson(res));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch service order telemetry: $e', originalException: e),
      );
    }
  }
}

/// Global provider for [IInspectionRepository].
final inspectionRepositoryProvider = Provider<IInspectionRepository>((ref) {
  return InspectionRepository();
});
