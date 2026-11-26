import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
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

/// Customer Appointments & Bookings Tracking Screen.
class CustomerAppointmentsScreen extends ConsumerStatefulWidget {
  const CustomerAppointmentsScreen({
    super.key,
    this.bookingRepository,
    this.initialBookings,
    this.initialCustomerId,
  });

  final BookingRepository? bookingRepository;
  final List<BookingModel>? initialBookings;
  final String? initialCustomerId;

  @override
  ConsumerState<CustomerAppointmentsScreen> createState() =>
      _CustomerAppointmentsScreenState();
}

class _CustomerAppointmentsScreenState
    extends ConsumerState<CustomerAppointmentsScreen> {
  late final BookingRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  String? _customerId;
  BookingStatus? _filterStatus;
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _repo = widget.bookingRepository ?? BookingRepository();
    if (widget.initialBookings != null) {
      _bookings = List.from(widget.initialBookings!);
      _customerId = widget.initialCustomerId;
    } else {
      _loadBookings();
    }
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadBookings() async {
    final client = _tryGetClient();
    if (client == null && widget.bookingRepository == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? custId = widget.initialCustomerId;
      if (custId == null && client != null) {
        final user = client.auth.currentUser;
        if (user == null) {
          if (mounted) {
            setState(() {
              _bookings = [];
              _isLoading = false;
            });
          }
          return;
        }
        final custData = await client
            .from('customers')
            .select('id')
            .eq('profile_id', user.id)
            .maybeSingle();
        custId = custData?['id'] as String?;
      }

      _customerId = custId;
      if (_customerId == null) {
        if (mounted) {
          setState(() {
            _bookings = [];
            _isLoading = false;
          });
        }
        return;
      }

      final loaded = await _repo.fetchCustomerBookings(_customerId!);
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

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: Text(
          'Are you sure you want to cancel your ${booking.serviceType} booking scheduled for '
          '${booking.bookingDate.year}-${booking.bookingDate.month.toString().padLeft(2, '0')}-${booking.bookingDate.day.toString().padLeft(2, '0')} '
          '(${booking.timeSlot})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('KEEP APPOINTMENT'),
          ),
          ElevatedButton(
            key: const Key('confirm-cancel-booking-button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('CANCEL BOOKING'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.updateBookingStatus(booking.id, BookingStatus.cancelled);
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment has been cancelled.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel appointment: ${e.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(
      context,
      RoleNavigation.customerNavItems,
      index,
      currentIndex: 2,
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
      return true;
    }).toList();

    return ResponsiveRoleScaffold(
      roleTitle: 'Service Appointments',
      userName: userName,
      userSubtitle: 'Verified Member',
      currentIndex: 2,
      onNavIndexChanged: _onNavChanged,
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
          onPressed: _loadBookings,
          tooltip: 'Refresh Appointments',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('book-new-appointment-fab'),
        onPressed: () async {
          await context.push(RoutePaths.bookService);
          _loadBookings();
        },
        backgroundColor: AppColors.racingRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('BOOK SERVICE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR WORKSHOP APPOINTMENTS',
                            style: AppTypography.headlineSmall(color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track booking status, arrival windows, and upcoming pit appointments.',
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const Key('book-new-appointment-btn'),
                      onPressed: () async {
                        await context.push(RoutePaths.bookService);
                        _loadBookings();
                      },
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('BOOK NEW SERVICE'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Appointments'),
                      selected: _filterStatus == null,
                      onSelected: (_) => setState(() => _filterStatus = null),
                    ),
                    FilterChip(
                      label: const Text('Pending'),
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
                      label: const Text('Cancelled'),
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
                            Icons.event_busy,
                            size: 40,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _bookings.isEmpty
                                ? 'No service appointments booked yet.'
                                : 'No appointments match the selected filter.',
                            style: AppTypography.bodyMedium(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push(RoutePaths.bookService),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('BOOK SERVICE NOW'),
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
                      return _buildBookingCard(booking, isDark, textColor);
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, bool isDark, Color textColor) {
    final canCancel =
        booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed;

    return PitCard(
      accentBorderLeft: _statusAccent(booking.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_circle, size: 20, color: AppColors.accentRed),
                  const SizedBox(width: 8),
                  Text(
                    booking.serviceType.toUpperCase(),
                    style: AppTypography.headlineSmall(color: textColor),
                  ),
                ],
              ),
              _statusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.accentRed),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.bookingDate.year}-${booking.bookingDate.month.toString().padLeft(2, '0')}-${booking.bookingDate.day.toString().padLeft(2, '0')}',
                    style: AppTypography.telemetrySmall(color: textColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text(
                    booking.timeSlot,
                    style: AppTypography.telemetrySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              if (booking.vehiclePlate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          const SizedBox(height: 8),
          Text(
            booking.vehicleDescription,
            style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
          ),
          if (booking.customerNotes != null && booking.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                borderRadius: AppSpacing.roundedSmall,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.customerNotes!,
                      style: AppTypography.bodySmall(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (booking.adminNotes != null && booking.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Workshop Note: ${booking.adminNotes!}',
                      style: AppTypography.bodySmall(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: Key('cancel-booking-btn-${booking.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => _cancelBooking(booking),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('CANCEL APPOINTMENT'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
