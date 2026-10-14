import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/booking.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Bookings intake management view for Admin role backed by live Supabase records.
class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusFilters = const [
    'All',
    'Requested',
    'Approved',
    'Scheduled',
    'Completed',
    'Rejected',
    'Cancelled',
  ];

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    ref
        .read(bookingsProvider.notifier)
        .setFilter(query: query, status: _selectedStatus);
  }

  void _onStatusFilterSelected(String status) {
    setState(() => _selectedStatus = status);
    ref
        .read(bookingsProvider.notifier)
        .setFilter(query: _searchQuery, status: status);
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return AppColors.warning;
      case BookingStatus.approved:
        return AppColors.info;
      case BookingStatus.scheduled:
        return AppColors.statusInProgress;
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  void _updateBookingStatusDialog(Booking booking, BookingStatus newStatus) {
    final notesController = TextEditingController(
      text: booking.adminNotes ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'Update Status to ${newStatus.label}',
          style: AppTypography.sectionTitle(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change booking status for ${booking.customer?.displayName ?? 'Customer'} (${booking.vehicle?.displayName ?? 'Vehicle'}) to "${newStatus.label}".',
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.standard),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: AppTypography.bodyMedium(),
              decoration: const InputDecoration(
                labelText: 'Admin Notes / Instructions',
                hintText: 'Optional instructions or reason...',
              ),
            ),
          ],
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
              backgroundColor: _getStatusColor(newStatus),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(bookingsProvider.notifier)
                    .updateBookingStatus(
                      id: booking.id,
                      status: newStatus,
                      adminNotes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking updated to ${newStatus.label}.'),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update booking: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text('Delete Booking', style: AppTypography.sectionTitle()),
        content: Text(
          'Are you sure you want to delete this booking request (#${booking.id.substring(0, 8).toUpperCase()})?',
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
                    .read(bookingsProvider.notifier)
                    .deleteBooking(booking.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking removed.'),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete booking: $e'),
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
    final bookingsAsync = ref.watch(bookingsProvider);

    return AdminShell(
      currentRoute: RoutePaths.adminBookings,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'SERVICE BOOKINGS INTAKE',
              subtitle:
                  'Customer appointment requests and workshop scheduling queue',
            ),
            const SizedBox(height: AppSpacing.compact),
            SearchFilterBar(
              searchHint: 'Search bookings by ID, client, or vehicle...',
              onSearchChanged: _onSearchChanged,
              filterOptions: _statusFilters,
              selectedFilter: _selectedStatus,
              onFilterSelected: _onStatusFilterSelected,
            ),
            const SizedBox(height: AppSpacing.section),
            bookingsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.section),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => ErrorState(
                title: 'Failed to load bookings',
                message: err.toString(),
                onRetry: () => ref.refresh(bookingsProvider),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return EmptyState(
                    title: 'No Bookings in Queue',
                    message: _searchQuery.isNotEmpty || _selectedStatus != 'All'
                        ? 'No service appointments match the specified criteria.'
                        : 'No bookings have been submitted yet.',
                    icon: Icons.calendar_month_outlined,
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.standard),
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    final statusColor = _getStatusColor(b.status);
                    final shortId = b.id.length >= 8
                        ? b.id.substring(0, 8).toUpperCase()
                        : b.id.toUpperCase();

                    return PitCard(
                      technicalLabel: 'BOOKING SLOT • #$shortId',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  b.requestedService,
                                  style: AppTypography.sectionTitle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  StatusBadge(
                                    label: b.status.label.toUpperCase(),
                                    color: statusColor,
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
                                        case 'approve':
                                          _updateBookingStatusDialog(
                                            b,
                                            BookingStatus.approved,
                                          );
                                          break;
                                        case 'schedule':
                                          _updateBookingStatusDialog(
                                            b,
                                            BookingStatus.scheduled,
                                          );
                                          break;
                                        case 'complete':
                                          _updateBookingStatusDialog(
                                            b,
                                            BookingStatus.completed,
                                          );
                                          break;
                                        case 'reject':
                                          _updateBookingStatusDialog(
                                            b,
                                            BookingStatus.rejected,
                                          );
                                          break;
                                        case 'cancel':
                                          _updateBookingStatusDialog(
                                            b,
                                            BookingStatus.cancelled,
                                          );
                                          break;
                                        case 'delete':
                                          _confirmDeleteBooking(b);
                                          break;
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      if (b.status != BookingStatus.approved)
                                        const PopupMenuItem(
                                          value: 'approve',
                                          child: Text('Approve Booking'),
                                        ),
                                      if (b.status != BookingStatus.scheduled)
                                        const PopupMenuItem(
                                          value: 'schedule',
                                          child: Text('Schedule Appointment'),
                                        ),
                                      if (b.status != BookingStatus.completed)
                                        const PopupMenuItem(
                                          value: 'complete',
                                          child: Text('Mark Completed'),
                                        ),
                                      if (b.status != BookingStatus.rejected)
                                        const PopupMenuItem(
                                          value: 'reject',
                                          child: Text('Reject Booking'),
                                        ),
                                      if (b.status != BookingStatus.cancelled)
                                        const PopupMenuItem(
                                          value: 'cancel',
                                          child: Text('Cancel Booking'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Record',
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
                            'Client: ${b.customer?.displayName ?? 'Unknown Client'} • Vehicle: ${b.vehicle?.displayName ?? 'Vehicle'} (${b.vehicle?.identifierLabel ?? 'NO-PLATE'})',
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (b.description != null &&
                              b.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              b.description!,
                              style: AppTypography.bodySmall(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          if (b.adminNotes != null &&
                              b.adminNotes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Admin Note: ${b.adminNotes!}',
                              style: AppTypography.bodySmall(
                                color: AppColors.info,
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
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Scheduled Slot: ${b.preferredDate ?? 'Unspecified'} (${b.preferredTime ?? 'Flexible'})',
                                style: AppTypography.technical(
                                  color: AppColors.primaryAccent,
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
    );
  }
}
