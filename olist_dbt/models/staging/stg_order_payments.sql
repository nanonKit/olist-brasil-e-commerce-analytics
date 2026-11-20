-- One row per payment in an order
with source as (
    select * from {{ source('raw', 'order_payments') }}
)

select
    order_id,
    cast(payment_sequential as integer)                          as payment_sequential,
    payment_type,
    greatest(cast(payment_installments as integer), 1)           as payment_installments,
    cast(payment_value as decimal(18, 2))                        as payment_value
from source