-- Question: how did orders, GMV and AOV develop month by month, and how big is 2018 vs 2017 like-for-like?

-- Monthly KPIs + month-over-month growth
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', purchase_date)::DATE     AS month_start,
        COUNT(*)                                     AS n_orders,
        COUNT(DISTINCT customer_unique_id)           AS n_customers,
        SUM(items_value)                             AS gmv,
        SUM(items_value) / COUNT(items_value)        AS aov          -- orders with items only
    FROM marts.fct_orders
    WHERE in_analysis_window
    GROUP BY ALL
)
SELECT
    month_start,
    n_orders,
    n_customers,
    ROUND(gmv, 0)                                                         AS gmv,
    ROUND(aov, 2)                                                         AS aov,
    ROUND(100.0 * (gmv - LAG(gmv) OVER (ORDER BY month_start))
          / LAG(gmv) OVER (ORDER BY month_start), 1)                      AS gmv_mom_pct
FROM monthly
ORDER BY month_start;


-- Like-for-like: Jan–Aug 2018 vs Jan–Aug 2017
SELECT
    YEAR(purchase_date)                                  AS year,
    COUNT(*)                                             AS n_orders,
    ROUND(SUM(items_value), 0)                           AS gmv,
    ROUND(SUM(items_value) / COUNT(items_value), 2)      AS aov
FROM marts.fct_orders
WHERE MONTH(purchase_date) BETWEEN 1 AND 8
  AND YEAR(purchase_date) IN (2017, 2018)
GROUP BY ALL
ORDER BY year;