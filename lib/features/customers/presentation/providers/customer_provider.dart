import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/customers/data/customer_repository.dart';
import 'package:pitmate/features/customers/domain/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository();
});

final customerListProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers();
});

final currentCustomerProfileProvider = FutureProvider.autoDispose.family<Customer?, String>((ref, profileId) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerByProfileId(profileId);
});
