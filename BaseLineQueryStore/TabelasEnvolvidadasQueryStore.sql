SELECT QSQ.query_id,
       QSQ.query_text_id,
       QSQ.context_settings_id,
       Objeto.name,
       QSQ.batch_sql_handle,
       QSQ.query_hash,
       QSQ.is_internal_query,
       QSQ.query_parameterization_type,
       QSQ.query_parameterization_type_desc,
       QSQ.initial_compile_start_time,
       QSQ.last_compile_start_time,
       QSQ.last_execution_time,
       QSQ.last_compile_batch_sql_handle,
       QSQ.last_compile_batch_offset_start,
       QSQ.last_compile_batch_offset_end,
       QSQ.count_compiles,
       QSQ.avg_compile_duration,
       QSQ.last_compile_duration,
       QSQ.avg_bind_duration,
       QSQ.last_bind_duration,
       QSQ.avg_bind_cpu_time,
       QSQ.last_bind_cpu_time,
       QSQ.avg_optimize_duration,
       QSQ.last_optimize_duration,
       QSQ.avg_optimize_cpu_time,
       QSQ.last_optimize_cpu_time,
       QSQ.avg_compile_memory_kb,
       QSQ.last_compile_memory_kb,
       QSQ.max_compile_memory_kb,
       QSQ.is_clouddb_internal_query
  FROM sys.query_store_query AS QSQ
       OUTER APPLY(SELECT * FROM sys.objects AS O WHERE O.object_id = QSQ.object_id)Objeto
 ORDER BY
    QSQ.query_id;

SELECT * FROM sys.query_store_plan AS QSP;

SELECT * FROM sys.query_store_query_text AS QSQT;

SELECT * FROM sys.query_store_wait_stats AS QSWS;

SELECT * FROM sys.query_store_runtime_stats AS QSRS;

SELECT * FROM sys.query_store_runtime_stats_interval AS QSRSI;