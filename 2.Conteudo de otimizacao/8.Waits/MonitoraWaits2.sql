/*master : LCK_M_S  : Ocorre quando uma tarefa quer adiquirir um bloqueio compartilhado (select) entretando o resurso já te, 
um bloqueio exclusivo */
SELECT wait.session_id AS [sessão bloqueada],
	   CONVERT(TIME,DATEADD (ms, wait.wait_duration_ms, 0)) AS Segundos,
       wait.wait_type,
       wait.resource_address,
       wait.blocking_session_id AS [Sessao Bloqueando],
       wait.resource_description
FROM sys.dm_os_waiting_tasks wait
WHERE wait.session_id > 50 ;