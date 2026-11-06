# Reconciliation

This document proves that data moved through the Bronze → Silver → Gold layers completely and correctly. Every record loaded is either retained in trusted reporting or accounted for as flagged, quarantined or excluded, with a reason.

> Fill every `TODO` with the real values from your pipeline run, then keep the queries in `validation/reconciliation_checks.sql`.

## 1. Reconciliation Objectives
- Source row count equals Bronze row count (nothing lost on ingestion).
- Bronze = Silver trusted + Silver excluded (every row is accounted for).
- Gold totals equal Silver trusted totals (aggregation introduced no drift).
- Every difference is explained.

## 2. Row Count Reconciliation

| Stage | Object | Row count | Notes |
|-------|--------|-----------|-------|
| Source | `sales.csv` | 1,506 | From the case study brief |
| Bronze | `bronze_sales` | `TODO` | Should equal source |
| Silver (all records) | `silver_sales` | `TODO` | Before exclusions, if flags are kept |
| Silver (trusted) | `silver_sales` where valid | `TODO` | Used by Gold |
| Excluded / quarantined | `TODO` | `TODO` | See breakdown below |

**Formula:**
`Bronze rows = Silver trusted rows + Excluded rows`
`1,506 = TODO + TODO`

## 3. Excluded and Flagged Records

| Reason | Rule ID | Count | Treatment | In Gold? |
|--------|---------|-------|-----------|----------|
| Exact duplicate rows | SLV-08 | `TODO` | Excluded (first occurrence kept) | No |
| Business-level duplicates | SLV-09 | `TODO` | `TODO` | `TODO` |
| Missing required values | SLV-04 | `TODO` | `TODO` | `TODO` |
| Zero/negative quantity | SLV-05 | `TODO` | Flagged | `TODO` |
| Negative unit price | SLV-06 | `TODO` | Flagged | `TODO` |
| Missing sales | SLV-07 | `TODO` | Flagged | `TODO` |
| **Total excluded** | | `TODO` | | |

> A record can break more than one rule, so flag counts may add up to more than the number of affected rows. Reconcile on distinct rows, not on flag totals.

## 4. Key Total Reconciliation

| Measure | Bronze | Silver (trusted) | Gold | Difference | Explained by |
|---------|--------|------------------|------|------------|--------------|
| Total sales | `TODO` | `TODO` | `TODO` | `TODO` | Excluded duplicates / flagged rows |
| Total profit | `TODO` | `TODO` | `TODO` | `TODO` | Same |
| Total quantity | `TODO` | `TODO` | `TODO` | `TODO` | Same |

**Pass criteria:** Silver trusted total = Gold total (difference = 0). Bronze vs. Silver differences must be fully explained by Section 3.

## 5. Gold Table Checks

| Gold table | Check | Expected | Actual | Status |
|------------|-------|----------|--------|--------|
| `gold_monthly_sales_trends` | Sum of monthly sales = Silver trusted sales | Equal | `TODO` | `TODO` |
| `gold_product_performance` | Sum across category/subcategory = Silver trusted sales | Equal | `TODO` | `TODO` |
| `gold_data_quality_summary` | Issue counts match Section 3 | Equal | `TODO` | `TODO` |

## 6. Validation Queries

Save these in `validation/reconciliation_checks.sql` and adjust the column and table names to match your schema.

```sql
-- 1. Row counts across layers
SELECT 'bronze' AS layer, COUNT(*) AS row_count FROM <catalog>.<schema>.bronze_sales
UNION ALL
SELECT 'silver_all', COUNT(*) FROM <catalog>.<schema>.silver_sales
UNION ALL
SELECT 'silver_trusted', COUNT(*) FROM <catalog>.<schema>.silver_sales
WHERE is_valid_for_reporting = true;   -- TODO: your trust flag
```

```sql
-- 2. Every Bronze row is accounted for
SELECT
  (SELECT COUNT(*) FROM <catalog>.<schema>.bronze_sales) AS bronze_rows,
  (SELECT COUNT(*) FROM <catalog>.<schema>.silver_sales
     WHERE is_valid_for_reporting = true)                AS silver_trusted,
  (SELECT COUNT(*) FROM <catalog>.<schema>.silver_sales
     WHERE is_valid_for_reporting = false)               AS silver_flagged_or_excluded;
```

```sql
-- 3. Sales total: Silver trusted vs. Gold monthly
SELECT
  s.silver_sales_total,
  g.gold_sales_total,
  s.silver_sales_total - g.gold_sales_total AS difference
FROM
  (SELECT SUM(sales) AS silver_sales_total
     FROM <catalog>.<schema>.silver_sales
     WHERE is_valid_for_reporting = true) s
CROSS JOIN
  (SELECT SUM(total_sales) AS gold_sales_total
     FROM <catalog>.<schema>.gold_monthly_sales_trends) g;
```

```sql
-- 4. Sales total: Gold monthly vs. Gold product performance
SELECT
  (SELECT SUM(total_sales) FROM <catalog>.<schema>.gold_monthly_sales_trends)   AS monthly_total,
  (SELECT SUM(total_sales) FROM <catalog>.<schema>.gold_product_performance)    AS product_total;
```

```sql
-- 5. Duplicate check on the business grain (should return 0 rows in trusted data)
SELECT order_id, product_id, order_date, customer_id, quantity, COUNT(*) AS cnt   -- TODO: your grain
FROM <catalog>.<schema>.silver_sales
WHERE is_valid_for_reporting = true
GROUP BY order_id, product_id, order_date, customer_id, quantity
HAVING COUNT(*) > 1;
```

## 7. Differences and Explanations

| Difference | Amount | Explanation |
|------------|--------|-------------|
| Bronze vs. Source rows | `TODO` | Expected 0 |
| Bronze vs. Silver trusted rows | `TODO` | Duplicates and rows excluded under the documented rules |
| Silver trusted vs. Gold totals | `TODO` | Expected 0 |

## 8. Sign-off Checklist

- [ ] Source row count = Bronze row count
- [ ] Bronze = Silver trusted + excluded
- [ ] All exclusions are listed with a reason and count
- [ ] Gold total sales = Silver trusted total sales
- [ ] Gold total profit = Silver trusted total profit
- [ ] No duplicate sales lines remain in trusted data
- [ ] Reconciliation re-run after a full pipeline refresh gives the same results

**Run date:** `TODO`  **Pipeline run ID:** `TODO`  **Result:** `TODO`

## 9. Rerun Behavior

The pipeline is repeatable: a full refresh must reproduce the same counts and totals. If numbers change between runs without a change in source data or rules, investigate before publishing.
