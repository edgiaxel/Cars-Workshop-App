import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../models/vehicle_handover_model.dart';

/// Contract for vehicle handover operations conforming to M5 architecture.
abstract class IHandoverRepository {
  /// Fetches service orders that have passed QC and are waiting for vehicle handover.
  Future<Result<List<HandoverOrderCandidate>>> fetchHandoverQueue();

  /// Fetches service orders where handover has been completed (service order closed).
  Future<Result<List<HandoverOrderCandidate>>> fetchHandoverHistory();

  /// Fetches the vehicle handover record associated with a given service order ID.
  Future<Result<VehicleHandoverModel?>> fetchHandoverByOrderId(String orderId);

  /// Executes `public.record_vehicle_handover` RPC to record vehicle handover,
  /// verify checklist items, validate payment settlement or authorized override,
  /// and transition service order status to 'closed'.
  Future<Result<VehicleHandoverModel>> recordVehicleHandover({
    required String serviceOrderId,
    required String adminId,
    required HandoverChecklist checklist,
    bool customerConfirmed = true,
    String? notes,
    String? paymentOverrideReason,
  });
}

/// Supabase implementation of [IHandoverRepository] hitting real tables and RPCs.
class HandoverRepository implements IHandoverRepository {
  HandoverRepository([this._clientOverride]);

  final sb.SupabaseClient? _clientOverride;

  sb.SupabaseClient get _client =>
      _clientOverride ?? sb.Supabase.instance.client;

  @override
  Future<Result<List<HandoverOrderCandidate>>> fetchHandoverQueue() async {
    try {
      final response = await _client
          .from('service_orders')
          .select('''
            id, order_number, status, customer_id, vehicle_id, odometer, customer_complaint, created_at, updated_at,
            customers:customer_id (id, full_name, phone_number),
            vehicles:vehicle_id (id, license_plate, make, model, year, color),
            invoices (id, invoice_number, status, total_amount_cents, amount_paid_cents, outstanding_balance_cents),
            vehicle_handovers (id, service_order_id, customer_id, responsible_admin_id, handover_timestamp, customer_confirmed, payment_override_reason, checklist, notes, created_at)
          ''')
          .eq('status', 'completed')
          .order('updated_at', ascending: false);

      final list = (response as List)
          .map((row) =>
              HandoverOrderCandidate.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to load handover queue: ${e.message}',
          code: e.code,
        ),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error connecting to Supabase: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error loading handover queue: $e'),
      );
    }
  }

  @override
  Future<Result<List<HandoverOrderCandidate>>> fetchHandoverHistory() async {
    try {
      final response = await _client
          .from('service_orders')
          .select('''
            id, order_number, status, customer_id, vehicle_id, odometer, customer_complaint, created_at, updated_at,
            customers:customer_id (id, full_name, phone_number),
            vehicles:vehicle_id (id, license_plate, make, model, year, color),
            invoices (id, invoice_number, status, total_amount_cents, amount_paid_cents, outstanding_balance_cents),
            vehicle_handovers (id, service_order_id, customer_id, responsible_admin_id, handover_timestamp, customer_confirmed, payment_override_reason, checklist, notes, created_at)
          ''')
          .eq('status', 'closed')
          .order('updated_at', ascending: false);

      final list = (response as List)
          .map((row) =>
              HandoverOrderCandidate.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to load handover history: ${e.message}',
          code: e.code,
        ),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error connecting to Supabase: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error loading handover history: $e'),
      );
    }
  }

  @override
  Future<Result<VehicleHandoverModel?>> fetchHandoverByOrderId(
      String orderId) async {
    try {
      final response = await _client
          .from('vehicle_handovers')
          .select('''
            *,
            service_orders:service_order_id (order_number, vehicles:vehicle_id (license_plate, make, model)),
            customers:customer_id (full_name, phone_number),
            responsible_admin:responsible_admin_id (full_name)
          ''')
          .eq('service_order_id', orderId)
          .maybeSingle();

      if (response == null) {
        return const Result.success(null);
      }

      return Result.success(
        VehicleHandoverModel.fromJson(response),
      );
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to load handover for order $orderId: ${e.message}',
          code: e.code,
        ),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error connecting to Supabase: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error loading handover: $e'),
      );
    }
  }

  @override
  Future<Result<VehicleHandoverModel>> recordVehicleHandover({
    required String serviceOrderId,
    required String adminId,
    required HandoverChecklist checklist,
    bool customerConfirmed = true,
    String? notes,
    String? paymentOverrideReason,
  }) async {
    try {
      // Execute transactional database RPC
      final rpcResponse = await _client.rpc(
        'record_vehicle_handover',
        params: {
          'p_service_order_id': serviceOrderId,
          'p_admin_id': adminId,
          'p_checklist': checklist.toJson(),
          'p_notes': notes,
          'p_payment_override_reason': paymentOverrideReason,
        },
      );

      final handoverId = rpcResponse as String;

      // Ensure customer confirmation flag is persisted if false
      if (!customerConfirmed) {
        await _client
            .from('vehicle_handovers')
            .update({'customer_confirmed': false})
            .eq('id', handoverId);
      }

      // Fetch the created record
      final fetchRes = await _client
          .from('vehicle_handovers')
          .select('''
            *,
            service_orders:service_order_id (order_number, vehicles:vehicle_id (license_plate, make, model)),
            customers:customer_id (full_name, phone_number),
            responsible_admin:responsible_admin_id (full_name)
          ''')
          .eq('id', handoverId)
          .single();

      return Result.success(
        VehicleHandoverModel.fromJson(fetchRes),
      );
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException(
          'Handover failed: ${e.message}',
          code: e.code,
        ),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error during handover: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Handover execution failed: $e'),
      );
    }
  }
}

/// Global provider for [IHandoverRepository].
final handoverRepositoryProvider = Provider<IHandoverRepository>((ref) {
  return HandoverRepository();
});
