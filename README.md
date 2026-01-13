
# Data Warehouse and Analytics Project 

Welcome to the Data Warehouse and Analytics Project repository! 🚀
This project demonstrates an end-to-end data warehousing and analytics solution, from building a SQL Server–based data warehouse to generating meaningful analytical insights.

## High-Level Data Warehouse Architecture (Medallion Architecture)

| Layer    | Description                     | Object Type | Load Strategy                         | Transformations                                   | Data Model        |
|----------|---------------------------------|-------------|----------------------------------------|---------------------------------------------------|-------------------|
| Sources  | ERP & CRM source systems (CSV)  | Files       | File-based ingestion                   | None                                              | Source format     |
| Bronze   | Raw, as-is data                 | Tables      | Full Load, Truncate & Insert           | None                                              | As-Is             |
| Silver   | Cleaned & standardized data     | Tables      | Full Load, Truncate & Insert           | Cleansing, standardization, derived columns       | As-Is             |
| Gold     | Business-ready data             | Views       | No Load                                | Aggregations, business logic, integrations        | Star Schema       |
| Consume  | Analytics & insights            | BI Tools    | Read-Only                              | Reporting, ad-hoc analysis, machine learning      | Semantic Layer    |

**Bronze Layer**: Stores raw data exactly as received from the source systems. Data is loaded from CSV files into the SQL Server database without transformations.
**Silver Layer**: Focuses on cleaning and standardizing the data by applying validation, normalization, and consistency rules to make it ready for analysis.
*Gold Layer*: Contains business-ready data modeled using a star schema to support reporting, analytics, and decision-making.
**Project Overview**

This project covers the full data lifecycle, including:

1. ***Data Architecture*** Designing a modern data warehouse using the Medallion Architecture (Bronze, Silver, and Gold layers).
2. ***ETL Pipelines*** Extracting, transforming, and loading data from source systems into a centralized warehouse.
3. ***Data Modeling*** Building fact and dimension tables optimized for analytical and reporting queries.
4. ***Analytics & Reporting*** Creating SQL-based analytical queries to support business insights and decision-making.
   
This repository showcases practical skills in:
- **SQL Development** – Writing optimized queries and validations
- **Data Architecture** – Designing medallion architecture (Bronze/Silver/Gold)
- **Data Engineering** – Building scalable data pipelines
- **ETL Pipeline Development** – Extract, transform, and load workflows
- **Data Modeling** – Fact and dimension tables
- **Data Analytics** – Business-focused reporting and insights
*The data architecture for this project follows Medallion Architecture Bronze, Silver, and Gold layers: *

Data Sources: Load data from two source systems (ERP and CRM) provided as CSV files.

Data Quality: Clean, validate, and resolve data quality issues before analysis.

Integration: Integrate both sources into a single, user-friendly data model optimized for analytical queries.

Scope: Focus on the most recent dataset only; historical data tracking is not required.

Documentation: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

BI: Analytics & Reporting (Data Analytics)
Objective
### BI: Analytics & Reporting (Data Analytics)

|Layer   | Description                    | Object Type | Load Strategy                 | Transformations                                      | Data Model       |
|---------|--------------------------------|-------------|-------------------------------|------------------------------------------------------|------------------|
| Bronze  | Raw data from source systems   | Tables      | Full Load, Truncate & Insert  | None (raw, as-is data)                               | As-Is            |
| Silver  | Cleaned and standardized data  | Tables      | Full Load, Truncate & Insert  | Data cleansing and standardization                   | As-Is            |
| Gold    | Business-ready data            | Views       | No Load                       | Aggregations, business logic, integrations            | Star Schema      |
| Consume | Analytics and insights         | BI Tools    | Read-Only                     | Reporting, ad-hoc analysis, machine learning          | Semantic Layer   |


Develop SQL-based analytics to deliver insights into:

*Customer Behavior*

*Product Performance*

*Sales Trends*

These insights help stakeholders understand key business metrics and support strategic, data-driven decision-making.
## High-Level Architecture



Hi! I’m GenetM.
I’m a data and analytics professional with a strong interest in data warehousing, SQL, and analytics. I enjoy building end-to-end data solutions and turning raw data into meaningful insights that support better decision-making.
