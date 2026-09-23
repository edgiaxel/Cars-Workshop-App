-- ============================================================
-- Cars Workshop App
-- Pitstop Garage
-- Demo / UTS Seed Data
-- ============================================================

-- ============================================================
-- 1. PROFILES
-- ============================================================

INSERT INTO public.profiles (
    id,
    full_name,
    email,
    role,
    phone
)
SELECT
    u.id,
    'Christian Horner',
    u.email,
    'ADMIN'::public.user_role,
    '+62 811-0000-0001'
FROM auth.users AS u
WHERE u.email = 'admin@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone;


INSERT INTO public.profiles (
    id,
    full_name,
    email,
    role,
    phone
)
SELECT
    u.id,
    'Lewis Hamilton',
    u.email,
    'MECHANIC'::public.user_role,
    '+62 811-0000-0002'
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone;


INSERT INTO public.profiles (
    id,
    full_name,
    email,
    role,
    phone
)
SELECT
    u.id,
    'Max Verstappen',
    u.email,
    'MECHANIC'::public.user_role,
    '+62 811-0000-0003'
FROM auth.users AS u
WHERE u.email = 'verstappen@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone;


INSERT INTO public.profiles (
    id,
    full_name,
    email,
    role,
    phone
)
SELECT
    u.id,
    'BMW Motorsport',
    u.email,
    'CUSTOMER'::public.user_role,
    '+49 89 382-0000'
FROM auth.users AS u
WHERE u.email = 'bmw@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone;


INSERT INTO public.profiles (
    id,
    full_name,
    email,
    role,
    phone
)
SELECT
    u.id,
    'Porsche Motorsport',
    u.email,
    'CUSTOMER'::public.user_role,
    '+49 711 911-0000'
FROM auth.users AS u
WHERE u.email = 'porsche@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone;


INSERT INTO public.profiles (
    id,
    full_name,
    email,
    role,
    phone
)
SELECT
    u.id,
    'George Russel',
    u.email,
    'CUSTOMER'::public.user_role,
    '+62 811-0000-0006'
FROM auth.users AS u
WHERE u.email = 'russel@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone;


-- ============================================================
-- 2. CUSTOMERS
-- ============================================================

INSERT INTO public.customers (
    id,
    profile_id,
    customer_type,
    company_name,
    contact_person,
    phone,
    email,
    address,
    notes
)
SELECT
    '10000000-0000-0000-0000-000000000001',
    u.id,
    'COMPANY'::public.customer_type,
    'BMW Motorsport',
    'Andreas Müller',
    '+49 89 382-0000',
    'bmw@pitstopgarage.test',
    'Munich, Germany',
    'Factory motorsport customer.'
FROM auth.users AS u
WHERE u.email = 'bmw@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    company_name = EXCLUDED.company_name,
    contact_person = EXCLUDED.contact_person,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    notes = EXCLUDED.notes;


INSERT INTO public.customers (
    id,
    profile_id,
    customer_type,
    company_name,
    contact_person,
    phone,
    email,
    address,
    notes
)
SELECT
    '10000000-0000-0000-0000-000000000002',
    u.id,
    'COMPANY'::public.customer_type,
    'Porsche Motorsport',
    'Lukas Schneider',
    '+49 711 911-0000',
    'porsche@pitstopgarage.test',
    'Stuttgart, Germany',
    'Endurance racing customer.'
FROM auth.users AS u
WHERE u.email = 'porsche@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    company_name = EXCLUDED.company_name,
    contact_person = EXCLUDED.contact_person,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    notes = EXCLUDED.notes;


INSERT INTO public.customers (
    id,
    profile_id,
    customer_type,
    company_name,
    contact_person,
    phone,
    email,
    address,
    notes
)
SELECT
    '10000000-0000-0000-0000-000000000003',
    u.id,
    'INDIVIDUAL'::public.customer_type,
    NULL,
    'George Russel',
    '+62 811-0000-0006',
    'russel@pitstopgarage.test',
    'Bandung, Indonesia',
    'Private road-car customer.'
FROM auth.users AS u
WHERE u.email = 'russel@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    company_name = EXCLUDED.company_name,
    contact_person = EXCLUDED.contact_person,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    notes = EXCLUDED.notes;


-- ============================================================
-- 3. MECHANICS
-- ============================================================

INSERT INTO public.mechanics (
    id,
    profile_id,
    employee_code,
    specialization,
    phone,
    hire_date,
    status
)
SELECT
    '20000000-0000-0000-0000-000000000001',
    u.id,
    'MEC-001',
    'Motorsport Powertrain',
    '+62 811-1000-0001',
    '2024-01-15',
    'ACTIVE'::public.mechanic_status
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    employee_code = EXCLUDED.employee_code,
    specialization = EXCLUDED.specialization,
    phone = EXCLUDED.phone,
    hire_date = EXCLUDED.hire_date,
    status = EXCLUDED.status;


INSERT INTO public.mechanics (
    id,
    profile_id,
    employee_code,
    specialization,
    phone,
    hire_date,
    status
)
SELECT
    '20000000-0000-0000-0000-000000000002',
    u.id,
    'MEC-002',
    'Chassis and Braking Systems',
    '+62 811-1000-0002',
    '2024-03-01',
    'ACTIVE'::public.mechanic_status
FROM auth.users AS u
WHERE u.email = 'verstappen@pitstopgarage.test'
ON CONFLICT (id) DO UPDATE SET
    profile_id = EXCLUDED.profile_id,
    employee_code = EXCLUDED.employee_code,
    specialization = EXCLUDED.specialization,
    phone = EXCLUDED.phone,
    hire_date = EXCLUDED.hire_date,
    status = EXCLUDED.status;


-- ============================================================
-- 4. VEHICLES
-- ============================================================

INSERT INTO public.vehicles (
    id,
    customer_id,
    brand,
    model,
    year,
    vehicle_type,
    registration_number,
    unit_number,
    mileage,
    status,
    notes
)
VALUES
(
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'BMW',
    'M Hybrid V8',
    2025,
    'MOTORSPORT'::public.vehicle_type,
    NULL,
    'BMW-01',
    18450,
    'IN_SERVICE'::public.vehicle_status,
    'GTP endurance prototype.'
),
(
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Porsche',
    '963',
    2025,
    'MOTORSPORT'::public.vehicle_type,
    NULL,
    'POR-963-01',
    22100,
    'IN_SERVICE'::public.vehicle_status,
    'LMDh endurance prototype.'
),
(
    '30000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003',
    'BMW',
    'M4 Competition',
    2024,
    'PASSENGER'::public.vehicle_type,
    'D 1234 AZ',
    'CAR-01',
    12450,
    'ACTIVE'::public.vehicle_status,
    'Road car.'
),
(
    '30000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000003',
    'Toyota',
    'GR86',
    2023,
    'PASSENGER'::public.vehicle_type,
    'D 5678 AZ',
    NULL,
    28750,
    'ACTIVE'::public.vehicle_status,
    'Road car used for track days.'
)
ON CONFLICT (id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    brand = EXCLUDED.brand,
    model = EXCLUDED.model,
    year = EXCLUDED.year,
    vehicle_type = EXCLUDED.vehicle_type,
    registration_number = EXCLUDED.registration_number,
    unit_number = EXCLUDED.unit_number,
    mileage = EXCLUDED.mileage,
    status = EXCLUDED.status,
    notes = EXCLUDED.notes;


-- ============================================================
-- 5. PARTS
-- ============================================================

INSERT INTO public.parts (
    id,
    part_number,
    name,
    category,
    brand,
    description,
    stock_quantity,
    minimum_stock,
    unit_price,
    supplier,
    status
)
VALUES
(
    '40000000-0000-0000-0000-000000000001',
    'BRK-PAD-001',
    'High Performance Brake Pad Set',
    'Braking',
    'Brembo',
    'High-temperature brake pad set.',
    12,
    4,
    1850.00,
    'Brembo Racing Supply',
    'ACTIVE'::public.part_status
),
(
    '40000000-0000-0000-0000-000000000002',
    'ENG-OIL-001',
    'Motorsport Engine Oil 10W-60',
    'Fluids',
    'Castrol',
    'High-performance synthetic engine oil.',
    24,
    8,
    320.00,
    'Castrol Performance',
    'ACTIVE'::public.part_status
),
(
    '40000000-0000-0000-0000-000000000003',
    'FLT-OIL-001',
    'Premium Oil Filter',
    'Filters',
    'MANN',
    'Engine oil filter.',
    3,
    5,
    95.00,
    'MANN Filter Supply',
    'ACTIVE'::public.part_status
),
(
    '40000000-0000-0000-0000-000000000004',
    'BRK-FLD-001',
    'High Temperature Brake Fluid',
    'Braking',
    'Motul',
    'Competition brake fluid.',
    2,
    5,
    180.00,
    'Motul Racing Supply',
    'ACTIVE'::public.part_status
),
(
    '40000000-0000-0000-0000-000000000005',
    'AIR-FLT-001',
    'Performance Air Filter',
    'Filters',
    'K&N',
    'Reusable performance air filter.',
    10,
    3,
    140.00,
    'K&N Distributor',
    'ACTIVE'::public.part_status
),
(
    '40000000-0000-0000-0000-000000000006',
    'CLT-001',
    'High Performance Coolant',
    'Cooling',
    'Motul',
    'High-temperature coolant.',
    8,
    3,
    210.00,
    'Motul Racing Supply',
    'ACTIVE'::public.part_status
)
ON CONFLICT (id) DO UPDATE SET
    part_number = EXCLUDED.part_number,
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    brand = EXCLUDED.brand,
    description = EXCLUDED.description,
    stock_quantity = EXCLUDED.stock_quantity,
    minimum_stock = EXCLUDED.minimum_stock,
    unit_price = EXCLUDED.unit_price,
    supplier = EXCLUDED.supplier,
    status = EXCLUDED.status;


-- ============================================================
-- 6. SERVICE ORDERS
-- ============================================================

INSERT INTO public.service_orders (
    id,
    customer_id,
    vehicle_id,
    assigned_mechanic_id,
    service_type,
    description,
    priority,
    status,
    estimated_labor_cost,
    estimated_parts_cost,
    estimated_additional_cost,
    estimated_total,
    final_labor_cost,
    final_parts_cost,
    final_additional_cost,
    final_total,
    requested_at,
    started_at,
    completed_at
)
VALUES
(
    '50000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    'Brake System Inspection',
    'Inspect braking system before endurance event.',
    'HIGH'::public.service_priority,
    'IN_PROGRESS'::public.service_order_status,
    1200.00,
    3700.00,
    0.00,
    4900.00,
    0.00,
    0.00,
    0.00,
    0.00,
    now() - interval '2 days',
    now() - interval '1 day',
    NULL
),
(
    '50000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'Cooling System Service',
    'Inspect and service cooling system.',
    'URGENT'::public.service_priority,
    'WAITING_PARTS'::public.service_order_status,
    1500.00,
    210.00,
    0.00,
    1710.00,
    0.00,
    0.00,
    0.00,
    0.00,
    now() - interval '3 days',
    now() - interval '2 days',
    NULL
),
(
    '50000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003',
    '30000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000001',
    'Scheduled Maintenance',
    'Routine engine oil and filter service.',
    'NORMAL'::public.service_priority,
    'COMPLETED'::public.service_order_status,
    500.00,
    415.00,
    0.00,
    915.00,
    500.00,
    415.00,
    0.00,
    915.00,
    now() - interval '10 days',
    now() - interval '9 days',
    now() - interval '8 days'
),
(
    '50000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000003',
    '30000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000002',
    'Track Day Inspection',
    'Inspect brakes, suspension and fluids.',
    'NORMAL'::public.service_priority,
    'QUALITY_CHECK'::public.service_order_status,
    800.00,
    275.00,
    50.00,
    1125.00,
    750.00,
    275.00,
    50.00,
    1075.00,
    now() - interval '4 days',
    now() - interval '3 days',
    NULL
),
(
    '50000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000002',
    NULL,
    'Pre-Race Inspection',
    'Full inspection requested before upcoming race weekend.',
    'HIGH'::public.service_priority,
    'REQUESTED'::public.service_order_status,
    2000.00,
    0.00,
    0.00,
    2000.00,
    0.00,
    0.00,
    0.00,
    0.00,
    now() - interval '3 hours',
    NULL,
    NULL
)
ON CONFLICT (id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    vehicle_id = EXCLUDED.vehicle_id,
    assigned_mechanic_id = EXCLUDED.assigned_mechanic_id,
    service_type = EXCLUDED.service_type,
    description = EXCLUDED.description,
    priority = EXCLUDED.priority,
    status = EXCLUDED.status,
    estimated_labor_cost = EXCLUDED.estimated_labor_cost,
    estimated_parts_cost = EXCLUDED.estimated_parts_cost,
    estimated_additional_cost = EXCLUDED.estimated_additional_cost,
    estimated_total = EXCLUDED.estimated_total,
    final_labor_cost = EXCLUDED.final_labor_cost,
    final_parts_cost = EXCLUDED.final_parts_cost,
    final_additional_cost = EXCLUDED.final_additional_cost,
    final_total = EXCLUDED.final_total,
    requested_at = EXCLUDED.requested_at,
    started_at = EXCLUDED.started_at,
    completed_at = EXCLUDED.completed_at;


-- ============================================================
-- 7. SERVICE TASKS
-- ============================================================

INSERT INTO public.service_tasks (
    id,
    service_order_id,
    assigned_mechanic_id,
    title,
    description,
    status,
    completed_at
)
VALUES
(
    '60000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    'Inspect brake system',
    'Inspect pads, discs and calipers.',
    'COMPLETED'::public.service_task_status,
    now() - interval '20 hours'
),
(
    '60000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    'Replace brake pads',
    'Replace worn brake pad set.',
    'IN_PROGRESS'::public.service_task_status,
    NULL
),
(
    '60000000-0000-0000-0000-000000000003',
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    'Final brake inspection',
    'Verify braking performance after replacement.',
    'PENDING'::public.service_task_status,
    NULL
),
(
    '60000000-0000-0000-0000-000000000004',
    '50000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'Inspect cooling system',
    'Inspect radiator, hoses and coolant level.',
    'COMPLETED'::public.service_task_status,
    now() - interval '36 hours'
),
(
    '60000000-0000-0000-0000-000000000005',
    '50000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'Replace coolant',
    'Replace coolant after inspection.',
    'PENDING'::public.service_task_status,
    NULL
),
(
    '60000000-0000-0000-0000-000000000006',
    '50000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000001',
    'Replace engine oil',
    'Drain and replace engine oil.',
    'COMPLETED'::public.service_task_status,
    now() - interval '8 days'
),
(
    '60000000-0000-0000-0000-000000000007',
    '50000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000001',
    'Replace oil filter',
    'Replace engine oil filter.',
    'COMPLETED'::public.service_task_status,
    now() - interval '8 days'
),
(
    '60000000-0000-0000-0000-000000000008',
    '50000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000002',
    'Inspect suspension',
    'Inspect dampers, bushings and mounting points.',
    'COMPLETED'::public.service_task_status,
    now() - interval '2 days'
),
(
    '60000000-0000-0000-0000-000000000009',
    '50000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000002',
    'Inspect brake system',
    'Inspect pads, discs and brake fluid.',
    'COMPLETED'::public.service_task_status,
    now() - interval '2 days'
),
(
    '60000000-0000-0000-0000-000000000010',
    '50000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000002',
    'Quality inspection',
    'Perform final inspection before vehicle release.',
    'IN_PROGRESS'::public.service_task_status,
    NULL
)
ON CONFLICT (id) DO UPDATE SET
    service_order_id = EXCLUDED.service_order_id,
    assigned_mechanic_id = EXCLUDED.assigned_mechanic_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    status = EXCLUDED.status,
    completed_at = EXCLUDED.completed_at;


-- ============================================================
-- 8. SERVICE ORDER PARTS
-- ============================================================

INSERT INTO public.service_order_parts (
    id,
    service_order_id,
    part_id,
    quantity,
    unit_price
)
VALUES
(
    '70000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    2,
    1850.00
),
(
    '70000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000006',
    1,
    210.00
),
(
    '70000000-0000-0000-0000-000000000003',
    '50000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000002',
    1,
    320.00
),
(
    '70000000-0000-0000-0000-000000000004',
    '50000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000003',
    1,
    95.00
),
(
    '70000000-0000-0000-0000-000000000005',
    '50000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000004',
    1,
    180.00
),
(
    '70000000-0000-0000-0000-000000000006',
    '50000000-0000-0000-0000-000000000004',
    '40000000-0000-0000-0000-000000000005',
    1,
    95.00
)
ON CONFLICT (id) DO UPDATE SET
    service_order_id = EXCLUDED.service_order_id,
    part_id = EXCLUDED.part_id,
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price;


-- ============================================================
-- 9. SERVICE RECORDS
-- ============================================================

INSERT INTO public.service_records (
    id,
    service_order_id,
    vehicle_id,
    mechanic_id,
    summary,
    diagnosis,
    work_performed,
    recommendations,
    final_cost,
    completed_at
)
VALUES
(
    '80000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000003',
    '30000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000001',
    'Routine scheduled maintenance completed.',
    'Engine oil and filter were due for replacement.',
    'Replaced engine oil and oil filter. Performed basic inspection.',
    'Return for the next scheduled service interval.',
    915.00,
    now() - interval '8 days'
)
ON CONFLICT (id) DO UPDATE SET
    service_order_id = EXCLUDED.service_order_id,
    vehicle_id = EXCLUDED.vehicle_id,
    mechanic_id = EXCLUDED.mechanic_id,
    summary = EXCLUDED.summary,
    diagnosis = EXCLUDED.diagnosis,
    work_performed = EXCLUDED.work_performed,
    recommendations = EXCLUDED.recommendations,
    final_cost = EXCLUDED.final_cost,
    completed_at = EXCLUDED.completed_at;


-- ============================================================
-- 10. STATUS HISTORY
-- ============================================================

INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    'REQUESTED'::public.service_order_status,
    u.id,
    'Service request received.',
    now() - interval '2 days'
FROM auth.users AS u
WHERE u.email = 'bmw@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000001',
    'INSPECTION'::public.service_order_status,
    u.id,
    'Vehicle inspection started.',
    now() - interval '40 hours'
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000003',
    '50000000-0000-0000-0000-000000000001',
    'DIAGNOSIS'::public.service_order_status,
    u.id,
    'Brake pads require replacement.',
    now() - interval '30 hours'
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000004',
    '50000000-0000-0000-0000-000000000001',
    'IN_PROGRESS'::public.service_order_status,
    u.id,
    'Brake pad replacement in progress.',
    now() - interval '10 hours'
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000005',
    '50000000-0000-0000-0000-000000000002',
    'REQUESTED'::public.service_order_status,
    u.id,
    'Cooling system service requested.',
    now() - interval '3 days'
FROM auth.users AS u
WHERE u.email = 'porsche@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000006',
    '50000000-0000-0000-0000-000000000002',
    'WAITING_PARTS'::public.service_order_status,
    u.id,
    'Required coolant currently below workshop stock threshold.',
    now() - interval '1 day'
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000007',
    '50000000-0000-0000-0000-000000000003',
    'REQUESTED'::public.service_order_status,
    u.id,
    'Routine maintenance requested.',
    now() - interval '10 days'
FROM auth.users AS u
WHERE u.email = 'russel@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000008',
    '50000000-0000-0000-0000-000000000003',
    'COMPLETED'::public.service_order_status,
    u.id,
    'Service completed and vehicle released.',
    now() - interval '8 days'
FROM auth.users AS u
WHERE u.email = 'hamilton@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000009',
    '50000000-0000-0000-0000-000000000004',
    'IN_PROGRESS'::public.service_order_status,
    u.id,
    'Inspection and preparation completed.',
    now() - interval '3 days'
FROM auth.users AS u
WHERE u.email = 'verstappen@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;


INSERT INTO public.service_order_status_history (
    id,
    service_order_id,
    status,
    changed_by,
    notes,
    created_at
)
SELECT
    '90000000-0000-0000-0000-000000000010',
    '50000000-0000-0000-0000-000000000004',
    'QUALITY_CHECK'::public.service_order_status,
    u.id,
    'Vehicle undergoing final quality inspection.',
    now() - interval '6 hours'
FROM auth.users AS u
WHERE u.email = 'verstappen@pitstopgarage.test'
ON CONFLICT (id) DO NOTHING;