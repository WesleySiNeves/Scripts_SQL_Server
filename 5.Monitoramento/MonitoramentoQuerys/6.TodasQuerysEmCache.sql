

SELECT
       -- using statement_start_offset and
       -- statement_end_offset we get the query text
       -- from inside the entire batch
        SUBSTRING(qt.text, ( qs.statement_start_offset / 2 ) + 1,
                  ( ( CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(qt.text)
                        ELSE qs.statement_end_offset
                      END - qs.statement_start_offset ) / 2 ) + 1) AS [Text] ,
        qs.execution_count ,
        qs.total_logical_reads ,
        qs.last_logical_reads ,
        qs.total_logical_writes ,
        qs.last_logical_writes ,
        qs.total_worker_time ,
        qs.last_worker_time ,
-- converting microseconds to seconds
        qs.total_elapsed_time / 1000000 total_elapsed_time_in_S ,
        qs.last_elapsed_time / 1000000 last_elapsed_time_in_S ,
        qs.last_execution_time ,
        qp.query_plan
FROM    sys.dm_exec_query_stats qs -- Retrieve the query text
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
       -- Retrieve the query plan
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_worker_time DESC; -- CPU time