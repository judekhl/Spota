-- =============================================================
-- Spota — Add data-quality fields to parking_lots
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS).
-- Paste into Supabase SQL Editor and run.
-- No existing data is deleted or overwritten.
-- =============================================================


-- opening_hours_text
-- Human-readable hours string set during manual verification.
-- NULL = unknown (do not display as if known).
ALTER TABLE public.parking_lots
  ADD COLUMN IF NOT EXISTS opening_hours_text text;


-- phone
-- Lot or management company phone number.
-- NULL = unknown.
ALTER TABLE public.parking_lots
  ADD COLUMN IF NOT EXISTS phone text;


-- source_url
-- Google Maps URL or official page for this lot.
-- Used to re-verify coordinates without re-searching.
ALTER TABLE public.parking_lots
  ADD COLUMN IF NOT EXISTS source_url text;


-- data_notes
-- Internal free-text note for the person who verified this row.
-- Example: 'Verified by Jude on 2026-06-21. Entrance is on side street.'
ALTER TABLE public.parking_lots
  ADD COLUMN IF NOT EXISTS data_notes text;


-- data_source
-- Where the field values came from.
-- Expected values: 'google_maps', 'operator', 'demo', 'manual'
ALTER TABLE public.parking_lots
  ADD COLUMN IF NOT EXISTS data_source text;


-- verified_status
-- Lifecycle state of this row.
--   'demo'        = placeholder row, not safe for real navigation testing
--   'unverified'  = real lot but fields not yet confirmed
--   'verified'    = coordinates and core fields confirmed in Google Maps
-- Defaults to 'unverified' for any new row going forward.
ALTER TABLE public.parking_lots
  ADD COLUMN IF NOT EXISTS verified_status text DEFAULT 'unverified';

-- Add the check constraint separately so it can be wrapped in a
-- DO block and skipped safely if it already exists.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'parking_lots_verified_status_check'
      AND conrelid = 'public.parking_lots'::regclass
  ) THEN
    ALTER TABLE public.parking_lots
      ADD CONSTRAINT parking_lots_verified_status_check
      CHECK (verified_status IN ('demo', 'unverified', 'verified'));
  END IF;
END $$;


-- =============================================================
-- After running: mark every existing demo row immediately
-- so the app and operators know which rows are not verified.
--
-- Run this AFTER the ALTER statements above:
-- =============================================================

-- Mark all current rows as 'demo' so nothing is ambiguously 'unverified'
-- (they were inserted by seed_demo_data.sql and have not been verified).
-- Safe to run: only touches verified_status, leaves all other fields intact.

UPDATE public.parking_lots
SET
  verified_status = 'demo',
  data_source     = 'demo',
  data_notes      = 'Seeded from seed_demo_data.sql — not verified for real navigation'
WHERE verified_status IS NULL
   OR verified_status = 'unverified';


-- Confirm: you should see all rows with verified_status = 'demo'
SELECT id, name, verified_status, data_source, data_notes
FROM public.parking_lots
ORDER BY name;
