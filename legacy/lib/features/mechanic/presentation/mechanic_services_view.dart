import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'mechanic_shell.dart';

/// Assigned services screen for Mechanic role backed by live Supabase records adhering to DESIGN.md.
class MechanicServicesPage extends ConsumerStatefulWidget {
  const MechanicServicesPage({super.key});

  @override
  ConsumerState<MechanicServicesPage> createState() =>
      _MechanicServicesPageState();
}

class _MechanicServicesPageState extends ConsumerState<MechanicServicesPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  void _showUpdateStatusDialog(BuildContext context, ServiceOrder order) {
    ServiceStatus selected = order.status;
    final notesCtrl = TextEditingController(text: order.description ?? '');

    // Ensure current order status is always present in dropdown to avoid assertion failure
    final allowedStatuses = <ServiceStatus>{
      order.status,
      ServiceStatus.requested,
      ServiceStatus.approved,
      ServiceStatus.scheduled,
      ServiceStatus.inspection,
      ServiceStatus.diagnosis,
      ServiceStatus.waitingForApproval,
      ServiceStatus.waitingForParts,
      ServiceStatus.inProgress,
      ServiceStatus.completionReview,
      ServiceStatus.completed,
    }.toList();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'UPDATE WORK ORDER STATUS',
            style: AppTypography.sectionTitle(),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber} • ${order.vehicle?.displayName ?? 'Vehicle'}',
                    style: AppTypography.label(color: AppColors.primaryAccent),
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  DropdownButtonFormField<ServiceStatus>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Service Status',
                    ),
                    items: allowedStatuses.map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selected = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Diagnostic Notes & Work Performed',
                    ),
                  ),
                ],
              ),
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
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(serviceOrdersProvider.notifier)
                      .updateServiceOrderStatus(
                        id: order.id,
                        status: selected,
                      );
                  ref.invalidate(mechanicServiceOrdersProvider(null));
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Work order #${order.orderNumber} status transitioned to ${selected.label}.',
                      ),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJobDetailsDialog(BuildContext context, ServiceOrder order) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.car_repair,
              color: AppColors.primaryAccent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Text(
                'JOB TICKET SPECIFICATION',
                style: AppTypography.sectionTitle(),
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
                'TICKET #${order.orderNumber}',
                style: AppTypography.technical(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                order.title,
                style: AppTypography.label(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Client: ${order.customer?.displayName ?? 'Workshop Client'}',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              Text(
                'Vehicle: ${order.vehicle?.displayName ?? 'Vehicle'} (${order.vehicle?.licensePlate ?? 'N/A'})',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              if (order.description != null &&
                  order.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.compact),
                Text(
                  order.description!,
                  style: AppTypography.bodySmall(color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.standard),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: AppSpacing.compact),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STATUS',
                    style: AppTypography.technical(color: AppColors.textMuted),
                  ),
                  StatusBadge.forServiceStatus(order.status.value),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Close',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showUpdateStatusDialog(context, order);
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(mechanicServiceOrdersProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderSubtle =
        isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return MechanicShell(
      currentRoute: RoutePaths.mechanicServices,
      child: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(mechanicServiceOrdersProvider(null).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'ASSIGNED SERVICE ORDERS',
                subtitle: 'Active vehicle work tickets assigned to your technician bay',
              ),
              const SizedBox(height: AppSpacing.compact),
              SearchFilterBar(
                searchHint: 'Search assigned jobs by order # or vehicle...',
                onSearchChanged: (query) =>
                    setState(() => _searchQuery = query),
                filterOptions: const [
                  'All',
                  'In Progress',
                  'Scheduled',
                  'Waiting For Parts',
                  'Completed',
                ],
                selectedFilter: _selectedFilter,
                onFilterSelected: (f) => setState(() => _selectedFilter = f),
              ),
              const SizedBox(height: AppSpacing.section),

              ordersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Retrieving assigned work orders from bay...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () =>
                      ref.refresh(mechanicServiceOrdersProvider(null)),
                ),
                data: (allOrders) {
                  final filtered = allOrders.where((s) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch =
                        query.isEmpty ||
                        s.orderNumber.toLowerCase().contains(query) ||
                        (s.vehicle?.displayName.toLowerCase().contains(query) ??
                            false) ||
                        (s.vehicle?.licensePlate?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        s.title.toLowerCase().contains(query) ||
                        (s.customer?.displayName.toLowerCase().contains(
                              query,
                            ) ??
                            false);

                    final matchesFilter =
                        _selectedFilter == 'All' ||
                        s.status.value.toLowerCase() ==
                            _selectedFilter.toLowerCase().replaceAll(' ', '_');

                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      title: 'No Assigned Services',
                      message: 'No service orders match your filter criteria.',
                      icon: Icons.car_repair_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final service = filtered[index];

                      return PitCard(
                        technicalLabel: 'TICKET • ${service.orderNumber}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.title,
                                        style: AppTypography.sectionTitle(
                                          color: textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (service.vehicle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${service.vehicle!.displayName} \u2022 ${service.vehicle!.licensePlate}',
                                          style: AppTypography.technical(
                                            color: AppColors.primaryAccent,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.compact),
                                StatusBadge.forServiceStatus(
                                  service.status.value,
                                ),
                              ],
                            ),
                            if (service.status ==
                                ServiceStatus.waitingForParts) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.standard,
                                  vertical: AppSpacing.compact,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.control),
                                  border: Border.all(
                                    color:
                                        AppColors.warning.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.pause_circle_outline,
                                      color: AppColors.warning,
                                      size: 18,
                                    ),
                                    const SizedBox(width: AppSpacing.compact),
                                    Expanded(
                                      child: Text(
                                        'HOLD BLOCKER: Waiting for parts before technician bay can advance ticket.',
                                        style: AppTypography.bodySmall(
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.compact),
                            Text(
                              'Client: ${service.customer?.displayName ?? 'Workshop Client'} \u2022 Location: Bay 1',
                              style: AppTypography.bodySmall(
                                color: textSecondary,
                              ),
                            ),
                            if (service.description != null &&
                                service.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                service.description!,
                                style: AppTypography.bodySmall(
                                  color: textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            Divider(
                              color: borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.scheduledStart != null
                                      ? 'Date: ${service.scheduledStart!.toIso8601String().split('T').first}'
                                      : 'Date: 2026-10-14',
                                  style: AppTypography.technical(
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.compact),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _showJobDetailsDialog(
                                        context,
                                        service,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: textPrimary,
                                        side: BorderSide(
                                          color: borderSubtle,
                                        ),
                                      ),
                                      child: const Text('Details'),
                                    ),
                                    const SizedBox(width: AppSpacing.compact),
                                    ElevatedButton.icon(
                                      onPressed: () => _showUpdateStatusDialog(
                                        context,
                                        service,
                                      ),
                                      icon: const Icon(
                                        Icons.build_circle,
                                        size: 14,
                                      ),
                                      label: const Text('Update Status'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryAccent,
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                  ],
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
}
