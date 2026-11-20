import 'package:pitmate/core/errors/app_exception.dart';
import '../models/e2e_customer.dart';
import '../fixtures/seed_fixtures.dart';

/// Test fake for CustomerRepository matching PROJECT.md interface contract.
class FakeCustomerRepository {
  final List<Customer> _customers = [];

  FakeCustomerRepository({List<Customer>? initialCustomers}) {
    if (initialCustomers != null) {
      _customers.addAll(initialCustomers);
    } else {
      _customers.addAll([
        SeedFixtures.registeredCustomer,
        SeedFixtures.guestCustomer,
      ]);
    }
  }

  List<Customer> get snapshot => List.unmodifiable(_customers);

  Future<List<Customer>> getCustomers({
    String? search,
    bool? isGuest,
  }) async {
    return _customers.where((c) {
      if (isGuest != null && c.isGuest != isGuest) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesPhone = c.phone.toLowerCase().contains(query);
        final matchesEmail = (c.email ?? '').toLowerCase().contains(query);
        return matchesName || matchesPhone || matchesEmail;
      }
      return true;
    }).toList();
  }

  Future<Customer> getCustomerById(String id) async {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      throw NotFoundException('Customer with id "$id" not found.');
    }
  }

  Future<Customer?> getCustomerByProfileId(String profileId) async {
    for (final c in _customers) {
      if (c.profileId == profileId) {
        return c;
      }
    }
    return null;
  }

  Future<Customer> createCustomer(Customer customer) async {
    final trimmedName = customer.name.trim();
    final trimmedPhone = customer.phone.trim();

    if (trimmedName.isEmpty) {
      throw const ValidationException('Customer name cannot be empty.');
    }
    if (trimmedPhone.isEmpty) {
      throw const ValidationException('Customer phone cannot be empty.');
    }
    if (customer.email != null && customer.email!.trim().isNotEmpty) {
      final email = customer.email!.trim();
      if (!email.contains('@') || !email.contains('.')) {
        throw const ValidationException('Invalid email format.');
      }
    }

    final newCustomer = customer.copyWith(
      id: customer.id.isEmpty
          ? 'cust-${DateTime.now().millisecondsSinceEpoch}'
          : customer.id,
      name: trimmedName,
      phone: trimmedPhone,
      email: customer.email?.trim(),
    );

    _customers.add(newCustomer);
    return newCustomer;
  }

  Future<Customer> linkProfileToCustomer(String customerId, String profileId) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) {
      throw NotFoundException('Customer with id "$customerId" not found.');
    }

    final updated = _customers[index].copyWith(
      profileId: profileId,
      isGuest: false,
    );
    _customers[index] = updated;
    return updated;
  }
}
