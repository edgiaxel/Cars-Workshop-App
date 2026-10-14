import '../datasources/customer_remote_datasource.dart';
import '../models/customer.dart';

/// Repository interface for Customer management.
abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    String? typeFilter,
  });
  Future<Customer> getCustomerById(String id);
  Future<Customer> updateCustomer({
    required String id,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
    String? fullName,
    String? phone,
  });
  Future<Customer> createCustomer({
    required String profileId,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
  });
  Future<Customer?> getCurrentCustomer();
  Future<void> deleteCustomer(String id);
}

/// Concrete repository delegating to [CustomerRemoteDataSource].
class SupabaseCustomerRepository implements CustomerRepository {
  const SupabaseCustomerRepository(this._remoteDataSource);

  final CustomerRemoteDataSource _remoteDataSource;

  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    String? typeFilter,
  }) {
    return _remoteDataSource.fetchCustomers(
      searchQuery: searchQuery,
      typeFilter: typeFilter,
    );
  }

  @override
  Future<Customer> getCustomerById(String id) {
    return _remoteDataSource.getCustomerById(id);
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
    String? fullName,
    String? phone,
  }) {
    return _remoteDataSource.updateCustomer(
      id: id,
      customerType: customerType,
      companyName: companyName,
      address: address,
      notes: notes,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<Customer> createCustomer({
    required String profileId,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
  }) {
    return _remoteDataSource.createCustomer(
      profileId: profileId,
      customerType: customerType,
      companyName: companyName,
      address: address,
      notes: notes,
    );
  }

  @override
  Future<Customer?> getCurrentCustomer() {
    return _remoteDataSource.getCurrentCustomer();
  }

  @override
  Future<void> deleteCustomer(String id) {
    return _remoteDataSource.deleteCustomer(id);
  }
}
