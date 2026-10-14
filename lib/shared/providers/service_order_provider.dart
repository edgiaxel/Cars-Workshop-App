import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/service_order_remote_datasource.dart';
import '../../data/models/service_order.dart';
import '../../data/repositories/service_order_repository.dart';
import 'customer_provider.dart';
import 'mechanic_provider.dart';
import 'supabase_provider.dart';

/// Provider for [ServiceOrderRemoteDataSource].
final serviceOrderRemoteDataSourceProvider =
    Provider<ServiceOrderRemoteDataSource?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return null;
      return SupabaseServiceOrderRemoteDataSource(client);
    });

/// Provider for [ServiceOrderRepository].
final serviceOrderRepositoryProvider = Provider<ServiceOrderRepository?>((ref) {
  final dataSource = ref.watch(serviceOrderRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseServiceOrderRepository(dataSource);
});

/// AsyncNotifier managing the Service Orders list for Admin.
class ServiceOrdersNotifier extends AsyncNotifier<List<ServiceOrder>> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String? _customerId;
  String? _mechanicId;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  @override
  Future<List<ServiceOrder>> build() async {
    final repository = ref.watch(serviceOrderRepositoryProvider);
    if (repository == null) {
      return const [];
    }
    return repository.getServiceOrders(
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      customerId: _customerId,
      mechanicId: _mechanicId,
    );
  }

  Future<void> setFilter({
    String? query,
    String? status,
    String? customerId,
    String? mechanicId,
  }) async {
    if (query != null) _searchQuery = query;
    if (status != null) _statusFilter = status;
    if (customerId != null) _customerId = customerId;
    if (mechanicId != null) _mechanicId = mechanicId;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceOrderRepositoryProvider);
      if (repository == null) return const [];
      return repository.getServiceOrders(
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
        customerId: _customerId,
        mechanicId: _mechanicId,
      );
    });
  }

  Future<ServiceOrder> createServiceOrder({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
  }) async {
    final repository = ref.read(serviceOrderRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase service order repository is unconfigured.');
    }

    final created = await repository.createServiceOrder(
      customerId: customerId,
      vehicleId: vehicleId,
      title: title,
      description: description,
      mechanicId: mechanicId,
      estimatedTotal: estimatedTotal,
      odometerKm: odometerKm,
    );

    ref.invalidateSelf();
    return created;
  }

  Future<ServiceOrder> updateServiceOrderStatus({
    required String id,
    required ServiceStatus status,
  }) async {
    final repository = ref.read(serviceOrderRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase service order repository is unconfigured.');
    }

    final updated = await repository.updateServiceOrderStatus(
      id: id,
      status: status,
    );

    ref.invalidateSelf();
    return updated;
  }

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
    final repository = ref.read(serviceOrderRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase service order repository is unconfigured.');
    }

    final updated = await repository.updateServiceOrder(
      id: id,
      title: title,
      description: description,
      status: status,
      estimatedTotal: estimatedTotal,
      finalTotal: finalTotal,
      odometerKm: odometerKm,
      mechanicId: mechanicId,
    );

    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteServiceOrder(String id) async {
    final repository = ref.read(serviceOrderRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase service order repository is unconfigured.');
    }

    await repository.deleteServiceOrder(id);
    ref.invalidateSelf();
  }
}

/// Provider exposing reactive service orders list.
final serviceOrdersProvider =
    AsyncNotifierProvider<ServiceOrdersNotifier, List<ServiceOrder>>(
      ServiceOrdersNotifier.new,
    );

/// Provider fetching service orders for a specific customer.
final customerServiceOrdersProvider =
    FutureProvider.family<List<ServiceOrder>, String?>((ref, customerId) async {
      final repository = ref.watch(serviceOrderRepositoryProvider);
      if (repository == null) return const [];
      var targetId = customerId;
      if (targetId == null) {
        try {
          final cust = await ref.watch(currentCustomerProvider.future);
          targetId = cust?.id;
        } catch (_) {}
      }
      return repository.getServiceOrders(customerId: targetId);
    });

/// Provider fetching service orders assigned to a specific mechanic.
final mechanicServiceOrdersProvider =
    FutureProvider.family<List<ServiceOrder>, String?>((ref, mechanicId) async {
      final repository = ref.watch(serviceOrderRepositoryProvider);
      if (repository == null) return const [];
      var targetId = mechanicId;
      if (targetId == null) {
        try {
          final mech = await ref.watch(currentMechanicProvider.future);
          targetId = mech?.id;
        } catch (_) {}
      }
      return repository.getServiceOrders(mechanicId: targetId);
    });
