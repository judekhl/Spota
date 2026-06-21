# Spota — parking_lots Data Quality Rules

## Column reference

| Column | Type | Constraint | Notes |
|---|---|---|---|
| `id` | uuid | PK, auto | Never set manually |
| `operator_id` | uuid | FK → operators | Required |
| `name` | text | NOT NULL | Hebrew preferred; must match real signage |
| `address` | text | NOT NULL | Full street address in Hebrew |
| `latitude` | double precision | NOT NULL | Decimal degrees, ~32.x for Haifa |
| `longitude` | double precision | NOT NULL | Decimal degrees, ~34.x–35.x for Haifa |
| `total_spaces` | integer | > 0 | Physical capacity of the lot |
| `available_spaces` | integer | >= 0, <= total_spaces | Operator-maintained; not set by user reports |
| `price` | text | NOT NULL | Free-form (e.g. `6 ₪/שעה`, `חינם`) |
| `is_open` | boolean | NOT NULL | Current open/closed status |
| `updated_at` | timestamptz | auto (trigger) | Set automatically on every UPDATE; UTC |

**Optional fields added by `backend/add_data_fields.sql` (all nullable):**

| Column | Type | Default | Notes |
|---|---|---|---|
| `opening_hours_text` | text | NULL | Human-readable hours, e.g. `ראשון–שישי 07:00–23:00`. NULL = unknown. |
| `phone` | text | NULL | Lot phone number. NULL = unknown. |
| `source_url` | text | NULL | Google Maps or official page URL used during verification. |
| `data_notes` | text | NULL | Internal note: who verified, when, any caveats. |
| `data_source` | text | NULL | `'google_maps'` / `'operator'` / `'demo'` / `'manual'` |
| `verified_status` | text | `'unverified'` | `'demo'` / `'unverified'` / `'verified'` — see lifecycle below. |

**Fields that do NOT exist in this schema:**
- `opening_hours` — there is no text hours field. Only `is_open` (boolean) plus the optional `opening_hours_text` above.
- `description` — not in schema.
- `image_url` — not in schema (Flutter falls back to a gradient placeholder).

---

## Coordinate rules

- **Coordinates must point to the real parking lot entrance or the centre of the parking area**, not the street corner or general neighbourhood.
- `latitude` is always the north–south value (~32.x for Haifa).
- `longitude` is always the east–west value (~34.9–35.1 for Haifa).
- **Never swap them.** A reversed pair (lat ≈ 34.x, lon ≈ 32.x) sends Waze to a location in Greece.
- Valid Haifa bounding box: `latitude` between 32.6 and 33.1, `longitude` between 34.8 and 35.2.

### How to get exact coordinates from Google Maps
1. Open Google Maps in a browser.
2. Search the exact parking lot name or address.
3. Zoom in until you can see the parking lot boundary.
4. Right-click on the **entrance** or centre of the lot.
5. Click the coordinates shown at the top of the context menu — they copy automatically.
6. The **first number** is `latitude`. The **second number** is `longitude`.
7. Paste into Supabase using the UPDATE template below.

---

## Timestamp rules

- `updated_at` is stored in **UTC** (timestamptz).
- The Flutter app calls `.toLocal()` when displaying it — no manual conversion needed.
- Do not manually set `updated_at`; the `parking_lots_set_updated_at` trigger handles it on every UPDATE.

---

## available_spaces rules

- `available_spaces` is set **only by operators** via the operator dashboard.
- **User reports (`parking_reports`) do NOT update `available_spaces`.** Reports are advisory signals only; they go to the separate `parking_reports` table.
- `available_spaces` must always be between 0 and `total_spaces`.

---

## verified_status lifecycle

| Value | Meaning | Safe for navigation testing? |
|---|---|---|
| `'demo'` | Seeded from `seed_demo_data.sql`. Coordinates are approximate. | **No** |
| `'unverified'` | Real lot data entered but not yet confirmed in Google Maps. | **No** |
| `'verified'` | Coordinates confirmed by right-clicking the lot entrance in Google Maps. | **Yes** |

Only rows with `verified_status = 'verified'` should be used to test Waze or Google Maps navigation.

---

## Demo data rules

- The file `backend/seed_demo_data.sql` contains placeholder demo lots for development only.
- **Demo data (`verified_status = 'demo'`) must never be used for real navigation testing.**
- Unknown prices or hours must be stored as NULL, not guessed or left as demo values.
- `available_spaces` must not be presented as live data unless an operator has recently updated it.
- After running `backend/add_data_fields.sql`, all existing unverified rows are automatically marked `verified_status = 'demo'`.

### Demo data reset workflow

Two options — pick one after running the audit queries:

**Option A — Fix in place (recommended if most data is close to correct)**
1. Run `backend/add_data_fields.sql` to add the new columns.
2. All rows are now marked `verified_status = 'demo'`.
3. Verify lots one by one using Google Maps.
4. Run the per-lot UPDATE template in `backend/audit_queries.sql` for each confirmed lot.
5. Set `verified_status = 'verified'` when done.

**Option B — Clean slate (recommended if coordinates are badly wrong)**
1. Run Audit 1 in `backend/audit_queries.sql` to see all rows.
2. Confirm the DELETE SQL below, then run it.
3. Insert fresh rows using the INSERT template in `backend/audit_queries.sql`.
4. Start with 1–2 verified lots before adding more.

```sql
-- SHOW THIS TO A HUMAN BEFORE RUNNING.
-- Deletes all rows belonging to the demo operator.
-- Replace operator_id with the real UUID from your Supabase operators table.

-- Preview first:
SELECT id, name FROM public.parking_lots
WHERE operator_id = 'ffce33c0-661c-47e1-98b1-b01515c0730f';

-- Only uncomment and run after confirming the preview above:
-- DELETE FROM public.parking_lots
-- WHERE operator_id = 'ffce33c0-661c-47e1-98b1-b01515c0730f';
```

---

## RLS summary

- Anonymous users: SELECT only on `parking_lots`.
- Authenticated operators: INSERT / UPDATE / DELETE only their own rows (`operator_id = auth.uid()`).
- No public writes to `parking_lots` directly.
