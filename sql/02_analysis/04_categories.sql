-- Question: which categories drive revenue, and which combine high revenue with late delivery / low reviews?
-- Note: delivery and review live at ORDER grain, so they are joined on distinct (order, category) pairs to avoid double counting.

-- Top 15 categories by GMV (+ cumulative share)
WITH cat_rev AS (
    SELECT
        p.category,
        COUNT(DISTINCT i.order_id)      AS n_orders,
        COUNT(*)                        AS n_items,
        SUM(i.price)                    AS gmv
    FROM marts.fct_order_items i
    JOIN marts.dim_products p USING (product_id)
    WHERE i.in_analysis_window
    GROUP BY p.category
),
shares AS (
    SELECT *, 100.0 * gmv / SUM(gmv) OVER () AS pct_gmv
    FROM cat_rev
)
SELECT
    category,
    n_orders,
    n_items,
    ROUND(gmv, 0)                                              AS gmv,
    ROUND(pct_gmv, 1)                                          AS pct_gmv,
    ROUND(SUM(pct_gmv) OVER (ORDER BY gmv DESC), 1)            AS cum_pct_gmv,
    ROUND(gmv / n_items, 2)                                    AS avg_item_price,
    COUNT(*) OVER ()                                           AS n_categories
FROM shares
ORDER BY gmv DESC
LIMIT 15;


-- Delivery and review by category (categories with >= 500 delivered orders), worst score first
WITH order_cat AS (
    SELECT DISTINCT i.order_id, p.category
    FROM marts.fct_order_items i
    JOIN marts.dim_products p USING (product_id)
    WHERE i.in_analysis_window
)
SELECT
    oc.category,
    COUNT(*)                                                AS n_delivered_orders,
    MEDIAN(o.delivery_days)                                 AS median_delivery_days,
    ROUND(100.0 * AVG(o.is_late::INT), 1)                   AS pct_late,
    ROUND(AVG(o.review_score), 2)                           AS avg_score,
    ROUND(100.0 * AVG((o.review_score <= 2)::INT), 1)       AS pct_1_2_stars
FROM order_cat oc
JOIN marts.fct_orders o USING (order_id)
WHERE o.is_late IS NOT NULL
GROUP BY oc.category
HAVING COUNT(*) >= 500
ORDER BY avg_score
LIMIT 15;