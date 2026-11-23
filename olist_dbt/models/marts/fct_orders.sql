-- One row per order(no fan-out).
with orders as (
    select
        o.*,
        c.customer_unique_id,
        c.customer_state
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_customers') }} c using (customer_id)
)

select
    o.order_id,
    o.customer_unique_id,
    o.purchase_date,
    o.order_status,
    o.customer_state,                                       -- state at order time

    -- items (NULL for 775 orders without items)
    i.n_items,
    i.n_sellers,
    i.items_value,
    i.freight_value,
    i.order_value,

    -- payments
    p.n_payments,
    p.paid_value,
    p.main_payment_type,
    p.max_installments,

    -- delivery (purchase -> delivered vs estimated; carrier date not used, Decision 11)
    o.order_status = 'delivered'                                            as is_delivered,
    o.order_status = 'canceled'                                             as is_canceled,
    date_diff('day', o.purchased_at, o.delivered_customer_at)               as delivery_days,
    date_diff('day', o.purchased_at, o.estimated_delivery_at)               as estimated_days,
    date_diff('day', o.estimated_delivery_at::date, o.delivered_customer_at::date) as delay_days,
    case
        when o.order_status = 'delivered' and o.delivered_customer_at is not null
            then o.delivered_customer_at::date > o.estimated_delivery_at::date
    end                                                                     as is_late,

    -- review (latest per order; NULL if none)
    r.review_score,
    r.review_score is not null                                              as has_review,
    r.has_comment,

    -- customer sequence
    row_number() over (partition by o.customer_unique_id order by o.purchased_at, o.order_id) as customer_order_number,
    o.purchase_date between date '2017-01-01' and date '2018-08-31'        as in_analysis_window
from orders o
left join {{ ref('int_order_items_agg') }}    i using (order_id)
left join {{ ref('int_order_payments_agg') }} p using (order_id)
left join {{ ref('stg_order_reviews') }}      r using (order_id)