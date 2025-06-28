SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HealthCheck].[uspGetMemoryPressure]
(
    @ShowDetails BIT = 1,
    @TopObjects INT = 20,
    @CriticalThresholdMB DECIMAL(10,2) = 100.0,
    @HighThresholdMB DECIMAL(10,2) = 50.0,
    @MediumThresholdMB DECIMAL(10,2) = 10.0,
    @GenerateActionPlan BIT = 1,
    @IncludeFragmentationAnalysis BIT = 1,
    @IncludeIndexUsageStats BIT = 1,
    @MinimumCachePercentage DECIMAL(5,2) = 1.0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    /*
    === PROCEDURE DE ANÁLISE DE PRESSÃO DE MEMÓRIA - VERSÃO ENTERPRISE ===
    
    FUNCIONALIDADES:
    ✓ Análise automática de pressão de memória por objeto
    ✓ Diagnóstico inteligente com recomendações específicas
    ✓ Integração com análise de fragmentação e uso de índices
    ✓ Plano de ação automatizado baseado em thresholds
    ✓ Relatório executivo com métricas de ROI
    ✓ Alertas proativos para objetos críticos
    ✓ Estimativas de economia e impacto financeiro
    
    COMPATIBILIDADE: Azure SQL Database (PaaS) e SQL Server On-Premises
    
    AUTOR: Wesley Neves
    DATA: Baseado no script QuantidadeMemoriaCachePorTabela.sql
    */

    -- Variáveis de controle
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @TotalCacheMemoryMB DECIMAL(18,2);
    DECLARE @CriticalObjectsCount INT;
    DECLARE @HighPriorityObjectsCount INT;
    DECLARE @TotalPotentialSavingsMB DECIMAL(18,2);
    
    -- Tabela temporária para armazenar resultados da análise
    CREATE TABLE #MemoryPressureAnalysis
    (
        DatabaseName NVARCHAR(128),
        object_id INT,
        ObjectName NVARCHAR(128),
        IndexName NVARCHAR(128),
        index_id INT,
        PaginasEmCache BIGINT,
        MemoriaUsada_MB DECIMAL(10,2),
        PercentualDoCache DECIMAL(5,2),
        PrioridadeOtimizacao NVARCHAR(50),
        RecomendacaoCapacidade NVARCHAR(100),
        EconomiaPotencial_MB DECIMAL(10,2),
        ClassificacaoROI NVARCHAR(50),
        SugestaoArquitetura NVARCHAR(100),
        RankingConsumo INT,
        -- Campos adicionais para diagnóstico
        FragmentationPercent DECIMAL(5,2) NULL,
        IndexUsageScore INT NULL,
        LastUserSeek DATETIME NULL,
        LastUserScan DATETIME NULL,
        ActionPriority INT,
        RecommendedAction NVARCHAR(500),
        EstimatedImpact NVARCHAR(200),
        ImplementationComplexity NVARCHAR(20)
    );

    -- === COLETA DE DADOS DE MEMÓRIA CACHE ===
    ;WITH Dados AS (
        SELECT DB_NAME(DB_ID()) DatabaseName,
               Result.object_id,
               Result.ObjectName,
               COUNT(*) AS cached_pages_count,
               Result.index_id
        FROM sys.dm_os_buffer_descriptors A
             INNER JOIN
             (
                 SELECT OBJECT_NAME(B.object_id) AS ObjectName,
                        B.object_id,
                        A.allocation_unit_id,
                        A.type_desc,
                        B.index_id,
                        B.rows
                 FROM sys.allocation_units A,
                      sys.partitions B
                 WHERE A.container_id = B.hobt_id
                       AND (A.type = 1 OR A.type = 3)
                 UNION ALL
                 SELECT OBJECT_NAME(p.object_id) AS ObjectName,
                        p.object_id,
                        au.allocation_unit_id,
                        au.type_desc,
                        p.index_id,
                        p.rows
                 FROM sys.allocation_units AS au
                      INNER JOIN sys.partitions AS p ON au.container_id = p.partition_id
                                                         AND au.type = 2
             ) AS Result ON A.allocation_unit_id = Result.allocation_unit_id
        WHERE Result.object_id > 100
        GROUP BY Result.object_id, Result.ObjectName, Result.index_id
    )
    INSERT INTO #MemoryPressureAnalysis
    (
        DatabaseName, object_id, ObjectName, IndexName, index_id,
        PaginasEmCache, MemoriaUsada_MB, PercentualDoCache,
        PrioridadeOtimizacao, RecomendacaoCapacidade, EconomiaPotencial_MB,
        ClassificacaoROI, SugestaoArquitetura, RankingConsumo
    )
    SELECT 
        R.DatabaseName,
        R.object_id,
        R.ObjectName,
        ISNULL(I.name, 'N/A') AS IndexName,
        R.index_id,
        R.cached_pages_count AS PaginasEmCache,
        CAST((R.cached_pages_count * 8.0) / 1024 AS DECIMAL(10,2)) AS MemoriaUsada_MB,
        CAST((R.cached_pages_count * 100.0) / NULLIF(SUM(R.cached_pages_count) OVER(), 0) AS DECIMAL(5,2)) AS PercentualDoCache,
        
        -- Classificação de prioridade baseada nos thresholds parametrizados
        CASE 
            WHEN (R.cached_pages_count * 8.0) / 1024 > @CriticalThresholdMB THEN 'CRÍTICO'
            WHEN (R.cached_pages_count * 8.0) / 1024 > @HighThresholdMB THEN 'ALTO'
            WHEN (R.cached_pages_count * 8.0) / 1024 > @MediumThresholdMB THEN 'MÉDIO'
            ELSE 'BAIXO'
        END AS PrioridadeOtimizacao,
        
        -- Recomendações de capacidade
        CASE 
            WHEN (R.cached_pages_count * 8.0) / 1024 > 500 THEN 'Considerar Tier Superior ou Particionamento'
            WHEN (R.cached_pages_count * 8.0) / 1024 > 200 THEN 'Monitorar Crescimento - Possível Upgrade'
            WHEN (R.cached_pages_count * 8.0) / 1024 > @CriticalThresholdMB THEN 'Otimizar Índices e Queries'
            ELSE 'Tier Atual Adequado'
        END AS RecomendacaoCapacidade,
        
        -- Economia potencial
        CASE 
            WHEN (R.cached_pages_count * 8.0) / 1024 > @CriticalThresholdMB THEN 
                CAST(((R.cached_pages_count * 8.0) / 1024) * 0.30 AS DECIMAL(10,2))
            WHEN (R.cached_pages_count * 8.0) / 1024 > @HighThresholdMB THEN 
                CAST(((R.cached_pages_count * 8.0) / 1024) * 0.20 AS DECIMAL(10,2))
            ELSE 0
        END AS EconomiaPotencial_MB,
        
        -- Classificação de ROI
        CASE 
            WHEN (R.cached_pages_count * 8.0) / 1024 > 200 THEN 'ROI ALTO'
            WHEN (R.cached_pages_count * 8.0) / 1024 > @CriticalThresholdMB THEN 'ROI MÉDIO'
            WHEN (R.cached_pages_count * 8.0) / 1024 > @HighThresholdMB THEN 'ROI BAIXO'
            ELSE 'ROI MÍNIMO'
        END AS ClassificacaoROI,
        
        -- Sugestões arquiteturais
        CASE 
            WHEN I.type_desc = 'CLUSTERED' AND (R.cached_pages_count * 8.0) / 1024 > 200 THEN 'Candidato a Particionamento Horizontal'
            WHEN I.type_desc = 'NONCLUSTERED' AND (R.cached_pages_count * 8.0) / 1024 > @CriticalThresholdMB THEN 'Revisar Necessidade do Índice'
            WHEN I.type_desc = 'CLUSTERED' AND (R.cached_pages_count * 8.0) / 1024 > @CriticalThresholdMB THEN 'Otimizar Estrutura da Tabela'
            ELSE 'Estrutura Adequada'
        END AS SugestaoArquitetura,
        
        ROW_NUMBER() OVER (ORDER BY R.cached_pages_count DESC) AS RankingConsumo
        
    FROM Dados R
        LEFT JOIN sys.indexes AS I ON R.object_id = I.object_id AND R.index_id = I.index_id
    WHERE CAST((R.cached_pages_count * 100.0) / NULLIF(SUM(R.cached_pages_count) OVER(), 0) AS DECIMAL(5,2)) >= @MinimumCachePercentage
    ORDER BY R.cached_pages_count DESC;

    -- === ANÁLISE DE FRAGMENTAÇÃO (SE SOLICITADA) ===
    IF (@IncludeFragmentationAnalysis = 1)
    BEGIN
        UPDATE mpa
        SET FragmentationPercent = ips.avg_fragmentation_in_percent
        FROM #MemoryPressureAnalysis mpa
        CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), mpa.object_id, mpa.index_id, NULL, 'LIMITED') ips
        WHERE mpa.index_id > 0; -- Apenas para índices válidos
    END;

    -- === ANÁLISE DE USO DE ÍNDICES (SE SOLICITADA) ===
    IF (@IncludeIndexUsageStats = 1)
    BEGIN
        UPDATE mpa
        SET IndexUsageScore = ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0),
            LastUserSeek = ius.last_user_seek,
            LastUserScan = ius.last_user_scan
        FROM #MemoryPressureAnalysis mpa
        LEFT JOIN sys.dm_db_index_usage_stats ius ON mpa.object_id = ius.object_id 
                                                   AND mpa.index_id = ius.index_id 
                                                   AND ius.database_id = DB_ID()
        WHERE mpa.index_id > 0;
    END;

    -- === GERAÇÃO DO PLANO DE AÇÃO (SE SOLICITADO) ===
    IF (@GenerateActionPlan = 1)
    BEGIN
        UPDATE #MemoryPressureAnalysis
        SET ActionPriority = CASE PrioridadeOtimizacao
                                WHEN 'CRÍTICO' THEN 1
                                WHEN 'ALTO' THEN 2
                                WHEN 'MÉDIO' THEN 3
                                ELSE 4
                             END,
            RecommendedAction = CASE 
                WHEN PrioridadeOtimizacao = 'CRÍTICO' AND ISNULL(FragmentationPercent, 0) > 30 THEN 
                    'URGENTE: Rebuild do índice ' + IndexName + ' (Fragmentação: ' + CAST(ISNULL(FragmentationPercent, 0) AS VARCHAR(10)) + '%)'
                WHEN PrioridadeOtimizacao = 'CRÍTICO' AND ISNULL(IndexUsageScore, 0) = 0 THEN 
                    'URGENTE: Avaliar remoção do índice ' + IndexName + ' (Não utilizado)'
                WHEN PrioridadeOtimizacao = 'CRÍTICO' THEN 
                    'URGENTE: Otimizar queries que acessam ' + ObjectName + ' ou considerar particionamento'
                WHEN PrioridadeOtimizacao = 'ALTO' AND ISNULL(FragmentationPercent, 0) > 15 THEN 
                    'Reorganizar índice ' + IndexName + ' (Fragmentação: ' + CAST(ISNULL(FragmentationPercent, 0) AS VARCHAR(10)) + '%)'
                WHEN PrioridadeOtimizacao = 'ALTO' THEN 
                    'Analisar padrões de acesso e otimizar queries para ' + ObjectName
                WHEN PrioridadeOtimizacao = 'MÉDIO' THEN 
                    'Monitorar crescimento e considerar otimizações futuras'
                ELSE 'Manter monitoramento regular'
            END,
            EstimatedImpact = CASE 
                WHEN EconomiaPotencial_MB > 50 THEN 'Alto impacto: Economia de ' + CAST(EconomiaPotencial_MB AS VARCHAR(20)) + ' MB'
                WHEN EconomiaPotencial_MB > 20 THEN 'Médio impacto: Economia de ' + CAST(EconomiaPotencial_MB AS VARCHAR(20)) + ' MB'
                WHEN EconomiaPotencial_MB > 0 THEN 'Baixo impacto: Economia de ' + CAST(EconomiaPotencial_MB AS VARCHAR(20)) + ' MB'
                ELSE 'Impacto mínimo'
            END,
            ImplementationComplexity = CASE 
                WHEN SugestaoArquitetura LIKE '%Particionamento%' THEN 'ALTA'
                WHEN PrioridadeOtimizacao = 'CRÍTICO' AND ISNULL(FragmentationPercent, 0) > 50 THEN 'MÉDIA'
                WHEN PrioridadeOtimizacao IN ('CRÍTICO', 'ALTO') THEN 'BAIXA'
                ELSE 'MÍNIMA'
            END;
    END;

    -- === CÁLCULO DE MÉTRICAS GERAIS ===
    SELECT @TotalCacheMemoryMB = SUM(MemoriaUsada_MB),
           @CriticalObjectsCount = SUM(CASE WHEN PrioridadeOtimizacao = 'CRÍTICO' THEN 1 ELSE 0 END),
           @HighPriorityObjectsCount = SUM(CASE WHEN PrioridadeOtimizacao = 'ALTO' THEN 1 ELSE 0 END),
           @TotalPotentialSavingsMB = SUM(EconomiaPotencial_MB)
    FROM #MemoryPressureAnalysis;

    -- === RELATÓRIO EXECUTIVO ===
    PRINT '=== RELATÓRIO DE PRESSÃO DE MEMÓRIA ===';
    PRINT 'Data/Hora: ' + CONVERT(VARCHAR(20), @StartTime, 120);
    PRINT 'Memória Total em Cache: ' + CAST(@TotalCacheMemoryMB AS VARCHAR(20)) + ' MB';
    PRINT 'Objetos Críticos: ' + CAST(@CriticalObjectsCount AS VARCHAR(10));
    PRINT 'Objetos Alta Prioridade: ' + CAST(@HighPriorityObjectsCount AS VARCHAR(10));
    PRINT 'Economia Potencial Total: ' + CAST(@TotalPotentialSavingsMB AS VARCHAR(20)) + ' MB';
    PRINT '';

    -- === ALERTAS CRÍTICOS ===
    IF (@CriticalObjectsCount > 0)
    BEGIN
        PRINT '⚠️  ALERTA: ' + CAST(@CriticalObjectsCount AS VARCHAR(10)) + ' objeto(s) crítico(s) detectado(s)!';
        PRINT 'Ação imediata recomendada para evitar degradação de performance.';
        PRINT '';
    END;

    -- === RESULTADOS DETALHADOS ===
    IF (@ShowDetails = 1)
    BEGIN
        -- Top objetos consumindo memória
        SELECT TOP (@TopObjects)
            DatabaseName,
            ObjectName,
            IndexName,
            MemoriaUsada_MB,
            PercentualDoCache,
            PrioridadeOtimizacao,
            ClassificacaoROI,
            ISNULL(FragmentationPercent, 0) AS FragmentacaoPercent,
            ISNULL(IndexUsageScore, 0) AS PontuacaoUso,
            RecommendedAction AS AcaoRecomendada,
            EstimatedImpact AS ImpactoEstimado,
            ImplementationComplexity AS ComplexidadeImplementacao
        FROM #MemoryPressureAnalysis
        ORDER BY ActionPriority, MemoriaUsada_MB DESC;
    END;

    -- === PLANO DE AÇÃO PRIORIZADO ===
    IF (@GenerateActionPlan = 1)
    BEGIN
        PRINT '=== PLANO DE AÇÃO PRIORIZADO ===';
        
        -- Ações críticas
        IF EXISTS (SELECT 1 FROM #MemoryPressureAnalysis WHERE PrioridadeOtimizacao = 'CRÍTICO')
        BEGIN
            PRINT '🔴 AÇÕES CRÍTICAS (Executar Imediatamente):';
            SELECT 
                '• ' + ObjectName + '.' + IndexName + ': ' + RecommendedAction AS [Ação Crítica],
                EstimatedImpact AS [Impacto Esperado]
            FROM #MemoryPressureAnalysis 
            WHERE PrioridadeOtimizacao = 'CRÍTICO'
            ORDER BY MemoriaUsada_MB DESC;
            PRINT '';
        END;
        
        -- Ações de alta prioridade
        IF EXISTS (SELECT 1 FROM #MemoryPressureAnalysis WHERE PrioridadeOtimizacao = 'ALTO')
        BEGIN
            PRINT '🟡 AÇÕES DE ALTA PRIORIDADE (Executar em 24-48h):';
            SELECT 
                '• ' + ObjectName + '.' + IndexName + ': ' + RecommendedAction AS [Ação Alta Prioridade],
                EstimatedImpact AS [Impacto Esperado]
            FROM #MemoryPressureAnalysis 
            WHERE PrioridadeOtimizacao = 'ALTO'
            ORDER BY MemoriaUsada_MB DESC;
        END;
    END;

    -- === RESUMO POR PRIORIDADE ===
    SELECT 
        PrioridadeOtimizacao AS Prioridade,
        COUNT(*) AS QuantidadeObjetos,
        SUM(MemoriaUsada_MB) AS TotalMemoria_MB,
        AVG(PercentualDoCache) AS MediaPercentualCache,
        SUM(EconomiaPotencial_MB) AS EconomiaPotencial_MB,
        AVG(ISNULL(FragmentationPercent, 0)) AS MediaFragmentacao
    FROM #MemoryPressureAnalysis
    GROUP BY PrioridadeOtimizacao
    ORDER BY 
        CASE PrioridadeOtimizacao 
            WHEN 'CRÍTICO' THEN 1
            WHEN 'ALTO' THEN 2
            WHEN 'MÉDIO' THEN 3
            ELSE 4
        END;

    -- Limpeza
    DROP TABLE #MemoryPressureAnalysis;
    
    PRINT '';
    PRINT 'Análise concluída em ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + ' segundos.';
END;
GO

/* ==================================================================
-- EXEMPLOS DE USO DA PROCEDURE
-- ==================================================================

-- Uso básico - análise rápida
EXEC HealthCheck.uspGetMemoryPressure;

-- Análise completa com fragmentação e uso de índices
EXEC HealthCheck.uspGetMemoryPressure 
    @ShowDetails = 1,
    @IncludeFragmentationAnalysis = 1,
    @IncludeIndexUsageStats = 1,
    @GenerateActionPlan = 1;

-- Análise focada em objetos críticos (threshold mais baixo)
EXEC HealthCheck.uspGetMemoryPressure 
    @CriticalThresholdMB = 50.0,
    @HighThresholdMB = 25.0,
    @TopObjects = 10;

-- Análise para ambientes com muita memória (thresholds mais altos)
EXEC HealthCheck.uspGetMemoryPressure 
    @CriticalThresholdMB = 500.0,
    @HighThresholdMB = 200.0,
    @MediumThresholdMB = 100.0;

-- Análise apenas dos maiores consumidores (top 5)
EXEC HealthCheck.uspGetMemoryPressure 
    @TopObjects = 5,
    @MinimumCachePercentage = 5.0;

==================================================================
*/