import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/providers/mechanic_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
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
            await ref
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
        backgroundColor: AppColors.surfacePrimary,
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
              action: PrimaryButton(
                text: 'Create Order',
                icon: Icons.add,
                width: 150,
                onPressed: () => _openOrderDialog(),
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  StatusBadge.forServiceStatus(
                                    order.status.value,
                                  ),
                                  const SizedBox(width: AppSpacing.compact),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    color: AppColors.surfacePrimary,
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
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Order Details'),
                                      ),
                                      if (order.status !=
                                          ServiceStatus.inProgress)
                                        const PopupMenuItem(
                                          value: 'status_in_progress',
                                          child: Text('Mark In Progress'),
                                        ),
                                      if (order.status !=
                                          ServiceStatus.waitingForParts)
                                        const PopupMenuItem(
                                          value: 'status_waiting_parts',
                                          child: Text('Mark Waiting For Parts'),
                                        ),
                                      if (order.status !=
                                          ServiceStatus.completed)
                                        const PopupMenuItem(
                                          value: 'status_completed',
                                          child: Text('Mark Completed'),
                                        ),
                                      if (order.status != ServiceStatus.closed)
                                        const PopupMenuItem(
                                          value: 'status_closed',
                                          child: Text('Close Order'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Order',
                                          style: TextStyle(
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            'Vehicle: ${order.vehicle?.displayName ?? 'Vehicle'} (${order.vehicle?.identifierLabel ?? 'NO-PLATE'}) • Client: ${order.customer?.displayName ?? 'Client'}',
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (order.description != null &&
                              order.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              order.description!,
                              style: AppTypography.bodySmall(
                                color: AppColors.textMuted,
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
                              _buildMetaBadge(
                                'Technician',
                                order.mechanicDisplayName,
                              ),
                              _buildMetaBadge(
                                'Odometer',
                                order.odometerKm != null
                                    ? '${order.odometerKm} km'
                                    : 'N/A',
                              ),
                              _buildMetaBadge(
                                'Est. Total',
                                'IDR ${order.estimatedTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              ),
                              if (order.createdAt != null)
                                _buildMetaBadge(
                                  'Logged',
                                  '${order.createdAt!.year}-${order.createdAt!.month.toString().padLeft(2, '0')}-${order.createdAt!.day.toString().padLeft(2, '0')}',
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

  Widget _buildMetaBadge(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTypography.technical(color: AppColors.textMuted),
        ),
        Text(
          value,
          style: AppTypography.bodySmall(color: AppColors.textPrimary),
        ),
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
    final customersAsync = ref.watch(customersProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final mechanicsAsync = ref.watch(mechanicsProvider);

    return Dialog(
      backgroundColor: AppColors.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: AppSpacing.paddingSection,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing
                          ? 'Edit Service Order'
                          : 'Create Service Ticket',
                      style: AppTypography.sectionTitle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
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
                const SizedBox(height: AppSpacing.standard),
                customersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading customers: $e'),
                  data: (customers) {
                    if (_selectedCustomerId == null && customers.isNotEmpty) {
                      _selectedCustomerId = customers.first.id;
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      dropdownColor: AppColors.surfacePrimary,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                      ),
                      items: customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.displayName),
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
                const SizedBox(height: AppSpacing.compact),
                vehiclesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading vehicles: $e'),
                  data: (vehicles) {
                    final filteredVehicles = _selectedCustomerId != null
                        ? vehicles
                              .where((v) => v.customerId == _selectedCustomerId)
                              .toList()
                        : vehicles;

                    if (_selectedVehicleId == null &&
                        filteredVehicles.isNotEmpty) {
                      _selectedVehicleId = filteredVehicles.first.id;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleId,
                      dropdownColor: AppColors.surfacePrimary,
                      decoration: const InputDecoration(labelText: 'Vehicle *'),
                      items: filteredVehicles
                          .map(
                            (v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                '${v.displayName} (${v.identifierLabel})',
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
                const SizedBox(height: AppSpacing.compact),
                mechanicsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading mechanics: $e'),
                  data: (mechanics) {
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedMechanicId,
                      dropdownColor: AppColors.surfacePrimary,
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
                              '${m.displayName} (${m.specialization ?? 'General'})',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedMechanicId = val),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.compact),
                TextFormField(
                  controller: _titleController,
                  style: AppTypography.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Service Title *',
                    hintText: 'e.g. 10,000 KM Maintenance & Brake Service',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.compact),
                if (isEditing) ...[
                  DropdownButtonFormField<ServiceStatus>(
                    initialValue: _selectedStatus,
                    dropdownColor: AppColors.surfacePrimary,
                    decoration: const InputDecoration(labelText: 'Status *'),
                    items: ServiceStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.compact),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedTotalController,
                        keyboardType: TextInputKeyData.number,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Estimated Total (IDR)',
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: TextFormField(
                        controller: _odometerController,
                        keyboardType: TextInputKeyData.number,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Odometer (KM)',
                          hintText: 'e.g. 24500',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.compact),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: AppTypography.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Description / Job Notes',
                    hintText: 'Customer symptoms, diagnostics plan, etc.',
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTypography.label(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Create Ticket',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension TextInputKeyData on TextInputType {
  static const TextInputType number = TextInputType.number;
}
