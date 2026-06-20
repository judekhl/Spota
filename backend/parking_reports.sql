-- =============================================================
-- Spota — parking_reports table
-- Added after initial schema (spota_mvp_schema.sql).
-- Paste into Supabase SQL Editor and run.
--
-- Purpose: stores anonymous user reports about current lot
-- occupancy. Reports are read-only signals; they do not update
-- available_spaces on parking_lots.
-- =============================================================


-- -------------------------------------------------------------
-- parking_reports
-- -------------------------------------------------------------

create table if not exists public.parking_reports (
  id             uuid        primary key default gen_random_uuid(),
  parking_lot_id uuid        not null references public.parking_lots(id) on delete cascade,
  report_value   text        not null check (report_value in ('empty', 'some_spots', 'almost_full', 'full')),
  source         text        not null default 'user',
  created_at     timestamptz not null default now()
);

-- Timestamps are stored in UTC (timestamptz).
-- Flutter clients call .toLocal() when displaying them.

alter table public.parking_reports enable row level security;


-- -------------------------------------------------------------
-- RLS policies
-- -------------------------------------------------------------

-- Anyone (logged-in or anonymous) can submit a report.
create policy "anon can insert reports"
  on public.parking_reports
  for insert
  to anon
  with check (true);

-- Anyone can read reports (needed for future "latest report" queries).
create policy "anon can select reports"
  on public.parking_reports
  for select
  to anon
  using (true);


-- -------------------------------------------------------------
-- Grants
-- -------------------------------------------------------------

grant insert on public.parking_reports to anon;
grant select on public.parking_reports to anon;
