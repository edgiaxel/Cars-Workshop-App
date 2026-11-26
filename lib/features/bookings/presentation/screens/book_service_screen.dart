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
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleOption {
  const VehicleOption({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
  });

  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final int year;

  String get displayName => '$make $model ($year)';
}

/// Customer Book Service screen allowing customers to schedule workshop visits.
class BookServiceScreen extends ConsumerStatefulWidget {
  const BookServiceScreen({
    super.key,
    this.initialVehicleId,
    this.bookingRepository,
    this.initialVehicles,
    this.initialCustomerId,
  });

  final String? initialVehicleId;
  final BookingRepository? bookingRepository;
  final List<VehicleOption>? initialVehicles;
  final String? initialCustomerId;

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BookingRepository _repo;

  bool _isLoadingVehicles = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String? _customerId;
  List<VehicleOption> _vehicles = [];
  String? _selectedVehicleId;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '08:00 - 10:00';
  String _selectedServiceType = 'Periodic Service';
  final _complaintsController = TextEditingController();

  static const List<String> _timeSlots = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '13:00 - 15:00',
    '15:00 - 17:00',
  ];

  static const List<String> _serviceTypes = [
    'Periodic Service',
    'Brake Service',
    'Engine Diagnostics',
    'General Repair',
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.bookingRepository ?? BookingRepository();
    if (widget.initialVehicles != null) {
      _vehicles = List.from(widget.initialVehicles!);
      _customerId = widget.initialCustomerId;
      if (_vehicles.isNotEmpty) {
        final hasInitial = widget.initialVehicleId != null &&
            _vehicles.any((v) => v.id == widget.initialVehicleId);
        _selectedVehicleId =
            hasInitial ? widget.initialVehicleId : _vehicles.first.id;
      }
    } else {
      _loadVehicles();
    }
  }

  @override
  void dispose() {
    _complaintsController.dispose();
    super.dispose();
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadVehicles() async {
    final client = _tryGetClient();
    if (client == null) {
      if (mounted) setState(() => _isLoadingVehicles = false);
      return;
    }

    setState(() {
      _isLoadingVehicles = true;
      _errorMessage = null;
    });

    try {
      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _vehicles = [];
            _selectedVehicleId = null;
            _isLoadingVehicles = false;
          });
        }
        return;
      }

      final custData = await client
          .from('customers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (custData == null) {
        if (mounted) {
          setState(() {
            _vehicles = [];
            _selectedVehicleId = null;
            _isLoadingVehicles = false;
          });
        }
        return;
      }

      _customerId = custData['id'] as String;
      final vehicleRows = await client
          .from('vehicles')
          .select('id, license_plate, make, model, year')
          .eq('customer_id', _customerId!)
          .order('created_at', ascending: false);

      final loaded = (vehicleRows as List).map((row) {
        return VehicleOption(
          id: row['id'] as String,
          licensePlate: (row['license_plate'] as String?) ?? '',
          make: (row['make'] as String?) ?? 'Vehicle',
          model: (row['model'] as String?) ?? '',
          year: (row['year'] as int?) ?? DateTime.now().year,
        );
      }).toList();

      if (mounted) {
        final hasInitial = widget.initialVehicleId != null &&
            loaded.any((v) => v.id == widget.initialVehicleId);
        setState(() {
          _vehicles = loaded;
          _selectedVehicleId = loaded.isEmpty
              ? null
              : (hasInitial ? widget.initialVehicleId : loaded.first.id);
          _isLoadingVehicles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load garage vehicles: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 60));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT SERVICE DATE',
      confirmText: 'CONFIRM',
      cancelText: 'CANCEL',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null || _customerId == null) {
      setState(() {
        _errorMessage = 'Please select a registered vehicle before booking.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final formattedDate =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final payload = {
      'customer_id': _customerId!,
      'vehicle_id': _selectedVehicleId,
      'booking_date': formattedDate,
      'time_slot': _selectedTimeSlot,
      'service_type': _selectedServiceType,
      'customer_notes': _complaintsController.text.trim(),
      'status': BookingStatus.pending.toDbString(),
    };

    try {
      await _repo.createBooking(payload);
      if (mounted) {
        _showSuccessDialog(formattedDate);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _errorMessage = 'Booking failed: $msg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $msg'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String formattedDate) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Booking Confirmed')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your appointment request for $_selectedServiceType has been received.',
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: 12),
              Text(
                'Date: $formattedDate\nSlot: $_selectedTimeSlot',
                style: AppTypography.telemetrySmall(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Our workshop team will review and confirm your slot.',
                style: AppTypography.bodySmall(),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            key: const Key('booking-success-ok-button'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go(RoutePaths.customerAppointments);
              }
            },
            child: const Text('VIEW APPOINTMENTS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    return ResponsiveRoleScaffold(
      roleTitle: 'Book Workshop Service',
      userName: userName,
      userSubtitle: 'Verified Member',
      currentIndex: 1,
      showBackButton: true,
      onBack: () => context.canPop() ? context.pop() : context.go(RoutePaths.customerGarage),
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.customerNavItems,
        i,
        currentIndex: 1,
      ),
      navItems: RoleNavigation.customerNavItems,
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: const [NotificationBellButton()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SCHEDULE SERVICE VISIT',
                    style: AppTypography.headlineSmall(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your vehicle, preferred calendar date, inspection window, and description of service needs.',
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedSmall,
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  PitCard(
                    accentBorderLeft: AppColors.accentRed,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. SELECT VEHICLE',
                          style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingVehicles)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: AppColors.accentRed),
                            ),
                          )
                        else if (_vehicles.isEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No vehicles registered in your garage yet. Register a vehicle first to book a workshop visit.',
                                style: AppTypography.bodyMedium(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                key: const Key('go-to-garage-button'),
                                onPressed: () => context.go(RoutePaths.customerGarage),
                                icon: const Icon(Icons.directions_car_outlined, size: 18),
                                label: const Text('REGISTER A VEHICLE'),
                              ),
                            ],
                          )
                        else
                          DropdownButtonFormField<String>(
                            key: const Key('book-service-vehicle-dropdown'),
                            isExpanded: true,
                            initialValue: _selectedVehicleId,
                            decoration: const InputDecoration(
                              labelText: 'Garage Vehicle',
                              prefixIcon: Icon(Icons.directions_car),
                            ),
                            items: _vehicles.map((v) {
                              return DropdownMenuItem<String>(
                                value: v.id,
                                child: Text('${v.displayName} [${v.licensePlate}]'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedVehicleId = val);
                            },
                            validator: (val) => val == null ? 'Please select a vehicle' : null,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  PitCard(
                    accentBorderLeft: AppColors.info,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. DATE & ARRIVAL WINDOW',
                          style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          key: const Key('book-service-date-picker'),
                          onTap: _pickDate,
                          borderRadius: AppSpacing.roundedMedium,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                              borderRadius: AppSpacing.roundedMedium,
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: AppColors.accentRed),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BOOKING DATE',
                                        style: AppTypography.telemetrySmall(
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                        style: AppTypography.labelLarge(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit_calendar, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AVAILABLE TIME SLOTS',
                          style: AppTypography.telemetrySmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _timeSlots.map((slot) {
                            final isSelected = _selectedTimeSlot == slot;
                            return ChoiceChip(
                              key: Key('slot-chip-$slot'),
                              label: Text(slot),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedTimeSlot = slot);
                              },
                              selectedColor: AppColors.accentRed.withValues(alpha: 0.18),
                              labelStyle: AppTypography.labelMedium(
                                color: isSelected ? AppColors.accentRed : textColor,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  PitCard(
                    accentBorderLeft: AppColors.warning,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3. SERVICE TYPE',
                          style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const Key('book-service-type-dropdown'),
                          isExpanded: true,
                          initialValue: _selectedServiceType,
                          decoration: const InputDecoration(
                            labelText: 'Service Category',
                            prefixIcon: Icon(Icons.build_circle_outlined),
                          ),
                          items: _serviceTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedServiceType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  PitCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4. COMPLAINTS & SPECIFIC REQUESTS',
                          style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('book-service-complaints-input'),
                          controller: _complaintsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Detail symptoms, warning lights, strange noises, brake vibration, or maintenance goals...',
                            alignLabelWithHint: true,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please describe the symptoms or reason for service';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      key: const Key('submit-booking-button'),
                      onPressed: (_isSubmitting || _vehicles.isEmpty) ? null : _submitBooking,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        _isSubmitting ? 'SUBMITTING BOOKING...' : 'CONFIRM SERVICE APPOINTMENT',
                        style: AppTypography.labelLarge(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
