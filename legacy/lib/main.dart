import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';

/// Application entry point adhering to ARCHITECTURE.md section 4.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client if configured
  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey, // ignore: deprecated_member_use
      );
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }

  runApp(const ProviderScope(child: PitMateApp()));
}
