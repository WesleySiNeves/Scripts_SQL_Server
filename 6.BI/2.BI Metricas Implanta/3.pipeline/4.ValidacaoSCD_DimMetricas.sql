-- =============================================
-- SCRIPT DE VALIDAÇÃO E MONITORAMENTO
-- SCD Tipo 2 - DimMetricas
-- =============================================

-- =============================================
-- 1. VALIDAÇÕES DE INTEGRIDADE SCD TIPO 2
-- =============================================

PRINT '=== VALIDAÇÕES DE INTEGRIDADE SCD TIPO 2 - DimMetricas ===';
PRINT '';

-- Validação 1: Verificar se existe apenas uma versão atual por métrica
PRINT '--- Validação 1: Versões Atuais Únicas ---';
SELECT 
    [NomeMetrica],
    COUNT(*) AS [VersoesAtuais]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 1
GROUP BY [NomeMetrica]
HAVING COUNT(*) > 1;

IF @@ROWCOUNT = 0
    PRINT '✓ PASSOU: Cada métrica possui apenas uma versão atual'
ELSE
    PRINT '✗ FALHOU: Existem métricas com múltiplas versões atuais';

PRINT '';

-- Validação 2: Verificar se versões históricas têm DataFimVersao preenchida
PRINT '--- Validação 2: DataFimVersao em Versões Históricas ---';
SELECT 
    [SkMetrica],
    [NomeMetrica],
    [VersaoAtual],
    [DataFimVersao]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 0 AND [DataFimVersao] IS NULL;

IF @@ROWCOUNT = 0
    PRINT '✓ PASSOU: Todas as versões históricas têm DataFimVersao preenchida'
ELSE
    PRINT '✗ FALHOU: Existem versões históricas sem DataFimVersao';

PRINT '';

-- Validação 3: Verificar se versões atuais têm DataFimVersao nula
PRINT '--- Validação 3: DataFimVersao Nula em Versões Atuais ---';
SELECT 
    [SkMetrica],
    [NomeMetrica],
    [VersaoAtual],
    [DataFimVersao]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 1 AND [DataFimVersao] IS NOT NULL;

IF @@ROWCOUNT = 0
    PRINT '✓ PASSOU: Todas as versões atuais têm DataFimVersao nula'
ELSE
    PRINT '✗ FALHOU: Existem versões atuais com DataFimVersao preenchida';

PRINT '';

-- Validação 4: Verificar consistência temporal (DataInicioVersao < DataFimVersao)
PRINT '--- Validação 4: Consistência Temporal ---';
SELECT 
    [SkMetrica],
    [NomeMetrica],
    [DataInicioVersao],
    [DataFimVersao]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [DataFimVersao] IS NOT NULL 
  AND [DataInicioVersao] >= [DataFimVersao];

IF @@ROWCOUNT = 0
    PRINT '✓ PASSOU: Todas as datas estão consistentes'
ELSE
    PRINT '✗ FALHOU: Existem inconsistências temporais';

PRINT '';

-- =============================================
-- 2. RELATÓRIOS DE MONITORAMENTO
-- =============================================

PRINT '=== RELATÓRIOS DE MONITORAMENTO ===';
PRINT '';

-- Relatório 1: Resumo geral das métricas
PRINT '--- Relatório 1: Resumo Geral ---';
SELECT 
    'Total de Métricas Únicas' AS [Métrica],
    COUNT(DISTINCT [NomeMetrica]) AS [Valor]
FROM [DM_MetricasClientes].[DimMetricas]
UNION ALL
SELECT 
    'Total de Versões',
    COUNT(*)
FROM [DM_MetricasClientes].[DimMetricas]
UNION ALL
SELECT 
    'Versões Atuais',
    COUNT(*)
FROM [DM_MetricasClientes].[DimMetricas]
WHERE [VersaoAtual] = 1
UNION ALL
SELECT 
    'Versões Históricas',
    COUNT(*)
FROM [DM_MetricasClientes].[DimMetricas]
WHERE [VersaoAtual] = 0
UNION ALL
SELECT 
    'Métricas Ativas',
    COUNT(*)
FROM [DM_MetricasClientes].[DimMetricas]
WHERE [VersaoAtual] = 1 AND [Ativo] = 1
UNION ALL
SELECT 
    'Métricas Inativas',
    COUNT(*)
FROM [DM_MetricasClientes].[DimMetricas]
WHERE [VersaoAtual] = 1 AND [Ativo] = 0;

PRINT '';

-- Relatório 2: Distribuição por categoria
PRINT '--- Relatório 2: Distribuição por Categoria ---';
SELECT 
    [Categoria],
    COUNT(*) AS [TotalMetricas],
    SUM(CASE WHEN [Ativo] = 1 THEN 1 ELSE 0 END) AS [MetricasAtivas],
    SUM(CASE WHEN [Ativo] = 0 THEN 1 ELSE 0 END) AS [MetricasInativas]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 1
GROUP BY [Categoria]
ORDER BY [TotalMetricas] DESC;

PRINT '';

-- Relatório 3: Distribuição por tipo de retorno
PRINT '--- Relatório 3: Distribuição por Tipo de Retorno ---';
SELECT 
    [TipoRetorno],
    COUNT(*) AS [TotalMetricas],
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS [Percentual]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 1
GROUP BY [TipoRetorno]
ORDER BY [TotalMetricas] DESC;

PRINT '';

-- Relatório 4: Métricas com histórico de mudanças
PRINT '--- Relatório 4: Métricas com Histórico de Mudanças ---';
SELECT 
    [NomeMetrica],
    COUNT(*) AS [TotalVersoes],
    MIN([DataInicioVersao]) AS [PrimeiraVersao],
    MAX([DataInicioVersao]) AS [UltimaVersao],
    DATEDIFF(DAY, MIN([DataInicioVersao]), MAX([DataInicioVersao])) AS [DiasEntreMudancas]
FROM [DM_MetricasClientes].[DimMetricas] 
GROUP BY [NomeMetrica]
HAVING COUNT(*) > 1
ORDER BY [TotalVersoes] DESC, [UltimaVersao] DESC;

PRINT '';

-- Relatório 5: Atividade recente (últimos 30 dias)
PRINT '--- Relatório 5: Atividade Recente (30 dias) ---';
SELECT 
    CAST([DataCarga] AS DATE) AS [Data],
    COUNT(*) AS [NovasMetricas],
    COUNT(CASE WHEN [VersaoAtual] = 0 THEN 1 END) AS [VersoesHistoricas]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [DataCarga] >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST([DataCarga] AS DATE)
ORDER BY [Data] DESC;

PRINT '';

-- =============================================
-- 3. QUERIES DE ANÁLISE TEMPORAL
-- =============================================

PRINT '=== QUERIES DE ANÁLISE TEMPORAL ===';
PRINT '';

-- Análise 1: Evolução temporal de uma métrica específica
PRINT '--- Análise 1: Evolução Temporal (exemplo) ---';
PRINT 'Para analisar uma métrica específica, use:';
PRINT 'SELECT * FROM [DM_MetricasClientes].[DimMetricas] WHERE [NomeMetrica] = ''SuaMetrica'' ORDER BY [DataInicioVersao];';
PRINT '';

-- Análise 2: Métricas válidas em uma data específica
PRINT '--- Análise 2: Métricas Válidas em Data Específica ---';
PRINT 'Para ver métricas válidas em uma data específica, use:';
PRINT 'DECLARE @DataConsulta DATETIME2(2) = ''2024-01-15'';';
PRINT 'SELECT * FROM [DM_MetricasClientes].[DimMetricas]';
PRINT 'WHERE [DataInicioVersao] <= @DataConsulta';
PRINT '  AND ([DataFimVersao] IS NULL OR [DataFimVersao] > @DataConsulta);';
PRINT '';

-- =============================================
-- 4. COMANDOS DE MANUTENÇÃO
-- =============================================

PRINT '=== COMANDOS DE MANUTENÇÃO ===';
PRINT '';

-- Comando 1: Reativar métrica
PRINT '--- Comando 1: Reativar Métrica ---';
PRINT 'UPDATE [DM_MetricasClientes].[DimMetricas]';
PRINT 'SET [Ativo] = 1, [DataAtualizacao] = GETDATE()';
PRINT 'WHERE [NomeMetrica] = ''SuaMetrica'' AND [VersaoAtual] = 1;';
PRINT '';

-- Comando 2: Desativar métrica manualmente
PRINT '--- Comando 2: Desativar Métrica ---';
PRINT 'UPDATE [DM_MetricasClientes].[DimMetricas]';
PRINT 'SET [Ativo] = 0, [DataAtualizacao] = GETDATE()';
PRINT 'WHERE [NomeMetrica] = ''SuaMetrica'' AND [VersaoAtual] = 1;';
PRINT '';

-- Comando 3: Limpar histórico antigo (cuidado!)
PRINT '--- Comando 3: Limpar Histórico Antigo (CUIDADO!) ---';
PRINT '-- Remover versões históricas com mais de 2 anos';
PRINT '-- DELETE FROM [DM_MetricasClientes].[DimMetricas]';
PRINT '-- WHERE [VersaoAtual] = 0 AND [DataFimVersao] < DATEADD(YEAR, -2, GETDATE());';
PRINT '';

-- =============================================
-- 5. ALERTAS E MONITORAMENTO AUTOMÁTICO
-- =============================================

PRINT '=== ALERTAS E MONITORAMENTO ===';
PRINT '';

-- Alerta 1: Métricas com muitas mudanças
PRINT '--- Alerta 1: Métricas com Muitas Mudanças ---';
SELECT 
    [NomeMetrica],
    COUNT(*) AS [TotalVersoes]
FROM [DM_MetricasClientes].[DimMetricas] 
GROUP BY [NomeMetrica]
HAVING COUNT(*) >= 5  -- Alerta para métricas com 5+ versões
ORDER BY [TotalVersoes] DESC;

IF @@ROWCOUNT > 0
    PRINT '⚠️ ALERTA: Existem métricas com muitas mudanças'
ELSE
    PRINT '✓ OK: Nenhuma métrica com excesso de mudanças';

PRINT '';

-- Alerta 2: Métricas sem atividade recente
PRINT '--- Alerta 2: Métricas Sem Atividade Recente ---';
SELECT 
    [NomeMetrica],
    [DataCarga],
    DATEDIFF(DAY, [DataCarga], GETDATE()) AS [DiasSemAtualizacao]
FROM [DM_MetricasClientes].[DimMetricas] 
WHERE [VersaoAtual] = 1 
  AND [Ativo] = 1
  AND [DataCarga] < DATEADD(DAY, -90, GETDATE())  -- 90 dias sem atualização
ORDER BY [DataCarga];

IF @@ROWCOUNT > 0
    PRINT '⚠️ ALERTA: Existem métricas sem atividade recente'
ELSE
    PRINT '✓ OK: Todas as métricas têm atividade recente';

PRINT '';

-- Alerta 3: Inconsistências de dados
PRINT '--- Alerta 3: Verificação de Inconsistências ---';
DECLARE @Inconsistencias INT = 0;

-- Verificar versões atuais duplicadas
SELECT @Inconsistencias = COUNT(*)
FROM (
    SELECT [NomeMetrica]
    FROM [DM_MetricasClientes].[DimMetricas] 
    WHERE [VersaoAtual] = 1
    GROUP BY [NomeMetrica]
    HAVING COUNT(*) > 1
) AS Duplicadas;

IF @Inconsistencias > 0
    PRINT '🚨 CRÍTICO: ' + CAST(@Inconsistencias AS VARCHAR(10)) + ' métricas com versões atuais duplicadas'
ELSE
    PRINT '✓ OK: Nenhuma inconsistência encontrada';

PRINT '';
PRINT '=== VALIDAÇÃO CONCLUÍDA ===';
PRINT '';
PRINT 'Execute este script regularmente para monitorar a saúde do SCD Tipo 2.';
PRINT 'Recomendação: Agendar execução diária ou semanal.';

-- =============================================
-- 6. EXEMPLO DE VIEW PARA CONSULTAS SIMPLIFICADAS
-- =============================================

/*
-- View para facilitar consultas das versões atuais
CREATE OR ALTER VIEW [DM_MetricasClientes].[VwMetricasAtuais]
AS
SELECT 
    [SkMetrica],
    [NomeMetrica],
    [TipoRetorno],
    [Categoria],
    [Descricao],
    [Ativo],
    [DataInicioVersao],
    [DataCarga]
FROM [DM_MetricasClientes].[DimMetricas]
WHERE [VersaoAtual] = 1;

-- View para análise histórica
CREATE OR ALTER VIEW [DM_MetricasClientes].[VwMetricasHistorico]
AS
SELECT 
    [SkMetrica],
    [NomeMetrica],
    [TipoRetorno],
    [Categoria],
    [VersaoAtual],
    [DataInicioVersao],
    [DataFimVersao],
    CASE 
        WHEN [VersaoAtual] = 1 THEN 'ATUAL'
        ELSE 'HISTÓRICA'
    END AS [StatusVersao],
    CASE 
        WHEN [DataFimVersao] IS NULL THEN NULL
        ELSE DATEDIFF(DAY, [DataInicioVersao], [DataFimVersao])
    END AS [DiasVigencia]
FROM [DM_MetricasClientes].[DimMetricas];
*/