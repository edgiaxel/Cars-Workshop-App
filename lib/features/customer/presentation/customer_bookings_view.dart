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

  void _openBookingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _CustomerBookingDialog(
        onBookingCreated: () {
          ref.invalidate(customerBookingsProvider(null));
        },
      ),
    );
  }

  void _confirmCancelBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
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
                    return EmptyState(
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
                      final statusColor = _getStatusColor(b.status);
                      final isCancellable =
                          b.status == BookingStatus.requested ||
                          b.status == BookingStatus.scheduled;
                      final shortId = b.id.length >= 8
                          ? b.id.substring(0, 8).toUpperCase()
                          : b.id.toUpperCase();

                      return PitCard(
                        technicalLabel: 'BOOKING CONFIRMATION • #$shortId',
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
                                    if (isCancellable) ...[
                                      const SizedBox(width: AppSpacing.compact),
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
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Text(
                              'Vehicle: ${b.vehicle?.displayName ?? 'Your Vehicle'} (${b.vehicle?.identifierLabel ?? 'NO-PLATE'})',
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
                                'Workshop Note: ${b.adminNotes!}',
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
                                  'Appointment: ${b.preferredDate ?? 'Flexible'} (${b.preferredTime ?? 'Anytime'})',
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

    return Dialog(
      backgroundColor: AppColors.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      'Book Workshop Service',
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

                    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
                      _selectedVehicleId = vehicles.first.id;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleId,
                      dropdownColor: AppColors.surfacePrimary,
                      decoration: const InputDecoration(
                        labelText: 'Select Vehicle *',
                      ),
                      items: vehicles
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
                          v == null ? 'Please select a vehicle' : null,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.compact),
                TextFormField(
                  controller: _serviceController,
                  style: AppTypography.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Requested Service *',
                    hintText: 'e.g. 10,000 KM Maintenance, Brake Inspection',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Service request is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.compact),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Preferred Date (YYYY-MM-DD) *',
                          hintText: '2026-10-20',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Date is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Preferred Time (HH:MM) *',
                          hintText: '09:00:00',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Time is required'
                            : null,
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
                    labelText: 'Service Notes / Symptoms',
                    hintText: 'Describe issues, strange noises, or specific requests...',
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
                      text: 'Submit Request',
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
