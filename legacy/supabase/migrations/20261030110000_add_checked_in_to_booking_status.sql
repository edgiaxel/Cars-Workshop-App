-- ============================================================
-- Migration: 20261030110000_add_checked_in_to_booking_status.sql
-- Description: Add 'checked_in' value to public.booking_status enum.
-- Separated to ensure enum commit before referencing in downstream migrations.
-- ============================================================

alter type public.booking_status add value if not exists 'checked_in';
