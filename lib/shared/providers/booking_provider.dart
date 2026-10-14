import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import 'supabase_provider.dart';

/// Provider for [BookingRemoteDataSource].
final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseBookingRemoteDataSource(client);
});

/// Provider for [BookingRepository].
final bookingRepositoryProvider = Provider<BookingRepository?>((ref) {
  final dataSource = ref.watch(bookingRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseBookingRepository(dataSource);
});

/// AsyncNotifier managing the Bookings list for Admin.
class BookingsNotifier extends AsyncNotifier<List<Booking>> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String? _customerId;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String? get customerId => _customerId;

  @override
  Future<List<Booking>> build() async {
    final repository = ref.watch(bookingRepositoryProvider);
    if (repository == null) {
      return const [];
    }
    return repository.getBookings(
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      customerId: _customerId,
    );
  }

  Future<void> setFilter({
    String? query,
    String? status,
    String? customerId,
  }) async {
    if (query != null) _searchQuery = query;
    if (status != null) _statusFilter = status;
    if (customerId != null) _customerId = customerId;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookingRepositoryProvider);
      if (repository == null) return const [];
      return repository.getBookings(
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
        customerId: _customerId,
      );
    });
  }

  Future<Booking> createBooking({
    required String customerId,
    required String vehicleId,
    required String requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    String? adminNotes,
  }) async {
    final repository = ref.read(bookingRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase booking repository is unconfigured.');
    }

    final created = await repository.createBooking(
      customerId: customerId,
      vehicleId: vehicleId,
      requestedService: requestedService,
      description: description,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      adminNotes: adminNotes,
    );

    ref.invalidateSelf();
    return created;
  }

  Future<Booking> updateBookingStatus({
    required String id,
    required BookingStatus status,
    String? adminNotes,
  }) async {
    final repository = ref.read(bookingRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase booking repository is unconfigured.');
    }

    final updated = await repository.updateBookingStatus(
      id: id,
      status: status,
      adminNotes: adminNotes,
    );

    ref.invalidateSelf();
    return updated;
  }

  Future<Booking> updateBooking({
    required String id,
    String? requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    BookingStatus? status,
    String? adminNotes,
  }) async {
    final repository = ref.read(bookingRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase booking repository is unconfigured.');
    }

    final updated = await repository.updateBooking(
      id: id,
      requestedService: requestedService,
      description: description,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      status: status,
      adminNotes: adminNotes,
    );

    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteBooking(String id) async {
    final repository = ref.read(bookingRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase booking repository is unconfigured.');
    }

    await repository.deleteBooking(id);
    ref.invalidateSelf();
  }
}

/// Provider exposing reactive bookings list.
final bookingsProvider = AsyncNotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);

/// Provider fetching bookings for a specific customer.
final customerBookingsProvider = FutureProvider.family<List<Booking>, String?>((
  ref,
  customerId,
) async {
  final repository = ref.watch(bookingRepositoryProvider);
  if (repository == null) return const [];
  return repository.getBookings(customerId: customerId);
});
