-- 01_load_raw.sql
CREATE SCHEMA IF NOT EXISTS 'raw';

-- load 9 olist CSVs (Kaggle: olistbr/brazilian-ecommerce) into schema raw, all column as VARCHAR.
CREATE OR REPLACE TABLE raw.sellers AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_sellers_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.customers AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_customers_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.geolocation AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_geolocation_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.order_items AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_order_items_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.order_payments AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_order_payments_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.order_reviews AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_order_reviews_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.orders AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_orders_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.products AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/olist_products_dataset.csv', all_varchar = true);
CREATE OR REPLACE TABLE raw.product_category_translate AS
SELECT * FROM read_csv('E:/Data_Analytic/Olist/data/raw/product_category_name_translation.csv', all_varchar = true);

-- re-runnable. casting happens in staging
SELECT 'customers' AS table_name, count(*) AS row_count FROM raw.customers
UNION ALL
SELECT 'geolocation' AS table_name, count(*) AS row_count FROM raw.geolocation
UNION ALL
SELECT 'order_items' AS table_name, count(*) AS row_count FROM raw.order_items
UNION ALL
SELECT 'order_payments' AS table_name, count(*) AS row_count FROM raw.order_payments
UNION ALL
SELECT 'order_reviews' AS table_name, count(*) AS row_count FROM raw.order_reviews
UNION ALL
SELECT 'orders' AS table_name, count(*) AS row_count FROM raw.orders
UNION ALL
SELECT 'products' AS table_name, count(*) AS row_count FROM raw.products
UNION ALL
SELECT 'sellers' AS table_name, count(*) AS row_count FROM raw.sellers
UNION ALL
SELECT 'product_category_translate' AS table_name, count(*) AS row_count FROM raw.product_category_translate
ORDER BY table_name;
