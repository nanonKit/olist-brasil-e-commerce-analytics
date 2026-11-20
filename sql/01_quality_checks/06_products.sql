-- Question: are product attributes complete, and does every category have an English name?

-- Key + completeness
SELECT
    COUNT(*)                                                               AS n_rows,
    COUNT(DISTINCT product_id)                                             AS n_product_id,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(product_category_name), '') IS NULL) AS no_category,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL)                       AS no_weight,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL
                        OR product_height_cm IS NULL
                        OR product_width_cm IS NULL)                       AS no_dimensions,
    COUNT(*) FILTER (WHERE TRY_CAST(product_weight_g AS INTEGER) = 0)      AS weight_eq_0
FROM raw.products;


-- Translation coverage: categories in products without an English name
SELECT
    p.product_category_name,
    COUNT(*) AS n_products
FROM raw.products p
WHERE NULLIF(TRIM(p.product_category_name), '') IS NOT NULL
  AND NOT EXISTS (
        SELECT 1 FROM raw.product_category_translate t
        WHERE t.product_category_name = p.product_category_name)
GROUP BY p.product_category_name
ORDER BY n_products DESC;


-- Category count + biggest categories by items sold
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, '(missing)') AS category,
    COUNT(*)                                                                        AS n_items_sold,
    ROUND(SUM(CAST(oi.price AS DECIMAL(18,2))), 0)                                  AS revenue
FROM raw.order_items oi
JOIN raw.products p USING (product_id)
LEFT JOIN raw.product_category_translate t USING (product_category_name)
GROUP BY ALL
ORDER BY revenue DESC
LIMIT 15;


-- Referential integrity: items whose product is missing from products
SELECT COUNT(*) AS items_without_product
FROM raw.order_items oi
WHERE NOT EXISTS (SELECT 1 FROM raw.products p WHERE p.product_id = oi.product_id);