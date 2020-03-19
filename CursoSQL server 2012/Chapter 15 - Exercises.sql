---------------------------------------------------------------------
-- TK 70-461 - Chapter 15 - Implementing Indexes and Statistics
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Implementing Indexes
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Nonclustered Indexes
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1
---------------------------------------------------------------------

-- 3.
USE tempdb;
SET NOCOUNT ON;
GO

-- 4.
CREATE TABLE dbo.TestStructure
(
id      INT       NOT NULL,
filler1 CHAR(36)  NOT NULL,
filler2 CHAR(216) NOT NULL
);
GO

-- 5.
CREATE NONCLUSTERED INDEX idx_nc_filler1 ON dbo.TestStructure(filler1);
GO

-- 6.
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
GO

-- 7.
DECLARE @i AS int = 0;
WHILE @i < 24472
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, FORMAT(@i,'00000'), 'b');
END;
GO

-- 8.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');

-- 9.
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(24473, '24473', 'b');

-- 10.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

---------------------------------------------------------------------
-- Exercise 2
---------------------------------------------------------------------

-- 1.
TRUNCATE TABLE dbo.TestStructure;
CREATE CLUSTERED INDEX idx_cl_id ON dbo.TestStructure(id);
GO

-- 2.
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
GO

-- 3.
DECLARE @i AS int = 0;
WHILE @i < 28864
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, FORMAT(@i,'00000'), 'b');
END;
GO

-- 4.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');

-- 5.
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(28865, '28865', 'b');

-- 6.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- 7.
DROP TABLE dbo.TestStructure;
GO

---------------------------------------------------------------------
-- Lesson 02 - Using Search Arguments
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the OR and AND Logical Operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
CREATE NONCLUSTERED INDEX idx_nc_shipcity ON Sales.Orders(shipcity);
GO

-- 5.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';

-- 6.
SELECT OBJECT_NAME(S.object_id) AS table_name,
 I.name AS index_name, 
 S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
 INNER JOIN sys.indexes AS i
  ON S.object_id = I.object_id
   AND S.index_id = I.index_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U')
 AND I.name = N'idx_nc_shipcity';

-- 7.
-- Turn on execution plan
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42;

-- 8.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 OR shipcity = N'Vancouver';


---------------------------------------------------------------------
-- Exercise 2
---------------------------------------------------------------------

-- 1.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 AND shipcity = N'Vancouver';
GO

-- 2.
DROP INDEX idx_nc_shipcity ON Sales.Orders;
GO

-- 3.
CREATE NONCLUSTERED INDEX idx_nc_shipcity_i_custid ON Sales.Orders(shipcity)
INCLUDE (custid);
GO

-- 4.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 OR shipcity = N'Vancouver';

-- 5.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 AND shipcity = N'Vancouver';
GO

-- 6.
DROP INDEX idx_nc_shipcity_i_custid ON Sales.Orders;
GO

---------------------------------------------------------------------
-- Lesson 03 - Understanding Statistics
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Manually Maintaining Statistics
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
DECLARE @statistics_name AS NVARCHAR(128), @ds AS NVARCHAR(1000);
DECLARE acs_cursor CURSOR FOR 
SELECT name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
  AND auto_created = 1;
OPEN acs_cursor;
FETCH NEXT FROM acs_cursor INTO @statistics_name;
WHILE @@FETCH_STATUS = 0
BEGIN
 SET @ds = N'DROP STATISTICS Sales.Orders.' + @statistics_name +';';
 EXEC(@ds);
 FETCH NEXT FROM acs_cursor INTO @statistics_name;
END;
CLOSE acs_cursor;
DEALLOCATE acs_cursor;
GO

-- 5.
ALTER DATABASE TSQL2012 
 SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT;
GO

---------------------------------------------------------------------
-- Exercise 2
---------------------------------------------------------------------

-- 1.
CREATE NONCLUSTERED INDEX idx_nc_custid_shipcity ON Sales.Orders(custid, shipcity);
GO

-- 2.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';

-- 4.
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
  AND auto_created = 1;
GO

-- 5.
CREATE STATISTICS st_shipcity ON Sales.Orders(shipcity);
DBCC FREEPROCCACHE;
GO

-- 6.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';
GO

-- 8.
DROP STATISTICS sales.Orders.st_shipcity;
DROP INDEX idx_nc_custid_shipcity ON Sales.Orders;
ALTER DATABASE TSQL2012 
 SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT;
EXEC sys.sp_updatestats;
GO
