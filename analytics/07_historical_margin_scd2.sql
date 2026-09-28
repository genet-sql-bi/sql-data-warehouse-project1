/*
====================================================================
Analysis 07: Gross Margin Using Historical Product Cost (SCD Type 2)
====================================================================
Business question:
What was the true gross margin each year, using the product cost that
was valid at the time of each sale, and how wrong would the margin be
if we used today's cost instead?

Why it matters:
77 products changed cost over time. Without SCD Type 2 history, every
past sale would be costed at the current price, which misstates
historical margins. This query shows the size of that error.

Techniques: SCD Type 2 join, self-join to the current version, aggregation
====================================================================
*/

WITH sales_cost AS (
    SELECT
        YEAR(f.order_date)       AS order_year,
        p.category,
        f.sales_amount,
        f.quantity * p.cost      AS historical_cost,   -- cost valid on the order date
        f.quantity * cur.cost    AS current_cost       -- today's cost (what you'd get without SCD2)
    FROM gold.fact_sales f
    JOIN gold.dim_products p
        ON f.product_key = p.product_key
    JOIN gold.dim_products cur
        ON  cur.product_number = p.product_number
        AND cur.is_current = 1
    WHERE f.order_date IS NOT NULL
)
SELECT
    order_year,
    category,
    SUM(sales_amount)                                        AS total_sales,
    SUM(historical_cost)                                     AS historical_cost,
    SUM(sales_amount) - SUM(historical_cost)                 AS gross_margin,
    CAST(100.0 * (SUM(sales_amount) - SUM(historical_cost))
         / NULLIF(SUM(sales_amount), 0) AS DECIMAL(5, 2))    AS margin_pct_historical_cost,
    CAST(100.0 * (SUM(sales_amount) - SUM(current_cost))
         / NULLIF(SUM(sales_amount), 0) AS DECIMAL(5, 2))    AS margin_pct_current_cost,
    SUM(current_cost) - SUM(historical_cost)                 AS cost_difference
FROM sales_cost
GROUP BY order_year, category
ORDER BY order_year, category;
