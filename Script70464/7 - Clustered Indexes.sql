-- Demonstration 7 - Clustered Indexes

-- Step 1: Open a new query window against the tempdb database

USE tempdb;
GO

-- Create a table without a primary key
CREATE TABLE dbo.PhoneLog
( PhoneLogID int IDENTITY(1,1),
  LogRecorded datetime2 NOT NULL,
  PhoneNumberCalled nvarchar(100) NOT NULL,
  CallDurationMs int NOT NULL
);
GO

-- Show execution plan for a scan
SELECT * FROM dbo.PhoneLog

-- Drop table
DROP TABLE dbo.PhoneLog


-- Step 2: Create a table with a primary key specified

CREATE TABLE dbo.PhoneLog
( PhoneLogID int IDENTITY(1,1) PRIMARY KEY,
  LogRecorded datetime2 NOT NULL,
  PhoneNumberCalled nvarchar(100) NOT NULL,
  CallDurationMs int NOT NULL
);
GO

-- Show execution plan for a scan
SELECT * FROM dbo.PhoneLog


-- Step 3: Query sys.indexes to view the structure
-- (note also the name chosen by SQL Server for the constraint and index)

SELECT * FROM sys.indexes WHERE OBJECT_NAME(object_id) = N'PhoneLog';
GO
SELECT * FROM sys.key_constraints WHERE OBJECT_NAME(parent_object_id) = N'PhoneLog';
GO
-- Drop table
DROP TABLE dbo.PhoneLog


