/*
====================================================================
Analysis 05: Customer RFM Segmentation
====================================================================
Business question:
Which customers are our most valuable, which are at risk of churning,
and how much revenue does each segment represent?

RFM = Recency (days since last order), Frequency (number of orders),
      Monetary (total spend). Each is scored 1-5 with NTILE(5),
      where 5 is best.

Note: many customers have exactly one order, so NTILE splits ties in
frequency arbitrarily. That is acceptable for segmentation but worth
knowing when reading individual scores.

Techniques: variable, multiple CTEs, NTILE(), CASE-based segmentation,
            share of total with SUM(SUM()) OVER ()
====================================================================
*/

-- Analysis date = the day after the last order in the data
DECLARE @analysis_date DATE = (
    SELECT DATEADD(DAY, 1, MAX(order_date)) FROM gold.fact_sales
);

WITH customer_metrics AS (
    SELECT
        customer_key,
        DATEDIFF(DAY, MAX(order_date), @analysis_date) AS recency_days,
        COUNT(DISTINCT order_number)                   AS frequency,
        SUM(sales_amount)                              AS monetary
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
      AND customer_key IS NOT NULL
    GROUP BY customer_key
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- most recent customers get 5
        NTILE(5) OVER (ORDER BY frequency)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM customer_metrics
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
            WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2                  THEN 'Hibernating'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM scored
)
SELECT
    rfm_segment,
    COUNT(*)                                         AS customers,
    AVG(recency_days)                                AS avg_recency_days,
    CAST(AVG(CAST(frequency AS DECIMAL(10, 2))) AS DECIMAL(10, 2)) AS avg_orders,
    SUM(monetary)                                    AS total_sales,
    CAST(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER () AS DECIMAL(5, 2)) AS pct_of_total_sales
FROM segmented
GROUP BY rfm_segment
ORDER BY total_sales DESC;
