# Data Quality Rules

This document describes the data-quality (DQ) rules applied in the Retail Sales Medallion pipeline, how each issue is treated, and where it is enforced.

> **Principle:** Raw data is never modified. Issues are **flagged** and made visible. Records are only **excluded** from trusted reporting when a documented rule says so, and every exclusion is counted and explained.

## 1. Known Issues in the Source Data

The source file (`sales.csv`, 1,506 rows × 33 columns) is synthetic and contains intentionally injected problems:

| # | Issue | Example |
|---|-------|---------|
| 1 | Leading/trailing whitespace | `" Furniture "` instead of `"Furniture"` |
| 2 | Inconsistent category/subcategory text | Mixed casing or spacing |
| 3 | Missing values in key fields | Null or blank sales, category, etc. |
| 4 | Exact duplicate rows | Same row repeated |
| 5 | Business-level duplicates | Same sales line repeated with different noise |
| 6 | Zero or negative quantity | `Quantity = 0` or `< 0` |
| 7 | Negative unit price | `Unit Price < 0` |
| 8 | Missing sales values | `Sales` is null |
| 9 | Invalid data types | Non-numeric text in numeric columns, bad dates |

## 2. Rules by Layer

### Bronze: preserve
| Rule ID | Rule | Treatment |
|---------|------|-----------|
| BRZ-01 | Source values are kept as-is | No trimming, casting or filtering |
| BRZ-02 | Ingestion metadata added | `TODO: e.g. _ingest_timestamp, _source_file` |
| BRZ-03 | Row count must match the source | Verified in reconciliation |

### Silver: standardize, validate, flag
| Rule ID | Dimension | Rule | Treatment | Action |
|---------|-----------|------|-----------|--------|
| SLV-01 | Standardization | Trim leading/trailing spaces on all text fields | `TRIM()` | Fix |
| SLV-02 | Standardization | Standardize category and subcategory (consistent case, spacing) | `TODO: e.g. INITCAP(TRIM(...))` | Fix |
| SLV-03 | Type validity | Cast date, quantity, unit price, sales, discount and profit to proper types | `TRY_CAST` / `CAST` | Fix, with failed casts flagged |
| SLV-04 | Completeness | Required fields must not be null or blank: `TODO: list fields` | Flag; **no silent replacement** | Flag |
| SLV-05 | Business validity | Quantity ≤ 0 | Flag for investigation | Flag |
| SLV-06 | Business validity | Unit price < 0 | Flag for investigation | Flag |
| SLV-07 | Completeness | Sales is null | Flag; recompute only if a documented rule exists (`TODO`) | Flag |
| SLV-08 | Duplicates | Exact duplicate rows | Keep the first occurrence; count the rest | Exclude |
| SLV-09 | Duplicates | Business-level duplicates at sales-line grain | Key: `TODO: e.g. order_id + product_id + order_date + customer_id + quantity` | Flag/Exclude |

> **Order ID alone is not a valid duplicate key.** One order can contain several product lines.

### Gold: only trusted data
| Rule ID | Rule | Treatment |
|---------|------|-----------|
| GLD-01 | Aggregations use only Silver records that pass trust criteria (`TODO: e.g. is_valid = true`) | Filter |
| GLD-02 | Gold totals must reconcile to Silver totals | Verified in reconciliation |
| GLD-03 | DQ summary reports counts for every issue type | `gold_data_quality_summary` |

## 3. Flag vs. Reject

| | **Flag** | **Reject / Exclude** |
|---|---------|----------------------|
| Meaning | Record is kept and marked as suspicious | Record is removed from trusted reporting |
| Use when | The value is unusual but could be legitimate (e.g. a return with negative quantity) | The record is certainly unusable or redundant (e.g. exact duplicate) |
| Visible in | Silver quality-flag columns, DQ summary | Quarantine table `TODO`, DQ summary, reconciliation |
| Reversible | Yes, rule can change later | Yes, since raw data stays in Bronze |

## 4. Quality Flag Columns (Silver)

| Column | Type | Description |
|--------|------|-------------|
| `TODO: is_missing_required` | boolean | Any required field is null or blank |
| `TODO: is_invalid_quantity` | boolean | Quantity ≤ 0 |
| `TODO: is_negative_price` | boolean | Unit price < 0 |
| `TODO: is_missing_sales` | boolean | Sales is null |
| `TODO: is_exact_duplicate` | boolean | Repeat of an identical row |
| `TODO: is_business_duplicate` | boolean | Repeat at sales-line grain |
| `TODO: is_valid_for_reporting` | boolean | Passes all trust criteria |

## 5. Pipeline Expectations (Lakeflow)

If you use declarative expectations, document them here:

```sql
-- TODO: replace with your actual constraints
CONSTRAINT valid_quantity EXPECT (quantity > 0)          ON VIOLATION DROP ROW,
CONSTRAINT valid_price    EXPECT (unit_price >= 0),
CONSTRAINT has_category   EXPECT (category IS NOT NULL)
```

| Expectation | Behavior |
|-------------|----------|
| `EXPECT (...)` | Violations are recorded in metrics; rows are kept |
| `ON VIOLATION DROP ROW` | Violating rows are dropped and counted |
| `ON VIOLATION FAIL UPDATE` | The pipeline stops on violation |

## 6. Investigating Suspicious Values

For a negative unit price or zero quantity:

1. Pull the flagged rows and compare them with the raw Bronze record.
2. Check related fields (sales, discount, profit) for consistency.
3. Check whether it looks like a return, refund, adjustment or data-entry error.
4. Look for a pattern by product, region, channel or date.
5. Decide, document the decision here, and update the rule if needed.

## 7. Issue Summary (fill after the pipeline run)

| Issue | Rule ID | Count | Treatment |
|-------|---------|-------|-----------|
| Whitespace in text fields | SLV-01 | `TODO` | Trimmed |
| Missing required values | SLV-04 | `TODO` | Flagged |
| Zero/negative quantity | SLV-05 | `TODO` | Flagged |
| Negative unit price | SLV-06 | `TODO` | Flagged |
| Missing sales | SLV-07 | `TODO` | Flagged |
| Exact duplicates | SLV-08 | `TODO` | Excluded |
| Business-level duplicates | SLV-09 | `TODO` | `TODO` |

## 8. Assumptions and Decisions

- Missing values are **not** imputed unless a rule above says so.
- Unusual values are flagged first, not assumed invalid.
- `TODO:` add any further assumptions (e.g. currency, date format, timezone).
