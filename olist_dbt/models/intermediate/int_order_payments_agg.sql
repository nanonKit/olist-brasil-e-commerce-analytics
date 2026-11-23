-- One row per order: payment totals; main type = the type with the largest amount.
select
    order_id,
    count(*)                                   as n_payments,
    sum(payment_value)                         as paid_value,
    max(payment_installments)                  as max_installments,
    arg_max(payment_type, payment_value)       as main_payment_type
from {{ ref('stg_order_payments') }}
group by order_id