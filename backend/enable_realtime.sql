-- =============================================================
-- Spota — Enable Supabase Realtime
-- Paste into Supabase SQL Editor and run.
-- =============================================================


-- parking_lots: REPLICA IDENTITY FULL so UPDATE events carry
-- the full new row (available_spaces, price, is_open), not just
-- the primary key. Required for the live map view to work.
alter table parking_lots replica identity full;

alter publication supabase_realtime add table parking_lots;


-- parking_updates: INSERT-only audit log. Default replica identity
-- is enough — subscribers see each new update row as it is written.
alter publication supabase_realtime add table parking_updates;
