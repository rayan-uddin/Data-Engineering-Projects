# Reconciliation & Validation — Hospital Billing Analytics Platform

## Purpose
Reconciliation checks that the source records loaded into Bronze are accounted for after deduplication and validation. It also makes data-quality issues visible rather than hiding them during cleaning.

## Source baseline
The project brief describes a synthetic dataset with:
- 1,010 source rows
- 20 columns
- 330 patient visits in 2025
- One row per bill line

The brief expects Bronze to contain 1,010 rows after ingestion. Actual pipeline output counts are run-dependent and should be recorded after execution.

## Required reconciliation
The project brief defines the reconciliation equation as:

```text
Bronze rows = clean rows + rejected rows + duplicate rows removed
```

For the equation to be meaningful, each source row must belong to exactly one accounting bucket. If duplicate rows are also included in the rejected count, or if clean and rejected sets overlap, the equation will double-count records. Implement the pipeline's accounting logic so the buckets are mutually exclusive, and document the chosen order of operations.

## Metrics to capture

| Metric | Meaning |
|--------|---------|
| `bronze_rows` | Number of raw records ingested |
| `duplicate_rows` | Extra records removed under the `bill_id` uniqueness rule |
| `invalid_quantity_rows` | Rows with quantity zero or below |
| `negative_price_rows` | Rows with a negative unit price |
| `missing_department_rows` | Rows with missing department |
| `missing_payer_rows` | Rows with missing payer type |
| `missing_amount_rows` | Rows with missing total amount before derivation |
| `clean_rows` | Records retained in the clean Silver output |
| `rejected_rows` | Invalid records retained in the rejected Silver output |

The project brief's starter SQL includes some of these measures and asks the implementer to add the remaining missing-value and negative-price counts.

## Validation queries

Adapt table names to the catalog and schema configured for the pipeline.

### Bronze row count
```sql
SELECT COUNT(*) AS bronze_rows
FROM bronze_hospital_billing;
```

### Duplicate bill IDs
```sql
SELECT
    COUNT(*) - COUNT(DISTINCT bill_id) AS duplicate_rows
FROM bronze_hospital_billing;
```

### Check duplicate keys
```sql
SELECT
    bill_id,
    COUNT(*) AS row_count
FROM bronze_hospital_billing
GROUP BY bill_id
HAVING COUNT(*) > 1;
```

### Invalid quantities
```sql
SELECT COUNT(*) AS invalid_quantity_rows
FROM bronze_hospital_billing
WHERE quantity <= 0;
```

### Negative unit prices
```sql
SELECT COUNT(*) AS negative_price_rows
FROM bronze_hospital_billing
WHERE unit_price < 0;
```

### Clean output validity
```sql
SELECT
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity_rows,
    SUM(CASE WHEN unit_price < 0 THEN 1 ELSE 0 END) AS negative_price_rows,
    COUNT(*) - COUNT(DISTINCT bill_id) AS duplicate_bill_id_rows
FROM silver_billing_clean;
```

### Layer counts
```sql
SELECT 'bronze' AS layer, COUNT(*) AS row_count
FROM bronze_hospital_billing
UNION ALL
SELECT 'clean', COUNT(*)
FROM silver_billing_clean
UNION ALL
SELECT 'rejected', COUNT(*)
FROM silver_billing_rejected;
```

## Result recording

Populate this table after a successful pipeline run. Do not treat the expected source count as proof that the remaining counts have been validated.

| Check | Expected / actual result |
|-------|---------------------------|
| Source CSV rows | 1,010 (project brief baseline) |
| Bronze rows | To be recorded |
| Clean Silver rows | To be recorded |
| Rejected Silver rows | To be recorded |
| Duplicate rows removed | To be recorded |
| Reconciliation equation | Pass / Fail — to be recorded |
| Gold revenue agrees with clean Silver totals | Pass / Fail — to be recorded |

## Gold total validation
The monthly revenue Gold table should preserve the total revenue of the clean Silver dataset, subject to the same business definitions and filters.

```sql
SELECT SUM(total_amount) AS silver_total_revenue
FROM silver_billing_clean;

SELECT SUM(total_revenue) AS gold_total_revenue
FROM gold_monthly_revenue;
```

The two totals should agree. If they do not, inspect date handling, null amounts, filtering and aggregation logic.

## Acceptance checks
- Bronze contains the expected source rows.
- Duplicate bill lines are removed from the clean output.
- Invalid quantity and negative price rows are not present in clean Silver.
- Rejected rows are retained with a reason.
- Clean, rejected and duplicate-removed buckets account for Bronze without overlap.
- Gold revenue totals agree with the clean Silver data.
