import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/bookings/data/models/booking_model.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import 'package:pitmate/features/service_orders/data/repositories/service_order_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerLookupItem {
  const CustomerLookupItem({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.vehicles = const [],
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final List<VehicleLookupItem> vehicles;
}

class VehicleLookupItem {
  const VehicleLookupItem({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    this.mileage = 0,
  });

  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final int mileage;

  String get displayName => '$make $model ($year) [$licensePlate]';
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Customer & Vehicle Intake Modal Sheet (UI-A06) backed by live Supabase queries and RPCs.
class CustomerIntakeModal extends StatefulWidget {
  const CustomerIntakeModal({
    super.key,
    this.booking,
    this.initialCustomerId,
    this.initialVehicleId,
    this.onIntakeCompleted,
    this.serviceOrderRepository,
    this.initialCustomers,
  });

  final BookingModel? booking;
  final String? initialCustomerId;
  final String? initialVehicleId;
  final ValueChanged<ServiceOrderModel>? onIntakeCompleted;
  final ServiceOrderRepository? serviceOrderRepository;
  final List<CustomerLookupItem>? initialCustomers;

  @override
  State<CustomerIntakeModal> createState() => _CustomerIntakeModalState();
}

class _CustomerIntakeModalState extends State<CustomerIntakeModal> {
  final _formKey = GlobalKey<FormState>();
  late final ServiceOrderRepository _repo;

  int _clientMode = 0;
  bool _isLoadingLookups = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<CustomerLookupItem> _customers = [];
  String? _selectedCustomerId;
  List<VehicleLookupItem> _customerVehicles = [];
  String? _selectedVehicleId;

  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _guestPlateController = TextEditingController();
  final _guestMakeController = TextEditingController();
  final _guestModelController = TextEditingController();
  final _guestYearController = TextEditingController();

  final _odometerController = TextEditingController();
  final _complaintController = TextEditingController();
  final _initialNotesController = TextEditingController();
  String _selectedFuelLevel = '1/2';
  List<String> _bayOptions = ['Unassigned'];
  String _selectedBay = 'Unassigned';

  static const List<String> _fuelLevels = ['1/4', '1/2', '3/4', 'Full'];

  @override
  void initState() {
    super.initState();
    _repo = widget.serviceOrderRepository ?? ServiceOrderRepository();

    if (widget.booking != null) {
      _complaintController.text =
          widget.booking!.customerNotes ?? widget.booking!.serviceType;
      _selectedCustomerId = widget.booking!.customerId;
      _selectedVehicleId = widget.booking!.vehicleId;
    } else {
      _selectedCustomerId = widget.initialCustomerId;
      _selectedVehicleId = widget.initialVehicleId;
    }

    if (widget.initialCustomers != null) {
      _customers = List.from(widget.initialCustomers!);
      _syncCustomerSelection();
    } else {
      _loadLookupData();
    }
  }

  void _syncCustomerSelection() {
    if (_customers.isEmpty) {
      _customerVehicles = [];
      _selectedVehicleId = null;
      return;
    }
    _selectedCustomerId ??= _customers.first.id;
    final match = _customers.where((c) => c.id == _selectedCustomerId).firstOrNull ??
        _customers.first;
    _selectedCustomerId = match.id;
    _customerVehicles = match.vehicles;
    if (_selectedVehicleId == null ||
        !_customerVehicles.any((v) => v.id == _selectedVehicleId)) {
      _selectedVehicleId = _customerVehicles.firstOrNull?.id;
    }
    final selectedVeh =
        _customerVehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
    if (selectedVeh != null && selectedVeh.mileage > 0) {
      _odometerController.text = selectedVeh.mileage.toString();
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestPlateController.dispose();
    _guestMakeController.dispose();
    _guestModelController.dispose();
    _guestYearController.dispose();
    _odometerController.dispose();
    _complaintController.dispose();
    _initialNotesController.dispose();
    super.dispose();
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLookupData() async {
    final client = _tryGetClient();
    if (client == null) {
      if (mounted) setState(() => _isLoadingLookups = false);
      return;
    }

    setState(() {
      _isLoadingLookups = true;
      _errorMessage = null;
    });

    try {
      final baysRes = await client
          .from('workshop_bays')
          .select('name, bay_number')
          .order('bay_number', ascending: true);

      final loadedBayNames = (baysRes as List)
          .map((row) => (row['name'] as String?) ?? 'Bay ${row['bay_number']}')
          .toList();

      if (widget.booking != null) {
        final vehRow = await client
            .from('vehicles')
            .select('mileage')
            .eq('id', widget.booking!.vehicleId)
            .maybeSingle();
        final currentKm = (vehRow?['mileage'] as int?) ?? 0;

        if (mounted) {
          setState(() {
            _bayOptions = ['Unassigned', ...loadedBayNames];
            _selectedBay =
                loadedBayNames.isNotEmpty ? loadedBayNames.first : 'Unassigned';
            if (currentKm > 0 && _odometerController.text.isEmpty) {
              _odometerController.text = currentKm.toString();
            }
            _isLoadingLookups = false;
          });
        }
        return;
      }

      final customerData = await client
          .from('customers')
          .select(
            'id, full_name, phone_number, vehicles(id, license_plate, make, model, year, mileage)',
          )
          .order('full_name');

      final loaded = (customerData as List).map((row) {
        final vList = (row['vehicles'] as List? ?? []).map((v) {
          return VehicleLookupItem(
            id: v['id'] as String,
            licensePlate: (v['license_plate'] as String?) ?? '',
            make: (v['make'] as String?) ?? 'Vehicle',
            model: (v['model'] as String?) ?? '',
            year: (v['year'] as int?) ?? DateTime.now().year,
            mileage: (v['mileage'] as int?) ?? 0,
          );
        }).toList();

        return CustomerLookupItem(
          id: row['id'] as String,
          fullName: (row['full_name'] as String?) ?? 'Customer',
          phoneNumber: (row['phone_number'] as String?) ?? '',
          vehicles: vList,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _customers = loaded;
          _bayOptions = ['Unassigned', ...loadedBayNames];
          _selectedBay =
              loadedBayNames.isNotEmpty ? loadedBayNames.first : 'Unassigned';
          _syncCustomerSelection();
          _isLoadingLookups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoadingLookups = false;
        });
      }
    }
  }

  void _onCustomerSelected(String? customerId) {
    if (customerId == null) return;
    setState(() {
      _selectedCustomerId = customerId;
      final match = _customers.where((c) => c.id == customerId).firstOrNull;
      _customerVehicles = match?.vehicles ?? [];
      _selectedVehicleId = _customerVehicles.firstOrNull?.id;
      if (_customerVehicles.isNotEmpty && _customerVehicles.first.mileage > 0) {
        _odometerController.text = _customerVehicles.first.mileage.toString();
      } else {
        _odometerController.clear();
      }
    });
  }

  Future<void> _submitIntake() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final isBooking = widget.booking != null;
    if (!isBooking && _clientMode == 0 &&
        (_selectedCustomerId == null || _selectedVehicleId == null)) {
      setState(() {
        _errorMessage = 'Please select both a registered customer and a vehicle.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final odometer = int.tryParse(_odometerController.text.trim()) ?? 0;
    final complaint = _complaintController.text.trim();
    final notes = _initialNotesController.text.trim();

    String finalCustomerId = _selectedCustomerId ?? '';
    String finalVehicleId = _selectedVehicleId ?? '';

    try {
      if (!isBooking && _clientMode == 1) {
        final client = Supabase.instance.client;
        final guestName = _guestNameController.text.trim();
        final guestPhone = _guestPhoneController.text.trim();
        final guestPlate = _guestPlateController.text.trim().toUpperCase();

        final custInsert = await client
            .from('customers')
            .insert({
              'full_name': guestName,
              'phone_number': guestPhone,
              'is_guest': true,
              'customer_type': 'individual',
            })
            .select()
            .single();

        finalCustomerId = custInsert['id'] as String;

        final vehicleInsert = await client
            .from('vehicles')
            .insert({
              'customer_id': finalCustomerId,
              'license_plate': guestPlate,
              'make': _guestMakeController.text.trim(),
              'model': _guestModelController.text.trim(),
              'year': int.tryParse(_guestYearController.text.trim()) ??
                  DateTime.now().year,
              'mileage': odometer,
              'notes': 'Intake Walk-in Guest Vehicle',
            })
            .select()
            .single();

        finalVehicleId = vehicleInsert['id'] as String;
      }

      final serviceOrder = await _repo.createIntake(
        customerId: finalCustomerId,
        vehicleId: finalVehicleId,
        odometer: odometer,
        customerComplaint: complaint,
        intakeType: isBooking ? 'booking' : 'walk_in',
        bookingId: widget.booking?.id,
        fuelLevel: _selectedFuelLevel,
        initialNotes: notes.isNotEmpty ? notes : null,
        assignedBay: _selectedBay,
      );

      if (mounted) {
        widget.onIntakeCompleted?.call(serviceOrder);
        _showSuccessDialog(serviceOrder);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(ServiceOrderModel serviceOrder) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Intake Registered')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Order successfully created and inspection session spawned.',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedLight,
                borderRadius: AppSpacing.roundedMedium,
                border: Border.all(color: AppColors.accentRed, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERVICE ORDER NUMBER',
                        style: AppTypography.telemetrySmall(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serviceOrder.orderNumber,
                        key: const Key('service-order-number-display'),
                        style: AppTypography.headlineSmall(
                          color: AppColors.racingRed,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge.inProgress('INSPECTION QUEUED'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Assigned: ${serviceOrder.assignedBay ?? _selectedBay}\nOdometer: ${serviceOrder.odometer} KM\nFuel: $_selectedFuelLevel',
              style: AppTypography.telemetrySmall(),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            key: const Key('dismiss-intake-dialog-btn'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('PROCEED TO DISPATCH'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final isBooking = widget.booking != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isBooking ? Icons.assignment_turned_in : Icons.sensor_door,
                          color: AppColors.accentRed,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isBooking
                                ? 'BOOKING INTAKE CHECK-IN'
                                : 'WORKSHOP VEHICLE INTAKE',
                            style: AppTypography.headlineSmall(color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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
                const SizedBox(height: 14),
              ],

              if (isBooking) ...[
                PitCard(
                  accentBorderLeft: AppColors.info,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'CONFIRMED APPOINTMENT',
                            style: AppTypography.telemetrySmall(
                              color: AppColors.info,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          StatusBadge.info(widget.booking!.serviceType.toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Client: ${widget.booking!.customerName ?? "Registered Customer"} (${widget.booking!.customerPhone ?? "-"})',
                        style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Vehicle: ${widget.booking!.vehicleDescription}',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled: ${widget.booking!.bookingDate.year}-${widget.booking!.bookingDate.month.toString().padLeft(2, '0')}-${widget.booking!.bookingDate.day.toString().padLeft(2, '0')} (${widget.booking!.timeSlot})',
                        style: AppTypography.telemetrySmall(color: AppColors.info),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        key: const Key('intake-mode-registered'),
                        label: const Center(child: Text('Existing Client')),
                        selected: _clientMode == 0,
                        onSelected: (val) {
                          if (val) setState(() => _clientMode = 0);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        key: const Key('intake-mode-walk-in'),
                        label: const Center(child: Text('Walk-in Guest')),
                        selected: _clientMode == 1,
                        onSelected: (val) {
                          if (val) setState(() => _clientMode = 1);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_clientMode == 0) ...[
                  if (_isLoadingLookups)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accentRed)),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      key: const Key('intake-customer-dropdown'),
                      isExpanded: true,
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Select Customer',
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      items: _customers.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text('${c.fullName} (${c.phoneNumber})'),
                        );
                      }).toList(),
                      onChanged: _onCustomerSelected,
                      validator: (val) => val == null ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('intake-vehicle-dropdown'),
                      isExpanded: true,
                      initialValue: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Select Vehicle',
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      items: _customerVehicles.map((v) {
                        return DropdownMenuItem<String>(
                          value: v.id,
                          child: Text(v.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedVehicleId = val;
                          final match =
                              _customerVehicles.where((v) => v.id == val).firstOrNull;
                          if (match != null && match.mileage > 0) {
                            _odometerController.text = match.mileage.toString();
                          }
                        });
                      },
                      validator: (val) => val == null
                          ? (_customerVehicles.isEmpty
                              ? 'Customer has no vehicles; switch to Walk-in Guest'
                              : 'Please select a vehicle')
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ] else ...[
                  TextFormField(
                    key: const Key('guest-name-input'),
                    controller: _guestNameController,
                    decoration: const InputDecoration(
                      labelText: 'Guest Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Please enter guest name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('guest-phone-input'),
                    controller: _guestPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Guest Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Please enter contact number' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('guest-plate-input'),
                    controller: _guestPlateController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                      _UpperCaseTextFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'License Plate (e.g. B 1234 XYZ)',
                      prefixIcon: Icon(Icons.pin),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Please enter license plate' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('guest-make-input'),
                          controller: _guestMakeController,
                          decoration: const InputDecoration(
                            labelText: 'Make',
                            hintText: 'Honda',
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: const Key('guest-model-input'),
                          controller: _guestModelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            hintText: 'Civic RS',
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          key: const Key('guest-year-input'),
                          controller: _guestYearController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            hintText: '2024',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              Text(
                'PHYSICAL INTAKE INSPECTION',
                style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: const Key('intake-odometer-input'),
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Odometer (KM)',
                        hintText: '15000',
                        prefixIcon: Icon(Icons.speed),
                        suffixText: 'KM',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter mileage';
                        final num = int.tryParse(val);
                        if (num == null || num <= 0) return 'Invalid KM';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      key: const Key('intake-fuel-dropdown'),
                      isExpanded: true,
                      initialValue: _selectedFuelLevel,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Level',
                        prefixIcon: Icon(Icons.local_gas_station),
                      ),
                      items: _fuelLevels
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFuelLevel = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                key: const Key('intake-complaint-input'),
                controller: _complaintController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Customer Complaint / Symptoms',
                  hintText: 'e.g. Engine shudder at idle, periodic maintenance, brake grinding...',
                  prefixIcon: Icon(Icons.report_problem_outlined),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please record customer complaint'
                    : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                key: const Key('intake-bay-dropdown'),
                isExpanded: true,
                initialValue: _bayOptions.contains(_selectedBay) ? _selectedBay : _bayOptions.first,
                decoration: const InputDecoration(
                  labelText: 'Assigned Shop Bay',
                  prefixIcon: Icon(Icons.garage),
                ),
                items: _bayOptions
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBay = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                key: const Key('intake-initial-notes-input'),
                controller: _initialNotesController,
                decoration: const InputDecoration(
                  labelText: 'Initial Notes / Technician Advisory (Optional)',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  key: const Key('submit-intake-button'),
                  onPressed: _isSubmitting ? null : _submitIntake,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    _isSubmitting
                        ? 'CREATING SERVICE ORDER...'
                        : (isBooking
                            ? 'CONFIRM CHECK-IN & SPAWN INSPECTION'
                            : 'CREATE SERVICE ORDER'),
                    style: AppTypography.labelLarge(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
