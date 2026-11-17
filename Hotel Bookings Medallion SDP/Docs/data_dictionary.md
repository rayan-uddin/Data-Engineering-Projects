# Dataset Overview and Data Dictionary

## Dataset profile

The supplied project brief describes a synthetic dataset named `hotel_bookings_raw.csv`.

| Attribute | Description |
|---|---|
| Rows | 1,316 |
| Columns | 20 |
| Period | Hotel stays in 2025 |
| Grain | One row per booking |
| Identifier | `booking_id` |
| Data type | Synthetic; no real guest data |

The CSV is expected to be uploaded to a Unity Catalog Volume before ingestion.

## Column dictionary

| Column | Example | Description |
|---|---|---|
| `booking_id` | `BK300001` | Unique ID of one booking |
| `guest_id` | `GU5321` | Guest who booked; sometimes blank |
| `booking_date` | `2025-04-02` | Date the booking was made |
| `check_in_date` | `2025-04-20` | Arrival date |
| `check_out_date` | `2025-04-23` | Departure date |
| `nights` | `3` | Number of nights; sometimes blank |
| `hotel_name` | `Sea Breeze Resort` | Hotel name |
| `city` | `Goa` | Hotel city; sometimes blank or inconsistent |
| `region` | `West` | Region: North, South or West |
| `room_type` | `Deluxe` | Standard, Deluxe, Suite or Family Room |
| `booking_channel` | `Mobile App` | Website, Mobile App, Travel Agent or Walk In |
| `guests` | `2` | Number of guests |
| `room_rate` | `5200.00` | Price per night in INR |
| `total_amount` | `15600.00` | Nights multiplied by room rate; sometimes blank |
| `discount_amount` | `780.00` | Discount given |
| `meal_plan` | `Breakfast` | Room Only, Breakfast or Half Board |
| `payment_method` | `UPI` | UPI, Card, Cash or Net Banking |
| `payment_status` | `Paid` | Paid, Pending or Refunded |
| `booking_status` | `Completed` | Completed or Cancelled |
| `guest_rating` | `4` | Rating from 1 to 5; blank for cancelled stays |

> The brief states that the dataset has 20 columns. The dictionary above lists the business fields explicitly described in the brief; confirm the exact CSV header row before defining the final table schema.

## Business formulas

```text
nights = DATEDIFF(check_out_date, check_in_date)

total_amount = nights × room_rate

net_revenue = total_amount − discount_amount
              (Completed bookings only)

room_nights = SUM(nights)
              (Completed bookings only)

ADR = net_revenue ÷ room_nights
```

## Important interpretation

- `booking_id` is the booking-level identifier used to detect duplicate booking records.
- `guest_id` is not a substitute for `booking_id`: one guest may make multiple bookings.
- A cancelled booking is a valid business event and should remain in Silver.
- Guest ratings may be NULL. A missing rating should not be converted to zero because zero is not a valid rating in the described 1–5 scale.
