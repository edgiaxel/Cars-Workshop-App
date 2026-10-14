import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/customer.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Customers directory screen for Admin role connected to Supabase data.
class AdminCustomersPage extends ConsumerStatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  ConsumerState<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends ConsumerState<AdminCustomersPage> {
  String _selectedFilter = 'All';

  void _onSearchChanged(String query) {
    ref.read(customersProvider.notifier).setFilter(query: query);
  }

  void _onFilterSelected(String filter) {
    setState(() => _selectedFilter = filter);
    ref.read(customersProvider.notifier).setFilter(type: filter);
  }

  Future<void> _openEditCustomerDialog(Customer customer) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: customer.profile?.fullName ?? '',
    );
    final companyController = TextEditingController(
      text: customer.companyName ?? '',
    );
    final phoneController = TextEditingController(
      text: customer.profile?.phone ?? '',
    );
    final addressController = TextEditingController(
      text: customer.address ?? '',
    );
    final notesController = TextEditingController(text: customer.notes ?? '');
    String customerType = customer.customerType;
    bool isSaving = false;
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.standard,
                right: AppSpacing.standard,
                top: AppSpacing.section,
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppSpacing.section,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EDIT CLIENT RECORD',
                            style: AppTypography.sectionTitle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      if (errorMessage != null) ...[
                        Text(
                          errorMessage!,
                          style: AppTypography.bodySmall(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.compact),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: customerType,
                        decoration: const InputDecoration(
                          labelText: 'Customer Type',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'company',
                            child: Text('Company / Motorsport Team'),
                          ),
                          DropdownMenuItem(
                            value: 'individual',
                            child: Text('Individual Customer'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => customerType = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      if (customerType == 'company') ...[
                        TextFormField(
                          controller: companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company / Team Name *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (val) {
                            if (customerType == 'company' &&
                                (val == null || val.trim().isEmpty)) {
                              return 'Company name is required for corporate clients';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),
                      ],
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person / Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telephone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Physical / Operational Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Operational Notes',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Cancel',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: PrimaryButton(
                              text: isSaving ? 'Saving...' : 'Save Changes',
                              isLoading: isSaving,
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setModalState(() {
                                        isSaving = true;
                                        errorMessage = null;
                                      });
                                      try {
                                        await ref
                                            .read(customersProvider.notifier)
                                            .updateCustomer(
                                              id: customer.id,
                                              customerType: customerType,
                                              companyName: companyController
                                                  .text
                                                  .trim(),
                                              fullName: nameController.text
                                                  .trim(),
                                              phone: phoneController.text
                                                  .trim(),
                                              address: addressController.text
                                                  .trim(),
                                              notes: notesController.text
                                                  .trim(),
                                            );
                                        if (context.mounted) {
                                          Navigator.of(sheetContext).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Customer profile updated successfully.',
                                                  ),
                                                ),
                                              );
                                        }
                                      } catch (err) {
                                        setModalState(() {
                                          isSaving = false;
                                          errorMessage = err.toString();
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'Delete Customer Account',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${customer.displayName}? This action cannot be undone if linked records exist.',
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(customersProvider.notifier).deleteCustomer(customer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer record deleted.')),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Failed to delete: $err'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return AdminShell(
      currentRoute: RoutePaths.adminCustomers,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(customersProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'CUSTOMER DIRECTORY',
                subtitle: 'Active workshop client accounts and motorsport organizations',
              ),
              const SizedBox(height: AppSpacing.compact),
              SearchFilterBar(
                searchHint:
                    'Search customers by name, organization, or email...',
                onSearchChanged: _onSearchChanged,
                filterOptions: const ['All', 'Company', 'Individual'],
                selectedFilter: _selectedFilter,
                onFilterSelected: _onFilterSelected,
              ),
              const SizedBox(height: AppSpacing.section),
              customersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Accessing customer telemetry database...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(customersProvider),
                ),
                data: (customers) {
                  if (customers.isEmpty) {
                    return const EmptyState(
                      title: 'No Customers Found',
                      message: 'No client accounts match the specified search or filter criteria.',
                      icon: Icons.people_outline,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final isCompany = customer.isCompany;

                      return PitCard(
                        technicalLabel:
                            'CLIENT-ID • ${(customer.id.length >= 8 ? customer.id.substring(0, 8) : customer.id).toUpperCase()}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCompany
                                            ? Icons.business
                                            : Icons.person_outline,
                                        color: AppColors.primaryAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.compact),
                                      Expanded(
                                        child: Text(
                                          customer.displayName,
                                          style: AppTypography.sectionTitle(
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    StatusBadge(
                                      label: customer.customerType
                                          .toUpperCase(),
                                      color: isCompany
                                          ? AppColors.info
                                          : AppColors.textSecondary,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                      tooltip: 'Edit customer',
                                      onPressed: () =>
                                          _openEditCustomerDialog(customer),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Delete customer',
                                      onPressed: () =>
                                          _confirmDeleteCustomer(customer),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (customer.notes != null &&
                                customer.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                customer.notes!,
                                style: AppTypography.bodySmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            const Divider(
                              color: AppColors.borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Wrap(
                              spacing: AppSpacing.section,
                              runSpacing: AppSpacing.compact,
                              children: [
                                if (customer.profile?.phone != null &&
                                    customer.profile!.phone!.isNotEmpty)
                                  _buildInfoChip(
                                    Icons.phone_outlined,
                                    customer.profile!.phone!,
                                  ),
                                if (customer.address != null &&
                                    customer.address!.isNotEmpty)
                                  _buildInfoChip(
                                    Icons.location_on_outlined,
                                    customer.address!,
                                  ),
                                if (customer.profile?.fullName != null &&
                                    isCompany)
                                  _buildInfoChip(
                                    Icons.person_pin_outlined,
                                    'Contact: ${customer.profile!.fullName}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.technical(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
