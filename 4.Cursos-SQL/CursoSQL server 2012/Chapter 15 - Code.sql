---------------------------------------------------------------------
-- TK 70-461 - Chapter 15 - Implementing Indexes and Statistics
-- Code
---------------------------------------------------------------------


---------------------------------------------------------------------
-- Lesson 01 - Implementing Indexes
---------------------------------------------------------------------

USE tempdb;
SET NOCOUNT ON;
GO

-- Test table
IF OBJECT_ID(N'dbo.TestStructure', N'U') IS NOT NULL
   DROP TABLE dbo.TestStructure;
GO
-- Heap
CREATE TABLE dbo.TestStructure
(
id      INT       NOT NULL,
filler1 CHAR(36)  NOT NULL,
filler2 CHAR(216) NOT NULL
);
GO

-- Table stored as a heap, type 0
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
GO

-- No pages allocated after creation, no reserved
-- SQL allocates pages only on demand
SELECT index_type_desc, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;
GO

-- Insert first row
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(1, 'a', 'b');
GO

-- IAM + one page allocated, two pages reserved
-- First pages are allocated on mixed extends
SELECT index_type_desc, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;
GO

-- Fill the first page
DECLARE @i AS int = 1;
WHILE @i < 30
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, 'a', 'b');
END;
GO

-- Still IAM + one page allocated, two pages reserved
--Heap pages are filled up
SELECT index_type_desc, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
EXEC sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;
GO

-- One more row
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(31, 'a', 'b');
GO

-- IAM  + two pages allocated, three pages reserved
-- If a row doesn't fit anymore, SQL Server reserves a new page on a mixed extent
SELECT index_type_desc, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
EXEC sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;
GO

-- Fill 8 pages
DECLARE @i AS int = 31;
WHILE @i < 240
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, 'a', 'b');
END;
GO

-- IAM + 8 pages allocated, 9 pages reserved
SELECT index_type_desc, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
EXEC sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;
GO

-- One more row
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(241, 'a', 'b');
GO

-- IAM + 9 pages allocated; 2 extents + one page reserved
-- From the 9th page on SQL Server reserves uniform extents
-- The first 8 pages stay on mixed extents
SELECT index_type_desc, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
EXEC sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;
GO

-- Truncate the table and add a clustered index using id
TRUNCATE TABLE dbo.TestStructure;
CREATE CLUSTERED INDEX idx_cl_id ON dbo.TestStructure(id);
GO

-- Heap does not exist anymore
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
GO

-- Fill 621 pages - id unique
DECLARE @i AS int = 0;
WHILE @i < 18630
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, 'a', 'b');
END;
GO

-- Two levels on index
-- Leaf level with data, and a single root page
SELECT index_type_desc, index_depth, index_level, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- One more row
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(18631, 'a', 'b');
GO

-- Three levels of index
-- If SQL Server cannot reference every page on the leaf anymore, 
-- it reorganizes the index levels and adds an additional level. 
SELECT index_type_desc, index_depth, index_level, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- Truncate the table
-- Non-unique index - influence of uniquifier
TRUNCATE TABLE dbo.TestStructure;
DECLARE @i AS int = 0;
WHILE @i < 8908
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i % 100, 'a', 'b');
END;
GO

-- Two levels on index
SELECT index_type_desc, index_depth, index_level, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- One more row
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(8909 % 100, 'a', 'b');
GO

-- Three levels of index
-- If the index is not unique, SQL Server has to add a uniquifier to the key 
-- to make it internally unique. Uniquifier is a 4 byte int.
-- Therefore SQL Server has to ad an additional level much earlier. 
SELECT index_type_desc, index_depth, index_level, page_count, 
 record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- Fragmentation

-- Truncate the table, drop existing cl index,
-- create cl index using filler1
-- Sequential values in filler1
TRUNCATE TABLE dbo.TestStructure;
DROP INDEX idx_cl_id ON dbo.TestStructure;
CREATE CLUSTERED INDEX idx_cl_filler1 ON dbo.TestStructure(filler1);
DECLARE @i AS int = 0;
WHILE @i < 9000
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, FORMAT(@i,'0000'), 'b');
END;
GO

-- All pages on the leaf level are filled and the table is not fragmented
-- as all new rows are added to the end of the index
SELECT index_level, page_count,
 avg_page_space_used_in_percent, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- Truncate the table
-- Random values in filler1
TRUNCATE TABLE dbo.TestStructure;
DECLARE @i AS int = 0;
WHILE @i < 9000
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, CAST(NEWID() AS CHAR(36)), 'b');
END;
GO

-- 130+ more pages on the leaf level (almost 50%), as the pages are only filled 68%
-- on average (internal fragmentation), because of the page split.
-- The pages itself are fragmented in the data file, 
-- which leads to external fragmentation of 99%.
SELECT index_level, page_count,
 avg_page_space_used_in_percent, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- Rebuilding the index
ALTER INDEX idx_cl_filler1 ON dbo.TestStructure REBUILD;
GO

-- Nearly no fragmentation after the rebuild
SELECT index_level, page_count,
 avg_page_space_used_in_percent, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure',N'U'), NULL, NULL , 'DETAILED');
GO

-- Clean up
USE tempdb;
IF OBJECT_ID(N'dbo.TestStructure', N'U') IS NOT NULL
   DROP TABLE dbo.TestStructure;
GO


-- Indexed views
SET NOCOUNT ON;
GO

USE TSQL2012;
SET STATISTICS IO ON;
-- Aggregate query with a join
SELECT O.shipcountry, SUM(OD.qty) AS totalordered
FROM Sales.OrderDetails AS OD
 INNER JOIN Sales.Orders AS O
  ON OD.orderid = O.orderid
GROUP BY O.shipcountry;
-- Table 'OrderDetails'. Scan count 1, logical reads 11 
-- Table 'Orders'. Scan count 1, logical reads 21
GO

-- Create a view from the query
IF OBJECT_ID(N'Sales.QuantityByCountry', N'V') IS NOT NULL
   DROP VIEW Sales.QuantityByCountry;
GO
CREATE VIEW Sales.QuantityByCountry
WITH SCHEMABINDING
AS
SELECT O.shipcountry, SUM(OD.qty) AS total_ordered,
 COUNT_BIG(*) AS number_of_rows
FROM Sales.OrderDetails AS OD
 INNER JOIN Sales.Orders AS O
  ON OD.orderid = O.orderid
GROUP BY O.shipcountry;
GO
-- Index the view
CREATE UNIQUE CLUSTERED INDEX idx_cl_shipcountry
ON Sales.QuantityByCountry(shipcountry);
GO

-- Repeat the aggregate query with a join
SELECT O.shipcountry, SUM(OD.qty) AS totalordered
FROM Sales.OrderDetails AS OD
 INNER JOIN Sales.Orders AS O
  ON OD.orderid = O.orderid
GROUP BY O.shipcountry;
-- Table 'QuantityByCountry'. Scan count 1, logical reads 2
GO

-- Clean up
SET STATISTICS IO OFF;
DROP VIEW Sales.QuantityByCountry;
GO

---------------------------------------------------------------------
-- Lesson 02 - Using Search Arguments
---------------------------------------------------------------------

-- Restart SQL Server and reconnect
SET NOCOUNT ON;
USE TSQL2012;
GO

-- Include actual execution plan
-- No indexes used
SELECT OBJECT_NAME(S.object_id) AS table_name,
 I.name AS index_name, 
 S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
 INNER JOIN sys.indexes AS i
  ON S.object_id = I.object_id
   AND S.index_id = I.index_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U');
GO

-- No search arguments, cl index scan
SELECT orderid, custid, shipcity
FROM Sales.Orders;

-- Search arguments not supported by an index, cl index scan
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';

-- Supporting joins with indexes will be covered in chapter 17

-- Aggregation not supported by an index, cl index scan, hash aggregate
SELECT shipregion, COUNT(*) AS num_regions
FROM Sales.Orders
GROUP BY shipregion;

-- Order not supported by an index, cl index scan, sort
SELECT shipregion
FROM Sales.Orders
ORDER BY shipregion;
GO

-- cl index used for 4 scans
SELECT OBJECT_NAME(S.object_id) AS table_name,
 I.name AS index_name, 
 S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
 INNER JOIN sys.indexes AS i
  ON S.object_id = I.object_id
   AND S.index_id = I.index_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U');
GO

-- Add nc index on shipregion
CREATE NONCLUSTERED INDEX idx_nc_shipregion ON Sales.Orders(shipregion);
GO

-- Aggregation supported by an index, nc index scan, stream aggregate
-- Query that aggregates the data
SELECT shipregion, COUNT(*) AS num_regions
FROM Sales.Orders
GROUP BY shipregion;

-- Order supported by an index, nc index scan, no sort
-- Query that sorts the output
SELECT shipregion
FROM Sales.Orders
ORDER BY shipregion;
GO

-- nc index used for two scans
-- Both queries were covered by the nc index
SELECT OBJECT_NAME(S.object_id) AS table_name,
 I.name AS index_name, 
 S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
 INNER JOIN sys.indexes AS i
  ON S.object_id = I.object_id
   AND S.index_id = I.index_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U');
GO

-- Drop nc index on shipregion
DROP INDEX idx_nc_shipregion ON Sales.Orders;
GO

-- SARGs
-- Not a SARG
SELECT orderid, custid, orderdate, shipname
FROM Sales.Orders
WHERE DATEDIFF(day, '20060709', orderdate) <= 2
 AND DATEDIFF(day, '20060709', orderdate) > 0;

-- SARG
SELECT orderid, custid, orderdate, shipname
FROM Sales.Orders
WHERE DATEADD(day, 2, '20060709') >= orderdate
 AND '20060709' < orderdate;

-- SARG
SELECT orderid, custid, orderdate, shipname
FROM Sales.Orders
WHERE orderdate IN ('20060710', '20060711');

-- SARG
SELECT orderid, custid, orderdate, shipname
FROM Sales.Orders
WHERE orderdate = '20060710'
 OR orderdate = '20060711';
GO


---------------------------------------------------------------------
-- Lesson 03 - Understanding Statistics
---------------------------------------------------------------------

SET NOCOUNT ON;
USE TSQL2012;
GO

-- Drop all auto-created statistics, if exists
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

-- Check statistics for Sales.Orders
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS statistics_name, auto_created
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U');
GO

-- Rebuild an index to make sure that the statists is updated
ALTER INDEX idx_nc_empid ON Sales.Orders REBUILD;
GO

-- Show the statistics histogram
DBCC SHOW_STATISTICS(N'Sales.Orders',N'idx_nc_empid') WITH HISTOGRAM;
GO

-- Show the statistics header
DBCC SHOW_STATISTICS(N'Sales.Orders',N'idx_nc_empid') WITH STAT_HEADER;
GO

-- Add nc index on custid, shipcity
CREATE NONCLUSTERED INDEX idx_nc_custid_shipcity ON Sales.Orders(custid, shipcity);
GO

-- 3 rows, nc index seek, 3 rows estimated
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42;

-- No auto-created statistics
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
  AND auto_created = 1;

-- same 3 rows, nc index scan, 3 rows estimated
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';

-- Auto-created statistics exists
SELECT OBJECT_NAME(s.object_id) AS table_name,
 S.name AS statistics_name, C.name AS column_name
FROM sys.stats AS S 
 INNER JOIN sys.stats_columns AS SC
  ON S.stats_id = SC.stats_id
 INNER JOIN sys.columns AS C
  ON S.object_id= C.object_id AND SC.column_id = C.column_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U')
  AND auto_created = 1;
GO

-- Clean up
DROP INDEX idx_nc_custid_shipcity ON Sales.Orders;
-- Drop all auto-created statistics, if exists
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
