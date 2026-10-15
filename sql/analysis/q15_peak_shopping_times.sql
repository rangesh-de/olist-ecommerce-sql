-- Q15. When do customers shop? (useful for timing campaigns and support staffing)
-- Concepts: EXTRACT, TO_CHAR, pivoting with FILTER
SELECT
    EXTRACT(ISODOW FROM order_purchase_timestamp)::INT            AS day_num,
    TO_CHAR(order_purchase_timestamp, 'Dy')                       AS day,
    COUNT(*)                                                      AS orders,
    COUNT(*) FILTER (WHERE EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 5)   AS night_0_5,
    COUNT(*) FILTER (WHERE EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 6 AND 11)  AS morning_6_11,
    COUNT(*) FILTER (WHERE EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 12 AND 17) AS afternoon_12_17,
    COUNT(*) FILTER (WHERE EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 18 AND 23) AS evening_18_23,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)            AS share_pct
FROM olist.orders
GROUP BY 1, 2
ORDER BY 1;
