-- One row per Portuguese category name with its English name
with source as (
    select * from {{ source('raw', 'product_category_translate') }}
)

select
    product_category_name,
    product_category_name_english
from source