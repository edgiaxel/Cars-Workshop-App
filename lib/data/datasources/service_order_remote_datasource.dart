import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_order.dart';

/// Contract for Service Order remote data access against Supabase.
abstract class ServiceOrderRemoteDataSource {
  Future<List<ServiceOrder>> fetchServiceOrders({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
    String? mechanicId,
  });
  Future<ServiceOrder> getServiceOrderById(String id);
  Future<ServiceOrder> createServiceOrder({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
  });
  Future<ServiceOrder> updateServiceOrderStatus({
    required String id,
    required ServiceStatus status,
  });
  Future<ServiceOrder> updateServiceOrder({
    required String id,
    String? title,
    String? description,
    ServiceStatus? status,
    double? estimatedTotal,
    double? finalTotal,
    int? odometerKm,
    String? mechanicId,
  });
  Future<void> deleteServiceOrder(String id);
}

/// Concrete Supabase implementation for [ServiceOrderRemoteDataSource].
class SupabaseServiceOrderRemoteDataSource
    implements ServiceOrderRemoteDataSource {
  const SupabaseServiceOrderRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _selectQuery =
      '*, customers(*, profiles(*)), vehicles(*), service_assignments(*, mechanics(*, profiles(*)))';

  @override
  Future<List<ServiceOrder>> fetchServiceOrders({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
    String? mechanicId,
  }) async {
    var query = _client.from('service_orders').select(_selectQuery);

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter.toLowerCase() != 'all') {
      final formattedStatus = statusFilter.toLowerCase().trim().replaceAll(
        ' ',
        '_',
      );
      query = query.eq('status', formattedStatus);
    }

    final data = await query.order('created_at', ascending: false);
    var orders = (data as List)
        .map((json) => ServiceOrder.fromJson(json as Map<String, dynamic>))
        .toList();

    if (mechanicId != null && mechanicId.isNotEmpty) {
      orders = orders.where((o) {
        return o.assignments.any((a) => a.mechanicId == mechanicId);
      }).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      orders = orders.where((o) {
        final codeMatch = o.orderNumber.toLowerCase().contains(q);
        final titleMatch = o.title.toLowerCase().contains(q);
        final customerMatch =
            o.customer?.displayName.toLowerCase().contains(q) ?? false;
        final vehicleMatch =
            o.vehicle?.displayName.toLowerCase().contains(q) ?? false;
        final plateMatch =
            o.vehicle?.licensePlate?.toLowerCase().contains(q) ?? false;
        final mechanicMatch = o.mechanicDisplayName.toLowerCase().contains(q);
        return codeMatch ||
            titleMatch ||
            customerMatch ||
            vehicleMatch ||
            plateMatch ||
            mechanicMatch;
      }).toList();
    }

    return orders;
  }

  @override
  Future<ServiceOrder> getServiceOrderById(String id) async {
    final data = await _client
        .from('service_orders')
        .select(_selectQuery)
        .eq('id', id)
        .single();
    return ServiceOrder.fromJson(data);
  }

  @override
  Future<ServiceOrder> createServiceOrder({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final orderNumber =
        'SO-${DateTime.now().year}-${ts.substring(ts.length - 4)}';

    final payload = <String, dynamic>{
      'order_number': orderNumber,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'title': title.trim(),
      'status': ServiceStatus.requested.value,
      'estimated_total': estimatedTotal,
    };
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }
    if (odometerKm != null) {
      payload['odometer_km'] = odometerKm;
    }

    final data = await _client
        .from('service_orders')
        .insert(payload)
        .select(_selectQuery)
        .single();

    final createdOrder = ServiceOrder.fromJson(data);

    if (mechanicId != null && mechanicId.isNotEmpty) {
      await _client.from('service_assignments').insert({
        'service_order_id': createdOrder.id,
        'mechanic_id': mechanicId,
        'role_description': 'Lead Technician',
      });
      return getServiceOrderById(createdOrder.id);
    }

    return createdOrder;
  }

  @override
  Future<ServiceOrder> updateServiceOrderStatus({
    required String id,
    required ServiceStatus status,
  }) async {
    final payload = <String, dynamic>{'status': status.value};
    if (status == ServiceStatus.completed) {
      payload['completed_at'] = DateTime.now().toIso8601String();
    } else if (status == ServiceStatus.closed) {
      payload['closed_at'] = DateTime.now().toIso8601String();
    }

    await _client.from('service_orders').update(payload).eq('id', id);
    return getServiceOrderById(id);
  }

  @override
  Future<ServiceOrder> updateServiceOrder({
    required String id,
    String? title,
    String? description,
    ServiceStatus? status,
    double? estimatedTotal,
    double? finalTotal,
    int? odometerKm,
    String? mechanicId,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (description != null) payload['description'] = description.trim();
    if (status != null) payload['status'] = status.value;
    if (estimatedTotal != null) payload['estimated_total'] = estimatedTotal;
    if (finalTotal != null) payload['final_total'] = finalTotal;
    if (odometerKm != null) payload['odometer_km'] = odometerKm;

    if (payload.isNotEmpty) {
      await _client.from('service_orders').update(payload).eq('id', id);
    }

    if (mechanicId != null && mechanicId.isNotEmpty) {
      // Upsert assignment
      final existingAssignments = await _client
          .from('service_assignments')
          .select('id')
          .eq('service_order_id', id);

      if ((existingAssignments as List).isEmpty) {
        await _client.from('service_assignments').insert({
          'service_order_id': id,
          'mechanic_id': mechanicId,
          'role_description': 'Lead Technician',
        });
      } else {
        await _client
            .from('service_assignments')
            .update({'mechanic_id': mechanicId})
            .eq('service_order_id', id);
      }
    }

    return getServiceOrderById(id);
  }

  @override
  Future<void> deleteServiceOrder(String id) async {
    await _client.from('service_orders').delete().eq('id', id);
  }
}
