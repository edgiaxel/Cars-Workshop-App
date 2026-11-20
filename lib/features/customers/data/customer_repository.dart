import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../app/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? query});
  Future<Customer?> getCustomerById(String id);
  Future<Customer?> getCustomerByProfileId(String profileId);
  Future<Customer> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String customerType = 'individual',
    bool isGuest = false,
    String? profileId,
  });
  Future<Customer> updateCustomer(Customer customer);
}

class SupabaseCustomerRepository implements CustomerRepository {
  supa.SupabaseClient get _client => supa.Supabase.instance.client;

  @override
  Future<List<Customer>> getCustomers({String? query}) async {
    if (!AppConfig.isSupabaseConfigured) return [];

    try {
      var queryBuilder = _client.from('customers').select();
      if (query != null && query.trim().isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'name.ilike.%${query.trim()}%,phone.ilike.%${query.trim()}%,email.ilike.%${query.trim()}%',
        );
      }

      final data = await queryBuilder.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch customers: $e');
    }
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    if (!AppConfig.isSupabaseConfigured) return null;

    try {
      final data = await _client
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to fetch customer: $e');
    }
  }

  @override
  Future<Customer?> getCustomerByProfileId(String profileId) async {
    if (!AppConfig.isSupabaseConfigured) return null;

    try {
      final data = await _client
          .from('customers')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to fetch customer by profile: $e');
    }
  }

  @override
  Future<Customer> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String customerType = 'individual',
    bool isGuest = false,
    String? profileId,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const DatabaseException('Supabase not configured');
    }

    try {
      final payload = {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'address': address?.trim(),
        'customer_type': customerType,
        'is_guest': isGuest,
        'profile_id': profileId,
      };

      final data = await _client
          .from('customers')
          .insert(payload)
          .select()
          .single();

      return Customer.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to create customer: $e');
    }
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const DatabaseException('Supabase not configured');
    }

    try {
      final data = await _client
          .from('customers')
          .update(customer.toJson())
          .eq('id', customer.id)
          .select()
          .single();

      return Customer.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to update customer: $e');
    }
  }
}
