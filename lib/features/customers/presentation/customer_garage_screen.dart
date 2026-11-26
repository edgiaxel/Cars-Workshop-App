import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/customers/models/customer_vehicle.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Customer Garage screen displaying registered vehicles and live fleet summary.
class CustomerGarageScreen extends ConsumerStatefulWidget {
  const CustomerGarageScreen({
    super.key,
    this.initialVehicles,
    this.onAddVehicleOverride,
  });

  final List<CustomerVehicle>? initialVehicles;
  final Future<void> Function(CustomerVehicle vehicle)? onAddVehicleOverride;

  @override
  ConsumerState<CustomerGarageScreen> createState() =>
      _CustomerGarageScreenState();
}

class _CustomerGarageScreenState extends ConsumerState<CustomerGarageScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _customerRecordId;
  String? _customerName;
  String _customerSubtitle = 'Verified Member';

  int _activeOrdersCount = 0;
  int _upcomingRemindersCount = 0;
  int _settledInvoicesCount = 0;
  List<CustomerVehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicles != null) {
      _vehicles = List.from(widget.initialVehicles!);
    } else {
      _loadVehiclesFromDb();
    }
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  VehicleStatus _mapOrderStatusToVehicleStatus(String orderStatus) {
    switch (orderStatus) {
      case 'estimate_pending':
        return VehicleStatus.awaitingAuth;
      case 'completed':
        return VehicleStatus.passedQC;
      default:
        return VehicleStatus.inWorkshop;
    }
  }

  Future<void> _loadVehiclesFromDb() async {
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
      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _vehicles = [];
            _isLoading = false;
          });
        }
        return;
      }

      final customerData = await client
          .from('customers')
          .select('id, full_name, customer_type, company_name')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (customerData == null) {
        if (mounted) {
          setState(() {
            _vehicles = [];
            _isLoading = false;
          });
        }
        return;
      }

      _customerRecordId = customerData['id'] as String;
      _customerName = (customerData['full_name'] as String?) ??
          (user.userMetadata?['full_name'] as String?);
      final custType = customerData['customer_type'] as String? ?? 'individual';
      final compName = customerData['company_name'] as String?;
      _customerSubtitle = custType == 'company'
          ? (compName != null ? 'Corporate Fleet • $compName' : 'Corporate Fleet Member')
          : 'Individual Customer Member';

      final vehicleRows = await client
          .from('vehicles')
          .select()
          .eq('customer_id', _customerRecordId!)
          .order('created_at', ascending: false);

      final activeOrdersRows = await client
          .from('service_orders')
          .select('id, order_number, status, assigned_bay, vehicle_id')
          .eq('customer_id', _customerRecordId!)
          .not('status', 'in', '("closed","cancelled")');

      final activeOrderByVehicle = <String, Map<String, dynamic>>{};
      for (final row in (activeOrdersRows as List)) {
        final map = row as Map<String, dynamic>;
        final vid = map['vehicle_id'] as String?;
        if (vid != null) {
          activeOrderByVehicle[vid] = map;
        }
      }

      final remindersRows = await client
          .from('maintenance_reminders')
          .select('id')
          .eq('customer_id', _customerRecordId!)
          .inFilter('status', ['pending', 'notified']);

      final settledInvoiceRows = await client
          .from('invoices')
          .select('id')
          .eq('customer_id', _customerRecordId!)
          .eq('status', 'paid');

      final loaded = (vehicleRows as List).map((row) {
        final vid = row['id'] as String;
        final activeOrder = activeOrderByVehicle[vid];
        final orderStatus = activeOrder?['status'] as String?;

        return CustomerVehicle(
          id: vid,
          make: (row['make'] as String?) ?? 'Vehicle',
          model: (row['model'] as String?) ?? '',
          year: (row['year'] as int?) ?? DateTime.now().year,
          licensePlate: (row['license_plate'] as String?) ?? '',
          mileageKm: (row['mileage'] as int?) ?? 0,
          trim: (row['engine_type'] as String?) ??
              (row['transmission'] as String?) ??
              'Standard',
          colorName: (row['color'] as String?) ?? 'Standard',
          status: orderStatus != null
              ? _mapOrderStatusToVehicleStatus(orderStatus)
              : VehicleStatus.ready,
          activeServiceOrderId: activeOrder?['order_number'] as String?,
          bayAssignment: activeOrder?['assigned_bay'] as String?,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _vehicles = loaded;
          _activeOrdersCount = (activeOrdersRows).length;
          _upcomingRemindersCount = (remindersRows as List).length;
          _settledInvoicesCount = (settledInvoiceRows as List).length;
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

  Future<void> _saveNewVehicle(CustomerVehicle newVehicle) async {
    if (widget.onAddVehicleOverride != null) {
      await widget.onAddVehicleOverride!(newVehicle);
      if (mounted) {
        setState(() {
          _vehicles.insert(0, newVehicle);
        });
      }
      return;
    }

    final client = _tryGetClient();
    if (client == null) {
      throw Exception('Database connection is unavailable.');
    }

    if (_customerRecordId == null) {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Please sign in again before registering a vehicle.');
      }
      final cust = await client
          .from('customers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();
      _customerRecordId = cust?['id'] as String?;
    }

    if (_customerRecordId == null) {
      throw Exception('Customer account record was not found.');
    }

    await client.from('vehicles').insert({
      'customer_id': _customerRecordId,
      'license_plate': newVehicle.licensePlate,
      'make': newVehicle.make,
      'model': newVehicle.model,
      'year': newVehicle.year,
      'mileage': newVehicle.mileageKm,
      'color': newVehicle.colorName.isEmpty ? null : newVehicle.colorName,
      'engine_type': newVehicle.trim.isEmpty ? null : newVehicle.trim,
      'notes': 'Registered via Customer Garage',
    });

    await _loadVehiclesFromDb();
  }

  void _openAddVehicleSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _AddVehicleSheet(
          existingPlates: _vehicles.map((v) => v.licensePlate).toList(),
          onVehicleAdded: (newVehicle) async {
            await _saveNewVehicle(newVehicle);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${newVehicle.displayName} [${newVehicle.licensePlate}] added to garage.',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;
    final auth = ref.watch(authNotifierProvider);
    final displayName = auth is AuthAuthenticated
        ? auth.userProfile.fullName
        : (_customerName ?? 'User');

    return ResponsiveRoleScaffold(
      roleTitle: 'Customer Garage',
      userName: displayName,
      userSubtitle: _customerSubtitle,
      currentIndex: 0,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.customerNavItems,
        i,
        currentIndex: 0,
      ),
      navItems: RoleNavigation.customerNavItems,
      telemetryNotice: 'CONNECTED TO PITMATE CLOUD',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _loadVehiclesFromDb,
          tooltip: 'Refresh Garage',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQuickActionCards(isDark),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  PitCard(
                    accentBorderLeft: AppColors.danger,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall(color: AppColors.danger),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadVehiclesFromDb,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'MY VEHICLES',
                          style: AppTypography.headlineSmall(
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
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
                            '${_vehicles.length}',
                            style: AppTypography.telemetrySmall(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: const Key('add-vehicle-button'),
                      onPressed: _openAddVehicleSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('ADD VEHICLE'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentRed,
                      ),
                    ),
                  )
                else if (_vehicles.isEmpty)
                  PitCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 44,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No vehicles registered in your garage yet.',
                            style: AppTypography.bodyMedium(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openAddVehicleSheet,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('REGISTER FIRST VEHICLE'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._vehicles.map(
                    (vehicle) => _buildVehicleCard(vehicle, isDark),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCards(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 480;
        final count = isSmall ? 2 : 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionItem(
              icon: Icons.speed,
              title: 'Active Bay Work',
              subtitle: _activeOrdersCount == 0
                  ? '0 Active'
                  : '$_activeOrdersCount In Progress',
              accentColor: AppColors.accentRed,
              isDark: isDark,
              width: (constraints.maxWidth - (count - 1) * 12) / count,
            ),
            _buildActionItem(
              icon: Icons.calendar_today,
              title: 'Reminders',
              subtitle: '$_upcomingRemindersCount Scheduled',
              accentColor: AppColors.warning,
              isDark: isDark,
              width: (constraints.maxWidth - (count - 1) * 12) / count,
            ),
            _buildActionItem(
              icon: Icons.receipt,
              title: 'Past Invoices',
              subtitle: '$_settledInvoicesCount Settled',
              accentColor: AppColors.success,
              isDark: isDark,
              width: (constraints.maxWidth - (count - 1) * 12) / count,
            ),
            _buildActionItem(
              icon: Icons.health_and_safety_outlined,
              title: 'Registered Fleet',
              subtitle: '${_vehicles.length} Vehicle${_vehicles.length == 1 ? '' : 's'}',
              accentColor: AppColors.info,
              isDark: isDark,
              width: (constraints.maxWidth - (count - 1) * 12) / count,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: PitCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: AppSpacing.roundedSmall,
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.labelMedium(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.graphitePrimary,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textSecondaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(CustomerVehicle vehicle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: PitCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    borderRadius: AppSpacing.roundedMedium,
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_car,
                      color: AppColors.accentRed,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.displayName,
                              style: AppTypography.headlineSmall(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.graphitePrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.plateBackground,
                              borderRadius: AppSpacing.roundedSmall,
                              border: Border.all(
                                color: AppColors.borderStrongDark,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              vehicle.licensePlate,
                              style: AppTypography.telemetrySmall(
                                color: AppColors.plateText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicle.specsSubtitle,
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildStatusBadge(vehicle),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.speed,
                                size: 14,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${vehicle.mileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} km',
                                style: AppTypography.telemetrySmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          if (vehicle.activeServiceOrderId != null)
                            Text(
                              vehicle.activeServiceOrderId!,
                              style: AppTypography.telemetrySmall(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicle.bayAssignment != null
                      ? 'Assigned: ${vehicle.bayAssignment}'
                      : 'No active shop bay',
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                TextButton.icon(
                  key: Key('vehicle-action-btn-${vehicle.id}'),
                  onPressed: () {
                    if (vehicle.activeServiceOrderId != null) {
                      context.go(RoutePaths.customerTracking);
                    } else {
                      context.go('${RoutePaths.bookService}?vehicleId=${vehicle.id}');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(
                    vehicle.activeServiceOrderId != null
                        ? 'TRACK SERVICE'
                        : 'BOOK SERVICE',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CustomerVehicle vehicle) {
    switch (vehicle.status) {
      case VehicleStatus.inWorkshop:
        return StatusBadge.info(
          'IN WORKSHOP (${vehicle.bayAssignment ?? "BAY"})',
          icon: Icons.build,
        );
      case VehicleStatus.passedQC:
        return StatusBadge.success(
          'PASSED QC',
          icon: Icons.check_circle,
        );
      case VehicleStatus.ready:
        return StatusBadge.success(
          'READY',
          icon: Icons.check_circle,
        );
      case VehicleStatus.serviceDue:
        return StatusBadge.warning('SERVICE DUE', icon: Icons.schedule);
      case VehicleStatus.awaitingAuth:
        return StatusBadge.warning('AWAITING AUTH', icon: Icons.pending);
    }
  }
}

/// Bottom sheet modal for registering a new customer vehicle.
class _AddVehicleSheet extends StatefulWidget {
  const _AddVehicleSheet({
    required this.existingPlates,
    required this.onVehicleAdded,
  });

  final List<String> existingPlates;
  final Future<void> Function(CustomerVehicle) onVehicleAdded;

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _trimController = TextEditingController();
  final _colorController = TextEditingController();

  bool _isDuplicate = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _plateController.addListener(_checkDuplicatePlate);
  }

  @override
  void dispose() {
    _plateController.removeListener(_checkDuplicatePlate);
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _trimController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String _normalizePlate(String text) {
    return text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _checkDuplicatePlate() {
    final current = _normalizePlate(_plateController.text);
    if (current.isEmpty) {
      if (_isDuplicate) setState(() => _isDuplicate = false);
      return;
    }

    final exists = widget.existingPlates.any(
      (p) => _normalizePlate(p) == current,
    );

    if (exists != _isDuplicate) {
      setState(() => _isDuplicate = exists);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isDuplicate || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final normalizedPlate = _normalizePlate(_plateController.text);
    final vehicle = CustomerVehicle(
      id: 'v-${DateTime.now().millisecondsSinceEpoch}',
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
      licensePlate: normalizedPlate,
      mileageKm: int.tryParse(_mileageController.text.trim()) ?? 0,
      trim: _trimController.text.trim(),
      colorName: _colorController.text.trim(),
      status: VehicleStatus.ready,
    );

    try {
      await widget.onVehicleAdded(vehicle);
      if (mounted) {
        Navigator.of(context).pop();
      }
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
                    'ADD VEHICLE TO GARAGE',
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
              const SizedBox(height: 16),

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

              TextFormField(
                key: const Key('vehicle-plate-input'),
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  _UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'License Plate (e.g. B 1234 XYZ)',
                  hintText: 'B 1234 PM',
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                  ),
                  suffixIcon: _isDuplicate
                      ? const Icon(Icons.warning_amber, color: AppColors.danger)
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'License plate is required';
                  }
                  if (_isDuplicate) {
                    return 'This plate is already registered in PitMate registry';
                  }
                  return null;
                },
              ),

              if (_isDuplicate) ...[
                const SizedBox(height: 8),
                Container(
                  key: const Key('duplicate-plate-warning'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.roundedSmall,
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DUPLICATE WARNING: Vehicle with plate "${_normalizePlate(_plateController.text)}" already exists in PitMate.',
                          style: AppTypography.telemetrySmall(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('vehicle-make-input'),
                      controller: _makeController,
                      decoration: const InputDecoration(
                        labelText: 'Make',
                        hintText: 'Honda',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Make required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('vehicle-model-input'),
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'Civic RS',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Model required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('vehicle-year-input'),
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        hintText: '2024',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Year required';
                        }
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 1950 || parsed > DateTime.now().year + 2) {
                          return 'Valid year required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('vehicle-mileage-input'),
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Mileage (km)',
                        hintText: '15000',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Mileage required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('vehicle-trim-input'),
                      controller: _trimController,
                      decoration: const InputDecoration(
                        labelText: 'Engine / Trim',
                        hintText: '1.5L Turbo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('vehicle-color-input'),
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        hintText: 'Platinum White',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                key: const Key('submit-add-vehicle-button'),
                onPressed: (_isDuplicate || _isSubmitting) ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('REGISTER VEHICLE TO GARAGE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
