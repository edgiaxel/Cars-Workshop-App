/// PitMate Application Configuration.
///
/// Runtime configuration and Supabase parameters provided via environment/dart-define.
class AppConfig {
  const AppConfig._();

  static const String appName = 'PitMate';
  static const String appVersion = '2.0.0-dev';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kxvoeqwelcmcvdfwxduu.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4dm9lcXdlbGNtY3ZkZnd4ZHV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5MDkxMjgsImV4cCI6MjEwNjQ4NTEyOH0.GxQTubQ0r9Wh6M8RI82--xaJgLb1qY7X-eG_hztEVrI',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
