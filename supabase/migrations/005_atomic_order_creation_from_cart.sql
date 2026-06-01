-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 005 - Atomic Order Creation from Cart
-- Description: Creates a single atomic PostgreSQL function that
--              reads cart_items, validates stock, creates the
--              order + order_items, decrements stock, and clears
--              the cart — all in one transaction.
-- Fixes non-atomic order creation where partial writes could
-- occur if stock decrement failed after order/items were inserted.
-- Idempotent: Yes (safe to run multiple times)
-- ============================================================

CREATE OR REPLACE FUNCTION create_order_atomic(
  p_user_id UUID,
  p_shipping_address JSONB,
  p_notes TEXT DEFAULT ''
)
RETURNS JSONB AS $$
DECLARE
  v_order_id UUID;
  v_total_amount NUMERIC(12, 2) := 0;
  v_cart_item RECORD;
  v_product_id UUID;
  v_quantity INTEGER;
  v_unit_price NUMERIC(12, 2);
  v_variant_selection JSONB;
  v_stock_ok BOOLEAN;
  v_is_active BOOLEAN;
  v_order_result JSONB;
  v_agg_product_id UUID;
  v_agg_quantity INTEGER;
  v_cart_items_count INTEGER;
BEGIN
  -- Phase 0: Verify the user has cart items
  SELECT COUNT(*) INTO v_cart_items_count
  FROM cart_items
  WHERE user_id = p_user_id;

  IF v_cart_items_count = 0 THEN
    RAISE EXCEPTION 'order_creation_failed: cart is empty';
  END IF;

  -- Phase 1: Calculate total amount from cart (no locking needed)
  FOR v_cart_item IN
    SELECT ci.product_id, ci.quantity, ci.variant_selection, p.base_price
    FROM cart_items ci
    JOIN products p ON p.id = ci.product_id
    WHERE ci.user_id = p_user_id
  LOOP
    v_total_amount := v_total_amount + (v_cart_item.base_price * v_cart_item.quantity);
  END LOOP;

  -- Phase 2: Aggregate quantities per product to handle duplicate cart entries,
  --           then validate stock with FOR UPDATE row locking.
  FOR v_agg_product_id, v_agg_quantity IN
    SELECT ci.product_id, SUM(ci.quantity) AS total_qty
    FROM cart_items ci
    WHERE ci.user_id = p_user_id
    GROUP BY ci.product_id
    ORDER BY ci.product_id
  LOOP
    SELECT stock_quantity >= v_agg_quantity, is_active INTO v_stock_ok, v_is_active
    FROM products
    WHERE id = v_agg_product_id
    FOR UPDATE;

    IF NOT FOUND OR NOT v_stock_ok OR NOT v_is_active THEN
      RAISE EXCEPTION 'order_creation_failed: insufficient stock or inactive product %', v_agg_product_id;
    END IF;
  END LOOP;

  -- Phase 3: All checks passed — perform writes atomically

  -- 3a. Insert the order
  INSERT INTO orders (user_id, status, total_amount, payment_method, shipping_address)
  VALUES (p_user_id, 'pending', v_total_amount, 'cod', p_shipping_address)
  RETURNING id INTO v_order_id;

  -- 3b. Insert order items from cart
  FOR v_cart_item IN
    SELECT ci.product_id, ci.quantity, ci.variant_selection, p.base_price
    FROM cart_items ci
    JOIN products p ON p.id = ci.product_id
    WHERE ci.user_id = p_user_id
  LOOP
    INSERT INTO order_items (order_id, product_id, quantity, unit_price, variant_selection)
    VALUES (v_order_id, v_cart_item.product_id, v_cart_item.quantity, v_cart_item.base_price, v_cart_item.variant_selection);
  END LOOP;

  -- 3c. Decrement stock per unique product (rows already locked in Phase 2)
  FOR v_agg_product_id, v_agg_quantity IN
    SELECT ci.product_id, SUM(ci.quantity) AS total_qty
    FROM cart_items ci
    WHERE ci.user_id = p_user_id
    GROUP BY ci.product_id
    ORDER BY ci.product_id
  LOOP
    UPDATE products
    SET stock_quantity = stock_quantity - v_agg_quantity
    WHERE id = v_agg_product_id;
  END LOOP;

  -- 3d. Clear the user's cart
  DELETE FROM cart_items WHERE user_id = p_user_id;

  -- Phase 4: Return the complete order as JSONB with embedded items
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
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', oi.id,
          'order_id', oi.order_id,
          'product_id', oi.product_id,
          'quantity', oi.quantity,
          'unit_price', oi.unit_price,
          'variant_selection', oi.variant_selection
        )
      ), '[]'::jsonb)
      FROM order_items oi
      WHERE oi.order_id = o.id
    )
  ) INTO v_order_result
  FROM orders o
  WHERE o.id = v_order_id;

  RETURN v_order_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Explicit GRANT EXECUTE for authenticated users
GRANT EXECUTE ON FUNCTION create_order_atomic(UUID, JSONB, TEXT) TO authenticated;

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
