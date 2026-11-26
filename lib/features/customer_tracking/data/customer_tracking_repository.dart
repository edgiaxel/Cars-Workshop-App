import 'package:pitmate/features/customer_tracking/models/customer_tracking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for customer vehicle live progress tracking.
class CustomerTrackingRepository {
  CustomerTrackingRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  /// Fetch customer profile ID for current auth session.
  Future<String?> getCurrentCustomerId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final res = await _supabase
          .from('customers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      return res?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Call RPC get_customer_service_tracking to fetch sanitized telemetry and timeline.
  Future<CustomerTrackingSummary> fetchTrackingSummary({
    required String customerId,
    String? orderId,
  }) async {
    final params = <String, dynamic>{
      'p_customer_id': customerId,
    };
    if (orderId != null) {
      params['p_order_id'] = orderId;
    }

    final res = await _supabase.rpc(
      'get_customer_service_tracking',
      params: params,
    );

    if (res is Map<String, dynamic>) {
      return CustomerTrackingSummary.fromJson(res);
    }
    return const CustomerTrackingSummary(hasActiveOrder: false);
  }
}
