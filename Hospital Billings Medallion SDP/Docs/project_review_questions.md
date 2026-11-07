# Project Review Questions — Hospital Billing Analytics Platform

These questions are based on the review section of the Hospital Billing Data Engineering Project brief. The answers are concise prompts for explaining the design; adapt them to match the implementation you actually completed.

## 1. Why do we keep the raw data in Bronze instead of cleaning the file directly?
Bronze preserves the original source records. It provides traceability and allows the cleaning logic to be reviewed or rerun without losing the original input.

## 2. What is the difference between removing a row and putting it in the rejected table?
Removing a row from the clean output prevents it from being used in trusted analytics. Putting it in a rejected table preserves the record and its rejection reason so the issue can be investigated.

## 3. Why can `bill_id` find duplicates but `visit_id` cannot?
The dataset grain is one bill line per row, and `bill_id` is expected to be unique for each bill line. A single visit can contain multiple bill lines, so `visit_id` is not unique.

## 4. Why do we use `TRIM` before `INITCAP`?
`TRIM` removes leading and trailing spaces first. `INITCAP` then standardizes the capitalization of the cleaned text.

## 5. Why is it OK to fill a blank `total_amount` with `quantity * unit_price`?
The project defines total amount as quantity multiplied by unit price. If the total is missing but both input values are available and valid, it can be derived using that calculation.

## 6. How does the reconciliation check prove that no row was lost?
It compares the Bronze source count with the mutually exclusive counts of clean records, rejected records and duplicate records removed. If the buckets cover every source row exactly once, the counts reconcile.

## 7. Why does the dashboard read Gold tables instead of Bronze?
Gold tables contain business-ready aggregates. They simplify dashboard queries and ensure visuals use the cleaned and validated data rather than raw source records.

## 8. Which dashboard tool did you choose, and why?
The project brief allows either Databricks AI/BI or Power BI. Explain the tool actually used and relate the choice to the project's reporting and sharing needs.

## Additional implementation questions

### What is the difference between a streaming table and a materialized view in this project?
The project uses a streaming table for Bronze ingestion and materialized views for Silver and Gold transformations. The streaming table reads new files incrementally; materialized views store query results that the pipeline maintains.

### What is a Lakeflow expectation?
An expectation is a data-quality rule applied to pipeline data. In this project, expectations validate that quantity is greater than zero and unit price is non-negative.

### Why is a blank patient ID retained?
The project brief says the bill can still be valid for revenue analysis even when the patient ID is blank. Therefore, the row is retained rather than rejected for that reason.

### What is the purpose of the Gold data-quality table?
It reports counts of source data problems and layer-level row counts so that data quality and reconciliation can be reviewed alongside business metrics.
