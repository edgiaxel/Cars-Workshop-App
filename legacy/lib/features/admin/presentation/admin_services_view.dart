import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/providers/mechanic_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/spare_part_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Workshop service orders view for Admin role backed by live Supabase records.
class AdminServicesPage extends ConsumerStatefulWidget {
  const AdminServicesPage({super.key});

  @override
  ConsumerState<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends ConsumerState<AdminServicesPage> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusFilters = const [
    'All',
    'Requested',
    'Approved',
    'Scheduled',
    'In Progress',
    'Waiting For Parts',
    'Completed',
    'Closed',
    'Cancelled',
  ];

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    ref
        .read(serviceOrdersProvider.notifier)
        .setFilter(query: query, status: _selectedStatus);
  }

  void _onStatusFilterSelected(String status) {
    setState(() => _selectedStatus = status);
    ref
        .read(serviceOrdersProvider.notifier)
        .setFilter(query: _searchQuery, status: status);
  }

  void _openOrderDialog([ServiceOrder? order]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ServiceOrderFormDialog(
        order: order,
        onSave: (payload) async {
          if (order == null) {
            final created = await ref
                .read(serviceOrdersProvider.notifier)
                .createServiceOrder(
                  customerId: payload['customer_id'] as String,
                  vehicleId: payload['vehicle_id'] as String,
                  title: payload['title'] as String,
                  description: payload['description'] as String?,
                  mechanicId: payload['mechanic_id'] as String?,
                  estimatedTotal: payload['estimated_total'] as double? ?? 0.0,
                  odometerKm: payload['odometer_km'] as int?,
                );

            final parts =
                payload['selected_parts'] as List<Map<String, dynamic>>?;
            if (parts != null && parts.isNotEmpty) {
              await ref
                  .read(sparePartsProvider.notifier)
                  .deductPartsForServiceOrder(
                    serviceOrderId: created.id,
                    items: parts,
                  );
            }
          } else {
            await ref
                .read(serviceOrdersProvider.notifier)
                .updateServiceOrder(
                  id: order.id,
                  title: payload['title'] as String?,
                  description: payload['description'] as String?,
                  status: payload['status'] as ServiceStatus?,
                  mechanicId: payload['mechanic_id'] as String?,
                  estimatedTotal: payload['estimated_total'] as double?,
                  odometerKm: payload['odometer_km'] as int?,
                );
          }
        },
      ),
    );
  }

  void _quickStatusUpdate(ServiceOrder order, ServiceStatus newStatus) async {
    try {
      await ref
          .read(serviceOrdersProvider.notifier)
          .updateServiceOrderStatus(id: order.id, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${order.orderNumber} status updated to ${newStatus.label}.',
            ),
            backgroundColor: AppColors.statusCompleted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmDeleteOrder(ServiceOrder order) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Delete Service Order',
          style: AppTypography.sectionTitle(),
        ),
        content: Text(
          'Are you sure you want to permanently delete ticket ${order.orderNumber} (${order.title})?',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(serviceOrdersProvider.notifier)
                    .deleteServiceOrder(order.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Service Order ${order.orderNumber} deleted.',
                      ),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete order: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(serviceOrdersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return AdminShell(
      currentRoute: RoutePaths.adminServices,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'SERVICE ORDERS CONTROL',
              subtitle:
                  'Active workshop job tickets and bay allocation pipeline',
              action: Wrap(
                spacing: AppSpacing.compact,
                runSpacing: AppSpacing.compact,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.alt_route, size: 16),
                    label: const Text('Workshop Queue'),
                    onPressed: () => context.go(RoutePaths.adminQueue),
                  ),
                  PrimaryButton(
                    text: 'Create Order',
                    icon: Icons.add,
                    width: 140,
                    onPressed: () => _openOrderDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            SearchFilterBar(
              searchHint:
                  'Search orders by ticket #, vehicle, or technician...',
              onSearchChanged: _onSearchChanged,
              filterOptions: _statusFilters,
              selectedFilter: _selectedStatus,
              onFilterSelected: _onStatusFilterSelected,
            ),
            const SizedBox(height: AppSpacing.section),
            ordersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.section),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => ErrorState(
                title: 'Failed to load service orders',
                message: err.toString(),
                onRetry: () => ref.refresh(serviceOrdersProvider),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return EmptyState(
                    title: 'No Service Orders',
                    message: _searchQuery.isNotEmpty || _selectedStatus != 'All'
                        ? 'No service orders match the selected filters.'
                        : 'No active workshop service orders found.',
                    icon: Icons.build_outlined,
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.standard),
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return PitCard(
                      technicalLabel: 'ORDER TICKET • ${order.orderNumber}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  order.title,
                                  style: AppTypography.sectionTitle(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                color: isDark
                                    ? AppColors.surfacePrimary
                                    : AppColors.lightSurfacePrimary,
                                onSelected: (action) {
                                  switch (action) {
                                    case 'edit':
                                      _openOrderDialog(order);
                                      break;
                                    case 'status_in_progress':
                                      _quickStatusUpdate(
                                        order,
                                        ServiceStatus.inProgress,
                                      );
                                      break;
                                    case 'status_waiting_parts':
                                      _quickStatusUpdate(
                                        order,
                                        ServiceStatus.waitingForParts,
                                      );
                                      break;
                                    case 'status_completed':
                                      _quickStatusUpdate(
                                        order,
                                        ServiceStatus.completed,
                                      );
                                      break;
                                    case 'status_closed':
                                      _quickStatusUpdate(
                                        order,
                                        ServiceStatus.closed,
                                      );
                                      break;
                                    case 'delete':
                                      _confirmDeleteOrder(order);
                                      break;
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(
                                      'Edit Order Details',
                                      style: TextStyle(color: textPrimary),
                                    ),
                                  ),
                                  if (order.status != ServiceStatus.inProgress)
                                    PopupMenuItem(
                                      value: 'status_in_progress',
                                      child: Text(
                                        'Mark In Progress',
                                        style: TextStyle(color: textPrimary),
                                      ),
                                    ),
                                  if (order.status !=
                                      ServiceStatus.waitingForParts)
                                    PopupMenuItem(
                                      value: 'status_waiting_parts',
                                      child: Text(
                                        'Mark Waiting For Parts',
                                        style: TextStyle(color: textPrimary),
                                      ),
                                    ),
                                  if (order.status != ServiceStatus.completed)
                                    PopupMenuItem(
                                      value: 'status_completed',
                                      child: Text(
                                        'Mark Completed',
                                        style: TextStyle(color: textPrimary),
                                      ),
                                    ),
                                  if (order.status != ServiceStatus.closed)
                                    PopupMenuItem(
                                      value: 'status_closed',
                                      child: Text(
                                        'Close Order',
                                        style: TextStyle(color: textPrimary),
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete Order',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Wrap(
                            spacing: AppSpacing.compact,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusBadge.forServiceStatus(order.status.value),
                              StatusBadge.forIntakeOrigin(order.intakeOrigin),
                              if (order.arrivedAt != null)
                                StatusBadge(
                                  label:
                                      'ARRIVED ${order.arrivedAt!.hour.toString().padLeft(2, '0')}:${order.arrivedAt!.minute.toString().padLeft(2, '0')}',
                                  color: AppColors.info,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            'Vehicle: ${order.vehicle?.displayName ?? 'Vehicle'} (${order.vehicle?.identifierLabel ?? 'NO-PLATE'}) • Client: ${order.customer?.displayName ?? 'Client'}',
                            style: AppTypography.bodySmall(
                              color: textSecondary,
                            ),
                          ),
                          if (order.description != null &&
                              order.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              order.description!,
                              style: AppTypography.bodySmall(color: textMuted),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.standard),
                          Divider(
                            color: isDark
                                ? AppColors.borderSubtle
                                : AppColors.lightBorderSubtle,
                            height: 1,
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Wrap(
                            spacing: AppSpacing.section,
                            runSpacing: AppSpacing.compact,
                            children: [
                              _buildMetaBadge(
                                'Technician',
                                order.mechanicDisplayName,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                              _buildMetaBadge(
                                'Odometer',
                                order.odometerKm != null
                                    ? '${order.odometerKm} km'
                                    : 'N/A',
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                              _buildMetaBadge(
                                'Est. Total',
                                'IDR ${order.estimatedTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                              if (order.createdAt != null)
                                _buildMetaBadge(
                                  'Logged',
                                  '${order.createdAt!.year}-${order.createdAt!.month.toString().padLeft(2, '0')}-${order.createdAt!.day.toString().padLeft(2, '0')}',
                                  textPrimary: textPrimary,
                                  textMuted: textMuted,
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
    );
  }

  Widget _buildMetaBadge(
    String label,
    String value, {
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: AppTypography.technical(color: textMuted)),
        Text(value, style: AppTypography.bodySmall(color: textPrimary)),
      ],
    );
  }
}

class _ServiceOrderFormDialog extends ConsumerStatefulWidget {
  const _ServiceOrderFormDialog({this.order, required this.onSave});

  final ServiceOrder? order;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  @override
  ConsumerState<_ServiceOrderFormDialog> createState() =>
      _ServiceOrderFormDialogState();
}

class _ServiceOrderFormDialogState
    extends ConsumerState<_ServiceOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _estimatedTotalController;
  late final TextEditingController _odometerController;

  String? _selectedCustomerId;
  String? _selectedVehicleId;
  String? _selectedMechanicId;
  ServiceStatus _selectedStatus = ServiceStatus.requested;
  final Map<String, int> _selectedParts = {}; // sparePartId -> quantity
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _titleController = TextEditingController(text: o?.title ?? '');
    _descriptionController = TextEditingController(text: o?.description ?? '');
    _estimatedTotalController = TextEditingController(
      text: o != null ? o.estimatedTotal.toStringAsFixed(0) : '0',
    );
    _odometerController = TextEditingController(
      text: o?.odometerKm?.toString() ?? '',
    );

    if (o != null) {
      _selectedCustomerId = o.customerId;
      _selectedVehicleId = o.vehicleId;
      _selectedStatus = o.status;
      if (o.assignments.isNotEmpty) {
        _selectedMechanicId = o.assignments.first.mechanicId;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedTotalController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      setState(() => _errorMessage = 'Please select a customer.');
      return;
    }
    if (_selectedVehicleId == null) {
      setState(() => _errorMessage = 'Please select a vehicle.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final estTotal =
          double.tryParse(_estimatedTotalController.text.trim()) ?? 0.0;
      final odo = int.tryParse(_odometerController.text.trim());

      final payload = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'vehicle_id': _selectedVehicleId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'mechanic_id': _selectedMechanicId,
        'status': _selectedStatus,
        'estimated_total': estTotal,
        'odometer_km': odo,
        'selected_parts': _selectedParts.entries
            .map((e) => {'spare_part_id': e.key, 'quantity': e.value})
            .toList(),
      };

      await widget.onSave(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.order != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderSubtle =
        isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    final customersAsync = ref.watch(customersProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final mechanicsAsync = ref.watch(mechanicsProvider);
    final sparePartsAsync = ref.watch(sparePartsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: dialogBg,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'EDIT SERVICE ORDER' : 'CREATE SERVICE TICKET',
                    style: AppTypography.sectionTitle(color: textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.compact),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.compact),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.compact),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer
                        customersAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading customers: $e'),
                          data: (customers) {
                            if (_selectedCustomerId == null &&
                                customers.isNotEmpty) {
                              _selectedCustomerId = customers.first.id;
                            }
                            return DropdownButtonFormField<String>(
                              initialValue: _selectedCustomerId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Customer *',
                              ),
                              items: customers
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCustomerId = val;
                                  _selectedVehicleId = null;
                                });
                              },
                              validator: (v) =>
                                  v == null ? 'Customer is required' : null,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Vehicle
                        vehiclesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading vehicles: $e'),
                          data: (vehicles) {
                            final filteredVehicles = _selectedCustomerId != null
                                ? vehicles
                                    .where(
                                      (v) => v.customerId == _selectedCustomerId,
                                    )
                                    .toList()
                                : vehicles;

                            if (_selectedVehicleId == null &&
                                filteredVehicles.isNotEmpty) {
                              _selectedVehicleId = filteredVehicles.first.id;
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedVehicleId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle *',
                              ),
                              items: filteredVehicles
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v.id,
                                      child: Text(
                                        '${v.displayName} (${v.identifierLabel})',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedVehicleId = val),
                              validator: (v) =>
                                  v == null ? 'Vehicle is required' : null,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Lead Technician (specialization kept, no overflow)
                        mechanicsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading mechanics: $e'),
                          data: (mechanics) {
                            return DropdownButtonFormField<String?>(
                              initialValue: _selectedMechanicId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Assign Lead Technician',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Unassigned'),
                                ),
                                ...mechanics.map(
                                  (m) => DropdownMenuItem<String?>(
                                    value: m.id,
                                    child: Text(
                                      m.specialization != null &&
                                              m.specialization!.isNotEmpty
                                          ? '${m.displayName} (${m.specialization})'
                                          : m.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedMechanicId = val),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Service Title
                        TextFormField(
                          controller: _titleController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Service Title *',
                            hintText:
                                'e.g. 10,000 KM Maintenance & Brake Service',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Title is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Status if editing
                        if (isEditing) ...[
                          DropdownButtonFormField<ServiceStatus>(
                            initialValue: _selectedStatus,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Status *'),
                            items: ServiceStatus.values
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.standard),
                        ],

                        // Estimated Total
                        TextFormField(
                          controller: _estimatedTotalController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Estimated Total (IDR)',
                            hintText: '0',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Odometer
                        TextFormField(
                          controller: _odometerController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Odometer (KM)',
                            hintText: 'e.g. 24500',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Spare Parts Allocation Section
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.compact),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceBackground
                                : AppColors.lightSurfaceBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ALLOCATE SPARE PARTS',
                                    style: AppTypography.technical(
                                      color: textMuted,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedParts.length} parts added',
                                    style: AppTypography.bodySmall(
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              sparePartsAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) =>
                                    Text('Error loading parts: $e'),
                                data: (parts) {
                                  return DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Add Part from Inventory',
                                      hintText: 'Choose available part...',
                                    ),
                                    items: parts.map((p) {
                                      final isAvailable = p.stock > 0;
                                      return DropdownMenuItem<String>(
                                        value: p.id,
                                        enabled: isAvailable,
                                        child: Text(
                                          isAvailable
                                              ? '${p.name} (${p.stock} ${p.unit} in stock)'
                                              : '${p.name} [Out of Stock - 0 ${p.unit}]',
                                          style: TextStyle(
                                            color: isAvailable
                                                ? textPrimary
                                                : textMuted,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (selectedId) {
                                      if (selectedId != null) {
                                        setState(() {
                                          _selectedParts[selectedId] =
                                              (_selectedParts[selectedId] ??
                                                  0) +
                                              1;
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                              if (_selectedParts.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.compact),
                                ..._selectedParts.entries.map((entry) {
                                  final part = sparePartsAsync.value
                                      ?.firstWhere((p) => p.id == entry.key);
                                  if (part == null) return const SizedBox.shrink();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${part.name} (Stock: ${part.stock} ${part.unit})',
                                            style: AppTypography.bodySmall(
                                              color: textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (entry.value > 1) {
                                                _selectedParts[entry.key] =
                                                    entry.value - 1;
                                              } else {
                                                _selectedParts
                                                    .remove(entry.key);
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          '${entry.value} ${part.unit}',
                                          style: AppTypography.label(
                                            color: AppColors.primaryAccent,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 18,
                                          ),
                                          onPressed: entry.value < part.stock
                                              ? () {
                                                  setState(() {
                                                    _selectedParts[entry.key] =
                                                        entry.value + 1;
                                                  });
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Description / Job Notes',
                            hintText:
                                'Customer symptoms, diagnostics plan, etc.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.standard),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  Expanded(
                    child: PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Create Ticket',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
