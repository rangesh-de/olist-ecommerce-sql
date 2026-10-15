-- Q2. What share of customers come back for a second order?
-- Concepts: customer_unique_id vs customer_id, FILTER clause
-- customer_id changes with every order, so counting it would show 0% repeat buyers.
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(*) AS n_orders
    FROM olist.v_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*)                                          AS customers,
    COUNT(*) FILTER (WHERE n_orders > 1)              AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE n_orders > 1)
          / COUNT(*), 2)                              AS repeat_rate_pct,
    ROUND(AVG(n_orders), 3)                           AS avg_orders_per_customer,
    MAX(n_orders)                                     AS max_orders_one_customer
FROM per_customer;
