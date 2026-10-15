-- Q5. How much does a late delivery hurt the customer's review score?
-- Concepts: CASE bucketing, comparing groups
SELECT
    CASE
        WHEN NOT is_late THEN '1. On time or early'
        WHEN order_delivered_customer_date::DATE - order_estimated_delivery_date::DATE <= 3
             THEN '2. Late by 1-3 days'
        WHEN order_delivered_customer_date::DATE - order_estimated_delivery_date::DATE <= 7
             THEN '3. Late by 4-7 days'
        ELSE '4. Late by 8+ days'
    END                                                              AS delivery_bucket,
    COUNT(*)                                                         AS orders,
    ROUND(AVG(review_score), 2)                                      AS avg_review,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 1) AS pct_1_or_2_stars
FROM olist.v_orders
WHERE is_delivered
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
