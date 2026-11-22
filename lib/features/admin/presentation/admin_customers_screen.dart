import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

enum CustomerType {
  registered,
  guest,
}

class AdminCustomerEntry {
  const AdminCustomerEntry({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.customerType,
    required this.vehicles,
    required this.totalVisits,
    required this.lastVisitDate,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final CustomerType customerType;
  final List<String> vehicles; // License plates
  final int totalVisits;
  final String lastVisitDate;
}

/// Admin Customers Screen:
/// - List customers with badges for "Registered Customer" vs "Guest Customer"
/// - Search by name, phone, or plate
/// - "New Customer" button supporting walk-in guest intake (name, phone, vehicle plate)
class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  int _navIndex = 1; // "Customers" item
  String _searchQuery = '';
  CustomerType? _filterType;

  final List<AdminCustomerEntry> _customers = [
    const AdminCustomerEntry(
      id: 'cust-1',
      fullName: 'Alex Pratama',
      phoneNumber: '+62 811-9234-889',
      email: 'alex.pratama@gtmail.com',
      customerType: CustomerType.registered,
      vehicles: ['B 2044 RFS', 'B 9912 SPO'],
      totalVisits: 8,
      lastVisitDate: 'Today (Active SO-0143)',
    ),
    const AdminCustomerEntry(
      id: 'cust-2',
      fullName: 'Bambang Soediro (Walk-in)',
      phoneNumber: '+62 812-8800-4321',
      email: 'bambang.guest@pitmate.local',
      customerType: CustomerType.guest,
      vehicles: ['B 3021 RFS'],
      totalVisits: 1,
      lastVisitDate: 'Today (Walk-in Intake)',
    ),
    const AdminCustomerEntry(
      id: 'cust-3',
      fullName: 'Rian Hidayat',
      phoneNumber: '+62 813-1122-3344',
      email: 'rian.h@motorsport.id',
      customerType: CustomerType.registered,
      vehicles: ['B 1555 ZT'],
      totalVisits: 12,
      lastVisitDate: 'Yesterday',
    ),
    const AdminCustomerEntry(
      id: 'cust-4',
      fullName: 'Hendra Wijaya (Guest)',
      phoneNumber: '+62 818-4567-9901',
      email: 'walkin-4567@pitmate.guest',
      customerType: CustomerType.guest,
      vehicles: ['D 1808 AC'],
      totalVisits: 1,
      lastVisitDate: '3 days ago',
    ),
  ];

  static const List<RoleNavItem> _adminNavItems = [
    RoleNavItem(label: 'Workshop Overview', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    RoleNavItem(label: 'Customers & Fleet', icon: Icons.people_outline, selectedIcon: Icons.people),
    RoleNavItem(label: 'Service Orders', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, badge: '4'),
    RoleNavItem(label: 'Bay Schedule', icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
    RoleNavItem(label: 'Inventory', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2),
  ];

  void _openGuestIntakeModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _WalkInGuestIntakeSheet(
          onCustomerAdded: (newCustomer) {
            setState(() {
              _customers.insert(0, newCustomer);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Walk-in guest "${newCustomer.fullName}" registered with plate ${newCustomer.vehicles.first}.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    final filtered = _customers.where((c) {
      if (_filterType != null && c.customerType != _filterType) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.fullName.toLowerCase().contains(q) ||
          c.phoneNumber.contains(q) ||
          c.vehicles.any((v) => v.toLowerCase().contains(q));
    }).toList();

    final registeredCount = _customers.where((c) => c.customerType == CustomerType.registered).length;
    final guestCount = _customers.where((c) => c.customerType == CustomerType.guest).length;

    return ResponsiveRoleScaffold(
      roleTitle: 'Customer Registry',
      userName: 'Marcus T.',
      userSubtitle: 'Workshop Director',
      currentIndex: _navIndex,
      onNavIndexChanged: (i) => setState(() => _navIndex = i),
      navItems: _adminNavItems,
      telemetryNotice: 'DISPATCH TELEMETRY ACTIVE',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => setState(() {}),
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
                // Top telemetry KPI summary cards
                Row(
                  children: [
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL IN REGISTRY',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_customers.length}',
                              style: AppTypography.displayMedium(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        accentBorderLeft: AppColors.success,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGISTERED CLIENTS',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$registeredCount',
                              style: AppTypography.displayMedium(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        accentBorderLeft: AppColors.warning,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WALK-IN GUESTS',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$guestCount',
                              style: AppTypography.displayMedium(color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search & Filter & New Customer Intake button
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            key: const Key('admin-customer-search-input'),
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search client, phone or plate...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            key: const Key('new-customer-button'),
                            onPressed: _openGuestIntakeModal,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('NEW CUSTOMER / WALK-IN'),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('admin-customer-search-input'),
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search by client name, phone or vehicle plate...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          key: const Key('new-customer-button'),
                          onPressed: _openGuestIntakeModal,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('NEW CUSTOMER / WALK-IN'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Filter chips (All / Registered / Guest)
                Row(
                  children: [
                    _buildFilterChip('All Customers (${_customers.length})', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Registered ($registeredCount)', CustomerType.registered),
                    const SizedBox(width: 8),
                    _buildFilterChip('Walk-in Guests ($guestCount)', CustomerType.guest),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer List
                if (filtered.isEmpty)
                  PitCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No customers found matching filter criteria.',
                        style: AppTypography.bodyMedium(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map((customer) => _buildCustomerCard(customer, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, CustomerType? type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor: AppColors.accentRed,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildCustomerCard(AdminCustomerEntry customer, bool isDark) {
    final isGuest = customer.customerType == CustomerType.guest;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: PitCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isGuest ? AppColors.warning.withValues(alpha: 0.15) : AppColors.accentRed,
                  child: Icon(
                    isGuest ? Icons.person_pin_circle_outlined : Icons.person,
                    color: isGuest ? AppColors.warning : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.fullName,
                              style: AppTypography.labelLarge(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isGuest)
                            StatusBadge.warning('GUEST CUSTOMER', icon: Icons.storefront)
                          else
                            StatusBadge.success('REGISTERED CUSTOMER', icon: Icons.verified_user),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.phoneNumber,
                            style: AppTypography.telemetrySmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.email_outlined,
                            size: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              customer.email,
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),

            // Vehicles & Visit statistics
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VEHICLES: ',
                      style: AppTypography.labelSmall(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...customer.vehicles.map(
                      (plate) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.plateBackground,
                            borderRadius: AppSpacing.roundedSmall,
                            border: Border.all(color: AppColors.borderStrongDark, width: 1),
                          ),
                          child: Text(
                            plate,
                            style: AppTypography.telemetrySmall(
                              color: AppColors.plateText,
                              fontWeight: FontWeight.w700,
                            ).copyWith(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Visits: ${customer.totalVisits} • ${customer.lastVisitDate}',
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Walk-in guest intake modal supporting quick customer intake.
class _WalkInGuestIntakeSheet extends StatefulWidget {
  const _WalkInGuestIntakeSheet({required this.onCustomerAdded});

  final ValueChanged<AdminCustomerEntry> onCustomerAdded;

  @override
  State<_WalkInGuestIntakeSheet> createState() => _WalkInGuestIntakeSheetState();
}

class _WalkInGuestIntakeSheetState extends State<_WalkInGuestIntakeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final normalizedPlate = _plateController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final newEntry = AdminCustomerEntry(
      id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
      fullName: name,
      phoneNumber: phone,
      email: 'walkin-${phone.replaceAll(RegExp(r'\D'), '')}@pitmate.guest',
      customerType: CustomerType.guest,
      vehicles: [normalizedPlate],
      totalVisits: 1,
      lastVisitDate: 'Today (Walk-in Intake)',
    );

    widget.onCustomerAdded(newEntry);
    Navigator.of(context).pop();
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
              // Modal Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WALK-IN GUEST INTAKE',
                    style: AppTypography.headlineSmall(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Creates a walk-in guest record for instant vehicle service order intake without full user app account creation.',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                key: const Key('guest-name-input'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Full Name',
                  hintText: 'Budi Santoso',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 14),

              // Phone Number
              TextFormField(
                key: const Key('guest-phone-input'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+62 812-3456-7890',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 14),

              // License Plate (uppercase auto-formatter)
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
                  labelText: 'Vehicle License Plate',
                  hintText: 'B 1234 XYZ',
                  prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vehicle plate is required' : null,
              ),
              const SizedBox(height: 22),

              // Submit Button
              ElevatedButton(
                key: const Key('submit-guest-intake-button'),
                onPressed: _submit,
                child: const Text('CREATE WALK-IN GUEST RECORD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
