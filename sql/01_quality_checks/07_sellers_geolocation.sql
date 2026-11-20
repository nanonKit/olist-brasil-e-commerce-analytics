-- Question: are sellers clean, and can geolocation be joined by zip prefix without fan-out?

-- Sellers: key + referential integrity with order_items
SELECT
    (SELECT COUNT(*)                   FROM raw.sellers)  AS n_rows,
    (SELECT COUNT(DISTINCT seller_id)  FROM raw.sellers)  AS n_seller_id,
    (SELECT COUNT(*) FROM raw.order_items oi
     WHERE NOT EXISTS (SELECT 1 FROM raw.sellers s WHERE s.seller_id = oi.seller_id))
                                                          AS items_without_seller;


-- Geolocation grain: many rows per zip prefix -> NOT a lookup table as-is
SELECT
    COUNT(*)                                                    AS n_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix)                 AS n_zip_prefix,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT geolocation_zip_code_prefix), 1) AS avg_rows_per_zip,
    COUNT(*) - COUNT(DISTINCT (geolocation_zip_code_prefix,
                               geolocation_lat, geolocation_lng,
                               geolocation_city, geolocation_state))         AS exact_duplicates
FROM raw.geolocation;


-- Coordinates outside Brazil's bounding box (lat -33.75..5.27, lng -73.99..-34.79)
SELECT COUNT(*) AS rows_outside_brazil
FROM raw.geolocation
WHERE CAST(geolocation_lat AS DOUBLE) NOT BETWEEN -33.75 AND 5.27
   OR CAST(geolocation_lng AS DOUBLE) NOT BETWEEN -73.99 AND -34.79;


-- Zip coverage: customer / seller zips missing from geolocation
SELECT
    (SELECT COUNT(DISTINCT customer_zip_code_prefix) FROM raw.customers c
     WHERE NOT EXISTS (SELECT 1 FROM raw.geolocation g
                       WHERE g.geolocation_zip_code_prefix = c.customer_zip_code_prefix))
        AS customer_zips_missing,
    (SELECT COUNT(DISTINCT seller_zip_code_prefix) FROM raw.sellers s
     WHERE NOT EXISTS (SELECT 1 FROM raw.geolocation g
                       WHERE g.geolocation_zip_code_prefix = s.seller_zip_code_prefix))
        AS seller_zips_missing;


-- State values: consistent 2-letter codes? (expect 27 Brazilian states)
SELECT
    (SELECT COUNT(DISTINCT customer_state) FROM raw.customers) AS customer_states,
    (SELECT COUNT(DISTINCT seller_state)   FROM raw.sellers)   AS seller_states,
    (SELECT COUNT(*) FROM raw.customers WHERE LENGTH(customer_state) <> 2) AS bad_customer_state;