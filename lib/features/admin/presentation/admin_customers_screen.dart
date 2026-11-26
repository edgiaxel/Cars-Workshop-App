import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/admin/presentation/widgets/customer_intake_modal.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CustomerType { registered, guest }

class AdminCustomerEntry {
  const AdminCustomerEntry({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.customerType,
    this.accountTier = 'individual',
    this.companyName,
    required this.vehicles,
    required this.totalVisits,
    required this.lastVisitDate,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final CustomerType customerType;
  final String accountTier;
  final String? companyName;
  final List<String> vehicles;
  final int totalVisits;
  final String lastVisitDate;
}

/// Admin Customers Screen connected live to Supabase.
class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({
    super.key,
    this.initialCustomers,
    this.onAddCustomerOverride,
  });

  final List<AdminCustomerEntry>? initialCustomers;
  final Future<AdminCustomerEntry> Function(Map<String, dynamic> payload)?
      onAddCustomerOverride;

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  String _searchQuery = '';
  CustomerType? _filterType;
  bool _isLoading = false;
  String? _errorMessage;
  List<AdminCustomerEntry> _customers = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomers != null) {
      _customers = List.from(widget.initialCustomers!);
    } else {
      _loadCustomersFromDb();
    }
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCustomersFromDb() async {
    final client = _tryGetClient();
    if (client == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await client
          .from('customers')
          .select('*, vehicles(license_plate), service_orders(id)')
          .order('created_at', ascending: false);

      final mapped = (data as List).map((row) {
        final vehiclesList = (row['vehicles'] as List? ?? [])
            .map((v) => (v['license_plate'] as String?) ?? '')
            .where((p) => p.isNotEmpty)
            .toList();

        final orderCount = (row['service_orders'] as List? ?? []).length;
        final isGuest = (row['is_guest'] as bool?) ?? false;
        final custTypeStr = (row['customer_type'] as String?) ?? 'individual';

        return AdminCustomerEntry(
          id: row['id'] as String,
          fullName: (row['full_name'] as String?) ?? 'Unnamed Customer',
          phoneNumber: (row['phone_number'] as String?) ?? '-',
          email: (row['email'] as String?) ?? (isGuest ? 'Walk-in Guest' : '-'),
          customerType: isGuest ? CustomerType.guest : CustomerType.registered,
          accountTier: custTypeStr,
          companyName: row['company_name'] as String?,
          vehicles: vehiclesList,
          totalVisits: orderCount,
          lastVisitDate: orderCount == 0
              ? 'No visits yet'
              : '$orderCount service order${orderCount == 1 ? '' : 's'}',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _customers = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _openCustomerIntakeModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _AdminNewCustomerSheet(
          onAddCustomerOverride: widget.onAddCustomerOverride,
          onCustomerAdded: (newCustomer) {
            setState(() {
              _customers = [newCustomer, ..._customers];
            });
            if (widget.onAddCustomerOverride == null) {
              _loadCustomersFromDb();
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Customer "${newCustomer.fullName}" saved.',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _openServiceOrderIntakeForCustomer(AdminCustomerEntry customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerIntakeModal(
        initialCustomerId: customer.id,
        onIntakeCompleted: (_) {
          _loadCustomersFromDb();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    final filtered = _customers.where((c) {
      if (_filterType != null && c.customerType != _filterType) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.fullName.toLowerCase().contains(q) ||
          c.phoneNumber.contains(q) ||
          (c.companyName?.toLowerCase().contains(q) ?? false) ||
          c.vehicles.any((v) => v.toLowerCase().contains(q));
    }).toList();

    final registeredCount = _customers
        .where((c) => c.customerType == CustomerType.registered)
        .length;
    final guestCount = _customers
        .where((c) => c.customerType == CustomerType.guest)
        .length;

    return ResponsiveRoleScaffold(
      roleTitle: 'Customer Registry',
      userName: userName,
      userSubtitle: 'Workshop Director',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.admin),
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      currentIndex: 1,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.adminNavItems,
        i,
        currentIndex: 1,
      ),
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: 'DISPATCH TELEMETRY ACTIVE',
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _loadCustomersFromDb,
          tooltip: 'Refresh Registry',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  PitCard(
                    accentBorderLeft: AppColors.danger,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall(color: AppColors.danger),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadCustomersFromDb,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final totalCard = PitCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL IN REGISTRY',
                            style: AppTypography.labelSmall(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_customers.length}',
                            style: AppTypography.displayMedium(
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    );

                    final regCard = PitCard(
                      padding: const EdgeInsets.all(12),
                      accentBorderLeft: AppColors.success,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REGISTERED CLIENTS',
                            style: AppTypography.labelSmall(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$registeredCount',
                            style: AppTypography.displayMedium(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );

                    final guestCard = PitCard(
                      padding: const EdgeInsets.all(12),
                      accentBorderLeft: AppColors.warning,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WALK-IN GUESTS',
                            style: AppTypography.labelSmall(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$guestCount',
                            style: AppTypography.displayMedium(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: regCard),
                              const SizedBox(width: 10),
                              Expanded(child: guestCard),
                            ],
                          ),
                          const SizedBox(height: 10),
                          totalCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: totalCard),
                        const SizedBox(width: 12),
                        Expanded(child: regCard),
                        const SizedBox(width: 12),
                        Expanded(child: guestCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 500;
                    final searchField = TextFormField(
                      key: const Key('admin-customer-search-input'),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText:
                            'Search by client name, company, phone, plate...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    );

                    final addBtn = ElevatedButton.icon(
                      key: const Key('new-customer-button'),
                      onPressed: _openCustomerIntakeModal,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('NEW CUSTOMER'),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 10),
                          addBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        addBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Customers'),
                      selected: _filterType == null,
                      onSelected: (_) => setState(() => _filterType = null),
                    ),
                    FilterChip(
                      label: const Text('Registered Only'),
                      selected: _filterType == CustomerType.registered,
                      onSelected: (_) =>
                          setState(() => _filterType = CustomerType.registered),
                    ),
                    FilterChip(
                      label: const Text('Guest Walk-ins'),
                      selected: _filterType == CustomerType.guest,
                      onSelected: (_) =>
                          setState(() => _filterType = CustomerType.guest),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentRed,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  PitCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 40,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _customers.isEmpty
                                ? 'No customers in the registry yet.'
                                : 'No customers match the current query.',
                            style: AppTypography.bodyMedium(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      return _buildCustomerRowCard(customer, isDark, textColor);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerRowCard(
    AdminCustomerEntry customer,
    bool isDark,
    Color textColor,
  ) {
    final isRegistered = customer.customerType == CustomerType.registered;
    final isCompany = customer.accountTier == 'company';

    return PitCard(
      accentBorderLeft: isCompany
          ? AppColors.info
          : (isRegistered ? AppColors.success : AppColors.warning),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 550;

          final avatar = CircleAvatar(
            radius: 20,
            backgroundColor: isCompany
                ? AppColors.info.withValues(alpha: 0.2)
                : (isRegistered
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.warning.withValues(alpha: 0.2)),
            child: Icon(
              isCompany
                  ? Icons.business
                  : (isRegistered
                      ? Icons.verified_user
                      : Icons.person_outline),
              size: 20,
              color: isCompany
                  ? AppColors.info
                  : (isRegistered ? AppColors.success : AppColors.warning),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    customer.fullName,
                    style: AppTypography.headlineSmall(
                      color: textColor,
                    ),
                  ),
                  if (isCompany)
                    StatusBadge.info(customer.companyName ?? 'COMPANY')
                  else if (isRegistered)
                    StatusBadge.success('REGISTERED CUSTOMER')
                  else
                    StatusBadge.warning('GUEST CUSTOMER'),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phoneNumber,
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.email,
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          final actionBtn = OutlinedButton(
            key: Key('intake-so-btn-${customer.id}'),
            onPressed: () => _openServiceOrderIntakeForCustomer(customer),
            child: const Text('INTAKE SO'),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: actionBtn,
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                    actionBtn,
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'FLEET VEHICLES:',
                      style: AppTypography.telemetrySmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (customer.vehicles.isEmpty)
                    Text(
                      'No vehicles registered',
                      style: AppTypography.bodySmall(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    )
                  else
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: customer.vehicles.map((plate) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceElevatedDark
                                  : AppColors.surfaceElevatedLight,
                              borderRadius: AppSpacing.roundedSmall,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Text(
                              plate,
                              style: AppTypography.telemetrySmall(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.graphitePrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Admin New Customer Sheet supporting Walk-in Guest OR Manual Customer Registration.
class _AdminNewCustomerSheet extends StatefulWidget {
  const _AdminNewCustomerSheet({
    required this.onCustomerAdded,
    this.onAddCustomerOverride,
  });

  final ValueChanged<AdminCustomerEntry> onCustomerAdded;
  final Future<AdminCustomerEntry> Function(Map<String, dynamic> payload)?
      onAddCustomerOverride;

  @override
  State<_AdminNewCustomerSheet> createState() => _AdminNewCustomerSheetState();
}

class _AdminNewCustomerSheetState extends State<_AdminNewCustomerSheet> {
  final _formKey = GlobalKey<FormState>();

  int _intakeMode = 0;
  bool _isSubmitting = false;
  String? _submitError;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _companyNameController = TextEditingController();
  String _customerType = 'individual';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final plate = _plateController.text.trim().toUpperCase();
    final isGuest = _intakeMode == 0;
    final custType = isGuest ? 'individual' : _customerType;
    final compName = (!isGuest && custType == 'company')
        ? _companyNameController.text.trim()
        : null;

    try {
      if (widget.onAddCustomerOverride != null) {
        final created = await widget.onAddCustomerOverride!({
          'full_name': name,
          'phone_number': phone,
          'email': email,
          'customer_type': custType,
          'company_name': compName,
          'is_guest': isGuest,
          'license_plate': plate,
          'make': _makeController.text.trim(),
          'model': _modelController.text.trim(),
        });
        widget.onCustomerAdded(created);
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final client = Supabase.instance.client;
      final customerInsert = await client
          .from('customers')
          .insert({
            'full_name': name,
            'phone_number': phone,
            'email': email.isNotEmpty ? email : null,
            'customer_type': custType,
            'company_name': compName,
            'is_guest': isGuest,
          })
          .select()
          .single();

      final customerId = customerInsert['id'] as String;

      if (plate.isNotEmpty) {
        await client.from('vehicles').insert({
          'customer_id': customerId,
          'license_plate': plate,
          'make': _makeController.text.trim().isNotEmpty
              ? _makeController.text.trim()
              : 'Vehicle',
          'model': _modelController.text.trim().isNotEmpty
              ? _modelController.text.trim()
              : 'Standard',
          'year': int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
          'mileage': int.tryParse(_mileageController.text.trim()) ?? 0,
          'notes': isGuest ? 'Walk-in Intake' : 'Admin Registered Customer',
        });
      }

      final newEntry = AdminCustomerEntry(
        id: customerId,
        fullName: name,
        phoneNumber: phone,
        email: email.isNotEmpty ? email : (isGuest ? 'Walk-in Guest' : '-'),
        customerType: isGuest ? CustomerType.guest : CustomerType.registered,
        accountTier: custType,
        companyName: compName,
        vehicles: plate.isNotEmpty ? [plate] : [],
        totalVisits: 0,
        lastVisitDate: 'No visits yet',
      );

      widget.onCustomerAdded(newEntry);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _intakeMode == 0
                        ? 'WALK-IN GUEST INTAKE'
                        : 'MANUAL CUSTOMER REGISTRATION',
                    style: AppTypography.headlineSmall(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.graphitePrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_submitError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.roundedSmall,
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _submitError!,
                    style: AppTypography.bodySmall(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Walk-in Guest'),
                    icon: Icon(Icons.directions_walk),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Register Customer'),
                    icon: Icon(Icons.how_to_reg),
                  ),
                ],
                selected: {_intakeMode},
                onSelectionChanged: (val) {
                  setState(() => _intakeMode = val.first);
                },
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _intakeMode == 0
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.info.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: _intakeMode == 0
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _intakeMode == 0
                      ? 'Walk-in guest intake is permitted for individual private customers. Corporate accounts must be registered.'
                      : 'Admin manual registration adds a customer directly to the system (individual or company fleet).',
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.graphitePrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_intakeMode == 1) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Individual Account'),
                        selected: _customerType == 'individual',
                        onSelected: (_) =>
                            setState(() => _customerType = 'individual'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Company / Fleet'),
                        selected: _customerType == 'company',
                        onSelected: (_) =>
                            setState(() => _customerType = 'company'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_customerType == 'company') ...[
                  TextFormField(
                    controller: _companyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Company / Fleet Name',
                      hintText: 'e.g. Aston Martin Racing',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Company name required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
              ],

              TextFormField(
                key: const Key('guest-name-input'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _intakeMode == 1 && _customerType == 'company'
                      ? 'Contact Person Name'
                      : 'Customer Full Name',
                  hintText: 'e.g. Budi Santoso',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                key: const Key('guest-phone-input'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+6281234567890',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Phone number is required'
                    : null,
              ),
              const SizedBox(height: 14),

              if (_intakeMode == 1) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'client@company.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@')) return 'Valid email required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              Text(
                'INITIAL VEHICLE INTAKE',
                style: AppTypography.labelMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                key: const Key('guest-plate-input'),
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  TextInputFormatter.withFunction(
                    (oldVal, newVal) => TextEditingValue(
                      text: newVal.text.toUpperCase(),
                      selection: newVal.selection,
                    ),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'License Plate (e.g. B 1234 XYZ)',
                  hintText: 'B 1234 XYZ',
                  prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
                ),
                validator: (val) {
                  if (_intakeMode == 0 && (val == null || val.trim().isEmpty)) {
                    return 'Vehicle plate required for walk-in intake';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(
                        labelText: 'Make',
                        hintText: 'Honda',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'Civic RS',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                key: const Key('submit-guest-intake-button'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _intakeMode == 0
                            ? 'CREATE WALK-IN GUEST RECORD'
                            : 'REGISTER CUSTOMER RECORD',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
