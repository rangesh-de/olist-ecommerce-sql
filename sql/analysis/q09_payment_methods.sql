-- Q9. How do customers pay, and do payment methods differ in order value?
-- Concepts: aggregating at the right grain (payments can be split across methods)
WITH order_payment AS (
    SELECT order_id, payment_type, SUM(payment_value) AS paid, MAX(payment_installments) AS installments
    FROM olist.order_payments
    WHERE payment_type <> 'not_defined'
    GROUP BY order_id, payment_type
)
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                                        AS orders,
    ROUND(100.0 * COUNT(DISTINCT order_id)
          / SUM(COUNT(DISTINCT order_id)) OVER (), 1)               AS share_of_orders_pct,
    ROUND(SUM(paid), 2)                                             AS total_paid,
    ROUND(AVG(paid), 2)                                             AS avg_paid_per_order,
    ROUND(AVG(installments), 2)                                     AS avg_installments
FROM order_payment
GROUP BY payment_type
ORDER BY orders DESC;
