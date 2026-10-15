-- =====================================================================
-- Olist E-commerce: relational schema (PostgreSQL)
-- Column order matches the Kaggle CSVs so they can be bulk-loaded with COPY.
-- A few source column names are misspelled ("lenght"); they are fixed here.
-- =====================================================================

DROP SCHEMA IF EXISTS olist CASCADE;
CREATE SCHEMA olist;
SET search_path TO olist;

-- Lookup: Portuguese category name -> English
CREATE TABLE category_translation (
    product_category_name          TEXT PRIMARY KEY,
    product_category_name_english  TEXT NOT NULL
);

-- One row per customer_id. NOTE: customer_id is created per ORDER.
-- The real person is customer_unique_id (needed for repeat-customer analysis).
CREATE TABLE customers (
    customer_id               TEXT PRIMARY KEY,
    customer_unique_id        TEXT NOT NULL,
    customer_zip_code_prefix  TEXT,
    customer_city             TEXT,
    customer_state            CHAR(2)
);

CREATE TABLE sellers (
    seller_id               TEXT PRIMARY KEY,
    seller_zip_code_prefix  TEXT,
    seller_city             TEXT,
    seller_state            CHAR(2)
);

-- Not FK'd to category_translation: a few categories have no translation.
CREATE TABLE products (
    product_id                  TEXT PRIMARY KEY,
    product_category_name       TEXT,
    product_name_length         NUMERIC,
    product_description_length  NUMERIC,
    product_photos_qty          NUMERIC,
    product_weight_g            NUMERIC,
    product_length_cm           NUMERIC,
    product_height_cm           NUMERIC,
    product_width_cm            NUMERIC
);

CREATE TABLE orders (
    order_id                       TEXT PRIMARY KEY,
    customer_id                    TEXT NOT NULL REFERENCES customers (customer_id),
    order_status                   TEXT NOT NULL,
    order_purchase_timestamp       TIMESTAMP NOT NULL,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

-- One row per item in an order (order_item_id = 1, 2, 3 ...)
CREATE TABLE order_items (
    order_id             TEXT NOT NULL REFERENCES orders (order_id),
    order_item_id        INTEGER NOT NULL,
    product_id           TEXT NOT NULL REFERENCES products (product_id),
    seller_id            TEXT NOT NULL REFERENCES sellers (seller_id),
    shipping_limit_date  TIMESTAMP,
    price                NUMERIC(10, 2) NOT NULL,
    freight_value        NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- An order can be paid in several parts (vouchers + card, etc.)
CREATE TABLE order_payments (
    order_id              TEXT NOT NULL REFERENCES orders (order_id),
    payment_sequential    INTEGER NOT NULL,
    payment_type          TEXT NOT NULL,
    payment_installments  INTEGER,
    payment_value         NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id is NOT unique in the source data, so the key is (review_id, order_id).
CREATE TABLE order_reviews (
    review_id                TEXT NOT NULL,
    order_id                 TEXT NOT NULL REFERENCES orders (order_id),
    review_score             SMALLINT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    review_creation_date     TIMESTAMP,
    review_answer_timestamp  TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

-- Many rows per zip prefix (no natural key), kept as a raw reference table.
CREATE TABLE geolocation (
    geolocation_zip_code_prefix  TEXT,
    geolocation_lat              NUMERIC,
    geolocation_lng              NUMERIC,
    geolocation_city             TEXT,
    geolocation_state            CHAR(2)
);

-- Indexes on the columns used most in joins and filters
CREATE INDEX idx_customers_unique   ON customers (customer_unique_id);
CREATE INDEX idx_orders_customer    ON orders (customer_id);
CREATE INDEX idx_orders_purchase    ON orders (order_purchase_timestamp);
CREATE INDEX idx_items_product      ON order_items (product_id);
CREATE INDEX idx_items_seller       ON order_items (seller_id);
CREATE INDEX idx_reviews_order      ON order_reviews (order_id);
CREATE INDEX idx_geo_zip            ON geolocation (geolocation_zip_code_prefix);
