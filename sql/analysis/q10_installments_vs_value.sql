-- Q10. Do customers who split payments into installments buy more expensive baskets?
-- Concepts: CASE bucketing on a numeric column, sort by a custom order
SELECT
    CASE
        WHEN payment_installments <= 1  THEN '1 (paid in full)'
        WHEN payment_installments <= 3  THEN '2-3'
        WHEN payment_installments <= 6  THEN '4-6'
        WHEN payment_installments <= 10 THEN '7-10'
        ELSE '11+'
    END                                  AS installments,
    COUNT(*)                             AS orders,
    ROUND(AVG(payment_value), 2)         AS avg_payment_value,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY payment_value)::NUMERIC, 2) AS median_payment_value
FROM olist.order_payments
WHERE payment_type = 'credit_card'
GROUP BY 1
ORDER BY MIN(payment_installments);
