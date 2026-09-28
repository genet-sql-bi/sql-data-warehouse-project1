
/*
Create Gold Views

Purpose:
This script creates views for the Gold layer in the data warehouse.
The Gold layer represents the final dimension and fact tables used for analytics.

Each view combines and transforms data from the Silver layer
to produce clean, enriched, and business-ready datasets.

Usage:
These views can be queried directly for reporting and analysis.
*/

--===============================================================
-- Create Dimension: gold.dim_customers
--===============================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
	cc.cst_id AS customer_id,
	cc.cst_key AS customer_number,
	cc.cst_firstname AS first_name,
	cc.cst_lastname AS last_name,
	el.CNTRY AS country,
	cc.cst_marital_status AS marital_status,
	CASE WHEN cc.cst_gndr != 'n/a' THEN cc.cst_gndr --crm is the master for gender info
		 ELSE COALESCE(ec.GEN, 'n/a')
	END AS gender,
	ec.BDATE AS birthdate,
	cc.cst_create_date AS create_date
FROM [silver].[crm_cust_info] cc
LEFT JOIN [silver].[erp_CUST_AZ12] ec
ON cc.cst_key = ec.CID
LEFT JOIN [silver].[erp_LOC_A101] el
ON cc.cst_key = el.CID;
GO

--===============================================================
-- Create Dimension: gold.dim_products  (SCD Type 2)
--===============================================================
-- Keeps every version of each product, so sales can be matched to the
-- product attributes (e.g. cost) that were valid on the order date.
--   start_date / end_date : dates as recorded in the source system
--   valid_from / valid_to : effective range used for the fact join.
--                           The first version of each product is treated as
--                           valid from 1900-01-01, because ~30% of sales are
--                           dated before the product's first recorded start date.
--   is_current            : 1 = latest version of the product
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,  -- surrogate key (one per version)
	pn.prd_id        AS product_id,
	pn.prd_key       AS product_number,
	pn.prd_nm        AS product_name,
	pn.cat_id        AS category_id,
	pc.CAT           AS category,
	pc.SUBCAT        AS subcategory,
	pc.MAINTENANCE   AS maintenance,
	pn.prd_cost      AS cost,
	pn.prd_line      AS product_line,
	pn.prd_start_dt  AS start_date,
	pn.prd_end_dt    AS end_date,
	CASE WHEN ROW_NUMBER() OVER (PARTITION BY pn.prd_key ORDER BY pn.prd_start_dt) = 1
	     THEN CAST('1900-01-01' AS DATE)
	     ELSE pn.prd_start_dt
	END               AS valid_from,
	ISNULL(pn.prd_end_dt, CAST('9999-12-31' AS DATE)) AS valid_to,
	CASE WHEN pn.prd_end_dt IS NULL THEN 1 ELSE 0 END  AS is_current
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_PX_CAT_G1V2 pc
	ON pn.cat_id = pc.ID;
GO

--===============================================================
-- Create Fact: gold.fact_sales
--===============================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num   AS order_number,
	gd.product_key,
	cu.customer_key,
	sd.sls_order_dt  AS order_date,
	sd.sls_ship_dt   AS shipping_date,
	sd.sls_due_dt    AS due_date,
	sd.sls_sales     AS sales_amount,
	sd.sls_quantity  AS quantity,
	sd.sls_price     AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products gd
	ON  sd.sls_prd_key = gd.product_number
	AND ISNULL(sd.sls_order_dt, CAST('9999-12-31' AS DATE))   -- orders with no valid date map to the current version
	    BETWEEN gd.valid_from AND gd.valid_to                  -- SCD2: pick the version valid on the order date
LEFT JOIN gold.dim_customers cu
	ON sd.sls_cust_id = cu.customer_id;
GO

--===============================================================
-- Create View: gold.customer_rfm  (RFM customer segmentation)
--===============================================================
-- One row per customer with Recency, Frequency, Monetary values,
-- 1-5 scores (5 = best), and a segment label. Used by the Power BI
-- Customers page. See analytics/05_customer_rfm_segmentation.sql
-- for the segment-level summary.
IF OBJECT_ID('gold.customer_rfm', 'V') IS NOT NULL
	DROP VIEW gold.customer_rfm;
GO

CREATE VIEW gold.customer_rfm AS
WITH customer_metrics AS (
	SELECT
		f.customer_key,
		DATEDIFF(DAY, MAX(f.order_date), a.analysis_date) AS recency_days,
		COUNT(DISTINCT f.order_number)                   AS frequency,
		SUM(f.sales_amount)                              AS monetary
	FROM gold.fact_sales f
	CROSS JOIN (
		SELECT DATEADD(DAY, 1, MAX(order_date)) AS analysis_date   -- day after the last order
		FROM gold.fact_sales
	) a
	WHERE f.order_date IS NOT NULL
	  AND f.customer_key IS NOT NULL
	GROUP BY f.customer_key, a.analysis_date
),
scored AS (
	SELECT
		*,
		NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- most recent customers get 5
		NTILE(5) OVER (ORDER BY frequency)         AS f_score,
		NTILE(5) OVER (ORDER BY monetary)          AS m_score
	FROM customer_metrics
)
SELECT
	customer_key,
	recency_days,
	frequency,
	monetary,
	r_score,
	f_score,
	m_score,
	CASE
		WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
		WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
		WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
		WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
		WHEN r_score <= 2 AND f_score <= 2                  THEN 'Hibernating'
		ELSE 'Needs Attention'
	END AS rfm_segment
FROM scored;
GO
