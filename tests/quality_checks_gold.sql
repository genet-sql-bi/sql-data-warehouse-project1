/*
Quality Checks – Gold Layer

Purpose:
This script runs quality checks on the Gold layer to make sure the data
is accurate, consistent, and reliable for analytics.

The checks include:
- Uniqueness of surrogate keys in dimension tables.
- Referential integrity between fact and dimension tables.
- Validation of relationships in the star schema.

Usage:
Run these checks after loading data into the Gold layer.
Review and fix any issues found before using the data for reporting.
*/
-- ============================================================
-- Checking 'gold.dim_customers'
-- ============================================================

-- Check for Uniqueness of Customer Key
-- Expectation: No results
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ============================================================
-- Checking 'gold.dim_products'
-- ============================================================

-- Check for Uniqueness of Product Key
-- Expectation: No results
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ============================================================
-- Checking 'gold.fact_sales'
-- ============================================================

-- Check data model connectivity between fact and dimensions
-- fact_sales gets its keys by joining to the dimensions,
-- so a NULL key means the sale has no matching dimension row.
-- Expectation: No results
SELECT
    *
FROM gold.fact_sales
WHERE product_key IS NULL
   OR customer_key IS NULL;
   
-- ============================================================
-- Checking SCD Type 2 in 'gold.dim_products'
-- ============================================================

-- Each product must have exactly one current version
-- Expectation: No results
SELECT
    product_number,
    SUM(is_current) AS current_versions
FROM gold.dim_products
GROUP BY product_number
HAVING SUM(is_current) <> 1;

-- Validity ranges of the same product must not overlap
-- Expectation: No results
SELECT
    a.product_number,
    a.product_key AS version_a,
    b.product_key AS version_b
FROM gold.dim_products a
JOIN gold.dim_products b
    ON  a.product_number = b.product_number
    AND a.product_key    < b.product_key
    AND a.valid_from    <= b.valid_to
    AND b.valid_from    <= a.valid_to;

-- Every sale must match exactly one product version
-- Expectation: No results (fact row count = source row count)
SELECT
    (SELECT COUNT(*) FROM silver.crm_sales_details) AS source_rows,
    (SELECT COUNT(*) FROM gold.fact_sales)          AS fact_rows
WHERE (SELECT COUNT(*) FROM silver.crm_sales_details)
   <> (SELECT COUNT(*) FROM gold.fact_sales);

-- ============================================================
-- Checking ETL load log
-- ============================================================

-- Failed loads
-- Expectation: No results
SELECT *
FROM etl.load_log
WHERE status = 'FAILED'
ORDER BY start_time DESC;

