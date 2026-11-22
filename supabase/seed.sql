-- ============================================================================
-- Seed Data: seed.sql
-- Milestone: M1 Development & Testing Data
-- Description: Seeds requested demo auth users, profiles, customers, and vehicles
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Helper function to provision auth user, identity, and profile
CREATE OR REPLACE FUNCTION public.create_seed_user(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_role public.user_role,
  p_phone TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = p_email;
  
  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    
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
      updated_at,
      confirmation_token
    ) VALUES (
      v_user_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      p_email,
      extensions.crypt(p_password, extensions.gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', p_full_name, 'phone_number', p_phone, 'role', p_role::text),
      NOW(),
      NOW(),
      ''
    );
    
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_user_id,
      jsonb_build_object('sub', v_user_id::text, 'email', p_email),
      'email',
      v_user_id::text,
      NOW(),
      NOW()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
        email_confirmed_at = NOW(),
        raw_user_meta_data = jsonb_build_object('full_name', p_full_name, 'phone_number', p_phone, 'role', p_role::text)
    WHERE id = v_user_id;
  END IF;

  INSERT INTO public.profiles (id, full_name, phone_number, role)
  VALUES (v_user_id, p_full_name, p_phone, p_role)
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone_number = EXCLUDED.phone_number,
    role = EXCLUDED.role;

  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
DECLARE
  v_admin_id UUID;
  v_verstappen_id UUID;
  v_perez_id UUID;
  v_axel_id UUID;
  v_aston_id UUID;
  v_bmw_id UUID;

  v_axel_cust_id UUID;
  v_aston_cust_id UUID;
  v_bmw_cust_id UUID;
  v_guest1_id UUID;
  v_guest2_id UUID;
BEGIN
  v_admin_id := public.create_seed_user('admin@pitmate.co', '000000', 'Toto Wolf', 'admin', '+628110000001');
  v_verstappen_id := public.create_seed_user('verstappen@pitmate.co', '000000', 'Max Verstappen', 'mechanic', '+628110000002');
  v_perez_id := public.create_seed_user('perez@pitmate.co', '000000', 'Sergio Perez', 'mechanic', '+628110000003');
  v_axel_id := public.create_seed_user('lexazeed@gmail.com', '000000', 'Axel Zeed', 'customer', '+6281234567890');
  v_aston_id := public.create_seed_user('motorsport@astonmartin.com', '000000', 'Aston Martin', 'customer', '+442079460001');
  v_bmw_id := public.create_seed_user('motorsport@bmw-m.com', '000000', 'BMW', 'customer', '+498938200000');

  INSERT INTO public.customers (profile_id, full_name, phone_number, email, customer_type, is_guest)
  VALUES (v_axel_id, 'Axel Zeed', '+6281234567890', 'lexazeed@gmail.com', 'individual', FALSE)
  ON CONFLICT (phone_number) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    customer_type = EXCLUDED.customer_type,
    is_guest = FALSE
  RETURNING id INTO v_axel_cust_id;

  INSERT INTO public.customers (profile_id, full_name, phone_number, email, customer_type, company_name, is_guest)
  VALUES (v_aston_id, 'Aston Martin', '+442079460001', 'motorsport@astonmartin.com', 'company', 'Aston Martin F1 Team', FALSE)
  ON CONFLICT (phone_number) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    customer_type = EXCLUDED.customer_type,
    company_name = EXCLUDED.company_name,
    is_guest = FALSE
  RETURNING id INTO v_aston_cust_id;

  INSERT INTO public.customers (profile_id, full_name, phone_number, email, customer_type, company_name, is_guest)
  VALUES (v_bmw_id, 'BMW', '+498938200000', 'motorsport@bmw-m.com', 'company', 'BMW M Motorsport', FALSE)
  ON CONFLICT (phone_number) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    customer_type = EXCLUDED.customer_type,
    company_name = EXCLUDED.company_name,
    is_guest = FALSE
  RETURNING id INTO v_bmw_cust_id;

  INSERT INTO public.customers (full_name, phone_number, email, customer_type, is_guest)
  VALUES ('Joko Susilo (Walk-in)', '+6281399887766', NULL, 'individual', TRUE)
  ON CONFLICT (phone_number) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    is_guest = TRUE
  RETURNING id INTO v_guest1_id;

  INSERT INTO public.customers (full_name, phone_number, email, customer_type, is_guest)
  VALUES ('Bambang Soediro (Walk-in)', '+6281288004321', NULL, 'individual', TRUE)
  ON CONFLICT (phone_number) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    is_guest = TRUE
  RETURNING id INTO v_guest2_id;

  INSERT INTO public.vehicles (customer_id, license_plate, make, model, year, engine_type, transmission, mileage, color, notes)
  VALUES
    (v_axel_cust_id, 'B 1234 TOY', 'Toyota', 'GR Yaris', 2023, '1.6L G16E-GTS Turbo', 'Manual 6-Speed', 12450, 'Precious White', 'Stage 1 Tune, Gazoo Racing suspension'),
    (v_axel_cust_id, 'B 5678 CIV', 'Honda', 'Civic Type R FL5', 2024, '2.0L K20C1 Turbo', 'Manual 6-Speed', 8200, 'Championship White', 'Track spec brake fluid, Brembo package')
  ON CONFLICT (license_plate) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    make = EXCLUDED.make,
    model = EXCLUDED.model,
    year = EXCLUDED.year,
    mileage = EXCLUDED.mileage,
    color = EXCLUDED.color,
    notes = EXCLUDED.notes;

  INSERT INTO public.vehicles (customer_id, license_plate, make, model, year, engine_type, transmission, mileage, color, notes)
  VALUES
    (v_aston_cust_id, 'B 0007 AM', 'Aston Martin', 'Vantage AMR GT4', 2023, '4.0L Twin-Turbo V8', 'Sequential 6-Speed', 5300, 'Racing Green', 'Corporate fleet GT4 #01'),
    (v_aston_cust_id, 'B 0008 AM', 'Aston Martin', 'DBX707', 2024, '4.0L Twin-Turbo V8', 'Automatic 9-Speed', 15400, 'Apex Grey', 'Executive support vehicle')
  ON CONFLICT (license_plate) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    make = EXCLUDED.make,
    model = EXCLUDED.model,
    year = EXCLUDED.year,
    mileage = EXCLUDED.mileage,
    color = EXCLUDED.color,
    notes = EXCLUDED.notes;

  INSERT INTO public.vehicles (customer_id, license_plate, make, model, year, engine_type, transmission, mileage, color, notes)
  VALUES
    (v_bmw_cust_id, 'B 0004 M', 'BMW', 'M4 GT3', 2023, '3.0L P58 TwinPower Turbo', 'Sequential 6-Speed', 4100, 'Frozen Deep Grey', 'M Motorsport customer racing fleet'),
    (v_bmw_cust_id, 'B 0005 M', 'BMW', 'M3 Touring G81', 2024, '3.0L S58 TwinPower Turbo', 'M Steptronic 8-Speed', 14200, 'Isle of Man Green', 'Daily fleet transport')
  ON CONFLICT (license_plate) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    make = EXCLUDED.make,
    model = EXCLUDED.model,
    year = EXCLUDED.year,
    mileage = EXCLUDED.mileage,
    color = EXCLUDED.color,
    notes = EXCLUDED.notes;

  INSERT INTO public.vehicles (customer_id, license_plate, make, model, year, engine_type, transmission, mileage, color, notes)
  VALUES
    (v_guest1_id, 'B 3021 RFS', 'Toyota', 'Innova Reborn 2.4 V', 2021, '2.4L 2GD-FTV Diesel', 'Automatic', 45200, 'Super White', 'AC not cooling properly'),
    (v_guest2_id, 'D 1808 AC', 'Mitsubishi', 'Pajero Sport Dakar', 2022, '2.4L MIVEC Turbo Diesel', 'Automatic 8-Speed', 38900, 'Jet Black', 'Brake pad replacement check')
  ON CONFLICT (license_plate) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    make = EXCLUDED.make,
    model = EXCLUDED.model,
    year = EXCLUDED.year,
    mileage = EXCLUDED.mileage,
    color = EXCLUDED.color,
    notes = EXCLUDED.notes;

END $$;

DROP FUNCTION IF EXISTS public.create_seed_user;
