-- Seed initial 5 bays if not present
INSERT INTO public.workshop_bays (bay_number, name, status)
VALUES
  (1, 'Bay 01 - Quick Service', 'available'),
  (2, 'Bay 02 - Diagnostic & Performance', 'available'),
  (3, 'Bay 03 - Heavy Repair', 'available'),
  (4, 'Bay 04 - Electrical & Electronics', 'available'),
  (5, 'Bay 05 - Suspension & Brakes', 'available')
ON CONFLICT (bay_number) DO UPDATE
SET name = EXCLUDED.name,
    updated_at = NOW();
