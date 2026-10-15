-- Q6. Which product categories drive revenue, and what share of the total does each hold?
-- Concepts: multi-table join, COALESCE, RANK and SUM() OVER () for share of total
WITH category_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
        COUNT(DISTINCT oi.order_id)  AS orders,
        SUM(oi.price)                AS revenue
    FROM olist.order_items oi
    JOIN olist.orders o                     ON o.order_id = oi.order_id
    JOIN olist.products p                   ON p.product_id = oi.product_id
    LEFT JOIN olist.category_translation t  ON t.product_category_name = p.product_category_name
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT
    RANK() OVER (ORDER BY revenue DESC)                          AS rank,
    category,
    orders,
    ROUND(revenue, 2)                                            AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)             AS share_pct,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2)                             AS cumulative_share_pct
FROM category_revenue
ORDER BY revenue DESC
LIMIT 20;
