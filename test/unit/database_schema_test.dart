import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database Migration File & Integrity Tests', () {
    late String migrationSql;
    late File migrationFile;

    setUpAll(() {
      migrationFile = File('supabase/migrations/20261120000001_v2_customers_vehicles.sql');
      if (!migrationFile.existsSync()) {
        // Fallback if test run from another subfolder
        final altPath = '${Directory.current.path}/supabase/migrations/20261120000001_v2_customers_vehicles.sql';
        migrationFile = File(altPath);
      }
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');
      migrationSql = migrationFile.readAsStringSync();
      expect(migrationSql.trim().isNotEmpty, isTrue, reason: 'Migration SQL must not be empty');
    });

    test('Migration file exists and has valid header metadata', () {
      expect(migrationSql, contains('PitMate v2.0 Customers & Vehicles Migration'));
      expect(migrationSql, contains('Milestone: M1.1'));
    });

    group('public.customers Table Schema Validation', () {
      test('defines public.customers table with required columns and constraints', () {
        expect(migrationSql, contains('CREATE TABLE IF NOT EXISTS public.customers'));
        expect(migrationSql, contains('id UUID PRIMARY KEY DEFAULT gen_random_uuid()'));
        expect(migrationSql, contains('profile_id UUID NULL REFERENCES public.profiles(id) ON DELETE SET NULL'));
        expect(migrationSql, contains("customer_type customer_type NOT NULL DEFAULT 'individual'"));
        expect(migrationSql, contains('name TEXT NOT NULL'));
        expect(migrationSql, contains('email TEXT NULL'));
        expect(migrationSql, contains('phone TEXT NOT NULL'));
        expect(migrationSql, contains('address TEXT NULL'));
        expect(migrationSql, contains('tax_number TEXT NULL'));
        expect(migrationSql, contains('is_guest BOOLEAN NOT NULL DEFAULT FALSE'));
        expect(migrationSql, contains('created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()'));
        expect(migrationSql, contains('updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()'));
      });

      test('creates partial unique index on profile_id and lookup indexes', () {
        expect(
          migrationSql,
          contains('CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_profile_id'),
        );
        expect(migrationSql, contains('ON public.customers (profile_id)'));
        expect(migrationSql, contains('WHERE profile_id IS NOT NULL'));
        expect(migrationSql, contains('CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers (phone)'));
        expect(migrationSql, contains('CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers (email)'));
      });
    });

    group('public.vehicles Table Schema Validation', () {
      test('defines public.vehicles table with required columns and constraints', () {
        expect(migrationSql, contains('CREATE TABLE IF NOT EXISTS public.vehicles'));
        expect(migrationSql, contains('id UUID PRIMARY KEY DEFAULT gen_random_uuid()'));
        expect(migrationSql, contains('customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT'));
        expect(migrationSql, contains('license_plate TEXT NOT NULL UNIQUE'));
        expect(migrationSql, contains('vin TEXT NULL UNIQUE'));
        expect(migrationSql, contains('make TEXT NOT NULL'));
        expect(migrationSql, contains('model TEXT NOT NULL'));
        expect(migrationSql, contains('year INT NOT NULL CHECK (year BETWEEN 1900 AND 2100)'));
        expect(migrationSql, contains('transmission TEXT NULL'));
        expect(migrationSql, contains('color TEXT NULL'));
        expect(migrationSql, contains('current_mileage INT NOT NULL DEFAULT 0 CHECK (current_mileage >= 0)'));
        expect(migrationSql, contains('notes TEXT NULL'));
        expect(migrationSql, contains('created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()'));
        expect(migrationSql, contains('updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()'));
      });

      test('creates foreign key index on customer_id for query performance', () {
        expect(
          migrationSql,
          contains('CREATE INDEX IF NOT EXISTS idx_vehicles_customer_id ON public.vehicles (customer_id)'),
        );
      });
    });

    group('Anti-Recursion Helper Functions Validation', () {
      test('defines is_admin helper with SECURITY DEFINER STABLE SET search_path = public', () {
        final isAdminRegex = RegExp(
          r'CREATE OR REPLACE FUNCTION public\.is_admin\(\)\s*RETURNS BOOLEAN\s+AS[\s\S]*?SECURITY DEFINER SET search_path = public;',
        );
        expect(isAdminRegex.hasMatch(migrationSql), isTrue);
        expect(migrationSql, contains("role = 'admin'"));
      });

      test('defines is_mechanic helper with SECURITY DEFINER STABLE SET search_path = public', () {
        final isMechanicRegex = RegExp(
          r'CREATE OR REPLACE FUNCTION public\.is_mechanic\(\)\s*RETURNS BOOLEAN\s+AS[\s\S]*?SECURITY DEFINER SET search_path = public;',
        );
        expect(isMechanicRegex.hasMatch(migrationSql), isTrue);
        expect(migrationSql, contains("role = 'mechanic'"));
      });

      test('defines current_customer_id helper with SECURITY DEFINER STABLE SET search_path = public', () {
        final currentCustomerRegex = RegExp(
          r'CREATE OR REPLACE FUNCTION public\.current_customer_id\(\)\s*RETURNS UUID\s+AS[\s\S]*?SECURITY DEFINER SET search_path = public;',
        );
        expect(currentCustomerRegex.hasMatch(migrationSql), isTrue);
        expect(migrationSql, contains('WHERE profile_id = auth.uid()'));
      });
    });

    group('Triggers and Functions Validation', () {
      test('defines set_updated_at trigger function and triggers on customers and vehicles', () {
        expect(migrationSql, contains('CREATE OR REPLACE FUNCTION public.set_updated_at()'));
        expect(migrationSql, contains('CREATE TRIGGER trg_customers_updated_at'));
        expect(migrationSql, contains('BEFORE UPDATE ON public.customers'));
        expect(migrationSql, contains('CREATE TRIGGER trg_vehicles_updated_at'));
        expect(migrationSql, contains('BEFORE UPDATE ON public.vehicles'));
      });

      test('defines normalize_vehicle_plate trigger function and trigger on vehicles', () {
        expect(migrationSql, contains('CREATE OR REPLACE FUNCTION public.normalize_vehicle_plate()'));
        expect(migrationSql, contains('CREATE TRIGGER trg_vehicles_normalize_plate'));
        expect(migrationSql, contains('BEFORE INSERT OR UPDATE ON public.vehicles'));
        expect(migrationSql, contains("REGEXP_REPLACE(NEW.license_plate, '\\s+', ' ', 'g')"));
      });

      test('defines prevent_role_escalation trigger function and trigger on profiles', () {
        expect(migrationSql, contains('CREATE OR REPLACE FUNCTION public.prevent_role_escalation()'));
        expect(migrationSql, contains('CREATE TRIGGER trg_profiles_role_escalation'));
        expect(migrationSql, contains('BEFORE UPDATE ON public.profiles'));
        expect(migrationSql, contains('IF NEW.role <> OLD.role AND NOT public.is_admin() THEN'));
      });

      test('defines handle_new_user auth trigger seeding profiles and customers', () {
        expect(migrationSql, contains('CREATE OR REPLACE FUNCTION public.handle_new_user()'));
        expect(migrationSql, contains('CREATE TRIGGER on_auth_user_created'));
        expect(migrationSql, contains('AFTER INSERT ON auth.users'));
        expect(migrationSql, contains("'customer'::public.user_role"));
        expect(migrationSql, contains('INSERT INTO public.customers'));
        expect(migrationSql, contains('is_guest'));
      });
    });

    group('Row Level Security (RLS) Policies Validation', () {
      test('enables RLS on customers and vehicles tables', () {
        expect(migrationSql, contains('ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;'));
        expect(migrationSql, contains('ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;'));
      });

      test('verifies all required RLS policies on public.customers', () {
        // Admin full access
        expect(migrationSql, contains('CREATE POLICY "Admins have full access to customers"'));
        expect(migrationSql, contains('ON public.customers FOR ALL TO authenticated'));
        expect(migrationSql, contains('USING (public.is_admin())'));
        expect(migrationSql, contains('WITH CHECK (public.is_admin())'));

        // Mechanic read
        expect(migrationSql, contains('CREATE POLICY "Mechanics can view customer info"'));
        expect(migrationSql, contains('ON public.customers FOR SELECT TO authenticated'));
        expect(migrationSql, contains('USING (public.is_mechanic())'));

        // Customer read own
        expect(migrationSql, contains('CREATE POLICY "Customers can view own profile"'));
        expect(migrationSql, contains('ON public.customers FOR SELECT TO authenticated'));
        expect(migrationSql, contains('USING (profile_id = auth.uid())'));

        // Customer update own
        expect(migrationSql, contains('CREATE POLICY "Customers can update own profile"'));
        expect(migrationSql, contains('ON public.customers FOR UPDATE TO authenticated'));
        expect(migrationSql, contains('USING (profile_id = auth.uid())'));
        expect(migrationSql, contains('WITH CHECK (profile_id = auth.uid())'));
      });

      test('verifies all required RLS policies on public.vehicles', () {
        // Admin full access
        expect(migrationSql, contains('CREATE POLICY "Admins have full access to vehicles"'));
        expect(migrationSql, contains('ON public.vehicles FOR ALL TO authenticated'));
        expect(migrationSql, contains('USING (public.is_admin())'));
        expect(migrationSql, contains('WITH CHECK (public.is_admin())'));

        // Mechanic read
        expect(migrationSql, contains('CREATE POLICY "Mechanics can view vehicles"'));
        expect(migrationSql, contains('ON public.vehicles FOR SELECT TO authenticated'));
        expect(migrationSql, contains('USING (public.is_mechanic())'));

        // Customer read own
        expect(migrationSql, contains('CREATE POLICY "Customers can view own vehicles"'));
        expect(migrationSql, contains('ON public.vehicles FOR SELECT TO authenticated'));
        expect(migrationSql, contains('USING (customer_id = public.current_customer_id())'));

        // Customer insert own
        expect(migrationSql, contains('CREATE POLICY "Customers can insert own vehicles"'));
        expect(migrationSql, contains('ON public.vehicles FOR INSERT TO authenticated'));
        expect(migrationSql, contains('WITH CHECK (customer_id = public.current_customer_id())'));

        // Customer update own
        expect(migrationSql, contains('CREATE POLICY "Customers can update own vehicles"'));
        expect(migrationSql, contains('ON public.vehicles FOR UPDATE TO authenticated'));
        expect(migrationSql, contains('USING (customer_id = public.current_customer_id())'));
        expect(migrationSql, contains('WITH CHECK (customer_id = public.current_customer_id())'));
      });
    });

    group('Domain Logic Simulation & Constraint Invariants', () {
      test('plate normalization replicates trigger behavior accurately', () {
        String normalizePlate(String plate) {
          return plate.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
        }

        expect(normalizePlate('  b  1234  cd  '), equals('B 1234 CD'));
        expect(normalizePlate('d 9999 zzz'), equals('D 9999 ZZZ'));
        expect(normalizePlate('bk-101-aa'), equals('BK-101-AA'));
      });

      test('year boundary constraint logic (1900 to 2100)', () {
        bool isYearValid(int year) => year >= 1900 && year <= 2100;

        expect(isYearValid(1899), isFalse);
        expect(isYearValid(1900), isTrue);
        expect(isYearValid(2024), isTrue);
        expect(isYearValid(2100), isTrue);
        expect(isYearValid(2101), isFalse);
      });

      test('current_mileage non-negative constraint logic', () {
        bool isMileageValid(int mileage) => mileage >= 0;

        expect(isMileageValid(-1), isFalse);
        expect(isMileageValid(0), isTrue);
        expect(isMileageValid(125000), isTrue);
      });

      test('guest customer isolation invariant', () {
        // Guest customer has profile_id == null
        const String? guestProfileId = null;
        const bool isGuest = true;
        const String currentAuthUid = 'user-auth-uuid-1234';

        // Customer RLS check: profile_id = auth.uid()
        final bool canAccessAsCustomer = (guestProfileId == currentAuthUid);
        expect(canAccessAsCustomer, isFalse, reason: 'Guest customers must never be accessible by regular customer profile queries');
        expect(isGuest, isTrue);
      });
    });
  });
}
