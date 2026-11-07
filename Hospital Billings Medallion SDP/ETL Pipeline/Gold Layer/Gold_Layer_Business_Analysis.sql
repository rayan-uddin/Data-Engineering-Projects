
-- =============================================================================
-- MONTHLY REVENUE
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_monthly_revenue
COMMENT "Show total revenue, insurance amount and visits for each month"
AS
SELECT
    MONTH(visit_date) AS Visit_Month,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    AVG(total_amount) AS Avg_Revenue,
    AVG(insurance_amount) AS Avg_Insurance,
    COUNT(visit_id) AS Total_Visits
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Visit_Month;


-- =============================================================================
-- DEPARTMENT PERFORMANCE
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_department_performance
COMMENT "Compare revenue, visits and average revenue per visit by department"
AS
SELECT
    department,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    AVG(total_amount) AS Avg_Revenue_per_visit,
    COUNT(visit_id) AS Total_Visits
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Total_Revenue DESC;


-- =============================================================================
-- BRANCH PERFORMANCE
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_branch_performance
COMMENT "Compare revenue and visits by region, city and branch"
AS
SELECT
    region,
    city,
    hospital_branch AS branch,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    AVG(total_amount) AS Avg_Revenue_per_visit,
    COUNT(visit_id) AS Total_Visits
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL;


-- =============================================================================
-- PAYER ANALYSIS
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_payer_analysis
COMMENT "Compare revenue, insurance amount and pending amount by payer type."
AS
SELECT
    payer_type,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    SUM(CASE WHEN payment_status = 'Pending'
        THEN total_amount ELSE 0 END) AS Pending_Amount
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL;


-- =============================================================================
-- DATA-QUALITY VISIBILITY
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_dq_visibility
COMMENT "Show how many rows had each problem (duplicates, bad quantity, bad price, blanks)."
AS
SELECT
    b.bronze_rows,
    b.duplicate_rows,
    b.invalid_quantity_rows,
    b.missing_department_rows,
    b.invalid_price_rows,
    b.invalid_amount,
    b.missing_payer_type_rows,
    s.clean_rows,
    r.rejected_rows
FROM
    (
        SELECT
            COUNT(*) AS bronze_rows,
            COUNT(*) - COUNT(DISTINCT bill_id) AS duplicate_rows,
            SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity_rows,
            SUM(CASE WHEN department IS NULL THEN 1 ELSE 0 END) AS missing_department_rows,
            SUM(CASE WHEN unit_price < 0 THEN 1 ELSE 0 END) AS invalid_price_rows,
            SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS invalid_amount,
            SUM(CASE WHEN payer_type IS NULL THEN 1 ELSE 0 END) AS missing_payer_type_rows
        FROM hospital_billings_sdp.default.hospital_billings_bronze
    ) b
CROSS JOIN
    (
        SELECT COUNT(*) AS clean_rows
        FROM hospital_billings_sdp.default.silver_hospital_billings
    ) s
CROSS JOIN
    (
        SELECT COUNT(*) AS rejected_rows
        FROM hospital_billings_sdp.default.silver_hospital_billings_rejected
    ) r;


-- =============================================================================
-- PATIENT DEMOGRAPHICS
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_patient_demographics
COMMENT "Compare revenue and visits by patient gender and age group"
AS
SELECT
    patient_gender,
    CASE
        WHEN patient_age < 18 THEN 'Child (0-17)'
        WHEN patient_age < 30 THEN 'Young Adult (18-29)'
        WHEN patient_age < 50 THEN 'Adult (30-49)'
        WHEN patient_age < 65 THEN 'Middle-Aged (50-64)'
        ELSE 'Senior (65+)'
    END AS age_group,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    AVG(total_amount) AS Avg_Revenue_per_visit,
    COUNT(visit_id) AS Total_Visits
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Total_Revenue DESC;


-- =============================================================================
-- DOCTOR PERFORMANCE
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_doctor_performance
COMMENT "Compare revenue, visits and average revenue per visit by doctor"
AS
SELECT
    doctor_name,
    COUNT(DISTINCT department) AS Departments_Served,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    AVG(total_amount) AS Avg_Revenue_per_visit,
    COUNT(visit_id) AS Total_Visits
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Total_Revenue DESC;


-- =============================================================================
-- SERVICE ANALYSIS
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_service_analysis
COMMENT "Compare revenue, volume and average price by service category and service"
AS
SELECT
    service_category,
    service_name,
    SUM(total_amount) AS Total_Revenue,
    SUM(quantity) AS Total_Quantity,
    AVG(unit_price) AS Avg_Unit_Price,
    COUNT(visit_id) AS Total_Visits
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Total_Revenue DESC;


-- =============================================================================
-- PAYMENT STATUS BREAKDOWN
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_payment_status
COMMENT "Compare billed, insurance-covered and pending revenue by payment status"
AS
SELECT
    payment_status,
    COUNT(visit_id) AS Total_Visits,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Amount,
    SUM(total_amount - insurance_amount) AS Patient_Liability,
    ROUND(SUM(total_amount) * 100.0 / SUM(SUM(total_amount)) OVER (), 2) AS Revenue_Share_Pct
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Total_Revenue DESC;


-- =============================================================================
-- OUT-OF-POCKET PATIENT LIABILITY
-- =============================================================================

CREATE OR REFRESH MATERIALIZED VIEW
hospital_billings_sdp.default.gold_out_of_pocket
COMMENT "Compare patient out-of-pocket liability (total minus insurance) by region, city and branch"
AS
SELECT
    region,
    city,
    hospital_branch AS branch,
    COUNT(visit_id) AS Total_Visits,
    SUM(total_amount) AS Total_Revenue,
    SUM(insurance_amount) AS Insurance_Covered,
    SUM(total_amount - insurance_amount) AS Out_Of_Pocket,
    ROUND(SUM(total_amount - insurance_amount) * 100.0 / SUM(total_amount), 2) AS Out_Of_Pocket_Pct
FROM hospital_billings_sdp.default.silver_hospital_billings
GROUP BY ALL
ORDER BY Out_Of_Pocket DESC;
