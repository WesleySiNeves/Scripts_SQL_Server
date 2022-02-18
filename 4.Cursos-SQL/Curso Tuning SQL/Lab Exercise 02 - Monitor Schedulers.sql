---------------------------------------------------------------------
-- LAB 01
--
-- Exercise 2
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Task 1 - Start a Workload
-- NB: BEFORE starting on the tasks in this exercise, make sure you have started the sample workload
-- by right-clicking D:\Labfiles\Lab01\Starter\start_load_exercise_02.ps1 and clicking "Run with PowerShell"
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Task 2 - Write a query to return details of the visible online schedulers. Execute it several times.
-- How do the column values change as the workload runs? 
-- Can you make any deductions about the level of CPU pressure?
---------------------------------------------------------------------
SELECT DOS.scheduler_id,
       DOS.cpu_id,
       DOS.is_online,
       DOS.current_tasks_count,
       DOS.runnable_tasks_count,
	   DOS.current_workers_count,
	   DOS.active_workers_count,
	   DOS.ideal_workers_limit
FROM sys.dm_os_schedulers AS DOS
WHERE DOS.status = 'VISIBLE ONLINE';
---------------------------------------------------------------------
-- Task 3 - Write a query to return details of the state of active user requests.
-- Hint: to filter the output, exclude sessions with a session_id <= 50, since these are likely to be system sessions
-- Which wait type are the user requests waiting for? 
-- What does the wait type indicate?
---------------------------------------------------------------------
SELECT DER.database_id,
       DER.session_id,
       -- DER.request_id,
       DER.status,
       DER.command,
       DER.sql_handle,
       DEST.text,
       DER.statement_start_offset,
       DER.statement_end_offset,
       DER.plan_handle,
       DER.blocking_session_id,
       DER.wait_time,
       DER.last_wait_type,
       --DER.wait_resource,
       DER.open_transaction_count,
       DER.cpu_time,
       DER.total_elapsed_time,
       DER.scheduler_id,
       --DER.task_address,
       DER.reads,
       DER.writes,
       DER.logical_reads,
       DER.text_size,
       DER.transaction_isolation_level,
       DER.lock_timeout,
       DER.row_count,
       DER.granted_query_memory,
       DER.query_hash,
       DER.query_plan_hash,
       DER.statement_sql_handle,
       DER.parallel_worker_count,
       DER.page_resource
FROM sys.dm_exec_requests AS DER
     OUTER APPLY (
                 SELECT *
                 FROM sys.dm_exec_sql_text(DER.sql_handle)
                 ) AS DEST
WHERE DER.database_id > 5
ORDER BY
    DER.database_id;

---------------------------------------------------------------------
-- Task 4 - Run the following query to stop the workload
---------------------------------------------------------------------
IF OBJECT_ID('tempdb..##stopload1') IS NULL
	CREATE TABLE ##stopload1 (id int)

