-- ============================================================================
-- Seed Data: seed.sql
-- Milestone: M1 Development & Testing Data
-- Description: Seeds demo auth users, profiles, customers, and mock vehicle data
-- ============================================================================

-- 1. Insert demo users into auth.users (local Supabase dev environment)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'auth' AND tablename = 'users') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES
    (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'admin@pitmate.com',
      crypt('PitMate2026!', gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Workshop Admin","phone_number":"+628110000001"}',
      NOW(),
      NOW()
    ),
    (
      '00000000-0000-0000-0000-000000000002',
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'mechanic@pitmate.com',
      crypt('PitMate2026!', gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Budi Santoso (Lead Mechanic)","phone_number":"+628110000002"}',
      NOW(),
      NOW()
    ),
    (
      '00000000-0000-0000-0000-000000000003',
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'customer@pitmate.com',
      crypt('PitMate2026!', gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Ahmad Fauzi","phone_number":"+628120000003"}',
      NOW(),
      NOW()
    ),
    (
      '00000000-0000-0000-0000-000000000004',
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'sarah.tan@example.com',
      crypt('PitMate2026!', gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Sarah Tan","phone_number":"+628120000004"}',
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

-- 2. Seed / Update Profiles with designated roles
INSERT INTO public.profiles (id, full_name, phone_number, role, avatar_url)
VALUES
  (
    '00000000-0000-0000-0000-000000000001',
    'Workshop Admin',
    '+628110000001',
    'admin',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80'
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'Budi Santoso (Lead Mechanic)',
    '+628110000002',
    'mechanic',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80'
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'Ahmad Fauzi',
    '+628120000003',
    'customer',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=256&q=80'
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    'Sarah Tan',
    '+628120000004',
    'customer',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=256&q=80'
  )
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name,
  phone_number = EXCLUDED.phone_number,
  avatar_url = EXCLUDED.avatar_url;

-- 3. Seed Customers
INSERT INTO public.customers (
  id,
  profile_id,
  full_name,
  phone_number,
  email,
  customer_type,
  company_name,
  is_guest
) VALUES
  (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000003',
    'Ahmad Fauzi',
    '+628120000003',
    'customer@pitmate.com',
    'individual',
    NULL,
    FALSE
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000004',
    'Sarah Tan',
    '+628120000004',
    'sarah.tan@example.com',
    'individual',
    NULL,
    FALSE
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    NULL,
    'PT Logistik Nusantara Prima',
    '+62215550199',
    'fleet@logistiknusantara.co.id',
    'company',
    'PT Logistik Nusantara Prima',
    FALSE
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    NULL,
    'Joko Walk-in Guest',
    '+6281399887766',
    NULL,
    'individual',
    NULL,
    TRUE
  )
ON CONFLICT (id) DO UPDATE SET
  profile_id = EXCLUDED.profile_id,
  full_name = EXCLUDED.full_name,
  phone_number = EXCLUDED.phone_number,
  email = EXCLUDED.email,
  customer_type = EXCLUDED.customer_type,
  company_name = EXCLUDED.company_name,
  is_guest = EXCLUDED.is_guest;

-- 4. Seed Vehicles
INSERT INTO public.vehicles (
  id,
  customer_id,
  license_plate,
  make,
  model,
  year,
  vin,
  engine_type,
  transmission,
  mileage,
  color,
  notes
) VALUES
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'B 1234 ABC',
    'Toyota',
    'Innova Reborn 2.4 V',
    2021,
    'MHF11AG40M0012345',
    '2.4L Diesel 2GD-FTV',
    'Automatic',
    45200,
    'Super White',
    'Regular customer, synthetic 5W-30 oil used'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'B 5678 DEF',
    'Honda',
    'HR-V 1.5 SE',
    2023,
    'MHRRU1850NJ005678',
    '1.5L i-VTEC DOHC',
    'CVT',
    18400,
    'Meteoroid Gray Metallic',
    'First 20,000 km major service pending'
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    'B 9999 XYZ',
    'Mitsubishi',
    'Pajero Sport Dakar 4x2',
    2022,
    'MK2KR450WNW009999',
    '2.4L MIVEC Turbo Diesel',
    'Automatic 8-Speed',
    38900,
    'Jet Black Mica',
    'Brake pad inspection requested'
  ),
  (
    '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000003',
    'B 8080 FLE',
    'Isuzu',
    'Elf NMR 71 HD 5.8',
    2020,
    'MHYNMR71LKK008080',
    '4.5L 4HG1-T Diesel',
    'Manual 6-Speed',
    112000,
    'White',
    'Fleet commercial vehicle #04'
  ),
  (
    '20000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000004',
    'B 4321 GUE',
    'Suzuki',
    'Ertiga GX',
    2019,
    'MHEZE81S0K0043210',
    '1.5L K15B',
    'Manual',
    67000,
    'Silky Silver Metallic',
    'Walk-in emergency AC inspection'
  )
ON CONFLICT (id) DO UPDATE SET
  customer_id = EXCLUDED.customer_id,
  license_plate = EXCLUDED.license_plate,
  make = EXCLUDED.make,
  model = EXCLUDED.model,
  year = EXCLUDED.year,
  vin = EXCLUDED.vin,
  engine_type = EXCLUDED.engine_type,
  transmission = EXCLUDED.transmission,
  mileage = EXCLUDED.mileage,
  color = EXCLUDED.color,
  notes = EXCLUDED.notes;
