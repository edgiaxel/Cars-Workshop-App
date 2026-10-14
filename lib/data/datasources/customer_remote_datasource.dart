import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';

/// Contract for Customer remote data access against Supabase.
abstract class CustomerRemoteDataSource {
  Future<List<Customer>> fetchCustomers({
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

/// Concrete Supabase implementation for [CustomerRemoteDataSource].
class SupabaseCustomerRemoteDataSource implements CustomerRemoteDataSource {
  const SupabaseCustomerRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Customer>> fetchCustomers({
    String? searchQuery,
    String? typeFilter,
  }) async {
    var query = _client.from('customers').select('*, profiles(*)');

    if (typeFilter != null &&
        typeFilter.isNotEmpty &&
        typeFilter.toLowerCase() != 'all') {
      query = query.eq('customer_type', typeFilter.toLowerCase());
    }

    final data = await query.order('created_at', ascending: false);
    final customers = (data as List)
        .map((json) => Customer.fromJson(json as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return customers.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(q);
        final emailMatch =
            c.profile?.fullName.toLowerCase().contains(q) ?? false;
        final notesMatch = c.notes?.toLowerCase().contains(q) ?? false;
        final addressMatch = c.address?.toLowerCase().contains(q) ?? false;
        return nameMatch || emailMatch || notesMatch || addressMatch;
      }).toList();
    }

    return customers;
  }

  @override
  Future<Customer> getCustomerById(String id) async {
    final data = await _client
        .from('customers')
        .select('*, profiles(*)')
        .eq('id', id)
        .single();
    return Customer.fromJson(data);
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
  }) async {
    final updatePayload = <String, dynamic>{
      'customer_type': customerType,
      'company_name': customerType == 'company' ? companyName : null,
      'address': address,
      'notes': notes,
    };

    final customerData = await _client
        .from('customers')
        .update(updatePayload)
        .eq('id', id)
        .select('*, profiles(*)')
        .single();

    final customer = Customer.fromJson(customerData);

    if (fullName != null || phone != null) {
      final profilePayload = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) {
        profilePayload['full_name'] = fullName.trim();
      }
      if (phone != null) {
        profilePayload['phone'] = phone.trim();
      }

      if (profilePayload.isNotEmpty) {
        await _client
            .from('profiles')
            .update(profilePayload)
            .eq('id', customer.profileId);
      }

      return getCustomerById(id);
    }

    return customer;
  }

  @override
  Future<Customer> createCustomer({
    required String profileId,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'profile_id': profileId,
      'customer_type': customerType,
    };
    if (customerType == 'company' && companyName != null) {
      payload['company_name'] = companyName;
    }
    if (address != null) {
      payload['address'] = address;
    }
    if (notes != null) {
      payload['notes'] = notes;
    }

    final data = await _client
        .from('customers')
        .insert(payload)
        .select('*, profiles(*)')
        .single();

    return Customer.fromJson(data);
  }

  @override
  Future<Customer?> getCurrentCustomer() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _client
        .from('customers')
        .select('*, profiles(*)')
        .eq('profile_id', uid)
        .maybeSingle();
    if (data == null) return null;
    return Customer.fromJson(data);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }
}
