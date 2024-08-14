SELECT 
    req.session_id,
    req.status,
    req.command,
    req.wait_type,
    req.wait_time,
    req.last_wait_type,
    req.cpu_time,
    req.total_elapsed_time,
    st.text AS query_text,
    qs.query_hash,
    qs.execution_count,
    qs.total_worker_time,
    qs.total_elapsed_time AS query_total_elapsed_time,
    qs.total_logical_reads,
    qs.total_logical_writes,
    qs.total_physical_reads
FROM 
    sys.dm_exec_requests AS req
JOIN 
    sys.dm_exec_query_memory_grants AS qmg ON req.plan_handle = qmg.plan_handle
CROSS APPLY 
    sys.dm_exec_sql_text(req.sql_handle) AS st
JOIN 
    sys.dm_exec_query_stats AS qs ON qmg.sql_handle = qs.sql_handle
WHERE 
    req.wait_type = 'RESOURCE_SEMAPHORE'
ORDER BY 
    req.wait_time DESC;
