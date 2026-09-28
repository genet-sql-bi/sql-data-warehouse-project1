/*
====================================================================
Analysis 04: Product Performance
====================================================================
Business question:
How does each product perform against its category average each year,
and is it growing or declining compared with the previous year?

Note: dim_products is SCD Type 2 (one row per product version), so sales
are grouped by product_number to combine all versions of a product.

Techniques: CTE, AVG() OVER (category benchmark), LAG() (year-over-year)
====================================================================
*/

WITH product_yearly_sales AS (
    SELECT
        YEAR(f.order_date)  AS order_year,
        p.product_number,
        p.product_name,
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_number, p.product_name, p.category
),
benchmarked AS (
    SELECT
        *,
        AVG(CAST(total_sales AS DECIMAL(18, 2))) OVER (PARTITION BY order_year, category) AS category_avg_sales,
        LAG(total_sales) OVER (PARTITION BY product_number ORDER BY order_year)           AS prev_year_sales
    FROM product_yearly_sales
)
SELECT
    order_year,
    category,
    product_number,
    product_name,
    total_sales,
    CAST(category_avg_sales AS DECIMAL(18, 2))                AS category_avg_sales,
    CAST(total_sales - category_avg_sales AS DECIMAL(18, 2))  AS diff_from_category_avg,
    CASE WHEN total_sales > category_avg_sales THEN 'Above average'
         WHEN total_sales < category_avg_sales THEN 'Below average'
         ELSE 'Average'
    END                                                       AS vs_category,
    prev_year_sales,
    CASE WHEN prev_year_sales IS NULL        THEN 'New'
         WHEN total_sales > prev_year_sales  THEN 'Increasing'
         WHEN total_sales < prev_year_sales  THEN 'Decreasing'
         ELSE 'No change'
    END                                                       AS yoy_trend
FROM benchmarked
ORDER BY order_year, category, total_sales DESC;
