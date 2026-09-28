/*
====================================================================
Analysis 01: Monthly Sales Trend
====================================================================
Business question:
How are sales trending month over month, and how is revenue
accumulating over time?

Techniques: CTE, aggregation, SUM() OVER (running total), LAG()
====================================================================
*/

WITH monthly_sales AS (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS order_month,
        SUM(sales_amount)                                     AS total_sales,
        COUNT(DISTINCT order_number)                          AS total_orders,
        COUNT(DISTINCT customer_key)                          AS total_customers
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT
    order_month,
    total_sales,
    total_orders,
    total_customers,
    SUM(CAST(total_sales AS BIGINT)) OVER (ORDER BY order_month ROWS UNBOUNDED PRECEDING) AS running_total_sales,
    LAG(total_sales) OVER (ORDER BY order_month)                                         AS prev_month_sales,
    CAST(100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY order_month))
         / NULLIF(LAG(total_sales) OVER (ORDER BY order_month), 0) AS DECIMAL(10, 2))    AS mom_growth_pct
FROM monthly_sales
ORDER BY order_month;
