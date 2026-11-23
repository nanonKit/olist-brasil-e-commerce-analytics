-- Fails if fct_orders does not keep every order from staging (no loss, no fan-out).
select
    (select count(*) from {{ ref('stg_orders') }}) as stg_orders,
    (select count(*) from {{ ref('fct_orders') }}) as fct_orders
where (select count(*) from {{ ref('stg_orders') }})
   <> (select count(*) from {{ ref('fct_orders') }})