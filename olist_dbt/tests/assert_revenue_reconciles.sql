-- Fails (returns a row) if revenue changes between layers: staging items vs fct_order_items vs fct_orders.
with s as (select sum(price) as v from {{ ref('stg_order_items') }}),
     f as (select sum(price) as v from {{ ref('fct_order_items') }}),
     o as (select sum(items_value) as v from {{ ref('fct_orders') }})
select s.v as staging_price, f.v as fct_items_price, o.v as fct_orders_items_value
from s, f, o
where s.v <> f.v or s.v <> o.v