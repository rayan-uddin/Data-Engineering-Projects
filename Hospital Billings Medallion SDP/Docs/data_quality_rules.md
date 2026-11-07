# Data Quality Rules — Hospital Billing Analytics Platform

## Objective
The Silver layer standardizes hospital billing records, retains valid billing information, and separates records that violate the stated quantity or price rules. The raw source remains available in Bronze for traceability.

## Dataset grain and key
- **Grain:** one bill line per row.
- **Uniqueness key:** `bill_id` should be unique for each real bill line.
- **Not a uniqueness key:** `visit_id`, because one visit can have several bill lines.

## Rules

| Issue | Example / condition | Treatment | SQL concept |
|------|---------------------|-----------|-------------|
| Duplicate bill line | Same `bill_id` appears more than once | Keep one copy | `SELECT DISTINCT` / deduplication by `bill_id` |
| Extra spaces | `" cardiology "` | Trim leading and trailing spaces | `TRIM()` |
| Inconsistent capitalization | `"PRIVATE INSURANCE"` | Standardize text to title case | `INITCAP()` |
| Missing department | Null or blank department | Replace with `Unknown` | `COALESCE()` after blank normalization |
| Missing payer type | Null or blank payer | Replace with `Unknown` | `COALESCE()` after blank normalization |
| Missing total amount | Null `total_amount` | Calculate `quantity * unit_price` | `COALESCE(total_amount, quantity * unit_price)` |
| Missing patient ID | Blank `patient_id` | Retain the row; revenue can still be valid | No change |
| Invalid quantity | `quantity <= 0` | Exclude from clean output and retain in rejected output | Lakeflow expectation / rejection filter |
| Negative unit price | `unit_price < 0` | Exclude from clean output and retain in rejected output | Lakeflow expectation / rejection filter |

## Text-cleaning pattern
Apply trimming before title casing:

```sql
INITCAP(TRIM(column_name))
```

For fields that should receive a fallback value, normalize empty strings to null before applying `COALESCE`. The project brief explicitly names department and payer type as fields to fill with `Unknown`.

## Amount derivation
When `total_amount` is missing, derive it from the billed quantity and unit price:

```sql
COALESCE(total_amount, quantity * unit_price)
```

This follows the project brief's definition of `total_amount` as quantity multiplied by unit price. Do not overwrite a supplied non-null total based solely on this rule.

## Validity expectations
The project brief specifies these Lakeflow expectations for the clean table:

```sql
CONSTRAINT valid_quantity
  EXPECT (quantity > 0) ON VIOLATION DROP ROW,

CONSTRAINT valid_unit_price
  EXPECT (unit_price >= 0) ON VIOLATION DROP ROW
```

The rejected table should preserve invalid source records and add a human-readable `reject_reason`, such as:
- `Quantity is zero or negative`
- `Unit price is negative`

## Implementation considerations
- Apply the same normalization rules consistently to department, service category, city and payer type where applicable.
- Ensure empty strings are treated as blanks; `COALESCE` alone does not replace an empty string.
- Ensure rejected records and duplicate-removed records are accounted for without overlap in reconciliation.
- Keep Bronze unchanged so that cleaning decisions can be reviewed against the original source.

## Validation checklist
- [ ] `bill_id` is unique in the clean output.
- [ ] Department and payer type do not remain null or blank; missing values are represented as `Unknown`.
- [ ] Relevant text fields have been trimmed and standardized.
- [ ] Missing total amounts are derived from quantity and unit price.
- [ ] Blank patient IDs are retained.
- [ ] Clean output contains no rows with `quantity <= 0`.
- [ ] Clean output contains no rows with `unit_price < 0`.
- [ ] Rejected rows include a rejection reason.
- [ ] Quality counts reconcile with Bronze.
