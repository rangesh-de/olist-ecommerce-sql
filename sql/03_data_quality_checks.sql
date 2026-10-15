-- =====================================================================
-- Data quality checks: run after loading, before trusting any analysis.
-- Each row is one check; look at the "result" column.
-- =====================================================================
SET search_path TO olist;

SELECT 'orders with no items' AS check_name,
       COUNT(*)::TEXT AS result
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM order_items i WHERE i.order_id = o.order_id)

UNION ALL
SELECT 'orders with no payment',
       COUNT(*)::TEXT
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM order_payments p WHERE p.order_id = o.order_id)

UNION ALL
SELECT 'orders with more than one review',
       COUNT(*)::TEXT
FROM (SELECT order_id FROM order_reviews GROUP BY order_id HAVING COUNT(*) > 1) x

UNION ALL
SELECT 'products with untranslated category',
       COUNT(*)::TEXT
FROM products p
LEFT JOIN category_translation t USING (product_category_name)
WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL

UNION ALL
SELECT 'delivered orders missing delivery date',
       COUNT(*)::TEXT
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT DISTINCT FROM NULL

UNION ALL
SELECT 'orders delivered to carrier before approval',
       COUNT(*)::TEXT
FROM orders
WHERE order_delivered_carrier_date < order_approved_at

UNION ALL
SELECT 'customers (customer_id) vs real people (customer_unique_id)',
       COUNT(*) || ' vs ' || COUNT(DISTINCT customer_unique_id)
FROM customers

UNION ALL
-- Payments should roughly equal items + freight. Small gaps are expected (vouchers, rounding).
SELECT 'orders where payments differ from items + freight by > 1.00',
       COUNT(*)::TEXT
FROM v_order_value v
JOIN (SELECT order_id, SUM(payment_value) AS paid FROM order_payments GROUP BY order_id) p
  USING (order_id)
WHERE ABS(p.paid - v.order_value) > 1.00;
