# Customer Churn Analysis & Customer Intelligence

An exploratory data analysis project focused on understanding customer churn, retention, subscription plans, revenue at risk, and customer-support signals using Python, Pandas, SQLite, Matplotlib, and Seaborn.

## Project Overview

Customer churn occurs when customers stop using or cancel a service. This project combines customer, subscription, and support data to calculate churn-related KPIs, explore patterns across subscription plans and locations, and examine whether support escalations are associated with churn.

The analysis is implemented in the Jupyter Notebook: [`churn_analysis.ipynb`](./churn_analysis.ipynb).

## Objectives

- Prepare and clean customer, subscription, and customer-support data.
- Combine related tables using customer IDs.
- Create a churn flag and customer churn-risk categories.
- Calculate key business metrics for churn, retention, revenue, and support.
- Visualize churn patterns to help identify areas for further investigation.

## Tools & Technologies

- **Python** — analysis and feature engineering
- **Pandas** — data cleaning, transformation, merging, and aggregation
- **NumPy** — conditional columns and numerical operations
- **SQLite** — relational database storage and table import
- **Matplotlib** — charts and trend visualizations
- **Seaborn** — statistical visualization and correlation heatmap
- **Jupyter Notebook** — interactive analysis

## Repository Contents

| File | Description |
|---|---|
| `churn_analysis.ipynb` | Main notebook containing data preparation, feature engineering, KPI calculations, and visualizations |
| `customer_churn.db` | SQLite database containing the project tables |
| `customer_churn_data_raw.xlsx` | Raw Excel workbook used as the source dataset and as an alternative way to rebuild the SQLite database |

The notebook loads three tables from the database: customer, subscription, and support data.

## Workflow

1. **Load the data** from the SQLite database into Pandas DataFrames. The notebook also includes code to recreate the database from the Excel workbook if needed.
2. **Clean the data**, including renaming columns, removing unused fields, converting date columns, standardizing gender values, and filling missing country values where a state-to-country mapping is available.
3. **Prepare the analysis dataset** by creating a churn flag from cancellation dates, checking and handling support-table duplicates, and joining the customer, subscription, and support tables.
4. **Engineer features**, including customer tenure and churn-risk categories based on the available churn score.
5. **Calculate KPIs** to summarize churn, retention, subscription-plan performance, revenue at risk, and support activity.
6. **Visualize patterns** using Matplotlib and Seaborn.

## Key Metrics & Findings

The notebook currently reports the following results for the supplied dataset:

| Metric | Result |
|---|---:|
| Churn rate | 28.57% |
| Retention rate | 71.43% |
| Average monthly charges (ARPU proxy) | 18.85 |
| Average customer tenure | Approximately 1,452 days |
| Revenue at risk from churned customers (sum of monthly charges) | 73.94 |
| Support escalation rate | 19.05% |
| Average complaints per customer | 0.43 |

### Churn rate by plan type

| Plan type | Churn rate |
|---|---:|
| Basic | 60.00% |
| Standard | 22.22% |
| Premium | 14.29% |

The notebook also calculates a correlation of **0.77** between the escalation indicator and churn flag in the prepared dataset. This is an exploratory association, not evidence that escalations cause churn. The dataset is small, so these results should be treated as illustrative rather than generalized business benchmarks.

> **Metric note:** The notebook labels the average of `monthly_charges` as ARPU and reports revenue at risk as the sum of monthly charges for churned customers. These are the calculations currently implemented in the notebook; the units and business definitions should be confirmed before interpreting them as financial results.

## Visualizations

The notebook includes visual analysis such as:

- Monthly churn trend
- Churn rate by subscription plan
- Churn rate by state
- Correlation heatmap for selected numerical features

## How to Run the Project

### 1. Clone the repository

```bash
git clone https://github.com/aditikhare137/Complete-Data-Analytics-Portfolio-Project-Python-SQL-.git
cd Complete-Data-Analytics-Portfolio-Project-Python-SQL-
```

### 2. Install the required libraries

Make sure Python is installed, then run:

```bash
pip install pandas numpy matplotlib seaborn openpyxl jupyter
```

SQLite support is provided through Python's built-in `sqlite3` module.

### 3. Open the notebook

```bash
jupyter notebook churn_analysis.ipynb
```

Run the cells from top to bottom. Keep the notebook, database, and Excel workbook in the same project directory so the relative file paths work.

If the SQLite database cannot be loaded, use the notebook's included database-creation section to build `customer_churn.db` from `customer_churn_data_raw.xlsx`.

## Potential Next Steps

- Add SQL queries for business questions and document them separately from the Python analysis.
- Investigate churn by contract type, subscription type, geography, and customer tenure.
- Validate joins and duplicate handling to ensure each metric uses the intended customer-level grain.
- Define revenue metrics and currency units explicitly.
- Add a concise executive summary with business recommendations supported by the analysis.
- Consider a dashboard in Power BI to make the KPIs easier to explore.

## Author

**Aditi Khare**

Data Analytics Portfolio Project

---

This project is intended for learning and portfolio demonstration. Findings depend on the supplied dataset and the transformations performed in the notebook.
