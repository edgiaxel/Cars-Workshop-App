import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/app_config.dart';

/// Provider for the global SupabaseClient instance.
///
/// Returns null if Supabase is unconfigured or not yet initialized.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (AppConfig.isSupabaseConfigured) {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
  return null;
});
