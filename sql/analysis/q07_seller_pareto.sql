-- Q7. Is revenue concentrated in a few sellers? (80/20 check)
-- Concepts: NTILE to split sellers into deciles
WITH seller_revenue AS (
    SELECT oi.seller_id, SUM(oi.price) AS revenue
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.seller_id
),
ranked AS (
    SELECT seller_id, revenue, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM seller_revenue
)
SELECT
    decile,
    COUNT(*)                                            AS sellers,
    ROUND(SUM(revenue), 2)                              AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS share_pct,
    ROUND(100.0 * SUM(SUM(revenue)) OVER (ORDER BY decile)
          / SUM(SUM(revenue)) OVER (), 2)               AS cumulative_share_pct
FROM ranked
GROUP BY decile
ORDER BY decile;
