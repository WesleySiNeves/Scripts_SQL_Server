SELECT DB_NAME(dm_bloqueado.database_id) DatabaseName,
       dm_ws.wait_type,
       dm_es.status,
       dm_ws.wait_duration_ms,
       [TempoEspera] = TIMEFROMPARTS((dm_ws.wait_duration_ms / (1000 * 60 * 60)), (dm_ws.wait_duration_ms % (1000 * 60 * 60)) / (1000 * 60), (((dm_ws.wait_duration_ms % (1000 * 60 * 60)) % (1000 * 60)) / 1000), 0, 0),
       dm_ws.session_id [Sessão Bloqueada (KILL)],
       dm_bloqueado.command,
       dm_t.text [Query Bloqueada (KILL)],
       dm_qp.query_plan,
       dm_es.cpu_time,
       dm_es.memory_usage,
       dm_es.logical_reads,
       '==>' AS [Informacao Origem],
       -- Optional columns
       dm_es.login_name,
       dm_ws.blocking_session_id [Sessão Iniciada primeiro],
       dm_bloqueando.text,
       dm_bloqueado.wait_resource
  FROM sys.dm_os_waiting_tasks dm_ws
       INNER JOIN sys.dm_exec_requests dm_bloqueado ON dm_ws.session_id = dm_bloqueado.session_id
       INNER JOIN sys.dm_exec_sessions dm_es ON dm_es.session_id = dm_bloqueado.session_id
       INNER JOIN sys.dm_exec_requests dm_bloquando ON dm_ws.blocking_session_id = dm_bloquando.session_id
       CROSS APPLY sys.dm_exec_sql_text(dm_bloqueado.sql_handle) dm_t
       CROSS APPLY sys.dm_exec_sql_text(dm_bloquando.sql_handle) dm_bloqueando
       CROSS APPLY sys.dm_exec_query_plan(dm_bloqueado.plan_handle) dm_qp
 WHERE
    dm_es.is_user_process = 1
    AND dm_ws.blocking_session_id > 0
    AND dm_bloqueado.last_wait_type LIKE '%LCK%';
