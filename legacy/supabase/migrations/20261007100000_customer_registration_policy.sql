-- ============================================================
-- Migration: 20261007100000_customer_registration_policy
-- Allow newly registered authenticated users to insert their
-- own profile as 'customer' strictly matching their auth.uid().
-- Mechanics and Admin roles cannot be self-registered.
-- ============================================================

create policy "profiles_insert_self_customer"
on public.profiles
for insert
to authenticated
with check (
  id = (select auth.uid())
  and
  role = 'customer'::public.user_role
);
