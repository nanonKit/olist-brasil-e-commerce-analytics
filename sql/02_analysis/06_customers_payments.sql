-- Question: how many customers come back, how fast, and how do customers pay?

-- Repeat rate: by orders vs by distinct purchase days
WITH per_customer AS (
    SELECT
        customer_unique_id,
        COUNT(*)                        AS n_orders,
        COUNT(DISTINCT purchase_date)   AS n_purchase_days
    FROM marts.fct_orders
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*)                                                    AS n_customers,
    COUNT(*) FILTER (WHERE n_orders > 1)                        AS n_repeat_orders,
    ROUND(100.0 * AVG((n_orders > 1)::INT), 2)                  AS repeat_rate_orders_pct,
    COUNT(*) FILTER (WHERE n_purchase_days > 1)                 AS n_repeat_days,
    ROUND(100.0 * AVG((n_purchase_days > 1)::INT), 2)           AS repeat_rate_days_pct
FROM per_customer;


-- Days between 1st and 2nd order (repeat customers)
WITH seq AS (
    SELECT
        customer_unique_id,
        customer_order_number,
        purchase_date,
        LAG(purchase_date) OVER (PARTITION BY customer_unique_id ORDER BY customer_order_number) AS prev_date
    FROM marts.fct_orders
)
SELECT
    COUNT(*)                                                     AS n_second_orders,
    MEDIAN(date_diff('day', prev_date, purchase_date))           AS median_days_to_2nd,
    ROUND(100.0 * AVG((date_diff('day', prev_date, purchase_date) = 0)::INT), 1) AS pct_same_day
FROM seq
WHERE customer_order_number = 2;


-- Payment mix (main payment type per order)
SELECT
    main_payment_type,
    COUNT(*)                                                     AS n_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_orders,
    ROUND(AVG(paid_value), 2)                                    AS avg_paid
FROM marts.fct_orders
WHERE in_analysis_window
  AND main_payment_type IS NOT NULL
GROUP BY ALL
ORDER BY n_orders DESC;


-- Credit card installments: order value by number of installments
SELECT
    CASE
        WHEN max_installments = 1  THEN '1. 1x'
        WHEN max_installments <= 3 THEN '2. 2-3x'
        WHEN max_installments <= 6 THEN '3. 4-6x'
        ELSE                            '4. 7x+'
    END                                                          AS installments,
    COUNT(*)                                                     AS n_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_orders,
    ROUND(AVG(paid_value), 2)                                    AS avg_paid
FROM marts.fct_orders
WHERE in_analysis_window
  AND main_payment_type = 'credit_card'
GROUP BY ALL
ORDER BY installments;