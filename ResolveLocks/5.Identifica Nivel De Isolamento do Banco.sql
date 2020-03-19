SELECT DES.session_id,
       DATEADD(HOUR,-3,DES.last_request_start_time) last_request_start_time,
       CASE DES.transaction_isolation_level WHEN 0 THEN 'Unspecified'
       WHEN 1 THEN 'ReadUncommitted'
       WHEN 2 THEN 'ReadCommitted'
       WHEN 3 THEN 'Repeatable'
       WHEN 4 THEN 'Serializable'
       WHEN 5 THEN 'Snapshot' END AS TRANSACTION_ISOLATION_LEVEL,
       DEST.text,
       DES.host_name,
       DES.program_name,
       DES.login_name,
       DES.cpu_time,
       DES.memory_usage,
       DES.reads,
       DES.writes,
       DES.logical_reads,
       DES.open_transaction_count
  FROM sys.dm_exec_sessions AS DES
       JOIN sys.dm_exec_connections AS DEC ON DES.session_id = DEC.session_id
       CROSS APPLY(SELECT * FROM sys.dm_exec_sql_text(DEC.most_recent_sql_handle) ) AS DEST
 WHERE
    DES.program_name NOT IN ('Microsoft SQL Server Management Studio - Transact-SQL IntelliSense')
    AND DES.host_name = 'DS10'
	AND DES.program_name ='rgdev-sqlsrv-dev01.database.windows.net'
 ORDER BY
    DEC.most_recent_sql_handle;
