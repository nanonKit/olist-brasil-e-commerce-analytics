-- which column identifies a real customer — customer_id or customer_unique_id?

-- Key cardinality: rows vs distinct values of each key
SELECT
    COUNT(*)                           AS n_rows,
    COUNT(DISTINCT customer_id)        AS n_customer_id,
    COUNT(DISTINCT customer_unique_id) AS n_customer_unique_id
FROM raw.customers;


-- Distribution: how many customer_ids does each real customer have?
WITH ids_per_person AS (            -- ชั้น 1: 1 row ต่อ 1 คน
    SELECT
        customer_unique_id,
        COUNT(DISTINCT customer_id) AS ids_per_customer
    FROM raw.customers
    GROUP BY customer_unique_id
)
SELECT
    ids_per_customer,               -- ชั้น 2: จัดกลุ่มคนตามจำนวน id
    COUNT(*)                                             AS n_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)   AS pct_customers
FROM ids_per_person
GROUP BY ids_per_customer
ORDER BY ids_per_customer;


-- Is customer_id 1:1 with orders?
SELECT
    MAX(n_orders)                         AS max_orders_per_customer_id,
    COUNT(*) FILTER (WHERE n_orders > 1)  AS ids_with_multiple_orders
FROM (
    SELECT customer_id, COUNT(*) AS n_orders
    FROM raw.orders
    GROUP BY customer_id
) AS t;


-- Referential integrity: orphans in both directions (expect 0 / 0)
SELECT
    (SELECT COUNT(*) FROM raw.orders o
     WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))
        AS orders_without_customer,
    (SELECT COUNT(*) FROM raw.customers c
     WHERE NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.customer_id = c.customer_id))
        AS customers_without_order;


-- Repeat rate measured on the right key
WITH orders_per_person AS (
    SELECT c.customer_unique_id, COUNT(*) AS n_orders
    FROM raw.orders o
    JOIN raw.customers c USING (customer_id)
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                                     AS n_real_customers,
    COUNT(*) FILTER (WHERE n_orders > 1)                         AS n_repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE n_orders > 1) / COUNT(*), 2) AS repeat_rate_pct
FROM orders_per_person;


-- Sanity check on the heaviest customers: genuine repeat buying or duplicates?
SELECT
    c.customer_unique_id,
    COUNT(*)                                                   AS n_orders,
    COUNT(DISTINCT CAST(o.order_purchase_timestamp AS DATE))   AS n_purchase_days,
    MIN(o.order_purchase_timestamp)                            AS first_purchase,
    MAX(o.order_purchase_timestamp)                            AS last_purchase,
    COUNT(*) FILTER (WHERE o.order_status = 'delivered')       AS n_delivered
FROM raw.orders o
JOIN raw.customers c USING (customer_id)
GROUP BY c.customer_unique_id
ORDER BY n_orders DESC
LIMIT 10;
