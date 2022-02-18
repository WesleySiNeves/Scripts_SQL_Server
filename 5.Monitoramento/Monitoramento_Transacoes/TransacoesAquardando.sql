SELECT CAST(SERVERPROPERTY('ServerName') AS sysname) AS ServerName,
       s.session_id,
       s.status,
       s.login_time,
       s.host_name,
       s.program_name,
       s.host_process_id,
       s.original_login_name,
       s.last_request_end_time,
       CAST(t.text AS NVARCHAR(4000)) AS [text],
       CAST(s.context_info AS VARCHAR(128)) AS [context_info]
FROM sys.dm_exec_sessions AS s
     INNER JOIN
     sys.dm_exec_connections AS c ON s.session_id = c.session_id
     CROSS APPLY (
                 SELECT MAX(DB_NAME(dt.database_id)) AS database_name
                 FROM sys.dm_tran_session_transactions AS st
                      INNER JOIN
                      sys.dm_tran_database_transactions AS dt ON st.transaction_id = dt.transaction_id
                 WHERE st.is_user_transaction = 1
                 GROUP BY
                     st.session_id
                 HAVING s.session_id = st.session_id
                 ) AS trans
     CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS t
WHERE s.session_id NOT IN (
                          SELECT dm_exec_requests.session_id
                          FROM sys.dm_exec_requests
                          )
      AND s.session_id IN (
                          SELECT dm_tran_locks.request_session_id
                          FROM sys.dm_tran_locks
                          WHERE dm_tran_locks.request_status = 'GRANT'
                          )
      AND s.status = 'sleeping'
      AND s.is_user_process = 1
      AND s.program_name NOT LIKE '%SQLAgent - Job Manager%'
OPTION (RECOMPILE, FORCE ORDER);