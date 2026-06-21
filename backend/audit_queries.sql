-- =============================================================
-- Spota — parking_lots Audit & Cleanup Queries
-- Run these in the Supabase SQL Editor (safe SELECT-only audits).
-- The UPDATE template at the bottom must be run ONE LOT AT A TIME.
-- =============================================================


-- -------------------------------------------------------------
-- AUDIT 1: Full snapshot — see all lots
-- -------------------------------------------------------------
SELECT
  id,
  name,
  address,
  latitude,
  longitude,
  total_spaces,
  available_spaces,
  price,
  is_open,
  updated_at
FROM public.parking_lots
ORDER BY name;


-- -------------------------------------------------------------
-- AUDIT 2: Coordinates outside the valid Haifa bounding box
--   latitude  must be 32.6 – 33.1
--   longitude must be 34.8 – 35.2
-- Rows returned here have wrong or reversed coordinates.
-- -------------------------------------------------------------
SELECT
  id,
  name,
  latitude,
  longitude
FROM public.parking_lots
WHERE
  latitude  < 32.6 OR latitude  > 33.1 OR
  longitude < 34.8 OR longitude > 35.2;


-- -------------------------------------------------------------
-- AUDIT 3: Possible reversed lat/lon
--   If latitude > 34 the lon value was likely stored in the lat column.
-- -------------------------------------------------------------
SELECT
  id,
  name,
  latitude,
  longitude
FROM public.parking_lots
WHERE latitude > 34 OR longitude < 30;


-- -------------------------------------------------------------
-- AUDIT 4: Zero coordinates (fallback default — means no real coord)
-- -------------------------------------------------------------
SELECT
  id,
  name,
  latitude,
  longitude
FROM public.parking_lots
WHERE latitude = 0 OR longitude = 0;


-- -------------------------------------------------------------
-- AUDIT 5: Empty or blank address
-- -------------------------------------------------------------
SELECT
  id,
  name,
  address
FROM public.parking_lots
WHERE trim(address) = '';


-- -------------------------------------------------------------
-- AUDIT 6: Empty or blank price
-- -------------------------------------------------------------
SELECT
  id,
  name,
  price
FROM public.parking_lots
WHERE trim(price) = '';


-- -------------------------------------------------------------
-- AUDIT 7: Impossible space counts
--   available_spaces > total_spaces is invalid
--   total_spaces <= 0 violates schema constraint but worth checking
-- -------------------------------------------------------------
SELECT
  id,
  name,
  total_spaces,
  available_spaces
FROM public.parking_lots
WHERE available_spaces > total_spaces
   OR total_spaces <= 0;


-- -------------------------------------------------------------
-- AUDIT 8: Open lots with 0 available spaces (possibly stale)
--   These show as "Full" in the app — verify they are really full
--   and not just outdated demo data.
-- -------------------------------------------------------------
SELECT
  id,
  name,
  is_open,
  available_spaces,
  total_spaces,
  updated_at
FROM public.parking_lots
WHERE is_open = true AND available_spaces = 0;


-- -------------------------------------------------------------
-- AUDIT 9: Stale data — not updated in the last 7 days
-- -------------------------------------------------------------
SELECT
  id,
  name,
  updated_at,
  now() - updated_at AS age
FROM public.parking_lots
WHERE updated_at < now() - interval '7 days'
ORDER BY updated_at ASC;


-- =============================================================
-- UPDATE TEMPLATE — use ONE lot at a time, never bulk-update
-- =============================================================
--
-- Workflow for each lot:
--   Step 1. Run AUDIT 1 above to find the lot's UUID.
--   Step 2. Look up the real location in Google Maps (see data_quality.md).
--   Step 3. Right-click the lot entrance → copy coordinates.
--   Step 4. Fill in ALL values below with verified real data.
--   Step 5. Run the UPDATE.
--   Step 6. Run the verification SELECT to confirm.
--
-- NEVER run this without a WHERE id = '...' clause.
-- NEVER update multiple rows in one statement.
-- =============================================================

-- Step 1: find the lot's UUID
SELECT id, name FROM public.parking_lots ORDER BY name;

-- Step 2: verify the current row before touching it
SELECT
  id, name, address, latitude, longitude,
  total_spaces, available_spaces, price, is_open
FROM public.parking_lots
WHERE id = 'PASTE-UUID-HERE';

-- Step 3: apply verified data
-- (Run backend/add_data_fields.sql first to make the extra columns available)
UPDATE public.parking_lots
SET
  name                = 'חניון הדר המרמל',     -- verified Hebrew name, matches signage
  address             = 'רחוב הרצל 50, חיפה',   -- full street address
  latitude            = 32.819100,              -- Google Maps right-click → first number
  longitude           = 35.000300,              -- Google Maps right-click → second number
  total_spaces        = 200,                    -- verified physical capacity
  available_spaces    = 100,                    -- set conservatively; operator will update live
  price               = '6 ₪/שעה',             -- verified price
  is_open             = true,                   -- current status
  opening_hours_text  = 'ראשון–שישי 07:00–23:00, שבת סגור',  -- or NULL if unknown
  phone               = NULL,                   -- or '+972-4-...' if known
  source_url          = 'https://maps.google.com/?q=32.819100,35.000300',
  data_notes          = 'Verified by [name] on [date]. Entrance on [street].',
  data_source         = 'google_maps',
  verified_status     = 'verified'
WHERE id = 'PASTE-UUID-HERE';                 -- UUID from Step 1 — required

-- Step 4: confirm the update applied correctly
SELECT
  id, name, address, latitude, longitude,
  total_spaces, available_spaces, price, is_open,
  opening_hours_text, verified_status, updated_at
FROM public.parking_lots
WHERE id = 'PASTE-UUID-HERE';


-- =============================================================
-- INSERT TEMPLATE — add one new verified parking lot
-- =============================================================
--
-- Prerequisites:
--   1. Run backend/add_data_fields.sql to ensure all columns exist.
--   2. Find a valid operator_id: SELECT id, email FROM public.operators;
--   3. Verify the lot in Google Maps before inserting.
--
-- =============================================================

-- Find your operator_id first
SELECT id, email, name FROM public.operators;

-- Insert one verified lot
INSERT INTO public.parking_lots (
  operator_id,
  name,
  address,
  latitude,
  longitude,
  total_spaces,
  available_spaces,
  price,
  is_open,
  opening_hours_text,
  phone,
  source_url,
  data_notes,
  data_source,
  verified_status
) VALUES (
  'PASTE-OPERATOR-UUID-HERE',                  -- from SELECT above
  'חניון הדר המרמל',                            -- Hebrew name, matches real signage
  'רחוב הרצל 50, חיפה',                         -- full street address
  32.819100,                                   -- Google Maps right-click → first number
  35.000300,                                   -- Google Maps right-click → second number
  200,                                         -- verified total capacity
  100,                                         -- starting estimate; operator updates live
  '6 ₪/שעה',                                  -- verified price (or 'לא ידוע' if unknown)
  true,                                        -- is it open right now?
  'ראשון–שישי 07:00–23:00, שבת סגור',           -- opening hours text, or NULL if unknown
  NULL,                                        -- phone, or '+972-4-xxx-xxxx' if known
  'https://maps.google.com/?q=32.819100,35.000300',
  'Verified by [name] on [date]. Entrance on [street name].',
  'google_maps',
  'verified'
);

-- Confirm the insert
SELECT id, name, latitude, longitude, verified_status, updated_at
FROM public.parking_lots
ORDER BY updated_at DESC
LIMIT 3;
