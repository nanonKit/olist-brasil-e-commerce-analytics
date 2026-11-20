-- Question: what is one row of order_payments, and does paid = items + freight?

-- Grain: is (order_id, payment_sequential) unique?
SELECT
    COUNT(*)                                          AS n_rows,
    COUNT(DISTINCT (order_id, payment_sequential))    AS n_distinct_keys,
    COUNT(DISTINCT order_id)                          AS n_orders_with_payment
FROM raw.order_payments;


-- Payment types: share of rows and value
SELECT
    payment_type,
    COUNT(*)                                                         AS n_rows,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)               AS pct_rows,
    SUM(CAST(payment_value AS DECIMAL(18,2)))                        AS total_value,
    ROUND(AVG(CAST(payment_value AS DECIMAL(18,2))), 2)              AS avg_value
FROM raw.order_payments
GROUP BY payment_type
ORDER BY n_rows DESC;


-- Payments per order: distribution
WITH pay_per_order AS (
    SELECT order_id, COUNT(*) AS n_payments
    FROM raw.order_payments
    GROUP BY order_id
)
SELECT
    n_payments,
    COUNT(*)                                            AS n_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_orders
FROM pay_per_order
GROUP BY n_payments
ORDER BY n_payments;


-- Numeric sanity: payment_value and installments
SELECT
    COUNT(*) FILTER (WHERE TRY_CAST(payment_value AS DECIMAL(18,2)) IS NULL)  AS value_not_numeric,         -- ไม่ใช่ตัวเลข
    COUNT(*) FILTER (WHERE CAST(payment_value AS DECIMAL(18,2)) = 0)          AS value_eq_0,                -- จ่าย 0
    COUNT(*) FILTER (WHERE CAST(payment_installments AS INTEGER) = 0)         AS installments_eq_0,         -- ผ่อน 0 งวด
    MAX(CAST(payment_installments AS INTEGER))                                AS max_installments,
    MAX(CAST(payment_value AS DECIMAL(18,2)))                                 AS max_value
FROM raw.order_payments;


-- Rows behind D: zero values and 'not_defined' type
SELECT payment_type, payment_installments, payment_value, COUNT(*) AS n_rows
FROM raw.order_payments
WHERE CAST(payment_value AS DECIMAL(18,2)) = 0
   OR CAST(payment_installments AS INTEGER) = 0
   OR payment_type = 'not_defined'
GROUP BY ALL
ORDER BY n_rows DESC;


-- Reconciliation: paid vs items + freight (aggregate to order grain FIRST → no fan-out)
WITH items AS (             -- ยุบ items เหลือ 1 แถวต่อ order
    SELECT order_id,
           SUM(CAST(price AS DECIMAL(18,2)) + CAST(freight_value AS DECIMAL(18,2))) AS items_total
    FROM raw.order_items
    GROUP BY order_id
),
pay AS (                    -- ยุบ payments เหลือ 1 แถวต่อ order
    SELECT order_id, SUM(CAST(payment_value AS DECIMAL(18,2))) AS paid_total
    FROM raw.order_payments
    GROUP BY order_id
),
cmp AS (                    -- JOIN ที่ grain เดียวกัน (1:1) แล้วหาผลต่าง
    SELECT i.order_id, i.items_total, p.paid_total, p.paid_total - i.items_total AS diff
    FROM items i
    JOIN pay p USING (order_id)
)
SELECT
    COUNT(*)                                          AS n_orders_compared,
    COUNT(*) FILTER (WHERE ABS(diff) <= 0.01)         AS n_match,                           -- ตรง (ยอมคลาดไม่เกิน 1 เซ็นต์)
    COUNT(*) FILTER (WHERE diff >  0.01)              AS n_paid_more,                       -- จ่ายมากกว่า
    COUNT(*) FILTER (WHERE diff < -0.01)              AS n_paid_less,                       -- จ่ายน้อยกว่า
    ROUND(100.0 * COUNT(*) FILTER (WHERE ABS(diff) <= 0.01) / COUNT(*), 2) AS pct_match,
    SUM(items_total)                                  AS sum_items_total,
    SUM(paid_total)                                   AS sum_paid_total
FROM cmp;


-- Referential integrity: orders without payment / payments without order
SELECT
    (SELECT COUNT(*) FROM raw.orders o
     WHERE NOT EXISTS (SELECT 1 FROM raw.order_payments p WHERE p.order_id = o.order_id))
        AS orders_without_payment,
    (SELECT COUNT(DISTINCT p.order_id) FROM raw.order_payments p
     WHERE NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.order_id = p.order_id))
        AS payments_without_order;