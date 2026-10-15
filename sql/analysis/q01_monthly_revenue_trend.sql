-- Q1. How are revenue and order volume trending month over month?
-- Concepts: DATE_TRUNC, LAG window function, growth %
-- Only full months (Jan 2017 - Aug 2018); the edges of the dataset are incomplete.
WITH monthly AS (
    SELECT
        purchase_month,
        COUNT(*)                    AS orders,
        ROUND(SUM(order_value), 2)  AS revenue
    FROM olist.v_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND purchase_month BETWEEN '2017-01-01' AND '2018-08-01'
    GROUP BY purchase_month
)
SELECT
    purchase_month,
    orders,
    revenue,
    ROUND(revenue / orders, 2)                                   AS avg_order_value,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY purchase_month))
          / LAG(revenue) OVER (ORDER BY purchase_month), 1)      AS revenue_mom_growth_pct
FROM monthly
ORDER BY purchase_month;
