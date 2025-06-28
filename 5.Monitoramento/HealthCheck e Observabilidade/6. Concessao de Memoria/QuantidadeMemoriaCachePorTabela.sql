

SET TRAN ISOLATION LEVEL READ UNCOMMITTED
/* ==================================================================
-- Script: Análise de Memória Cache por Tabela - Azure SQL Optimized
-- Data: 14/09/2018 (Atualizado para Azure SQL)
-- Autor: Wesley Neves
-- Observação: Query otimizada para Azure SQL Database
-- Tempo estimado: 15-30 segundos
--
-- FUNCIONALIDADES:
-- ✓ Análise de uso de memória cache por tabela/índice
-- ✓ Controle de custos através de eficiência de recursos
-- ✓ Planejamento de capacidade e arquitetura
-- ✓ Identificação de objetos candidatos a otimização
-- ✓ Métricas de ROI para upgrade de tier
-- ✓ Análise de padrões de acesso vs consumo
--
-- COMPATIBILIDADE: Azure SQL Database (PaaS)
-- ==================================================================
*/
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
           AND (
               A.type = 1
               OR A.type = 3
               )
     UNION ALL
     SELECT OBJECT_NAME(p.object_id) AS ObjectName,
			p.object_id,
            au.allocation_unit_id,
            au.type_desc,
            p.index_id,
            p.rows
     FROM sys.allocation_units AS au
          INNER JOIN
          sys.partitions AS p ON au.container_id = p.partition_id
                                 AND au.type = 2
     ) AS Result ON A.allocation_unit_id = Result.allocation_unit_id
--WHERE database_id = DB_ID()
AND Result.object_id > 100
GROUP BY
	Result.object_id,
    Result.ObjectName,
    Result.index_id
ORDER BY
    cached_pages_count DESC
	OFFSET 0 ROWS FETCH NEXT 10000 ROW ONLY 
 )
 SELECT 
    -- === INFORMAÇÕES BÁSICAS ===
    R.DatabaseName,
    R.object_id,
    R.ObjectName,
    I.name AS IndexName,
    R.index_id,
    
    -- === MÉTRICAS DE MEMÓRIA ===
    R.cached_pages_count AS PaginasEmCache,
    CAST((R.cached_pages_count * 8.0) / 1024 AS DECIMAL(10,2)) AS MemoriaUsada_MB,
    CAST(((SUM(R.cached_pages_count) OVER() * 8.0) / 1024) AS DECIMAL(18,2)) AS TotalMemoriaCache_MB,
    
    -- === ANÁLISE DE EFICIÊNCIA E CUSTOS ===
    CAST((R.cached_pages_count * 100.0) / NULLIF(SUM(R.cached_pages_count) OVER(), 0) AS DECIMAL(5,2)) AS PercentualDoCache,
    
    -- Classificação de prioridade para otimização
    CASE 
        WHEN (R.cached_pages_count * 8.0) / 1024 > 100 THEN 'CRÍTICO - Revisar Imediatamente'
        WHEN (R.cached_pages_count * 8.0) / 1024 > 50 THEN 'ALTO - Candidato a Otimização'
        WHEN (R.cached_pages_count * 8.0) / 1024 > 10 THEN 'MÉDIO - Monitorar'
        ELSE 'BAIXO - Normal'
    END AS PrioridadeOtimizacao,
    
    -- === PLANEJAMENTO DE CAPACIDADE ===
    -- Estimativa de impacto no tier do Azure SQL
    CASE 
        WHEN (R.cached_pages_count * 8.0) / 1024 > 500 THEN 'Considerar Tier Superior ou Particionamento'
        WHEN (R.cached_pages_count * 8.0) / 1024 > 200 THEN 'Monitorar Crescimento - Possível Upgrade'
        WHEN (R.cached_pages_count * 8.0) / 1024 > 100 THEN 'Otimizar Índices e Queries'
        ELSE 'Tier Atual Adequado'
    END AS RecomendacaoCapacidade,
    
    -- === CONTROLE DE CUSTOS ===
    -- Estimativa de economia potencial com otimização
    CASE 
        WHEN (R.cached_pages_count * 8.0) / 1024 > 100 THEN 
            CAST(((R.cached_pages_count * 8.0) / 1024) * 0.30 AS DECIMAL(10,2)) -- 30% de economia potencial
        WHEN (R.cached_pages_count * 8.0) / 1024 > 50 THEN 
            CAST(((R.cached_pages_count * 8.0) / 1024) * 0.20 AS DECIMAL(10,2)) -- 20% de economia potencial
        ELSE 0
    END AS EconomiaPotencial_MB,
    
    -- Classificação de ROI para otimização
    CASE 
        WHEN (R.cached_pages_count * 8.0) / 1024 > 200 THEN 'ROI ALTO - Otimizar Prioritariamente'
        WHEN (R.cached_pages_count * 8.0) / 1024 > 100 THEN 'ROI MÉDIO - Avaliar Otimização'
        WHEN (R.cached_pages_count * 8.0) / 1024 > 50 THEN 'ROI BAIXO - Monitorar'
        ELSE 'ROI MÍNIMO - Manter'
    END AS ClassificacaoROI,
    
    -- === MÉTRICAS ARQUITETURAIS ===
    -- Sugestões de arquitetura baseadas no uso
    CASE 
        WHEN I.type_desc = 'CLUSTERED' AND (R.cached_pages_count * 8.0) / 1024 > 200 THEN 'Candidato a Particionamento Horizontal'
        WHEN I.type_desc = 'NONCLUSTERED' AND (R.cached_pages_count * 8.0) / 1024 > 100 THEN 'Revisar Necessidade do Índice'
        WHEN I.type_desc = 'CLUSTERED' AND (R.cached_pages_count * 8.0) / 1024 > 100 THEN 'Otimizar Estrutura da Tabela'
        ELSE 'Estrutura Adequada'
    END AS SugestaoArquitetura,
    
    -- Ranking de consumo para priorização
    ROW_NUMBER() OVER (ORDER BY R.cached_pages_count DESC) AS RankingConsumo
    
FROM Dados R
    LEFT JOIN sys.indexes AS I ON R.object_id = I.object_id AND R.index_id = I.index_id
ORDER BY R.cached_pages_count DESC;

/* ==================================================================
-- GUIA DE INTERPRETAÇÃO DOS RESULTADOS
-- ==================================================================

-- === CONTROLE DE CUSTOS ===
-- 1. EconomiaPotencial_MB: Estimativa de memória que pode ser liberada
-- 2. ClassificacaoROI: Priorização baseada no retorno do investimento
-- 3. PercentualDoCache: Identifica objetos que dominam o cache
--
-- AÇÕES RECOMENDADAS:
-- • ROI ALTO: Otimizar imediatamente (maior economia)
-- • ROI MÉDIO: Planejar otimização no próximo ciclo
-- • ROI BAIXO: Monitorar tendências

-- === PLANEJAMENTO DE CAPACIDADE ===
-- 1. RecomendacaoCapacidade: Orientação sobre tier do Azure SQL
-- 2. SugestaoArquitetura: Estratégias de design de dados
-- 3. RankingConsumo: Priorização de objetos para análise
--
-- ESTRATÉGIAS:
-- • Tier Superior: Para objetos >500MB em cache
-- • Particionamento: Para tabelas grandes com acesso concentrado
-- • Otimização: Para objetos 100-500MB

-- === MÉTRICAS DE EFICIÊNCIA ===
-- 1. PrioridadeOtimizacao: Classificação de urgência
-- 2. MemoriaUsada_MB: Consumo real de memória
-- 3. TotalMemoriaCache_MB: Contexto geral do ambiente
--
-- THRESHOLDS RECOMENDADOS:
-- • CRÍTICO: >100MB - Ação imediata necessária
-- • ALTO: 50-100MB - Planejar otimização
-- • MÉDIO: 10-50MB - Monitoramento regular
-- • BAIXO: <10MB - Comportamento normal

-- === EXEMPLOS DE USO ===
--
-- CENÁRIO 1: Controle de Custos
-- SELECT * FROM resultado WHERE ClassificacaoROI LIKE 'ROI ALTO%'
-- ORDER BY EconomiaPotencial_MB DESC;
--
-- CENÁRIO 2: Planejamento de Upgrade
-- SELECT ObjectName, MemoriaUsada_MB, RecomendacaoCapacidade
-- FROM resultado WHERE RecomendacaoCapacidade LIKE '%Tier Superior%';
--
-- CENÁRIO 3: Candidatos a Particionamento
-- SELECT * FROM resultado WHERE SugestaoArquitetura LIKE '%Particionamento%';
--
-- CENÁRIO 4: Análise de Tendências (executar periodicamente)
-- Comparar RankingConsumo ao longo do tempo para identificar
-- objetos com crescimento anômalo de uso de memória.

==================================================================
*/


