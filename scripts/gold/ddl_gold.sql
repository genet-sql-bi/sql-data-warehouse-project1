
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
--Create Dimension:gold.dim_customers
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
ON cc.cst_key = el.CID

--===============================================================
--Create Dimension:gold.dim_products
--===============================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
	GO

CREATE VIEW gold.dim_products AS
SELECT  
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number, 
	pn.prd_nm AS product_name, 
	pn.cat_id AS category_id,
	pc.CAT AS category,
	pc.SUBCAT AS subcategory,
	pc.MAINTENANCE AS maintenance,
	pn.prd_cost AS cost, 
	pn.prd_line AS product_line, 
	pn.prd_start_dt AS start_date
FROM [silver].[crm_prd_info] pn
LEFT JOIN [silver].[erp_PX_CAT_G1V2] pc
    ON pn.cat_id = pc.ID 
WHERE prd_end_dt IS NULL ---filter out all historical data

--===============================================================
--Create Dimension:gold.fact_sales
--===============================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
	GO

CREATE VIEW gold.fact_sales AS 
SELECT 
	sd.sls_ord_num AS order_number, 
	gd.product_key ,
	cu.customer_key,
	sd.sls_order_dt AS order_date, 
	sd.sls_ship_dt AS shipping_dat, 
	sd.sls_due_dt AS due_date, 
	sd.sls_sales AS sales_amount, 
	sd.sls_quantity AS quantity, 
	sd.sls_price AS price
FROM [silver].[crm_sales_details] sd
LEFT JOIN gold.dim_products gd
ON sd.sls_prd_key = gd.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id
