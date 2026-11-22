import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../models/estimate_authorization_model.dart';
import '../models/estimate_item_model.dart';
import '../models/estimate_model.dart';

/// Abstract contract for estimate data operations.
abstract class IEstimateRepository {
  Future<Result<EstimateModel?>> fetchEstimateByOrderId(String orderId);
  Future<Result<EstimateModel?>> fetchEstimateById(String estimateId);
  Future<Result<List<EstimateItemModel>>> fetchEstimateItems(String estimateId);
  Future<Result<EstimateModel>> createEstimateDraft(
    EstimateModel estimate,
    List<EstimateItemModel> items,
  );
  Future<Result<EstimateModel>> publishEstimate(String estimateId);
  Future<Result<EstimateModel>> authorizeEstimate(
    String estimateId,
    EstimateStatus decision, {
    String? notes,
    String? signatureToken,
  });
  Future<Result<List<EstimateAuthorizationModel>>> fetchAuthorizations(String estimateId);
  Future<Result<Map<String, dynamic>?>> fetchServiceOrderSummary(String orderId);
}

/// Supabase implementation of [IEstimateRepository].
class EstimateRepository implements IEstimateRepository {
  final sb.SupabaseClient? _clientOverride;

  EstimateRepository([this._clientOverride]);

  sb.SupabaseClient get _client {
    if (_clientOverride != null) return _clientOverride;
    return sb.Supabase.instance.client;
  }

  @override
  Future<Result<EstimateModel?>> fetchEstimateByOrderId(String orderId) async {
    try {
      final response = await _client
          .from('estimates')
          .select()
          .eq('service_order_id', orderId)
          .order('revision_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const Result.success(null);
      }
      return Result.success(EstimateModel.fromJson(response));
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch estimate for order $orderId: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error while fetching estimate: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error fetching estimate: $e'),
      );
    }
  }

  @override
  Future<Result<EstimateModel?>> fetchEstimateById(String estimateId) async {
    try {
      final response = await _client
          .from('estimates')
          .select()
          .eq('id', estimateId)
          .maybeSingle();

      if (response == null) {
        return const Result.success(null);
      }
      return Result.success(EstimateModel.fromJson(response));
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch estimate $estimateId: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Result<List<EstimateItemModel>>> fetchEstimateItems(String estimateId) async {
    try {
      final response = await _client
          .from('estimate_items')
          .select()
          .eq('estimate_id', estimateId)
          .order('created_at', ascending: true);

      final items = (response as List)
          .map((row) => EstimateItemModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to load estimate items: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error loading estimate items: $e'),
      );
    }
  }

  @override
  Future<Result<EstimateModel>> createEstimateDraft(
    EstimateModel estimate,
    List<EstimateItemModel> items,
  ) async {
    try {
      EstimateModel savedEstimate;

      if (estimate.id.isNotEmpty) {
        // Update existing estimate header
        final updatedData = await _client
            .from('estimates')
            .update({
              'subtotal_cents': estimate.subtotalCents,
              'tax_cents': estimate.taxCents,
              'discount_cents': estimate.discountCents,
              'total_cents': estimate.totalCents,
              'notes': estimate.notes,
              'revision_number': estimate.revisionNumber,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', estimate.id)
            .select()
            .single();

        savedEstimate = EstimateModel.fromJson(updatedData);

        // Delete existing items and re-insert fresh
        await _client.from('estimate_items').delete().eq('estimate_id', savedEstimate.id);
      } else {
        // Insert new estimate draft
        final insertPayload = estimate.toJson(includeId: false);
        insertPayload['status'] = EstimateStatus.draft.toDbString();
        insertPayload['created_at'] = DateTime.now().toIso8601String();
        insertPayload['updated_at'] = DateTime.now().toIso8601String();

        final createdData = await _client
            .from('estimates')
            .insert(insertPayload)
            .select()
            .single();

        savedEstimate = EstimateModel.fromJson(createdData);
      }

      // Batch insert items if any
      if (items.isNotEmpty) {
        final itemsPayload = items.map((item) {
          final map = item.toJson(includeId: false);
          map['estimate_id'] = savedEstimate.id;
          return map;
        }).toList();

        await _client.from('estimate_items').insert(itemsPayload);
      }

      return Result.success(savedEstimate);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to save estimate draft: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error while saving draft: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error saving draft: $e'),
      );
    }
  }

  @override
  Future<Result<EstimateModel>> publishEstimate(String estimateId) async {
    try {
      final response = await _client
          .from('estimates')
          .update({
            'status': EstimateStatus.sent.toDbString(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', estimateId)
          .select()
          .single();

      final updated = EstimateModel.fromJson(response);
      return Result.success(updated);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to publish estimate: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error while publishing: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error publishing estimate: $e'),
      );
    }
  }

  @override
  Future<Result<EstimateModel>> authorizeEstimate(
    String estimateId,
    EstimateStatus decision, {
    String? notes,
    String? signatureToken,
  }) async {
    try {
      final response = await _client.rpc(
        'authorize_estimate',
        params: {
          'p_estimate_id': estimateId,
          'p_decision': decision.toDbString(),
          'p_notes': notes,
          'p_signature_token': signatureToken,
        },
      );

      if (response == null) {
        return const Result.failure(
          DatabaseException('Authorization RPC returned empty result'),
        );
      }

      final updated = EstimateModel.fromJson(Map<String, dynamic>.from(response as Map));
      return Result.success(updated);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Authorization rejected: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network connection error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Authorization failed: $e'),
      );
    }
  }

  @override
  Future<Result<List<EstimateAuthorizationModel>>> fetchAuthorizations(String estimateId) async {
    try {
      final response = await _client
          .from('estimate_authorizations')
          .select()
          .eq('estimate_id', estimateId)
          .order('authorized_at', ascending: false);

      final auths = (response as List)
          .map((row) => EstimateAuthorizationModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(auths);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch authorizations: ${e.message}', code: e.code),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Error fetching authorizations: $e'),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> fetchServiceOrderSummary(String orderId) async {
    try {
      final response = await _client
          .from('service_orders')
          .select('''
            id, order_number, odometer, customer_complaint, status, assigned_bay, created_at,
            customers:customer_id (id, full_name, phone_number, customer_type),
            vehicles:vehicle_id (id, make, model, year, license_plate, color),
            inspections (id, status, summary, inspection_findings (*))
          ''')
          .eq('id', orderId)
          .maybeSingle();

      return Result.success(response);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch service order summary: ${e.message}', code: e.code),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Error loading service order: $e'),
      );
    }
  }
}

/// Global provider for [IEstimateRepository].
final estimateRepositoryProvider = Provider<IEstimateRepository>((ref) {
  return EstimateRepository();
});
