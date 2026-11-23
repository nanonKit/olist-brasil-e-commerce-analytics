-- One row per order: item totals aggregated BEFORE joining to orders (prevents fan-out).
select
    order_id,
    count(*)                    as n_items,
    count(distinct product_id)  as n_products,
    count(distinct seller_id)   as n_sellers,
    sum(price)                  as items_value,
    sum(freight_value)          as freight_value,
    sum(item_value)             as order_value
from {{ ref('stg_order_items') }}
group by order_id