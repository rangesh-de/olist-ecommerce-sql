-- Q11. Where does shipping cost eat the largest share of the basket?
-- Concepts: ratio metrics, ratio of sums vs average of ratios
SELECT
    customer_state,
    COUNT(*)                                             AS orders,
    ROUND(AVG(items_value), 2)                           AS avg_items_value,
    ROUND(AVG(freight_value), 2)                         AS avg_freight,
    ROUND(100.0 * SUM(freight_value) / SUM(items_value), 1) AS freight_pct_of_items
FROM olist.v_orders
WHERE order_status NOT IN ('canceled', 'unavailable')
  AND items_value > 0
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY freight_pct_of_items DESC;
