import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/pit_primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import 'providers/customer_provider.dart';

class AdminCustomersPage extends ConsumerStatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  ConsumerState<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends ConsumerState<AdminCustomersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog({bool isGuest = false}) {
    showDialog(
      context: context,
      builder: (context) => _AddCustomerDialog(isGuest: isGuest),
    ).then((_) => ref.refresh(customerListProvider));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
        actions: [
          IconButton(
            tooltip: 'Add Walk-in Guest',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddCustomerDialog(isGuest: true),
          ),
          IconButton(
            tooltip: 'Add Registered Customer',
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddCustomerDialog(isGuest: false),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: TextField(
              key: const Key('customer_search_input'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingState(message: 'Loading customers...'),
              error: (err, stack) => ErrorState(
                title: 'Failed to Load Customers',
                message: err.toString(),
                onRetry: () => ref.refresh(customerListProvider),
              ),
              data: (customers) {
                final filtered = customers.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  return c.name.toLowerCase().contains(_searchQuery) ||
                      c.phone.toLowerCase().contains(_searchQuery) ||
                      (c.email?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No Customers Found',
                    description: _searchQuery.isEmpty
                        ? 'No customer records yet. Add a walk-in guest or registered customer.'
                        : 'No customers match your search criteria.',
                    actionLabel: 'Add Customer',
                    onAction: () => _showAddCustomerDialog(isGuest: false),
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.paddingMd,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return PitCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: customer.isGuest
                              ? AppColors.warning.withValues(alpha: 0.2)
                              : AppColors.info.withValues(alpha: 0.2),
                          child: Icon(
                            customer.isGuest ? Icons.person_outline : Icons.person,
                            color: customer.isGuest ? AppColors.warning : AppColors.info,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                customer.name,
                                style: AppTypography.headingSmall(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            StatusBadge(
                              label: customer.isGuest ? 'Walk-in Guest' : 'Registered',
                              variant: customer.isGuest
                                  ? StatusBadgeVariant.warning
                                  : StatusBadgeVariant.success,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            Text('Phone: ${customer.phone}', style: AppTypography.bodySmall()),
                            if (customer.email != null)
                              Text('Email: ${customer.email}', style: AppTypography.bodySmall()),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_customer_fab'),
        onPressed: () => _showAddCustomerDialog(isGuest: false),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddCustomerDialog extends ConsumerStatefulWidget {
  final bool isGuest;

  const _AddCustomerDialog({required this.isGuest});

  @override
  ConsumerState<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(customerRepositoryProvider).createCustomer(
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text.isNotEmpty ? _emailController.text : null,
            address: _addressController.text.isNotEmpty ? _addressController.text : null,
            isGuest: widget.isGuest,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isGuest ? 'New Walk-in Guest' : 'New Registered Customer'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(_errorMessage!, style: AppTypography.bodySmall(color: AppColors.error)),
                  ),
                TextFormField(
                  key: const Key('add_customer_name_input'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('add_customer_phone_input'),
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('add_customer_email_input'),
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('add_customer_address_input'),
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address (Optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        PitPrimaryButton(
          key: const Key('save_customer_button'),
          text: 'Save Customer',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
