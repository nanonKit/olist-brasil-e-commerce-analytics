-- Question: are order statuses and the 5 timestamps complete and in a logical order?

-- Status distribution
SELECT
    order_status,
    COUNT(*)                                            AS n_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_orders
FROM raw.orders
GROUP BY order_status
ORDER BY n_orders DESC;


-- Missing timestamps by status (NULL or empty)
SELECT
    order_status,
    COUNT(*)                                                                    AS n_orders,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(order_approved_at), '') IS NULL)            AS no_approved,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(order_delivered_carrier_date), '') IS NULL) AS no_carrier,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(order_delivered_customer_date), '') IS NULL) AS no_delivered,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(order_estimated_delivery_date), '') IS NULL) AS no_estimated
FROM raw.orders
GROUP BY order_status
ORDER BY n_orders DESC;


-- Timestamp order: purchase <= approved <= carrier <= delivered  (count violations)
WITH t AS (
    SELECT
        order_id, order_status,
        TRY_CAST(order_purchase_timestamp      AS TIMESTAMP) AS purchased_at,
        TRY_CAST(order_approved_at             AS TIMESTAMP) AS approved_at,
        TRY_CAST(order_delivered_carrier_date  AS TIMESTAMP) AS carrier_at,
        TRY_CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
        TRY_CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_at
    FROM raw.orders
)
SELECT
    COUNT(*) FILTER (WHERE approved_at  < purchased_at)  AS approved_before_purchase,
    COUNT(*) FILTER (WHERE carrier_at   < purchased_at)  AS carrier_before_purchase,
    COUNT(*) FILTER (WHERE carrier_at   < approved_at)   AS carrier_before_approved,
    COUNT(*) FILTER (WHERE delivered_at < carrier_at)    AS delivered_before_carrier,
    COUNT(*) FILTER (WHERE delivered_at < purchased_at)  AS delivered_before_purchase,
    COUNT(*) FILTER (WHERE estimated_at < purchased_at)  AS estimated_before_purchase
FROM t;


-- Delivered orders: delivery days and late share (preview of the main KPI)
WITH t AS (
    SELECT
        TRY_CAST(order_purchase_timestamp      AS TIMESTAMP) AS purchased_at,
        TRY_CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
        TRY_CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_at
    FROM raw.orders
    WHERE order_status = 'delivered'
)
SELECT
    COUNT(*)                                                             AS n_delivered_with_date,
    ROUND(MEDIAN(date_diff('day', purchased_at, delivered_at)), 1)       AS median_delivery_days,           -- ใช้เวลากี่วัน
    MAX(date_diff('day', purchased_at, delivered_at))                    AS max_delivery_days,              -- ส่งช้ากว่าที่แจ้ง
    COUNT(*) FILTER (WHERE delivered_at::DATE > estimated_at::DATE)      AS n_late,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivered_at::DATE > estimated_at::DATE) / COUNT(*), 2) AS pct_late
FROM t
WHERE delivered_at IS NOT NULL;


-- Coverage: orders per month (spot partial / sparse months)
SELECT
    DATE_TRUNC('month', TRY_CAST(order_purchase_timestamp AS TIMESTAMP))::DATE AS purchase_month,
    COUNT(*)                                                                 AS n_orders
FROM raw.orders
GROUP BY ALL
ORDER BY purchase_month;