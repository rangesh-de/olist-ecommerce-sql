-- Q8. Which high-volume sellers deliver the worst experience?
-- Concepts: seller scorecard joining items, orders and reviews; ranking within a filter
WITH seller_orders AS (
    SELECT DISTINCT oi.seller_id, v.order_id, v.is_late, v.review_score
    FROM olist.order_items oi
    JOIN olist.v_orders v ON v.order_id = oi.order_id
    WHERE v.is_delivered
),
seller_revenue AS (
    SELECT oi.seller_id, SUM(oi.price) AS revenue
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.seller_id
)
SELECT
    so.seller_id,
    s.seller_state,
    COUNT(*)                                                      AS delivered_orders,
    ROUND(r.revenue, 2)                                           AS revenue,
    ROUND(AVG(so.review_score), 2)                                AS avg_review,
    ROUND(100.0 * COUNT(*) FILTER (WHERE so.is_late) / COUNT(*), 1) AS late_pct,
    RANK() OVER (ORDER BY AVG(so.review_score) ASC)               AS worst_review_rank
FROM seller_orders so
JOIN olist.sellers s   ON s.seller_id = so.seller_id
JOIN seller_revenue r  ON r.seller_id = so.seller_id
GROUP BY so.seller_id, s.seller_state, r.revenue
HAVING COUNT(*) >= 100
ORDER BY avg_review ASC
LIMIT 15;
