WITH QuerysMaisExecutadas
  AS (
     SELECT TOP 1000
         qs.execution_count,
         qs.total_worker_time,
         qs.total_worker_time / qs.execution_count AS 'Avg CPU Time',
         qs.total_physical_reads,
         qs.total_physical_reads / qs.execution_count AS 'Avg Physical Reads',
         qs.total_logical_reads,
         qs.total_logical_reads / qs.execution_count AS 'Avg Logical Reads',
         qs.total_logical_writes,
         qs.total_logical_writes / qs.execution_count AS 'Avg Logical Writes',
         SUBSTRING(   st.text,
                      qs.statement_start_offset / 2 + 1,
                      (CASE qs.statement_end_offset
                           WHEN-1 THEN
                               DATALENGTH(st.text)
                           ELSE
                               qs.statement_end_offset
                       END - qs.statement_start_offset
                      ) / 2 + 1
                  ) AS statement_text
     FROM sys.dm_exec_query_stats AS qs
          CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
     )
SELECT Q.execution_count,
       Q.total_worker_time,
       Q.[Avg CPU Time],
       Q.total_physical_reads,
       Q.[Avg Physical Reads],
       Q.total_logical_reads,
       Q.[Avg Logical Reads],
       Q.total_logical_writes,
       Q.[Avg Logical Writes],
       Q.statement_text
FROM QuerysMaisExecutadas Q
ORDER BY
    Q.execution_count DESC;


