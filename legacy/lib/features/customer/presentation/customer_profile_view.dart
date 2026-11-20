import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'customer_shell.dart';

/// Customer profile view adhering to DESIGN.md and backed by live Supabase data.
class CustomerProfilePage extends ConsumerWidget {
  const CustomerProfilePage({super.key});

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic customer,
    String currentName,
    String? currentPhone,
    String? currentAddress,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');
    final addressCtrl = TextEditingController(text: currentAddress ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'EDIT CUSTOMER PROFILE',
          style: AppTypography.sectionTitle(),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: AppTypography.bodyMedium(),
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: phoneCtrl,
                style: AppTypography.bodyMedium(),
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: addressCtrl,
                style: AppTypography.bodyMedium(),
                decoration: const InputDecoration(labelText: 'Primary Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newAddress = addressCtrl.text.trim();

              if (customer != null) {
                try {
                  await ref.read(customersProvider.notifier).updateCustomer(
                        id: customer.id as String,
                        customerType: customer.customerType as String,
                        companyName: customer.companyName as String?,
                        address: newAddress,
                        notes: customer.notes as String?,
                        fullName: newName,
                        phone: newPhone,
                      );
                  ref.invalidate(currentCustomerProvider);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile details updated successfully.'),
                        backgroundColor: AppColors.statusCompleted,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update profile: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, WidgetRef ref) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'ACCOUNT SECURITY & CREDENTIALS',
          style: AppTypography.sectionTitle(),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                style: AppTypography.bodyMedium(),
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: AppTypography.bodyMedium(),
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPass = newPassCtrl.text;
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              try {
                await ref
                    .read(authSessionProvider.notifier)
                    .updatePassword(newPass);
                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password credentials updated successfully.'),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update credentials: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final profile = authState.profile;
    final customerAsync = ref.watch(currentCustomerProvider);
    final vehiclesAsync = ref.watch(customerVehiclesProvider(null));

    final customer = customerAsync.asData?.value;
    final vehicles = vehiclesAsync.asData?.value ?? [];

    final displayName = customer?.displayName ?? profile?.fullName ?? 'User';
    final email = authState.email ?? 'user@pitmate.co';
    final phone = customer?.profile?.phone ?? profile?.phone ?? '-';
    final address = customer?.address ?? '-';
    final customerType = customer?.customerType ?? 'individual';
    final rawAccountId = customer?.id ?? profile?.id ?? 'cust-001';

    return CustomerShell(
      currentRoute: RoutePaths.customerProfile,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'CUSTOMER ACCOUNT PROFILE',
              subtitle:
                  'Identity, contact details, and workshop garage membership',
            ),
            const SizedBox(height: AppSpacing.compact),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                  onPressed: () => _showEditProfileDialog(
                    context,
                    ref,
                    customer,
                    displayName,
                    phone,
                    address,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAccent,
                    side: const BorderSide(color: AppColors.primaryAccent),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset, size: 16),
                  label: const Text('Security'),
                  onPressed: () => _showSecurityDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderSubtle
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.standard),

            PitCard(
              technicalLabel:
                  'PROFILE TELEMETRY • ${customer?.id != null ? customer!.id.substring(0, 8).toUpperCase() : 'CLIENT'}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surfaceSecondary,
                        child: Text(
                          (displayName.isNotEmpty ? displayName[0] : 'U')
                              .toUpperCase(),
                          style: AppTypography.displayLarge().copyWith(
                            fontSize: 24,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.standard),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.sectionTitle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              email,
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            const StatusBadge(
                              label: 'VERIFIED CLIENT',
                              color: AppColors.statusCompleted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: AppSpacing.standard),
                  _buildAccountIdRow(context, rawAccountId),
                  _buildProfileRow(
                    'Customer Tier',
                    customerType == 'corporate'
                        ? 'Corporate Motorsport Fleet'
                        : 'Individual (Private Owner)',
                  ),
                  _buildProfileRow('Contact Phone', phone),
                  _buildProfileRow('Primary Address', address),
                  _buildProfileRow(
                    'Registered Vehicles',
                    '${vehicles.length} Vehicles in Garage',
                  ),
                  _buildProfileRow(
                    'Workshop Service Tier',
                    'PitMate Priority Client',
                  ),
                  _buildProfileRow('Account Status', 'Active Supabase Session'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountIdRow(BuildContext context, String rawId) {
    final displayId = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ACCOUNT ID',
            style: AppTypography.technical(color: AppColors.textMuted),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayId.toUpperCase(),
                style: AppTypography.technical(color: AppColors.textPrimary),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 14,
                  color: AppColors.primaryAccent,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Copy ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: rawId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account ID copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.technical(color: AppColors.textMuted),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
