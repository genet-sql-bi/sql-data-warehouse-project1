/*
====================================================================
Analysis 02: Year-over-Year Sales by Category
====================================================================
Business question:
Which product categories are growing or declining year over year,
and what share of each year's sales does each category contribute?

Techniques: CTE, LAG() partitioned by category, share of total with SUM() OVER
====================================================================
*/

WITH yearly_category_sales AS (
    SELECT
        YEAR(f.order_date)        AS order_year,
        ISNULL(p.category, 'n/a') AS category,
        SUM(f.sales_amount)       AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), ISNULL(p.category, 'n/a')
)
SELECT
    order_year,
    category,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year) AS prev_year_sales,
    CAST(100.0 * (total_sales - LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year))
         / NULLIF(LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year), 0)
         AS DECIMAL(10, 2))                                           AS yoy_growth_pct,
    CAST(100.0 * total_sales / SUM(total_sales) OVER (PARTITION BY order_year)
         AS DECIMAL(5, 2))                                            AS pct_of_year_sales
FROM yearly_category_sales
ORDER BY order_year, total_sales DESC;
