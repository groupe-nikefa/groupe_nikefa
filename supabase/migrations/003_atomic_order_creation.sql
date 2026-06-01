-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 003 - Atomic Order Creation
-- Description: Replaces client-side multi-step order creation
--              with a single atomic PostgreSQL function.
-- Fixes:
--   1. decrement_stock missing SECURITY DEFINER
--   2. Race condition in decrement_stock (no row locking)
--   3. Non-atomic order creation (partial writes on failure)
--   4. search_path hardening for SECURITY DEFINER
--   5. Explicit GRANT EXECUTE for authenticated role
--   6. Duplicate-product stock aggregation
-- Idempotent: Yes (safe to run multiple times)
-- ============================================================

-- -----------------------------------------------------------
-- 1. Fix decrement_stock: SECURITY DEFINER + row locking + search_path
-- -----------------------------------------------------------

CREATE OR REPLACE FUNCTION decrement_stock(product_uuid UUID, quantity_int INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
  current_stock INTEGER;
BEGIN
  SELECT stock_quantity INTO current_stock
  FROM products
  WHERE id = product_uuid
  FOR UPDATE;

  IF current_stock >= quantity_int THEN
    UPDATE products
    SET stock_quantity = stock_quantity - quantity_int
    WHERE id = product_uuid;
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- -----------------------------------------------------------
-- 2. Atomic order creation function
-- -----------------------------------------------------------

CREATE OR REPLACE FUNCTION create_order(
  p_user_id UUID,
  p_shipping_address JSONB,
  p_items JSONB
)
RETURNS JSONB AS $$
DECLARE
  v_order_id UUID;
  v_total_amount NUMERIC(12, 2) := 0;
  v_item_count INTEGER;
  v_product_id UUID;
  v_quantity INTEGER;
  v_unit_price NUMERIC(12, 2);
  v_variant_selection JSONB;
  v_stock_ok BOOLEAN;
  v_order_result JSONB;
  v_agg_product_id UUID;
  v_agg_quantity INTEGER;
BEGIN
  -- Validate input
  v_item_count := jsonb_array_length(p_items);
  IF v_item_count = 0 THEN
    RAISE EXCEPTION 'order_creation_failed: no items provided';
  END IF;

  -- Phase 1: Calculate total amount (no locking needed)
  FOR i IN 0 .. v_item_count - 1 LOOP
    v_quantity := (p_items->i->>'quantity')::INTEGER;
    v_unit_price := (p_items->i->>'unit_price')::NUMERIC(12, 2);
    v_total_amount := v_total_amount + (v_unit_price * v_quantity);
  END LOOP;

  -- Phase 2: Aggregate quantities per product to handle duplicates,
  --           then validate stock with FOR UPDATE locking.
  FOR v_agg_product_id, v_agg_quantity IN
    SELECT
      (elem->>'product_id')::UUID AS product_id,
      SUM((elem->>'quantity')::INTEGER) AS total_qty
    FROM jsonb_array_elements(p_items) AS elem
    GROUP BY (elem->>'product_id')::UUID
    ORDER BY product_id
  LOOP
    SELECT stock_quantity >= v_agg_quantity INTO v_stock_ok
    FROM products
    WHERE id = v_agg_product_id
    FOR UPDATE;

    IF NOT v_stock_ok THEN
      RAISE EXCEPTION 'order_creation_failed: insufficient stock for product %', v_agg_product_id;
    END IF;
  END LOOP;

  -- Phase 3: All checks passed — perform writes

  -- 3a. Insert the order
  INSERT INTO orders (user_id, status, total_amount, payment_method, shipping_address)
  VALUES (p_user_id, 'pending', v_total_amount, 'cod', p_shipping_address)
  RETURNING id INTO v_order_id;

  -- 3b. Insert order items
  FOR i IN 0 .. v_item_count - 1 LOOP
    v_product_id := (p_items->i->>'product_id')::UUID;
    v_quantity := (p_items->i->>'quantity')::INTEGER;
    v_unit_price := (p_items->i->>'unit_price')::NUMERIC(12, 2);
    v_variant_selection := p_items->i->'variant_selection';

    INSERT INTO order_items (order_id, product_id, quantity, unit_price, variant_selection)
    VALUES (v_order_id, v_product_id, v_quantity, v_unit_price, v_variant_selection);
  END LOOP;

  -- 3c. Decrement stock per unique product (already locked in Phase 2)
  FOR v_agg_product_id, v_agg_quantity IN
    SELECT
      (elem->>'product_id')::UUID AS product_id,
      SUM((elem->>'quantity')::INTEGER) AS total_qty
    FROM jsonb_array_elements(p_items) AS elem
    GROUP BY (elem->>'product_id')::UUID
    ORDER BY product_id
  LOOP
    UPDATE products
    SET stock_quantity = stock_quantity - v_agg_quantity
    WHERE id = v_agg_product_id;
  END LOOP;

  -- 3d. Clear the user's cart
  DELETE FROM cart_items WHERE user_id = p_user_id;

  -- Phase 4: Return the complete order as JSONB
  SELECT jsonb_build_object(
    'id', o.id,
    'user_id', o.user_id,
    'status', o.status,
    'total_amount', o.total_amount,
    'payment_method', o.payment_method,
    'shipping_address', o.shipping_address,
    'created_at', o.created_at,
    'updated_at', o.updated_at,
    'order_items', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', oi.id,
          'order_id', oi.order_id,
          'product_id', oi.product_id,
          'quantity', oi.quantity,
          'unit_price', oi.unit_price,
          'variant_selection', oi.variant_selection
        )
      )
      FROM order_items oi
      WHERE oi.order_id = o.id
    )
  ) INTO v_order_result
  FROM orders o
  WHERE o.id = v_order_id;

  RETURN v_order_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- -----------------------------------------------------------
-- 3. Explicit GRANT EXECUTE for authenticated users
-- -----------------------------------------------------------

GRANT EXECUTE ON FUNCTION create_order(UUID, JSONB, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_stock(UUID, INTEGER) TO authenticated;

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
