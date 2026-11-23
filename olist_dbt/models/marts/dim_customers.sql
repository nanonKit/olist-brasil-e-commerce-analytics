-- One row per real customer (customer_unique_id). Location = from the latest order.
with orders as (
    select
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        o.purchased_at
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_customers') }} c using (customer_id)
)

select
    customer_unique_id,
    arg_max(customer_state, purchased_at)   as customer_state,
    arg_max(customer_city,  purchased_at)   as customer_city,
    min(purchased_at)::date                 as first_order_date,
    max(purchased_at)::date                 as last_order_date,
    count(*)                                as n_orders,
    count(*) > 1                            as is_repeat
from orders
group by customer_unique_id