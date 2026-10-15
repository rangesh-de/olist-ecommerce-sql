-- Q13. Where is time lost between purchase and delivery?
-- Concepts: timestamp arithmetic, splitting a process into stages
WITH stages AS (
    SELECT
        DATE_TRUNC('quarter', order_purchase_timestamp)::DATE                                AS quarter,
        EXTRACT(EPOCH FROM order_approved_at - order_purchase_timestamp) / 86400.0           AS approval_days,
        EXTRACT(EPOCH FROM order_delivered_carrier_date - order_approved_at) / 86400.0       AS seller_handling_days,
        EXTRACT(EPOCH FROM order_delivered_customer_date - order_delivered_carrier_date) / 86400.0 AS carrier_transit_days,
        EXTRACT(EPOCH FROM order_estimated_delivery_date - order_purchase_timestamp) / 86400.0 AS promised_days
    FROM olist.orders
    WHERE order_status = 'delivered'
      AND order_approved_at IS NOT NULL
      AND order_delivered_carrier_date IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
      AND order_delivered_carrier_date >= order_approved_at          -- drop impossible timestamps
      AND order_delivered_customer_date >= order_delivered_carrier_date
      AND order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp <  '2018-09-01'
)
SELECT
    quarter,
    COUNT(*)                                                          AS orders,
    ROUND(AVG(approval_days)::NUMERIC, 2)                             AS avg_approval_days,
    ROUND(AVG(seller_handling_days)::NUMERIC, 2)                      AS avg_seller_handling_days,
    ROUND(AVG(carrier_transit_days)::NUMERIC, 2)                      AS avg_carrier_transit_days,
    ROUND(AVG(approval_days + seller_handling_days + carrier_transit_days)::NUMERIC, 2) AS avg_total_days,
    ROUND(AVG(promised_days)::NUMERIC, 2)                             AS avg_promised_days
FROM stages
GROUP BY quarter
ORDER BY quarter;
