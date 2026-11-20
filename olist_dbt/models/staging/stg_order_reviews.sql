-- One row per ORDER: keep the latest review when an order has several
with source as (
    select * from {{ source('raw', 'order_reviews') }}
),

typed as (
    select
        review_id,
        order_id,
        cast(review_score as integer)                as review_score,
        nullif(trim(review_comment_title), '')       as review_comment_title,
        nullif(trim(review_comment_message), '')     as review_comment_message,
        cast(review_creation_date    as timestamp)   as review_created_at,
        cast(review_answer_timestamp as timestamp)   as review_answered_at
    from source
)

select
    *,
    review_comment_message is not null as has_comment
from typed
qualify row_number() over (
    partition by order_id
    order by review_answered_at desc, review_created_at desc, review_id
) = 1