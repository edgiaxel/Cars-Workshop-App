import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';
import 'supabase_provider.dart';

/// Provider for [CustomerRemoteDataSource].
final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseCustomerRemoteDataSource(client);
});

/// Provider for [CustomerRepository].
final customerRepositoryProvider = Provider<CustomerRepository?>((ref) {
  final dataSource = ref.watch(customerRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseCustomerRepository(dataSource);
});

/// State parameters for customer query.
class CustomerQueryState {
  const CustomerQueryState({this.searchQuery = '', this.typeFilter = 'All'});
  final String searchQuery;
  final String typeFilter;
}

/// AsyncNotifier managing the Customers list lifecycle, filters, and mutations.
class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  String _searchQuery = '';
  String _typeFilter = 'All';

  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;

  @override
  Future<List<Customer>> build() async {
    final repository = ref.watch(customerRepositoryProvider);
    if (repository == null) {
      return const [];
    }

    return repository.getCustomers(
      searchQuery: _searchQuery,
      typeFilter: _typeFilter,
    );
  }

  Future<void> setFilter({String? query, String? type}) async {
    if (query != null) _searchQuery = query;
    if (type != null) _typeFilter = type;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(customerRepositoryProvider);
      if (repository == null) return const [];
      return repository.getCustomers(
        searchQuery: _searchQuery,
        typeFilter: _typeFilter,
      );
    });
  }

  Future<Customer> updateCustomer({
    required String id,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
    String? fullName,
    String? phone,
  }) async {
    final repository = ref.read(customerRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase customer repository is unconfigured.');
    }

    final updated = await repository.updateCustomer(
      id: id,
      customerType: customerType,
      companyName: companyName,
      address: address,
      notes: notes,
      fullName: fullName,
      phone: phone,
    );

    // Refresh list state
    ref.invalidateSelf();
    return updated;
  }

  Future<Customer> createCustomer({
    required String profileId,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
  }) async {
    final repository = ref.read(customerRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase customer repository is unconfigured.');
    }

    final created = await repository.createCustomer(
      profileId: profileId,
      customerType: customerType,
      companyName: companyName,
      address: address,
      notes: notes,
    );

    ref.invalidateSelf();
    return created;
  }

  Future<void> deleteCustomer(String id) async {
    final repository = ref.read(customerRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase customer repository is unconfigured.');
    }

    await repository.deleteCustomer(id);
    ref.invalidateSelf();
  }
}

/// Provider exposing reactive customer records.
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
      CustomersNotifier.new,
    );

/// Provider resolving the currently authenticated customer profile.
final currentCustomerProvider = FutureProvider<Customer?>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  if (repository == null) return null;
  return repository.getCurrentCustomer();
});
