import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<List<BookingModel>> fetchCustomerBookings(String customerId) async {
    final response = await _supabase
        .from('bookings')
        .select('*, vehicles(license_plate, make, model)')
        .eq('customer_id', customerId)
        .order('booking_date', ascending: false);

    return (response as List)
        .map((row) => BookingModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> fetchAdminBookings({BookingStatus? status}) async {
    var query = _supabase
        .from('bookings')
        .select('*, customers(full_name, phone_number, email), vehicles(license_plate, make, model)');

    if (status != null) {
      query = query.eq('status', status.toDbString());
    }

    final response = await query.order('booking_date', ascending: true);

    return (response as List)
        .map((row) => BookingModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('bookings')
        .insert(data)
        .select('*, vehicles(license_plate, make, model)')
        .single();

    return BookingModel.fromJson(response);
  }

  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? adminNotes,
  }) async {
    final Map<String, dynamic> updates = {
      'status': status.toDbString(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (adminNotes != null) {
      updates['admin_notes'] = adminNotes;
    }

    final response = await _supabase
        .from('bookings')
        .update(updates)
        .eq('id', bookingId)
        .select('*, customers(full_name, phone_number, email), vehicles(license_plate, make, model)')
        .single();

    return BookingModel.fromJson(response);
  }

  Future<BookingModel> rescheduleBooking(
    String bookingId,
    DateTime date,
    String slot,
  ) async {
    final formattedDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from('bookings')
        .update({
          'booking_date': formattedDate,
          'time_slot': slot,
          'status': BookingStatus.rescheduled.toDbString(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .select('*, customers(full_name, phone_number, email), vehicles(license_plate, make, model)')
        .single();

    return BookingModel.fromJson(response);
  }
}
