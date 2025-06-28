/*
=============================================
Autor: Wesley David Santos
Data de Criação: 2024-12-19
Descrição: Rotina COMPLETA para identificar queries com maiores waits
           e análise detalhada dos tipos de espera no SQL Server
           
Versão: 1.0 - Análise abrangente de waits

Funcionalidades:
📊 ANÁLISE DE WAITS POR QUERY:
- Queries com maiores tempos de espera
- Tipos de wait mais frequentes por query
- Estatísticas detalhadas de execução

🔍 ANÁLISE GERAL DE WAITS:
- Top waits do servidor
- Percentual de cada tipo de wait
- Tendências e padrões de espera

💡 DIAGNÓSTICO E RECOMENDAÇÕES:
- Possíveis causas para cada tipo de wait
- Sugestões de otimização
- Alertas para waits críticos

Uso: Execute as seções conforme necessário
=============================================
*/

-- ═══════════════════════════════════════════════════════════════
-- 🔍 SEÇÃO 1: QUERIES COM MAIORES WAITS ATIVOS
-- ═══════════════════════════════════════════════════════════════

PRINT '🔍 ANALISANDO QUERIES COM WAITS ATIVOS...';
PRINT '═══════════════════════════════════════════════════════════════';

-- Queries atualmente em espera
SELECT TOP 20
    r.session_id AS [Session ID],
    r.blocking_session_id AS [Bloqueando],
    r.wait_type AS [Tipo Wait],
    r.wait_time AS [Tempo Wait (ms)],
    r.wait_resource AS [Recurso],
    r.status AS [Status],
    r.command AS [Comando],
    r.cpu_time AS [CPU Time (ms)],
    r.total_elapsed_time AS [Tempo Total (ms)],
    r.logical_reads AS [Leituras Lógicas],
    r.writes AS [Escritas],
    DB_NAME(r.database_id) AS [Database],
    s.login_name AS [Login],
    s.host_name AS [Host],
    s.program_name AS [Programa],
    SUBSTRING(st.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) AS [Query Atual],
    -- Classificação do wait
    CASE 
        WHEN r.wait_type LIKE 'LCK_%' THEN '🔒 Lock/Bloqueio'
        WHEN r.wait_type LIKE 'PAGEIOLATCH_%' THEN '💾 I/O Disco'
        WHEN r.wait_type LIKE 'RESOURCE_SEMAPHORE%' THEN '🧠 Memória'
        WHEN r.wait_type LIKE 'CXPACKET%' OR r.wait_type LIKE 'CXCONSUMER%' THEN '⚡ Paralelismo'
        WHEN r.wait_type LIKE 'ASYNC_NETWORK_IO' THEN '🌐 Rede/Cliente'
        WHEN r.wait_type LIKE 'WRITELOG' THEN '📝 Log de Transação'
        WHEN r.wait_type LIKE 'SOS_SCHEDULER_YIELD' THEN '⚙️ CPU/Scheduler'
        ELSE '❓ Outros'
    END AS [Categoria Wait]
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.wait_type IS NOT NULL
    AND r.wait_type NOT IN (
        'BROKER_EVENTHANDLER', 'BROKER_RECEIVE_WAITFOR', 'BROKER_TASK_STOP',
        'BROKER_TO_FLUSH', 'BROKER_TRANSMITTER', 'CHECKPOINT_QUEUE',
        'CHKPT', 'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT', 'CLR_SEMAPHORE',
        'DBMIRROR_DBM_EVENT', 'DBMIRROR_EVENTS_QUEUE', 'DBMIRROR_WORKER_QUEUE',
        'DBMIRRORING_CMD', 'DIRTY_PAGE_POLL', 'DISPATCHER_QUEUE_SEMAPHORE',
        'EXECSYNC', 'FSAGENT', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 'FT_IFTSHC_MUTEX',
        'HADR_CLUSAPI_CALL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'HADR_LOGCAPTURE_WAIT',
        'HADR_NOTIFICATION_DEQUEUE', 'HADR_TIMER_TASK', 'HADR_WORK_QUEUE',
        'KSOURCE_WAKEUP', 'LAZYWRITER_SLEEP', 'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE',
        'PWAIT_ALL_COMPONENTS_INITIALIZED', 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 'REQUEST_FOR_DEADLOCK_SEARCH',
        'RESOURCE_QUEUE', 'SERVER_IDLE_CHECK', 'SLEEP_BPOOL_FLUSH', 'SLEEP_DBSTARTUP',
        'SLEEP_DCOMSTARTUP', 'SLEEP_MASTERDBREADY', 'SLEEP_MASTERMDREADY',
        'SLEEP_MASTERUPGRADED', 'SLEEP_MSDBSTARTUP', 'SLEEP_SYSTEMTASK', 'SLEEP_TASK',
        'SLEEP_TEMPDBSTARTUP', 'SNI_HTTP_ACCEPT', 'SP_SERVER_DIAGNOSTICS_SLEEP',
        'SQLTRACE_BUFFER_FLUSH', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 'SQLTRACE_WAIT_ENTRIES',
        'WAIT_FOR_RESULTS', 'WAITFOR', 'WAITFOR_TASKSHUTDOWN', 'WAIT_XTP_HOST_WAIT',
        'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 'WAIT_XTP_CKPT_CLOSE', 'XE_DISPATCHER_JOIN',
        'XE_DISPATCHER_WAIT', 'XE_TIMER_EVENT'
    )
ORDER BY r.wait_time DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';

-- ═══════════════════════════════════════════════════════════════
-- 📊 SEÇÃO 2: ESTATÍSTICAS HISTÓRICAS DE WAITS POR QUERY
-- ═══════════════════════════════════════════════════════════════

PRINT '📊 ANALISANDO HISTÓRICO DE WAITS POR QUERY...';
PRINT '═══════════════════════════════════════════════════════════════';

-- Top queries com maiores waits históricos
SELECT TOP 20
    qs.execution_count AS [Execuções],
    qs.total_elapsed_time / 1000 AS [Tempo Total (ms)],
    qs.total_elapsed_time / qs.execution_count / 1000 AS [Tempo Médio (ms)],
    qs.total_worker_time / 1000 AS [CPU Total (ms)],
    qs.total_worker_time / qs.execution_count / 1000 AS [CPU Médio (ms)],
    (qs.total_elapsed_time - qs.total_worker_time) / 1000 AS [Wait Total (ms)],
    (qs.total_elapsed_time - qs.total_worker_time) / qs.execution_count / 1000 AS [Wait Médio (ms)],
    qs.total_logical_reads AS [Leituras Lógicas],
    qs.total_logical_reads / qs.execution_count AS [Leituras Médias],
    qs.total_physical_reads AS [Leituras Físicas],
    qs.total_logical_writes AS [Escritas],
    qs.query_hash,
    qs.query_plan_hash,
    DB_NAME(st.dbid) AS [Database],
    -- Percentual de wait em relação ao tempo total
    CAST(((qs.total_elapsed_time - qs.total_worker_time) * 100.0 / qs.total_elapsed_time) AS DECIMAL(5,2)) AS [% Wait],
    -- Query text (primeiros 500 caracteres)
    LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 500) AS [Query Text]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE qs.total_elapsed_time > qs.total_worker_time -- Apenas queries com waits
    AND qs.execution_count > 1 -- Queries executadas mais de uma vez
ORDER BY (qs.total_elapsed_time - qs.total_worker_time) DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';

-- ═══════════════════════════════════════════════════════════════
-- 🏆 SEÇÃO 3: TOP WAITS DO SERVIDOR (ESTATÍSTICAS GERAIS)
-- ═══════════════════════════════════════════════════════════════

PRINT '🏆 ANALISANDO TOP WAITS DO SERVIDOR...';
PRINT '═══════════════════════════════════════════════════════════════';

-- Estatísticas gerais de waits desde o último restart
WITH WaitStats AS (
    SELECT 
        wait_type,
        wait_time_ms,
        waiting_tasks_count,
        signal_wait_time_ms,
        wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        'BROKER_EVENTHANDLER', 'BROKER_RECEIVE_WAITFOR', 'BROKER_TASK_STOP',
        'BROKER_TO_FLUSH', 'BROKER_TRANSMITTER', 'CHECKPOINT_QUEUE',
        'CHKPT', 'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT', 'CLR_SEMAPHORE',
        'DBMIRROR_DBM_EVENT', 'DBMIRROR_EVENTS_QUEUE', 'DBMIRROR_WORKER_QUEUE',
        'DBMIRRORING_CMD', 'DIRTY_PAGE_POLL', 'DISPATCHER_QUEUE_SEMAPHORE',
        'EXECSYNC', 'FSAGENT', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 'FT_IFTSHC_MUTEX',
        'HADR_CLUSAPI_CALL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'HADR_LOGCAPTURE_WAIT',
        'HADR_NOTIFICATION_DEQUEUE', 'HADR_TIMER_TASK', 'HADR_WORK_QUEUE',
        'KSOURCE_WAKEUP', 'LAZYWRITER_SLEEP', 'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE',
        'PWAIT_ALL_COMPONENTS_INITIALIZED', 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 'REQUEST_FOR_DEADLOCK_SEARCH',
        'RESOURCE_QUEUE', 'SERVER_IDLE_CHECK', 'SLEEP_BPOOL_FLUSH', 'SLEEP_DBSTARTUP',
        'SLEEP_DCOMSTARTUP', 'SLEEP_MASTERDBREADY', 'SLEEP_MASTERMDREADY',
        'SLEEP_MASTERUPGRADED', 'SLEEP_MSDBSTARTUP', 'SLEEP_SYSTEMTASK', 'SLEEP_TASK',
        'SLEEP_TEMPDBSTARTUP', 'SNI_HTTP_ACCEPT', 'SP_SERVER_DIAGNOSTICS_SLEEP',
        'SQLTRACE_BUFFER_FLUSH', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 'SQLTRACE_WAIT_ENTRIES',
        'WAIT_FOR_RESULTS', 'WAITFOR', 'WAITFOR_TASKSHUTDOWN', 'WAIT_XTP_HOST_WAIT',
        'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 'WAIT_XTP_CKPT_CLOSE', 'XE_DISPATCHER_JOIN',
        'XE_DISPATCHER_WAIT', 'XE_TIMER_EVENT'
    )
),
TotalWaits AS (
    SELECT SUM(wait_time_ms) AS total_wait_time
    FROM WaitStats
)
SELECT TOP 20
    ws.wait_type AS [Tipo de Wait],
    ws.waiting_tasks_count AS [Contagem Tasks],
    ws.wait_time_ms AS [Tempo Wait (ms)],
    ws.wait_time_ms / 1000.0 AS [Tempo Wait (seg)],
    ws.wait_time_ms / 60000.0 AS [Tempo Wait (min)],
    CAST((ws.wait_time_ms * 100.0 / tw.total_wait_time) AS DECIMAL(5,2)) AS [% do Total],
    ws.wait_time_ms / ws.waiting_tasks_count AS [Média por Task (ms)],
    ws.signal_wait_time_ms AS [Signal Wait (ms)],
    ws.resource_wait_time_ms AS [Resource Wait (ms)],
    -- Classificação e possível causa
    CASE 
        WHEN ws.wait_type LIKE 'LCK_%' THEN '🔒 Bloqueios/Locks'
        WHEN ws.wait_type LIKE 'PAGEIOLATCH_%' THEN '💾 I/O de Disco'
        WHEN ws.wait_type LIKE 'RESOURCE_SEMAPHORE%' THEN '🧠 Pressão de Memória'
        WHEN ws.wait_type LIKE 'CXPACKET%' OR ws.wait_type LIKE 'CXCONSUMER%' THEN '⚡ Paralelismo'
        WHEN ws.wait_type LIKE 'ASYNC_NETWORK_IO' THEN '🌐 Rede/Cliente Lento'
        WHEN ws.wait_type LIKE 'WRITELOG' THEN '📝 Log de Transação'
        WHEN ws.wait_type LIKE 'SOS_SCHEDULER_YIELD' THEN '⚙️ Pressão de CPU'
        WHEN ws.wait_type LIKE 'THREADPOOL' THEN '🔄 Pool de Threads'
        WHEN ws.wait_type LIKE 'IO_COMPLETION' THEN '💿 I/O Assíncrono'
        ELSE '❓ Outros'
    END AS [Categoria],
    -- Possível causa/recomendação
    CASE 
        WHEN ws.wait_type LIKE 'LCK_%' THEN 'Verificar bloqueios, otimizar transações'
        WHEN ws.wait_type LIKE 'PAGEIOLATCH_%' THEN 'Verificar I/O do disco, considerar SSD'
        WHEN ws.wait_type LIKE 'RESOURCE_SEMAPHORE%' THEN 'Aumentar memória ou otimizar queries'
        WHEN ws.wait_type LIKE 'CXPACKET%' THEN 'Ajustar MAXDOP ou Cost Threshold'
        WHEN ws.wait_type LIKE 'ASYNC_NETWORK_IO' THEN 'Verificar aplicação cliente'
        WHEN ws.wait_type LIKE 'WRITELOG' THEN 'Otimizar log, verificar disco do log'
        WHEN ws.wait_type LIKE 'SOS_SCHEDULER_YIELD' THEN 'Verificar CPU, otimizar queries'
        WHEN ws.wait_type LIKE 'THREADPOOL' THEN 'Verificar conexões, aumentar max worker threads'
        ELSE 'Analisar caso específico'
    END AS [Recomendação]
FROM WaitStats ws
CROSS JOIN TotalWaits tw
ORDER BY ws.wait_time_ms DESC;

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';

-- ═══════════════════════════════════════════════════════════════
-- 🚨 SEÇÃO 4: ALERTAS E DIAGNÓSTICOS CRÍTICOS
-- ═══════════════════════════════════════════════════════════════

PRINT '🚨 VERIFICANDO ALERTAS CRÍTICOS...';
PRINT '═══════════════════════════════════════════════════════════════';

-- Verificar situações críticas
DECLARE @AlertCount INT = 0;

-- 1. Verificar bloqueios ativos
IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE blocking_session_id > 0)
BEGIN
    SET @AlertCount = @AlertCount + 1;
    PRINT '🚨 ALERTA: Bloqueios ativos detectados!';
    
    SELECT 
        r.session_id AS [Sessão Bloqueada],
        r.blocking_session_id AS [Sessão Bloqueando],
        r.wait_time AS [Tempo Bloqueio (ms)],
        r.wait_resource AS [Recurso],
        DB_NAME(r.database_id) AS [Database],
        SUBSTRING(st.text, (r.statement_start_offset/2)+1,
            ((CASE r.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE r.statement_end_offset
            END - r.statement_start_offset)/2) + 1) AS [Query Bloqueada]
    FROM sys.dm_exec_requests r
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
    WHERE r.blocking_session_id > 0
    ORDER BY r.wait_time DESC;
    
    PRINT '';
END

-- 2. Verificar pressão de memória
IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE wait_type LIKE 'RESOURCE_SEMAPHORE%')
BEGIN
    SET @AlertCount = @AlertCount + 1;
    PRINT '🚨 ALERTA: Pressão de memória detectada!';
    PRINT 'Recomendação: Verificar queries com alto consumo de memória ou aumentar RAM.';
    PRINT '';
END

-- 3. Verificar alto paralelismo
IF EXISTS (
    SELECT 1 FROM sys.dm_os_wait_stats 
    WHERE wait_type IN ('CXPACKET', 'CXCONSUMER') 
    AND wait_time_ms > 10000 -- Mais de 10 segundos
)
BEGIN
    SET @AlertCount = @AlertCount + 1;
    PRINT '🚨 ALERTA: Alto tempo de espera em paralelismo!';
    PRINT 'Recomendação: Considerar ajustar MAXDOP ou Cost Threshold for Parallelism.';
    PRINT '';
END

-- 4. Verificar I/O lento
IF EXISTS (
    SELECT 1 FROM sys.dm_os_wait_stats 
    WHERE wait_type LIKE 'PAGEIOLATCH_%' 
    AND wait_time_ms / waiting_tasks_count > 100 -- Média > 100ms por I/O
)
BEGIN
    SET @AlertCount = @AlertCount + 1;
    PRINT '🚨 ALERTA: I/O de disco lento detectado!';
    PRINT 'Recomendação: Verificar performance do disco, considerar SSD.';
    PRINT '';
END

IF @AlertCount = 0
    PRINT '✅ Nenhum alerta crítico detectado no momento.';

PRINT '';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT '📋 RESUMO DA ANÁLISE DE WAITS CONCLUÍDA';
PRINT '═══════════════════════════════════════════════════════════════';
PRINT 'ℹ️  Para análise contínua, execute este script periodicamente.';
PRINT 'ℹ️  Para waits específicos, use os scripts dedicados na pasta Waits.';
PRINT 'ℹ️  Documente padrões de wait para análise de tendências.';
PRINT '═══════════════════════════════════════════════════════════════';

/*
💡 GUIA RÁPIDO DE INTERPRETAÇÃO DE WAITS:

🔒 LCK_* (Locks/Bloqueios):
   - Causa: Transações longas, falta de índices, design inadequado
   - Solução: Otimizar transações, criar índices, revisar lógica

💾 PAGEIOLATCH_* (I/O de Disco):
   - Causa: Disco lento, falta de memória, queries ineficientes
   - Solução: SSD, mais RAM, otimizar queries, índices

🧠 RESOURCE_SEMAPHORE (Memória):
   - Causa: Queries com alto consumo de memória, pouca RAM
   - Solução: Otimizar queries, aumentar memória, revisar joins

⚡ CXPACKET/CXCONSUMER (Paralelismo):
   - Causa: MAXDOP alto, Cost Threshold baixo, queries complexas
   - Solução: Ajustar MAXDOP, aumentar Cost Threshold

🌐 ASYNC_NETWORK_IO (Rede/Cliente):
   - Causa: Cliente lento processando resultados, rede lenta
   - Solução: Otimizar aplicação, reduzir dados retornados

📝 WRITELOG (Log de Transação):
   - Causa: Disco do log lento, transações grandes
   - Solução: SSD para log, otimizar transações, log em disco separado

⚙️ SOS_SCHEDULER_YIELD (CPU):
   - Causa: Alta utilização de CPU, queries ineficientes
   - Solução: Otimizar queries, mais CPU, revisar índices
*/