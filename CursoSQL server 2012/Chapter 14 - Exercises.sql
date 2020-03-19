---------------------------------------------------------------------
-- TK 70-461 - Chapter 14 - Using Tools to Analyze Query Performance
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Getting Started with Query Optimization
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Extended Events
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
   ON C.custid = O.custid
ORDER BY C.custid, O.orderid;
GO


---------------------------------------------------------------------
-- Lesson 02 - Using SET Session Options and Analyzing Query Plans
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - SET Session Options and Execution Plans
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Analyzing a Query
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
SELECT N1.n * 100000 + O.orderid AS norderid,
       O.*
INTO dbo.NewOrders
FROM Sales.Orders AS O
 CROSS JOIN (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),
                   (10),(11),(12),(13),(14),(15),(16),
				   (17),(18),(19),(20),(21),(22),(23),
				   (24),(25),(26),(27),(28),(29),(30)) AS N1(n);
GO

-- 5.
CREATE NONCLUSTERED INDEX idx_nc_orderid
 ON dbo.NewOrders(orderid);
GO

-- 6.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- 7.
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 8.
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- 9. Turn on the actual execution plan
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 12.
CREATE NONCLUSTERED INDEX idx_nc_norderid
 ON dbo.NewOrders(norderid);
GO

-- 13.
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 14. Turn off execution plan

-- 15. Clean up
DROP TABLE dbo.NewOrders;
GO


---------------------------------------------------------------------
-- Lesson 03 - Using Dynamic Management Objects
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Index Related DMOs
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Finding Not Used and Missing Indexes
---------------------------------------------------------------------

-- 1. Restart SQL Server

-- 3.
USE TSQL2012;

-- 4. Not used nonclustered indexes
SELECT OBJECT_NAME(I.object_id) AS objectname,
 I.name AS indexname,
 I.index_id AS indexid
FROM sys.indexes AS I
 INNER JOIN sys.objects AS O
  ON O.object_id = I.object_id
WHERE I.object_id > 100
  AND I.type_desc = 'NONCLUSTERED'
  AND I.index_id NOT IN 
       (SELECT S.index_id 
        FROM sys.dm_db_index_usage_stats AS S
        WHERE S.object_id=I.object_id
          AND I.index_id=S.index_id
          AND database_id = DB_ID('TSQL2012'))
ORDER BY objectname, indexname;

-- 6. Recreation of the table from previous practice 
--    and reproducing the missing index problem
SELECT N1.n * 100000 + O.orderid AS norderid,
       O.*
INTO dbo.NewOrders
FROM Sales.Orders AS O
 CROSS JOIN (VALUES(1),(2),(3)) AS N1(n);
GO
CREATE NONCLUSTERED INDEX idx_nc_orderid
 ON dbo.NewOrders(orderid);
GO
SELECT norderid
FROM dbo.NewOrders
WHERE norderid = 110248
ORDER BY norderid;
GO

-- 7. Missing indexes
SELECT MID.statement AS [Database.Schema.Table],
 MIC.column_id AS ColumnId,
 MIC.column_name AS ColumnName,
 MIC.column_usage AS ColumnUsage, 
 MIGS.user_seeks AS UserSeeks,
 MIGS.user_scans AS UserScans,
 MIGS.last_user_seek AS LastUserSeek,
 MIGS.avg_total_user_cost AS AvgQueryCostReduction,
 MIGS.avg_user_impact AS AvgPctBenefit
FROM sys.dm_db_missing_index_details AS MID
 CROSS APPLY sys.dm_db_missing_index_columns (MID.index_handle) AS MIC
 INNER JOIN sys.dm_db_missing_index_groups AS MIG 
	ON MIG.index_handle = MIG.index_handle
 INNER JOIN sys.dm_db_missing_index_group_stats AS MIGS 
	ON MIG.index_group_handle=MIGS.group_handle
ORDER BY MIGS.avg_user_impact DESC;
GO																																																												

-- 14. Clean up
DROP TABLE dbo.NewOrders;
GO
