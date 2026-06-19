-- =============================================================
-- Spota MVP Schema
-- Paste into Supabase SQL Editor and run in order.
-- =============================================================


-- -------------------------------------------------------------
-- operators
-- -------------------------------------------------------------

create table operators (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text not null unique,
  name       text not null,
  created_at timestamptz not null default now()
);

alter table operators enable row level security;

create policy "operators: select own row"
  on operators for select
  using (auth.uid() = id);

create policy "operators: insert own row"
  on operators for insert
  with check (auth.uid() = id);

create policy "operators: update own row"
  on operators for update
  using (auth.uid() = id);


-- -------------------------------------------------------------
-- parking_lots
-- -------------------------------------------------------------

create table parking_lots (
  id               uuid primary key default gen_random_uuid(),
  operator_id      uuid not null references operators(id) on delete cascade,
  name             text not null,
  address          text not null,
  latitude         double precision not null,
  longitude        double precision not null,
  total_spaces     integer not null check (total_spaces > 0),
  available_spaces integer not null check (available_spaces >= 0),
  price            text not null,
  is_open          boolean not null default true,
  updated_at       timestamptz not null default now()
);

alter table parking_lots enable row level security;

-- Public read allows the user-facing map to load without login.
create policy "parking_lots: public select"
  on parking_lots for select
  using (true);

create policy "parking_lots: operator insert"
  on parking_lots for insert
  with check (auth.uid() = operator_id);

create policy "parking_lots: operator update"
  on parking_lots for update
  using (auth.uid() = operator_id);

create policy "parking_lots: operator delete"
  on parking_lots for delete
  using (auth.uid() = operator_id);


-- -------------------------------------------------------------
-- parking_updates
-- -------------------------------------------------------------

create table parking_updates (
  id               uuid primary key default gen_random_uuid(),
  lot_id           uuid not null references parking_lots(id) on delete cascade,
  operator_id      uuid not null references operators(id) on delete cascade,
  available_spaces integer not null check (available_spaces >= 0),
  price            text not null,
  is_open          boolean not null,
  created_at       timestamptz not null default now()
);

alter table parking_updates enable row level security;

create policy "parking_updates: public select"
  on parking_updates for select
  using (true);

create policy "parking_updates: operator insert"
  on parking_updates for insert
  with check (auth.uid() = operator_id);


-- -------------------------------------------------------------
-- Auto-update updated_at on parking_lots
-- -------------------------------------------------------------

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger parking_lots_set_updated_at
  before update on parking_lots
  for each row execute procedure set_updated_at();
