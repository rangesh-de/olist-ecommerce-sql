-- Q12. Segment customers by Recency, Frequency and Monetary value (RFM).
-- Concepts: NTILE scoring, CASE-based segment rules, a fixed "as of" date
WITH base AS (
    SELECT
        customer_unique_id,
        MAX(order_purchase_timestamp) AS last_order,
        COUNT(*)                      AS frequency,
        SUM(order_value)              AS monetary
    FROM olist.v_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND order_value IS NOT NULL
    GROUP BY customer_unique_id
),
snapshot AS (
    SELECT MAX(last_order) + INTERVAL '1 day' AS as_of FROM base
),
scored AS (
    SELECT
        b.*,
        EXTRACT(DAY FROM s.as_of - b.last_order)::INT       AS recency_days,
        NTILE(5) OVER (ORDER BY b.last_order ASC)           AS r_score,   -- 5 = most recent
        CASE WHEN b.frequency >= 3 THEN 5
             WHEN b.frequency = 2  THEN 4
             ELSE 1 END                                     AS f_score,   -- most buy once, so NTILE would be meaningless
        NTILE(5) OVER (ORDER BY b.monetary ASC)             AS m_score
    FROM base b CROSS JOIN snapshot s
),
segmented AS (
    SELECT *,
        CASE
            WHEN f_score >= 4 AND r_score >= 4                 THEN 'Loyal - active'
            WHEN f_score >= 4                                  THEN 'Loyal - at risk'
            WHEN r_score >= 4 AND m_score >= 4                 THEN 'New big spender'
            WHEN r_score >= 4                                  THEN 'New customer'
            WHEN r_score <= 2 AND m_score >= 4                 THEN 'Lost big spender'
            WHEN r_score <= 2                                  THEN 'Lost'
            ELSE 'Needs attention'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                              AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_customers,
    ROUND(AVG(recency_days))                              AS avg_recency_days,
    ROUND(AVG(frequency), 2)                              AS avg_orders,
    ROUND(AVG(monetary), 2)                               AS avg_spend,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue
FROM segmented
GROUP BY segment
ORDER BY pct_revenue DESC;
