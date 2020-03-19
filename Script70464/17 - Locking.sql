-- Demonstration 17 - Locking and Deadlocks

USE [TSQL]
GO

-- Talk about read committed versus repeatable read
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
GO
BEGIN TRANSACTION
SELECT * FROM HR.Employees
WHERE lastname = 'Buck'


SELECT request_session_id AS Session,
resource_database_id AS DBID,
Resource_Type,
resource_description AS Resource,
request_type AS Type,
request_mode AS Mode,
request_status AS Status
FROM sys.dm_tran_locks
ORDER BY [session]

-- talk about the locking modes and key lock

-- start a different window

UPDATE HR.Employees 
SET titleofcourtesy = 'Dr.'
WHERE lastname = 'Buck'

-- The new session has an update lock on the same page as the previous session. Update locks are compatible are used to read data before changing it. 

-- Refreshing the tran_locks view doesn't change anything so look to see whats blocking

SELECT session_id,wait_duration_ms,wait_type,
blocking_session_id,resource_description
FROM sys.dm_os_waiting_tasks
WHERE session_id > 50

ROLLBACK TRANSACTION

-- Create a deadlock

DBCC TRACEON (1222,-1)
GO

--Run Profiler and setup deadlock graph

-- Session 1
BEGIN TRANSACTION
	UPDATE HR.Employees 
	SET titleofcourtesy = 'Dr.'
	WHERE lastname = 'Buck'

-- Session 1
	UPDATE HR.Employees  
	SET titleofcourtesy = 'Dr.'
	WHERE lastname = 'King'

-- Session 2
BEGIN TRANSACTION
	UPDATE HR.Employees  
	SET titleofcourtesy = 'Dr.'
	WHERE lastname = 'King'

-- Session 2
	UPDATE HR.Employees  
	SET titleofcourtesy = 'Dr.'
	WHERE lastname = 'Buck'

