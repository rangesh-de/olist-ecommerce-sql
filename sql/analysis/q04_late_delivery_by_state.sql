-- Q4. Which states get the most late deliveries, and how long do they wait?
-- Concepts: boolean aggregation, HAVING for minimum sample size
SELECT
    customer_state,
    COUNT(*)                                                    AS delivered_orders,
    ROUND(AVG(delivery_days)::NUMERIC, 1)                       AS avg_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 1) AS late_pct
FROM olist.v_orders
WHERE is_delivered
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY late_pct DESC;
