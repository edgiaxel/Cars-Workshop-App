-- ============================================================
-- PitMate Development Seed
-- ============================================================

-- ============================================================
-- PROFILES
-- ============================================================

insert into public.profiles (
  id,
  role,
  full_name,
  phone
)
select
  id,
  'admin',
  'Christian Horner',
  '+62 811 1000 0001'
from auth.users
where email = 'admin@pitmate.co'
on conflict (id) do update
set
  role = excluded.role,
  full_name = excluded.full_name,
  phone = excluded.phone;

insert into public.profiles (
  id,
  role,
  full_name,
  phone
)
select
  id,
  'mechanic',
  'Max Verstappen',
  '+62 811 1000 0002'
from auth.users
where email = 'verstappen@pitmate.co'
on conflict (id) do update
set
  role = excluded.role,
  full_name = excluded.full_name,
  phone = excluded.phone;

insert into public.profiles (
  id,
  role,
  full_name,
  phone
)
select
  id,
  'mechanic',
  'Sergio Perez',
  '+62 811 1000 0003'
from auth.users
where email = 'perez@pitmate.co'
on conflict (id) do update
set
  role = excluded.role,
  full_name = excluded.full_name,
  phone = excluded.phone;

insert into public.profiles (
  id,
  role,
  full_name,
  phone
)
select
  id,
  'customer',
  'BMW M Motorsport',
  '+49 89 382 0'
from auth.users
where email = 'motorsport@bmw-m.com'
on conflict (id) do update
set
  role = excluded.role,
  full_name = excluded.full_name,
  phone = excluded.phone;

insert into public.profiles (
  id,
  role,
  full_name,
  phone
)
select
  id,
  'customer',
  'Aston Martin',
  '+44 1926 644 644'
from auth.users
where email = 'motorsport@astonmartin.com'
on conflict (id) do update
set
  role = excluded.role,
  full_name = excluded.full_name,
  phone = excluded.phone;

insert into public.profiles (
  id,
  role,
  full_name,
  phone
)
select
  id,
  'customer',
  'Axel Zeed',
  '+62 812 0000 0000'
from auth.users
where email = 'lexazeed@gmail.com'
on conflict (id) do update
set
  role = excluded.role,
  full_name = excluded.full_name,
  phone = excluded.phone;

-- ============================================================
-- CUSTOMERS
-- ============================================================

insert into public.customers (
  profile_id,
  customer_type,
  company_name,
  address,
  notes
)
select
  p.id,
  'company',
  'BMW M Motorsport',
  'Munich, Germany',
  'Development and customer racing operations.'
from public.profiles p
where p.full_name = 'BMW M Motorsport'
on conflict (profile_id) do update
set
  customer_type = excluded.customer_type,
  company_name = excluded.company_name,
  address = excluded.address,
  notes = excluded.notes;

insert into public.customers (
  profile_id,
  customer_type,
  company_name,
  address,
  notes
)
select
  p.id,
  'company',
  'Aston Martin',
  'Gaydon, Warwickshire, United Kingdom',
  'Performance and motorsport vehicle operations.'
from public.profiles p
where p.full_name = 'Aston Martin'
on conflict (profile_id) do update
set
  customer_type = excluded.customer_type,
  company_name = excluded.company_name,
  address = excluded.address,
  notes = excluded.notes;

insert into public.customers (
  profile_id,
  customer_type,
  company_name,
  address,
  notes
)
select
  p.id,
  'individual',
  null,
  'Bandung, Indonesia',
  'Development/test customer account.'
from public.profiles p
where p.full_name = 'Axel Zeed'
on conflict (profile_id) do update
set
  customer_type = excluded.customer_type,
  company_name = excluded.company_name,
  address = excluded.address,
  notes = excluded.notes;

-- ============================================================
-- MECHANICS
-- ============================================================

insert into public.mechanics (
  profile_id,
  employee_code,
  specialization,
  hourly_rate,
  compensation_percentage,
  hire_date
)
select
  p.id,
  'MEC-001',
  'Performance Powertrain & Diagnostics',
  350000,
  30,
  '2025-01-15'
from public.profiles p
where p.full_name = 'Max Verstappen'
on conflict (profile_id) do update
set
  employee_code = excluded.employee_code,
  specialization = excluded.specialization,
  hourly_rate = excluded.hourly_rate,
  compensation_percentage = excluded.compensation_percentage;

insert into public.mechanics (
  profile_id,
  employee_code,
  specialization,
  hourly_rate,
  compensation_percentage,
  hire_date
)
select
  p.id,
  'MEC-002',
  'Chassis, Suspension & Vehicle Dynamics',
  325000,
  28,
  '2025-03-01'
from public.profiles p
where p.full_name = 'Sergio Perez'
on conflict (profile_id) do update
set
  employee_code = excluded.employee_code,
  specialization = excluded.specialization,
  hourly_rate = excluded.hourly_rate,
  compensation_percentage = excluded.compensation_percentage;

-- ============================================================
-- VEHICLES
-- ============================================================

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'BMW',
  'M Hybrid V8',
  'LMDh',
  2026,
  '#15',
  18420,
  'BMW Motorsport White',
  'WEC endurance prototype. Competition service profile.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'BMW M Motorsport'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'M Hybrid V8'
    and v.vehicle_number = '#15'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'BMW',
  'M Hybrid V8',
  'LMDh',
  2026,
  '#20',
  16780,
  'BMW Motorsport White',
  'WEC endurance prototype. Competition service profile.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'BMW M Motorsport'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'M Hybrid V8'
    and v.vehicle_number = '#20'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'BMW',
  'M4 GT3',
  'Evo',
  2026,
  '#32',
  12340,
  'BMW M Motorsport Livery',
  'GT3 competition vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'BMW M Motorsport'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'M4 GT3'
    and v.vehicle_number = '#32'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'BMW',
  'M4 GT3',
  'Evo',
  2026,
  '#46',
  10980,
  'BMW M Motorsport Livery',
  'GT3 competition vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'BMW M Motorsport'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'M4 GT3'
    and v.vehicle_number = '#46'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'Aston Martin',
  'Valkyrie',
  'AMR Pro',
  2025,
  '#007',
  4820,
  'Aston Martin Racing Green',
  'High-performance track vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'Aston Martin'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'Valkyrie'
    and v.vehicle_number = '#007'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'Aston Martin',
  'Valkyrie',
  'AMR Pro',
  2025,
  '#009',
  3910,
  'Aston Martin Racing Green',
  'High-performance track vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'Aston Martin'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'Valkyrie'
    and v.vehicle_number = '#009'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  license_plate,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'BMW',
  'M3 Touring',
  'Competition G81',
  2024,
  'D 1999 AZ',
  'G81-01',
  28650,
  'Black Sapphire',
  'Personal vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'M3 Touring'
    and v.variant = 'Competition G81'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  license_plate,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'Toyota',
  'Innova Zenix',
  'Hybrid',
  2024,
  'D 1234 ZEN',
  'ZEN-01',
  17420,
  'Platinum White Pearl',
  'Family vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'Innova Zenix'
);

insert into public.vehicles (
  customer_id,
  make,
  model,
  variant,
  model_year,
  license_plate,
  vehicle_number,
  mileage_km,
  color,
  notes
)
select
  c.id,
  'Ford',
  'Raptor',
  'F-150',
  2023,
  'D 9999 RAP',
  'F150-01',
  42100,
  'Oxford White',
  'Utility and weekend vehicle.'
from public.customers c
join public.profiles p on p.id = c.profile_id
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.vehicles v
  where v.customer_id = c.id
    and v.model = 'Raptor'
);

-- ============================================================
-- TASK TEMPLATES
-- ============================================================

insert into public.task_templates
(name, description, category, estimated_minutes)
values
('Engine Diagnostic Inspection',
 'Run diagnostic scan, inspect fault codes and verify engine operating parameters.',
 'Diagnostics',
 60),
('Brake System Inspection',
 'Inspect brake discs, pads, calipers, lines and fluid condition.',
 'Brakes',
 45),
('Brake Pad Replacement',
 'Remove worn pads, inspect hardware and install replacement pads.',
 'Brakes',
 75),
('Engine Oil & Filter Service',
 'Drain engine oil, replace filter and refill to specified capacity.',
 'Engine',
 45),
('Cooling System Inspection',
 'Inspect coolant level, hoses, radiator, expansion tank and leaks.',
 'Cooling',
 40),
('Suspension Inspection',
 'Inspect dampers, springs, control arms, bushings and mounting points.',
 'Chassis',
 60),
('Wheel Alignment Check',
 'Measure alignment geometry and adjust within vehicle specification.',
 'Chassis',
 90),
('Tire Condition Inspection',
 'Inspect tread depth, wear pattern, pressure and visible damage.',
 'Tires',
 30),
('High Voltage System Inspection',
 'Inspect hybrid high-voltage system status and associated diagnostic data.',
 'Hybrid',
 90),
('Pre-Race Inspection',
 'Perform competition vehicle inspection before track or endurance operation.',
 'Motorsport',
 120)
on conflict do nothing;

-- ============================================================
-- SPARE PARTS
-- ============================================================

insert into public.spare_parts
(sku, name, category, brand, description, unit, unit_cost, selling_price, minimum_stock)
values
('OIL-5W40-001', '5W-40 Full Synthetic Engine Oil', 'Fluids', 'Castrol', 'Full synthetic high-performance engine oil.', 'liter', 145000, 185000, 12),
('OIL-FLTR-001', 'Performance Oil Filter', 'Filters', 'MANN-FILTER', 'High-flow engine oil filter.', 'pcs', 95000, 135000, 8),
('AIR-FLTR-001', 'High-Flow Air Filter', 'Filters', 'MANN-FILTER', 'Engine air filter element.', 'pcs', 280000, 395000, 4),
('BRK-PAD-F-001', 'Front Performance Brake Pad Set', 'Brakes', 'Brembo', 'High-temperature performance front brake pad set.', 'set', 1650000, 2200000, 4),
('BRK-DISC-F-001', 'Front Performance Brake Disc', 'Brakes', 'Brembo', 'High-performance ventilated brake disc.', 'pcs', 3200000, 4200000, 4),
('BRK-FLD-001', 'High Temperature Brake Fluid', 'Fluids', 'Motul', 'DOT 4 racing brake fluid.', 'liter', 350000, 475000, 6),
('COOL-001', 'High Performance Coolant', 'Fluids', 'Motul', 'High-temperature engine coolant.', 'liter', 120000, 165000, 10),
('SPK-PLG-001', 'Iridium Spark Plug', 'Ignition', 'NGK', 'Iridium performance spark plug.', 'pcs', 240000, 325000, 12),
('CAB-FLTR-001', 'Cabin Air Filter', 'Filters', 'Bosch', 'Activated carbon cabin filter.', 'pcs', 180000, 260000, 6),
('WIPER-001', 'Performance Wiper Blade', 'Exterior', 'Bosch', 'Premium aerodynamic wiper blade.', 'pcs', 165000, 235000, 8),
('TYR-245-001', '245/40 R19 Performance Tire', 'Tires', 'Michelin', 'High-performance road tire.', 'pcs', 4800000, 5600000, 8),
('TYR-305-001', '305/30 R20 Track Tire', 'Tires', 'Michelin', 'Track-focused performance tire.', 'pcs', 9200000, 10500000, 8)
on conflict (sku) do update
set
  name = excluded.name,
  category = excluded.category,
  brand = excluded.brand,
  description = excluded.description,
  unit = excluded.unit,
  unit_cost = excluded.unit_cost,
  selling_price = excluded.selling_price,
  minimum_stock = excluded.minimum_stock;

-- ============================================================
-- INITIAL INVENTORY
-- ============================================================

insert into public.inventory_transactions
(spare_part_id, transaction_type, quantity, unit_cost, notes)
select
  id,
  'initial_stock',
  case sku
    when 'OIL-5W40-001' then 60
    when 'OIL-FLTR-001' then 30
    when 'AIR-FLTR-001' then 12
    when 'BRK-PAD-F-001' then 10
    when 'BRK-DISC-F-001' then 8
    when 'BRK-FLD-001' then 24
    when 'COOL-001' then 40
    when 'SPK-PLG-001' then 48
    when 'CAB-FLTR-001' then 18
    when 'WIPER-001' then 20
    when 'TYR-245-001' then 16
    when 'TYR-305-001' then 12
  end,
  unit_cost,
  'Initial PitMate workshop inventory'
from public.spare_parts
where sku in (
  'OIL-5W40-001',
  'OIL-FLTR-001',
  'AIR-FLTR-001',
  'BRK-PAD-F-001',
  'BRK-DISC-F-001',
  'BRK-FLD-001',
  'COOL-001',
  'SPK-PLG-001',
  'CAB-FLTR-001',
  'WIPER-001',
  'TYR-245-001',
  'TYR-305-001'
)
and not exists (
  select 1
  from public.inventory_transactions it
  where it.spare_part_id = spare_parts.id
    and it.transaction_type = 'initial_stock'
);

-- ============================================================
-- REMINDERS
-- ============================================================

insert into public.service_reminders (
  customer_id,
  vehicle_id,
  reminder_type,
  title,
  description,
  due_date,
  due_mileage_km,
  status
)
select
  c.id,
  v.id,
  'maintenance',
  'BMW M3 Touring scheduled maintenance',
  'Review engine oil, brake system, tires and vehicle inspection items.',
  current_date + interval '30 days',
  30000,
  'pending'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'M3 Touring'
  and not exists (
    select 1
    from public.service_reminders r
    where r.vehicle_id = v.id
      and r.title = 'BMW M3 Touring scheduled maintenance'
  );

insert into public.service_reminders (
  customer_id,
  vehicle_id,
  reminder_type,
  title,
  description,
  due_date,
  due_mileage_km,
  status
)
select
  c.id,
  v.id,
  'inspection',
  'Valkyrie track inspection',
  'Pre-track inspection recommended before next high-performance session.',
  current_date + interval '14 days',
  v.mileage_km + 500,
  'pending'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Aston Martin'
  and v.vehicle_number = '#007'
  and not exists (
    select 1
    from public.service_reminders r
    where r.vehicle_id = v.id
      and r.title = 'Valkyrie track inspection'
  );

insert into public.service_reminders (
  customer_id,
  vehicle_id,
  reminder_type,
  title,
  description,
  due_date,
  due_mileage_km,
  status
)
select
  c.id,
  v.id,
  'inspection',
  'Toyota Innova Zenix Hybrid Check',
  'Routine 20,000 KM hybrid drive battery cooling duct inspection and tire rotation.',
  current_date + interval '60 days',
  20000,
  'pending'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'Innova Zenix'
  and not exists (
    select 1
    from public.service_reminders r
    where r.vehicle_id = v.id
      and r.title = 'Toyota Innova Zenix Hybrid Check'
  );

-- ============================================================
-- BOOKINGS
-- ============================================================

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  '30,000 KM Annual Maintenance: Castrol 5W-40 & Filters',
  'Routine 30k maintenance, oil change, brake check, and overall inspection.',
  current_date - interval '2 days',
  '13:00',
  'checked_in',
  'Technician Max Verstappen allocated. Checked in and completed under SO-2026-003.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'M3 Touring'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%30,000 KM Annual Maintenance%'
  );

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  'Hybrid Drive Battery Cooling Duct Inspection',
  'Routine 20,000 KM hybrid drive battery cooling duct inspection and tire rotation.',
  current_date + interval '11 days',
  '10:00',
  'scheduled',
  'Awaiting customer drop-off confirmation.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'Innova Zenix'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%Hybrid Drive Battery%'
  );

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  'Powertrain Diagnostics & Hybrid Battery Inspection',
  'Full system diagnostic scan, error code clearance, and high voltage cell balancing.',
  current_date,
  '08:30',
  'checked_in',
  'Checked in and transitioned to active hoist service SO-2026-001.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport'
  and v.vehicle_number = '#15'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%Powertrain Diagnostics%'
  );

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  'Pre-Race Inspection & High-Voltage Systems Verification',
  'Perform competition vehicle inspection before track or endurance testing.',
  current_date + interval '3 days',
  '09:00',
  'approved',
  'Upcoming appointment; customer confirmed arrival date.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport'
  and v.vehicle_number = '#20'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%Pre-Race Inspection%'
  );

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  'Heavy Duty Suspension & 4x4 Driveline Inspection',
  'Comprehensive off-road damper and chassis inspection.',
  current_date + interval '5 days',
  '14:00',
  'requested',
  'Pending workshop schedule confirmation.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'Raptor'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%Heavy Duty Suspension%'
  );

-- ============================================================
-- SERVICE ORDERS
-- ============================================================

-- SO-2026-001: In Service (In Progress) - Pre-booked, Hoist Bay 1
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  booking_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  scheduled_end,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-001',
  c.id,
  v.id,
  b.id,
  'Powertrain Diagnostics & Hybrid Battery Inspection',
  'Full system diagnostic scan, error code clearance, and high voltage cell balancing.',
  'in_progress',
  'booking',
  now() - interval '3 hours',
  current_date + interval '8 hours 30 minutes',
  current_date + interval '16 hours 30 minutes',
  18420,
  12500000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
left join public.bookings b on b.vehicle_id = v.id and b.requested_service like '%Powertrain Diagnostics%'
where p.full_name = 'BMW M Motorsport' and v.vehicle_number = '#15'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-001'
);

-- SO-2026-002: In Service (Diagnosis) - Walk-in Admission
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-002',
  c.id,
  v.id,
  'Track Dynamic Calibration & Suspension Diagnostics',
  'Walk-in vehicle intake: damper telemetry analysis and corner balancing adjustment.',
  'diagnosis',
  'walk_in',
  now() - interval '90 minutes',
  now() - interval '60 minutes',
  4820,
  9500000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Aston Martin' and v.vehicle_number = '#007'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-002'
);

-- SO-2026-003: Completed & Closed - Pre-booked
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  booking_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  scheduled_end,
  odometer_km,
  estimated_total,
  final_total,
  customer_approved,
  completed_at,
  closed_at
)
select
  'SO-2026-003',
  c.id,
  v.id,
  b.id,
  '30,000 KM Annual Maintenance: Castrol 5W-40 & Filters',
  '30,000 KM Annual Maintenance: Castrol 5W-40 full synthetic oil service, oil filter replacement, air filter change, and full brake system inspection.',
  'completed',
  'booking',
  now() - interval '2 days 4 hours',
  current_date - interval '2 days',
  current_date - interval '2 days' + interval '3 hours',
  28650,
  3850000.00,
  3850000.00,
  true,
  now() - interval '2 days',
  now() - interval '2 days'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
left join public.bookings b on b.vehicle_id = v.id and b.requested_service like '%30,000 KM Annual Maintenance%'
where p.full_name = 'Axel Zeed' and v.model = 'M3 Touring'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-003'
);

-- SO-2026-004: Waiting Queue - Walk-in Admission (Arrived, waiting for bay allocation)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-004',
  c.id,
  v.id,
  'Heavy Duty Suspension & Alignment Check',
  'Walk-in vehicle check-in: suspension inspection and multi-point alignment check.',
  'scheduled',
  'walk_in',
  now() - interval '45 minutes',
  now() + interval '30 minutes',
  42100,
  4200000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed' and v.model = 'Raptor'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-004'
);

-- SO-2026-005: Upcoming Queue - Pre-booked (Future scheduled start, vehicle not arrived yet)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  booking_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-005',
  c.id,
  v.id,
  b.id,
  'Pre-Race Inspection & High-Voltage Systems Verification',
  'Perform competition vehicle inspection before track or endurance testing.',
  'scheduled',
  'booking',
  null,
  current_date + interval '3 days 9 hours',
  16780,
  8500000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
left join public.bookings b on b.vehicle_id = v.id and b.requested_service like '%Pre-Race Inspection%'
where p.full_name = 'BMW M Motorsport' and v.vehicle_number = '#20'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-005'
);

-- SO-2026-006: Blocked Queue - Walk-in Admission (Awaiting parts delivery)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-006',
  c.id,
  v.id,
  'Brembo Racing Brake Pad & Disc Replacement',
  'Brembo racing hardware replacement. On hold awaiting shipment of Brembo brake disc set.',
  'waiting_for_parts',
  'walk_in',
  now() - interval '5 hours',
  now() - interval '4 hours',
  12340,
  7400000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport' and v.vehicle_number = '#32'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-006'
);

-- SO-2026-007: Recently Completed / Settlement (Payment pending)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  intake_origin,
  arrived_at,
  scheduled_start,
  scheduled_end,
  odometer_km,
  estimated_total,
  final_total,
  customer_approved,
  completed_at
)
select
  'SO-2026-007',
  c.id,
  v.id,
  'Performance Brake Fluid Flush & High Temperature Inspection',
  'Track preparation complete; final inspection passed. Ready for payment settlement.',
  'payment',
  'booking',
  now() - interval '1 day',
  now() - interval '1 day',
  now() - interval '1 day' + interval '2 hours',
  3910,
  5200000.00,
  5200000.00,
  true,
  now() - interval '3 hours'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Aston Martin' and v.vehicle_number = '#009'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-007'
);

-- ============================================================
-- SERVICE ASSIGNMENTS
-- ============================================================

-- SO-2026-001 -> Max Verstappen
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Lead Diagnostics & Powertrain Engineer',
  now() - interval '3 hours'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- SO-2026-002 -> Sergio Perez
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Chassis, Suspension & Vehicle Dynamics Specialist',
  now() - interval '90 minutes'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-002'
  and p.full_name = 'Sergio Perez'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- SO-2026-003 -> Max Verstappen (Completed)
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at,
  completed_at
)
select
  so.id,
  m.id,
  'Lead Master Technician',
  now() - interval '2 days 4 hours',
  now() - interval '2 days'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-003'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- SO-2026-006 -> Sergio Perez
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Race Support Brake Technician',
  now() - interval '5 hours'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-006'
  and p.full_name = 'Sergio Perez'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- SO-2026-007 -> Max Verstappen
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at,
  completed_at
)
select
  so.id,
  m.id,
  'High Performance Calibrator',
  now() - interval '1 day',
  now() - interval '3 hours'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-007'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- ============================================================
-- SERVICE TASKS
-- ============================================================

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes,
  actual_minutes,
  started_at,
  completed_at
)
select
  so.id,
  m.id,
  'Engine Diagnostic Inspection',
  'Run diagnostic scan, inspect fault codes and verify engine operating parameters.',
  'completed',
  60,
  55,
  now() - interval '3 hours',
  now() - interval '2 hours'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Engine Diagnostic Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes,
  actual_minutes,
  started_at
)
select
  so.id,
  m.id,
  'High Voltage System Inspection',
  'Inspect hybrid high-voltage system status and associated diagnostic telemetry.',
  'in_progress',
  90,
  45,
  now() - interval '45 minutes'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'High Voltage System Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Brake System Inspection',
  'Inspect brake discs, pads, calipers, lines and Motul racing fluid condition.',
  'pending',
  45
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Brake System Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Cooling System Inspection',
  'Inspect coolant level, hoses, radiator, expansion tank and thermal leaks.',
  'pending',
  40
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Cooling System Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes,
  actual_minutes,
  started_at
)
select
  so.id,
  m.id,
  'Suspension Inspection',
  'Inspect active dampers, sway bars, and ride height sensors.',
  'in_progress',
  60,
  30,
  now() - interval '30 minutes'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-002' and p.full_name = 'Sergio Perez'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Suspension Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Wheel Alignment Check',
  'Laser wheel alignment check according to high-downforce circuit spec.',
  'pending',
  90
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-002' and p.full_name = 'Sergio Perez'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Wheel Alignment Check'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Brake Pad Replacement',
  'Awaiting delivery of replacement Brembo ventilated brake disc set.',
  'pending',
  75
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-006' and p.full_name = 'Sergio Perez'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Brake Pad Replacement'
);

-- ============================================================
-- SERVICE STATUS HISTORY
-- ============================================================

insert into public.service_status_history (
  service_order_id,
  previous_status,
  new_status,
  notes,
  created_at
)
select
  so.id,
  null,
  'scheduled'::public.service_status,
  'Service order initialized.',
  so.arrived_at - interval '30 minutes'
from public.service_orders so
where so.arrived_at is not null
and not exists (
  select 1 from public.service_status_history ssh
  where ssh.service_order_id = so.id and ssh.new_status = 'scheduled'
);

insert into public.service_status_history (
  service_order_id,
  previous_status,
  new_status,
  notes,
  created_at
)
select
  so.id,
  'scheduled'::public.service_status,
  so.status,
  'Service order transitioned to ' || so.status::text || ' state.',
  so.arrived_at
from public.service_orders so
where so.status in ('in_progress', 'diagnosis', 'waiting_for_parts', 'completed', 'payment')
and not exists (
  select 1 from public.service_status_history ssh
  where ssh.service_order_id = so.id and ssh.new_status = so.status
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'booking',
  'normal',
  'Booking Confirmed',
  'Your appointment for BMW M3 Touring on Oct 15 at 13:00 WIB has been confirmed.',
  false
from public.profiles p
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Booking Confirmed'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'service',
  'high',
  'Service Order Closed',
  'Work order SO-2026-003 has been completed. Your invoice receipt is now available.',
  true
from public.profiles p
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Service Order Closed'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'reminder',
  'low',
  'Maintenance Reminder',
  'Annual maintenance is approaching for your BMW M3 Touring (28,650 KM).',
  true
from public.profiles p
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Maintenance Reminder'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'service',
  'high',
  'New Job Assignment',
  'Assigned as lead technician for SO-2026-001 (BMW M Hybrid V8 #15).',
  false
from public.profiles p
where p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'New Job Assignment'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'service',
  'high',
  'New Job Assignment: SO-2026-002',
  'Assigned as lead chassis technician for SO-2026-002 (Aston Martin Valkyrie #007).',
  false
from public.profiles p
where p.full_name = 'Sergio Perez'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'New Job Assignment: SO-2026-002'
);