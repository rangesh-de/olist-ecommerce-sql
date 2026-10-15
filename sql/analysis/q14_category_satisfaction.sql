-- Q14. Which big categories have the unhappiest customers, and is it the product or the delivery?
-- Concepts: separating causes by comparing on-time vs late orders within each category
WITH order_category AS (
    SELECT DISTINCT
        oi.order_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
    FROM olist.order_items oi
    JOIN olist.products p                  ON p.product_id = oi.product_id
    LEFT JOIN olist.category_translation t ON t.product_category_name = p.product_category_name
)
SELECT
    oc.category,
    COUNT(*)                                                               AS reviewed_orders,
    ROUND(AVG(v.review_score), 2)                                          AS avg_review,
    ROUND(AVG(v.review_score) FILTER (WHERE NOT v.is_late), 2)             AS avg_review_on_time,
    ROUND(100.0 * COUNT(*) FILTER (WHERE v.review_score = 1) / COUNT(*), 1) AS one_star_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE v.is_late) / COUNT(*), 1)         AS late_pct
FROM order_category oc
JOIN olist.v_orders v ON v.order_id = oc.order_id
WHERE v.is_delivered
  AND v.review_score IS NOT NULL
GROUP BY oc.category
HAVING COUNT(*) >= 500
ORDER BY avg_review_on_time ASC
LIMIT 15;
