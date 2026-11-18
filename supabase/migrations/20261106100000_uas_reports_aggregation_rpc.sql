-- ============================================================
-- Migration: 20261106100000_uas_reports_aggregation_rpc.sql
-- Description:
--   Phase 6 — UAS Reporting Backend & Aggregation Telemetry RPC
--   Provides server-side aggregation for:
--     1. Intake origin comparison (booking vs walk-in vs legacy_unknown)
--     2. Volume over time by day
--     3. Service status distribution
--     4. Mechanic workload and assignments
--     5. Financial summaries (estimated pipeline vs settled totals)
--   Enforces Admin-only authorization, safe search_path, and boundary handling.
-- ============================================================

create or replace function public.get_admin_reports_telemetry(
  p_start_date timestamptz default null,
  p_end_date timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_start timestamptz;
  v_end timestamptz;
  v_result jsonb;

  v_total_orders int;
  v_booking_count int;
  v_walk_in_count int;
  v_legacy_count int;

  v_estimated_total numeric;
  v_settled_total numeric;
  v_settled_count int;
  v_pending_settlement_count int;

  v_status_distribution jsonb;
  v_volume_timeline jsonb;
  v_mechanic_workload jsonb;
begin
  -- 1. Security Authorization Check (Admin only)
  if not public.is_admin() then
    raise exception 'Unauthorized: Only administrators can view reporting telemetry.';
  end if;

  -- 2. Date Boundary Normalization (Inclusive range)
  v_start := coalesce(p_start_date, (now() - interval '30 days'));
  v_end := coalesce(p_end_date, now());

  -- Ensure start is not after end
  if v_start > v_end then
    raise exception 'Invalid date range: start_date must be before or equal to end_date.';
  end if;

  -- 3. Intake Breakdown
  select
    count(*)::int,
    count(*) filter (where intake_origin = 'booking')::int,
    count(*) filter (where intake_origin = 'walk_in')::int,
    count(*) filter (where intake_origin = 'legacy_unknown' or intake_origin is null)::int
  into
    v_total_orders,
    v_booking_count,
    v_walk_in_count,
    v_legacy_count
  from public.service_orders
  where created_at >= v_start and created_at <= v_end;

  -- 4. Financial Summary
  select
    coalesce(sum(estimated_total), 0),
    coalesce(sum(final_total) filter (where status in ('completed', 'closed') and final_total is not null), 0),
    count(*) filter (where status in ('completed', 'closed') and final_total is not null)::int,
    count(*) filter (where status not in ('completed', 'closed', 'cancelled'))::int
  into
    v_estimated_total,
    v_settled_total,
    v_settled_count,
    v_pending_settlement_count
  from public.service_orders
  where created_at >= v_start and created_at <= v_end;

  -- 5. Service Status Distribution
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'status', status::text,
      'count', count
    ) order by count desc
  ), '[]'::jsonb)
  into v_status_distribution
  from (
    select
      status,
      count(*)::int as count
    from public.service_orders
    where created_at >= v_start and created_at <= v_end
    group by status
  ) s;

  -- 6. Volume Over Time (Grouped by Date)
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'date', to_char(day_series, 'YYYY-MM-DD'),
      'total_count', coalesce(t.total_count, 0),
      'completed_count', coalesce(t.completed_count, 0)
    ) order by day_series asc
  ), '[]'::jsonb)
  into v_volume_timeline
  from (
    select generate_series(
      date_trunc('day', v_start),
      date_trunc('day', v_end),
      interval '1 day'
    ) as day_series
  ) days
  left join (
    select
      date_trunc('day', created_at) as order_day,
      count(*)::int as total_count,
      count(*) filter (where status in ('completed', 'closed'))::int as completed_count
    from public.service_orders
    where created_at >= v_start and created_at <= v_end
    group by date_trunc('day', created_at)
  ) t on days.day_series = t.order_day;

  -- 7. Mechanic Workload
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'mechanic_id', m.id,
      'mechanic_name', p.full_name,
      'employee_code', m.employee_code,
      'specialization', m.specialization,
      'assigned_count', coalesce(w.assigned_count, 0),
      'active_count', coalesce(w.active_count, 0),
      'completed_count', coalesce(w.completed_count, 0)
    ) order by coalesce(w.assigned_count, 0) desc, p.full_name asc
  ), '[]'::jsonb)
  into v_mechanic_workload
  from public.mechanics m
  join public.profiles p on p.id = m.profile_id
  left join (
    select
      sa.mechanic_id,
      count(distinct so.id)::int as assigned_count,
      count(distinct so.id) filter (where so.status not in ('completed', 'closed', 'cancelled'))::int as active_count,
      count(distinct so.id) filter (where so.status in ('completed', 'closed'))::int as completed_count
    from public.service_assignments sa
    join public.service_orders so on so.id = sa.service_order_id
    where so.created_at >= v_start and so.created_at <= v_end
    group by sa.mechanic_id
  ) w on w.mechanic_id = m.id
  where m.id is not null;

  -- 8. Assemble Full Telemetry Response
  v_result := jsonb_build_object(
    'date_range', jsonb_build_object(
      'start_date', v_start,
      'end_date', v_end
    ),
    'intake_breakdown', jsonb_build_object(
      'total_orders', v_total_orders,
      'booking_count', v_booking_count,
      'walk_in_count', v_walk_in_count,
      'legacy_unknown_count', v_legacy_count
    ),
    'financial_summary', jsonb_build_object(
      'estimated_total', v_estimated_total,
      'settled_total', v_settled_total,
      'settled_orders_count', v_settled_count,
      'pending_settlement_count', v_pending_settlement_count
    ),
    'status_distribution', v_status_distribution,
    'volume_timeline', v_volume_timeline,
    'mechanic_workload', v_mechanic_workload
  );

  return v_result;
end;
$$;

revoke all on function public.get_admin_reports_telemetry(timestamptz, timestamptz) from public;
grant execute on function public.get_admin_reports_telemetry(timestamptz, timestamptz) to authenticated;
