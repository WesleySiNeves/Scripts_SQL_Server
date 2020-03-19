---------------------------------------------------------------------
-- TK 70-461 - Chapter 04 - Using Tools to Analyze Query Performance
-- Code
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Getting Started with Query Optimization
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Pseudo-code in this lesson
---------------------------------------------------------------------
/*
SELECT A.col5, SUM(C.col6) AS col6sum
FROM TableA AS A
 INNER JOIN TableB AS B
   ON A.col1 = B.col1
 INNER JOIN TableC AS C
   ON B.col2 = c.col2
WHERE A.col3 = constant1
  AND B.col4 = constant2
GROUP BY A.col5;

SELECT col1 FROM TableA WHERE col2 = 3;

SELECT col1 FROM TableA WHERE col2 = 5;

SELECT col1 FROM TableA WHERE col2 = ?;
*/


---------------------------------------------------------------------
-- Lesson 02 - Using SET Session Options and Analyzing Query Plans
---------------------------------------------------------------------

---------------------------------------------------------------------
-- SET Session Options
---------------------------------------------------------------------

USE TSQL2012;
SET NOCOUNT ON;
GO

-- Get number of pages for Customers and Orders
DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SELECT * FROM Sales.Customers;
SELECT * FROM Sales.Orders;
GO

-- Example of overestimated logical reads
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
   ON C.custid = O.custid;
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
   ON C.custid = O.custid
WHERE O.custid < 5;
GO

-- Turn off statistics IO
SET STATISTICS IO OFF;
GO

-- Use statistics time for the same two queries
-- Also drop clean buffers
DBCC DROPCLEANBUFFERS;
SET STATISTICS TIME ON;
GO
-- Execute a query
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid;
-- Drop clean buffers
DBCC DROPCLEANBUFFERS;
GO
-- Execute a query
SELECT C.custid, C.companyname, 
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid
WHERE O.custid < 5;
-- Set statistics time off
SET STATISTICS TIME OFF;
GO


---------------------------------------------------------------------
-- Execution plans
---------------------------------------------------------------------

-- Turn Actual Execution Plan on
SELECT C.custid, MIN(C.companyname) AS companyname, 
 COUNT(*) AS numorders
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid
WHERE O.custid < 5
GROUP BY C.custid
HAVING COUNT(*) > 6;
GO


---------------------------------------------------------------------
-- Lesson 03 - Using Dynamic Management Objects
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Most Important DMOs for Query Tuning
---------------------------------------------------------------------

-- Base info - sys.dm_os_sys_info
SELECT cpu_count AS logical_cpu_count,
 cpu_count / hyperthread_ratio AS physical_cpu_count,
 CAST(physical_memory_kb / 1024. AS int) AS physical_memory__mb, 
 sqlserver_start_time
FROM sys.dm_os_sys_info;

-- Waiting sessions - sys.dm_os_waiting_tasks, sys.dm_exec_sessions
SELECT S.login_name, S.host_name, S.program_name,
 WT.session_id, WT.wait_duration_ms, WT.wait_type, 
 WT.blocking_session_id, WT.resource_description
FROM sys.dm_os_waiting_tasks AS WT
 INNER JOIN sys.dm_exec_sessions AS S
  ON WT.session_id = S.session_id
WHERE s.is_user_process = 1;

-- Currently executing batches, with text and wait info
SELECT S.login_name, S.host_name, S.program_name,
 R.command, T.text,
 R.wait_type, R.wait_time, R.blocking_session_id
FROM sys.dm_exec_requests AS R
 INNER JOIN sys.dm_exec_sessions AS S
  ON R.session_id = S.session_id		
 OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
WHERE S.is_user_process = 1;

-- Top five queries by total logical IO
SELECT TOP (5)
 (total_logical_reads + total_logical_writes) AS total_logical_IO,
 execution_count, 
 (total_logical_reads/execution_count) AS avg_logical_reads,
 (total_logical_writes/execution_count) AS avg_logical_writes,
 (SELECT SUBSTRING(text, statement_start_offset/2 + 1,
    (CASE WHEN statement_end_offset = -1
          THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
          ELSE statement_end_offset
     END - statement_start_offset)/2)
   FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
FROM sys.dm_exec_query_stats
ORDER BY (total_logical_reads + total_logical_writes) DESC;
GO
