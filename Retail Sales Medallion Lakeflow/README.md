# Retail Sales Analytics Platform: Medallion Architecture with Lakeflow Spark Declarative Pipelines

An end-to-end retail sales ETL pipeline on **Azure Databricks**, built with **Lakeflow Spark Declarative Pipelines (SQL)** and the **Medallion Architecture** (Bronze → Silver → Gold). It turns a raw, messy sales CSV into trusted, business-ready reporting tables, with data-quality tracking and reconciliation across layers.

![Architecture](images/architecture.png)

## Table of Contents
- [Business Problem](#business-problem)
- [Architecture](#architecture)
- [Pipeline Lineage](#pipeline-lineage)
- [Tech Stack](#tech-stack)
- [Dataset](#dataset)
- [Repository Structure](#repository-structure)
- [Layer Details](#layer-details)
- [Data Quality Rules](#data-quality-rules)
- [Reconciliation](#reconciliation)
- [How to Run](#how-to-run)
- [Business Requirements Coverage](#business-requirements-coverage)
- [Key Learnings](#key-learnings)
- [Future Improvements](#future-improvements)

## Business Problem
A mid-sized omnichannel retailer receives sales data as CSV files. Reporting is slow and unreliable because of inconsistent category text, missing values, duplicate rows, and zero/negative quantities or prices. Manual spreadsheet cleanup is not repeatable.

**Goal:** build a repeatable, managed pipeline that preserves the raw data, standardizes and validates records, and publishes trusted Gold tables for sales and profitability analysis.

## Architecture
`sales.csv` (Unity Catalog Volume) → **Bronze** (raw, traceable) → **Silver** (cleaned, validated) → **Gold** (business aggregates) → Databricks SQL / dashboards / BI tools

| Layer | Purpose | Key actions |
|-------|---------|-------------|
| Bronze | Preserve source data | Load CSV, keep original values, add ingestion metadata |
| Silver | Improve trust and consistency | Trim text, standardize categories, cast types, flag invalid values, handle duplicates |
| Gold | Serve business questions | Monthly trends, product performance, data-quality summary |

## Pipeline Lineage
![Pipeline lineage](images/pipeline_lineage.png)

| Object | Type | Description |
|--------|------|-------------|
| `bronze_sales` | Streaming table | Raw ingested sales records |
| `silver_sales` | Materialized view | Cleaned and validated records |
| `gold_monthly_sales_trends` | Materialized view | Sales and profit by month |
| `gold_product_performance` | Materialized view | Sales, quantity and profit by category/subcategory |
| `gold_data_quality_summary` | Materialized view | Issue counts and validation status (reads Bronze and Silver) |

Materialized views refresh **incrementally** where possible.

## Tech Stack
- Azure Databricks
- Lakeflow Spark Declarative Pipelines (SQL)
- Unity Catalog (Volumes)
- Delta Lake
- Databricks SQL

## Dataset
Synthetic retail sales dataset: **1,506 rows × 33 columns**, with intentionally injected quality issues (whitespace, missing values, duplicates, zero quantities, negative prices, missing sales values).

> The grain is one sales line per row. **Order ID alone is not unique**, because one order can contain multiple product lines.

## Repository Structure
```
├── README.md
├── data/                      # sample dataset
├── pipeline/
│   ├── bronze/bronze_transformation.sql
│   ├── silver/silver_transformation.sql
│   └── gold/gold_transformation.sql
├── validation/                # reconciliation queries
├── docs/                      # case study, DQ rules, review answers
└── images/                    # architecture and screenshots
```

## Layer Details

### Bronze
- Reads the CSV from a Unity Catalog Volume: `TODO: /Volumes/<catalog>/<schema>/<volume>/sales.csv`
- Keeps source values unchanged
- Adds ingestion metadata: `TODO: e.g. _ingest_timestamp, _source_file`

### Silver
- `TODO:` trimming and standardization of category and subcategory
- `TODO:` type casting (dates, quantity, price, sales, profit)
- `TODO:` quality flags and duplicate handling
- `TODO:` pipeline expectations (`CONSTRAINT ... EXPECT ...`)

### Gold
- `gold_monthly_sales_trends`: sales and profit by month
- `gold_product_performance`: category and subcategory comparison
- `gold_data_quality_summary`: missing, invalid, duplicate and suspicious counts

## Data Quality Rules
| Rule | Treatment |
|------|-----------|
| Completeness | Missing values in required fields are identified, not silently replaced |
| Standardization | Leading/trailing spaces removed; category values standardized |
| Type validity | Date, quantity, price, sales and profit cast to proper types |
| Business validity | Zero/negative quantity and negative price are **flagged for investigation**, not blindly dropped |
| Duplicates | Exact duplicates and business-level duplicates detected at sales-line grain |
| Auditability | Raw data is always retained in Bronze |

Details: [`docs/data_quality_rules.md`](docs/data_quality_rules.md)

## Reconciliation
| Check | Result |
|-------|--------|
| Source CSV rows | 1,506 |
| Bronze rows | `TODO` |
| Silver rows (trusted) | `TODO` |
| Excluded/quarantined rows | `TODO` (reason: `TODO`) |
| Gold total sales = Silver total sales | `TODO` |

Queries: [`validation/`](validation/)

## How to Run
1. Upload `sales.csv` to a Unity Catalog Volume and confirm read permissions.
2. Clone this repo into your Databricks workspace (Repos / Git folder).
3. Create a new **Lakeflow Spark Declarative Pipeline** and add the SQL files under `pipeline/` as source code.
4. Set the target catalog and schema: `TODO`.
5. Run the pipeline (**Start** or **Full refresh**).
6. Run the checks in `validation/` and query the Gold tables.

## Business Requirements Coverage
| ID | Requirement | Status |
|----|-------------|--------|
| BR-01 | Sales trend | `gold_monthly_sales_trends` |
| BR-02 | Product performance | `gold_product_performance` |
| BR-03 | Geographic performance | `TODO` |
| BR-04 | Customer analysis | `TODO` |
| BR-05 | Sales-channel analysis | `TODO` |
| BR-06 | Data-quality visibility | `gold_data_quality_summary` |
| BR-07 | Reconciliation | `validation/` |
| BR-08 | Repeatability | Managed Lakeflow pipeline |

## Key Learnings
- Why raw data is preserved in Bronze for traceability
- Flagging vs. rejecting records
- Why Order ID is an unsafe duplicate key
- Declarative pipelines with data-quality expectations and lineage

## Future Improvements
- Daily file arrival with Auto Loader and incremental processing
- Separate customer and product dimension tables
- Alerts and monitoring on data-quality metrics
- Dashboard on top of the Gold layer

## License
MIT (see `LICENSE`)
