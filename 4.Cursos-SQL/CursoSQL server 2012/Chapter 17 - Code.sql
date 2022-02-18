----------------------------------------------------------------------
-- TK 70-461 - Chapter 17 - Understanding Further Optimization Aspects
-- Code
----------------------------------------------------------------------


---------------------------------------------------------------------
-- Lesson 01 - Understanding Plan Iterators
---------------------------------------------------------------------

USE TSQL2012;
SET NOCOUNT ON;
GO

-- Creating a heap
SELECT orderid, productid, unitprice, qty, discount
INTO Sales.OrderDetailsHeap
FROM Sales.OrderDetails;
GO

-- Table scan
SELECT orderid, productid
FROM Sales.OrderDetailsHeap
WHERE orderid = 10248
  AND productid = 11;

-- Clustered index scan, data not returned ordered
SELECT orderid, productid, unitprice
FROM Sales.OrderDetails;

-- Covering nonclustered index scan, data ordered
SELECT orderid, productid
FROM Sales.OrderDetails
ORDER BY productid;
GO

-- Clustered index seek, partial scan, data ordered
SELECT orderid, productid, unitprice
FROM Sales.OrderDetails
WHERE orderid BETWEEN 10250 AND 10390
ORDER BY orderid, productid;
GO

-- Covering nonclustered index seek, partial scan, data ordered
SELECT orderid, productid
FROM Sales.OrderDetails
WHERE productid BETW																																			EEN 10 AND 30
ORDER BY productid;	
GO

-- Nonclustered index seek + RID lookup
-- Creating an index on a heap
CREATE NONCLUSTERED INDEX idx_nc_qtyheap ON Sales.OrderDetailsHeap(qty);
-- Index seek + RID lookup
SELECT orderid, productid, unitprice, qty
FROM Sales.OrderDetailsHeap
WHERE qty = 52;
GO

-- Nonclustered index seek + Key lookup
-- Creating an index on a clustered table
CREATE NONCLUSTERED INDEX idx_nc_qty ON Sales.OrderDetails(qty);
-- Index seek + key lookup
SELECT orderid, productid, unitprice, qty
FROM Sales.OrderDetails
WHERE qty = 52;
GO

-- Clean up
DROP INDEX idx_nc_qtyheap ON Sales.OrderDetailsHeap;
DROP INDEX idx_nc_qty ON Sales.OrderDetails;
DROP TABLE Sales.OrderDetailsHeap;
GO


-- Nested loops join
SELECT O.custid, O.orderdate, OD.orderid, OD.productid,OD.qty
FROM Sales.Orders AS O
 INNER JOIN Sales.OrderDetails AS OD
  ON O.orderid = OD.orderid
WHERE O.orderid < 10250;

-- Merge join
SELECT O.custid, O.orderdate, OD.orderid, OD.productid, OD.qty
FROM Sales.Orders AS O
 INNER JOIN Sales.OrderDetails AS OD
  ON O.orderid = OD.orderid;

-- Two heaps
SELECT orderid, productid, unitprice, qty, discount
INTO Sales.OrderDetailsHeap
FROM Sales.OrderDetails;
SELECT orderid, custid, orderdate
INTO Sales.OrdersHeap
FROM Sales.Orders;
-- Hash join
SELECT O.custid, O.orderdate, OD.orderid, OD.productid, OD.qty
FROM Sales.OrdersHeap AS O
 INNER JOIN Sales.OrderDetailsHeap AS OD
  ON O.orderid = OD.orderid;
GO

-- Clean up
DROP TABLE Sales.OrderDetailsHeap;
DROP TABLE Sales.OrdersHeap;
GO

-- Sort
SELECT orderid, productid, qty
FROM Sales.OrderDetails
ORDER BY qty;

-- Stream aggregate
SELECT productid, COUNT(*) AS num
FROM Sales.OrderDetails
GROUP BY productid;

-- Hash match aggregate
SELECT qty, COUNT(*) AS num
FROM Sales.OrderDetails
GROUP BY qty;
GO

---------------------------------------------------------------------
-- Lesson 02 - Using Parameterized Queries and Batch Operations
---------------------------------------------------------------------

USE TSQL2012;
SET NOCOUNT ON;
GO

-- Clearing the cache
DBCC FREEPROCCACHE;
GO

-- Three queries that produce two different plans
-- Parameter INT
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = 10248;
-- Parameter INT
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = 10249;
-- Parameter DECIMAL
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = 10250.0;
GO

-- Checking the plans
SELECT qs.execution_count AS cnt,
 qt.text
FROM sys.dm_exec_query_stats AS qs 
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text LIKE N'%Orders%' 
  AND qt.text NOT LIKE N'%qs.execution_count%'
ORDER BY qs.execution_count;
GO

-- Clearing the cache
DBCC FREEPROCCACHE
GO

-- Three queries that produce three different plans
-- One row
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 13;
GO
-- Two rows
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 33;
GO
-- 31 rows
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 71;
GO

-- Checking the plans
SELECT qs.execution_count AS cnt,
 qt.text
FROM sys.dm_exec_query_stats AS qs 
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text LIKE N'%Orders%' 
  AND qt.text NOT LIKE N'%qs.execution_count%'
ORDER BY qs.execution_count;
GO

-- Clearing the cache
DBCC FREEPROCCACHE;
GO

-- Two queries that produce two different plans
-- Query that is parameterized
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = 10248;
-- Changing a SET option
SET CONCAT_NULL_YIELDS_NULL OFF;
-- Query that could use the same plan
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = 10249;
-- Restoring the SET option
SET CONCAT_NULL_YIELDS_NULL ON;

-- Checking the plans
SELECT qs.execution_count AS cnt,
 qt.text
FROM sys.dm_exec_query_stats AS qs 
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text LIKE N'%Orders%' 
  AND qt.text NOT LIKE N'%qs.execution_count%'
ORDER BY qs.execution_count;
GO

-- Clearing the cache
DBCC FREEPROCCACHE;
GO

DECLARE @v INT;
DECLARE @s NVARCHAR(500);
DECLARE @p NVARCHAR(500);
-- Build the SQL string
SET @s = N'
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = @orderid';
SET @p = N'@orderid INT';
-- Parameter integral
SET @v = 10248;
EXECUTE sys.sp_executesql @s, @p, @orderid = @v;
-- Parameter decimal
SET @v = 10249.0;
EXECUTE sp_executesql @s, @p, @orderid = @v;

-- Checking the plans
SELECT qs.execution_count AS cnt,
 qt.text
FROM sys.dm_exec_query_stats AS qs 
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text LIKE N'%Orders%' 
  AND qt.text NOT LIKE N'%qs.execution_count%'
ORDER BY qs.execution_count;
GO

-- Stored procedure
CREATE PROCEDURE Sales.GetOrder
(@orderid INT)
AS
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = @orderid;
GO

-- Clearing the cache
DBCC FREEPROCCACHE;
GO

-- Calling the procedure twice with different parameters
EXEC Sales.GetOrder @orderid = 10248;
EXEC Sales.GetOrder @orderid = 10249.0;

-- Checking the plans
SELECT qs.execution_count AS cnt,
 qt.text
FROM sys.dm_exec_query_stats AS qs 
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text LIKE N'%Orders%' 
  AND qt.text NOT LIKE N'%qs.execution_count%'
ORDER BY qs.execution_count;
GO

-- Clean up
DROP PROCEDURE Sales.GetOrder;
GO

-- Batch processing

-- Data distribution settings for DW
DECLARE
  @dim1rows AS INT = 100, 
  @dim2rows AS INT = 50,
  @dim3rows AS INT = 200;
-- First dimension
CREATE TABLE dbo.Dim1
(
  key1  INT NOT NULL CONSTRAINT PK_Dim1 PRIMARY KEY,
  attr1 INT NOT NULL,
  filler BINARY(100) NOT NULL DEFAULT (0x)
);
-- Second dimension
CREATE TABLE dbo.Dim2
(
  key2  INT NOT NULL CONSTRAINT PK_Dim2 PRIMARY KEY,
  attr1 INT NOT NULL,
  filler BINARY(100) NOT NULL DEFAULT (0x)
);
-- Third dimension
CREATE TABLE dbo.Dim3
(
  key3  INT NOT NULL CONSTRAINT PK_Dim3 PRIMARY KEY,
  attr1 INT NOT NULL,
  filler BINARY(100) NOT NULL DEFAULT (0x)
);
-- Fact table
CREATE TABLE dbo.Fact
(
  key1 INT NOT NULL CONSTRAINT FK_Fact_Dim1 FOREIGN KEY REFERENCES dbo.Dim1,
  key2 INT NOT NULL CONSTRAINT FK_Fact_Dim2 FOREIGN KEY REFERENCES dbo.Dim2,
  key3 INT NOT NULL CONSTRAINT FK_Fact_Dim3 FOREIGN KEY REFERENCES dbo.Dim3,
  measure1 INT NOT NULL,
  measure2 INT NOT NULL,
  measure3 INT NOT NULL,
  filler  BINARY(100) NOT NULL DEFAULT (0x),
  CONSTRAINT PK_Fact PRIMARY KEY(key1, key2, key3)
);
-- Populating the first dimension
INSERT INTO dbo.Dim1(key1, attr1)
  SELECT n, ABS(CHECKSUM(NEWID())) % 20 + 1
  FROM dbo.GetNums(1, @dim1rows);
-- Populating the second dimension
INSERT INTO dbo.Dim2(key2, attr1)
  SELECT n, ABS(CHECKSUM(NEWID())) % 10 + 1
  FROM dbo.GetNums(1, @dim2rows);
-- Populating the third dimension
INSERT INTO dbo.Dim3(key3, attr1)
  SELECT n, ABS(CHECKSUM(NEWID())) % 40 + 1
  FROM dbo.GetNums(1, @dim3rows);
-- Populating the fact table
INSERT INTO dbo.Fact WITH (TABLOCK) 
    (key1, key2, key3, measure1, measure2, measure3)
  SELECT N1.n, N2.n, N3.n,
    ABS(CHECKSUM(NEWID())) % 1000000 + 1,
    ABS(CHECKSUM(NEWID())) % 1000000 + 1,
    ABS(CHECKSUM(NEWID())) % 1000000 + 1
  FROM dbo.GetNums(1, @dim1rows) AS N1
    CROSS JOIN dbo.GetNums(1, @dim2rows) AS N2
    CROSS JOIN dbo.GetNums(1, @dim3rows) AS N3;
GO

-- Measuring IO and time
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
-- Query demonstrating star join
SELECT D1.attr1 AS x, D2.attr1 AS y, D3.attr1 AS z, 
  COUNT(*) AS cnt, SUM(F.measure1) AS total
FROM dbo.Fact AS F
 INNER JOIN dbo.Dim1 AS D1
    ON F.key1 = D1.key1
 INNER JOIN dbo.Dim2 AS D2
    ON F.key2 = D2.key2
 INNER JOIN dbo.Dim3 AS D3
    ON F.key3 = D3.key3
WHERE D1.attr1 <= 10
  AND D2.attr1 <= 15
  AND D3.attr1 <= 10
GROUP BY D1.attr1, D2.attr1, D3.attr1;
GO

-- columnstore index
CREATE COLUMNSTORE INDEX idx_cs_fact 
  ON dbo.Fact(key1, key2, key3, measure1, measure2, measure3);
GO

-- Query demonstrating batch processing
SELECT D1.attr1 AS x, D2.attr1 AS y, D3.attr1 AS z, 
  COUNT(*) AS cnt, SUM(F.measure1) AS total
FROM dbo.Fact AS F
 INNER JOIN dbo.Dim1 AS D1
    ON F.key1 = D1.key1
 INNER JOIN dbo.Dim2 AS D2
    ON F.key2 = D2.key2
 INNER JOIN dbo.Dim3 AS D3
    ON F.key3 = D3.key3
WHERE D1.attr1 <= 10
  AND D2.attr1 <= 15
  AND D3.attr1 <= 10
GROUP BY D1.attr1, D2.attr1, D3.attr1;
GO

-- Clean up
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
DROP TABLE dbo.Fact;
DROP TABLE dbo.Dim1;
DROP TABLE dbo.Dim2;
DROP TABLE dbo.Dim3;
GO


---------------------------------------------------------------------
-- Lesson 03 - Using Optimizer Hints and Plan Guides
---------------------------------------------------------------------

USE TSQL2012;
SET NOCOUNT ON;
GO

-- Hash match aggregate
SELECT qty, COUNT(*) AS num
FROM Sales.OrderDetails
GROUP BY qty;
-- Forcing stream aggregate
SELECT qty, COUNT(*) AS num
FROM Sales.OrderDetails
GROUP BY qty
OPTION (ORDER GROUP);
GO

-- Clustered index scan
SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE productid BETWEEN 10 AND 30
ORDER BY productid;
-- Forcing a nonclustered index usage
SELECT orderid, productid, qty
FROM Sales.OrderDetails WITH (INDEX(idx_nc_productid))
WHERE productid BETWEEN 10 AND 30
ORDER BY productid;

-- Nested loops join
SELECT O.custid, O.orderdate, OD.orderid, OD.productid,OD.qty
FROM Sales.Orders AS O
 INNER JOIN Sales.OrderDetails AS OD
  ON O.orderid = OD.orderid
WHERE O.orderid < 10250;
-- Forced merge join
SELECT O.custid, O.orderdate, OD.orderid, OD.productid,OD.qty
FROM Sales.Orders AS O
 INNER MERGE JOIN Sales.OrderDetails AS OD
  ON O.orderid = OD.orderid
WHERE O.orderid < 10250;
GO

-- OBJECT plan guide
-- Stored procedure
CREATE PROCEDURE Sales.GetCustomerOrders
(@custid INT)
AS
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = @custid;
GO

-- Creating a plan guide
-- Optimizing for custid = 71
EXEC sys.sp_create_plan_guide 
 @name = N'Cust71',
 @stmt = N'
  SELECT orderid, custid, empid, orderdate
  FROM Sales.Orders
  WHERE custid = @custid;',
 @type = N'OBJECT',
 @module_or_batch = N'Sales.GetCustomerOrders',
 @params = NULL,
 @hints = N'OPTION (OPTIMIZE FOR (@custid = 71))';
GO

-- Clearing the cache
DBCC FREEPROCCACHE;
-- Executing the procedure with different parameters
EXEC Sales.GetCustomerOrders @custid = 13;
EXEC Sales.GetCustomerOrders @custid = 71;
GO

-- Checking the plan guides
SELECT plan_guide_id, name,	scope_type_desc, is_disabled,
 query_text, hints
FROM sys.plan_guides;																						
GO

-- Clean up
EXEC sys.sp_control_plan_guide N'DROP', N'Cust71';
DROP PROCEDURE Sales.GetCustomerOrders;
GO