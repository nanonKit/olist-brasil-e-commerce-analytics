-- Question: what is one row of order_items, and are price / freight / keys clean?

-- Grain: is (order_id, order_item_id) unique?  expect n_rows = n_distinct_keys
SELECT
    COUNT(*)                                       AS n_rows,
    COUNT(DISTINCT (order_id, order_item_id))      AS n_distinct_keys,
    COUNT(DISTINCT order_id)                       AS n_orders_with_items
FROM raw.order_items;


-- Items per order: distribution
WITH items_per_order AS (
    SELECT order_id, COUNT(*) AS n_items
    FROM raw.order_items
    GROUP BY order_id
)
SELECT
    n_items,
    COUNT(*)                                            AS n_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_orders
FROM items_per_order
GROUP BY n_items
ORDER BY n_items;


-- order_item_id is a 1..n sequence per order (no gaps)?  expect 0
SELECT COUNT(*) AS orders_with_gaps
FROM (
    SELECT order_id,
           MAX(CAST(order_item_id AS INTEGER)) AS max_seq,
           COUNT(*)                            AS n_items
    FROM raw.order_items
    GROUP BY order_id
) AS t
WHERE max_seq <> n_items;


-- Numeric sanity: price and freight_value
SELECT
    COUNT(*) FILTER (WHERE TRY_CAST(price AS DECIMAL(18,2)) IS NULL)          AS price_not_numeric,     -- แปลงเป็นตัวเลขไม่ได้
    COUNT(*) FILTER (WHERE TRY_CAST(freight_value AS DECIMAL(18,2)) IS NULL)  AS freight_not_numeric,
    COUNT(*) FILTER (WHERE CAST(price AS DECIMAL(18,2)) <= 0)                 AS price_le_0,            -- ราคา 0 หรือติดลบ
    COUNT(*) FILTER (WHERE CAST(freight_value AS DECIMAL(18,2)) = 0)          AS freight_eq_0,          -- ส่งฟรี
    MIN(CAST(price AS DECIMAL(18,2)))                                         AS min_price,
    MEDIAN(CAST(price AS DECIMAL(18,2)))                                      AS median_price,
    MAX(CAST(price AS DECIMAL(18,2)))                                         AS max_price
FROM raw.order_items;


-- Referential integrity with orders (both directions)
SELECT
    (SELECT COUNT(DISTINCT oi.order_id) FROM raw.order_items oi
     WHERE NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.order_id = oi.order_id))
        AS items_without_order,
    (SELECT COUNT(*) FROM raw.orders o
     WHERE NOT EXISTS (SELECT 1 FROM raw.order_items oi WHERE oi.order_id = o.order_id))
        AS orders_without_items;


-- Orders without items: which status?  (explains E)
SELECT o.order_status, COUNT(*) AS n_orders
FROM raw.orders o
WHERE NOT EXISTS (SELECT 1 FROM raw.order_items oi WHERE oi.order_id = o.order_id)
GROUP BY o.order_status
ORDER BY n_orders DESC;