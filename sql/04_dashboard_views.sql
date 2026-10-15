-- =====================================================================
-- Dashboard-ready views, exported to CSV for Tableau Public
-- (Tableau Public reads files, not databases).
-- Two grains, joined in Tableau on order_id:
--   dash_orders       one row per order
--   dash_order_items  one row per item
-- =====================================================================
SET search_path TO olist;

CREATE OR REPLACE VIEW dash_state_names AS
SELECT * FROM (VALUES
    ('AC','Acre'), ('AL','Alagoas'), ('AP','Amapá'), ('AM','Amazonas'), ('BA','Bahia'),
    ('CE','Ceará'), ('DF','Distrito Federal'), ('ES','Espírito Santo'), ('GO','Goiás'),
    ('MA','Maranhão'), ('MT','Mato Grosso'), ('MS','Mato Grosso do Sul'), ('MG','Minas Gerais'),
    ('PA','Pará'), ('PB','Paraíba'), ('PR','Paraná'), ('PE','Pernambuco'), ('PI','Piauí'),
    ('RJ','Rio de Janeiro'), ('RN','Rio Grande do Norte'), ('RS','Rio Grande do Sul'),
    ('RO','Rondônia'), ('RR','Roraima'), ('SC','Santa Catarina'), ('SP','São Paulo'),
    ('SE','Sergipe'), ('TO','Tocantins')
) AS t (state_code, state_name);

CREATE OR REPLACE VIEW dash_orders AS
WITH main_payment AS (
    -- The payment method that covered most of the order's value
    SELECT DISTINCT ON (order_id)
        order_id,
        payment_type AS main_payment_type,
        payment_installments
    FROM order_payments
    ORDER BY order_id, payment_value DESC
),
sequenced AS (
    SELECT
        v.*,
        ROW_NUMBER() OVER (PARTITION BY v.customer_unique_id
                           ORDER BY v.order_purchase_timestamp) AS customer_order_number
    FROM v_orders v
    WHERE v.order_status NOT IN ('canceled', 'unavailable')
)
SELECT
    o.order_id,
    o.customer_unique_id,
    o.order_status,
    o.order_status NOT IN ('canceled', 'unavailable')                      AS is_valid_sale,
    o.order_purchase_timestamp::DATE                                        AS purchase_date,
    o.customer_state                                                        AS state_code,
    s.state_name,
    'Brazil'                                                                AS country,
    o.n_items,
    o.items_value,
    o.freight_value,
    o.order_value,
    o.review_score,
    o.is_delivered,
    o.is_late,
    ROUND(o.delivery_days::NUMERIC, 1)                                      AS delivery_days,
    CASE WHEN o.is_delivered
         THEN o.order_delivered_customer_date::DATE - o.order_estimated_delivery_date::DATE
    END                                                                     AS days_vs_estimate,
    CASE WHEN q.customer_order_number = 1 THEN 'New customer'
         WHEN q.customer_order_number > 1 THEN 'Repeat customer'
    END                                                                     AS customer_type,
    p.main_payment_type,
    p.payment_installments
FROM v_orders o
LEFT JOIN sequenced q        ON q.order_id = o.order_id
LEFT JOIN main_payment p     ON p.order_id = o.order_id
LEFT JOIN dash_state_names s ON s.state_code = o.customer_state;

CREATE OR REPLACE VIEW dash_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
    oi.seller_id,
    se.seller_state,
    oi.price,
    oi.freight_value
FROM order_items oi
JOIN products p                  ON p.product_id = oi.product_id
JOIN sellers se                  ON se.seller_id = oi.seller_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name;
