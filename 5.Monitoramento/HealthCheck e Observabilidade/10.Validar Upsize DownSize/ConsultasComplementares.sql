-- Consultas complementares para análise de upsize/downsize

-- 1. Verificar configuração atual do banco
SELECT 
    database_name,
    service_objective,
    cpu_limit,
    max_db_memory,
    max_db_max_size_in_mb
FROM sys.dm_user_db_resource_governance;

-- 2. Histórico de métricas dos últimos 14 dias (dados disponíveis)
SELECT 
    end_time,
    avg_cpu_percent,
    avg_data_io_percent,
    avg_log_write_percent,
    avg_memory_usage_percent,
    avg_instance_cpu_percent,
    max_worker_percent,
    max_session_percent
FROM sys.dm_db_resource_stats
WHERE end_time >= DATEADD(day, -14, GETUTCDATE())
ORDER BY end_time DESC;

-- 3. Identificar consultas que mais consomem CPU
SELECT TOP 10
    qs.sql_handle,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.execution_count,
    qs.total_worker_time,
    qs.total_elapsed_time,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time / qs.execution_count DESC;

-- 4. Verificar waits mais frequentes
SELECT TOP 10
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms,
    signal_wait_time_ms,
    wait_time_ms / waiting_tasks_count AS avg_wait_time_ms
FROM sys.dm_db_wait_stats
WHERE waiting_tasks_count > 0
ORDER BY wait_time_ms DESC;

-- 5. Verificar sessões ativas e bloqueios
SELECT 
    session_id,
    status,
    cpu_time,
    memory_usage,
    reads,
    writes,
    logical_reads,
    blocking_session_id,
    wait_type,
    wait_time,
    last_request_start_time,
    program_name,
    host_name,
    login_name
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
  AND status IN ('running', 'runnable', 'suspended')
ORDER BY cpu_time DESC;