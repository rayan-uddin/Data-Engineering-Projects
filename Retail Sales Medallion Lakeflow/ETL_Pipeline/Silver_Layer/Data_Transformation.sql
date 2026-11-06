create or refresh materialized view cs_silver_sales (
    constraint valid_order_id expect (order_id is not null),
    constraint valid_customer_id expect (customer_id is not null),
    constraint valid_product_id expect (product_id is not null),
    constraint valid_quantity expect (quantity > 0),
    constraint valid_price expect (price > 0),
    constraint valid_order_date expect (order_date is not null),
    constraint valid_ship_date expect (ship_date is not null),
    constraint valid_sales expect (sales is not null)
)
comment "Silver Layer Data Transformation"
as
select
    trim(orderid) as order_id,
    orderdate as order_date,
    shipdate as ship_date,
    trim(shipmode) as ship_mode,
    trim(customerid) as customer_id,
    trim(customername) as customer_name,
    trim(customersegment) as customer_segment,
    trim(country) as country,
    trim(region) as region,
    trim(state) as state,
    trim(city) as city,
    postalcode as postal_code,
    trim(productid) as product_id,
    trim(productname) as product_name,
    trim(productcategory) as category,
    trim(productsubcategory) as subcategory,
    trim(brand) as brand,
    trim(supplier) as supplier,
    quantity as quantity,
    try_cast(unitprice as decimal(10,2)) as price,
    try_cast(discountpercent as decimal(5,2)) as discount_percent,
    try_cast(discountamount as decimal(10,2)) as discount_amount,
    try_cast(sales as decimal(10,2)) as sales,
    try_cast(unitcost as decimal(10,2)) as unit_cost,
    try_cast(totalcost as decimal(10,2)) as total_cost,
    try_cast(profit as decimal(10,2)) as profit,
    trim(paymentmethod) as payment_method,
    trim(saleschannel) as sales_channel,
    trim(salesrep) as sales_rep,
    trim(orderstatus) as order_status,
    returned as returned,
    customerrating as customer_rating,
    trim(currency) as currency,
    source_file,
    injected_at
from
    cs_bronze_sales

where trim(OrderID) is not null
    and trim(OrderID) != " "
    and try_cast(OrderDate as Date) is not null
    and try_cast(sales as decimal(10,2)) > 0
    and try_cast(Quantity as int) > 0
    and try_cast(Profit as decimal(10,2)) is not null

qualify row_number() over (
    partition by trim(orderid), trim(productID)
    order by injected_at desc
) = 1;