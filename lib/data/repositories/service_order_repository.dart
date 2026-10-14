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
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
  }) {
    return _remoteDataSource.createServiceOrder(
      customerId: customerId,
      vehicleId: vehicleId,
      title: title,
      description: description,
      mechanicId: mechanicId,
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
