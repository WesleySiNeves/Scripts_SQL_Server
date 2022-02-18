--Skill 4.1: Optimize statistics and indexes 

----Determine the accuracy of statistics and the associated impact to query plans and performance
------LISTING 4-1 Create an index and show its statistics
Use WideWorldImporters;
GO
CREATE NONCLUSTERED INDEX IX_Purchasing_Suppliers_ExamBook762Ch4 
    ON Purchasing.Suppliers
(
    SupplierCategoryID,
	SupplierID
)
INCLUDE (SupplierName);
GO
DBCC SHOW_STATISTICS ('Purchasing.Suppliers', 
    IX_Purchasing_Suppliers_ExamBook762Ch4 );
GO

------LISTING 4-2 Create test environment with automatic statistics disabled
CREATE DATABASE ExamBook762Ch4_Statistics;
GO
ALTER DATABASE ExamBook762Ch4_Statistics
    SET   AUTO_CREATE_STATISTICS OFF;
ALTER DATABASE ExamBook762Ch4_Statistics
    SET AUTO_UPDATE_STATISTICS OFF;
ALTER DATABASE ExamBook762Ch4_Statistics
    SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
GO
USE ExamBook762Ch4_Statistics;
GO
CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.OrderLines (
    OrderLineID int NOT NULL,
    OrderID int NOT NULL,
    StockItemID int NOT NULL,
    Description nvarchar(100) NOT NULL,
    PackageTypeID int NOT NULL,
    Quantity int NOT NULL,
    UnitPrice decimal(18, 2) NULL,
    TaxRate decimal(18, 3) NOT NULL,
    PickedQuantity int NOT NULL,
    PickingCompletedWhen datetime2(7) NULL,
    LastEditedBy int NOT NULL,
    LastEditedWhen datetime2(7) NOT NULL);
GO
INSERT INTO Examples.OrderLines
SELECT * 
FROM WideWorldImporters.Sales.OrderLines;
GO

CREATE INDEX ix_OrderLines_StockItemID
    ON Examples.OrderLines (StockItemID);
GO

DBCC SHOW_STATISTICS ('Examples.OrderLines', 
    ix_OrderLines_StockItemID );
GO


------LISTING 4-3 Update table rows and check statistics
UPDATE Examples.OrderLines
    SET StockItemID = 1
    WHERE OrderLineID < 45000;
DBCC SHOW_STATISTICS ('Examples.OrderLines', 
    ix_OrderLines_StockItemID );
GO

------Include Actual Execution Plan and run this query
SELECT StockItemID
FROM Examples.OrderLines
WHERE StockItemID = 1;


------LISTING 4-4 Check auto-created statistics in a database
USE WideWorldImporters;
GO
SELECT 
    OBJECT_NAME(object_id) AS ObjectName,
	name, 
	auto_created
FROM sys.stats
WHERE auto_created = 1 AND
    object_id IN 
        (SELECT objected FROM sys.objects WHERE type = 'U');


------LISTING 4-5 Check last update of statistics for an object
SELECT 
    name AS ObjectName,   
    STATS_DATE(object_id, stats_id) AS UpdateDate  
FROM sys.stats   
WHERE object_id = OBJECT_ID('Purchasing.Suppliers'); 


----Design statistics maintenance tasks
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'Agent XPs', 1;
GO
RECONFIGURE;
GO 

----LISTING 4-6 Script to update statistics for a specific table
USE WideWorldImporters;
GO
UPDATE STATISTICS [Application].[Cities] 
WITH FULLSCAN
GO


----Use dynamic management objects to review current index usage and identify missing indexes
-----LISTING 4-7 Review current index usage
SELECT 
    OBJECT_NAME(ixu.object_id, DB_ID('WideWorldImporters')) AS [object_name] ,
    ix.[name] AS index_name ,
    ixu.user_seeks + ixu.user_scans + ixu.user_lookups AS user_reads,
	ixu.user_updates AS user_writes
FROM sys.dm_db_index_usage_stats ixu
INNER JOIN WideWorldImporters.sys.indexes ix ON 
    ixu.[object_id] = ix.[object_id] AND 
	ixu.index_id = ix.index_id 
WHERE ixu.database_id = DB_ID('WideWorldImporters')
ORDER BY user_reads DESC;

-----LISTING 4-8 Find unused indexes
SELECT 
    OBJECT_NAME(ix.object_id) AS ObjectName ,
    ix.name
FROM sys.indexes AS ix
INNER JOIN sys.objects AS o ON 
    ix.object_id = o.object_id
WHERE ix.index_id NOT IN ( 
    SELECT ixu.index_id
    FROM sys.dm_db_index_usage_stats AS ixu
    WHERE 
	    ixu.object_id = ix.object_id AND 
		ixu.index_id = ix.index_id AND 
		database_id = DB_ID() 
	) AND 
	o.[type] = 'U'
ORDER BY OBJECT_NAME(ix.object_id) ASC ;


-----LISTING 4-9 Find indexes that are updated but never used
SELECT 
    o.name AS ObjectName ,
    ix.name AS IndexName ,
    ixu.user_seeks + ixu.user_scans + ixu.user_lookups AS user_reads ,
    ixu.user_updates AS user_writes ,
    SUM(p.rows) AS total_rows
FROM sys.dm_db_index_usage_stats ixu
INNER JOIN sys.indexes ix ON 
    ixu.object_id = ix.object_id AND 
	ixu.index_id = ix.index_id
INNER JOIN sys.partitions p ON 
    ixu.object_id = p.object_id AND 
	ixu.index_id = p.index_id
INNER JOIN sys.objects o ON 
    ixu.object_id = o.object_id
WHERE 
    ixu.database_id = DB_ID() AND 
	OBJECTPROPERTY(ixu.object_id, 'IsUserTable') = 1 AND 
	ixu.index_id > 0
GROUP BY 
 o.name ,
 ix.name ,
 ixu.user_seeks + ixu.user_scans + ixu.user_lookups ,
 ixu.user_updates
HAVING ixu.user_seeks + ixu.user_scans + ixu.user_lookups = 0
ORDER BY ixu.user_updates DESC,
 o.name ,
 ix.name ;

 
------LISTING 4-10 Review index fragmentation
DECLARE  @db_id SMALLINT, @object_id INT;
SET @db_id = DB_ID(N'WideWorldImporters');
SET @object_id = OBJECT_ID(N'WideWorldImporters.Sales.Orders');

SELECT
   ixs.index_id AS idx_id,
   ix.name AS ObjectName, 
   index_type_desc, 
   page_count AS pg_ct, 
   avg_page_space_used_in_percent AS AvgPageSpacePct, 
   fragment_count AS frag_ct,
   avg_fragmentation_in_percent AS AvgFragPct
FROM sys.dm_db_index_physical_stats 
    (@db_id, @object_id, NULL, NULL , 'Detailed') ixs
INNER JOIN sys.indexes ix ON 
    ixs.index_id = ix.index_id AND 
	ixs.object_id = ix.object_id
ORDER BY avg_fragmentation_in_percent DESC;


------LISTING 4-11 Review missing indexes
SELECT
    (user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01) AS IndexImprovement,
    id.statement,
    id.equality_columns,
    id.inequality_columns,
    id.included_columns
FROM sys.dm_db_missing_index_group_stats AS igs
INNER JOIN sys.dm_db_missing_index_groups AS ig
    ON igs.group_handle = ig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS id
    ON ig.index_handle = id.index_handle
ORDER BY IndexImprovement DESC;

----Consolidate overlapping indexes
------LISTING 4-12 Create overlapping indexes
USE [WideWorldImporters];
GO
CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_ExamBook762Ch4_A] 
    ON [Sales].[Invoices]
(
	[CustomerID],
	[InvoiceDate] 
)
INCLUDE ([TotalDryItems]);
GO

CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_ExamBook762Ch4_B] 
    ON [Sales].[Invoices]
(
	[CustomerID],
	[InvoiceDate],
    [CustomerPurchaseOrderNumber]
)
INCLUDE ([TotalDryItems]);
GO

------LISTING 4-13 Find overlapping indexes
WITH IndexColumns AS (
    SELECT 
	    '[' + s.Name + '].[' + T.Name + ']' AS TableName,
        ix.name AS IndexName,  
        c.name AS ColumnName, 
        ix.index_id,
        ixc.index_column_id,
        COUNT(*) OVER(PARTITION BY t.OBJECT_ID, ix.index_id) AS ColumnCount
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t ON 
	    t.schema_id = s.schema_id
    INNER JOIN sys.indexes AS ix ON 
	    ix.OBJECT_ID = t.OBJECT_ID
    INNER JOIN sys.index_columns AS ixc ON  
	    ixc.OBJECT_ID = ix.OBJECT_ID AND 
		ixc.index_id = ix.index_id
    INNER JOIN sys.columns AS c ON  
	    c.OBJECT_ID = ixc.OBJECT_ID AND 
		c.column_id = ixc.column_id
    WHERE 
        ixc.is_included_column = 0 AND
        LEFT(ix.name, 2) NOT IN ('PK', 'UQ', 'FK')
)
SELECT DISTINCT 
    ix1.TableName, 
	ix1.IndexName AS Index1, 
	ix2.IndexName AS Index2
FROM IndexColumns AS ix1
INNER JOIN IndexColumns AS ix2 ON 
    ix1.TableName = ix2.TableName AND 
	ix1.IndexName <> ix2.IndexName AND 
	ix1.index_column_id = ix2.index_column_id AND  
	ix1.ColumnName = ix2.ColumnName AND 
	ix1.index_column_id < 3 AND 
	ix1.index_id < ix2.index_id AND 
	ix1.ColumnCount <= ix2.ColumnCount
ORDER BY ix1.TableName, ix2.IndexName; 


--Skill 4.2 Analyze and troubleshoot query plans

----Capture query plans using extended events and traces
------Listing 4-14 Create and start an Extended Event session to capture an actual query plan
IF EXISTS(SELECT * 
          FROM sys.server_event_sessions 
          WHERE name='ActualQueryPlans')
    DROP EVENT SESSION ActualQueryPlans 
    ON SERVER;
GO

CREATE EVENT SESSION ActualQueryPlans
ON SERVER
ADD EVENT sqlserver.query_post_execution_showplan(
    ACTION (sqlserver.database_name,
	        sqlserver.client_hostname,
			sqlserver.client_app_name,
            sqlserver.plan_handle,
            sqlserver.sql_text,
            sqlserver.tsql_stack,
            package0.callstack,
			sqlserver.query_hash,
			sqlserver.session_id,
            sqlserver.request_id)

WHERE 
    sqlserver.database_name='WideWorldImporters'
	AND object_type = 'ADHOC'
)
ADD TARGET package0.event_file(SET filename=N'C:\ExamBook762Ch4\ActualQueryPlans.xel',
    max_file_size=(5),max_rollover_files=(4)),
ADD TARGET package0.ring_buffer
WITH (MAX_DISPATCH_LATENCY=5SECONDS, TRACK_CAUSALITY=ON);
GO
ALTER EVENT SESSION ActualQueryPlans 
	ON SERVER
	STATE=START;
GO
------Generate an event by executing a query
SELECT * 
FROM Warehouse.StockGroups;

------Listing 4-15 Disable or drop extended event sessions
--Disable extended event session
ALTER EVENT SESSION ActualQueryPlans 
    ON SERVER
    STATE=STOP;
GO
--Drop extended event session 
IF EXISTS(SELECT * 
    FROM sys.server_event_sessions 
    WHERE name='ActualQueryPlans')
    DROP EVENT SESSION ActualQueryPlans 
    ON SERVER;
GO

------Listing 4-16 Create a trace, add events and filter to a trace, and start a trace
USE master;
GO
DECLARE @TraceID int;
EXEC sp_trace_create 
    @TraceID output, 
	0, 
	N'C:\ExamBook762Ch4\ActualQueryPlanTrc';

EXEC sp_trace_setevent @TraceID, 
    146,    -- Showplan XML Statistics Profile
	27,     -- BinaryData column
	1;      -- Column is ON for this event 

EXEC sp_trace_setevent @TraceID, 
    146, 
	1,       -- TextData column
	1;   

EXEC sp_trace_setevent @TraceID, 
    146, 
	14,      -- StartTime column
	1;   

EXEC sp_trace_setevent @TraceID, 
    146, 
	15,      -- EndTime column
	1;   
  
-- Set filter for database
EXEC sp_trace_setfilter @TraceID, 
   @ColumnID = 35, --Database Name
   @LogicalOperator = 0, -- Logical AND
   @ComparisonOperator = 6, -- Comparison LIKE
   @Value = N'WideWorldImporters' ;

-- Set filter for application name
 EXEC sp_trace_setfilter @TraceID, 
   @ColumnID = 10, --ApplicationName
   @LogicalOperator = 0, -- Logical AND
   @ComparisonOperator = 6, -- Comparison LIKE
   @Value = N'Microsoft SQL Server Management Studio - Query' ; 

-- Set filter for application name
 EXEC sp_trace_setfilter @TraceID, 
   @ColumnID = 10, --ObjectName
   @LogicalOperator = 0, -- Logical AND
   @ComparisonOperator = 6, -- Comparison LIKE
   @Value = N'Microsoft SQL Server Management Studio - Query' ; 


-- Start Trace (status 1 = start)  
EXEC sp_trace_setstatus @TraceID, 1;
GO  

USE WideWorldImporters;
GO
SELECT * 
FROM Warehouse.StockGroups;
GO

------Listing 4-17 Stop and delete a trace
----  Find the trace ID
USE master;
GO
SELECT * 
FROM sys.fn_trace_getinfo(0)
WHERE value = 'C:\ExamBook762Ch4\ActualQueryPlanTrc.trc';

-- Set  the trace status to stop
EXEC sp_trace_setstatus 
    @traceid = <traceid>, 
	@status= 0;
GO

-- Close and Delete the trace
EXEC sp_trace_setstatus 
    @traceid = <traceid>, 
	@status = 2;
GO


------Listing 4-18 Get event and column identifiers for use in a trace definition
--Get event identifiers 
SELECT 
    e.trace_event_id AS EventID, 
    e.name AS EventName, 
    c.name AS CategoryName
FROM sys.trace_events e
JOIN sys.trace_categories c 
    ON e.category_id = c.category_id
ORDER BY e.trace_event_id;

--Get column identifiers for events
SELECT 
    trace_column_id, 
    name AS ColumnName
FROM sys.trace_columns
ORDER BY trace_column_id;

----Identify poorly performing query plan operators 

------Table scan
SELECT * 
FROM Warehouse.VehicleTemperatures;

------Clustered Index Scan
SELECT * 
FROM Warehouse.StockGroups;

------Clustered Index Seek
SELECT * 
FROM Warehouse.StockGroups
WHERE StockGroupID = 1;

----Index Seek (NonClustered) and Key Lookup
SELECT 
    StockGroupID,
	StockGroupName,
	ValidFrom,
	ValidTo
FROM Warehouse.StockGroups
WHERE StockGroupName = 'Novelty Items';


----Sort without Clustered Index Key
SELECT * 
FROM Warehouse.StockItems
ORDER BY StockItemName;

----Sort on Clustered Index Key
SELECT * 
FROM Warehouse.StockItems
ORDER BY StockItemID;

----Hash Match (Aggregate)
SELECT 
   YEAR(InvoiceDate) AS InvoiceYear,
   COUNT(InvoiceID) AS InvoiceCount
FROM Sales.Invoices
GROUP BY YEAR(InvoiceDate);

------Listing 4-19 Create an indexed view to improve aggregate query performance
CREATE VIEW Sales.vSalesByYear
WITH SCHEMABINDING
AS
    SELECT 
   YEAR(InvoiceDate) AS InvoiceYear,
   COUNT_BIG(*) AS InvoiceCount
FROM Sales.Invoices
GROUP BY YEAR(InvoiceDate);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vSalesByYear
    ON Sales.vSalesByYear
	(InvoiceYear);
GO

----Hash Match (Inner Join)
SELECT 
    si.StockItemName,
	c.ColorName,
	s.SupplierName
FROM Warehouse.StockItems si
INNER JOIN Warehouse.Colors c ON
  c.ColorID = si.ColoriD
INNER JOIN Purchasing.Suppliers s ON
    s.SupplierID = si.SupplierID;

------Listing 4-20 Add indexes to eliminate Hash Match (Inner Join) operators
CREATE NONCLUSTERED INDEX IX_Purchasing_Suppliers_ExamBook762Ch4_SupplierID 
    ON Purchasing.Suppliers
(
    SupplierID ASC,
	SupplierName
);
GO
CREATE NONCLUSTERED INDEX IX_Warehouse_StockItems_ExamBook762Ch4_ColorID
    ON Warehouse.StockItems
(
   
	ColorID ASC,
	SupplierID ASC,
	StockItemName ASC

);
GO


----Create efficient query plans using Query Store

------Listing 4-21 Enable the query store for a database and set its properties
ALTER DATABASE <databasename> 
    SET QUERY_STORE = ON 
    (
      OPERATION_MODE = READ_WRITE, 
	  CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 5 ), 
	  DATA_FLUSH_INTERVAL_SECONDS = 2000, 
	  MAX_STORAGE_SIZE_MB = 10, 
	  INTERVAL_LENGTH_MINUTES = 10 
    );

------Listing 4-22 Purge data from the query store
--Option 1: Use the ALTER DATABASE statement
ALTER DATABASE <databasename> 
SET QUERY_STORE CLEAR ALL;
GO

--Option 2: Use a system stored procedure
EXEC sys.sp_query_store_flush_db;
GO

------Listing 4-23 Top 5 queries with highest average logical reads
USE WideWorldImporters;
GO
SELECT TOP 1
    qt.query_sql_text,
    CAST(query_plan AS XML) AS QueryPlan,
    rs.avg_logical_io_reads
FROM sys.query_store_plan qp
INNER JOIN sys.query_store_query q
  ON qp.query_id = q.query_id
INNER JOIN sys.query_store_query_text qt
    ON q.query_text_id = qt.query_text_id
INNER JOIN sys.query_store_runtime_stats rs
    ON qp.plan_id = rs.plan_id
ORDER BY rs.avg_logical_io_reads DESC;


------Listing 4-24 Create test environment for Query Store
CREATE DATABASE ExamBook762Ch4_QueryStore;
GO
USE ExamBook762Ch4_QueryStore;
GO
CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.SimpleTable(
    Ident INT IDENTITY,
	ID INT,
    Value INT);

WITH IDs
    AS (SELECT 
	        TOP (9999)
            ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS n
        FROM master.sys.All_Columns ac1
        CROSS JOIN master.sys.All_Columns ac2
        )
INSERT  INTO Examples.SimpleTable(ID, Value)
SELECT  
    1,
    n
FROM    IDs;
GO
INSERT Examples.SimpleTable (ID, Value) 
  VALUES (2, 100);
 
ALTER TABLE Examples.SimpleTable
  ADD  CONSTRAINT [PK_SimpleTable_Ident] 
  PRIMARY KEY CLUSTERED (Ident);
 
CREATE NONCLUSTERED INDEX ix_SimpleTable_ID
  ON Examples.SimpleTable(ID);
GO

CREATE PROCEDURE Examples.GetValues 
    @PARAMETER1 INT
AS 
    SELECT
	    ID,
		Value
	FROM Examples.SimpleTable
	WHERE 
	    ID = @PARAMETER1;
GO

ALTER DATABASE ExamBook762Ch4_QueryStore 
SET QUERY_STORE = ON (
    INTERVAL_LENGTH_MINUTES = 1
);

EXEC Examples.GetValues 1;
GO 20

------Listing 4-25 Execute stored procedure with new parameter value 
EXEC Examples.GetValues 2;
GO 

------Listing 4-26 Execute stored procedure after clearing procedure cache
DBCC FREEPROCCACHE();
GO
EXEC Examples.GetValues 2;
GO 


------Listing 4-27 Execute stored procedure with new parameter value and forced query plan
EXEC Examples.GetValues 1;
GO 
 

------Listing 4-28 Check status of forced plans
SELECT 
    p.plan_id, 
	p.query_id, 
	q.object_id	,  
    force_failure_count, 
	last_force_failure_reason_desc  
FROM sys.query_store_plan AS p  
INNER JOIN sys.query_store_query AS q 
    ON p.query_id = q.query_id  
WHERE is_forced_plan = 1;   

----Compare estimated and actual query plans and related metadata
------Listing 4-29 Create test environment for comparing estimated and actual query plans
CREATE DATABASE ExamBook762Ch4_QueryPlans;
GO
USE ExamBook762Ch4_QueryPlans;
GO
CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.OrderLines (
    OrderLineID int NOT NULL,
    OrderID int NOT NULL,
    StockItemID int NOT NULL,
    Description nvarchar(100) NOT NULL,
    PackageTypeID int NOT NULL,
    Quantity int NOT NULL,
    UnitPrice decimal(18, 2) NULL,
    TaxRate decimal(18, 3) NOT NULL,
    PickedQuantity int NOT NULL,
    PickingCompletedWhen datetime2(7) NULL,
    LastEditedBy int NOT NULL,
    LastEditedWhen datetime2(7) NOT NULL);
GO
INSERT INTO Examples.OrderLines
SELECT * 
FROM WideWorldImporters.Sales.OrderLines;
GO
CREATE INDEX ix_OrderLines_StockItemID
ON Examples.OrderLines (StockItemID);
GO

------Listing 4-30 Generate estimated query plan
SET SHOWPLAN_XML ON;
GO
BEGIN TRANSACTION;
    UPDATE Examples.OrderLines 
        SET StockItemID = 300 
        WHERE StockItemID < 100;
    SELECT 
        OrderID,
        Description,
        UnitPrice
    FROM Examples.OrderLines 
    WHERE StockItemID = 300;
ROLLBACK TRANSACTION;
GO
SET SHOWPLAN_XML OFF;
GO

------Listing 4-31 Generate actual query plan
SET STATISTICS XML ON;
GO
BEGIN TRANSACTION;
    UPDATE Examples.OrderLines 
        SET StockItemID = 300 
        WHERE StockItemID < 100;
    SELECT 
        OrderID,
        Description,
        UnitPrice
    FROM Examples.OrderLines 
    WHERE StockItemID = 300;
ROLLBACK TRANSACTION;
GO
SET STATISTICS XML OFF;
GO

----Configure Azure SQL Database Performance Insight
------Listing 4-32 Execute SQL Database query multiple times after enabling Query Store
SELECT
    c.LastName,
    c.FirstName,
    c.CompanyName,
    year(OrderDate) AS OrderYear,
    sum(OrderQty) AS OrderQty,
    p.Name AS ProductName,
    sum(LineTotal) AS SalesTotal
FROM SalesLT.SalesOrderHeader soh
JOIN SalesLT.SalesOrderDetail sod ON 
    soh.SalesOrderID = sod.SalesOrderID
JOIN SalesLT.Customer c ON 
    soh.CustomerID = c.CustomerID
JOIN SalesLT.Product p ON
    sod.ProductID = p.ProductID
GROUP BY
    c.LastName,
    c.FirstName,
    c.CompanyName,
    year(OrderDate),
    p.Name
ORDER BY 
    c.CompanyName, 
    c.LastName, 
    c.FirstName,
    p.Name;
GO 20


--Skill 4.3: Manage the performance for database instances

----Manage database workload in SQL Server

------Enable Resource Governor
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

------Listing 4-33 Create user-defined resource pools
CREATE RESOURCE POOL poolExamBookDaytime
WITH (  
    MIN_CPU_PERCENT = 50,  
    MAX_CPU_PERCENT = 80,  
    CAP_CPU_PERCENT = 90,  
    AFFINITY SCHEDULER = (0 TO 3),  
    MIN_MEMORY_PERCENT = 50,  
    MAX_MEMORY_PERCENT = 100,
    MIN_IOPS_PER_VOLUME = 20,
    MAX_IOPS_PER_VOLUME = 100
);
GO
CREATE RESOURCE POOL poolExamBookNighttime
WITH (  
    MIN_CPU_PERCENT = 	0,  
    MAX_CPU_PERCENT = 50,  
    CAP_CPU_PERCENT = 50,  
    AFFINITY SCHEDULER = (0 TO 3),  
    MIN_MEMORY_PERCENT = 5,  
    MAX_MEMORY_PERCENT = 15,
    MIN_IOPS_PER_VOLUME = 45,
    MAX_IOPS_PER_VOLUME = 100
);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

------Listing 4-34 Create workload groups
CREATE WORKLOAD GROUP apps 
WITH (
    IMPORTANCE = HIGH,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 35,
    REQUEST_MAX_CPU_TIME_SEC = 0, --0 = unlimited 
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 60, --seconds
    MAX_DOP = 0, -- uses global setting
    GROUP_MAX_REQUESTS = 1000 --0 = unlimited
)
USING "poolExamBookDaytime";
GO
CREATE WORKLOAD GROUP reports 
WITH (
    IMPORTANCE = LOW,
    REQUEST_MAX_MEMORY_GRANT_PERCENT = 25,
    REQUEST_MAX_CPU_TIME_SEC = 0, --0 = unlimited 
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 60, --seconds
    MAX_DOP = 0, -- uses global setting
    GROUP_MAX_REQUESTS = 100 --0 = unlimited
)
USING "poolExamBookNighttime";
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

------Listing 4-35 Create lookup table
USE master  
GO  
CREATE TABLE tblClassificationTime  (  
    TimeOfDay SYSNAME NOT NULL,  
    TimeStart TIME NOT NULL,  
    TimeEnd   TIME NOT NULL  
);
GO    
INSERT INTO tblClassificationTime 
VALUES('apps', '8:00 AM', '6:00 PM');
GO  
INSERT INTO tblClassificationTime 
VALUES('reports', '6:00 PM', '8:00 AM');
GO

------Listing 4-36 Create and register classifier function
USE master;
GO
CREATE FUNCTION fnTimeOfDayClassifier()  
RETURNS sysname  
WITH SCHEMABINDING  AS  
BEGIN  
    DECLARE @TimeOfDay sysname  
    DECLARE @loginTime time  
    SET @loginTime = CONVERT(time,GETDATE())  
    SELECT 
        TOP 1 @TimeOfDay = TimeOfDay
    FROM dbo.tblClassificationTime
    WHERE TimeStart <= @loginTime and TimeEnd >= @loginTime  
    IF(@TimeOfDay IS NOT NULL) 
        BEGIN
            RETURN @TimeOfDay
        END 
    RETURN N'default'
END;
GO
ALTER RESOURCE GOVERNOR with (CLASSIFIER_FUNCTION = dbo.fnTimeOfDayClassifier);
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO  


------Listing 4-37 Monitor resource consumption
--Current runtime data
SELECT * FROM sys.dm_resource_governor_resource_pools;
GO
SELECT * FROM sys.dm_resource_governor_workload_groups;
GO  

--Determine the workload group for each session
SELECT
    s.group_id, 
    CAST(g.name as nvarchar(20)) AS WkGrp, 
    s.session_id, 
    s.login_time, 
    CAST(s.host_name as nvarchar(20)) AS Host, 
    CAST(s.program_name AS nvarchar(20)) AS Program
FROM sys.dm_exec_sessions s  
INNER JOIN sys.dm_resource_governor_workload_groups g  
    ON g.group_id = s.group_id  
ORDER BY g.name;
GO
SELECT 
    r.group_id, 
    g.name, 
    r.status,
    r.session_id, 
    r.request_id,
    r.start_time, 
    r.command, 
    r.sql_handle,
    t.text   
FROM sys.dm_exec_requests r 
INNER JOIN sys.dm_resource_governor_workload_groups g  
    ON g.group_id = r.group_id  
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t  
    ORDER BY g.name  
GO
-- Determine the classifier running the request
SELECT 
    s.group_id, 
    g.name, 
    s.session_id, 
    s.login_time, 
    s.host_name, 
    s.program_name,
	s.status
FROM sys.dm_exec_sessions s  
INNER JOIN sys.dm_resource_governor_workload_groups g  
    ON g.group_id = s.group_id  
	--AND 
 --       s.status = 'preconnect'  
ORDER BY g.name;
GO
SELECT 
    r.group_id,
    g.name,
    r.status, 
    r.session_id, 
    r.request_id, 
    r.start_time, 
    r.command, 
    r.sql_handle, 
    t.text
FROM sys.dm_exec_requests r  
INNER JOIN sys.dm_resource_governor_workload_groups g  
    ON g.group_id = r.group_id  
        AND r.status = 'preconnect'   
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t  
ORDER BY g.name;
GO

----Optimize database file and tempdb configuration
------Listing 4-38 Relocate data and log files
ALTER DATABASE <databasename>
SET OFFLINE;
GO
ALTER DATABASE <databasename>
MODIFY FILE (NAME = <databasename>_Data, FILENAME = "<drive:\filepath>\Data\<databasename>_Data.mdf");
GO
ALTER DATABASE <databasename>
MODIFY FILE (NAME = <databasename>_Log, FILENAME = "<drive:filepath>\Log\<databasename>_Log.mdf");
ALTER DATABASE <databasename>
SET ONLINE;


------Listing 4-39 Create and alter database with multiple file groups
--Create a database on 4 drives
CREATE DATABASE DB1 ON 
PRIMARY 
    (Name = <databasename>, FILENAME = '<drive1:filepath>\<databasename>.mdf'),
FILEGROUP FGHeavyAccess1
    (Name = <databasename>_1, FILENAME = '<drive3:filepath>\<databasename>_1.ndf')
LOG ON 
    (Name = <databasename>_1_Log, FILENAME = '<drive3:filepath>\<databasename>_1_log.ldf'),
    (Name = <databasename>_1, FILENAME = '<drive4:filepath>\<databasename>_1_log_2.ldf');

-- Add filegroup for index
ALTER DATABASE <databasename> 
    ADD FILEGROUP FGIndex;
	
--  Add data file to the new filegroup
ALTER DATABASE <databasename> 
ADD FILE (
    NAME = <databasename>, 
    FILENAME = '<drive1:filepath>\<databasename>.ndf', 
	SIZE=1024MB, 
	MAXSIZE=10GB, 
	FILEGROWTH=10%)
TO FILEGROUP FGIndex;

-- Add index to filegroup
CREATE NONCLUSTERED INDEX ix_Example
    ON Examples.BusyTable(TableColumn)
    ON FGIndex;

------Listing 4-40 Create a partition scheme to map partition function to filegroups
CREATE PARTITION SCHEME PSYear  
    AS PARTITION PFYearRange
    TO (FGYear1, FGYear2, FGYear3, FGYear4);  

------ Configure memory
EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
EXEC sp_configure 'min memory per query', 512 ;  
GO  
RECONFIGURE;  
GO  

----Troubleshoot and analyze storage, IO, and cache issues
------Listing 4-41 Review SQL Server:Buffer Manager performance counters
SELECT  
    object_name, 
    counter_name, 
    instance_name, 
    cntr_value, 
    cntr_type
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND
    counter_name IN
        ('Page lookups/sec', 'Page reads/sec', 'Page writes/sec')

-- Skill 4.4: Monitor and trace SQL Server baseline metrics
----Monitor Azure SQL Database performance
------Listing 4-42 Find deadlocks and throttle events in SQL Database
SELECT 
    Event_Category, 
	Event_Type, 
	Event_Subtype_Desc, 
	Event_Count, 
	Description, 
	Start_Time
FROM sys.event_log
WHERE Event_Type = 'deadlock' OR
    Event_Type like 'throttling%'
ORDER By Start_Time DESC;


----Define differences between Extended Events Packages, Targets, Actions, and Sessions
------Listing 4-43 Create event session
CREATE EVENT SESSION [stored_proc]
ON SERVER
ADD EVENT sqlserver.sp_statement_completed(
    ACTION (sqlserver.session_id,
        sqlserver.sql_text))
ADD TARGET package0.event_file(SET filename=N'C:\ExamBook762Ch4\query.xel',
    max_file_size=(5),max_rollover_files=(4)),
ADD TARGET package0.ring_buffer;





