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
-- Expectation: No results
SELECT
    *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;


