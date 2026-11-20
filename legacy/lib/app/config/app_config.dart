/// Application-wide client configuration for PitMate.
///
/// Follows ARCHITECTURE.md and AGENTS.md: secrets and service-role keys
/// must never be stored in Flutter client source code.
/// Values are provided via `--dart-define` or fall back to local Supabase defaults.
class AppConfig {
  const AppConfig._();

  /// PitMate Application Name.
  static const String appName = 'PitMate';

  /// Supabase API URL.
  /// Defaults to local Supabase development container as defined in `supabase/config.toml`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kxvoeqwelcmcvdfwxduu.supabase.co',
  );

  /// Supabase public anonymous client key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4dm9lcXdlbGNtY3ZkZnd4ZHV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5MDkxMjgsImV4cCI6MjEwNjQ4NTEyOH0.GxQTubQ0r9Wh6M8RI82--xaJgLb1qY7X-eG_hztEVrI',
  );

  /// Whether Supabase credentials have been configured with a valid key.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
