# Data Dictionary – Gold Layer

## Overview

The Gold layer represents the business-ready data model designed to support reporting and analytics.
It contains curated dimension and fact tables that store clean, standardized, and enriched data for business use cases.

### 1. gold.dim_customers
Purpose: Stores customer information enriched with demographic and geographic attributes.

Columns :


| Column Name        | Data Type        | Description |
|--------------------|------------------|-------------|
| customer_key       | INT              | Surrogate key uniquely identifying each customer record. |
| customer_id        | INT              | Unique numerical identifier assigned to each customer. |
| customer_number    | NVARCHAR(50)     | Alphanumeric customer identifier used for tracking and referencing. |
| first_name         | NVARCHAR(50)     | Customer’s first name. |
| last_name          | NVARCHAR(50)     | Customer’s last or family name. |
| country            | NVARCHAR(50)     | Country of residence (e.g., Australia). |
| marital_status     | VARCHAR(50)      | Customer’s marital status (e.g., Married, Single). |
| gender             | NVARCHAR(50)     | Customer’s gender (e.g., Male, Female, n/a). |
| birthdate          | DATE             | Customer’s date of birth (YYYY-MM-DD) (e.g., 1983-10-06) |
| create_date        | DATE             | Date when the customer record was created. |



### 2. gold.dim_products

Purpose: Provides information about products and their attributes for analysis and reporting.
This is a **Slowly Changing Dimension (Type 2)**: each row is one version of a product, so sales can be matched to the attributes (such as cost) that were valid on the order date.

Columns:

| Column Name              | Data Type        | Description |
|--------------------------|------------------|-------------|
| product_key              | INT              | Surrogate key uniquely identifying each product version. |
| product_id               | INT              | Unique product identifier from the source system. |
| product_number           | NVARCHAR(50)     | Alphanumeric product code used for tracking and inventory. |
| product_name             | NVARCHAR(50)     | Descriptive name of the product. |
| category_id              | NVARCHAR(50)     | Identifier linking the product to its category. |
| category                 | NVARCHAR(50)     | High-level product classification (e.g., Bikes, Components). |
| subcategory              | NVARCHAR(50)     | Detailed classification within the product category. |
| maintenance              | NVARCHAR(50)     | Indicates whether maintenance is required (Yes / No). |
| cost                     | INT              | Base cost of the product in whole currency units. |
| product_line             | NVARCHAR(50)     | Product line or series to which the product belongs. |
| start_date               | DATE             | Date this product version became effective in the source system. |
| end_date                 | DATE             | Date this version ended (day before the next version started). NULL for the current version. |
| valid_from               | DATE             | Start of the validity range used to join sales. 1900-01-01 for the first version of each product. |
| valid_to                 | DATE             | End of the validity range used to join sales. 9999-12-31 for the current version. |
| is_current               | INT              | 1 = latest version of the product, 0 = historical version. |



### 3. gold.fact_sales

Purpose: Stores transactional sales data used for analytical and reporting purposes.

Columns:

| Column Name      | Data Type        | Description |
|------------------|------------------|-------------|
| order_number     | NVARCHAR(50)     | Unique alphanumeric identifier for each sales order (e.g., SO54496). |
| product_key      | INT              | Surrogate key linking the sale to the product version valid on the order date. |
| customer_key     | INT              | Surrogate key linking the sale to the customer dimension. |
| order_date       | DATE             | Date when the order was placed. |
| shipping_date    | DATE             | Date when the order was shipped. |
| due_date         | DATE             | Date when payment for the order was due. |
| sales_amount     | INT              | Total monetary value of the sale line item. |
| quantity         | INT              | Number of units ordered for the line item. |
| price            | INT              | Price per unit of the product. |



**Business Rule:** `sales_amount = quantity × price`

### 4. etl.load_log

Purpose: Records one row per table per load run for monitoring and troubleshooting.

| Column Name    | Data Type        | Description |
|----------------|------------------|-------------|
| log_id         | INT              | Identity key for the log entry. |
| batch_id       | UNIQUEIDENTIFIER | Groups all tables loaded in the same run. |
| layer          | NVARCHAR(20)     | Layer being loaded (bronze / silver). |
| table_name     | NVARCHAR(128)    | Table being loaded. |
| start_time     | DATETIME2(0)     | When the table load started. |
| end_time       | DATETIME2(0)     | When the table load finished or failed. |
| duration_sec   | INT (computed)   | Load duration in seconds. |
| rows_loaded    | INT              | Rows inserted. NULL if the load failed. |
| status         | NVARCHAR(10)     | SUCCESS or FAILED. |
| error_message  | NVARCHAR(4000)   | Error details when status is FAILED. |
