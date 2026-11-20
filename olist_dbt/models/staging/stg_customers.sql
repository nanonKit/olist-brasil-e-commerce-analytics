-- One row per customer_id (= per order)
with source as (
    select * from {{ source('raw', 'customers') }}
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,              -- text: keeps leading zeros
    lower(trim(customer_city))  as customer_city,
    upper(trim(customer_state)) as customer_state
from source