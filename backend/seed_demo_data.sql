-- =============================================================
-- Spota Demo Seed Data
-- Inserts 5 demo parking lots for Haifa testing.
-- Operator: ffce33c0-661c-47e1-98b1-b01515c0730f
-- =============================================================

do $$
declare
  demo_operator_id uuid := 'ffce33c0-661c-47e1-98b1-b01515c0730f';
begin

  -- Insert demo operator first (FK: parking_lots.operator_id → operators.id).
  -- ON CONFLICT DO NOTHING makes this safe to re-run.
  insert into operators (id, email, name)
  values (
    demo_operator_id,
    'demo@spota.app',
    'Demo Operator'
  )
  on conflict (id) do nothing;

  insert into parking_lots
    (operator_id, name, address, latitude, longitude, total_spaces, available_spaces, price, is_open)
  values

    -- 1. Hadar HaCarmel — busy commercial centre
    (
      demo_operator_id,
      'חניון הדר המרמל',
      'רחוב הרצל 50, חיפה',
      32.8191, 35.0003,
      200, 47,
      '6 ₪/שעה',
      true
    ),

    -- 2. Carmel Center — upscale neighbourhood
    (
      demo_operator_id,
      'חניון מרכז הכרמל',
      'שדרות הנשיא 120, חיפה',
      32.8078, 34.9893,
      150, 0,
      '8 ₪/שעה',
      true
    ),

    -- 3. Haifa Port — near the waterfront
    (
      demo_operator_id,
      'חניון הנמל',
      'שד׳ בן גוריון 10, חיפה',
      32.8232, 35.0092,
      300, 120,
      '5 ₪/שעה',
      true
    ),

    -- 4. Downtown / Wadi Nisnas
    (
      demo_operator_id,
      'חניון ואדי ניסנאס',
      'רחוב עבאס 3, חיפה',
      32.8161, 35.0041,
      80, 22,
      'חינם',
      true
    ),

    -- 5. Bat Galim — beachside lot, closed overnight
    (
      demo_operator_id,
      'חניון בת גלים',
      'שד׳ שאול המלך 1, חיפה',
      32.8314, 34.9782,
      120, 0,
      '4 ₪/שעה',
      false
    );

end $$;
