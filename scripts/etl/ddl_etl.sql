/*
====================================================================
DDL Script: ETL Logging
====================================================================

Purpose:
Creates the 'etl' schema, the etl.load_log table, and the
etl.log_load procedure. Every bronze and silver load writes one row
per table to etl.load_log, recording start/end time, rows loaded,
status (SUCCESS / FAILED), and the error message if it failed.

Run this once, right after init_database.sql.

Warning:
Re-running this script drops etl.load_log and its run history.
====================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA etl');
GO

IF OBJECT_ID('etl.load_log', 'U') IS NOT NULL
    DROP TABLE etl.load_log;
GO

CREATE TABLE etl.load_log (
    log_id         INT IDENTITY(1,1) PRIMARY KEY,
    batch_id       UNIQUEIDENTIFIER NOT NULL,   -- groups all tables loaded in one run
    layer          NVARCHAR(20)     NOT NULL,   -- bronze / silver
    table_name     NVARCHAR(128)    NOT NULL,
    start_time     DATETIME2(0)     NOT NULL,
    end_time       DATETIME2(0)     NOT NULL,
    duration_sec   AS DATEDIFF(SECOND, start_time, end_time),
    rows_loaded    INT              NULL,
    status         NVARCHAR(10)     NOT NULL,   -- SUCCESS / FAILED
    error_message  NVARCHAR(4000)   NULL
);
GO

CREATE OR ALTER PROCEDURE etl.log_load
    @batch_id       UNIQUEIDENTIFIER,
    @layer          NVARCHAR(20),
    @table_name     NVARCHAR(128),
    @start_time     DATETIME2(0),
    @rows_loaded    INT            = NULL,
    @status         NVARCHAR(10),
    @error_message  NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO etl.load_log
        (batch_id, layer, table_name, start_time, end_time, rows_loaded, status, error_message)
    VALUES
        (@batch_id, @layer, @table_name, @start_time, SYSDATETIME(), @rows_loaded, @status, @error_message);
END;
GO
