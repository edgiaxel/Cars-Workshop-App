import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

/// Contract for Booking remote data access against Supabase.
abstract class BookingRemoteDataSource {
  Future<List<Booking>> fetchBookings({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
  });
  Future<Booking> getBookingById(String id);
  Future<Booking> createBooking({
    required String customerId,
    required String vehicleId,
    required String requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    String? adminNotes,
  });
  Future<Booking> updateBookingStatus({
    required String id,
    required BookingStatus status,
    String? adminNotes,
  });
  Future<Booking> updateBooking({
    required String id,
    String? requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    BookingStatus? status,
    String? adminNotes,
  });
  Future<void> deleteBooking(String id);
}

/// Concrete Supabase implementation for [BookingRemoteDataSource].
class SupabaseBookingRemoteDataSource implements BookingRemoteDataSource {
  const SupabaseBookingRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Booking>> fetchBookings({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
  }) async {
    var query = _client
        .from('bookings')
        .select('*, customers(*, profiles(*)), vehicles(*)');

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter.toLowerCase() != 'all') {
      query = query.eq('status', statusFilter.toLowerCase());
    }

    final data = await query.order('created_at', ascending: false);
    final bookings = (data as List)
        .map((json) => Booking.fromJson(json as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return bookings.where((b) {
        final serviceMatch = b.requestedService.toLowerCase().contains(q);
        final descMatch = b.description?.toLowerCase().contains(q) ?? false;
        final customerMatch =
            b.customer?.displayName.toLowerCase().contains(q) ?? false;
        final vehicleMatch =
            b.vehicle?.displayName.toLowerCase().contains(q) ?? false;
        final plateMatch =
            b.vehicle?.licensePlate?.toLowerCase().contains(q) ?? false;
        return serviceMatch ||
            descMatch ||
            customerMatch ||
            vehicleMatch ||
            plateMatch;
      }).toList();
    }

    return bookings;
  }

  @override
  Future<Booking> getBookingById(String id) async {
    final data = await _client
        .from('bookings')
        .select('*, customers(*, profiles(*)), vehicles(*)')
        .eq('id', id)
        .single();
    return Booking.fromJson(data);
  }

  @override
  Future<Booking> createBooking({
    required String customerId,
    required String vehicleId,
    required String requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    String? adminNotes,
  }) async {
    final payload = <String, dynamic>{
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'requested_service': requestedService.trim(),
      'status': BookingStatus.requested.value,
    };
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }
    if (preferredDate != null && preferredDate.trim().isNotEmpty) {
      payload['preferred_date'] = preferredDate.trim();
    }
    if (preferredTime != null && preferredTime.trim().isNotEmpty) {
      payload['preferred_time'] = preferredTime.trim();
    }
    if (adminNotes != null && adminNotes.trim().isNotEmpty) {
      payload['admin_notes'] = adminNotes.trim();
    }

    final data = await _client
        .from('bookings')
        .insert(payload)
        .select('*, customers(*, profiles(*)), vehicles(*)')
        .single();

    return Booking.fromJson(data);
  }

  @override
  Future<Booking> updateBookingStatus({
    required String id,
    required BookingStatus status,
    String? adminNotes,
  }) async {
    final payload = <String, dynamic>{'status': status.value};
    if (adminNotes != null) {
      payload['admin_notes'] = adminNotes.trim();
    }

    final data = await _client
        .from('bookings')
        .update(payload)
        .eq('id', id)
        .select('*, customers(*, profiles(*)), vehicles(*)')
        .single();

    return Booking.fromJson(data);
  }

  @override
  Future<Booking> updateBooking({
    required String id,
    String? requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    BookingStatus? status,
    String? adminNotes,
  }) async {
    final payload = <String, dynamic>{};
    if (requestedService != null) {
      payload['requested_service'] = requestedService.trim();
    }
    if (description != null) {
      payload['description'] = description.trim();
    }
    if (preferredDate != null) {
      payload['preferred_date'] = preferredDate.trim();
    }
    if (preferredTime != null) {
      payload['preferred_time'] = preferredTime.trim();
    }
    if (status != null) {
      payload['status'] = status.value;
    }
    if (adminNotes != null) {
      payload['admin_notes'] = adminNotes.trim();
    }

    final data = await _client
        .from('bookings')
        .update(payload)
        .eq('id', id)
        .select('*, customers(*, profiles(*)), vehicles(*)')
        .single();

    return Booking.fromJson(data);
  }

  @override
  Future<void> deleteBooking(String id) async {
    await _client.from('bookings').delete().eq('id', id);
  }
}
