-- =====================================================================
-- Reusable views: define business logic ONCE so every query agrees.
-- =====================================================================
SET search_path TO olist;

-- Order value per order (items + freight)
CREATE OR REPLACE VIEW v_order_value AS
SELECT
    order_id,
    COUNT(*)                         AS n_items,
    SUM(price)                       AS items_value,
    SUM(freight_value)               AS freight_value,
    SUM(price) + SUM(freight_value)  AS order_value
FROM order_items
GROUP BY order_id;

-- One review score per order (some orders have more than one review: keep the latest)
CREATE OR REPLACE VIEW v_order_review AS
SELECT DISTINCT ON (order_id)
    order_id,
    review_score
FROM order_reviews
ORDER BY order_id, review_creation_date DESC NULLS LAST;

-- The main analysis view: one row per order with everything most questions need
CREATE OR REPLACE VIEW v_orders AS
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE   AS purchase_month,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    v.n_items,
    v.items_value,
    v.freight_value,
    v.order_value,
    r.review_score,
    (o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL)    AS is_delivered,
    (o.order_delivered_customer_date::DATE
        > o.order_estimated_delivery_date::DATE)            AS is_late,
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date
        - o.order_purchase_timestamp)) / 86400.0            AS delivery_days
FROM orders o
JOIN customers c          ON c.customer_id = o.customer_id
LEFT JOIN v_order_value v ON v.order_id    = o.order_id
LEFT JOIN v_order_review r ON r.order_id   = o.order_id;
