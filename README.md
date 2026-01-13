
# Data Warehouse and Analytics Project 

Welcome to the Data Warehouse and Analytics Project repository! 🚀
This project demonstrates an end-to-end data warehousing and analytics solution, from building a SQL Server–based data warehouse to generating meaningful analytical insights.

Designed as a portfolio project, it follows industry best practices in modern data engineering, data modeling, and analytics.

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
┌────────────────────┐ >> ┌────────────────────┐ >> ┌────────────────────┐ >> ┌────────────────────┐
│    Bronze Layer    │    │    Silver Layer    │    │     Gold Layer     │    │      Consume       │
├────────────────────┤    ├────────────────────┤     ────────────────────┤    ├────────────────────┤
│ Raw / As-Is Data   │    │ Cleaned &          │    │ Business-Ready     │    │ BI & Reporting     │
│                    │    │ Standardized Data  │    │ Data               │    │ Dashboards         │
│ Object Type:       │    │ Object Type:       │    │ Object Type:       │    │ Ad-Hoc SQL         │
│ Tables             │    │ Tables             │    │ Views              │    │ Analytics          │
│                    │    │                    │    │                    │    │ Machine Learning   │
│ Load:              │    │ Load:              │    │ Load:              │    │                    │
│ Full Load          │    │ Full Load          │    │ No Load            │    │ Read-Only Access   │
│ Truncate & Insert  │    │ Truncate & Insert  │    │                    │    │                    │
│                    │    │                    │    │                    │    │ Data Source:       │
│ Transformations:   │    │ Transformations:   │    │ Transformations:   │    │ Gold Views         │
│ None               │    │ Cleansing          │    │ Aggregations       │    │                    │
│                    │    │ Standardization    │    │ Business Logic     │    │                    │
│ Data Model:        │    │ Data Model:        │    │ Data Model:        │    │                    │
│ As-Is              │    │ As-Is              │    │ Star Schema        │    │                    │
└────────────────────┘    └────────────────────┘    └────────────────────┘    └────────────────────┘

Data Sources: Load data from two source systems (ERP and CRM) provided as CSV files.

Data Quality: Clean, validate, and resolve data quality issues before analysis.

Integration: Integrate both sources into a single, user-friendly data model optimized for analytical queries.

Scope: Focus on the most recent dataset only; historical data tracking is not required.

Documentation: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

BI: Analytics & Reporting (Data Analytics)
Objective

Develop SQL-based analytics to deliver insights into:

*Customer Behavior*

*Product Performance*

*Sales Trends*

These insights help stakeholders understand key business metrics and support strategic, data-driven decision-making.

Hi! I’m GenetM.
I’m a data and analytics professional with a strong interest in data warehousing, SQL, and analytics. I enjoy building end-to-end data solutions and turning raw data into meaningful insights that support better decision-making.
