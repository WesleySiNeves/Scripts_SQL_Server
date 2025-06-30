/*
=============================================================================
PROCEDURE: HealthCheck.uspQueryStoreTopQueries
DESCRIÇÃO: Busca as top queries executadas usando Query Store com métricas detalhadas
           incluindo CPU, I/O, memória e análise de custo percentual
AUTOR: Wesley
DATA CRIAÇÃO: 2024
VERSÃO: 2.0 - Adicionadas métricas de memória e TempDB

PARÂMETROS:
@TopN - Número de queries a retornar (padrão: 10)
@MetricType - Tipo de métrica para ordenação:
  - 'duration' (padrão): Duração total
  - 'cpu': Tempo de CPU
  - 'logical_reads': Leituras lógicas
  - 'physical_reads': Leituras físicas
  - 'writes': Escritas
  - 'execution_count': Número de execuções
@TimeRange - Período em horas (padrão: 24 horas)
@DatabaseName - Nome do banco (opcional, se não informado usa o banco atual)
@ShowCostPercentage - Exibir percentual de custo (padrão: 1)
@CostThresholdYellow - Limite percentual para status Amarelo (padrão: 10%)
@CostThresholdRed - Limite percentual para status Vermelho (padrão: 25%)

EXEMPLO DE USO:
EXEC HealthCheck.uspQueryStoreTopQueries @TopN = 5, @MetricType = 'duration', @TimeRange = 6

EXEMPLO COM ANÁLISE DE CUSTO PERSONALIZADA:
EXEC HealthCheck.uspQueryStoreTopQueries 
    @TopN = 10, @MetricType = 'cpu', @TimeRange = 24,
    @CostThresholdYellow = 15.0, @CostThresholdRed = 30.0
=============================================================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspQueryStoreTopQueries
    @TopN INT = 10,
    @MetricType VARCHAR(20) = 'duration',
    @TimeRange INT = 24,
    @DatabaseName SYSNAME = NULL,
    @ShowCostPercentage BIT = 1,
    @CostThresholdYellow DECIMAL(5,2) = 10.0,  -- Percentual para status Amarelo
    @CostThresholdRed DECIMAL(5,2) = 25.0      -- Percentual para status Vermelho
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validação dos parâmetros
    IF @TopN <= 0 OR @TopN > 100
    BEGIN
        RAISERROR('O parâmetro @TopN deve estar entre 1 e 100', 16, 1);
        RETURN;
    END
    
    IF @MetricType NOT IN ('duration', 'cpu', 'logical_reads', 'physical_reads', 'writes', 'execution_count')
    BEGIN
        RAISERROR('Tipo de métrica inválido. Use: duration, cpu, logical_reads, physical_reads, writes, execution_count', 16, 1);
        RETURN;
    END
    
    IF @TimeRange <= 0 OR @TimeRange > 168 -- Máximo 7 dias
    BEGIN
        RAISERROR('O parâmetro @TimeRange deve estar entre 1 e 168 horas', 16, 1);
        RETURN;
    END
    
    -- Verifica se o Query Store está habilitado
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.database_query_store_options 
        WHERE actual_state = 2 -- READ_WRITE
    )
    BEGIN
        RAISERROR('Query Store não está habilitado ou não está em modo READ_WRITE neste banco de dados', 16, 1);
        RETURN;
    END
    
    DECLARE @StartTime DATETIMEOFFSET = DATEADD(HOUR, -@TimeRange, SYSDATETIMEOFFSET());
    DECLARE @CurrentDB SYSNAME = ISNULL(@DatabaseName, DB_NAME());
    
    -- Cabeçalho do relatório
    PRINT '===============================================================================';
    PRINT 'RELATÓRIO: TOP ' + CAST(@TopN AS VARCHAR(10)) + ' QUERIES - QUERY STORE';
    PRINT 'BANCO DE DADOS: ' + @CurrentDB;
    PRINT 'PERÍODO: Últimas ' + CAST(@TimeRange AS VARCHAR(10)) + ' horas';
    PRINT 'MÉTRICA: ' + UPPER(@MetricType);
    PRINT 'DATA/HORA GERAÇÃO: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
    PRINT '===============================================================================';
    PRINT '';
    
    -- Query principal para buscar as top queries
    WITH QueryStats AS (
        SELECT 
            q.query_id,
            qt.query_sql_text,
            p.plan_id,
            -- Métricas agregadas
            SUM(rs.count_executions) AS total_executions,
            SUM(rs.avg_duration * rs.count_executions) / 1000.0 AS total_duration_ms,
            SUM(rs.avg_cpu_time * rs.count_executions) / 1000.0 AS total_cpu_time_ms,
            SUM(rs.avg_logical_io_reads * rs.count_executions) AS total_logical_reads,
            SUM(rs.avg_physical_io_reads * rs.count_executions) AS total_physical_reads,
            SUM(rs.avg_logical_io_writes * rs.count_executions) AS total_writes,
            -- Métricas de memória
            SUM(rs.avg_query_max_used_memory * rs.count_executions) AS total_memory_used_kb,
            SUM(rs.avg_tempdb_space_used * rs.count_executions) AS total_tempdb_space_used_kb,
            -- Métricas médias
            AVG(rs.avg_duration) / 1000.0 AS avg_duration_ms,
            AVG(rs.avg_cpu_time) / 1000.0 AS avg_cpu_time_ms,
            AVG(rs.avg_logical_io_reads) AS avg_logical_reads,
            AVG(rs.avg_physical_io_reads) AS avg_physical_reads,
            AVG(rs.avg_logical_io_writes) AS avg_writes,
            -- Métricas médias de memória
            AVG(rs.avg_query_max_used_memory) AS avg_memory_used_kb,
            AVG(rs.avg_tempdb_space_used) AS avg_tempdb_space_used_kb,
            -- Métricas máximas de memória
            MAX(rs.max_query_max_used_memory) AS max_memory_used_kb,
            MAX(rs.max_tempdb_space_used) AS max_tempdb_space_used_kb
            -- Informações adicionais
            MIN(rsi.start_time) AS first_execution_time,
            MAX(rsi.end_time) AS last_execution_time,
            COUNT(DISTINCT p.plan_id) AS plan_count
        FROM sys.query_store_query q
        INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
        INNER JOIN sys.query_store_plan p ON q.query_id = p.query_id
        INNER JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
        INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
        WHERE rsi.start_time >= @StartTime
            AND q.is_internal_query = 0 -- Exclui queries internas do sistema
        GROUP BY q.query_id, qt.query_sql_text, p.plan_id
    ),
    -- CTE para calcular totais gerais para percentual de custo
    TotalStats AS (
        SELECT 
            SUM(total_duration_ms) AS total_all_duration_ms,
            SUM(total_cpu_time_ms) AS total_all_cpu_time_ms,
            SUM(total_logical_reads) AS total_all_logical_reads,
            SUM(total_physical_reads) AS total_all_physical_reads,
            SUM(total_writes) AS total_all_writes,
            SUM(total_executions) AS total_all_executions,
            -- Totais de memória
            SUM(total_memory_used_kb) AS total_all_memory_used_kb,
            SUM(total_tempdb_space_used_kb) AS total_all_tempdb_space_used_kb
        FROM QueryStats
    ),
    RankedQueries AS (
        SELECT qs.*,
            ts.total_all_duration_ms,
            ts.total_all_cpu_time_ms,
            ts.total_all_logical_reads,
            ts.total_all_physical_reads,
            ts.total_all_writes,
            ts.total_all_executions,
            -- Cálculo do percentual de custo baseado na métrica
            CASE @MetricType
                WHEN 'duration' THEN 
                    CASE WHEN ts.total_all_duration_ms > 0 
                         THEN (qs.total_duration_ms * 100.0) / ts.total_all_duration_ms 
                         ELSE 0 END
                WHEN 'cpu' THEN 
                    CASE WHEN ts.total_all_cpu_time_ms > 0 
                         THEN (qs.total_cpu_time_ms * 100.0) / ts.total_all_cpu_time_ms 
                         ELSE 0 END
                WHEN 'logical_reads' THEN 
                    CASE WHEN ts.total_all_logical_reads > 0 
                         THEN (qs.total_logical_reads * 100.0) / ts.total_all_logical_reads 
                         ELSE 0 END
                WHEN 'physical_reads' THEN 
                    CASE WHEN ts.total_all_physical_reads > 0 
                         THEN (qs.total_physical_reads * 100.0) / ts.total_all_physical_reads 
                         ELSE 0 END
                WHEN 'writes' THEN 
                    CASE WHEN ts.total_all_writes > 0 
                         THEN (qs.total_writes * 100.0) / ts.total_all_writes 
                         ELSE 0 END
                WHEN 'execution_count' THEN 
                    CASE WHEN ts.total_all_executions > 0 
                         THEN (qs.total_executions * 100.0) / ts.total_all_executions 
                         ELSE 0 END
            END AS cost_percentage,
            -- Ranking baseado na métrica escolhida
            ROW_NUMBER() OVER (
                ORDER BY 
                    CASE @MetricType
                        WHEN 'duration' THEN qs.total_duration_ms
                        WHEN 'cpu' THEN qs.total_cpu_time_ms
                        WHEN 'logical_reads' THEN qs.total_logical_reads
                        WHEN 'physical_reads' THEN qs.total_physical_reads
                        WHEN 'writes' THEN qs.total_writes
                        WHEN 'execution_count' THEN qs.total_executions
                    END DESC
            ) AS ranking
        FROM QueryStats qs
        CROSS JOIN TotalStats ts
    )
    SELECT 
        ranking AS [Rank],
        query_id AS [Query ID],
        plan_id AS [Plan ID],
        total_executions AS [Total Executions],
        CAST(total_duration_ms AS DECIMAL(18,2)) AS [Total Duration (ms)],
        CAST(avg_duration_ms AS DECIMAL(18,2)) AS [Avg Duration (ms)],
        CAST(total_cpu_time_ms AS DECIMAL(18,2)) AS [Total CPU Time (ms)],
        CAST(avg_cpu_time_ms AS DECIMAL(18,2)) AS [Avg CPU Time (ms)],
        total_logical_reads AS [Total Logical Reads],
        CAST(avg_logical_reads AS DECIMAL(18,2)) AS [Avg Logical Reads],
        total_physical_reads AS [Total Physical Reads],
        CAST(avg_physical_reads AS DECIMAL(18,2)) AS [Avg Physical Reads],
        total_writes AS [Total Writes],
        CAST(avg_writes AS DECIMAL(18,2)) AS [Avg Writes],
        -- Métricas de memória
        CAST(total_memory_used_kb AS BIGINT) AS [Total Memory Used (KB)],
        CAST(total_memory_used_kb / 1024.0 AS DECIMAL(18,2)) AS [Total Memory Used (MB)],
        CAST(avg_memory_used_kb AS DECIMAL(18,2)) AS [Avg Memory Used (KB)],
        CAST(avg_memory_used_kb / 1024.0 AS DECIMAL(18,2)) AS [Avg Memory Used (MB)],
        CAST(max_memory_used_kb AS BIGINT) AS [Max Memory Used (KB)],
        CAST(max_memory_used_kb / 1024.0 AS DECIMAL(18,2)) AS [Max Memory Used (MB)],
        CAST(total_tempdb_space_used_kb AS BIGINT) AS [Total TempDB Used (KB)],
        CAST(total_tempdb_space_used_kb / 1024.0 AS DECIMAL(18,2)) AS [Total TempDB Used (MB)],
        CAST(avg_tempdb_space_used_kb AS DECIMAL(18,2)) AS [Avg TempDB Used (KB)],
        CAST(avg_tempdb_space_used_kb / 1024.0 AS DECIMAL(18,2)) AS [Avg TempDB Used (MB)],
        CAST(max_tempdb_space_used_kb AS BIGINT) AS [Max TempDB Used (KB)],
        CAST(max_tempdb_space_used_kb / 1024.0 AS DECIMAL(18,2)) AS [Max TempDB Used (MB)],
        -- Percentual de custo (se habilitado)
        CASE WHEN @ShowCostPercentage = 1 
             THEN CAST(cost_percentage AS DECIMAL(5,2))
             ELSE NULL 
        END AS [Cost Percentage (%)],
        -- Status de interpretação baseado no percentual de custo
        CASE WHEN @ShowCostPercentage = 1 THEN
            CASE 
                WHEN cost_percentage >= @CostThresholdRed THEN '🔴 Vermelho'  -- Alto impacto
                WHEN cost_percentage >= @CostThresholdYellow THEN '🟡 Amarelo'  -- Médio impacto
                ELSE '🟢 Verde'  -- Baixo impacto
            END
        ELSE 'N/A'
        END AS [Status Interpretação],
        -- Descrição do status
        CASE WHEN @ShowCostPercentage = 1 THEN
            CASE 
                WHEN cost_percentage >= @CostThresholdRed THEN 'CRÍTICO: Query consome ' + CAST(CAST(cost_percentage AS DECIMAL(5,2)) AS VARCHAR(10)) + '% do total - Requer otimização urgente'
                WHEN cost_percentage >= @CostThresholdYellow THEN 'ATENÇÃO: Query consome ' + CAST(CAST(cost_percentage AS DECIMAL(5,2)) AS VARCHAR(10)) + '% do total - Monitorar e considerar otimização'
                ELSE 'OK: Query consome ' + CAST(CAST(cost_percentage AS DECIMAL(5,2)) AS VARCHAR(10)) + '% do total - Dentro do esperado'
            END
        ELSE 'Análise de custo desabilitada'
        END AS [Descrição Status],
        plan_count AS [Plan Count],
        first_execution_time AS [First Execution],
        last_execution_time AS [Last Execution],
        -- Limita o texto da query para melhor visualização
        CASE 
            WHEN LEN(query_sql_text) > 100 
            THEN LEFT(query_sql_text, 100) + '...'
            ELSE query_sql_text
        END AS [Query Text (Preview)],
        query_sql_text AS [Full Query Text]
    FROM RankedQueries
    WHERE ranking <= @TopN
    ORDER BY ranking;
    
    -- Estatísticas resumidas
    PRINT '';
    PRINT '===============================================================================';
    PRINT 'ESTATÍSTICAS RESUMIDAS DO PERÍODO';
    PRINT '===============================================================================';
    
    SELECT 
        COUNT(DISTINCT q.query_id) AS [Total Unique Queries],
        COUNT(DISTINCT p.plan_id) AS [Total Unique Plans],
        SUM(rs.count_executions) AS [Total Executions],
        CAST(SUM(rs.avg_duration * rs.count_executions) / 1000.0 AS DECIMAL(18,2)) AS [Total Duration (ms)],
        CAST(SUM(rs.avg_cpu_time * rs.count_executions) / 1000.0 AS DECIMAL(18,2)) AS [Total CPU Time (ms)],
        SUM(rs.avg_logical_io_reads * rs.count_executions) AS [Total Logical Reads],
        SUM(rs.avg_physical_io_reads * rs.count_executions) AS [Total Physical Reads],
        SUM(rs.avg_logical_io_writes * rs.count_executions) AS [Total Writes],
        -- Estatísticas de memória
        CAST(SUM(rs.avg_query_max_used_memory * rs.count_executions) AS BIGINT) AS [Total Memory Used (KB)],
        CAST(SUM(rs.avg_query_max_used_memory * rs.count_executions) / 1024.0 AS DECIMAL(18,2)) AS [Total Memory Used (MB)],
        CAST(SUM(rs.avg_tempdb_space_used * rs.count_executions) AS BIGINT) AS [Total TempDB Used (KB)],
        CAST(SUM(rs.avg_tempdb_space_used * rs.count_executions) / 1024.0 AS DECIMAL(18,2)) AS [Total TempDB Used (MB)]
    FROM sys.query_store_query q
    INNER JOIN sys.query_store_plan p ON q.query_id = p.query_id
    INNER JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
    INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    WHERE rsi.start_time >= @StartTime
        AND q.is_internal_query = 0;
    
    -- Informações do Query Store
    PRINT '';
    PRINT '===============================================================================';
    PRINT 'CONFIGURAÇÕES DO QUERY STORE';
    PRINT '===============================================================================';
    
    SELECT 
        actual_state_desc AS [Estado Atual],
        readonly_reason AS [Motivo Somente Leitura],
        desired_state_desc AS [Estado Desejado],
        current_storage_size_mb AS [Tamanho Atual (MB)],
        max_storage_size_mb AS [Tamanho Máximo (MB)],
        flush_interval_seconds AS [Intervalo Flush (seg)],
        interval_length_minutes AS [Duração Intervalo (min)],
        stale_query_threshold_days AS [Threshold Queries Antigas (dias)],
        size_based_cleanup_mode_desc AS [Modo Limpeza],
        query_capture_mode_desc AS [Modo Captura],
        max_plans_per_query AS [Max Planos por Query]
    FROM sys.database_query_store_options;
    
END;
GO

-- Exemplo de uso da procedure
/*
-- Buscar top 5 queries por duração nas últimas 6 horas (com análise de custo padrão)
EXEC HealthCheck.uspQueryStoreTopQueries @TopN = 5, @MetricType = 'duration', @TimeRange = 6;

-- Buscar top 10 queries por CPU nas últimas 24 horas com thresholds personalizados
EXEC HealthCheck.uspQueryStoreTopQueries 
    @TopN = 10, 
    @MetricType = 'cpu', 
    @TimeRange = 24,
    @CostThresholdYellow = 15.0,
    @CostThresholdRed = 30.0;

-- Buscar top 15 queries por leituras lógicas na última semana sem análise de custo
EXEC HealthCheck.uspQueryStoreTopQueries 
    @TopN = 15, 
    @MetricType = 'logical_reads', 
    @TimeRange = 168,
    @ShowCostPercentage = 0;

-- Buscar top 5 queries mais executadas nas últimas 12 horas com thresholds mais rigorosos
EXEC HealthCheck.uspQueryStoreTopQueries 
    @TopN = 5, 
    @MetricType = 'execution_count', 
    @TimeRange = 12,
    @CostThresholdYellow = 5.0,
    @CostThresholdRed = 15.0;

-- Análise crítica: queries que consomem mais de 20% dos recursos por escritas
EXEC HealthCheck.uspQueryStoreTopQueries 
    @TopN = 20, 
    @MetricType = 'writes', 
    @TimeRange = 48,
    @CostThresholdYellow = 5.0,
    @CostThresholdRed = 20.0;

-- Análise completa com foco em métricas de memória e performance
EXEC HealthCheck.uspQueryStoreTopQueries 
    @TopN = 10, 
    @MetricType = 'duration', 
    @TimeRange = 24,
    @ShowCostPercentage = 1,
    @CostThresholdYellow = 8.0,
    @CostThresholdRed = 20.0;
*/

-- Script para habilitar Query Store (se necessário)
/*
ALTER DATABASE [NomeDoBanco] SET QUERY_STORE = ON;
ALTER DATABASE [NomeDoBanco] SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE,
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    INTERVAL_LENGTH_MINUTES = 60,
    MAX_STORAGE_SIZE_MB = 1000,
    QUERY_CAPTURE_MODE = AUTO,
    SIZE_BASED_CLEANUP_MODE = AUTO
);
*/