-- Export dashboard-ready flat files for Looker Studio

-- One row per order
COPY (
    SELECT
        o.order_id,
        o.purchase_date,
        DATE_TRUNC('month', o.purchase_date)::DATE      AS purchase_month,
        o.order_status,
        o.customer_state,
        o.customer_unique_id,
        o.customer_order_number,
        o.n_items,
        o.items_value                                   AS gmv,
        o.freight_value,
        o.order_value,
        o.main_payment_type,
        o.max_installments,
        o.is_delivered::INT                             AS is_delivered,
        o.is_canceled::INT                              AS is_canceled,
        o.delivery_days,
        o.estimated_days,
        o.delay_days,
        o.is_late::INT                                  AS is_late,        -- NULL if not delivered
        o.review_score,
        o.has_review::INT                               AS has_review,
        CASE WHEN o.review_score <= 2 THEN 1 ELSE 0 END  AS is_low_review
    FROM marts.fct_orders o
    WHERE o.in_analysis_window
) TO 'E:/Data_Analytic/Olist/exports/looker_orders.csv' (HEADER, DELIMITER ',');


-- One row per order item (category / seller analysis)
COPY (
    SELECT
        i.order_id,
        i.order_item_id,
        i.purchase_date,
        DATE_TRUNC('month', i.purchase_date)::DATE      AS purchase_month,
        i.customer_state,
        p.category,
        i.seller_id,
        s.seller_state,
        i.price,
        i.freight_value,
        o.is_late::INT                                  AS is_late,
        o.review_score
    FROM marts.fct_order_items i
    JOIN marts.dim_products p USING (product_id)
    JOIN marts.dim_sellers  s USING (seller_id)
    JOIN marts.fct_orders   o USING (order_id)
    WHERE i.in_analysis_window
) TO 'E:/Data_Analytic/Olist/exports/looker_order_items.csv' (HEADER, DELIMITER ',');