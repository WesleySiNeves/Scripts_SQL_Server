-- Demonstration 22 - Waits

USE people
GO

EXEC usp_looppeopleinsert 10000
GO

SELECT * FROM sys.dm_exec_requests
GO

SELECT * from sys.dm_os_waiting_tasks
GO

SELECT * from sys.dm_os_wait_stats
GO