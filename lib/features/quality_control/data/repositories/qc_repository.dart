import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/core/errors/app_exception.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import '../models/qc_inspection_model.dart';

/// Abstract contract for PitMate Quality Control operations.
abstract class IQcRepository {
  /// Fetches service orders currently in `qc_pending` status awaiting inspection.
  Future<Result<List<ServiceOrderModel>>> fetchQcPendingOrders();

  /// Fetches the latest active QC inspection session for a specific service order.
  Future<Result<QcInspectionModel?>> fetchActiveInspectionForOrder(String orderId);

  /// Fetches a specific QC inspection by ID with all checklist items and joined order details.
  Future<Result<QcInspectionModel?>> fetchInspectionById(String inspectionId);

  /// Submits a service order for Quality Control via database RPC `submit_order_for_qc`.
  Future<Result<String>> submitOrderForQc({
    required String serviceOrderId,
    required String inspectorId,
  });

  /// Records final or in-progress QC results via database RPC `record_qc_result`.
  Future<Result<bool>> recordQcResult({
    required String qcInspectionId,
    required QcStatus status,
    String? notes,
    String? failureReason,
    List<QcChecklistItemModel>? items,
  });

  /// Fails QC and returns vehicle back to active repair via database RPC `return_to_repair_from_qc`.
  Future<Result<bool>> returnToRepairFromQc({
    required String qcInspectionId,
    required String correctionNotes,
  });
}

/// Supabase implementation of [IQcRepository] communicating directly with real Postgres tables and RPCs.
class QcRepository implements IQcRepository {
  final sb.SupabaseClient? _clientOverride;

  QcRepository([this._clientOverride]);

  sb.SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<List<ServiceOrderModel>>> fetchQcPendingOrders() async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('service_orders')
          .select('*, customers(full_name, phone_number), vehicles(license_plate, make, model)')
          .eq('status', 'qc_pending')
          .order('updated_at', ascending: false);

      final orders = (res as List)
          .map((row) => ServiceOrderModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(orders);
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error fetching QC pending orders: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch QC pending orders: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<QcInspectionModel?>> fetchActiveInspectionForOrder(String orderId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('qc_inspections')
          .select(
            '*, qc_checklist_items(*), service_orders(*, customers(full_name, phone_number), vehicles(license_plate, make, model))',
          )
          .eq('service_order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) {
        return const Result.success(null);
      }

      return Result.success(QcInspectionModel.fromJson(res));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch active QC inspection for order $orderId: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<QcInspectionModel?>> fetchInspectionById(String inspectionId) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client
          .from('qc_inspections')
          .select(
            '*, qc_checklist_items(*), service_orders(*, customers(full_name, phone_number), vehicles(license_plate, make, model))',
          )
          .eq('id', inspectionId)
          .maybeSingle();

      if (res == null) {
        return const Result.success(null);
      }

      return Result.success(QcInspectionModel.fromJson(res));
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch QC inspection $inspectionId: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<String>> submitOrderForQc({
    required String serviceOrderId,
    required String inspectorId,
  }) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client.rpc(
        'submit_order_for_qc',
        params: {
          'p_service_order_id': serviceOrderId,
          'p_inspector_id': inspectorId,
        },
      );

      return Result.success(res as String);
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to submit order for QC via RPC: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<bool>> recordQcResult({
    required String qcInspectionId,
    required QcStatus status,
    String? notes,
    String? failureReason,
    List<QcChecklistItemModel>? items,
  }) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final params = <String, dynamic>{
        'p_qc_inspection_id': qcInspectionId,
        'p_status': status.value,
        'p_notes': notes,
        'p_failure_reason': failureReason,
      };

      if (items != null) {
        params['p_items'] = items.map((i) => i.toRpcItemJson()).toList();
      }

      final res = await client.rpc(
        'record_qc_result',
        params: params,
      );

      return Result.success(res as bool? ?? true);
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to record QC result via RPC: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<bool>> returnToRepairFromQc({
    required String qcInspectionId,
    required String correctionNotes,
  }) async {
    final client = _client;
    if (client == null) {
      return const Result.failure(
        NetworkException('Supabase client is not initialized.'),
      );
    }

    try {
      final res = await client.rpc(
        'return_to_repair_from_qc',
        params: {
          'p_qc_inspection_id': qcInspectionId,
          'p_correction_notes': correctionNotes,
        },
      );

      return Result.success(res as bool? ?? true);
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to return order to repair via RPC: $e', originalException: e),
      );
    }
  }
}

/// Global Riverpod provider for [IQcRepository].
final qcRepositoryProvider = Provider<IQcRepository>((ref) {
  return QcRepository();
});
