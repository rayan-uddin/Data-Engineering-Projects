create or refresh materialized view hospital_billings_sdp.default.silver_hospital_billings
(
    constraint valid_quantity expect (quantity > 0) ON VIOLATION DROP ROW,
    constraint valid_amount expect (total_amount > 0) ON VIOLATION DROP ROW
) 
as select 
    distinct bill_id,
    patient_id,
    visit_id,
    coalesce(initcap(trim(department)), 'unknown') as department,
    initcap(trim(patient_gender)) as patient_gender,
    patient_age,
    visit_date,
    initcap(trim(visit_type)) as visit_type,
    initcap(trim(doctor_name)) as doctor_name,
    initcap(trim(service_category)) as service_category,
    initcap(trim(service_name)) as service_name,
    initcap(trim(hospital_branch)) as hospital_branch,
    initcap(trim(city)) as city,
    initcap(trim(region)) as region,
    initcap(trim(payer_type)) as payer_type,
    quantity,
    unit_price,
    coalesce(total_amount, quantity * unit_price) as total_amount,
    insurance_amount,
    payment_status
from hospital_billings_sdp.default.hospital_billings_bronze;

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.silver_hospital_billings_rejected
AS
SELECT *,
    CASE
        WHEN quantity <= 0 THEN 'Quantity is zero or negative'
        WHEN COALESCE(total_amount, quantity * unit_price) <= 0
            THEN 'Total amount is zero or negative'
    END AS reject_reason
FROM hospital_billings_sdp.default.hospital_billings_bronze
WHERE quantity <= 0
   OR COALESCE(total_amount, quantity * unit_price) <= 0;