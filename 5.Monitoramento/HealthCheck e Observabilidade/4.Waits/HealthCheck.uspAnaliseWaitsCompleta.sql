/*
=============================================
Autor: Wesley David Santos
Data de Criação: 2024-12-19
Descrição: PROCEDURE ESPECIALISTA EM TUNING - Análise Completa de Waits
           Diagnóstico avançado e recomendações específicas para otimização
           
Versão: 2.0 - Análise Especializada para Tuning

Funcionalidades Avançadas:
🎯 DIAGNÓSTICO COMPLETO:
- Análise detalhada de waits ativos e históricos
- Identificação de gargalos de performance
- Métricas avançadas de CPU, I/O e memória
- Correlação entre waits e queries problemáticas

📊 RELATÓRIOS EXECUTIVOS:
- Dashboard de performance em tempo real
- Tendências e padrões de comportamento
- Alertas críticos automatizados
- Recomendações priorizadas por impacto

🔧 RECOMENDAÇÕES ESPECÍFICAS:
- Sugestões de índices e otimizações
- Configurações de servidor recomendadas
- Scripts de correção automática
- Plano de ação estruturado

Uso: EXEC uspAnaliseWaitsCompleta @TipoAnalise = 'COMPLETA', @MostrarRecomendacoes = 1
=============================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspAnaliseWaitsCompleta
    @TipoAnalise VARCHAR(20) = 'COMPLETA',  -- COMPLETA, RAPIDA, CRITICA
    @MostrarRecomendacoes BIT = 1,          -- Exibir recomendações detalhadas
    @MostrarScripts BIT = 0,                -- Gerar scripts de correção
    @TopQueries INT = 20,                   -- Número de queries a analisar
    @AlertasApenas BIT = 0,                 -- Mostrar apenas alertas críticos
    @Debug BIT = 0                          -- Modo debug com informações extras
AS
BEGIN
    SET NOCOUNT ON;
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 DECLARAÇÃO DE VARIÁVEIS E CONFIGURAÇÕES INICIAIS
    -- ═══════════════════════════════════════════════════════════════
    
    DECLARE @InicioExecucao DATETIME2 = GETDATE();
    DECLARE @AlertCount INT = 0;
    DECLARE @PerformanceScore DECIMAL(5,2) = 100.0;
    DECLARE @StatusGeral VARCHAR(20) = 'EXCELENTE';
    DECLARE @RecomendacoesCriticas TABLE (
        ID INT IDENTITY(1,1),
        Prioridade VARCHAR(10),
        Categoria VARCHAR(50),
        Problema VARCHAR(200),
        Solucao VARCHAR(500),
        Script VARCHAR(1000),
        ImpactoEstimado VARCHAR(20)
    );
    
    -- Cabeçalho do relatório
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '🎯 ANÁLISE ESPECIALIZADA DE WAITS E PERFORMANCE - SQL SERVER';
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT 'Executado em: ' + CONVERT(VARCHAR, @InicioExecucao, 120);
    PRINT 'Tipo de Análise: ' + @TipoAnalise;
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '';
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🚨 SEÇÃO 1: ALERTAS CRÍTICOS E DIAGNÓSTICO IMEDIATO
    -- ═══════════════════════════════════════════════════════════════
    
    IF @AlertasApenas = 0 OR @TipoAnalise = 'CRITICA'
    BEGIN
        PRINT '🚨 VERIFICANDO ALERTAS CRÍTICOS E PROBLEMAS IMEDIATOS...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- 1. BLOQUEIOS ATIVOS (CRÍTICO)
        IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE blocking_session_id > 0)
        BEGIN
            SET @AlertCount = @AlertCount + 1;
            SET @PerformanceScore = @PerformanceScore - 25;
            
            PRINT '🔴 CRÍTICO: Bloqueios ativos detectados!';
            PRINT 'Impacto: Alto - Usuários podem estar esperando';
            PRINT '';
            
            SELECT 
                '🔒 BLOQUEIO ATIVO' AS [Tipo Alerta],
                r.session_id AS [Sessão Bloqueada],
                r.blocking_session_id AS [Sessão Bloqueando],
                r.wait_time AS [Tempo Bloqueio (ms)],
                r.wait_resource AS [Recurso Bloqueado],
                DB_NAME(r.database_id) AS [Database],
                s.login_name AS [Login Bloqueado],
                s.host_name AS [Host],
                s.program_name AS [Aplicação],
                -- Query sendo bloqueada
                SUBSTRING(st.text, (r.statement_start_offset/2)+1,
                    ((CASE r.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE r.statement_end_offset
                    END - r.statement_start_offset)/2) + 1) AS [Query Bloqueada],
                -- Classificação da severidade
                CASE 
                    WHEN r.wait_time > 30000 THEN '🔴 CRÍTICO (>30s)'
                    WHEN r.wait_time > 10000 THEN '🟡 ALTO (>10s)'
                    ELSE '🟢 MODERADO'
                END AS [Severidade]
            FROM sys.dm_exec_requests r
            INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
            CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
            WHERE r.blocking_session_id > 0
            ORDER BY r.wait_time DESC;
            
            -- Inserir recomendação
            INSERT INTO @RecomendacoesCriticas VALUES (
                'CRÍTICA', 'Bloqueios', 'Bloqueios ativos detectados',
                'Investigar transações longas, otimizar queries, revisar lógica de negócio',
                'SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id > 0',
                'ALTO'
            );
            
            PRINT '';
        END
        
        -- 2. PRESSÃO DE MEMÓRIA (CRÍTICO)
        IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE wait_type LIKE 'RESOURCE_SEMAPHORE%')
        BEGIN
            SET @AlertCount = @AlertCount + 1;
            SET @PerformanceScore = @PerformanceScore - 20;
            
            PRINT '🔴 CRÍTICO: Pressão de memória detectada!';
            PRINT 'Impacto: Alto - Queries aguardando memória disponível';
            
            -- Análise detalhada de memória
            SELECT 
                '🧠 PRESSÃO MEMÓRIA' AS [Tipo Alerta],
                COUNT(*) AS [Queries Aguardando],
                SUM(r.granted_query_memory) * 8 / 1024 AS [Memória Concedida (MB)],
                AVG(r.wait_time) AS [Tempo Médio Espera (ms)],
                MAX(r.wait_time) AS [Maior Tempo Espera (ms)]
            FROM sys.dm_exec_requests r
            WHERE r.wait_type LIKE 'RESOURCE_SEMAPHORE%';
            
            INSERT INTO @RecomendacoesCriticas VALUES (
                'CRÍTICA', 'Memória', 'Pressão de memória detectada',
                'Aumentar memória do servidor, otimizar queries com alto consumo, revisar joins',
                'sp_configure "max server memory"',
                'ALTO'
            );
            
            PRINT '';
        END
        
        -- 3. I/O EXTREMAMENTE LENTO (CRÍTICO) - ANÁLISE DETALHADA
        IF EXISTS (
            SELECT 1 FROM sys.dm_os_wait_stats 
            WHERE wait_type LIKE 'PAGEIOLATCH_%' 
            AND wait_time_ms / NULLIF(waiting_tasks_count, 0) > 200 -- Média > 200ms
        )
        BEGIN
            SET @AlertCount = @AlertCount + 1;
            SET @PerformanceScore = @PerformanceScore - 15;
            
            PRINT '🔴 CRÍTICO: I/O de disco extremamente lento!';
            PRINT 'Impacto: Alto - Performance geral comprometida';
            PRINT '';
            
            -- Análise detalhada de I/O por arquivo
            SELECT 
                '💾 ANÁLISE I/O DETALHADA' AS [Tipo Alerta],
                DB_NAME(vfs.database_id) AS [Database],
                mf.name AS [Logical Name],
                mf.physical_name AS [Physical Name],
                CASE mf.type_desc
                    WHEN 'ROWS' THEN '📊 DADOS'
                    WHEN 'LOG' THEN '📝 LOG'
                    ELSE mf.type_desc
                END AS [Tipo Arquivo],
                -- Latências calculadas
                CASE 
                    WHEN vfs.num_of_reads > 0 
                    THEN CAST((vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) AS DECIMAL(10,2))
                    ELSE 0
                END AS [Latência Leitura (ms)],
                CASE 
                    WHEN vfs.num_of_writes > 0 
                    THEN CAST((vfs.io_stall_write_ms * 1.0 / vfs.num_of_writes) AS DECIMAL(10,2))
                    ELSE 0
                END AS [Latência Escrita (ms)],
                CASE 
                    WHEN (vfs.num_of_reads + vfs.num_of_writes) > 0 
                    THEN CAST((vfs.io_stall * 1.0 / (vfs.num_of_reads + vfs.num_of_writes)) AS DECIMAL(10,2))
                    ELSE 0
                END AS [Latência Total (ms)],
                vfs.num_of_reads AS [Total Leituras],
                vfs.num_of_writes AS [Total Escritas],
                CAST(vfs.num_of_bytes_read / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS [MB Lidos],
                CAST(vfs.num_of_bytes_written / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS [MB Escritos],
                -- Diagnóstico automático
                CASE 
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 70 
                    THEN '🔴 CRÍTICO - Leitura muito lenta (>70ms)'
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 20 
                    THEN '🟡 ATENÇÃO - Leitura lenta (>20ms)'
                    WHEN vfs.num_of_writes > 0 AND (vfs.io_stall_write_ms * 1.0 / vfs.num_of_writes) > 10 
                    THEN '🟠 MODERADO - Escrita lenta (>10ms)'
                    ELSE '🟢 NORMAL'
                END AS [Status I/O],
                -- Causa provável
                CASE 
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 70 AND mf.type_desc = 'ROWS'
                    THEN '🎯 CAUSA: Disco lento + Índices inadequados + Queries ineficientes'
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 70 AND mf.type_desc = 'LOG'
                    THEN '🎯 CAUSA: Disco lento + Transações longas + Log fragmentado'
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 20
                    THEN '🎯 CAUSA: Performance do disco ou fragmentação de índices'
                    WHEN vfs.num_of_writes > 0 AND (vfs.io_stall_write_ms * 1.0 / vfs.num_of_writes) > 10
                    THEN '🎯 CAUSA: Disco lento para escritas ou contenção de log'
                    ELSE '✅ Performance adequada'
                END AS [Causa Identificada],
                -- Recomendação específica
                CASE 
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 70 AND mf.type_desc = 'ROWS'
                    THEN '🔧 AÇÃO: 1)Verificar saúde do disco 2)Analisar índices fragmentados 3)Otimizar queries com alto I/O'
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 70 AND mf.type_desc = 'LOG'
                    THEN '🔧 AÇÃO: 1)Verificar disco do log 2)Reduzir transações longas 3)Considerar múltiplos arquivos de log'
                    WHEN vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 20
                    THEN '🔧 AÇÃO: 1)Rebuild índices fragmentados 2)Analisar missing indexes 3)Verificar estatísticas'
                    WHEN vfs.num_of_writes > 0 AND (vfs.io_stall_write_ms * 1.0 / vfs.num_of_writes) > 10
                    THEN '🔧 AÇÃO: 1)Verificar disco 2)Otimizar checkpoint 3)Revisar configurações de log'
                    ELSE '✅ Monitorar tendências'
                END AS [Ação Recomendada]
            FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
            INNER JOIN sys.database_files mf ON vfs.file_id = mf.file_id
            WHERE vfs.database_id = DB_ID()
                AND (
                    (vfs.num_of_reads > 0 AND (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads) > 15) OR
                    (vfs.num_of_writes > 0 AND (vfs.io_stall_write_ms * 1.0 / vfs.num_of_writes) > 8)
                )
            ORDER BY 
                CASE 
                    WHEN vfs.num_of_reads > 0 THEN (vfs.io_stall_read_ms * 1.0 / vfs.num_of_reads)
                    ELSE 0
                END DESC;
            
            INSERT INTO @RecomendacoesCriticas VALUES (
                'CRÍTICA', 'I/O', 'I/O de disco extremamente lento (>200ms)',
                'Verificar saúde do disco, considerar SSD, otimizar queries, revisar índices',
                'SELECT * FROM sys.dm_io_virtual_file_stats(NULL, NULL)',
                'ALTO'
            );
            
            PRINT '';
        END
        
        -- 4. CPU SATURADA (ALTO)
        IF EXISTS (
            SELECT 1 FROM sys.dm_os_wait_stats 
            WHERE wait_type = 'SOS_SCHEDULER_YIELD' 
            AND wait_time_ms > 50000 -- Mais de 50 segundos
        )
        BEGIN
            SET @AlertCount = @AlertCount + 1;
            SET @PerformanceScore = @PerformanceScore - 10;
            
            PRINT '🟡 ALTO: CPU com alta utilização!';
            
            INSERT INTO @RecomendacoesCriticas VALUES (
                'ALTA', 'CPU', 'CPU com alta utilização detectada',
                'Otimizar queries ineficientes, revisar índices, considerar upgrade de CPU',
                'SELECT * FROM sys.dm_exec_query_stats ORDER BY total_worker_time DESC',
                'MÉDIO'
            );
        END
        
        -- 5. PARALELISMO EXCESSIVO (MÉDIO)
        IF EXISTS (
            SELECT 1 FROM sys.dm_os_wait_stats 
            WHERE wait_type IN ('CXPACKET', 'CXCONSUMER') 
            AND wait_time_ms > 30000 -- Mais de 30 segundos
        )
        BEGIN
            SET @AlertCount = @AlertCount + 1;
            SET @PerformanceScore = @PerformanceScore - 5;
            
            PRINT '🟡 MÉDIO: Problemas de paralelismo detectados!';
            
            INSERT INTO @RecomendacoesCriticas VALUES (
                'MÉDIA', 'Paralelismo', 'Waits excessivos de paralelismo',
                'Ajustar MAXDOP, revisar Cost Threshold for Parallelism, otimizar queries',
                'sp_configure "max degree of parallelism"',
                'MÉDIO'
            );
        END
        
        -- Determinar status geral
        SET @StatusGeral = CASE 
            WHEN @PerformanceScore >= 90 THEN 'EXCELENTE'
            WHEN @PerformanceScore >= 75 THEN 'BOM'
            WHEN @PerformanceScore >= 60 THEN 'REGULAR'
            WHEN @PerformanceScore >= 40 THEN 'RUIM'
            ELSE 'CRÍTICO'
        END;
        
        PRINT 'Score de Performance: ' + CAST(@PerformanceScore AS VARCHAR(10)) + '% - Status: ' + @StatusGeral;
        PRINT 'Total de Alertas: ' + CAST(@AlertCount AS VARCHAR(10));
        PRINT '';
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📊 SEÇÃO 2: ANÁLISE DETALHADA DE WAITS ATIVOS
    -- ═══════════════════════════════════════════════════════════════
    
    IF @TipoAnalise IN ('COMPLETA', 'RAPIDA')
    BEGIN
        PRINT '📊 ANÁLISE DETALHADA DE WAITS ATIVOS...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- Waits ativos com análise avançada
        SELECT TOP (@TopQueries)
            '🔍 WAIT ATIVO' AS [Tipo],
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
            r.granted_query_memory * 8 / 1024 AS [Memória Concedida (MB)],
            DB_NAME(r.database_id) AS [Database],
            s.login_name AS [Login],
            s.host_name AS [Host],
            s.program_name AS [Programa],
            -- Classificação do wait com emoji
            CASE 
                WHEN r.wait_type LIKE 'LCK_%' THEN '🔒 Lock/Bloqueio'
                WHEN r.wait_type LIKE 'PAGEIOLATCH_%' THEN '💾 I/O Disco'
                WHEN r.wait_type LIKE 'RESOURCE_SEMAPHORE%' THEN '🧠 Memória'
                WHEN r.wait_type LIKE 'CXPACKET%' OR r.wait_type LIKE 'CXCONSUMER%' THEN '⚡ Paralelismo'
                WHEN r.wait_type LIKE 'ASYNC_NETWORK_IO' THEN '🌐 Rede/Cliente'
                WHEN r.wait_type LIKE 'WRITELOG' THEN '📝 Log de Transação'
                WHEN r.wait_type LIKE 'SOS_SCHEDULER_YIELD' THEN '⚙️ CPU/Scheduler'
                ELSE '❓ Outros'
            END AS [Categoria Wait],
            -- Severidade baseada no tempo
            CASE 
                WHEN r.wait_time > 30000 THEN '🔴 CRÍTICO'
                WHEN r.wait_time > 10000 THEN '🟡 ALTO'
                WHEN r.wait_time > 5000 THEN '🟠 MÉDIO'
                ELSE '🟢 BAIXO'
            END AS [Severidade],
            -- Query atual (limitada)
            LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 200) AS [Query Atual],
            -- Diagnóstico automático da causa
            CASE 
                WHEN r.wait_type = 'PAGEIOLATCH_SH' AND r.wait_time > 1000
                THEN '🎯 CAUSA: Leitura lenta de dados - Verificar I/O do disco e índices'
                WHEN r.wait_type = 'PAGEIOLATCH_EX' AND r.wait_time > 1000
                THEN '🎯 CAUSA: Escrita lenta ou contenção - Verificar I/O e transações'
                WHEN r.wait_type LIKE 'LCK_%' AND r.blocking_session_id IS NOT NULL
                THEN '🎯 CAUSA: Bloqueio - Session ' + CAST(r.blocking_session_id AS VARCHAR(10)) + ' está bloqueando'
                WHEN r.wait_type = 'CXPACKET' AND r.wait_time > 500
                THEN '🎯 CAUSA: Paralelismo ineficiente - Revisar MAXDOP e query'
                WHEN r.wait_type = 'WRITELOG' AND r.wait_time > 100
                THEN '🎯 CAUSA: Log lento - Verificar I/O do arquivo de log'
                WHEN r.wait_type = 'PAGELATCH_EX' AND r.wait_time > 100
                THEN '🎯 CAUSA: Contenção de página - Possível hotspot'
                WHEN r.wait_type = 'RESOURCE_SEMAPHORE' 
                THEN '🎯 CAUSA: Falta de memória - Query aguardando grant de memória'
                ELSE '📋 Analisar contexto específico'
            END AS [Causa Identificada],
            -- Recomendação imediata
            CASE 
                WHEN r.wait_type = 'PAGEIOLATCH_SH' AND r.wait_time > 1000
                THEN '🔧 AÇÃO: 1)Verificar fragmentação 2)Analisar missing indexes 3)Verificar I/O'
                WHEN r.wait_type = 'PAGEIOLATCH_EX' AND r.wait_time > 1000
                THEN '🔧 AÇÃO: 1)Verificar I/O 2)Reduzir transações longas 3)Otimizar INSERTs/UPDATEs'
                WHEN r.wait_type LIKE 'LCK_%' AND r.blocking_session_id IS NOT NULL
                THEN '🔧 AÇÃO: 1)Analisar query bloqueante 2)Reduzir tempo de transação 3)Revisar isolamento'
                WHEN r.wait_type = 'CXPACKET' AND r.wait_time > 500
                THEN '🔧 AÇÃO: 1)Ajustar MAXDOP 2)Otimizar query 3)Verificar estatísticas'
                WHEN r.wait_type = 'WRITELOG' AND r.wait_time > 100
                THEN '🔧 AÇÃO: 1)Verificar I/O do log 2)Considerar múltiplos arquivos 3)Otimizar commits'
                WHEN r.wait_type = 'RESOURCE_SEMAPHORE' 
                THEN '🔧 AÇÃO: 1)Aumentar memória 2)Otimizar query 3)Verificar Resource Governor'
                ELSE '📋 Investigar caso específico'
            END AS [Ação Recomendada]
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
        
        -- Análise específica de PAGEIOLATCH com detalhes
        IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE wait_type LIKE 'PAGEIOLATCH_%' AND wait_time > 100)
        BEGIN
            PRINT '';
            PRINT '💾 ANÁLISE ESPECÍFICA DE PAGEIOLATCH...';
            PRINT '═══════════════════════════════════════════════════════════════';
            
            SELECT 
                '🔍 PAGEIOLATCH DETALHADO' AS [Tipo Análise],
                r.session_id AS [Session ID],
                r.wait_type AS [Tipo Wait],
                r.wait_time AS [Tempo Wait (ms)],
                r.wait_resource AS [Recurso],
                -- Decodificação do recurso
                CASE 
                    WHEN r.wait_resource LIKE '%:%:%' 
                    THEN 'DB: ' + PARSENAME(r.wait_resource, 3) + ' | File: ' + PARSENAME(r.wait_resource, 2) + ' | Page: ' + PARSENAME(r.wait_resource, 1)
                    ELSE r.wait_resource
                END AS [Recurso Decodificado],
                SUBSTRING(st.text, (r.statement_start_offset/2)+1,
                    ((CASE r.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE r.statement_end_offset
                    END - r.statement_start_offset)/2) + 1) AS [Query Específica],
                r.logical_reads AS [Logical Reads],
                r.reads AS [Physical Reads],
                r.writes AS [Writes],
                -- Análise da causa específica
                CASE 
                    WHEN r.wait_type = 'PAGEIOLATCH_SH' AND r.logical_reads > 10000
                    THEN '🎯 CAUSA ESPECÍFICA: Query com muitas leituras lógicas - Índices inadequados'
                    WHEN r.wait_type = 'PAGEIOLATCH_SH' AND r.reads > 1000
                    THEN '🎯 CAUSA ESPECÍFICA: Muitas leituras físicas - Dados não estão em cache'
                    WHEN r.wait_type = 'PAGEIOLATCH_EX' AND r.writes > 100
                    THEN '🎯 CAUSA ESPECÍFICA: Muitas escritas - Transação longa ou I/O lento'
                    WHEN r.wait_type = 'PAGEIOLATCH_EX' AND r.wait_time > 1000
                    THEN '🎯 CAUSA ESPECÍFICA: I/O de escrita muito lento - Verificar disco'
                    ELSE '📋 Analisar padrão de acesso'
                END AS [Causa Específica],
                -- Prioridade de correção
                CASE 
                    WHEN r.wait_time > 5000 THEN '🔴 CRÍTICA'
                    WHEN r.wait_time > 1000 THEN '🟡 ALTA'
                    WHEN r.wait_time > 500 THEN '🟠 MÉDIA'
                    ELSE '🟢 BAIXA'
                END AS [Prioridade]
            FROM sys.dm_exec_requests r
            CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
            WHERE r.wait_type LIKE 'PAGEIOLATCH_%'
                AND r.wait_time > 100
                AND r.session_id > 50
            ORDER BY r.wait_time DESC;
        END
        
        PRINT '';
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🏆 SEÇÃO 3: TOP QUERIES COM MAIORES WAITS HISTÓRICOS
    -- ═══════════════════════════════════════════════════════════════
    
    IF @TipoAnalise = 'COMPLETA'
    BEGIN
        PRINT '🏆 TOP QUERIES COM MAIORES WAITS HISTÓRICOS...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- Análise histórica avançada
        SELECT TOP (@TopQueries)
            '📈 HISTÓRICO' AS [Tipo],
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
            qs.min_elapsed_time / 1000 AS [Tempo Mín (ms)],
            qs.max_elapsed_time / 1000 AS [Tempo Máx (ms)],
            DB_NAME(st.dbid) AS [Database],
            -- Percentual de wait em relação ao tempo total
            CAST(((qs.total_elapsed_time - qs.total_worker_time) * 100.0 / NULLIF(qs.total_elapsed_time, 0)) AS DECIMAL(5,2)) AS [% Wait],
            -- Classificação de performance
            CASE 
                WHEN (qs.total_elapsed_time - qs.total_worker_time) / qs.execution_count / 1000 > 1000 THEN '🔴 CRÍTICO'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) / qs.execution_count / 1000 > 500 THEN '🟡 ALTO'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) / qs.execution_count / 1000 > 100 THEN '🟠 MÉDIO'
                ELSE '🟢 BOM'
            END AS [Performance],
            -- Tipo de problema predominante
            CASE 
                WHEN qs.total_logical_reads / qs.execution_count > 100000 THEN '📚 I/O Excessivo'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) * 100.0 / qs.total_elapsed_time > 50 THEN '⏱️ Wait Alto'
                WHEN qs.total_worker_time / qs.execution_count / 1000 > 1000 THEN '⚙️ CPU Alto'
                ELSE '✅ Normal'
            END AS [Tipo Problema],
            -- Diagnóstico automático baseado em padrões
            CASE 
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2 AND qs.total_logical_reads / qs.execution_count > 100000
                THEN '🔴 CRÍTICO: Alto wait + Muitas leituras - Provável PAGEIOLATCH_SH'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time AND qs.total_logical_writes / qs.execution_count > 1000
                THEN '🟡 ATENÇÃO: Wait alto + Muitas escritas - Provável PAGEIOLATCH_EX'
                WHEN qs.total_logical_reads / qs.execution_count > 500000
                THEN '🟠 MODERADO: Leituras excessivas - Índices inadequados'
                WHEN qs.total_physical_reads / qs.execution_count > 10000
                THEN '🟡 ATENÇÃO: Muitas leituras físicas - Dados não em cache'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 3
                THEN '🔴 CRÍTICO: Wait time muito alto - Bloqueios ou I/O lento'
                WHEN qs.total_worker_time / qs.execution_count > 1000000 -- > 1 segundo CPU
                THEN '🟠 MODERADO: CPU alto - Query ineficiente'
                ELSE '🟢 NORMAL: Performance adequada'
            END AS [Diagnóstico Automático],
            -- Causa mais provável
            CASE 
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2 AND qs.total_logical_reads / qs.execution_count > 100000
                THEN '🎯 CAUSA: I/O lento + Índices inadequados + Possível fragmentação'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time AND qs.total_logical_writes / qs.execution_count > 1000
                THEN '🎯 CAUSA: I/O de escrita lento + Transações longas'
                WHEN qs.total_logical_reads / qs.execution_count > 500000
                THEN '🎯 CAUSA: Falta de índices adequados + Scans desnecessários'
                WHEN qs.total_physical_reads / qs.execution_count > 10000
                THEN '🎯 CAUSA: Buffer pool insuficiente + Dados não em cache'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 3
                THEN '🎯 CAUSA: Bloqueios frequentes ou I/O extremamente lento'
                WHEN qs.total_worker_time / qs.execution_count > 1000000
                THEN '🎯 CAUSA: Algoritmo ineficiente + Estatísticas desatualizadas'
                ELSE '✅ Performance dentro do esperado'
            END AS [Causa Mais Provável],
            -- Ação recomendada específica
            CASE 
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2 AND qs.total_logical_reads / qs.execution_count > 100000
                THEN '🔧 AÇÃO: 1)Criar índices missing 2)Rebuild fragmentados 3)Verificar I/O disco'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time AND qs.total_logical_writes / qs.execution_count > 1000
                THEN '🔧 AÇÃO: 1)Otimizar transações 2)Verificar I/O log 3)Batch menores'
                WHEN qs.total_logical_reads / qs.execution_count > 500000
                THEN '🔧 AÇÃO: 1)Analisar plano execução 2)Criar índices 3)Reescrever query'
                WHEN qs.total_physical_reads / qs.execution_count > 10000
                THEN '🔧 AÇÃO: 1)Aumentar buffer pool 2)Otimizar cache 3)Verificar memória'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 3
                THEN '🔧 AÇÃO: 1)Identificar bloqueios 2)Reduzir tempo transação 3)Verificar I/O'
                WHEN qs.total_worker_time / qs.execution_count > 1000000
                THEN '🔧 AÇÃO: 1)Otimizar algoritmo 2)Atualizar estatísticas 3)Revisar joins'
                ELSE '✅ Monitorar tendências'
            END AS [Ação Recomendada],
            -- Prioridade de correção
            CASE 
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2 AND qs.total_logical_reads / qs.execution_count > 100000
                THEN '🔴 CRÍTICA'
                WHEN qs.total_logical_reads / qs.execution_count > 500000 OR (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2
                THEN '🟡 ALTA'
                WHEN qs.total_physical_reads / qs.execution_count > 10000 OR qs.total_worker_time / qs.execution_count > 1000000
                THEN '🟠 MÉDIA'
                ELSE '🟢 BAIXA'
            END AS [Prioridade],
            -- Query text (limitada)
            LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 300) AS [Query Text],
            -- Recomendação específica
            CASE 
                WHEN qs.total_logical_reads / qs.execution_count > 100000 THEN 'Criar/otimizar índices'
                WHEN (qs.total_elapsed_time - qs.total_worker_time) * 100.0 / qs.total_elapsed_time > 50 THEN 'Investigar waits específicos'
                WHEN qs.total_worker_time / qs.execution_count / 1000 > 1000 THEN 'Otimizar lógica da query'
                ELSE 'Monitorar tendências'
            END AS [Recomendação]
        FROM sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        WHERE qs.total_elapsed_time > qs.total_worker_time -- Apenas queries com waits
            AND qs.execution_count > 1 -- Queries executadas mais de uma vez
        ORDER BY 
            CASE 
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2 AND qs.total_logical_reads / qs.execution_count > 100000 THEN 1
                WHEN qs.total_logical_reads / qs.execution_count > 500000 THEN 2
                WHEN (qs.total_elapsed_time - qs.total_worker_time) > qs.total_worker_time * 2 THEN 3
                ELSE 4
            END,
            (qs.total_elapsed_time - qs.total_worker_time) DESC;
        
        PRINT '';
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📈 SEÇÃO 4: ESTATÍSTICAS GERAIS DE WAITS DO SERVIDOR
    -- ═══════════════════════════════════════════════════════════════
    
    IF @TipoAnalise = 'COMPLETA'
    BEGIN
        PRINT '📈 ESTATÍSTICAS GERAIS DE WAITS DO SERVIDOR...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- Estatísticas gerais com análise avançada
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
            '📊 ESTATÍSTICA' AS [Tipo],
            ws.wait_type AS [Tipo de Wait],
            ws.waiting_tasks_count AS [Contagem Tasks],
            ws.wait_time_ms AS [Tempo Wait (ms)],
            ws.wait_time_ms / 1000.0 AS [Tempo Wait (seg)],
            ws.wait_time_ms / 60000.0 AS [Tempo Wait (min)],
            CAST((ws.wait_time_ms * 100.0 / tw.total_wait_time) AS DECIMAL(5,2)) AS [% do Total],
            ws.wait_time_ms / NULLIF(ws.waiting_tasks_count, 0) AS [Média por Task (ms)],
            ws.signal_wait_time_ms AS [Signal Wait (ms)],
            ws.resource_wait_time_ms AS [Resource Wait (ms)],
            -- Classificação visual com emoji
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
            -- Severidade baseada no percentual
            CASE 
                WHEN (ws.wait_time_ms * 100.0 / tw.total_wait_time) > 20 THEN '🔴 CRÍTICO'
                WHEN (ws.wait_time_ms * 100.0 / tw.total_wait_time) > 10 THEN '🟡 ALTO'
                WHEN (ws.wait_time_ms * 100.0 / tw.total_wait_time) > 5 THEN '🟠 MÉDIO'
                ELSE '🟢 BAIXO'
            END AS [Severidade],
            -- Recomendação específica e detalhada
            CASE 
                WHEN ws.wait_type LIKE 'LCK_%' THEN 'Verificar bloqueios, otimizar transações, revisar isolamento'
                WHEN ws.wait_type LIKE 'PAGEIOLATCH_%' THEN 'Verificar I/O do disco, considerar SSD, otimizar índices'
                WHEN ws.wait_type LIKE 'RESOURCE_SEMAPHORE%' THEN 'Aumentar memória ou otimizar queries com alto consumo'
                WHEN ws.wait_type LIKE 'CXPACKET%' THEN 'Ajustar MAXDOP ou Cost Threshold for Parallelism'
                WHEN ws.wait_type LIKE 'ASYNC_NETWORK_IO' THEN 'Verificar aplicação cliente, otimizar resultados'
                WHEN ws.wait_type LIKE 'WRITELOG' THEN 'Otimizar log, verificar disco do log, revisar transações'
                WHEN ws.wait_type LIKE 'SOS_SCHEDULER_YIELD' THEN 'Verificar CPU, otimizar queries, revisar índices'
                WHEN ws.wait_type LIKE 'THREADPOOL' THEN 'Verificar conexões, aumentar max worker threads'
                ELSE 'Analisar caso específico com especialista'
            END AS [Recomendação Detalhada]
        FROM WaitStats ws
        CROSS JOIN TotalWaits tw
        ORDER BY ws.wait_time_ms DESC;
        
        PRINT '';
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 💡 SEÇÃO 5: RECOMENDAÇÕES PRIORIZADAS E SCRIPTS
    -- ═══════════════════════════════════════════════════════════════
    
    IF @MostrarRecomendacoes = 1
    BEGIN
        PRINT '💡 RECOMENDAÇÕES PRIORIZADAS PARA OTIMIZAÇÃO...';
        PRINT '═══════════════════════════════════════════════════════════════';
        
        -- Exibir recomendações coletadas
        IF EXISTS (SELECT 1 FROM @RecomendacoesCriticas)
        BEGIN
            SELECT 
                '🎯 RECOMENDAÇÃO' AS [Tipo],
                Prioridade AS [Prioridade],
                Categoria AS [Categoria],
                Problema AS [Problema Identificado],
                Solucao AS [Solução Recomendada],
                ImpactoEstimado AS [Impacto Estimado],
                CASE Prioridade
                    WHEN 'CRÍTICA' THEN '🔴 Implementar IMEDIATAMENTE'
                    WHEN 'ALTA' THEN '🟡 Implementar em 24h'
                    WHEN 'MÉDIA' THEN '🟠 Implementar esta semana'
                    ELSE '🟢 Implementar quando possível'
                END AS [Prazo Sugerido]
            FROM @RecomendacoesCriticas
            ORDER BY 
                CASE Prioridade
                    WHEN 'CRÍTICA' THEN 1
                    WHEN 'ALTA' THEN 2
                    WHEN 'MÉDIA' THEN 3
                    ELSE 4
                END;
        END
        ELSE
        BEGIN
            PRINT '✅ Nenhuma recomendação crítica identificada.';
            PRINT 'Sistema operando dentro dos parâmetros normais.';
        END
        
        PRINT '';
        
        -- Scripts de correção se solicitado
        IF @MostrarScripts = 1 AND EXISTS (SELECT 1 FROM @RecomendacoesCriticas)
        BEGIN
            PRINT '🔧 SCRIPTS DE CORREÇÃO SUGERIDOS...';
            PRINT '═══════════════════════════════════════════════════════════════';
            
            SELECT 
                '📜 SCRIPT' AS [Tipo],
                Categoria AS [Categoria],
                Problema AS [Para Corrigir],
                Script AS [Script Sugerido]
            FROM @RecomendacoesCriticas
            WHERE Script IS NOT NULL
            ORDER BY 
                CASE Prioridade
                    WHEN 'CRÍTICA' THEN 1
                    WHEN 'ALTA' THEN 2
                    WHEN 'MÉDIA' THEN 3
                    ELSE 4
                END;
            
            PRINT '';
        END
        
        -- ═══════════════════════════════════════════════════════════════
        -- 🛠️ SCRIPTS DE DIAGNÓSTICO AUTOMÁTICO AVANÇADO
        -- ═══════════════════════════════════════════════════════════════
        IF @MostrarScripts = 1
        BEGIN
            PRINT '🛠️ SCRIPTS DE DIAGNÓSTICO AUTOMÁTICO AVANÇADO...';
            PRINT '═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            -- 1. Script para verificar fragmentação de índices
            PRINT '-- 📊 SCRIPT 1: VERIFICAR FRAGMENTAÇÃO DE ÍNDICES';
            PRINT '-- Execute este script para identificar índices fragmentados:';
            PRINT '';
            PRINT 'SELECT ';
            PRINT '    OBJECT_SCHEMA_NAME(ips.object_id) AS [Schema],';
            PRINT '    OBJECT_NAME(ips.object_id) AS [Table],';
            PRINT '    i.name AS [Index],';
            PRINT '    ips.avg_fragmentation_in_percent AS [Fragmentação %],';
            PRINT '    ips.page_count AS [Páginas],';
            PRINT '    CASE ';
            PRINT '        WHEN ips.avg_fragmentation_in_percent > 30 THEN ''🔴 REBUILD NECESSÁRIO''';
            PRINT '        WHEN ips.avg_fragmentation_in_percent > 10 THEN ''🟡 REORGANIZE RECOMENDADO''';
            PRINT '        ELSE ''🟢 OK''';
            PRINT '    END AS [Ação],';
            PRINT '    CASE ';
            PRINT '        WHEN ips.avg_fragmentation_in_percent > 30 ';
            PRINT '        THEN ''ALTER INDEX ['' + i.name + ''] ON ['' + OBJECT_SCHEMA_NAME(ips.object_id) + ''].['' + OBJECT_NAME(ips.object_id) + ''] REBUILD;''';
            PRINT '        WHEN ips.avg_fragmentation_in_percent > 10 ';
            PRINT '        THEN ''ALTER INDEX ['' + i.name + ''] ON ['' + OBJECT_SCHEMA_NAME(ips.object_id) + ''].['' + OBJECT_NAME(ips.object_id) + ''] REORGANIZE;''';
            PRINT '        ELSE ''-- Índice OK''';
            PRINT '    END AS [Script Correção]';
            PRINT 'FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''LIMITED'') ips';
            PRINT 'INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id';
            PRINT 'WHERE ips.avg_fragmentation_in_percent > 5';
            PRINT '    AND ips.page_count > 100';
            PRINT '    AND i.index_id > 0';
            PRINT 'ORDER BY ips.avg_fragmentation_in_percent DESC;';
            PRINT '';
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            -- 2. Script para missing indexes
            PRINT '-- 📈 SCRIPT 2: MISSING INDEXES (ÍNDICES RECOMENDADOS)';
            PRINT '-- Execute este script para identificar índices que podem melhorar a performance:';
            PRINT '';
            PRINT 'SELECT ';
            PRINT '    ROUND(migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans), 0) AS [Impacto],';
            PRINT '    migs.user_seeks AS [Seeks],';
            PRINT '    migs.user_scans AS [Scans],';
            PRINT '    OBJECT_SCHEMA_NAME(mid.object_id) AS [Schema],';
            PRINT '    OBJECT_NAME(mid.object_id) AS [Table],';
            PRINT '    ''CREATE INDEX IX_'' + OBJECT_NAME(mid.object_id) + ''_'' + ';
            PRINT '        REPLACE(REPLACE(ISNULL(mid.equality_columns, '''') + ISNULL(mid.inequality_columns, ''''), ''['', ''''), '']'', '''') AS [Nome Sugerido],';
            PRINT '    ''CREATE INDEX IX_'' + OBJECT_NAME(mid.object_id) + ''_'' + ';
            PRINT '        REPLACE(REPLACE(ISNULL(mid.equality_columns, '''') + ISNULL(mid.inequality_columns, ''''), ''['', ''''), '']'', '''') + ';
            PRINT '        '' ON ['' + OBJECT_SCHEMA_NAME(mid.object_id) + ''].['' + OBJECT_NAME(mid.object_id) + ''] ('' + ';
            PRINT '        ISNULL(mid.equality_columns, '''') + ';
            PRINT '        CASE WHEN mid.inequality_columns IS NOT NULL THEN '', '' + mid.inequality_columns ELSE '''' END + '')'' + ';
            PRINT '        CASE WHEN mid.included_columns IS NOT NULL THEN '' INCLUDE ('' + mid.included_columns + '')'' ELSE '''' END + '';'' AS [Script CREATE INDEX]';
            PRINT 'FROM sys.dm_db_missing_index_groups mig';
            PRINT 'INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle';
            PRINT 'INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle';
            PRINT 'WHERE mid.database_id = DB_ID()';
            PRINT '    AND migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) > 100';
            PRINT 'ORDER BY [Impacto] DESC;';
            PRINT '';
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            -- 3. Script para análise detalhada de I/O
            PRINT '-- 💾 SCRIPT 3: ANÁLISE DETALHADA DE I/O POR ARQUIVO';
            PRINT '-- Execute este script para análise completa de I/O:';
            PRINT '';
            PRINT 'SELECT ';
            PRINT '    DB_NAME(vfs.database_id) AS [Database],';
            PRINT '    mf.name AS [Logical Name],';
            PRINT '    mf.physical_name AS [Physical Path],';
            PRINT '    mf.type_desc AS [File Type],';
            PRINT '    CAST((vfs.io_stall_read_ms * 1.0 / NULLIF(vfs.num_of_reads, 0)) AS DECIMAL(10,2)) AS [Avg Read Latency (ms)],';
            PRINT '    CAST((vfs.io_stall_write_ms * 1.0 / NULLIF(vfs.num_of_writes, 0)) AS DECIMAL(10,2)) AS [Avg Write Latency (ms)],';
            PRINT '    vfs.num_of_reads AS [Total Reads],';
            PRINT '    vfs.num_of_writes AS [Total Writes],';
            PRINT '    CAST(vfs.num_of_bytes_read / 1024.0 / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS [GB Read],';
            PRINT '    CAST(vfs.num_of_bytes_written / 1024.0 / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS [GB Written],';
            PRINT '    CASE ';
            PRINT '        WHEN (vfs.io_stall_read_ms * 1.0 / NULLIF(vfs.num_of_reads, 0)) > 50 THEN ''🔴 CRÍTICO''';
            PRINT '        WHEN (vfs.io_stall_read_ms * 1.0 / NULLIF(vfs.num_of_reads, 0)) > 20 THEN ''🟡 ATENÇÃO''';
            PRINT '        ELSE ''🟢 OK''';
            PRINT '    END AS [Status Read],';
            PRINT '    CASE ';
            PRINT '        WHEN (vfs.io_stall_write_ms * 1.0 / NULLIF(vfs.num_of_writes, 0)) > 20 THEN ''🔴 CRÍTICO''';
            PRINT '        WHEN (vfs.io_stall_write_ms * 1.0 / NULLIF(vfs.num_of_writes, 0)) > 10 THEN ''🟡 ATENÇÃO''';
            PRINT '        ELSE ''🟢 OK''';
            PRINT '    END AS [Status Write]';
            PRINT 'FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs';
            PRINT 'INNER JOIN sys.database_files mf ON vfs.file_id = mf.file_id';
            PRINT 'WHERE vfs.database_id = DB_ID()';
            PRINT 'ORDER BY [Avg Read Latency (ms)] DESC;';
            PRINT '';
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            -- 4. Script para queries com alto I/O
            PRINT '-- 🔍 SCRIPT 4: QUERIES COM ALTO I/O (PRINCIPAIS CAUSADORAS)';
            PRINT '-- Execute este script para identificar as queries que mais consomem I/O:';
            PRINT '';
            PRINT 'SELECT TOP 20';
            PRINT '    qs.execution_count AS [Executions],';
            PRINT '    CAST(qs.total_logical_reads / qs.execution_count AS BIGINT) AS [Avg Logical Reads],';
            PRINT '    CAST(qs.total_physical_reads / qs.execution_count AS BIGINT) AS [Avg Physical Reads],';
            PRINT '    CAST(qs.total_logical_writes / qs.execution_count AS BIGINT) AS [Avg Writes],';
            PRINT '    CAST((qs.total_elapsed_time - qs.total_worker_time) / qs.execution_count / 1000.0 AS DECIMAL(10,2)) AS [Avg Wait Time (s)],';
            PRINT '    CAST(qs.total_worker_time / qs.execution_count / 1000.0 AS DECIMAL(10,2)) AS [Avg CPU Time (s)],';
            PRINT '    CASE ';
            PRINT '        WHEN qs.total_logical_reads / qs.execution_count > 100000 THEN ''🔴 ALTO I/O''';
            PRINT '        WHEN qs.total_logical_reads / qs.execution_count > 50000 THEN ''🟡 MÉDIO I/O''';
            PRINT '        ELSE ''🟢 BAIXO I/O''';
            PRINT '    END AS [I/O Level],';
            PRINT '    LEFT(REPLACE(REPLACE(st.text, CHAR(13), '' ''), CHAR(10), '' ''), 200) AS [Query Text]';
            PRINT 'FROM sys.dm_exec_query_stats qs';
            PRINT 'CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st';
            PRINT 'WHERE qs.total_logical_reads > 0';
            PRINT 'ORDER BY qs.total_logical_reads / qs.execution_count DESC;';
            PRINT '';
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            -- 5. Script para análise de bloqueios
            PRINT '-- 🚫 SCRIPT 5: ANÁLISE DE BLOQUEIOS ATIVOS';
            PRINT '-- Execute este script para identificar bloqueios em tempo real:';
            PRINT '';
            PRINT 'SELECT ';
            PRINT '    r.session_id AS [Blocked Session],';
            PRINT '    r.blocking_session_id AS [Blocking Session],';
            PRINT '    r.wait_type AS [Wait Type],';
            PRINT '    r.wait_time AS [Wait Time (ms)],';
            PRINT '    r.wait_resource AS [Resource],';
            PRINT '    s1.login_name AS [Blocked User],';
            PRINT '    s2.login_name AS [Blocking User],';
            PRINT '    st1.text AS [Blocked Query],';
            PRINT '    st2.text AS [Blocking Query],';
            PRINT '    CASE ';
            PRINT '        WHEN r.wait_time > 30000 THEN ''🔴 CRÍTICO - Considerar KILL '' + CAST(r.blocking_session_id AS VARCHAR(10))';
            PRINT '        WHEN r.wait_time > 10000 THEN ''🟡 ATENÇÃO - Monitorar de perto''';
            PRINT '        ELSE ''🟢 NORMAL''';
            PRINT '    END AS [Ação Recomendada]';
            PRINT 'FROM sys.dm_exec_requests r';
            PRINT 'INNER JOIN sys.dm_exec_sessions s1 ON r.session_id = s1.session_id';
            PRINT 'INNER JOIN sys.dm_exec_sessions s2 ON r.blocking_session_id = s2.session_id';
            PRINT 'OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) st1';
            PRINT 'OUTER APPLY sys.dm_exec_sql_text(s2.most_recent_sql_handle) st2';
            PRINT 'WHERE r.blocking_session_id <> 0';
            PRINT 'ORDER BY r.wait_time DESC;';
            PRINT '';
            PRINT '-- ═══════════════════════════════════════════════════════════════';
            PRINT '';
            
            PRINT '✅ Scripts de diagnóstico prontos para execução!';
            PRINT 'ℹ️  Copie e execute os scripts conforme necessário para análise detalhada.';
            PRINT '';
        END
    END
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 SEÇÃO 6: RELATÓRIO EXECUTIVO E RESUMO
    -- ═══════════════════════════════════════════════════════════════
    
    PRINT '📋 RELATÓRIO EXECUTIVO - RESUMO DA ANÁLISE';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    -- Métricas gerais do sistema
    DECLARE @TotalWaitTime BIGINT;
    DECLARE @TopWaitType VARCHAR(100);
    DECLARE @TopWaitPercent DECIMAL(5,2);
    
    SELECT TOP 1
        @TotalWaitTime = SUM(wait_time_ms),
        @TopWaitType = wait_type,
        @TopWaitPercent = (wait_time_ms * 100.0 / SUM(wait_time_ms) OVER())
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT LIKE 'SLEEP_%'
        AND wait_type NOT LIKE 'BROKER_%'
        AND wait_type NOT LIKE 'XE_%'
    GROUP BY wait_type, wait_time_ms
    ORDER BY wait_time_ms DESC;
    
    -- Relatório executivo
    SELECT 
        '📊 RESUMO EXECUTIVO' AS [Tipo Relatório],
        @StatusGeral AS [Status Geral],
        CAST(@PerformanceScore AS VARCHAR(10)) + '%' AS [Score Performance],
        @AlertCount AS [Alertas Críticos],
        @TopWaitType AS [Principal Wait Type],
        CAST(@TopWaitPercent AS VARCHAR(10)) + '%' AS [% do Wait Principal],
        CAST(@TotalWaitTime / 1000.0 / 60.0 AS DECIMAL(10,2)) AS [Total Waits (min)],
        DATEDIFF(SECOND, @InicioExecucao, GETDATE()) AS [Tempo Análise (seg)],
        CASE 
            WHEN @AlertCount = 0 THEN '✅ Sistema estável'
            WHEN @AlertCount <= 2 THEN '⚠️ Atenção necessária'
            ELSE '🚨 Intervenção urgente'
        END AS [Ação Recomendada];
    
    -- Próximos passos
    PRINT '';
    PRINT '🎯 PRÓXIMOS PASSOS RECOMENDADOS:';
    PRINT '1. Implementar correções críticas identificadas';
    PRINT '2. Monitorar métricas de performance continuamente';
    PRINT '3. Executar esta análise regularmente (diário/semanal)';
    PRINT '4. Documentar mudanças e resultados obtidos';
    PRINT '5. Considerar implementação de alertas automáticos';
    
    PRINT '';
    PRINT '═══════════════════════════════════════════════════════════════';
    PRINT '✅ ANÁLISE COMPLETA FINALIZADA EM: ' + CAST(DATEDIFF(SECOND, @InicioExecucao, GETDATE()) AS VARCHAR(10)) + ' segundos';
    PRINT '📧 Para suporte especializado, documente os resultados desta análise';
    PRINT '═══════════════════════════════════════════════════════════════';
    
    -- Debug information se solicitado
    IF @Debug = 1
    BEGIN
        PRINT '';
        PRINT '🔍 INFORMAÇÕES DE DEBUG:';
        PRINT 'Parâmetros utilizados:';
        PRINT '- Tipo Análise: ' + @TipoAnalise;
        PRINT '- Top Queries: ' + CAST(@TopQueries AS VARCHAR(10));
        PRINT '- Mostrar Recomendações: ' + CASE WHEN @MostrarRecomendacoes = 1 THEN 'Sim' ELSE 'Não' END;
        PRINT '- Mostrar Scripts: ' + CASE WHEN @MostrarScripts = 1 THEN 'Sim' ELSE 'Não' END;
        PRINT '- Alertas Apenas: ' + CASE WHEN @AlertasApenas = 1 THEN 'Sim' ELSE 'Não' END;
    END
    
END
GO

-- ═══════════════════════════════════════════════════════════════
-- 📚 EXEMPLOS DE USO DA PROCEDURE
-- ═══════════════════════════════════════════════════════════════

/*
-- ANÁLISE COMPLETA (recomendado para análise detalhada)
EXEC uspAnaliseWaitsCompleta 
    @TipoAnalise = 'COMPLETA',
    @MostrarRecomendacoes = 1,
    @MostrarScripts = 1,
    @TopQueries = 20;

-- ANÁLISE RÁPIDA (para verificação diária)
EXEC uspAnaliseWaitsCompleta 
    @TipoAnalise = 'RAPIDA',
    @MostrarRecomendacoes = 1,
    @TopQueries = 10;

-- APENAS ALERTAS CRÍTICOS (para monitoramento automático)
EXEC uspAnaliseWaitsCompleta 
    @TipoAnalise = 'CRITICA',
    @AlertasApenas = 1;

-- ANÁLISE COM DEBUG (para troubleshooting)
EXEC uspAnaliseWaitsCompleta 
    @TipoAnalise = 'COMPLETA',
    @MostrarRecomendacoes = 1,
    @MostrarScripts = 1,
    @Debug = 1;
*/

-- ═══════════════════════════════════════════════════════════════
-- 📖 GUIA DE INTERPRETAÇÃO E AÇÕES
-- ═══════════════════════════════════════════════════════════════

/*
🎯 GUIA DE AÇÕES POR TIPO DE WAIT:

🔒 LCK_* (Locks/Bloqueios):
   ✅ Ações Imediatas:
   - Identificar transações longas: SELECT * FROM sys.dm_tran_active_transactions
   - Verificar bloqueios: sp_who2 ou sys.dm_exec_requests
   - Matar sessões problemáticas se necessário: KILL [session_id]
   
   🔧 Otimizações:
   - Criar índices em colunas de JOIN e WHERE
   - Reduzir tempo de transação
   - Usar READ_COMMITTED_SNAPSHOT
   - Revisar lógica de negócio

💾 PAGEIOLATCH_* (I/O de Disco):
   ✅ Ações Imediatas:
   - Verificar performance do disco: sys.dm_io_virtual_file_stats
   - Identificar arquivos com maior I/O
   - Verificar fragmentação de índices
   
   🔧 Otimizações:
   - Migrar para SSD
   - Separar dados e log em discos diferentes
   - Otimizar índices e queries
   - Aumentar memória para reduzir I/O

🧠 RESOURCE_SEMAPHORE (Memória):
   ✅ Ações Imediatas:
   - Identificar queries com alto consumo de memória
   - Verificar configuração de memória: sp_configure 'max server memory'
   - Monitorar: sys.dm_exec_query_memory_grants
   
   🔧 Otimizações:
   - Aumentar memória do servidor
   - Otimizar queries com JOINs complexos
   - Revisar uso de funções de janela
   - Implementar paginação em queries grandes

⚡ CXPACKET/CXCONSUMER (Paralelismo):
   ✅ Ações Imediatas:
   - Verificar MAXDOP: sp_configure 'max degree of parallelism'
   - Verificar Cost Threshold: sp_configure 'cost threshold for parallelism'
   
   🔧 Otimizações:
   - Ajustar MAXDOP (recomendado: número de cores físicos)
   - Aumentar Cost Threshold (recomendado: 50-100)
   - Otimizar queries para reduzir complexidade
   - Criar índices para evitar paralelismo desnecessário

🌐 ASYNC_NETWORK_IO (Rede/Cliente):
   ✅ Ações Imediatas:
   - Verificar aplicações cliente lentas
   - Identificar queries que retornam muitos dados
   
   🔧 Otimizações:
   - Implementar paginação
   - Otimizar aplicação cliente
   - Reduzir dados retornados
   - Usar compressão de dados

📝 WRITELOG (Log de Transação):
   ✅ Ações Imediatas:
   - Verificar disco do log de transação
   - Identificar transações grandes
   
   🔧 Otimizações:
   - Mover log para SSD dedicado
   - Reduzir tamanho de transações
   - Configurar backup de log mais frequente
   - Otimizar operações em lote

⚙️ SOS_SCHEDULER_YIELD (CPU):
   ✅ Ações Imediatas:
   - Verificar utilização de CPU
   - Identificar queries com alto consumo de CPU
   
   🔧 Otimizações:
   - Otimizar queries ineficientes
   - Criar/otimizar índices
   - Considerar upgrade de CPU
   - Revisar planos de execução

📊 MÉTRICAS DE SUCESSO:
- Score de Performance > 90%
- Tempo médio de wait < 100ms
- Alertas críticos = 0
- I/O médio < 50ms
- CPU utilization < 80%
- Bloqueios < 5 segundos

🔄 MONITORAMENTO CONTÍNUO:
- Execute análise diariamente
- Configure alertas automáticos
- Documente mudanças e resultados
- Revise tendências semanalmente
- Implemente baselines de performance
*/