-- Question: how long does delivery take and how often is it late, by customer state?

-- Overall delivery KPIs
SELECT
    COUNT(*)                                                   AS n_delivered,
    MEDIAN(delivery_days)                                      AS median_delivery_days,
    ROUND(AVG(delivery_days), 1)                               AS avg_delivery_days,
    MEDIAN(estimated_days)                                     AS median_estimated_days,
    ROUND(100.0 * AVG(is_late::INT), 2)                        AS pct_late
FROM marts.fct_orders
WHERE in_analysis_window
  AND is_late IS NOT NULL;


-- By customer state (states with >= 100 delivered orders), slowest first
SELECT
    customer_state,
    COUNT(*)                                                   AS n_delivered,
    MEDIAN(delivery_days)                                      AS median_delivery_days,
    ROUND(100.0 * AVG(is_late::INT), 1)                        AS pct_late,
    ROUND(AVG(delay_days) FILTER (WHERE is_late), 1)           AS avg_days_late_when_late
FROM marts.fct_orders
WHERE in_analysis_window
  AND is_late IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY median_delivery_days DESC, pct_late DESC;