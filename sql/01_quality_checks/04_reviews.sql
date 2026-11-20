-- Question: what is one row of order_reviews, and can we link one score to one order?


-- Keys: review_id and order_id are NOT unique on their own
SELECT
    COUNT(*)                                     AS n_rows,
    COUNT(DISTINCT review_id)                    AS n_review_id,
    COUNT(DISTINCT order_id)                     AS n_order_id,
    COUNT(DISTINCT (review_id, order_id))        AS n_review_order_pairs
FROM raw.order_reviews;


-- Orders with more than one review
WITH reviews_per_order AS (
    SELECT order_id,
           COUNT(*)                     AS n_reviews,
           COUNT(DISTINCT review_score) AS n_distinct_scores
    FROM raw.order_reviews
    GROUP BY order_id
)
SELECT
    n_reviews,
    COUNT(*)                                        AS n_orders,
    COUNT(*) FILTER (WHERE n_distinct_scores > 1)   AS n_orders_conflicting_scores
FROM reviews_per_order
GROUP BY n_reviews
ORDER BY n_reviews;


-- Same review_id on several orders: same text reused?
SELECT
    review_id,
    COUNT(*)                            AS n_orders,
    COUNT(DISTINCT review_score)        AS n_distinct_scores,
    MIN(review_creation_date)           AS created
FROM raw.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY n_orders DESC
LIMIT 10;


-- Score distribution + comment completeness
SELECT
    review_score,
    COUNT(*)                                                                AS n_rows,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                      AS pct_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_comment_message IS NULL
                                   OR TRIM(review_comment_message) = '')
          / COUNT(*), 2)                                                    AS pct_no_comment
FROM raw.order_reviews
GROUP BY review_score
ORDER BY review_score;


-- Coverage: orders without any review, by status
SELECT o.order_status, COUNT(*) AS n_orders_without_review
FROM raw.orders o
WHERE NOT EXISTS (SELECT 1 FROM raw.order_reviews r WHERE r.order_id = o.order_id)
GROUP BY o.order_status
ORDER BY n_orders_without_review DESC;


-- Dates: answer before creation? (expect 0)
SELECT
    COUNT(*) FILTER (WHERE TRY_CAST(review_answer_timestamp AS TIMESTAMP)
                         < TRY_CAST(review_creation_date AS TIMESTAMP))  AS answer_before_creation,
    MIN(review_creation_date)                                            AS first_review,
    MAX(review_creation_date)                                            AS last_review
FROM raw.order_reviews;