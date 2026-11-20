-- PitMate v2.0 Initial Seed Data
-- Workshop Bays (5 Bays)
INSERT INTO public.workshop_bays (id, name, bay_type, is_active)
VALUES
  (1, 'Bay 1 - Quick Service', '2-Post Lift', TRUE),
  (2, 'Bay 2 - Heavy Mechanical', '2-Post Lift', TRUE),
  (3, 'Bay 3 - Diagnostics & Electrical', 'Flat Diagnostic Bay', TRUE),
  (4, 'Bay 4 - Suspension & Brakes', '4-Post Lift', TRUE),
  (5, 'Bay 5 - Inspection & Wheel Alignment', 'Alignment Rack', TRUE)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  bay_type = EXCLUDED.bay_type,
  is_active = EXCLUDED.is_active;
