CREATE SCHEMA IF NOT EXISTS clickhouse.dwh;

DROP TABLE IF EXISTS clickhouse.dwh.fact_sales;
DROP TABLE IF EXISTS clickhouse.dwh.dim_date;
DROP TABLE IF EXISTS clickhouse.dwh.dim_supplier;
DROP TABLE IF EXISTS clickhouse.dwh.dim_store;
DROP TABLE IF EXISTS clickhouse.dwh.dim_product;
DROP TABLE IF EXISTS clickhouse.dwh.dim_seller;
DROP TABLE IF EXISTS clickhouse.dwh.dim_customer;
DROP TABLE IF EXISTS clickhouse.dwh.stg_sales;

CREATE TABLE clickhouse.dwh.stg_sales
WITH (
  engine = 'MergeTree'
) AS
WITH source_rows AS (
  SELECT 'clickhouse' AS source_system, m.*
  FROM clickhouse.raw.mock_data m

  UNION ALL

  SELECT 'postgresql' AS source_system, m.*
  FROM postgresql.raw.mock_data m
),
cleaned AS (
  SELECT
    source_system,
    NULLIF(trim(id), '') AS source_row_id,
    NULLIF(trim(customer_first_name), '') AS customer_first_name,
    NULLIF(trim(customer_last_name), '') AS customer_last_name,
    try_cast(NULLIF(trim(customer_age), '') AS integer) AS customer_age,
    lower(NULLIF(trim(customer_email), '')) AS customer_email,
    NULLIF(trim(customer_country), '') AS customer_country,
    NULLIF(trim(customer_postal_code), '') AS customer_postal_code,
    NULLIF(trim(customer_pet_type), '') AS customer_pet_type,
    NULLIF(trim(customer_pet_name), '') AS customer_pet_name,
    NULLIF(trim(customer_pet_breed), '') AS customer_pet_breed,
    NULLIF(trim(seller_first_name), '') AS seller_first_name,
    NULLIF(trim(seller_last_name), '') AS seller_last_name,
    lower(NULLIF(trim(seller_email), '')) AS seller_email,
    NULLIF(trim(seller_country), '') AS seller_country,
    NULLIF(trim(seller_postal_code), '') AS seller_postal_code,
    NULLIF(trim(product_name), '') AS product_name,
    NULLIF(trim(product_category), '') AS product_category,
    try_cast(NULLIF(trim(product_price), '') AS decimal(12, 2)) AS product_price,
    try_cast(NULLIF(trim(product_quantity), '') AS integer) AS product_quantity,
    TRY(CAST(date_parse(NULLIF(trim(sale_date), ''), '%c/%e/%Y') AS date)) AS sale_date,
    NULLIF(trim(sale_customer_id), '') AS sale_customer_id,
    NULLIF(trim(sale_seller_id), '') AS sale_seller_id,
    NULLIF(trim(sale_product_id), '') AS sale_product_id,
    try_cast(NULLIF(trim(sale_quantity), '') AS integer) AS sale_quantity,
    try_cast(NULLIF(trim(sale_total_price), '') AS decimal(14, 2)) AS sale_total_price,
    NULLIF(trim(store_name), '') AS store_name,
    NULLIF(trim(store_location), '') AS store_location,
    NULLIF(trim(store_city), '') AS store_city,
    NULLIF(trim(store_state), '') AS store_state,
    NULLIF(trim(store_country), '') AS store_country,
    NULLIF(trim(store_phone), '') AS store_phone,
    lower(NULLIF(trim(store_email), '')) AS store_email,
    NULLIF(trim(pet_category), '') AS pet_category,
    try_cast(NULLIF(trim(product_weight), '') AS decimal(10, 2)) AS product_weight,
    NULLIF(trim(product_color), '') AS product_color,
    NULLIF(trim(product_size), '') AS product_size,
    NULLIF(trim(product_brand), '') AS product_brand,
    NULLIF(trim(product_material), '') AS product_material,
    NULLIF(trim(product_description), '') AS product_description,
    try_cast(NULLIF(trim(product_rating), '') AS double) AS product_rating,
    try_cast(NULLIF(trim(product_reviews), '') AS integer) AS product_reviews,
    TRY(CAST(date_parse(NULLIF(trim(product_release_date), ''), '%c/%e/%Y') AS date)) AS product_release_date,
    TRY(CAST(date_parse(NULLIF(trim(product_expiry_date), ''), '%c/%e/%Y') AS date)) AS product_expiry_date,
    NULLIF(trim(supplier_name), '') AS supplier_name,
    NULLIF(trim(supplier_contact), '') AS supplier_contact,
    lower(NULLIF(trim(supplier_email), '')) AS supplier_email,
    NULLIF(trim(supplier_phone), '') AS supplier_phone,
    NULLIF(trim(supplier_address), '') AS supplier_address,
    NULLIF(trim(supplier_city), '') AS supplier_city,
    NULLIF(trim(supplier_country), '') AS supplier_country
  FROM source_rows
)
SELECT
  lower(to_hex(md5(to_utf8(concat_ws('|',
    source_system,
    coalesce(source_row_id, ''),
    coalesce(customer_email, ''),
    coalesce(seller_email, ''),
    coalesce(product_name, ''),
    coalesce(store_name, ''),
    coalesce(supplier_name, ''),
    coalesce(CAST(sale_date AS varchar), '')
  ))))) AS sale_key,
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(customer_email, ''),
    coalesce(customer_first_name, ''),
    coalesce(customer_last_name, ''),
    coalesce(customer_country, ''),
    coalesce(customer_postal_code, '')
  ))))) AS customer_key,
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(seller_email, ''),
    coalesce(seller_first_name, ''),
    coalesce(seller_last_name, ''),
    coalesce(seller_country, ''),
    coalesce(seller_postal_code, '')
  ))))) AS seller_key,
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(product_name, ''),
    coalesce(product_category, ''),
    coalesce(product_brand, ''),
    coalesce(product_color, ''),
    coalesce(product_size, ''),
    coalesce(product_material, ''),
    coalesce(supplier_name, '')
  ))))) AS product_key,
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(store_name, ''),
    coalesce(store_location, ''),
    coalesce(store_city, ''),
    coalesce(store_state, ''),
    coalesce(store_country, '')
  ))))) AS store_key,
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(supplier_name, ''),
    coalesce(supplier_contact, ''),
    coalesce(supplier_email, ''),
    coalesce(supplier_phone, ''),
    coalesce(supplier_address, ''),
    coalesce(supplier_city, ''),
    coalesce(supplier_country, '')
  ))))) AS supplier_key,
  source_system,
  source_row_id,
  customer_first_name,
  customer_last_name,
  customer_age,
  customer_email,
  customer_country,
  customer_postal_code,
  customer_pet_type,
  customer_pet_name,
  customer_pet_breed,
  seller_first_name,
  seller_last_name,
  seller_email,
  seller_country,
  seller_postal_code,
  product_name,
  product_category,
  product_price,
  product_quantity,
  sale_date,
  CASE
    WHEN sale_date IS NULL THEN NULL
    ELSE CAST(year(sale_date) * 10000 + month(sale_date) * 100 + day(sale_date) AS integer)
  END AS sale_date_key,
  sale_customer_id,
  sale_seller_id,
  sale_product_id,
  sale_quantity,
  coalesce(sale_total_price, CAST(product_price * sale_quantity AS decimal(14, 2))) AS sale_total_price,
  store_name,
  store_location,
  store_city,
  store_state,
  store_country,
  store_phone,
  store_email,
  pet_category,
  product_weight,
  product_color,
  product_size,
  product_brand,
  product_material,
  product_description,
  product_rating,
  product_reviews,
  product_release_date,
  product_expiry_date,
  supplier_name,
  supplier_contact,
  supplier_email,
  supplier_phone,
  supplier_address,
  supplier_city,
  supplier_country
FROM cleaned;

CREATE TABLE clickhouse.dwh.dim_customer
WITH (
  engine = 'MergeTree'
) AS
SELECT DISTINCT
  customer_key,
  customer_first_name,
  customer_last_name,
  customer_age,
  customer_email,
  customer_country,
  customer_postal_code,
  customer_pet_type,
  customer_pet_name,
  customer_pet_breed
FROM clickhouse.dwh.stg_sales;

CREATE TABLE clickhouse.dwh.dim_seller
WITH (
  engine = 'MergeTree'
) AS
SELECT DISTINCT
  seller_key,
  seller_first_name,
  seller_last_name,
  seller_email,
  seller_country,
  seller_postal_code
FROM clickhouse.dwh.stg_sales;

CREATE TABLE clickhouse.dwh.dim_product
WITH (
  engine = 'MergeTree'
) AS
SELECT DISTINCT
  product_key,
  product_name,
  product_category,
  pet_category,
  product_price,
  product_quantity,
  product_weight,
  product_color,
  product_size,
  product_brand,
  product_material,
  product_description,
  product_rating,
  product_reviews,
  product_release_date,
  product_expiry_date
FROM clickhouse.dwh.stg_sales;

CREATE TABLE clickhouse.dwh.dim_store
WITH (
  engine = 'MergeTree'
) AS
SELECT DISTINCT
  store_key,
  store_name,
  store_location,
  store_city,
  store_state,
  store_country,
  store_phone,
  store_email
FROM clickhouse.dwh.stg_sales;

CREATE TABLE clickhouse.dwh.dim_supplier
WITH (
  engine = 'MergeTree'
) AS
SELECT DISTINCT
  supplier_key,
  supplier_name,
  supplier_contact,
  supplier_email,
  supplier_phone,
  supplier_address,
  supplier_city,
  supplier_country
FROM clickhouse.dwh.stg_sales;

CREATE TABLE clickhouse.dwh.dim_date
WITH (
  engine = 'MergeTree'
) AS
SELECT DISTINCT
  sale_date_key AS date_key,
  sale_date AS full_date,
  CAST(year(sale_date) AS integer) AS year_number,
  CAST(quarter(sale_date) AS integer) AS quarter_number,
  CAST(month(sale_date) AS integer) AS month_number,
  CAST(day(sale_date) AS integer) AS day_number,
  CAST(day_of_week(sale_date) AS integer) AS day_of_week_number,
  CAST(date_trunc('month', CAST(sale_date AS timestamp)) AS date) AS month_start_date,
  CAST(date_trunc('year', CAST(sale_date AS timestamp)) AS date) AS year_start_date
FROM clickhouse.dwh.stg_sales
WHERE sale_date IS NOT NULL;

CREATE TABLE clickhouse.dwh.fact_sales
WITH (
  engine = 'MergeTree'
) AS
SELECT
  sale_key,
  source_system,
  source_row_id,
  customer_key,
  seller_key,
  product_key,
  store_key,
  supplier_key,
  sale_date_key,
  sale_customer_id,
  sale_seller_id,
  sale_product_id,
  sale_quantity,
  sale_total_price,
  product_price
FROM clickhouse.dwh.stg_sales;
