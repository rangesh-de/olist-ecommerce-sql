-- Q3. Of customers who first bought in a given month, what % bought again 1, 2, 3... months later?
-- Concepts: cohort analysis, MIN() OVER (PARTITION BY), AGE(), conditional aggregation
WITH orders_clean AS (
    SELECT customer_unique_id, purchase_month
    FROM olist.v_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
with_cohort AS (
    SELECT
        customer_unique_id,
        purchase_month,
        MIN(purchase_month) OVER (PARTITION BY customer_unique_id) AS cohort_month
    FROM orders_clean
),
with_offset AS (
    SELECT DISTINCT
        customer_unique_id,
        cohort_month,
        (EXTRACT(YEAR  FROM AGE(purchase_month, cohort_month)) * 12
       + EXTRACT(MONTH FROM AGE(purchase_month, cohort_month)))::INT AS month_number
    FROM with_cohort
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS customers
    FROM with_offset
    WHERE month_number = 0
    GROUP BY cohort_month
)
SELECT
    w.cohort_month,
    s.customers                                                                AS cohort_customers,
    ROUND(100.0 * COUNT(DISTINCT w.customer_unique_id) FILTER (WHERE month_number = 1) / s.customers, 2) AS m1_pct,
    ROUND(100.0 * COUNT(DISTINCT w.customer_unique_id) FILTER (WHERE month_number = 2) / s.customers, 2) AS m2_pct,
    ROUND(100.0 * COUNT(DISTINCT w.customer_unique_id) FILTER (WHERE month_number = 3) / s.customers, 2) AS m3_pct,
    ROUND(100.0 * COUNT(DISTINCT w.customer_unique_id) FILTER (WHERE month_number = 6) / s.customers, 2) AS m6_pct,
    ROUND(100.0 * COUNT(DISTINCT w.customer_unique_id) FILTER (WHERE month_number BETWEEN 1 AND 12) / s.customers, 2) AS any_within_12m_pct
FROM with_offset w
JOIN cohort_size s USING (cohort_month)
WHERE w.cohort_month BETWEEN '2017-01-01' AND '2018-06-01'
GROUP BY w.cohort_month, s.customers
ORDER BY w.cohort_month;
