/*
========================================================================================================

Stored Procedure: Load Bronze Layer

========================================================================================================

This stored procedure is responsible for loading raw source data
into the bronze layer of the data warehouse. It reads data from
external CSV files and loads it into bronze tables using BULK INSERT.

Before loading new data, the procedure truncates the existing
bronze tables to ensure only fresh data is stored. This layer
keeps the data in its original format with minimal transformation
and serves as the foundation for the silver and gold layers.

This stored procedure does not accept any parameters or return any values.
==========================================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 

BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==========================================================================================='
		PRINT'Loading Bronze Layer'
		PRINT '==========================================================================================='

		PRINT '-------------------------------------------------------------------------------------------'
		PRINT 'Loading CRM Tables'
		PRINT '-------------------------------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '**Truncating Table: [bronze].[crm_cust_info]' ;
		TRUNCATE TABLE [bronze].[crm_cust_info];
		PRINT '**Inserting data into [bronze].[crm_cust_info]';

		BULK INSERT [bronze].[crm_cust_info]
		FROM 'C:\Users\Genet\Downloads\sql-data-warehouse-project(1)\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------'

		SET @start_time = GETDATE();
		PRINT '**Truncating Table: [bronze].[crm_prd_info]' ;
		TRUNCATE TABLE [bronze].[crm_prd_info];
		PRINT '**Inserting data into [bronze].[crm_prd_info]';

		BULK INSERT [bronze].[crm_prd_info]
		FROM 'C:\Users\Genet\Downloads\sql-data-warehouse-project(1)\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------' 

		SET @start_time = GETDATE();
		PRINT '**Truncating Table: [bronze].[crm_sales_details]' ;
		TRUNCATE TABLE [bronze].[crm_sales_details];
		PRINT '**Inserting data into [bronze].[crm_sales_details]';

		BULK INSERT [bronze].[crm_sales_details]
		FROM 'C:\Users\Genet\Downloads\sql-data-warehouse-project(1)\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------'

		PRINT '-------------------------------------------------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '-------------------------------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '**Truncating Table: [bronze].[erp_CUST_AZ12]' ;
		TRUNCATE TABLE [bronze].[erp_CUST_AZ12];
		PRINT '**Inserting data into [bronze].[erp_CUST_AZ12]';

		BULK INSERT [bronze].[erp_CUST_AZ12]
		FROM 'C:\Users\Genet\Downloads\sql-data-warehouse-project(1)\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------'

		SET @start_time = GETDATE();
		PRINT '**Truncating Table: [bronze].[erp_LOC_A101]' ;
		TRUNCATE TABLE [bronze].[erp_LOC_A101];
		PRINT '**Inserting data into [bronze].[erp_LOC_A101]';

		BULK INSERT [bronze].[erp_LOC_A101]
		FROM 'C:\Users\Genet\Downloads\sql-data-warehouse-project(1)\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------'

		SET @start_time = GETDATE();
		PRINT '**Truncating Table: [bronze].[erp_PX_CAT_G1V2]' ;
		TRUNCATE TABLE [bronze].[erp_PX_CAT_G1V2];
		PRINT '**Inserting data into [bronze].[erp_PX_CAT_G1V2]';

		BULK INSERT [bronze].[erp_PX_CAT_G1V2]
		FROM 'C:\Users\Genet\Downloads\sql-data-warehouse-project(1)\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------'

		SET @batch_end_time = GETDATE();
		PRINT '=================================================='
		PRINT 'Loading Bronze Layer is Completed';
		PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
		PRINT '====================================================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE ();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '====================================================================================';
	END CATCH
END
