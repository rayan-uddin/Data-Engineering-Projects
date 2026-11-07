# Business Requirements — Hospital Billing Analytics Platform

## Purpose
This document records the business requirements defined in the Hospital Billing Data Engineering Project brief. The pipeline turns hospital billing CSV data into trusted summaries for management reporting.

## Business context
The hospital chain has six branches across three regions in India. Visits may be Outpatient, Inpatient or Emergency. Each visit can generate multiple bill lines for consultations, lab tests, scans, procedures, pharmacy items or room charges. Payments may be made through Self Pay, Private Insurance, Government Scheme or Corporate arrangements.

The current reporting process is manual and affected by inconsistent text, missing values, duplicate records and invalid quantities or prices.

## Requirements

| ID | Requirement | Expected output |
|----|-------------|-----------------|
| BR-01 | Monthly revenue | Total revenue, insurance amount and visits for each month |
| BR-02 | Department performance | Revenue, visits and average revenue per visit by department |
| BR-03 | Branch performance | Revenue and visits by region, city and hospital branch |
| BR-04 | Payer analysis | Revenue, insurance amount and pending amount by payer type |
| BR-05 | Data-quality visibility | Counts of duplicates, invalid quantity/price and missing values |
| BR-06 | Reconciliation | Demonstrate that Bronze rows are accounted for as clean, rejected or duplicate-removed rows |
| BR-07 | Repeatability | Run the pipeline again through Lakeflow with one click |
| BR-08 | Dashboard | One dashboard built from Gold tables in Databricks AI/BI or Power BI |

## Gold table mapping

| Gold object | Business purpose | Key measures / dimensions |
|-------------|------------------|---------------------------|
| `gold_monthly_revenue` | BR-01 | Visit month, visits, total revenue, insurance amount |
| `gold_department_summary` | BR-02 | Department, visits, bills, total revenue, average revenue per visit |
| `gold_branch_summary` | BR-03 | Region, city, hospital branch, visits, total revenue |
| `gold_payer_summary` | BR-04 | Payer type, visits, total revenue, insurance amount, pending amount |
| `gold_data_quality` | BR-05 and BR-06 | Bronze rows, duplicate rows, issue counts, clean rows, rejected rows |

## Dashboard requirements
The dashboard is expected to contain three pages:

1. **Overview:** total revenue, visits, insurance covered and pending amount; monthly revenue trend; revenue by department.
2. **Branch & Payer:** revenue by branch or region; revenue versus insurance by payer; payer detail table.
3. **Data Quality:** Bronze, clean, rejected and duplicate counts; reconciliation status; data-problem counts.

Only one dashboard tool is required: Databricks AI/BI or Power BI.

## Definition of Done
- The source CSV is loaded from a Unity Catalog Volume and Bronze contains 1,010 rows.
- Silver clean contains standardized, deduplicated records with no invalid quantity or negative price.
- Rejected rows are retained with a rejection reason.
- The four business Gold tables answer BR-01 through BR-04.
- `gold_data_quality` supports data-quality visibility and reconciliation.
- The reconciliation condition is satisfied.
- The pipeline can be rerun and produces consistent results.
- The dashboard contains the three required pages and agrees with the Gold tables.

## Scope boundaries
Included: one synthetic CSV, batch ingestion, Bronze/Silver/Gold pipeline in SQL, data-quality checks, reconciliation and one dashboard.

Excluded: real patient data, real-time processing, multiple source systems, advanced dimensional modelling (including SCD) and production alerting.
