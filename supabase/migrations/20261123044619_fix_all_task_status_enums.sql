DO $$ BEGIN
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'pending';
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'assigned';
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'in_progress';
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'paused';
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'completed';
  ALTER TYPE public.task_status ADD VALUE IF NOT EXISTS 'blocked';
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
