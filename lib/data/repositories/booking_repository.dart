import '../datasources/booking_remote_datasource.dart';
import '../models/booking.dart';

/// Repository interface for Booking management.
abstract class BookingRepository {
  Future<List<Booking>> getBookings({
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

/// Concrete repository delegating to [BookingRemoteDataSource].
class SupabaseBookingRepository implements BookingRepository {
  const SupabaseBookingRepository(this._remoteDataSource);

  final BookingRemoteDataSource _remoteDataSource;

  @override
  Future<List<Booking>> getBookings({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
  }) {
    return _remoteDataSource.fetchBookings(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      customerId: customerId,
    );
  }

  @override
  Future<Booking> getBookingById(String id) {
    return _remoteDataSource.getBookingById(id);
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
  }) {
    return _remoteDataSource.createBooking(
      customerId: customerId,
      vehicleId: vehicleId,
      requestedService: requestedService,
      description: description,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      adminNotes: adminNotes,
    );
  }

  @override
  Future<Booking> updateBookingStatus({
    required String id,
    required BookingStatus status,
    String? adminNotes,
  }) {
    return _remoteDataSource.updateBookingStatus(
      id: id,
      status: status,
      adminNotes: adminNotes,
    );
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
  }) {
    return _remoteDataSource.updateBooking(
      id: id,
      requestedService: requestedService,
      description: description,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      status: status,
      adminNotes: adminNotes,
    );
  }

  @override
  Future<void> deleteBooking(String id) {
    return _remoteDataSource.deleteBooking(id);
  }
}
