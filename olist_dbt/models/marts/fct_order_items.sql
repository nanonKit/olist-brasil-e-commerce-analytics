-- One row per item in an order. Use for category / seller / product analysis.
select
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    c.customer_unique_id,
    o.purchase_date,
    o.order_status,
    c.customer_state,
    oi.price,
    oi.freight_value,
    oi.item_value,
    o.purchase_date between date '2017-01-01' and date '2018-08-31' as in_analysis_window
from {{ ref('stg_order_items') }} oi
join {{ ref('stg_orders') }}    o using (order_id)
join {{ ref('stg_customers') }} c using (customer_id)