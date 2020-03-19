/*
https://blog.sqlauthority.com/2017/01/29/find-queries-implict-conversion-sql-server-interview-question-week-107/
*/


-- (c) https://blog.sqlauthority.com
SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name], 
t.text AS [Query Text],
qs.total_worker_time AS [Total Worker Time], 
qs.total_worker_time/qs.execution_count AS [Avg Worker Time], 
qs.max_worker_time AS [Max Worker Time], 
qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time], 
qs.max_elapsed_time AS [Max Elapsed Time],
qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],
qs.max_logical_reads AS [Max Logical Reads], 
qs.execution_count AS [Execution Count], 
qs.creation_time AS [Creation Time],
qp.query_plan AS [Query Plan]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
WHERE CAST(query_plan AS NVARCHAR(MAX)) LIKE ('%Lookup%')
 AND t.[dbid] = DB_ID()
 AND t.text NOT LIKE '%sys.%'
  AND t.text NOT LIKE '%HangFire%'
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);
