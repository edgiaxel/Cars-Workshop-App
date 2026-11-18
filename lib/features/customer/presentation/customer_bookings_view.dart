import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/booking.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'customer_shell.dart';

/// Customer bookings view backed by real Supabase records adhering to DESIGN.md.
class CustomerBookingsPage extends ConsumerStatefulWidget {
  const CustomerBookingsPage({super.key});

  @override
  ConsumerState<CustomerBookingsPage> createState() =>
      _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends ConsumerState<CustomerBookingsPage> {
  void _openBookingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor:
              isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: _CustomerBookingDialog(
              onBookingCreated: () {
                ref.invalidate(customerBookingsProvider(null));
              },
            ),
          ),
        );
      },
    );
  }

  void _showRescheduleDialog(Booking booking) {
    final nextDay = DateTime.now().add(const Duration(days: 1));
    final dateCtrl = TextEditingController(
      text:
          '${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}',
    );
    final timeCtrl = TextEditingController(text: '10:00:00');
    bool isSaving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final dialogBg =
              isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard;
          final textPrimary =
              isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: dialogBg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.standard),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'RESCHEDULE APPOINTMENT',
                      style: AppTypography.sectionTitle(color: textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      'Reschedule your missed booking for ${booking.requestedService} within the 24-hour grace window.',
                      style: AppTypography.bodySmall(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    TextFormField(
                      controller: dateCtrl,
                      style: AppTypography.bodyMedium(color: textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'New Preferred Date (YYYY-MM-DD) *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    TextFormField(
                      controller: timeCtrl,
                      style: AppTypography.bodyMedium(color: textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'New Preferred Time (HH:MM:SS) *',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'Cancel',
                            onPressed:
                                isSaving ? null : () => Navigator.pop(dialogCtx),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.standard),
                        Expanded(
                          child: PrimaryButton(
                            text: isSaving ? 'Saving...' : 'Confirm Reschedule',
                            isLoading: isSaving,
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setDialogState(() => isSaving = true);
                                    try {
                                      await ref
                                          .read(bookingsProvider.notifier)
                                          .updateBooking(
                                            id: booking.id,
                                            preferredDate: dateCtrl.text.trim(),
                                            preferredTime: timeCtrl.text.trim(),
                                          );
                                      ref.invalidate(
                                        customerBookingsProvider(null),
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(dialogCtx);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Appointment rescheduled successfully.',
                                                ),
                                                backgroundColor:
                                                    AppColors.statusCompleted,
                                              ),
                                            );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSaving = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to reschedule: $e',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmCancelBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Cancel Appointment', style: AppTypography.sectionTitle()),
        content: Text(
          'Are you sure you want to cancel your booking for ${booking.requestedService}?',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Keep Booking',
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
                    .updateBookingStatus(
                      id: booking.id,
                      status: BookingStatus.cancelled,
                    );
                ref.invalidate(customerBookingsProvider(null));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment has been cancelled.'),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel appointment: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(customerBookingsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return CustomerShell(
      currentRoute: RoutePaths.customerBookings,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(customerBookingsProvider(null).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'SERVICE APPOINTMENTS',
                subtitle:
                    'Active bookings and scheduling requests with the workshop',
                action: PrimaryButton(
                  text: 'Book Service',
                  icon: Icons.calendar_today,
                  width: 150,
                  onPressed: _openBookingDialog,
                ),
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
                  title: 'Failed to load appointments',
                  message: err.toString(),
                  onRetry: () => ref.refresh(customerBookingsProvider(null)),
                ),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return const EmptyState(
                      title: 'No Upcoming Appointments',
                      message: 'You have no scheduled bookings at this time. Book your next pitstop appointment!',
                      icon: Icons.calendar_today_outlined,
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
                      final isCancellable =
                          b.status == BookingStatus.requested ||
                          b.status == BookingStatus.scheduled;
                      final shortId = b.id.length >= 8
                          ? b.id.substring(0, 8).toUpperCase()
                          : b.id.toUpperCase();

                      DateTime? appointmentTime;
                      if (b.preferredDate != null) {
                        final timeStr = b.preferredTime ?? '09:00:00';
                        appointmentTime = DateTime.tryParse(
                          '${b.preferredDate} $timeStr',
                        );
                      }
                      final now = DateTime.now();
                      final isPast = appointmentTime != null &&
                          now.isAfter(appointmentTime);
                      final isWithin24hGrace = isPast &&
                          now.difference(appointmentTime).inHours < 24 &&
                          (b.status == BookingStatus.requested ||
                              b.status == BookingStatus.scheduled);

                      return PitCard(
                        technicalLabel: 'BOOKING CONFIRMATION • #$shortId',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    b.requestedService,
                                    style: AppTypography.sectionTitle(
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                if (isCancellable)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      size: 20,
                                    ),
                                    color: AppColors.error,
                                    tooltip: 'Cancel Booking',
                                    onPressed: () =>
                                        _confirmCancelBooking(b),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              children: [
                                StatusBadge.forBookingStatus(b.status),
                                if (isWithin24hGrace) ...[
                                  const SizedBox(width: AppSpacing.compact),
                                  StatusBadge(
                                    label: 'Grace Period (Reschedule)',
                                    color: AppColors.warning,
                                  ),
                                ],
                              ],
                            ),
                            if (isWithin24hGrace) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.compact),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.warning),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.warning,
                                          size: 18,
                                        ),
                                        const SizedBox(width: AppSpacing.compact),
                                        Expanded(
                                          child: Text(
                                            'Missed appointment. You have 24 hours to reschedule before automatic cancellation.',
                                            style: AppTypography.bodySmall(
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.compact),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _showRescheduleDialog(b),
                                        icon: const Icon(Icons.edit_calendar, size: 16),
                                        label: const Text('Reschedule'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.compact),
                            Text(
                              'Vehicle: ${b.vehicle?.displayName ?? 'Your Vehicle'} (${b.vehicle?.identifierLabel ?? 'NO-PLATE'})',
                              style: AppTypography.bodySmall(
                                color: textSecondary,
                              ),
                            ),
                            if (b.description != null &&
                                b.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                b.description!,
                                style: AppTypography.bodySmall(
                                  color: textMuted,
                                ),
                              ),
                            ],
                            if (b.adminNotes != null &&
                                b.adminNotes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Workshop Note: ${b.adminNotes!}',
                                style: AppTypography.bodySmall(
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            Divider(
                              color: borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Appointment: ${b.preferredDate ?? 'Flexible'} (${b.preferredTime ?? 'Anytime'})',
                                      style: AppTypography.technical(
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isCancellable && !isWithin24hGrace)
                                  TextButton.icon(
                                    onPressed: () => _showRescheduleDialog(b),
                                    icon: const Icon(Icons.edit_calendar, size: 14),
                                    label: const Text('Reschedule'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
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

class _CustomerBookingDialog extends ConsumerStatefulWidget {
  const _CustomerBookingDialog({required this.onBookingCreated});

  final VoidCallback onBookingCreated;

  @override
  ConsumerState<_CustomerBookingDialog> createState() =>
      _CustomerBookingDialogState();
}

class _CustomerBookingDialogState
    extends ConsumerState<_CustomerBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String? _selectedVehicleId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(days: 1));
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _timeController.text = '09:00:00';
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      setState(
        () => _errorMessage = 'Please select a vehicle from your garage.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentCustomer = await ref.read(currentCustomerProvider.future);
      if (currentCustomer == null) {
        throw Exception('Could not resolve your customer account.');
      }

      await ref
          .read(bookingsProvider.notifier)
          .createBooking(
            customerId: currentCustomer.id,
            vehicleId: _selectedVehicleId!,
            requestedService: _serviceController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            preferredDate: _dateController.text.trim(),
            preferredTime: _timeController.text.trim(),
          );

      widget.onBookingCreated();
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
    final vehiclesAsync = ref.watch(customerVehiclesProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BOOK WORKSHOP SERVICE',
                style: AppTypography.sectionTitle(color: textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
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
                    vehiclesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text(
                        'Error loading vehicles: $e',
                        style: AppTypography.bodySmall(color: AppColors.error),
                      ),
                      data: (vehicles) {
                        if (vehicles.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.compact),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning),
                            ),
                            child: Text(
                              'No registered vehicles found. Please add a vehicle to your garage before booking.',
                              style: AppTypography.bodySmall(
                                color: AppColors.warning,
                              ),
                            ),
                          );
                        }

                        if (_selectedVehicleId == null &&
                            vehicles.isNotEmpty) {
                          _selectedVehicleId = vehicles.first.id;
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedVehicleId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Vehicle *',
                          ),
                          items: vehicles
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
                              v == null ? 'Please select a vehicle' : null,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    TextFormField(
                      controller: _serviceController,
                      style: AppTypography.bodyMedium(color: textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Requested Service *',
                        hintText:
                            'e.g. 10,000 KM Maintenance, Brake Inspection',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Service request is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    TextFormField(
                      controller: _dateController,
                      style: AppTypography.bodyMedium(color: textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Preferred Date (YYYY-MM-DD) *',
                        hintText: '2026-10-20',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Date is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    TextFormField(
                      controller: _timeController,
                      style: AppTypography.bodyMedium(color: textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Preferred Time (HH:MM:SS) *',
                        hintText: '09:00:00',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Time is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: AppTypography.bodyMedium(color: textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Service Notes / Symptoms',
                        hintText:
                            'Describe issues, strange noises, or specific requests...',
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
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.standard),
              Expanded(
                child: PrimaryButton(
                  text: 'Submit Request',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
