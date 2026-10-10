/*
========================================================================================================
Stored Procedure: Load Bronze Layer (Source CSV -> Bronze)
========================================================================================================

Purpose:
Loads raw source data from CSV files into the bronze tables using BULK INSERT.
Each table is truncated first, so the bronze layer always holds the latest full extract.

Transaction safety:
The whole layer loads inside one transaction (SET XACT_ABORT ON + TRY...CATCH).
If any table fails, every table in the layer rolls back to its last good state,
so a failed run never leaves bronze empty or half-loaded.

Data quality gate:
If any table loads 0 rows (e.g. an empty or truncated source file), the load
is treated as FAILED and rolled back, so an empty source can't wipe good data.

Logging:
Every table load is recorded in etl.load_log (rows loaded, duration, status).
SUCCESS rows are written inside the transaction, so they only persist if the
whole layer commits. On failure, the transaction is rolled back first and the
FAILED row is written afterwards, so the failure record is never lost.
The error is then re-thrown, so the caller (e.g. a SQL Agent job) sees the
load as FAILED instead of silently succeeding.

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
    SET XACT_ABORT ON;   -- any runtime error dooms the transaction, so nothing is half-committed

    DECLARE @batch_id         UNIQUEIDENTIFIER = NEWID(),
            @table_name       NVARCHAR(128),
            @start_time       DATETIME2(0),
            @batch_start_time DATETIME2(0) = SYSDATETIME(),
            @rows             INT,
            @error_message    NVARCHAR(4000),
            @error_number     INT,
            @error_state      INT;

    BEGIN TRY
        BEGIN TRANSACTION;   -- all tables in this layer succeed together or roll back together

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

        IF @rows = 0   -- data quality gate: an empty source must never replace good data
        BEGIN
            SET @error_message = @table_name + ' loaded 0 rows - source is empty or unreadable';
            THROW 50001, @error_message, 1;   -- jumps to CATCH, which rolls back the whole layer
        END;

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

        IF @rows = 0   -- data quality gate: an empty source must never replace good data
        BEGIN
            SET @error_message = @table_name + ' loaded 0 rows - source is empty or unreadable';
            THROW 50001, @error_message, 1;   -- jumps to CATCH, which rolls back the whole layer
        END;

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

        IF @rows = 0   -- data quality gate: an empty source must never replace good data
        BEGIN
            SET @error_message = @table_name + ' loaded 0 rows - source is empty or unreadable';
            THROW 50001, @error_message, 1;   -- jumps to CATCH, which rolls back the whole layer
        END;

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

        IF @rows = 0   -- data quality gate: an empty source must never replace good data
        BEGIN
            SET @error_message = @table_name + ' loaded 0 rows - source is empty or unreadable';
            THROW 50001, @error_message, 1;   -- jumps to CATCH, which rolls back the whole layer
        END;

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

        IF @rows = 0   -- data quality gate: an empty source must never replace good data
        BEGIN
            SET @error_message = @table_name + ' loaded 0 rows - source is empty or unreadable';
            THROW 50001, @error_message, 1;   -- jumps to CATCH, which rolls back the whole layer
        END;

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

        IF @rows = 0   -- data quality gate: an empty source must never replace good data
        BEGIN
            SET @error_message = @table_name + ' loaded 0 rows - source is empty or unreadable';
            THROW 50001, @error_message, 1;   -- jumps to CATCH, which rolls back the whole layer
        END;

        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, @rows, 'SUCCESS';
        PRINT '>> Rows loaded: ' + CAST(@rows AS NVARCHAR(20))
            + ' | Duration: ' + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';

        COMMIT TRANSACTION;

        PRINT '==========================================================================';
        PRINT 'Bronze Layer load completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, SYSDATETIME()) AS NVARCHAR(20)) + ' seconds';
        PRINT '==========================================================================';
    END TRY
    BEGIN CATCH
        -- Capture error details first, then undo every table loaded in this run.
        SET @error_message = ERROR_MESSAGE();
        SET @error_number  = ERROR_NUMBER();
        SET @error_state   = ERROR_STATE();
        SET @table_name    = ISNULL(@table_name, 'n/a');
        SET @start_time    = ISNULL(@start_time, SYSDATETIME());

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Logged after the rollback, so the FAILED row is kept.
        EXEC etl.log_load @batch_id, 'bronze', @table_name, @start_time, NULL, 'FAILED', @error_message;

        PRINT '==========================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER - all bronze tables rolled back';
        PRINT 'Failed table: '  + @table_name;
        PRINT 'Error Message: ' + @error_message;
        PRINT 'Error Number: '  + CAST(@error_number AS NVARCHAR(20));
        PRINT 'Error State: '   + CAST(@error_state AS NVARCHAR(20));
        PRINT '==========================================================================';

        THROW;   -- re-raise so the caller knows the load failed
    END CATCH
END;
GO