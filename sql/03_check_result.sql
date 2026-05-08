SELECT 'clickhouse.raw.mock_data' AS object_name, count(*) AS rows_count
FROM clickhouse.raw.mock_data

UNION ALL

SELECT 'postgresql.raw.mock_data' AS object_name, count(*) AS rows_count
FROM postgresql.raw.mock_data

UNION ALL

SELECT 'dwh.stg_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.dwh.stg_sales

UNION ALL

SELECT 'dwh.fact_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.dwh.fact_sales

UNION ALL

SELECT 'reports.report_product_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.reports.report_product_sales

UNION ALL

SELECT 'reports.report_customer_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.reports.report_customer_sales

UNION ALL

SELECT 'reports.report_time_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.reports.report_time_sales

UNION ALL

SELECT 'reports.report_store_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.reports.report_store_sales

UNION ALL

SELECT 'reports.report_supplier_sales' AS object_name, count(*) AS rows_count
FROM clickhouse.reports.report_supplier_sales

UNION ALL

SELECT 'reports.report_product_quality' AS object_name, count(*) AS rows_count
FROM clickhouse.reports.report_product_quality
ORDER BY object_name;

SELECT
  product_rank_by_quantity,
  product_name,
  product_category,
  total_quantity_sold,
  total_revenue
FROM clickhouse.reports.report_product_sales
WHERE product_rank_by_quantity <= 10
ORDER BY product_rank_by_quantity, product_name;
