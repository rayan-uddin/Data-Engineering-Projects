# Project Review Questions and Answers

Answers to the eight review questions from the Retail Sales Medallion case study, written in the context of this project (Lakeflow Spark Declarative Pipelines on Azure Databricks).

---

## 1. Why do we preserve raw data in Bronze instead of cleaning the source immediately?

Bronze is the system of record for what actually arrived. Keeping it unchanged gives us:

- **Traceability:** any cleaned value in Silver or Gold can be traced back to the original source record.
- **Reprocessability:** if a cleaning rule turns out to be wrong (for example, a "negative price" was really a refund), we fix the rule and rebuild Silver and Gold from Bronze, without asking for the file again.
- **Auditability:** we can show exactly what was received, what was changed and why.
- **Safe experimentation:** new rules or models can be tested without risking the source data.

If we cleaned the source immediately, the original values would be lost, and we could not prove or undo any decision.

---

## 2. What is the difference between a data-quality flag and rejecting a record?

| | Flag | Reject / exclude |
|---|------|------------------|
| What happens | The record stays in the dataset, marked as suspicious | The record is removed from trusted reporting (and quarantined or counted) |
| Use when | The value is unusual but possibly legitimate (zero quantity, negative price) | The record is certainly unusable or redundant (exact duplicate, unparseable data) |
| Risk | Flagged rows may still reach reports if not filtered | Valid data may be lost if the rule is too aggressive |
| Reversible | Yes | Yes, as long as Bronze is preserved |

In this project, suspicious business values are **flagged for investigation**, and exact duplicates are **excluded** with the counts reported in the data quality summary.

---

## 3. Why is Order ID alone potentially unsafe as a duplicate key?

One order can contain **several product lines**, so the same Order ID legitimately appears on multiple rows. Treating Order ID as unique would wrongly delete valid lines and understate sales.

Duplicates should be detected at the **sales-line grain**: Order ID combined with fields that identify the line, such as product, order date, customer, quantity and price. `TODO: replace with your actual key columns.`

Exact duplicates (every column identical) are checked separately from business-level duplicates.

---

## 4. How would you investigate a negative unit price or zero quantity?

1. **Isolate** the flagged rows in Silver and compare them with the raw Bronze record.
2. **Check related fields:** do sales, discount and profit agree with the odd value? A negative quantity with negative sales often indicates a return.
3. **Look for patterns** by product, category, region, channel or date. A cluster points to a systematic cause, while scattered rows suggest data-entry errors.
4. **Check for business explanations:** returns, refunds, price adjustments, promotions or system defaults.
5. **Decide and document:** keep and flag, correct under a documented rule, or exclude. Update `data_quality_rules.md`.
6. **Escalate** to the data owner if the cause cannot be determined from the data alone.

The key principle: do not assume every unusual value is invalid.

---

## 5. How can you prove that the Gold sales total is consistent with the cleaned Silver data?

By running **reconciliation queries** that compare totals across layers:

- `SUM(sales)` from Silver trusted records vs. `SUM(total_sales)` from each Gold table. The difference must be **0**.
- Monthly Gold total vs. product-performance Gold total. They must agree, since both come from the same Silver data.
- Row counts: Bronze = Silver trusted + excluded, with every exclusion explained.

The queries and results are in `validation/reconciliation_checks.sql` and `docs/reconciliation.md`. Re-running them after a full pipeline refresh should give identical results.

---

## 6. What would change if new files arrived every day?

- **Ingestion:** switch to incremental file discovery with **Auto Loader** (`cloud_files`) on the Volume path, so only new files are processed. The streaming table `bronze_sales` is already a good fit for this.
- **Deduplication across files:** duplicates can now span days, so the business-key dedup must consider existing Silver data, not just the current batch.
- **Idempotency:** reprocessing the same file must not double-count. Track source file names and ingestion timestamps.
- **Scheduling:** run the pipeline on a schedule or trigger it on file arrival.
- **Monitoring:** add alerts for failed runs, schema changes and unusual quality-flag rates.
- **Schema evolution:** handle new or changed columns using rescued-data handling.
- **Gold:** materialized views refresh incrementally, so Gold stays current without full rebuilds.

---

## 7. When would you introduce separate customer and product dimension tables?

When the flat sales table starts to cause problems:

- Customer or product attributes (name, segment, category) are **repeated** on millions of rows and change over time.
- Multiple fact tables (sales, returns, inventory) need to share **consistent** definitions.
- You need **history** of attribute changes, such as a customer changing segment (slowly changing dimensions).
- Reporting tools and analysts want a **star schema** for easier, faster joins.
- Several source systems feed the same entities, so master data must be managed in one place.

For a single 1,506-row file, a flat model is enough. Dimensions are a Phase 2 improvement.

---

## 8. How could this batch pipeline evolve toward incremental or streaming processing?

1. **Incremental batch:** use Auto Loader for Bronze and keep Silver and Gold as materialized views that refresh incrementally. This is partly in place already.
2. **Micro-batch streaming:** convert Silver to a streaming table to process new records continuously with sub-minute or minute latency.
3. **True streaming:** read from an event source such as Kafka or Event Hubs instead of files, with watermarking for late data.
4. **Supporting changes:** stateful deduplication, handling of late and out-of-order records, checkpointing, and monitoring of lag and throughput.
5. **Operational maturity:** SLAs, alerting and automated deployment (CI/CD) for the pipeline.

Phase 1 intentionally stays batch-oriented so the design can be validated before adding complexity.

---

> **Note:** items marked `TODO` should be filled in with the actual column names and details from your SQL.
