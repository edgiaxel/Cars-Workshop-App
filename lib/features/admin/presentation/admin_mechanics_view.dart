import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/mechanic.dart';
import '../../../shared/providers/mechanic_provider.dart';
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

/// Mechanics roster screen for Admin role connected to real Supabase records.
class AdminMechanicsPage extends ConsumerStatefulWidget {
  const AdminMechanicsPage({super.key});

  @override
  ConsumerState<AdminMechanicsPage> createState() => _AdminMechanicsPageState();
}

class _AdminMechanicsPageState extends ConsumerState<AdminMechanicsPage> {
  String _selectedFilter = 'All';

  void _onSearchChanged(String query) {
    ref.read(mechanicsProvider.notifier).search(query);
  }

  Future<void> _openEditMechanicDialog(Mechanic mechanic) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: mechanic.profile?.fullName ?? '',
    );
    final codeController = TextEditingController(text: mechanic.employeeCode);
    final specController = TextEditingController(
      text: mechanic.specialization ?? '',
    );
    final rateController = TextEditingController(
      text: mechanic.hourlyRate.toInt().toString(),
    );
    final commissionController = TextEditingController(
      text: mechanic.compensationPercentage.toInt().toString(),
    );
    final phoneController = TextEditingController(
      text: mechanic.profile?.phone ?? '',
    );
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
                            'EDIT TECHNICIAN PROFILE',
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
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Employee Code (e.g. MEC-001) *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Employee code is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Technician Full Name *',
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
                        controller: specController,
                        decoration: const InputDecoration(
                          labelText: 'Engineering Specialization *',
                          prefixIcon: Icon(Icons.build_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Specialization is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: rateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Hourly Rate (IDR)',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0) {
                                  return 'Invalid rate';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: TextFormField(
                              controller: commissionController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Commission (%)',
                                prefixIcon: Icon(Icons.percent_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0 || num > 100) {
                                  return '0-100%';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telephone Contact',
                          prefixIcon: Icon(Icons.phone_outlined),
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
                                            .read(mechanicsProvider.notifier)
                                            .updateMechanic(
                                              id: mechanic.id,
                                              employeeCode: codeController.text
                                                  .trim(),
                                              specialization: specController
                                                  .text
                                                  .trim(),
                                              hourlyRate:
                                                  double.tryParse(
                                                    rateController.text.trim(),
                                                  ) ??
                                                  0,
                                              compensationPercentage:
                                                  double.tryParse(
                                                    commissionController.text
                                                        .trim(),
                                                  ) ??
                                                  30,
                                              fullName: nameController.text
                                                  .trim(),
                                              phone: phoneController.text
                                                  .trim(),
                                            );
                                        if (context.mounted) {
                                          Navigator.of(sheetContext).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Technician profile updated successfully.',
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

  Future<void> _confirmDeleteMechanic(Mechanic mechanic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'Remove Technician',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${mechanic.displayName} (${mechanic.employeeCode})? This will restrict service assignments.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(mechanicsProvider.notifier).deleteMechanic(mechanic.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Technician record removed.')),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Failed to remove: $err'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mechanicsAsync = ref.watch(mechanicsProvider);

    return AdminShell(
      currentRoute: RoutePaths.adminMechanics,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(mechanicsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'PIT CREW & MECHANICS',
                subtitle: 'Master technician certifications, assignments, and availability',
              ),
              const SizedBox(height: AppSpacing.compact),
              SearchFilterBar(
                searchHint:
                    'Search technicians by name, code, or specialization...',
                onSearchChanged: _onSearchChanged,
                filterOptions: const ['All', 'Active', 'Lead Technicians'],
                selectedFilter: _selectedFilter,
                onFilterSelected: (f) => setState(() => _selectedFilter = f),
              ),
              const SizedBox(height: AppSpacing.section),
              mechanicsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Accessing technician engineering roster...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(mechanicsProvider),
                ),
                data: (mechanics) {
                  if (mechanics.isEmpty) {
                    return const EmptyState(
                      title: 'No Technicians Found',
                      message: 'No mechanics match the current search or filter criteria.',
                      icon: Icons.engineering_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mechanics.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final mechanic = mechanics[index];

                      return PitCard(
                        technicalLabel:
                            'ENGINEER-ID • ${mechanic.employeeCode}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.engineering,
                                        color: AppColors.primaryAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.compact),
                                      Expanded(
                                        child: Text(
                                          mechanic.displayName,
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
                                      label: mechanic.employeeCode,
                                      color: AppColors.info,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                      tooltip: 'Edit technician',
                                      onPressed: () =>
                                          _openEditMechanicDialog(mechanic),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Remove technician',
                                      onPressed: () =>
                                          _confirmDeleteMechanic(mechanic),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (mechanic.specialization != null &&
                                mechanic.specialization!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                mechanic.specialization!,
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
                                _buildMetricChip(
                                  'HOURLY RATE',
                                  'Rp ${mechanic.hourlyRate.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}/hr',
                                ),
                                _buildMetricChip(
                                  'COMMISSION',
                                  '${mechanic.compensationPercentage.toInt()}%',
                                ),
                                if (mechanic.hireDate != null)
                                  _buildMetricChip(
                                    'HIRED',
                                    "${mechanic.hireDate!.year}-${mechanic.hireDate!.month.toString().padLeft(2, '0')}-${mechanic.hireDate!.day.toString().padLeft(2, '0')}",
                                  ),
                                if (mechanic.profile?.phone != null &&
                                    mechanic.profile!.phone!.isNotEmpty)
                                  _buildMetricChip(
                                    'PHONE',
                                    mechanic.profile!.phone!,
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

  Widget _buildMetricChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.technical(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.metricValue(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
