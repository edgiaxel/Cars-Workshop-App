import '../datasources/service_order_remote_datasource.dart';
import '../models/service_order.dart';

/// Repository interface for Service Order management.
abstract class ServiceOrderRepository {
  Future<List<ServiceOrder>> getServiceOrders({
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
    String? bookingId,
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
    ServiceIntakeOrigin intakeOrigin = ServiceIntakeOrigin.walkIn,
    DateTime? arrivedAt,
  });
  Future<ServiceOrder> checkInBooking({
    required String bookingId,
    String? adminNotes,
  });
  Future<ServiceOrder> admitWalkIn({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
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

/// Concrete repository delegating to [ServiceOrderRemoteDataSource].
class SupabaseServiceOrderRepository implements ServiceOrderRepository {
  const SupabaseServiceOrderRepository(this._remoteDataSource);

  final ServiceOrderRemoteDataSource _remoteDataSource;

  @override
  Future<List<ServiceOrder>> getServiceOrders({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
    String? mechanicId,
  }) {
    return _remoteDataSource.fetchServiceOrders(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      customerId: customerId,
      mechanicId: mechanicId,
    );
  }

  @override
  Future<ServiceOrder> getServiceOrderById(String id) {
    return _remoteDataSource.getServiceOrderById(id);
  }

  @override
  Future<ServiceOrder> createServiceOrder({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
    String? bookingId,
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
    ServiceIntakeOrigin intakeOrigin = ServiceIntakeOrigin.walkIn,
    DateTime? arrivedAt,
  }) {
    return _remoteDataSource.createServiceOrder(
      customerId: customerId,
      vehicleId: vehicleId,
      title: title,
      description: description,
      bookingId: bookingId,
      mechanicId: mechanicId,
      estimatedTotal: estimatedTotal,
      odometerKm: odometerKm,
      intakeOrigin: intakeOrigin,
      arrivedAt: arrivedAt,
    );
  }

  @override
  Future<ServiceOrder> checkInBooking({
    required String bookingId,
    String? adminNotes,
  }) {
    return _remoteDataSource.checkInBooking(
      bookingId: bookingId,
      adminNotes: adminNotes,
    );
  }

  @override
  Future<ServiceOrder> admitWalkIn({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
    double estimatedTotal = 0.0,
    int? odometerKm,
  }) {
    return _remoteDataSource.admitWalkIn(
      customerId: customerId,
      vehicleId: vehicleId,
      title: title,
      description: description,
      estimatedTotal: estimatedTotal,
      odometerKm: odometerKm,
    );
  }

  @override
  Future<ServiceOrder> updateServiceOrderStatus({
    required String id,
    required ServiceStatus status,
  }) {
    return _remoteDataSource.updateServiceOrderStatus(id: id, status: status);
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
  }) {
    return _remoteDataSource.updateServiceOrder(
      id: id,
      title: title,
      description: description,
      status: status,
      estimatedTotal: estimatedTotal,
      finalTotal: finalTotal,
      odometerKm: odometerKm,
      mechanicId: mechanicId,
    );
  }

  @override
  Future<void> deleteServiceOrder(String id) {
    return _remoteDataSource.deleteServiceOrder(id);
  }
}
