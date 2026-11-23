import 'package:flutter/material.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/service_operations/data/repositories/service_operations_repository.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';

class DispatchOperationsModal extends StatefulWidget {
  const DispatchOperationsModal({
    super.key,
    required this.serviceOrder,
    required this.onDispatched,
  });

  final ServiceOrderModel serviceOrder;
  final VoidCallback onDispatched;

  @override
  State<DispatchOperationsModal> createState() => _DispatchOperationsModalState();
}

class _DispatchOperationsModalState extends State<DispatchOperationsModal> {
  final _operationsRepo = ServiceOperationsRepository();

  int _selectedBayNumber = 1;
  String _selectedLeadMechanicId = '7294334d-7144-4c14-9d28-5f90e48a5fbb'; // Max Verstappen
  bool _isSubmitting = false;

  // Operations to dispatch
  final List<Map<String, dynamic>> _operations = [
    {
      'title': 'Front Brake Pad Replacement & Rotor Truing',
      'description': 'Replace worn Brembo composite pads, clean caliper pins, torque lug nuts to 108 Nm.',
      'estimated_duration_minutes': 45,
      'priority': 'high',
      'checklists': [
        'Inspect caliper sliding pins and silicone boots',
        'Install new ceramic compound brake pads',
        'Verify brake fluid reservoir level',
        'Torque wheel lug nuts to 108 Nm specification',
      ],
    },
    {
      'title': 'Brake System Bleeding & ABS Pressure Test',
      'description': 'High-temperature DOT 5.1 fluid flush and diagnostic pressure test.',
      'estimated_duration_minutes': 30,
      'priority': 'medium',
      'checklists': [
        'Connect pressurized bleeder system',
        'Flush fluid sequentially (RR, RL, FR, FL)',
        'Perform diagnostic ABS purge cycle',
      ],
    },
  ];

  Future<void> _handleDispatch() async {
    setState(() => _isSubmitting = true);

    try {
      await _operationsRepo.dispatchOperations(
        serviceOrderId: widget.serviceOrder.id,
        tasks: _operations,
        leadMechanicId: _selectedLeadMechanicId,
        bayNumber: _selectedBayNumber,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDispatched();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully dispatched operations for ${widget.serviceOrder.orderNumber} to Bay 0$_selectedBayNumber',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DISPATCH WORKSHOP OPERATIONS',
                  style: AppTypography.headlineMedium(color: textColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Order: ${widget.serviceOrder.orderNumber} • ${widget.serviceOrder.vehicleDescription}',
              style: AppTypography.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Bay Selector
            Text(
              'SELECT PHYSICAL SERVICE BAY',
              style: AppTypography.labelSmall(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedBayNumber,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceElevatedLight,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedSmall,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Bay 01 - Quick Service')),
                DropdownMenuItem(value: 2, child: Text('Bay 02 - Diagnostic & Performance')),
                DropdownMenuItem(value: 3, child: Text('Bay 03 - Heavy Repair')),
                DropdownMenuItem(value: 4, child: Text('Bay 04 - Electrical & Electronics')),
                DropdownMenuItem(value: 5, child: Text('Bay 05 - Suspension & Brakes')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedBayNumber = v);
              },
            ),
            const SizedBox(height: 14),

            // Lead Mechanic Selector
            Text(
              'ASSIGN LEAD PERFORMANCE TECHNICIAN',
              style: AppTypography.labelSmall(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedLeadMechanicId,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceElevatedLight,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedSmall,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: '7294334d-7144-4c14-9d28-5f90e48a5fbb',
                  child: Text('Max Verstappen (Lead Performance Tech)'),
                ),
                DropdownMenuItem(
                  value: '3de53358-caf4-440e-8040-2d088c08b146',
                  child: Text('Sergio Perez (Chassis & Suspension Specialist)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedLeadMechanicId = v);
              },
            ),
            const SizedBox(height: 18),

            // Operations List Preview
            Text(
              'AUTHORIZED OPERATIONS TO EXECUTE (${_operations.length})',
              style: AppTypography.labelSmall(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 8),
            ..._operations.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final op = entry.value;
              final checklists = op['checklists'] as List<String>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PitCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '0$idx. ${op['title']}',
                              style: AppTypography.labelMedium(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${op['estimated_duration_minutes']} MIN',
                            style: AppTypography.telemetrySmall(
                              color: AppColors.accentRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        op['description'] as String,
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Checklist items: ${checklists.length}',
                        style: AppTypography.telemetrySmall(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            ElevatedButton(
              key: const Key('btn_confirm_dispatch_operations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedSmall,
                ),
              ),
              onPressed: _isSubmitting ? null : _handleDispatch,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'DISPATCH OPERATIONS TO WORKSHOP FLOOR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
