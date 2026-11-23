-- Question: how concentrated is GMV across sellers, and are late deliveries concentrated in a few sellers?

WITH seller_gmv AS (
    SELECT seller_id, SUM(price) AS gmv
    FROM marts.fct_order_items
    WHERE in_analysis_window
    GROUP BY seller_id
),
ranked AS (
    SELECT
        seller_id,
        gmv,
        ROW_NUMBER() OVER (ORDER BY gmv DESC)    AS rnk,
        COUNT(*)     OVER ()                     AS n_sellers,
        SUM(gmv)     OVER ()                     AS total_gmv
    FROM seller_gmv
)
SELECT
    MAX(n_sellers)                                                                 AS n_sellers,
    ROUND(100.0 * SUM(gmv) FILTER (WHERE rnk <= n_sellers * 0.01) / MAX(total_gmv), 1) AS pct_gmv_top_1pct,
    ROUND(100.0 * SUM(gmv) FILTER (WHERE rnk <= n_sellers * 0.10) / MAX(total_gmv), 1) AS pct_gmv_top_10pct,
    ROUND(100.0 * SUM(gmv) FILTER (WHERE rnk <= n_sellers * 0.20) / MAX(total_gmv), 1) AS pct_gmv_top_20pct,
    MEDIAN(gmv)                                                                    AS median_seller_gmv
FROM ranked;


-- B. Seller state: where GMV comes from
SELECT
    s.seller_state,
    COUNT(DISTINCT i.seller_id)                         AS n_sellers,
    ROUND(SUM(i.price), 0)                              AS gmv,
    ROUND(100.0 * SUM(i.price) / SUM(SUM(i.price)) OVER (), 1) AS pct_gmv
FROM marts.fct_order_items i
JOIN marts.dim_sellers s USING (seller_id)
WHERE i.in_analysis_window
GROUP BY s.seller_state
ORDER BY gmv DESC
LIMIT 8;


-- C. Late-delivery concentration: sellers with >= 50 delivered orders and late rate >= 15%
WITH order_seller AS (
    SELECT DISTINCT order_id, seller_id
    FROM marts.fct_order_items
    WHERE in_analysis_window
),
seller_late AS (
    SELECT
        os.seller_id,
        COUNT(*)                        AS n_delivered,
        SUM(o.is_late::INT)             AS n_late
    FROM order_seller os
    JOIN marts.fct_orders o USING (order_id)
    WHERE o.is_late IS NOT NULL
    GROUP BY os.seller_id
)
SELECT
    COUNT(*) FILTER (WHERE n_delivered >= 50)                                          AS sellers_50plus,
    COUNT(*) FILTER (WHERE n_delivered >= 50 AND n_late * 1.0 / n_delivered >= 0.15)   AS sellers_late_15pct,
    SUM(n_late) FILTER (WHERE n_delivered >= 50 AND n_late * 1.0 / n_delivered >= 0.15) AS late_orders_from_them,
    SUM(n_late)                                                                        AS late_orders_all,
    ROUND(100.0 * SUM(n_late) FILTER (WHERE n_delivered >= 50 AND n_late * 1.0 / n_delivered >= 0.15)
          / SUM(n_late), 1)                                                            AS pct_late_from_them
FROM seller_late;