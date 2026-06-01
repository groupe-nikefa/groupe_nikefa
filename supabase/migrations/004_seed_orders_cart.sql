DO $$
DECLARE
  test_user_id UUID;
  admin_user_id UUID;
  stethoscope_id UUID;
  gloves_id UUID;
  syringes_id UUID;
  order1_id UUID;
  order2_id UUID;
BEGIN
  -- Look up users by email instead of hardcoded UUIDs.
  -- Create test users first via Supabase Auth, then run this seed.
  -- If users don't exist yet, the seed will skip gracefully.
  SELECT id INTO test_user_id FROM auth.users WHERE email = 'test@nikefa.net';
  SELECT id INTO admin_user_id FROM auth.users WHERE email = 'admin@nikefa.net';

  IF test_user_id IS NULL OR admin_user_id IS NULL THEN
    RAISE NOTICE '⚠️ Test users not found. Create auth users with emails test@nikefa.net and admin@nikefa.net first.';
    RETURN;
  END IF;

  SELECT id INTO stethoscope_id FROM products WHERE sku = 'MED-STET-001';
  SELECT id INTO gloves_id FROM products WHERE sku = 'MED-GLOV-002';
  SELECT id INTO syringes_id FROM products WHERE sku = 'MED-SYRN-003';

  IF stethoscope_id IS NULL OR gloves_id IS NULL OR syringes_id IS NULL THEN
    RAISE NOTICE '⚠️ Products not found. Run migration 001 first.';
    RETURN;
  END IF;

  INSERT INTO orders (id, user_id, status, total_amount, payment_method, shipping_address)
  VALUES (gen_random_uuid(), test_user_id, 'delivered', 155.00, 'cod',
    '{"name": "أحمد محمد", "phone": "+23566123456", "address": "شارع الحرية، رقم 45", "city": "نجامينا", "notes": "يرجى الاتصال قبل التوصيل"}'::jsonb
  ) RETURNING id INTO order1_id;

  INSERT INTO orders (id, user_id, status, total_amount, payment_method, shipping_address)
  VALUES (gen_random_uuid(), test_user_id, 'pending', 23.50, 'cod',
    '{"name": "أحمد محمد", "phone": "+23566123456", "address": "شارع الحرية، رقم 45", "city": "نجامينا", "notes": ""}'::jsonb
  ) RETURNING id INTO order2_id;

  INSERT INTO order_items (order_id, product_id, quantity, unit_price, variant_selection) VALUES
    (order1_id, stethoscope_id, 1, 125.00, NULL),
    (order1_id, gloves_id, 1, 15.00, NULL);

  INSERT INTO order_items (order_id, product_id, quantity, unit_price, variant_selection) VALUES
    (order2_id, gloves_id, 1, 15.00, NULL),
    (order2_id, syringes_id, 1, 8.50, NULL);

  INSERT INTO cart_items (user_id, product_id, quantity, variant_selection)
  VALUES
    (test_user_id, stethoscope_id, 2, NULL),
    (test_user_id, syringes_id, 3, '{"packaging": "box-50"}'::jsonb)
  ON CONFLICT (user_id, product_id, COALESCE(variant_selection::text, ''))
    DO UPDATE SET quantity = EXCLUDED.quantity, updated_at = NOW();

  UPDATE profiles SET role = 'admin' WHERE id = admin_user_id;
END $$; 