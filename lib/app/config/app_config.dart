/// Application-wide configuration contract for PitMate v2.0.
///
/// Follows ARCHITECTURE.md and AGENTS.md: secrets and service-role keys
/// must never be stored in Flutter client source code.
/// Values are provided via `--dart-define` or fall back to local Supabase defaults.
class AppConfig {
  const AppConfig._();

  /// PitMate Application Name.
  static const String appName = 'PitMate';

  /// Application version.
  static const String appVersion = '2.0.0-dev';

  /// Supabase API URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  /// Supabase public anonymous client key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_anon_placeholder',
  );

  /// Whether Supabase credentials have been configured.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'sb_publishable_anon_placeholder';
}
