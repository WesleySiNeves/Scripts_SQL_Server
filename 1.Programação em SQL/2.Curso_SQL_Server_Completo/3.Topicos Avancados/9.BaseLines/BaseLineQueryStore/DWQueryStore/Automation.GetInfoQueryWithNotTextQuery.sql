CREATE PROCEDURE Automation.GetInfoQueryWithNotTextQuery
AS
BEGIN


    SELECT Query.query_text_id,
           --Query.query_sql_text,
           InfoQuery.query_id,
           InfoQuery.context_settings_id,
           InfoQuery.object_id,
           InfoQuery.Procedimento,
           InfoQuery.batch_sql_handle,
           InfoQuery.query_hash,
           InfoQuery.is_internal_query,
           InfoQuery.query_parameterization_type_desc,
           InfoQuery.last_execution_time,
           InfoQuery.count_compiles,
           InfoQuery.[avg_compile_duration/SEC],
           InfoQuery.[last_compile_duration/SEC],
           InfoQuery.[avg_bind_duration/SEC],
           InfoQuery.[last_bind_duration/SEC],
           InfoQuery.[avg_bind_cpu_time/SEC],
           InfoQuery.[last_bind_cpu_time/SEC],
           InfoQuery.[avg_optimize_duration/SEC],
           InfoQuery.[last_optimize_duration/SEC],
           InfoQuery.[avg_optimize_cpu_time/SEC],
           InfoQuery.[last_optimize_cpu_time/SEC],
           InfoQuery.avg_compile_memory_kb,
           InfoQuery.last_compile_memory_kb,
           InfoQuery.max_compile_memory_kb
    FROM
    (
        SELECT query.query_text_id,
               query.query_sql_text
        FROM sys.query_store_query_text AS query
    ) Query
        JOIN
        (
            SELECT QSQ.query_id,
                   QSQ.query_text_id,
                   QSQ.context_settings_id,
                   QSQ.object_id,
                   [Procedimento] = OBJECT_NAME(QSQ.object_id),
                   QSQ.batch_sql_handle,
                   QSQ.query_hash,
                   QSQ.is_internal_query,
                   QSQ.query_parameterization_type_desc,
                   QSQ.last_execution_time,
                   QSQ.count_compiles,
                   [avg_compile_duration/SEC] = CAST((QSQ.avg_compile_duration / 1000000.0) AS DECIMAL(18, 4)),     --compilação do plano de execução
                   [last_compile_duration/SEC] = CAST((QSQ.last_compile_duration / 1000000.0) AS DECIMAL(18, 4)),   --compilação do plano de execução
                   [avg_bind_duration/SEC] = CAST((QSQ.avg_bind_duration / 1000000.0) AS DECIMAL(18, 4)),           --binding do plano de execução
                   [last_bind_duration/SEC] = CAST((QSQ.last_bind_duration / 1000000.0) AS DECIMAL(18, 4)),         --binding do plano de execução
                   [avg_bind_cpu_time/SEC] = CAST((QSQ.avg_bind_cpu_time / 1000000.0) AS DECIMAL(18, 4)),           --binding CPU do plano de execução
                   [last_bind_cpu_time/SEC] = CAST((QSQ.last_bind_cpu_time / 1000000.0) AS DECIMAL(18, 4)),         --binding CPU do plano de execução
                   [avg_optimize_duration/SEC] = CAST((QSQ.avg_optimize_duration / 1000000.0) AS DECIMAL(18, 4)),   --Tempo de otimização do plano de execução
                   [last_optimize_duration/SEC] = CAST((QSQ.last_optimize_duration / 1000000.0) AS DECIMAL(18, 4)), --Tempo de otimização do plano de execução
                   [avg_optimize_cpu_time/SEC] = CAST((QSQ.avg_optimize_cpu_time / 1000000.0) AS DECIMAL(18, 4)),   --Tempo de otimização do plano de execução
                   [last_optimize_cpu_time/SEC] = CAST((QSQ.last_optimize_cpu_time / 1000000.0) AS DECIMAL(18, 4)), --Tempo de otimização do plano de execução
                   QSQ.avg_compile_memory_kb,
                   QSQ.last_compile_memory_kb,
                   QSQ.max_compile_memory_kb
            FROM sys.query_store_query AS QSQ
        ) InfoQuery
            ON InfoQuery.query_text_id = Query.query_text_id;

END;

--WHERE Query.query_text_id = '9643651';

