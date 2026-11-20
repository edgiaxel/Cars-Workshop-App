import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/config/app_config.dart';
import 'package:pitmate/core/constants/app_constants.dart';

void main() {
  group('AppConfig Tests', () {
    test('default configuration provides valid application identity', () {
      expect(AppConfig.appName, equals('PitMate'));
      expect(AppConfig.appVersion, contains('2.0'));
      expect(AppConfig.supabaseUrl, isNotEmpty);
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
    });

    test('isSupabaseConfigured returns false for placeholder key', () {
      // By default with placeholder, returns false to prevent unconfigured crash
      expect(AppConfig.isSupabaseConfigured, isFalse);
    });
  });

  group('AppConstants Tests', () {
    test('workshop capacity is exactly 5 bays', () {
      expect(AppConstants.totalWorkshopBays, equals(5));
    });

    test('default tax rate is 11%', () {
      expect(AppConstants.defaultTaxRate, equals(11.0));
    });
  });
}
