import 'package:pitmate/features/mechanic/data/models/mechanic_compensation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for Mechanic Compensation, Incentives, and Payroll Adjustments.
class MechanicCompensationRepository {
  final SupabaseClient? _client;

  MechanicCompensationRepository([SupabaseClient? client]) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Fetches all mechanic compensation profiles with joined profile metadata.
  Future<List<MechanicCompensationProfile>> fetchProfiles() async {
    final response = await _supabase
        .from('mechanic_compensation_profiles')
        .select('*, profiles(full_name, email)')
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => MechanicCompensationProfile.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Updates a mechanic's salary and incentive settings.
  Future<void> updateProfile({
    required String mechanicId,
    required int baseSalaryCents,
    required double incentivePercentage,
    required double defaultLeadSharePercentage,
  }) async {
    await _supabase.from('mechanic_compensation_profiles').upsert({
      'mechanic_id': mechanicId,
      'base_salary_cents': baseSalaryCents,
      'incentive_percentage': incentivePercentage,
      'default_lead_share_percentage': defaultLeadSharePercentage,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetches earned incentive allocations for a specific mechanic.
  Future<List<MechanicEarningAllocation>> fetchAllocationsForMechanic(String mechanicId) async {
    final response = await _supabase
        .from('mechanic_earning_allocations')
        .select('*, mechanic_earnings(task_id, service_order_id, service_orders(order_number), service_order_tasks(title))')
        .eq('mechanic_id', mechanicId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => MechanicEarningAllocation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all payroll adjustments (optionally filtered by mechanic).
  Future<List<MechanicPayrollAdjustment>> fetchAdjustments([String? mechanicId]) async {
    var query = _supabase
        .from('mechanic_payroll_adjustments')
        .select('*, profiles!mechanic_id(full_name)');

    if (mechanicId != null && mechanicId.isNotEmpty) {
      query = query.eq('mechanic_id', mechanicId);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((row) => MechanicPayrollAdjustment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Records an auditable payroll adjustment (bonus, deduction, adjustment).
  Future<MechanicPayrollAdjustment> adjustCompensation({
    required String mechanicId,
    required int amountCents,
    required String type,
    required String reason,
  }) async {
    final response = await _supabase.rpc(
      'adjust_mechanic_compensation',
      params: {
        'p_mechanic_id': mechanicId,
        'p_amount_cents': amountCents,
        'p_type': type,
        'p_reason': reason,
      },
    );

    return MechanicPayrollAdjustment.fromJson(response as Map<String, dynamic>);
  }

  /// Calculates and records incentive pool allocations for a completed task.
  Future<Map<String, dynamic>> generateTaskIncentives({
    required String taskId,
    required String serviceOrderId,
    required String leadMechanicId,
    List<String> helperMechanicIds = const [],
    required int incentiveAmountCents,
    double leadPercentage = 70.0,
  }) async {
    final response = await _supabase.rpc(
      'generate_task_mechanic_incentives',
      params: {
        'p_task_id': taskId,
        'p_service_order_id': serviceOrderId,
        'p_lead_mechanic_id': leadMechanicId,
        'p_helper_mechanic_ids': helperMechanicIds,
        'p_incentive_amount_cents': incentiveAmountCents,
        'p_lead_percentage': leadPercentage,
      },
    );

    return (response as Map<String, dynamic>?) ?? {};
  }
}
