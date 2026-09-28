/*
========================================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
========================================================================================================

Purpose:
Loads data from the bronze tables into the silver tables, applying cleansing and
standardization along the way:
- Removes duplicate customers (keeps the most recent record per customer).
- Trims text and maps codes to readable values (gender, marital status, product line, country).
- Splits the product key into category id and product key.
- Derives product end dates from the next version's start date (keeps full product history).
- Converts integer dates (YYYYMMDD) to DATE and sets invalid dates to NULL.
- Recalculates sales and price where they are missing, negative, or inconsistent.
- Nulls out birthdates in the future.

Logging:
Every table load is recorded in etl.load_log. On failure, the error is logged and re-thrown.

Parameters: None.

How to run:
    EXEC silver.load_silver;
========================================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_id         UNIQUEIDENTIFIER = NEWID(),
            @table_name       NVARCHAR(128),
            @start_time       DATETIME2(0),
            @batch_start_time DATETIME2(0) = SYSDATETIME(),
            @rows             INT,
            @error_message    NVARCHAR(4000);

    BEGIN TRY
        PRINT '==========================================================================';
        PRINT 'Loading Silver Layer';
        PRINT '==========================================================================';

        PRINT '--------------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '--------------------------------------------------------------------------';

        -- silver.crm_cust_info
        SET @table_name = 'silver.crm_cust_info';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname)  AS cst_lastname,
            CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                 ELSE 'n/a'
            END AS cst_marital_status,          -- normalize marital status to readable values
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                 ELSE 'n/a'                      -- default for missing values
            END AS cst_gndr,                    -- normalize gender to readable values
            cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last  -- remove duplicates
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;                    -- keep the most recent record per customer
        SET @rows = @@ROWCOUNT;

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20));

        -- silver.crm_prd_info
        SET @table_name = 'silver.crm_prd_info';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,     -- extract category id
            SUBSTRING(prd_key, 7, LEN(prd_key))         AS prd_key,    -- extract product key
            prd_nm,
            ISNULL(prd_cost, 0)                         AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END                                         AS prd_line,
            CAST(prd_start_dt AS DATE)                  AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE)
                                                        AS prd_end_dt  -- end date = day before next version starts
        FROM bronze.crm_prd_info;
        SET @rows = @@ROWCOUNT;

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20));

        -- silver.crm_sales_details
        SET @table_name = 'silver.crm_sales_details';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                 THEN sls_quantity * ABS(sls_price)
                 ELSE sls_sales
            END AS sls_sales,                   -- recalculate missing or inconsistent sales
            sls_quantity,
            CASE WHEN sls_price IS NULL OR sls_price <= 0
                 THEN sls_sales / NULLIF(sls_quantity, 0)
                 ELSE sls_price
            END AS sls_price                    -- derive price if missing or invalid
        FROM bronze.crm_sales_details;
        SET @rows = @@ROWCOUNT;

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20));

        PRINT '--------------------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '--------------------------------------------------------------------------';

        -- silver.erp_CUST_AZ12
        SET @table_name = 'silver.erp_CUST_AZ12';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE silver.erp_CUST_AZ12;

        INSERT INTO silver.erp_CUST_AZ12 (
            CID,
            BDATE,
            GEN
        )
        SELECT
            CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))  -- remove 'NAS' prefix
                 ELSE CID
            END AS CID,
            CASE WHEN BDATE > GETDATE() THEN NULL                       -- future birthdates are invalid
                 ELSE BDATE
            END AS BDATE,
            CASE WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
                 WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE')   THEN 'Male'
                 ELSE 'n/a'
            END AS GEN
        FROM bronze.erp_CUST_AZ12;
        SET @rows = @@ROWCOUNT;

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20));

        -- silver.erp_LOC_A101
        SET @table_name = 'silver.erp_LOC_A101';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE silver.erp_LOC_A101;

        INSERT INTO silver.erp_LOC_A101 (
            CID,
            CNTRY
        )
        SELECT
            REPLACE(CID, '-', '') AS CID,
            CASE WHEN TRIM(CNTRY) = 'DE'             THEN 'Germany'
                 WHEN TRIM(CNTRY) IN ('US', 'USA')   THEN 'United States'
                 WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
                 ELSE TRIM(CNTRY)
            END AS CNTRY                        -- normalize country codes
        FROM bronze.erp_LOC_A101;
        SET @rows = @@ROWCOUNT;

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20));

        -- silver.erp_PX_CAT_G1V2
        SET @table_name = 'silver.erp_PX_CAT_G1V2';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE silver.erp_PX_CAT_G1V2;

        INSERT INTO silver.erp_PX_CAT_G1V2 (
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        )
        SELECT
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        FROM bronze.erp_PX_CAT_G1V2;
        SET @rows = @@ROWCOUNT;

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20));

        PRINT '==========================================================================';
        PRINT 'Silver Layer load completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';
        PRINT '==========================================================================';
    END TRY
    BEGIN CATCH
        SET @error_message = ERROR_MESSAGE();
        SET @table_name    = ISNULL(@table_name, 'n/a');
        SET @start_time    = ISNULL(@start_time, SYSDATETIME());

        EXEC etl.log_load @batch_id, 'silver', @table_name, @start_time, NULL, 'FAILED', @error_message;

        PRINT '==========================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Failed table: '  + @table_name;
        PRINT 'Error Message: ' + @error_message;
        PRINT 'Error Number: '  + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: '   + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT '==========================================================================';

        THROW;   -- re-raise so the caller knows the load failed
    END CATCH
END;
GO
