WITH QuerysMaiorCusto
  AS (
     SELECT RANK() OVER (ORDER BY
                             qs.total_worker_time DESC,
                             qs.sql_handle,
                             qs.statement_start_offset
                        ) AS row_no,
            (RANK() OVER (ORDER BY
                              qs.total_worker_time DESC,
                              qs.sql_handle,
                              qs.statement_start_offset
                         )
            ) % 2 AS l1,
			OB.name AS [ObjetcName],
          --  qs.creation_time,
            qs.last_execution_time,
            (qs.total_worker_time + 0.0) / 1000 AS total_worker_time,
            (qs.total_worker_time + 0.0) / (qs.execution_count * 1000) AS [AvgCPUTime],
            qs.total_logical_reads AS [LogicalReads],
            qs.total_logical_writes AS [logicalWrites],
            qs.execution_count,
            qs.total_logical_reads + qs.total_logical_writes AS [CustoIO],
            CAST( (qs.total_logical_reads + qs.total_logical_writes) / (qs.execution_count + 0.0) AS DECIMAL(18,2)) AS [AvgIO],
            CASE
                WHEN qs.sql_handle IS NULL THEN
                    ''
                ELSE
            (SUBSTRING(
                          st.text,
                          (qs.statement_start_offset + 2) / 2,
                          (CASE
                               WHEN qs.statement_end_offset = -1 THEN
                                   LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2
                               ELSE
                                   qs.statement_end_offset
                           END - qs.statement_start_offset
                          ) / 2
                      )
            )
            END AS query_text,
            pla.query_plan,
            DB_NAME(st.dbid) AS database_name,
            st.objectid AS object_id
     FROM sys.dm_exec_query_stats qs WITH (NOLOCK)
          CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
		   JOIN sys.objects OB  ON OB.object_id = st.objectid
          CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) pla
     WHERE total_worker_time > 0
           AND DB_NAME(st.dbid) = DB_NAME(DB_ID())
     )
SELECT R.database_name,
       R.ObjetcName,
       --R.row_no,
      -- R.l1,
       R.last_execution_time,
       R.total_worker_time,
       R.AvgCPUTime,
       [Total Paginas Lidas] = R.LogicalReads,
       [Total Lido em MB] = CONCAT(CAST(((R.LogicalReads * 8) / 1024) AS VARCHAR(10)), ' MB'),
       R.logicalWrites,
       R.execution_count,
       R.[CustoIO],
       R.AvgIO,
       R.query_text,
       R.query_plan
FROM QuerysMaiorCusto R (NOLOCK)
ORDER BY
    R.total_worker_time DESC;

