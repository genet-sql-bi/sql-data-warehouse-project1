/*
====================================================================
Analysis 03: Top Customers
====================================================================
Business questions:
1. Who are the top 10 customers by total revenue?
2. Who are the top 3 customers in each country?

Techniques: CTE, DENSE_RANK() overall and partitioned by country
====================================================================
*/

-- 1. Top 10 customers overall
WITH customer_sales AS (
    SELECT
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        SUM(f.sales_amount)                    AS total_sales,
        COUNT(DISTINCT f.order_number)         AS total_orders
    FROM gold.fact_sales f
    JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key, c.customer_number, c.first_name, c.last_name, c.country
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS overall_rank
    FROM customer_sales
)
SELECT
    overall_rank,
    customer_number,
    customer_name,
    country,
    total_sales,
    total_orders
FROM ranked
WHERE overall_rank <= 10
ORDER BY overall_rank;

-- 2. Top 3 customers in each country
WITH customer_sales AS (
    SELECT
        c.customer_key,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        SUM(f.sales_amount)                    AS total_sales
    FROM gold.fact_sales f
    JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name, c.country
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY country ORDER BY total_sales DESC) AS country_rank
    FROM customer_sales
)
SELECT
    country,
    country_rank,
    customer_name,
    total_sales
FROM ranked
WHERE country_rank <= 3
ORDER BY country, country_rank;
