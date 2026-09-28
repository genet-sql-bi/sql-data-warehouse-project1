/*
========================================================================================================
Stored Procedure: Load Bronze Layer (Source CSV -> Bronze)
========================================================================================================

Purpose:
Loads raw source data from CSV files into the bronze tables using BULK INSERT.
Each table is truncated first, so the bronze layer always holds the latest full extract.

Logging:
Every table load is recorded in etl.load_log (rows loaded, duration, status).
If any step fails, the failure is logged and the error is re-thrown, so the
caller (e.g. a SQL Agent job) sees the load as FAILED instead of silently succeeding.

Prerequisites:
- scripts/etl/ddl_etl.sql has been run.
- The file paths below point to your local 'datasets' folder.

Parameters: None.

How to run:
    EXEC bronze.load_bronze;
========================================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
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
        PRINT 'Loading Bronze Layer';
        PRINT '==========================================================================';

        PRINT '--------------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '--------------------------------------------------------------------------';

        -- bronze.crm_cust_info
        SET @table_name = 'bronze.crm_cust_info';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\GitProjects\sql-data-warehouse-project1\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;   -- capture immediately; later statements reset it

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        -- bronze.crm_prd_info
        SET @table_name = 'bronze.crm_prd_info';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\GitProjects\sql-data-warehouse-project1\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;   -- capture immediately; later statements reset it

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        -- bronze.crm_sales_details
        SET @table_name = 'bronze.crm_sales_details';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\GitProjects\sql-data-warehouse-project1\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;   -- capture immediately; later statements reset it

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        PRINT '--------------------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '--------------------------------------------------------------------------';

        -- bronze.erp_CUST_AZ12
        SET @table_name = 'bronze.erp_CUST_AZ12';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE bronze.erp_CUST_AZ12;

        BULK INSERT bronze.erp_CUST_AZ12
        FROM 'C:\GitProjects\sql-data-warehouse-project1\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;   -- capture immediately; later statements reset it

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        -- bronze.erp_LOC_A101
        SET @table_name = 'bronze.erp_LOC_A101';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE bronze.erp_LOC_A101;

        BULK INSERT bronze.erp_LOC_A101
        FROM 'C:\GitProjects\sql-data-warehouse-project1\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;   -- capture immediately; later statements reset it

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        -- bronze.erp_PX_CAT_G1V2
        SET @table_name = 'bronze.erp_PX_CAT_G1V2';
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating and loading: ' + @table_name;
        TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;

        BULK INSERT bronze.erp_PX_CAT_G1V2
        FROM 'C:\GitProjects\sql-data-warehouse-project1\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;   -- capture immediately; later statements reset it

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        PRINT '==========================================================================';
        PRINT 'Bronze Layer load completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';
        PRINT '==========================================================================';
    END TRY
    BEGIN CATCH
        SET @error_message = ERROR_MESSAGE();
        SET @table_name    = ISNULL(@table_name, 'n/a');
        SET @start_time    = ISNULL(@start_time, SYSDATETIME());

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, NULL, 'FAILED', @error_message;

        PRINT '==========================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Failed table: '  + ISNULL(@table_name, 'n/a');
        PRINT 'Error Message: ' + @error_message;
        PRINT 'Error Number: '  + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: '   + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT '==========================================================================';

        THROW;   -- re-raise so the caller knows the load failed
    END CATCH
END;
GO
