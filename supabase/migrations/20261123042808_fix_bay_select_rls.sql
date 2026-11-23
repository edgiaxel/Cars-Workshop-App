DROP POLICY IF EXISTS "Anyone view workshop_bays" ON public.workshop_bays;
CREATE POLICY "Anyone view workshop_bays" ON public.workshop_bays FOR SELECT USING (true);
