-- Module 1 - Demo 2 - File 3

-- Step 1 - From the solution, open and execute the query Demo2i - Create hanging transaction.sql against MIA-SQL
-- note the value of update_session_id in the results pane

-- Step 2 - From the solution, open and execute the query Demo2ii - Start blocked transaction.sql against MIA-SQL
-- note the value of select_session_id in the results pane

-- Step 3 - Add the values of update_session_id and select_session_id collected in the last two steps
-- to a temporary table.
-- substitute the values in the VALUES clause below (you can use template parameters - Ctrl + Shift + M)
DROP TABLE IF EXISTS #session;
CREATE TABLE #session (session_id int NOT NULL);

INSERT #session 
VALUES
(56),(54)




-- Step 4 - View session status 
-- Note that:
--   the update session has the status sleeping
--   the select session has the status running
SELECT status,dm_exec_sessions.open_transaction_count, * 
FROM sys.dm_exec_sessions 
WHERE session_id IN (SELECT session_id FROM #session)
ORDER BY dm_exec_sessions.last_request_start_time

-- Step 5 - View request status
-- Note that:
--   the update session has no request, because it is not currently working
--   the select session request has a suspended status, because it is waiting for a resource to become free

/*TSQL : A Sessão ? fez um pedido de um recurso (ler as paginas  da tabela Customers , porem ela esta bloqueadas*/




/* ==================================================================
Esse tipo de espera é quando um encadeamento está aguardando para adquirir um bloqueio
 Compartilhado em um recurso e há pelo menos um outro bloqueio em um modo
 incompatível concedido no recurso para um encadeamento diferente.
 
-- ==================================================================
*/ 
SELECT req.database_id,
       req.status,
	   req.session_id,
	   req.command,
       req.start_time,
       req.wait_type,
       req.wait_time,--409179
       [Sessão que está bloqueando] = req.blocking_session_id,
       req.sql_handle,
       req.plan_handle,
       req.wait_resource,
       req.open_transaction_count,
       req.open_resultset_count,
       req.transaction_id,
       req.cpu_time,
       req.total_elapsed_time,
       req.scheduler_id,
       req.task_address,
       req.reads,
       req.writes,
       req.logical_reads,
       req.text_size,
       req.language,
       req.date_first,
       req.transaction_isolation_level,
       req.lock_timeout,
       req.deadlock_priority,
       req.row_count,
       req.prev_error,
       req.nest_level,
       req.granted_query_memory,
       req.executing_managed_code,
       req.group_id,
       req.query_hash,
       req.query_plan_hash,
       req.statement_sql_handle,
       req.statement_context_id
FROM sys.dm_exec_requests req
--WHERE  req.user_id =1
WHERE req.session_id IN (
                        SELECT #session.session_id
                        FROM #session
                        );

/*saiba mais sobre Locks
https://www.sqlskills.com/help/waits/lck_m_s/
*/


-- Step 6 - View task status
/*TSQL : - a sessão de atualização não tem tarefa, porque não está funcionando atualmente
- a tarefa de seleção de sessão possui um status suspenso, porque está aguardando que um recurso fique livre*/
SELECT ta.task_address,ta.task_state,ta.session_id,ta.scheduler_id,ta.worker_address
FROM sys.dm_os_tasks ta
WHERE session_id IN (SELECT session_id FROM #session);

-- Step 7 - View worker status
--   the update session has no worker, because it is not currently working
--   the select session worker has a suspended status, because it is waiting for a resource to become free
SELECT dot.session_id, dow.state, dow.*
FROM sys.dm_os_workers AS dow
JOIN sys.dm_os_tasks AS dot
ON   dot.task_address = dow.task_address
WHERE dot.session_id IN (SELECT session_id FROM #session);

-- Step 8 - view tempo gasto waiting/runnable
SELECT	dot.session_id, 
		dow.state,
		CASE WHEN dow.state = 'SUSPENDED' 
			 THEN (SELECT ms_ticks FROM sys.dm_os_sys_info) - dow.wait_started_ms_ticks
			 ELSE NULL
		END AS time_spent_waiting_ms,
		CASE WHEN dow.state = 'RUNNABLE' 
			 THEN (SELECT ms_ticks FROM sys.dm_os_sys_info) - dow.wait_resumed_ms_ticks
			 ELSE NULL
		END AS time_spent_runnable_ms
FROM sys.dm_os_workers AS dow
JOIN sys.dm_os_tasks AS dot
ON   dot.task_address = dow.task_address
WHERE dot.session_id IN (SELECT session_id FROM #session);

-- Step 9 - view thread status
--   the update session has no thread, because it is not currently working
--   the select session thread has a suspended status, because it is waiting for a resource to become free
SELECT dot.session_id,  dth.*
FROM sys.dm_os_threads dth
JOIN sys.dm_os_workers AS dow
ON	 dow.worker_address = dth.worker_address
JOIN sys.dm_os_tasks AS dot
ON   dot.task_address = dow.task_address
WHERE dot.session_id IN (SELECT session_id FROM #session);

-- Step 10 - return to the query window where Demo2i - Create hanging transaction.sql is running.
-- Uncomment and execute the ROLLBACK command at the end of the file

-- Step 11 - return to the query window where Demo2ii - Start blocked transaction.sql is running.
-- notice that the query is no longer blocked and results have been returned.
