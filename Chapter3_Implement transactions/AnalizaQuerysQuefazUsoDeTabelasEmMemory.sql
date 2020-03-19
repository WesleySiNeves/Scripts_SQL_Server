SELECT OBJECT_NAME(PS.object_id) AS obj_name,
       cached_time AS cached_tm,
       last_execution_time AS last_exec_tm,
       execution_count AS ex_cnt,
       total_worker_time AS wrkr_tm,
       total_elapsed_time AS elpsd_tm
FROM sys.dm_exec_procedure_stats PS
    INNER JOIN sys.all_sql_modules SM
        ON SM.object_id = PS.object_id
WHERE SM.uses_native_compilation = 1;
