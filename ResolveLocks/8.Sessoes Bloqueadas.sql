SELECT owt.session_id AS waiting_session_id,
       owt.blocking_session_id,
       DB_NAME(tls.resource_database_id) AS database_name,
       (
           SELECT SUBSTRING(est.text, ers.statement_start_offset / 2 + 1, (CASE WHEN ers.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), est.text)) * 2 ELSE ers.statement_end_offset END - ers.statement_start_offset) / 2)
             FROM sys.dm_exec_sql_text(ers.[sql_handle]) AS est
       ) AS waiting_query_text,
       CASE WHEN owt.blocking_session_id > 0 THEN (
                                                      SELECT est.text
                                                        FROM sys.sysprocesses AS sp
                                                             CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) AS est
                                                       WHERE
                                                          sp.spid = owt.blocking_session_id
                                                  )ELSE NULL END AS blocking_query_text,
       (CASE tls.resource_type WHEN 'OBJECT' THEN OBJECT_NAME(tls.resource_associated_entity_id, tls.resource_database_id)
        WHEN 'DATABASE' THEN DB_NAME(tls.resource_database_id)ELSE (
                                                                       SELECT OBJECT_NAME(pat.object_id, tls.resource_database_id)
                                                                         FROM sys.partitions pat
                                                                        WHERE
                                                                           pat.hobt_id = tls.resource_associated_entity_id
                                                                   )END
       ) AS object_name,
       owt.wait_duration_ms,
       owt.waiting_task_address,
       owt.wait_type,
       tls.resource_associated_entity_id,
       tls.resource_description AS local_resource_description,
       tls.resource_type,
       tls.request_mode,
       tls.request_type,
       tls.request_session_id,
       owt.resource_description AS blocking_resource_description,
       qp.query_plan AS waiting_query_plan
  FROM sys.dm_tran_locks AS tls
       INNER JOIN sys.dm_os_waiting_tasks owt ON tls.lock_owner_address = owt.resource_address
       INNER JOIN sys.dm_exec_requests ers ON tls.request_request_id = ers.request_id
                                              AND owt.session_id = ers.session_id
       OUTER APPLY sys.dm_exec_query_plan(ers.plan_handle) AS qp
 WHERE
    tls.resource_description NOT LIKE '%HangFireSiscaf%';

 --owt.blocking_session_id =  1594  