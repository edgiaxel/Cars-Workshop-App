DO $$ BEGIN
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'assigned';
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
