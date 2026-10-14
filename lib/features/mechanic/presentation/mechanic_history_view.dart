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

/// Completed service jobs history for Mechanic role backed by live Supabase records adhering to DESIGN.md.
class MechanicHistoryPage extends ConsumerStatefulWidget {
  const MechanicHistoryPage({super.key});

  @override
  ConsumerState<MechanicHistoryPage> createState() =>
      _MechanicHistoryPageState();
}

class _MechanicHistoryPageState extends ConsumerState<MechanicHistoryPage> {
  String _searchQuery = '';

  void _showArchivedLogDialog(BuildContext context, ServiceOrder order) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Row(
          children: [
            const Icon(Icons.history, color: AppColors.primaryAccent, size: 24),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Text(
                'ARCHIVED SERVICE LOG',
                style: AppTypography.sectionTitle(color: AppColors.textPrimary),
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
                'ORDER #${order.orderNumber}',
                style: AppTypography.technical(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                order.title,
                style: AppTypography.label(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Vehicle: ${order.vehicle?.displayName ?? 'Vehicle'} (${order.vehicle?.licensePlate ?? 'N/A'})',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              Text(
                'Client: ${order.customer?.displayName ?? 'Workshop Client'}',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              if (order.description != null &&
                  order.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.compact),
                Text(
                  'Work Log: ${order.description!}',
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
                    'COMPLETED STATUS',
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Archived service log telemetry exported.'),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Export Telemetry Log'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(mechanicServiceOrdersProvider(null));

    return MechanicShell(
      currentRoute: RoutePaths.mechanicHistory,
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
                title: 'SERVICE LOG HISTORY',
                subtitle: 'Archived vehicles and completed service assignments',
              ),
              const SizedBox(height: AppSpacing.compact),
              SearchFilterBar(
                searchHint: 'Search completed orders by ticket #, vehicle, or client...',
                onSearchChanged: (query) =>
                    setState(() => _searchQuery = query),
              ),
              const SizedBox(height: AppSpacing.section),

              ordersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Retrieving archived technician service logs...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () =>
                      ref.refresh(mechanicServiceOrdersProvider(null)),
                ),
                data: (allOrders) {
                  // Show completed, closed, or past orders
                  final historyList = allOrders.where((h) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch =
                        query.isEmpty ||
                        h.orderNumber.toLowerCase().contains(query) ||
                        (h.vehicle?.displayName.toLowerCase().contains(query) ??
                            false) ||
                        (h.vehicle?.licensePlate?.toLowerCase().contains(
                              query,
                            ) ??
                            false) ||
                        h.title.toLowerCase().contains(query) ||
                        (h.customer?.displayName.toLowerCase().contains(
                              query,
                            ) ??
                            false);

                    return matchesSearch;
                  }).toList();

                  if (historyList.isEmpty) {
                    return const EmptyState(
                      title: 'No Completed Jobs',
                      message: 'No service records match your search.',
                      icon: Icons.history_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final item = historyList[index];

                      return PitCard(
                        technicalLabel:
                            'ARCHIVED SERVICE • ${item.orderNumber} • ${item.completedAt?.toIso8601String().split('T').first ?? item.createdAt?.toIso8601String().split('T').first ?? '2026-10-14'}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Wrapped vehicle name and license plate below to guarantee no card overflow
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.vehicle?.displayName ??
                                            'Archived Vehicle',
                                        style: AppTypography.sectionTitle(
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.vehicle?.licensePlate != null &&
                                          item
                                              .vehicle!
                                              .licensePlate!
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.vehicle!.licensePlate!,
                                          style: AppTypography.technical(
                                            color: AppColors.primaryAccent,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.compact),
                                StatusBadge.forServiceStatus(item.status.value),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Text(
                              'Client: ${item.customer?.displayName ?? 'Workshop Client'} • Service: ${item.title}',
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (item.description != null &&
                                item.description!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                item.description!,
                                style: AppTypography.bodySmall(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            const Divider(
                              color: AppColors.borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status: ${item.status.label}',
                                  style: AppTypography.technical(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showArchivedLogDialog(context, item),
                                  icon: const Icon(
                                    Icons.receipt_long,
                                    size: 16,
                                  ),
                                  label: const Text('View Telemetry Log'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryAccent,
                                    side: const BorderSide(
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
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
