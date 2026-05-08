CREATE SCHEMA IF NOT EXISTS clickhouse.reports;

DROP TABLE IF EXISTS clickhouse.reports.report_product_sales;
DROP TABLE IF EXISTS clickhouse.reports.report_customer_sales;
DROP TABLE IF EXISTS clickhouse.reports.report_time_sales;
DROP TABLE IF EXISTS clickhouse.reports.report_store_sales;
DROP TABLE IF EXISTS clickhouse.reports.report_supplier_sales;
DROP TABLE IF EXISTS clickhouse.reports.report_product_quality;

CREATE TABLE clickhouse.reports.report_product_sales
WITH (
  engine = 'MergeTree'
) AS
WITH product_stats AS (
  SELECT
    p.product_name,
    p.product_category,
    lower(to_hex(md5(to_utf8(concat_ws('|',
      coalesce(p.product_name, ''),
      coalesce(p.product_category, '')
    ))))) AS product_group_key,
    count(*) AS orders_count,
    count(DISTINCT p.product_key) AS product_variants_count,
    sum(coalesce(f.sale_quantity, 0)) AS total_quantity_sold,
    sum(coalesce(f.sale_total_price, CAST(0 AS decimal(14, 2)))) AS total_revenue,
    avg(p.product_rating) AS avg_product_rating,
    sum(coalesce(p.product_reviews, 0)) AS total_product_reviews
  FROM clickhouse.dwh.fact_sales f
  JOIN clickhouse.dwh.dim_product p ON f.product_key = p.product_key
  GROUP BY
    p.product_name,
    p.product_category
)
SELECT
  product_group_key,
  product_name,
  product_category,
  orders_count,
  product_variants_count,
  total_quantity_sold,
  total_revenue,
  sum(total_revenue) OVER (PARTITION BY product_category) AS category_total_revenue,
  avg_product_rating,
  total_product_reviews,
  rank() OVER (ORDER BY total_quantity_sold DESC, total_revenue DESC) AS product_rank_by_quantity
FROM product_stats;

CREATE TABLE clickhouse.reports.report_customer_sales
WITH (
  engine = 'MergeTree'
) AS
WITH customer_stats AS (
  SELECT
    c.customer_key,
    c.customer_first_name,
    c.customer_last_name,
    c.customer_email,
    c.customer_country,
    count(*) AS orders_count,
    sum(coalesce(f.sale_quantity, 0)) AS total_items_bought,
    sum(coalesce(f.sale_total_price, CAST(0 AS decimal(14, 2)))) AS total_purchase_amount,
    avg(f.sale_total_price) AS avg_check
  FROM clickhouse.dwh.fact_sales f
  JOIN clickhouse.dwh.dim_customer c ON f.customer_key = c.customer_key
  GROUP BY
    c.customer_key,
    c.customer_first_name,
    c.customer_last_name,
    c.customer_email,
    c.customer_country
)
SELECT
  customer_key,
  customer_first_name,
  customer_last_name,
  customer_email,
  customer_country,
  orders_count,
  total_items_bought,
  total_purchase_amount,
  avg_check,
  count(*) OVER (PARTITION BY customer_country) AS customers_in_country,
  rank() OVER (ORDER BY total_purchase_amount DESC) AS customer_rank_by_amount
FROM customer_stats;

CREATE TABLE clickhouse.reports.report_time_sales
WITH (
  engine = 'MergeTree'
) AS
WITH month_stats AS (
  SELECT
    d.year_number,
    d.month_number,
    d.month_start_date,
    count(*) AS orders_count,
    sum(coalesce(f.sale_quantity, 0)) AS total_quantity_sold,
    sum(coalesce(f.sale_total_price, CAST(0 AS decimal(14, 2)))) AS total_revenue,
    avg(f.sale_total_price) AS avg_order_amount
  FROM clickhouse.dwh.fact_sales f
  JOIN clickhouse.dwh.dim_date d ON f.sale_date_key = d.date_key
  GROUP BY
    d.year_number,
    d.month_number,
    d.month_start_date
)
SELECT
  year_number,
  month_number,
  month_start_date,
  orders_count,
  total_quantity_sold,
  total_revenue,
  avg_order_amount,
  lag(total_revenue) OVER (ORDER BY month_start_date) AS previous_month_revenue,
  total_revenue - coalesce(lag(total_revenue) OVER (ORDER BY month_start_date), CAST(0 AS decimal(14, 2))) AS revenue_change_from_previous_month,
  sum(total_revenue) OVER (PARTITION BY year_number) AS year_total_revenue
FROM month_stats;

CREATE TABLE clickhouse.reports.report_store_sales
WITH (
  engine = 'MergeTree'
) AS
WITH store_location_stats AS (
  SELECT
    s.store_name,
    s.store_city,
    s.store_country,
    count(*) AS orders_count,
    sum(coalesce(f.sale_quantity, 0)) AS total_quantity_sold,
    sum(coalesce(f.sale_total_price, CAST(0 AS decimal(14, 2)))) AS total_revenue,
    avg(f.sale_total_price) AS avg_check
  FROM clickhouse.dwh.fact_sales f
  JOIN clickhouse.dwh.dim_store s ON f.store_key = s.store_key
  GROUP BY
    s.store_name,
    s.store_city,
    s.store_country
),
store_totals AS (
  SELECT
    store_name,
    sum(orders_count) AS store_orders_count,
    sum(total_quantity_sold) AS store_quantity_sold,
    sum(total_revenue) AS store_total_revenue,
    sum(total_revenue) / sum(orders_count) AS store_avg_check
  FROM store_location_stats
  GROUP BY store_name
)
SELECT
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(sls.store_name, ''),
    coalesce(sls.store_city, ''),
    coalesce(sls.store_country, '')
  ))))) AS store_location_key,
  lower(to_hex(md5(to_utf8(coalesce(sls.store_name, ''))))) AS store_group_key,
  sls.store_name,
  sls.store_city,
  sls.store_country,
  sls.orders_count AS location_orders_count,
  sls.total_quantity_sold AS location_quantity_sold,
  sls.total_revenue AS location_revenue,
  sls.avg_check AS location_avg_check,
  st.store_orders_count,
  st.store_quantity_sold,
  st.store_total_revenue,
  st.store_avg_check,
  sum(sls.total_revenue) OVER (PARTITION BY sls.store_city) AS city_total_revenue,
  sum(sls.total_revenue) OVER (PARTITION BY sls.store_country) AS country_total_revenue,
  rank() OVER (ORDER BY st.store_total_revenue DESC) AS store_rank_by_revenue
FROM store_location_stats sls
JOIN store_totals st ON sls.store_name = st.store_name;

CREATE TABLE clickhouse.reports.report_supplier_sales
WITH (
  engine = 'MergeTree'
) AS
WITH supplier_country_stats AS (
  SELECT
    sp.supplier_name,
    sp.supplier_country,
    count(*) AS orders_count,
    sum(coalesce(f.sale_quantity, 0)) AS total_quantity_sold,
    sum(coalesce(f.sale_total_price, CAST(0 AS decimal(14, 2)))) AS total_revenue,
    avg(f.product_price) AS avg_product_price
  FROM clickhouse.dwh.fact_sales f
  JOIN clickhouse.dwh.dim_supplier sp ON f.supplier_key = sp.supplier_key
  GROUP BY
    sp.supplier_name,
    sp.supplier_country
),
supplier_totals AS (
  SELECT
    supplier_name,
    sum(orders_count) AS supplier_orders_count,
    sum(total_quantity_sold) AS supplier_quantity_sold,
    sum(total_revenue) AS supplier_total_revenue,
    avg(avg_product_price) AS supplier_avg_product_price
  FROM supplier_country_stats
  GROUP BY supplier_name
)
SELECT
  lower(to_hex(md5(to_utf8(concat_ws('|',
    coalesce(scs.supplier_name, ''),
    coalesce(scs.supplier_country, '')
  ))))) AS supplier_country_key,
  lower(to_hex(md5(to_utf8(coalesce(scs.supplier_name, ''))))) AS supplier_group_key,
  scs.supplier_name,
  scs.supplier_country,
  scs.orders_count AS country_orders_count,
  scs.total_quantity_sold AS country_quantity_sold,
  scs.total_revenue AS country_revenue,
  scs.avg_product_price AS country_avg_product_price,
  st.supplier_orders_count,
  st.supplier_quantity_sold,
  st.supplier_total_revenue,
  st.supplier_avg_product_price,
  sum(scs.total_revenue) OVER (PARTITION BY scs.supplier_country) AS supplier_country_total_revenue,
  rank() OVER (ORDER BY st.supplier_total_revenue DESC) AS supplier_rank_by_revenue
FROM supplier_country_stats scs
JOIN supplier_totals st ON scs.supplier_name = st.supplier_name;

CREATE TABLE clickhouse.reports.report_product_quality
WITH (
  engine = 'MergeTree'
) AS
WITH product_stats AS (
  SELECT
    p.product_name,
    p.product_category,
    lower(to_hex(md5(to_utf8(concat_ws('|',
      coalesce(p.product_name, ''),
      coalesce(p.product_category, '')
    ))))) AS product_group_key,
    avg(p.product_rating) AS avg_rating,
    sum(coalesce(p.product_reviews, 0)) AS total_product_reviews,
    sum(coalesce(f.sale_quantity, 0)) AS total_quantity_sold,
    sum(coalesce(f.sale_total_price, CAST(0 AS decimal(14, 2)))) AS total_revenue
  FROM clickhouse.dwh.fact_sales f
  JOIN clickhouse.dwh.dim_product p ON f.product_key = p.product_key
  GROUP BY
    p.product_name,
    p.product_category
),
quality_correlation AS (
  SELECT
    corr(avg_rating, CAST(total_quantity_sold AS double)) AS rating_sales_correlation
  FROM product_stats
)
SELECT
  ps.product_group_key,
  ps.product_name,
  ps.product_category,
  ps.avg_rating,
  ps.total_product_reviews,
  ps.total_quantity_sold,
  ps.total_revenue,
  qc.rating_sales_correlation,
  rank() OVER (ORDER BY ps.avg_rating DESC, ps.total_product_reviews DESC) AS rating_rank_desc,
  rank() OVER (ORDER BY ps.avg_rating ASC, ps.total_product_reviews ASC) AS rating_rank_asc,
  rank() OVER (ORDER BY ps.total_product_reviews DESC) AS reviews_rank_desc
FROM product_stats ps
CROSS JOIN quality_correlation qc;
