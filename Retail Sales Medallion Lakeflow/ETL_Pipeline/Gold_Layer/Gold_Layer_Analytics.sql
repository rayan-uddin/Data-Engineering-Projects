-- ============================================
-- GOLD: DATA QUALITY SUMMARY
-- ============================================

create or refresh materialized view gold_dq_summary
comment "Data Quality Summary: Row Count accross pipeline layers"
as

select
    'Bronze (raw)' as layer,
    'Raw Records from CSV' as description,
    count(*) as row_count
from cs_bronze_sales

union

select
    'silver (clean)' as layer,
    'Valid deduplicated records' as description,
    count(*) as row_count
from cs_silver_sales;

-- =======================================================
-- GOLD MONTHLY SALES TREND
-- =======================================================

create or refresh materialized view gold_monthly_sales
comment "Gold layer Monthly Sales Trend"
as
select
    year(order_date) as order_year,
    month(order_date) as order_month,
    count(*) as order_count,
    sum(sales) as total_sales,
    sum(profit) as total_profit,
    avg(sales) as avg_sales,
    sum(quantity) as total_quantity
from cs_silver_sales
group by all;

-- =======================================================
-- INDIVIDUAL PRODUCT PERFORMANCE METRIC
-- =======================================================
create or refresh materialized view gold_category_performance
comment "GOLD LAYER: Individual Product Performance Metrics"
as
select
    product_id,
    product_name,
    category,
    subcategory,
    count(*) as order_count,
    sum(quantity) as total_quantity,
    sum(sales) as total_sales,
    sum(profit) as total_profit,
    avg(sales) as avg_sale,
    avg(profit) as avg_profit,
    avg(customer_rating) as avg_customer_rating,
    round(
        sum(profit) / nullif(sum(sales), 0) * 100, 2
    ) as profit_margin
from cs_silver_sales
group by all 
order by total_sales desc;


-- =======================================================
-- SALES AND PROFIT BY PRODUCT CATEGORY AND SUB-CATEGORY
-- =======================================================
create or refresh materialized view gold_sales_profit_by_category
comment "GOLD LAYER Sales and Profit by category and sub-category"
select
    category as product_category,
    subcategory as product_sub_category,
    count(*) as order_count,
    sum(quantity) as total_quantity,
    sum(sales) as total_sales,
    sum(profit) as total_profit,
    avg(sales) as avg_sale,
    avg(profit) as avg_profit
from cs_silver_sales
group by all
order by total_sales desc;


-- =======================================================
-- GEOGRAPHIC PERFORMANCE
-- =======================================================
create or refresh materialized view gold_region_performance
comment "Compare sales and profitability across available regions, states or cities"
as
select 
    region,
    state,
    city,
    count(*) as order_count,
    sum(quantity) as total_quantity,
    sum(sales) as total_sales,
    sum(profit) as total_profit,
    avg(sales) as avg_sale,
    avg(profit) as avg_profit,
    round(
        sum(profit) / nullif(sum(sales), 0) * 100, 2
    ) as profit_margin
from cs_silver_sales
group by all
order by region, state, city, total_sales desc;



create or refresh materialized view gold_segment_performance
comment "Review performance by customer segment or other available customer attributes"
as
select
    customer_segment,
    count(*) as order_count,
    sum(profit) as total_profit,
    sum(sales) as total_sales,
    avg(sales) as avg_sale,
    avg(profit) as avg_profit,
    round(
        sum(profit) / nullif(sum(sales), 0) * 100
    ) as profit_margin
    from cs_silver_sales
group by all
order by customer_segment, total_sales desc;


-- =======================================================
-- CHANNEL PERFORMANCE
-- =======================================================
create or refresh materialized view gold_channel_performance
comment "Compare channels or order types if those fields exist in the supplied dataset."
as
select
    sales_channel,
    count(*) as order_count,
    sum(sales) as total_sales,
    sum(profit) as total_profit,
    avg(sales) as avg_sales,
    avg(profit) as avg_profit,
    round(
        sum(profit) / nullif(sum(sales), 0) * 100, 2
    ) as profit_margin
from cs_silver_sales
group by all
order by sales_channel, total_sales desc;


-- =======================================================
-- QUALITY VISIBILITY SUMMARY
-- =======================================================

create or refresh materialized view gold_reconciliation
comment "GOLD LAYER: Show missing, invalid, duplicate and suspicious record counts"
as
select
    'missing' as quality,
    count(*) as record_count
from cs_bronze_sales
where OrderID is null
   or OrderID is null
   or sales is null
   or OrderID is null
   or region is null

union all

select
    'invalid' as quality,
    count(*) as record_count
from cs_bronze_sales
where sales < 0
   or quantity <= 0
   or profit > sales
   or OrderDate > current_date()

union all

select
    'duplicate' as quality,
    count(*) - count(distinct OrderID) as record_count
from cs_bronze_sales

union all

select
    'suspicious' as quality,
    count(*) as record_count
from cs_silver_sales
where round(profit / nullif(sales, 0) * 100, 2) not between -100 and 100
   or customer_rating not between 1 and 5