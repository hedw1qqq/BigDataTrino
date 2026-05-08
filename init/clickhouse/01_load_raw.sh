#!/usr/bin/env bash
set -euo pipefail

clickhouse client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" -n <<'SQL'
CREATE DATABASE IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.mock_data
(
  id String,
  customer_first_name String,
  customer_last_name String,
  customer_age String,
  customer_email String,
  customer_country String,
  customer_postal_code String,
  customer_pet_type String,
  customer_pet_name String,
  customer_pet_breed String,
  seller_first_name String,
  seller_last_name String,
  seller_email String,
  seller_country String,
  seller_postal_code String,
  product_name String,
  product_category String,
  product_price String,
  product_quantity String,
  sale_date String,
  sale_customer_id String,
  sale_seller_id String,
  sale_product_id String,
  sale_quantity String,
  sale_total_price String,
  store_name String,
  store_location String,
  store_city String,
  store_state String,
  store_country String,
  store_phone String,
  store_email String,
  pet_category String,
  product_weight String,
  product_color String,
  product_size String,
  product_brand String,
  product_material String,
  product_description String,
  product_rating String,
  product_reviews String,
  product_release_date String,
  product_expiry_date String,
  supplier_name String,
  supplier_contact String,
  supplier_email String,
  supplier_phone String,
  supplier_address String,
  supplier_city String,
  supplier_country String
)
ENGINE = MergeTree
ORDER BY tuple();

TRUNCATE TABLE raw.mock_data;
SQL

for file in \
  "/data/MOCK_DATA.csv" \
  "/data/MOCK_DATA (1).csv" \
  "/data/MOCK_DATA (2).csv" \
  "/data/MOCK_DATA (3).csv" \
  "/data/MOCK_DATA (4).csv"
do
  clickhouse client \
    --user "$CLICKHOUSE_USER" \
    --password "$CLICKHOUSE_PASSWORD" \
    --query "INSERT INTO raw.mock_data FORMAT CSVWithNames" < "$file"
done
