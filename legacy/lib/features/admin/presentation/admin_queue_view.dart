import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/spare_part_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Top-level page for the Admin Workshop Queue route (/admin/queue).
class AdminQueuePage extends StatelessWidget {
  const AdminQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      currentRoute: RoutePaths.adminQueue,
      child: AdminQueueView(),
    );
  }
}

/// Admin Workshop Queue view adhering to SPEC.md, DESIGN.md, and Stitch references.
///
/// Implements deterministic FIFO arrival queue with 5 distinct physical sections:
/// 1. Upcoming Bookings (not arrived)
/// 2. Waiting in Workshop (arrived, waiting for bay work)
/// 3. In Service (inspection, diagnosis, in progress)
/// 4. Blocked / On Hold (waiting for parts or customer approval)
/// 5. Recently Completed (completed, payment, closed)
class AdminQueueView extends ConsumerStatefulWidget {
  const AdminQueueView({super.key});

  @override
  ConsumerState<AdminQueueView> createState() => _AdminQueueViewState();
}

class _AdminQueueViewState extends ConsumerState<AdminQueueView> {
  String _searchQuery = '';
  String _selectedSection = 'Waiting';
  String _selectedOrigin = 'All';

  final List<String> _sectionTabs = const [
    'Waiting',
    'In Service',
    'Blocked',
    'Upcoming',
    'Completed',
    'All Active',
  ];

  final List<String> _originFilters = const ['All', 'Booking', 'Walk-In'];

  String _formatWaitDuration(DateTime? arrivedAt) {
    if (arrivedAt == null) return 'Arrival not recorded';
    final diff = DateTime.now().difference(arrivedAt);
    if (diff.isNegative) return 'Just arrived';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m wait';
    }
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    return '${hours}h ${mins}m wait';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showCheckInDialog(Booking booking) {
    final notesCtrl = TextEditingController(
      text: booking.adminNotes ?? 'Checked in at reception desk.',
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor:
            Theme.of(context).cardTheme.color ?? AppColors.surfacePrimary,
        title: Row(
          children: [
            const Icon(
              Icons.how_to_reg,
              color: AppColors.primaryAccent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Text(
                'CHECK IN VEHICLE',
                style: AppTypography.sectionTitle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admit scheduled customer vehicle to the workshop queue. This will mark the booking as checked in and create a physical service order.',
                style: AppTypography.bodySmall(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              Container(
                padding: const EdgeInsets.all(AppSpacing.compact),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceSecondary
                      : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderSubtle
                        : AppColors.lightBorderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client: ${booking.customer?.displayName ?? 'Customer'}',
                      style: AppTypography.label(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vehicle: ${booking.vehicle?.displayName ?? 'Vehicle'} (${booking.vehicle?.licensePlate ?? 'No Plate'})',
                      style: AppTypography.bodySmall(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Service: ${booking.requestedService}',
                      style: AppTypography.technical(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: AppTypography.bodyMedium(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Check-In Notes / Bay Instructions',
                  hintText: 'e.g. Assigned to Bay 2 for inspection',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm Check-In'),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(serviceOrdersProvider.notifier)
                    .checkInBooking(
                      bookingId: booking.id,
                      adminNotes: notesCtrl.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Booking checked in. Order created and vehicle admitted to workshop queue.',
                      ),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Check-in failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAdmitWalkInDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        backgroundColor:
            Theme.of(context).cardTheme.color ?? AppColors.surfacePrimary,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: _WalkInAdmissionSheet(
            onAdmitted: () {
              ref.invalidate(serviceOrdersProvider);
            },
          ),
        ),
      ),
    );
  }

  void _showStatusTransitionDialog(ServiceOrder order) {
    final validNextStatuses = _getValidNextStatuses(order.status);
    if (validNextStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order #${order.orderNumber} is closed. No further transitions permitted.',
          ),
        ),
      );
      return;
    }

    ServiceStatus selected = validNextStatuses.first;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
              Theme.of(context).cardTheme.color ?? AppColors.surfacePrimary,
          title: Text(
            'TRANSITION SERVICE STATUS',
            style: AppTypography.sectionTitle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber} (${order.vehicle?.displayName ?? 'Vehicle'})',
                  style: AppTypography.technical(
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Status: ${order.status.label}',
                  style: AppTypography.bodySmall(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                DropdownButtonFormField<ServiceStatus>(
                  initialValue: selected,
                  dropdownColor:
                      Theme.of(context).cardTheme.color ??
                      AppColors.surfaceSecondary,
                  decoration: const InputDecoration(labelText: 'Target Status'),
                  items: validNextStatuses.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selected = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: AppTypography.label(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: selected.color),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(serviceOrdersProvider.notifier)
                      .updateServiceOrderStatus(id: order.id, status: selected);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order #${order.orderNumber} transitioned to ${selected.label}.',
                      ),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Transition failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Apply Transition'),
            ),
          ],
        ),
      ),
    );
  }

  List<ServiceStatus> _getValidNextStatuses(ServiceStatus current) {
    switch (current) {
      case ServiceStatus.requested:
        return [
          ServiceStatus.inspection,
          ServiceStatus.approved,
          ServiceStatus.scheduled,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.approved:
        return [
          ServiceStatus.scheduled,
          ServiceStatus.inspection,
          ServiceStatus.inProgress,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.scheduled:
        return [
          ServiceStatus.inspection,
          ServiceStatus.diagnosis,
          ServiceStatus.inProgress,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.inspection:
        return [
          ServiceStatus.diagnosis,
          ServiceStatus.inProgress,
          ServiceStatus.waitingForApproval,
          ServiceStatus.waitingForParts,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.diagnosis:
        return [
          ServiceStatus.inProgress,
          ServiceStatus.waitingForApproval,
          ServiceStatus.waitingForParts,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.waitingForApproval:
        return [
          ServiceStatus.inProgress,
          ServiceStatus.waitingForParts,
          ServiceStatus.diagnosis,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.waitingForParts:
        return [
          ServiceStatus.inProgress,
          ServiceStatus.waitingForApproval,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.inProgress:
        return [
          ServiceStatus.completionReview,
          ServiceStatus.completed,
          ServiceStatus.waitingForParts,
          ServiceStatus.waitingForApproval,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.completionReview:
        return [
          ServiceStatus.completed,
          ServiceStatus.inProgress,
          ServiceStatus.cancelled,
        ];
      case ServiceStatus.completed:
        return [ServiceStatus.payment, ServiceStatus.closed];
      case ServiceStatus.payment:
        return [ServiceStatus.closed];
      case ServiceStatus.closed:
      case ServiceStatus.cancelled:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(serviceOrdersProvider);
    final bookingsAsync = ref.watch(bookingsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.paddingSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Telemetry Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKSHOP DISPATCH & QUEUE',
                      style: AppTypography.technical(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live FIFO Queue Control',
                      style: AppTypography.pageTitle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Track physical bay allocation, vehicle arrivals, wait duration, and service flow.',
                      style: AppTypography.bodySmall(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Admit Walk-In'),
                onPressed: _showAdmitWalkInDialog,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.standard),

          // Operational Telemetry Counters
          ordersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (orders) {
              final bookings = bookingsAsync.asData?.value ?? [];

              final waitingCount = orders
                  .where(
                    (o) =>
                        o.arrivedAt != null &&
                        (o.status == ServiceStatus.requested ||
                            o.status == ServiceStatus.approved ||
                            o.status == ServiceStatus.scheduled),
                  )
                  .length;

              final inServiceCount = orders
                  .where(
                    (o) =>
                        o.status == ServiceStatus.inspection ||
                        o.status == ServiceStatus.diagnosis ||
                        o.status == ServiceStatus.inProgress,
                  )
                  .length;

              final blockedCount = orders
                  .where(
                    (o) =>
                        o.status == ServiceStatus.waitingForApproval ||
                        o.status == ServiceStatus.waitingForParts ||
                        o.status == ServiceStatus.completionReview,
                  )
                  .length;

              final upcomingCount = bookings
                  .where(
                    (b) =>
                        b.status == BookingStatus.requested ||
                        b.status == BookingStatus.approved ||
                        b.status == BookingStatus.scheduled,
                  )
                  .length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: AppSpacing.compact,
                      mainAxisSpacing: AppSpacing.compact,
                      mainAxisExtent: 140,
                    ),
                    children: [
                      StatCard(
                        title: 'Waiting in Bay',
                        value: '$waitingCount Vehicles',
                        technicalCode: 'FIFO-WAIT',
                        badgeText: 'WAITING',
                        badgeColor: AppColors.warning,
                        icon: Icons.hourglass_top,
                      ),
                      StatCard(
                        title: 'In Service',
                        value: '$inServiceCount Active',
                        technicalCode: 'BAY-LOAD',
                        badgeText: 'IN WORKSHOP',
                        badgeColor: AppColors.primaryAccent,
                        icon: Icons.engineering,
                      ),
                      StatCard(
                        title: 'Blocked / Hold',
                        value: '$blockedCount Jobs',
                        technicalCode: 'HOLD-TEL',
                        badgeText: blockedCount > 0 ? 'ATTENTION' : 'CLEAR',
                        badgeColor: blockedCount > 0
                            ? AppColors.warning
                            : AppColors.statusCompleted,
                        icon: Icons.pause_circle_outline,
                      ),
                      StatCard(
                        title: 'Upcoming Bookings',
                        value: '$upcomingCount Bookings',
                        technicalCode: 'NOT-ARRIVED',
                        badgeText: 'SCHEDULED',
                        badgeColor: AppColors.info,
                        icon: Icons.calendar_month,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.section),

          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: AppTypography.bodyMedium(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search queue by plate, customer, order number, or car...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: AppSpacing.compact),
              // Origin Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderSubtle
                        : AppColors.lightBorderSubtle,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOrigin,
                    dropdownColor:
                        Theme.of(context).cardTheme.color ??
                        AppColors.surfaceSecondary,
                    items: _originFilters.map((orig) {
                      return DropdownMenuItem(
                        value: orig,
                        child: Text(
                          'Origin: $orig',
                          style: AppTypography.bodySmall(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOrigin = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),

          // 5 Physical Queue Section Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sectionTabs.map((tab) {
                final isSelected = _selectedSection == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.compact),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
                    selectedColor: AppColors.primaryAccent.withValues(
                      alpha: 0.2,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryAccent
                          : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondary
                                : AppColors.lightTextSecondary),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryAccent
                          : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.borderSubtle
                                : AppColors.lightBorderSubtle),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSection = tab);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.standard),

          // Main Queue Content
          ordersAsync.when(
            loading: () =>
                const LoadingState(message: 'Loading live workshop queue...'),
            error: (err, _) => ErrorState(
              title: 'Queue Telemetry Error',
              message: err.toString(),
              onRetry: () {
                ref.invalidate(serviceOrdersProvider);
                ref.invalidate(bookingsProvider);
              },
            ),
            data: (allOrders) {
              final allBookings = bookingsAsync.asData?.value ?? [];

              // Categorize into the 5 physical queue buckets
              final waitingOrders = allOrders.where((o) {
                final isWaitingStatus =
                    o.status == ServiceStatus.requested ||
                    o.status == ServiceStatus.approved ||
                    o.status == ServiceStatus.scheduled;
                return o.arrivedAt != null && isWaitingStatus;
              }).toList();

              final inServiceOrders = allOrders.where((o) {
                return o.status == ServiceStatus.inspection ||
                    o.status == ServiceStatus.diagnosis ||
                    o.status == ServiceStatus.inProgress;
              }).toList();

              final blockedOrders = allOrders.where((o) {
                return o.status == ServiceStatus.waitingForApproval ||
                    o.status == ServiceStatus.waitingForParts ||
                    o.status == ServiceStatus.completionReview;
              }).toList();

              final completedOrders = allOrders.where((o) {
                return o.status == ServiceStatus.completed ||
                    o.status == ServiceStatus.payment ||
                    o.status == ServiceStatus.closed;
              }).toList();

              final upcomingBookings = allBookings.where((b) {
                return b.status == BookingStatus.requested ||
                    b.status == BookingStatus.approved ||
                    b.status == BookingStatus.scheduled;
              }).toList();

              // Deterministic FIFO Sorting:
              // Arrived orders: sorted by arrivedAt ASC, then createdAt ASC, then id ASC
              int compareFifoArrival(ServiceOrder a, ServiceOrder b) {
                final aArrival = a.arrivedAt ?? a.createdAt ?? DateTime(2000);
                final bArrival = b.arrivedAt ?? b.createdAt ?? DateTime(2000);
                final cmp = aArrival.compareTo(bArrival);
                if (cmp != 0) return cmp;
                final aCreated = a.createdAt ?? DateTime(2000);
                final bCreated = b.createdAt ?? DateTime(2000);
                final cmpCreated = aCreated.compareTo(bCreated);
                if (cmpCreated != 0) return cmpCreated;
                return a.id.compareTo(b.id);
              }

              waitingOrders.sort(compareFifoArrival);
              inServiceOrders.sort(compareFifoArrival);
              blockedOrders.sort(compareFifoArrival);

              // Upcoming bookings: sorted by preferredDate ASC, preferredTime ASC, createdAt ASC
              upcomingBookings.sort((a, b) {
                final aDate = a.preferredDate ?? '9999-99-99';
                final bDate = b.preferredDate ?? '9999-99-99';
                final cmpDate = aDate.compareTo(bDate);
                if (cmpDate != 0) return cmpDate;
                final aTime = a.preferredTime ?? '99:99';
                final bTime = b.preferredTime ?? '99:99';
                final cmpTime = aTime.compareTo(bTime);
                if (cmpTime != 0) return cmpTime;
                return (a.createdAt ?? DateTime(2000)).compareTo(
                  b.createdAt ?? DateTime(2000),
                );
              });

              // Completed orders: sorted by completedAt DESC, then createdAt DESC
              completedOrders.sort((a, b) {
                final aComp =
                    a.completedAt ??
                    a.closedAt ??
                    a.createdAt ??
                    DateTime(2000);
                final bComp =
                    b.completedAt ??
                    b.closedAt ??
                    b.createdAt ??
                    DateTime(2000);
                return bComp.compareTo(aComp);
              });

              // Apply Search and Origin filters
              List<ServiceOrder> filterOrders(List<ServiceOrder> input) {
                return input.where((o) {
                  // Origin filter
                  if (_selectedOrigin == 'Booking' &&
                      o.intakeOrigin != ServiceIntakeOrigin.booking) {
                    return false;
                  }
                  if (_selectedOrigin == 'Walk-In' &&
                      o.intakeOrigin != ServiceIntakeOrigin.walkIn) {
                    return false;
                  }
                  // Search query
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    final plate = o.vehicle?.licensePlate?.toLowerCase() ?? '';
                    final vehicle = o.vehicle?.displayName.toLowerCase() ?? '';
                    final customer =
                        o.customer?.displayName.toLowerCase() ?? '';
                    final orderNo = o.orderNumber.toLowerCase();
                    final title = o.title.toLowerCase();
                    return plate.contains(q) ||
                        vehicle.contains(q) ||
                        customer.contains(q) ||
                        orderNo.contains(q) ||
                        title.contains(q);
                  }
                  return true;
                }).toList();
              }

              List<Booking> filterBookings(List<Booking> input) {
                if (_selectedOrigin == 'Walk-In') {
                  return [];
                }
                return input.where((b) {
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    final plate = b.vehicle?.licensePlate?.toLowerCase() ?? '';
                    final vehicle = b.vehicle?.displayName.toLowerCase() ?? '';
                    final customer =
                        b.customer?.displayName.toLowerCase() ?? '';
                    final service = b.requestedService.toLowerCase();
                    return plate.contains(q) ||
                        vehicle.contains(q) ||
                        customer.contains(q) ||
                        service.contains(q);
                  }
                  return true;
                }).toList();
              }

              if (_selectedSection == 'Upcoming') {
                final displayBookings = filterBookings(upcomingBookings);
                if (displayBookings.isEmpty) {
                  return const EmptyState(
                    title: 'No Upcoming Bookings',
                    message: 'All scheduled bookings have checked in or no bookings pending.',
                    icon: Icons.calendar_month_outlined,
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayBookings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.standard),
                  itemBuilder: (context, index) {
                    return _buildUpcomingBookingCard(displayBookings[index]);
                  },
                );
              }

              List<ServiceOrder> activeSectionOrders;
              switch (_selectedSection) {
                case 'Waiting':
                  activeSectionOrders = filterOrders(waitingOrders);
                  break;
                case 'In Service':
                  activeSectionOrders = filterOrders(inServiceOrders);
                  break;
                case 'Blocked':
                  activeSectionOrders = filterOrders(blockedOrders);
                  break;
                case 'Completed':
                  activeSectionOrders = filterOrders(completedOrders);
                  break;
                case 'All Active':
                default:
                  activeSectionOrders = filterOrders([
                    ...waitingOrders,
                    ...inServiceOrders,
                    ...blockedOrders,
                  ]);
                  break;
              }

              if (activeSectionOrders.isEmpty) {
                return EmptyState(
                  title: 'No Vehicles in $_selectedSection',
                  message:
                      'No service orders match the selected queue criteria.',
                  icon: Icons.garage_outlined,
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeSectionOrders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.standard),
                itemBuilder: (context, index) {
                  final order = activeSectionOrders[index];
                  final queuePosition = index + 1;
                  return _buildQueueOrderCard(order, queuePosition);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueOrderCard(ServiceOrder order, int position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waitText = _formatWaitDuration(order.arrivedAt);
    final arrivedTime = _formatTime(order.arrivedAt);

    final isBlocked =
        order.status == ServiceStatus.waitingForParts ||
        order.status == ServiceStatus.waitingForApproval ||
        order.status == ServiceStatus.completionReview;

    return PitCard(
      technicalLabel:
          'DISPATCH SLOT #$position \u2022 ORDER ${order.orderNumber}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Origin Badge, Order Number, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.compact,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge.forIntakeOrigin(order.intakeOrigin),
                  Text(
                    order.orderNumber,
                    style: AppTypography.technical(
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
              StatusBadge.forServiceStatus(order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),

          // Vehicle & License Plate
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (order.vehicle?.licensePlate != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevated
                        : AppColors.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderSubtle
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Text(
                    order.vehicle!.licensePlate!,
                    style: AppTypography.technical(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
              ],
              Expanded(
                child: Text(
                  order.vehicle?.displayName ?? 'Assigned Vehicle',
                  style: AppTypography.sectionTitle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Customer & Service Title
          Text(
            'Client: ${order.customer?.displayName ?? 'Client'} \u2022 Service: ${order.title}',
            style: AppTypography.bodySmall(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.compact),

          // Telemetry Row: Arrival Time & Elapsed Wait
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundSecondary
                  : AppColors.lightBackgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.lightBorderSubtle,
              ),
            ),
            child: Wrap(
              spacing: AppSpacing.standard,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Arrival: $arrivedTime',
                      style: AppTypography.technical(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_empty,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      waitText,
                      style: AppTypography.technical(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.neutral,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lead: ${order.mechanicDisplayName}',
                      style: AppTypography.technical(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Blocker Callout Banner
          if (isBlocked) ...[
            const SizedBox(height: AppSpacing.compact),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.compact),
                  Expanded(
                    child: Text(
                      _getBlockerMessage(order.status),
                      style: AppTypography.bodySmall(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.standard),

          // Contextual Next Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status == ServiceStatus.requested ||
                  order.status == ServiceStatus.approved ||
                  order.status == ServiceStatus.scheduled) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Start Inspection'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(serviceOrdersProvider.notifier)
                          .updateServiceOrderStatus(
                            id: order.id,
                            status: ServiceStatus.inspection,
                          );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order #${order.orderNumber} moved to Inspection.',
                          ),
                          backgroundColor: AppColors.statusCompleted,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to start inspection: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.compact),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change Status'),
                onPressed: () => _showStatusTransitionDialog(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getBlockerMessage(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.waitingForParts:
        return 'BLOCKED: Awaiting spare parts allocation from inventory.';
      case ServiceStatus.waitingForApproval:
        return 'ON HOLD: Awaiting customer estimate authorization.';
      case ServiceStatus.completionReview:
        return 'REVIEW: Service completed, pending final supervisor sign-off.';
      default:
        return 'Action required on this service order.';
    }
  }

  Widget _buildUpcomingBookingCard(Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortId = booking.id.length >= 8
        ? booking.id.substring(0, 8).toUpperCase()
        : booking.id;

    return PitCard(
      technicalLabel: 'UPCOMING BOOKING \u2022 #$shortId',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusBadge(
                label: 'BOOKING SCHEDULED',
                color: AppColors.info,
                icon: Icons.calendar_month,
              ),
              StatusBadge.forBookingStatus(booking.status),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),

          // Vehicle & Customer
          Row(
            children: [
              if (booking.vehicle?.licensePlate != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevated
                        : AppColors.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderSubtle
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Text(
                    booking.vehicle!.licensePlate!,
                    style: AppTypography.technical(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
              ],
              Expanded(
                child: Text(
                  booking.vehicle?.displayName ?? 'Customer Vehicle',
                  style: AppTypography.sectionTitle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            'Client: ${booking.customer?.displayName ?? 'Client'} \u2022 Service: ${booking.requestedService}',
            style: AppTypography.bodySmall(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.compact),

          // Appointment Time details (NOT arrival time!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundSecondary
                  : AppColors.lightBackgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.lightBorderSubtle,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  'Preferred Slot: ${booking.preferredDate ?? 'Unspecified'} at ${booking.preferredTime ?? 'Flexible'}',
                  style: AppTypography.technical(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.standard),

          // Check-In Action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                ),
                icon: const Icon(Icons.how_to_reg, size: 16),
                label: const Text('Check In Vehicle'),
                onPressed: () => _showCheckInDialog(booking),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Walk-in admission bottom sheet modal.
class _WalkInAdmissionSheet extends ConsumerStatefulWidget {
  const _WalkInAdmissionSheet({required this.onAdmitted});
  final VoidCallback onAdmitted;

  @override
  ConsumerState<_WalkInAdmissionSheet> createState() =>
      _WalkInAdmissionSheetState();
}

class _WalkInAdmissionSheetState extends ConsumerState<_WalkInAdmissionSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  String? _selectedVehicleId;
  final Map<String, int> _selectedParts = {}; // sparePartId -> quantity
  final _titleCtrl = TextEditingController(
    text: 'Routine Maintenance & Inspection',
  );
  final _descCtrl = TextEditingController();
  final _estimatedTotalCtrl = TextEditingController(text: '750000');
  final _odometerCtrl = TextEditingController(text: '25000');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _estimatedTotalCtrl.dispose();
    _odometerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final sparePartsAsync = ref.watch(sparePartsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customers = customersAsync.asData?.value ?? [];
    final allVehicles = vehiclesAsync.asData?.value ?? [];

    // Filter vehicles by selected customer if chosen
    final availableVehicles = _selectedCustomerId != null
        ? allVehicles.where((v) => v.customerId == _selectedCustomerId).toList()
        : allVehicles;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.section,
        right: AppSpacing.section,
        top: AppSpacing.section,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.section,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ADMIT WALK-IN VEHICLE',
                      style: AppTypography.sectionTitle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Create an active workshop queue entry for a walk-in vehicle without a prior booking. Origin will be recorded as WALK-IN.',
                style: AppTypography.bodySmall(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.standard),

              // Customer Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedCustomerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Customer *'),
                dropdownColor:
                    Theme.of(context).cardTheme.color ??
                    AppColors.surfaceSecondary,
                items: customers.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.displayName} (${c.customerType})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCustomerId = val;
                    _selectedVehicleId = null;
                  });
                },
                validator: (val) =>
                    val == null ? 'Please select customer' : null,
              ),
              const SizedBox(height: AppSpacing.standard),

              // Vehicle Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vehicle *'),
                dropdownColor:
                    Theme.of(context).cardTheme.color ??
                    AppColors.surfaceSecondary,
                items: availableVehicles.map((v) {
                  final plate = v.licensePlate != null
                      ? ' [${v.licensePlate}]'
                      : '';
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text(
                      '${v.displayName}$plate',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedVehicleId = val),
                validator: (val) =>
                    val == null ? 'Please select vehicle' : null,
              ),
              const SizedBox(height: AppSpacing.standard),

              // Service Title
              TextFormField(
                controller: _titleCtrl,
                style: AppTypography.bodyMedium(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(labelText: 'Service Title *'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter service title'
                    : null,
              ),
              const SizedBox(height: AppSpacing.standard),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: AppTypography.bodyMedium(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Customer Issue / Service Description',
                  hintText: 'Customer remarks, requested parts, or notes...',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _estimatedTotalCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMedium(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Estimated Total (IDR)',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.compact),
                  Expanded(
                    child: TextFormField(
                      controller: _odometerCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMedium(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Odometer (km)',
                      ),
                    ),
                  ),
                ],
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
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSubtle
                        : AppColors.lightBorderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALLOCATE SPARE PARTS',
                          style: AppTypography.technical(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          '${_selectedParts.length} parts',
                          style: AppTypography.bodySmall(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    sparePartsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading parts: $e'),
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
                                      ? (isDark
                                          ? AppColors.textPrimary
                                          : AppColors.lightTextPrimary)
                                      : (isDark
                                          ? AppColors.textMuted
                                          : AppColors.lightTextMuted),
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
                                    (_selectedParts[selectedId] ?? 0) + 1;
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${part.name} (Stock: ${part.stock} ${part.unit})',
                                  style: AppTypography.bodySmall(
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppColors.lightTextPrimary,
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
                                      _selectedParts.remove(entry.key);
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
              const SizedBox(height: AppSpacing.section),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _isSubmitting ? 'Admitting...' : 'Admit Vehicle to Queue',
                ),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSubmitting = true);

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          final cost =
                              double.tryParse(
                                _estimatedTotalCtrl.text.trim(),
                              ) ??
                              0.0;
                          final odo = int.tryParse(_odometerCtrl.text.trim());

                          final createdOrder = await ref
                              .read(serviceOrdersProvider.notifier)
                              .admitWalkIn(
                                customerId: _selectedCustomerId!,
                                vehicleId: _selectedVehicleId!,
                                title: _titleCtrl.text.trim(),
                                description: _descCtrl.text.trim().isEmpty
                                    ? null
                                    : _descCtrl.text.trim(),
                                estimatedTotal: cost,
                                odometerKm: odo,
                              );

                          if (_selectedParts.isNotEmpty) {
                            final partsList = _selectedParts.entries
                                .map((e) => {
                                      'spare_part_id': e.key,
                                      'quantity': e.value,
                                    })
                                .toList();
                            await ref
                                .read(sparePartsProvider.notifier)
                                .deductPartsForServiceOrder(
                                  serviceOrderId: createdOrder.id,
                                  items: partsList,
                                );
                          }

                          navigator.pop();
                          widget.onAdmitted();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Walk-in admitted to workshop queue.',
                              ),
                              backgroundColor: AppColors.statusCompleted,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Admission failed: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
