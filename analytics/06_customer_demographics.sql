/*
====================================================================
Analysis 06: Sales by Customer Demographics
====================================================================
Business question:
How do sales and average order value differ by age group and gender?

Age is calculated at the time of each order (not today), because the
sales data is historical. Customers with no valid birthdate are
grouped as 'Unknown'.

Techniques: exact age calculation, CASE banding, aggregation
====================================================================
*/

WITH sales_with_age AS (
    SELECT
        f.order_number,
        f.customer_key,
        f.sales_amount,
        c.gender,
        DATEDIFF(YEAR, c.birthdate, f.order_date)
          - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, c.birthdate, f.order_date), c.birthdate) > f.order_date
                 THEN 1 ELSE 0 END AS age_at_order    -- subtract 1 if birthday not reached yet that year
    FROM gold.fact_sales f
    JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),
banded AS (
    SELECT
        *,
        CASE WHEN age_at_order IS NULL THEN 'Unknown'
             WHEN age_at_order < 35    THEN 'Under 35'
             WHEN age_at_order < 50    THEN '35-49'
             WHEN age_at_order < 65    THEN '50-64'
             ELSE '65+'
        END AS age_group
    FROM sales_with_age
)
SELECT
    age_group,
    gender,
    COUNT(DISTINCT customer_key)                                  AS customers,
    COUNT(DISTINCT order_number)                                  AS orders,
    SUM(sales_amount)                                             AS total_sales,
    CAST(1.0 * SUM(sales_amount) / COUNT(DISTINCT order_number) AS DECIMAL(10, 2)) AS avg_order_value
FROM banded
GROUP BY age_group, gender
ORDER BY age_group, gender;
