create or refresh materialized view hotel_bookings_sdp.default.hotel_bookings_silver(
  CONSTRAINT valid_stay_dates EXPECT (check_out_date > check_in_date) ON VIOLATION DROP ROW,
  CONSTRAINT valid_room_rate  EXPECT (room_rate >= 0)                 ON VIOLATION DROP ROW
)
as
select
    distinct booking_id,
    guest_id,
    booking_date,
    check_in_date,
    check_out_date,
    coalesce(nights, datediff(check_out_date, check_in_date)) as nights,
    initcap(trim(hotel_name)) as hotel_name,
    coalesce(city, 'Unknown') as city,
    initcap(trim(region)) as region,
    initcap(trim(room_type)) as room_type,
    initcap(trim(booking_channel)) as booking_channel,
    guests,
    room_rate,
    coalesce(total_amount, nights * room_rate) as total_amount,
    discount_amount,
    initcap(trim(meal_plan)) as meal_plan,
    initcap(trim(payment_method)) as payment_method,
    initcap(trim(payment_status)) as payment_status,
    initcap(trim(booking_status)) as booking_status,
    guest_rating
from hotel_bookings_sdp.default.hotel_bookings_bronze;

create or refresh materialized view hotel_bookings_sdp.default.hotel_bookings_silver_rejected
as
SELECT *,
  CASE WHEN check_out_date <= check_in_date THEN 'Check-out is not after check-in'
       ELSE 'Room rate is negative' END AS reject_reason
FROM hotel_bookings_bronze
WHERE check_out_date <= check_in_date OR room_rate < 0;