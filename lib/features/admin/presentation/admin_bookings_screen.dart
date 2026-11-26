import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/admin/presentation/widgets/customer_intake_modal.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/bookings/data/models/booking_model.dart';
import 'package:pitmate/features/bookings/data/repositories/booking_repository.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Workshop Bookings Screen for booking triage, scheduling, and intake dispatch.
class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({
    super.key,
    this.bookingRepository,
    this.initialBookings,
  });

  final BookingRepository? bookingRepository;
  final List<BookingModel>? initialBookings;

  @override
  ConsumerState<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  late final BookingRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  BookingStatus? _filterStatus;
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _repo = widget.bookingRepository ?? BookingRepository();
    if (widget.initialBookings != null) {
      _bookings = List.from(widget.initialBookings!);
    } else {
      _loadBookings();
    }
  }

  bool get _hasSupabase {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadBookings() async {
    if (widget.bookingRepository == null && !_hasSupabase) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final loaded = await _repo.fetchAdminBookings();
      if (mounted) {
        setState(() {
          _bookings = loaded;
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

  void _onNavChanged(int index) {
    RoleNavigation.navigate(
      context,
      RoleNavigation.adminNavItems,
      index,
      currentIndex: 3,
    );
  }

  Future<void> _confirmBooking(BookingModel booking) async {
    try {
      await _repo.updateBookingStatus(booking.id, BookingStatus.confirmed);
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking for ${booking.customerName ?? "Customer"} confirmed.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm booking: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(BookingModel booking) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Booking Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Specify reason for declining the appointment request from ${booking.customerName ?? "Customer"}:'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reject-reason-input'),
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'e.g. Workshop at capacity for selected bay/time window',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            key: const Key('confirm-reject-booking-button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('REJECT BOOKING'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      try {
        await _repo.updateBookingStatus(
          booking.id,
          BookingStatus.rejected,
          adminNotes: reason.isNotEmpty ? reason : 'Booking declined by workshop dispatch',
        );
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rejected.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject booking: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _rescheduleBooking(BookingModel booking) async {
    DateTime pickedDate = booking.bookingDate;
    String pickedSlot = booking.timeSlot;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Reschedule Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select new date and time slot for ${booking.customerName ?? "Customer"}:'),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    'DATE: ${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}',
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: pickedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (d != null) {
                      setDialogState(() => pickedDate = d);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Time Slot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: pickedSlot,
                  items: const [
                    DropdownMenuItem(value: '08:00 - 10:00', child: Text('08:00 - 10:00')),
                    DropdownMenuItem(value: '10:00 - 12:00', child: Text('10:00 - 12:00')),
                    DropdownMenuItem(value: '13:00 - 15:00', child: Text('13:00 - 15:00')),
                    DropdownMenuItem(value: '15:00 - 17:00', child: Text('15:00 - 17:00')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => pickedSlot = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                key: const Key('confirm-reschedule-button'),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('SAVE RESCHEDULE'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.rescheduleBooking(booking.id, pickedDate, pickedSlot);
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rescheduled successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reschedule booking: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _openIntakeModal({BookingModel? booking}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => CustomerIntakeModal(
        booking: booking,
        onIntakeCompleted: (order) {
          _loadBookings();
        },
      ),
    );
  }

  Color _statusAccent(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.pending:
      case BookingStatus.rescheduled:
        return AppColors.warning;
      case BookingStatus.checked_in:
        return AppColors.info;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return AppColors.danger;
    }
  }

  StatusBadge _statusBadge(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return StatusBadge.success('CONFIRMED', icon: Icons.check_circle_outline);
      case BookingStatus.pending:
        return StatusBadge.warning('PENDING REVIEW', icon: Icons.hourglass_top);
      case BookingStatus.rescheduled:
        return StatusBadge.warning('RESCHEDULED', icon: Icons.schedule);
      case BookingStatus.checked_in:
        return StatusBadge.info('CHECKED IN', icon: Icons.directions_car);
      case BookingStatus.cancelled:
        return StatusBadge.danger('CANCELLED', icon: Icons.cancel_outlined);
      case BookingStatus.rejected:
        return StatusBadge.danger('REJECTED', icon: Icons.block);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    final filtered = _bookings.where((b) {
      if (_filterStatus != null && b.status != _filterStatus) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (b.customerName?.toLowerCase().contains(q) ?? false) ||
          (b.customerPhone?.contains(q) ?? false) ||
          (b.vehiclePlate?.toLowerCase().contains(q) ?? false) ||
          b.serviceType.toLowerCase().contains(q) ||
          b.id.toLowerCase().contains(q);
    }).toList();

    final pendingCount = _bookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmedCount = _bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final checkedInCount = _bookings.where((b) => b.status == BookingStatus.checked_in).length;

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Bookings',
      userName: userName,
      userSubtitle: 'Workshop Director',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.admin),
      currentIndex: 3,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: 'LIVE DISPATCH SCHEDULER',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _loadBookings,
          tooltip: 'Refresh Bookings',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('admin-walk-in-intake-fab'),
        onPressed: () => _openIntakeModal(),
        backgroundColor: AppColors.racingRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('WALK-IN INTAKE'),
      ),
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
                          onPressed: _loadBookings,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL BOOKINGS',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${_bookings.length}', style: AppTypography.headlineLarge(color: textColor)),
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
                              'PENDING REVIEW',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$pendingCount', style: AppTypography.headlineLarge(color: AppColors.warning)),
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
                              'CONFIRMED',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$confirmedCount', style: AppTypography.headlineLarge(color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        accentBorderLeft: AppColors.info,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHECKED IN',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$checkedInCount', style: AppTypography.headlineLarge(color: AppColors.info)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('admin-booking-search-input'),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by client, plate, phone, or service...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const Key('admin-new-walkin-intake-btn'),
                      onPressed: () => _openIntakeModal(),
                      icon: const Icon(Icons.sensor_door, size: 18),
                      label: const Text('NEW INTAKE'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Bookings'),
                      selected: _filterStatus == null,
                      onSelected: (_) => setState(() => _filterStatus = null),
                    ),
                    FilterChip(
                      label: const Text('Pending Review'),
                      selected: _filterStatus == BookingStatus.pending,
                      onSelected: (_) => setState(() => _filterStatus = BookingStatus.pending),
                    ),
                    FilterChip(
                      label: const Text('Confirmed'),
                      selected: _filterStatus == BookingStatus.confirmed,
                      onSelected: (_) => setState(() => _filterStatus = BookingStatus.confirmed),
                    ),
                    FilterChip(
                      label: const Text('Checked In'),
                      selected: _filterStatus == BookingStatus.checked_in,
                      onSelected: (_) => setState(() => _filterStatus = BookingStatus.checked_in),
                    ),
                    FilterChip(
                      label: const Text('Cancelled / Rejected'),
                      selected: _filterStatus == BookingStatus.cancelled,
                      onSelected: (_) => setState(() => _filterStatus = BookingStatus.cancelled),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accentRed),
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
                            Icons.calendar_today_outlined,
                            size: 40,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _bookings.isEmpty
                                ? 'No service bookings submitted yet.'
                                : 'No bookings match the current filter or search criteria.',
                            style: AppTypography.bodyMedium(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = filtered[index];
                      return _buildBookingRowCard(booking, isDark, textColor);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingRowCard(BookingModel booking, bool isDark, Color textColor) {
    final isPending = booking.status == BookingStatus.pending;
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final canIntake = booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending;

    return PitCard(
      accentBorderLeft: _statusAccent(booking.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentRed.withValues(alpha: 0.15),
                child: const Icon(Icons.person, size: 20, color: AppColors.accentRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          booking.customerName ?? 'Client Account',
                          style: AppTypography.headlineSmall(color: textColor),
                        ),
                        if (booking.vehiclePlate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.plateBackground,
                              borderRadius: AppSpacing.roundedSmall,
                              border: Border.all(color: AppColors.borderStrongDark, width: 1.0),
                            ),
                            child: Text(
                              booking.vehiclePlate!,
                              style: AppTypography.telemetrySmall(
                                color: AppColors.plateText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.customerPhone ?? "-"} • ${booking.vehicleDescription}',
                      style: AppTypography.bodySmall(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: AppColors.accentRed),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.bookingDate.year}-${booking.bookingDate.month.toString().padLeft(2, '0')}-${booking.bookingDate.day.toString().padLeft(2, '0')}',
                      style: AppTypography.telemetrySmall(color: textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, size: 16, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text(
                      booking.timeSlot,
                      style: AppTypography.telemetrySmall(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  booking.serviceType.toUpperCase(),
                  style: AppTypography.labelMedium(color: AppColors.accentRed, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (booking.customerNotes != null && booking.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Complaint: ${booking.customerNotes}',
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (booking.adminNotes != null && booking.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Admin Note: ${booking.adminNotes}',
              style: AppTypography.bodySmall(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (isPending) ...[
                OutlinedButton.icon(
                  key: Key('reject-booking-btn-${booking.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => _rejectBooking(booking),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('REJECT'),
                ),
                OutlinedButton.icon(
                  key: Key('reschedule-booking-btn-${booking.id}'),
                  onPressed: () => _rescheduleBooking(booking),
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('RESCHEDULE'),
                ),
                ElevatedButton.icon(
                  key: Key('approve-booking-btn-${booking.id}'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () => _confirmBooking(booking),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('APPROVE'),
                ),
              ],
              if (isConfirmed) ...[
                OutlinedButton.icon(
                  key: Key('reschedule-confirmed-btn-${booking.id}'),
                  onPressed: () => _rescheduleBooking(booking),
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('RESCHEDULE'),
                ),
              ],
              if (canIntake) ...[
                ElevatedButton.icon(
                  key: Key('intake-checkin-btn-${booking.id}'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.racingRed),
                  onPressed: () => _openIntakeModal(booking: booking),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('INTAKE CHECK-IN'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
