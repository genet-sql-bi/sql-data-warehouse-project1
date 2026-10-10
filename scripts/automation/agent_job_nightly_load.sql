/*
========================================================================================================
SQL Server Agent Job: Nightly Data Warehouse Load
========================================================================================================

Purpose:
Creates a SQL Server Agent job that runs the warehouse pipeline automatically every night at 2:00 AM:
    Step 1: EXEC bronze.load_bronze   (CSV -> bronze)
    Step 2: EXEC silver.load_silver   (bronze -> silver)

The gold layer is made of views over silver, so it needs no load step: as soon as silver commits,
gold (and Power BI on its next refresh) sees the new data.

Failure handling:
- Each load procedure runs in one transaction and re-throws on error, so a failure fails the job step.
- If bronze fails, the job stops and silver does NOT run on top of bad bronze data.
- Each step retries once after 5 minutes (e.g. a CSV still being written). Retrying is safe because
  every load is atomic and fully reloads its tables.
- Every run is recorded twice: in the Agent job history and, per table, in etl.load_log.

Re-runnable:
If the job already exists it is dropped and recreated, so this script can be run any number of times.

Prerequisites:
- SQL Server Agent service is running (Object Explorer -> SQL Server Agent -> right-click -> Start).
- The SQL Server service account (e.g. NT Service\MSSQLSERVER) can read the 'datasets' folder,
  because BULK INSERT runs under that account when called from a job.

How to run it manually (without waiting for 2:00 AM):
    EXEC msdb.dbo.sp_start_job @job_name = N'DWH - Nightly Load';
========================================================================================================
*/

USE msdb;
GO

DECLARE @job_name SYSNAME = N'DWH - Nightly Load';

-- Drop the job if it already exists, so the script is re-runnable
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job_name)
    EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_unused_schedule = 1;

-- 1. Create the job
EXEC msdb.dbo.sp_add_job
    @job_name    = @job_name,
    @enabled     = 1,
    @description = N'Nightly load of the data warehouse: bronze, then silver. Gold views update automatically.';

-- 2. Step 1: load bronze
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = @job_name,
    @step_id           = 1,
    @step_name         = N'Load Bronze',
    @subsystem         = N'TSQL',
    @database_name     = N'DataWarehouse',
    @command           = N'EXEC bronze.load_bronze;',
    @retry_attempts    = 1,
    @retry_interval    = 5,          -- minutes
    @on_success_action = 3,          -- go to next step
    @on_fail_action    = 2;          -- quit the job, reporting failure

-- 3. Step 2: load silver
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = @job_name,
    @step_id           = 2,
    @step_name         = N'Load Silver',
    @subsystem         = N'TSQL',
    @database_name     = N'DataWarehouse',
    @command           = N'EXEC silver.load_silver;',
    @retry_attempts    = 1,
    @retry_interval    = 5,
    @on_success_action = 1,          -- quit the job, reporting success
    @on_fail_action    = 2;          -- quit the job, reporting failure

-- 4. Schedule: every day at 2:00 AM
EXEC msdb.dbo.sp_add_jobschedule
    @job_name          = @job_name,
    @name              = N'Daily 2:00 AM',
    @enabled           = 1,
    @freq_type         = 4,          -- daily
    @freq_interval     = 1,          -- every 1 day
    @active_start_time = 020000;     -- HHMMSS

-- 5. Register the job on this server
EXEC msdb.dbo.sp_add_jobserver
    @job_name    = @job_name,
    @server_name = N'(local)';

/*
Optional: email alert on failure.
Requires Database Mail and an Agent operator to be configured first, then:

    EXEC msdb.dbo.sp_update_job
        @job_name                   = N'DWH - Nightly Load',
        @notify_level_email         = 2,              -- 2 = on failure
        @notify_email_operator_name = N'DWH Admins';
*/
GO