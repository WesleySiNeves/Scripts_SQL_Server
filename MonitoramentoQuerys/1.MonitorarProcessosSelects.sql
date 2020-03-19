

SELECT  requests.session_id, 
        requests.status, 
        requests.command, 
        requests.statement_start_offset,
        requests.statement_end_offset,
        requests.total_elapsed_time,
        details.text
FROM    sys.dm_exec_requests requests
CROSS APPLY sys.dm_exec_sql_text (requests.plan_handle) details
WHERE   requests.session_id  <> @@SPID
ORDER BY total_elapsed_time DESC

