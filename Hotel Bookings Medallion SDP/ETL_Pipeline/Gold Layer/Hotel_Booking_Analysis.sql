-- =========================================================
-- ===================GOLD MONTHLY REVENUE==================
-- =========================================================

CREATE OR REFRESH MATERIALIZED VIEW hotel_bookings_sdp.default.gold_monthly_bookings AS
SELECT DATE_TRUNC('MONTH', check_in_date)                          AS stay_month,
       COUNT(*)                                                    AS bookings,
       SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END)  AS cancelled_bookings,
       SUM(CASE WHEN booking_status = 'Completed' THEN nights ELSE 0 END) AS room_nights,
       SUM(CASE WHEN booking_status = 'Completed'
                THEN total_amount - discount_amount ELSE 0 END)     AS net_revenue
FROM hotel_bookings_sdp.default.hotel_bookings_silver
GROUP BY DATE_TRUNC('MONTH', check_in_date);

-- =========================================================
-- ====================HOTEL PERFORMANCE====================
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.hotel_performance as
select
        hotel_name,
        region,
        city,
        DATE_TRUNC('MONTH', check_in_date) as stay_month,
        count(*) as bookings,
        sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
        sum(case when booking_status = 'Completed' then nights else 0 end) as room_nights,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) / sum(case when booking_status = 'Completed' then nights else 0 end) as adr
from hotel_bookings_sdp.default.hotel_bookings_silver
group by hotel_name, region, city, stay_month;

-- =========================================================
-- ==================ROOM TYPE PERFORMANCE==================
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.room_performance as
select 
        room_type,
        count(*) as bookings,
        sum(case when booking_status = 'Completed' then 1 else 0 end) as completed_bookings,
        sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue,
        sum(case when booking_status = 'Completed' then nights else 0 end) as room_nights,
        round(avg(guest_rating),1) as Avg_Customer_Rating
from hotel_bookings_sdp.default.hotel_bookings_silver
group by room_type
order by bookings desc;

-- =========================================================
-- ==================CHANNEL ANALYSIS==================
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.channel_analysis as
select
        booking_channel,
        count(*) as bookings,
        sum(case when booking_status = 'Completed' then 1 else 0 end) as completed_bookings,
        sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue,
        round(sum(case when booking_status = 'Cancelled' then 1 else 0 end) * 100.0 / count(*),2) as cancellation_rate
from hotel_bookings_sdp.default.hotel_bookings_silver
group by booking_channel
order by bookings desc;

-- =========================================================
-- ==================DATA QUALITY VISIBILITY==================
-- =========================================================

CREATE OR REFRESH MATERIALIZED VIEW hotel_bookings_sdp.default.gold_data_quality AS
SELECT 
        COUNT(*) AS bronze_rows,
        COUNT(*) - COUNT(DISTINCT booking_id) AS duplicate_rows,
        SUM(CASE WHEN check_out_date <= check_in_date THEN 1 ELSE 0 END) AS invalid_date_rows,
        SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS missing_city_rows,
        sum(case when booking_status = 'Cancelled' and total_amount > 0 THEN 1 ELSE 0 END) AS negative_amount_rows,
        SUM(CASE WHEN booking_channel IS NULL THEN 1 ELSE 0 END) AS missing_channel_rows,
        SUM(CASE WHEN nights IS NULL THEN 1 ELSE 0 END) AS missing_nights_rows,
        SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS missing_amount_rows,
        (SELECT COUNT(*) FROM hotel_bookings_sdp.default.hotel_bookings_silver) AS clean_rows,
        (SELECT COUNT(*) FROM hotel_bookings_sdp.default.hotel_bookings_silver_rejected) AS rejected_rows
FROM hotel_bookings_sdp.default.hotel_bookings_bronze;

-- =========================================================
-- ================Q: BOOKING LEAD TIME======================
-- How far in advance do guests book, and how does the
-- booking window affect volume, completion and revenue?
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.gold_lead_time_analysis as
select
        case
            when datediff(check_in_date, booking_date) <= 7  then '0-7 days'
            when datediff(check_in_date, booking_date) <= 30 then '8-30 days'
            when datediff(check_in_date, booking_date) <= 90 then '31-90 days'
            else '90+ days'
        end as booking_window,
        count(*) as bookings,
        sum(case when booking_status = 'Completed' then 1 else 0 end) as completed_bookings,
        sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
        round(sum(case when booking_status = 'Cancelled' then 1 else 0 end) * 100.0 / count(*), 2) as cancellation_rate,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue
from hotel_bookings_sdp.default.hotel_bookings_silver
where booking_date is not null
  and datediff(check_in_date, booking_date) >= 0
group by booking_window
order by min(datediff(check_in_date, booking_date));

-- =========================================================
-- ================Q: REGION & CITY PERFORMANCE==============
-- Which regions and cities drive revenue, room nights and
-- average daily rate?
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.gold_region_performance as
select
        region,
        city,
        count(*) as bookings,
        sum(case when booking_status = 'Completed' then 1 else 0 end) as completed_bookings,
        sum(case when booking_status = 'Completed' then nights else 0 end) as room_nights,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end)
          / nullif(sum(case when booking_status = 'Completed' then nights else 0 end), 0) as adr,
        round(avg(guest_rating), 1) as avg_customer_rating
from hotel_bookings_sdp.default.hotel_bookings_silver
group by region, city
order by net_revenue desc;

-- =========================================================
-- ================Q: DAY-OF-WEEK SEASONALITY================
-- Which check-in weekdays are busiest and most profitable?
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.gold_day_of_week_performance as
select
        date_format(check_in_date, 'EEEE') as check_in_day,
        count(*) as bookings,
        sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled_bookings,
        sum(case when booking_status = 'Completed' then nights else 0 end) as room_nights,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue
from hotel_bookings_sdp.default.hotel_bookings_silver
group by date_format(check_in_date, 'EEEE')
order by net_revenue desc;

-- =========================================================
-- ================Q: PAYMENT BEHAVIOUR======================
-- How do payment methods split by status, cancellations and
-- realised (net) revenue?
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.gold_payment_analysis as
select
        payment_method,
        payment_status,
        count(*) as bookings,
        sum(case when booking_status = 'Completed' then 1 else 0 end) as completed_bookings,
        round(sum(case when booking_status = 'Cancelled' then 1 else 0 end) * 100.0 / count(*), 2) as cancellation_rate,
        sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue
from hotel_bookings_sdp.default.hotel_bookings_silver
group by payment_method, payment_status
order by payment_method, net_revenue desc;

-- =========================================================
-- ================Q: GUEST LOYALTY==========================
-- How much of the business comes from repeat guests versus
-- one-time guests?
-- =========================================================

create or refresh materialized view hotel_bookings_sdp.default.gold_guest_loyalty as
select
        case when total_bookings > 1 then 'Repeat guest' else 'One-time guest' end as guest_type,
        count(*) as guests,
        sum(total_bookings) as bookings,
        sum(completed_bookings) as completed_bookings,
        sum(net_revenue) as net_revenue,
        round(sum(net_revenue) / nullif(count(*), 0), 2) as revenue_per_guest
from (
    select
            guest_id,
            count(*) as total_bookings,
            sum(case when booking_status = 'Completed' then 1 else 0 end) as completed_bookings,
            sum(case when booking_status = 'Completed' then total_amount - discount_amount else 0 end) as net_revenue
    from hotel_bookings_sdp.default.hotel_bookings_silver
    group by guest_id
)
group by guest_type;
