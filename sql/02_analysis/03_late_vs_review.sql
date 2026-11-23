-- Question: how much does late delivery hurt the review score?
-- Source: marts.fct_orders · delivered, reviewed orders · window 2017-01 → 2018-08
-- Caveat: association, not proof of causation. Only orders with a review (selection bias).

-- Late vs on time
SELECT
    CASE WHEN is_late THEN 'late' ELSE 'on time' END            AS delivery,
    COUNT(*)                                                    AS n_orders,
    ROUND(AVG(review_score), 2)                                 AS avg_score,
    ROUND(100.0 * AVG((review_score <= 2)::INT), 1)             AS pct_1_2_stars,
    ROUND(100.0 * AVG((review_score = 5)::INT), 1)              AS pct_5_stars
FROM marts.fct_orders
WHERE in_analysis_window
  AND is_late IS NOT NULL
  AND has_review
GROUP BY ALL
ORDER BY delivery;


-- Dose-response: the later, the worse?
SELECT
    CASE
        WHEN delay_days <= -7 THEN '1. 7+ days early'
        WHEN delay_days <=  0 THEN '2. 0-6 days early / on time'
        WHEN delay_days <=  3 THEN '3. 1-3 days late'
        WHEN delay_days <=  7 THEN '4. 4-7 days late'
        WHEN delay_days <= 14 THEN '5. 8-14 days late'
        ELSE                       '6. 15+ days late'
    END                                                         AS delay_bucket,
    COUNT(*)                                                    AS n_orders,
    ROUND(AVG(review_score), 2)                                 AS avg_score,
    ROUND(100.0 * AVG((review_score <= 2)::INT), 1)             AS pct_1_2_stars
FROM marts.fct_orders
WHERE in_analysis_window
  AND is_late IS NOT NULL
  AND has_review
GROUP BY ALL
ORDER BY delay_bucket;


-- Share of all 1-2 star reviews that come from late orders
SELECT
    COUNT(*) FILTER (WHERE review_score <= 2)                                   AS n_low_reviews,
    COUNT(*) FILTER (WHERE review_score <= 2 AND is_late)                       AS n_low_reviews_late,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2 AND is_late)
          / COUNT(*) FILTER (WHERE review_score <= 2), 1)                       AS pct_low_reviews_from_late,
    ROUND(100.0 * AVG(is_late::INT), 1)                                         AS pct_orders_late
FROM marts.fct_orders
WHERE in_analysis_window
  AND is_late IS NOT NULL
  AND has_review;