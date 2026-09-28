/*
====================================================================
Create Database and Schemas
====================================================================

Purpose:
This script creates a SQL Server database named 'DataWarehouse'.
If the database already exists, it will be dropped and recreated.
After creating the database, three schemas are created to support
a layered data warehouse architecture:
- bronze  : raw source data ingested from upstream systems
- silver  : cleansed, standardized, and transformed data
- gold    : curated, analytics-ready data for reporting and insights

Warning:
Running this script will permanently delete the existing
'DataWarehouse' database and all of its data if it exists.
Ensure proper backups are taken before execution.
====================================================================
*/

USE master;
GO

-- Drop and recreate the DataWarehouse database if it exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create schemas for layered data architecture
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
