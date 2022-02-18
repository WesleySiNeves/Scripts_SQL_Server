

SELECT  O.name AS 'StoredProcName' ,
        O.object_id ,
        ps.execution_count ,
        CAST(ROUND(( ps.last_elapsed_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Last_elapsed_time_In_Sec' ,
        ps.last_execution_time AS 'Last_execution_time' ,
        ps.last_logical_reads AS 'Last_logical_reads' ,
        ps.last_logical_writes AS 'Last_logical_writes' ,
        ps.last_physical_reads AS 'Last_physical_reads' ,
        CAST(ROUND(( ps.last_worker_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Last_worker_time_In_Sec' ,
        CAST(ROUND(( ps.max_elapsed_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Max_elapsed_time_In_Sec' ,
        ps.max_logical_reads ,
        ps.max_logical_writes ,
        ps.max_physical_reads ,
        CAST(ROUND(( ps.max_worker_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Max_worker_time_In_Sec' ,
        CAST(ROUND(( ps.min_elapsed_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Min_elapsed_time_In_Sec' ,
        ps.min_logical_reads ,
        ps.min_logical_writes ,
        ps.min_physical_reads ,
        CAST(ROUND(( ps.min_worker_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Min_worker_time_In_Sec' ,
        CAST(ROUND(( ps.total_elapsed_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Total_elapsed_time_In_Sec' ,
        ps.total_logical_reads ,
        ps.total_logical_writes ,
        ps.total_physical_reads ,
        CAST(ROUND(( ps.total_worker_time / 1000000.00 ), 4) AS NUMERIC(8, 4)) AS 'Total_worker_time_In_Sec'
FROM    sys.objects O
        LEFT JOIN sys.dm_exec_procedure_stats ps ON O.name = OBJECT_NAME(ps.object_id,
                                                              ps.database_id)
WHERE   O.type = 'P'
  AND ps.execution_count > 0
ORDER BY Last_execution_time;