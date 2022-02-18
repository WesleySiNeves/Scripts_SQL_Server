SELECT DMExQryStats.last_execution_time AS [Executed At],
       DMExSQLTxt.text AS [Query]
FROM sys.dm_exec_query_stats AS DMExQryStats
     CROSS APPLY sys.dm_exec_sql_text(DMExQryStats.sql_handle) AS DMExSQLTxt
ORDER BY
    DMExQryStats.last_execution_time DESC;