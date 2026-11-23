-- One row per product
select
    p.product_id,
    coalesce(t.product_category_name_english, p.product_category_name, '(unknown)') as category,
    p.product_category_name                                                         as category_pt,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_photos_qty
from {{ ref('stg_products') }} p
left join {{ ref('stg_product_category_translate') }} t using (product_category_name)