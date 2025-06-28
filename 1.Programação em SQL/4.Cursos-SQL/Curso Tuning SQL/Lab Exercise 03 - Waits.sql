---------------------------------------------------------------------
-- LAB 01
--
-- Exercise 3
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Task 1 - Write a query to clear the wait statistics
-- Hint: review the lesson "Viewing Wait Statistics" in this module for assistance with this task.
---------------------------------------------------------------------

SELECT * FROM sys.dm_os_wait_stats AS DOWS
WHERE DOWS.wait_time_ms > 0
ORDER BY DOWS.wait_time_ms DESC

DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
---------------------------------------------------------------------
-- Task 2 - Write a query to view the wait statistics. 
-- Note that most of the column values are zero
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Task 3 - Start a Workload
-- NB: BEFORE continuing with the tasks in this exercise, make sure you have started the sample workload
-- by right-clicking D:\Labfiles\Lab01\Starter\start_load_exercise_03.ps1 and clicking "Run with PowerShell"
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Task 4 - Write a query to view the waiter list. 
-- Hint: to filter the output, exclude sessions with a session_id <= 50, since these are likely to be system sessions
-- Note the wait type(s) the tasks are waiting for.
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Task 5 
-- Execute the following query to capture a snapshot of wait statistics into a 
-- temporary table called #wait_stats_snapshot. 
---------------------------------------------------------------------
DROP TABLE IF EXISTS #wait_stats_snapshot


SELECT *
INTO #wait_stats_snapshot
FROM sys.dm_os_wait_stats;

-- The following query compares the snapshot captured in #wait_stats_snapshot 
-- with the current wait statistics. 
-- Amend the query to order the results by the change to wait_time_ms 
-- between the snapshot and the current wait statistics, descending.
-- Amend the query to exclude wait types where there is no change.
SELECT snap.*,
       '==>',
       [Dirf] =  ws.wait_time_ms -snap.wait_time_ms 
FROM #wait_stats_snapshot AS snap
     JOIN
     sys.dm_os_wait_stats AS ws ON ws.wait_type = snap.wait_type
	 WHERE snap.wait_time_ms < ws.wait_time_ms


---------------------------------------------------------------------
-- Task 6 - stop the workload
---------------------------------------------------------------------
CREATE TABLE ##stopload2 (id int)


SELECT ws.*

FROM #wait_stats_snapshot AS snap

JOIN sys.dm_os_wait_stats AS ws

ON ws.wait_type = snap.wait_type

WHERE ws.wait_time_ms - snap.wait_time_ms > 0

ORDER BY ws.wait_time_ms - snap.wait_time_ms DESC;