-- =============================================
-- Views para Consulta de Histórico - Fato Métricas Clientes
-- Descrição: Views otimizadas para análise temporal dos valores das métricas
-- Autor: Sistema
-- Data: 2024
-- =============================================

USE [DW_MetricasClientes];
GO

-- =============================================
-- VIEW 1: VALORES ATUAIS (MAIS RECENTES)
-- Retorna apenas o último valor de cada métrica
-- =============================================

CREATE OR ALTER VIEW [DM_MetricasClientes].[VwMetricasAtuais]
AS
WITH UltimosValores AS (
    SELECT 
        f.*,
        -- Dimensões desnormalizadas para facilitar consultas
        cli.SiglaCliente,
        cli.NomeCliente,
        cli.TipoCliente,
        cli.Estado,
        prod.NomeProduto,
        prod.VersaoProduto,
        met.NomeMetrica,
        met.Categoria AS CategoriaMetrica,
        met.Descricao AS DescricaoMetrica,
        met.TipoRetorno,
        tab.Nome AS TabelaConsultada,
        tab.Descricao AS DescricaoTabela,
        
        -- Ranking para identificar o mais recente
        ROW_NUMBER() OVER (
            PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
            ORDER BY f.SkTempo DESC
        ) AS rn
    FROM DM_MetricasClientes.FatoMetricasClientes f
    LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = f.SkCliente
    LEFT JOIN Shared.DimProdutos prod ON prod.SkProduto = f.SkProduto
    LEFT JOIN DM_MetricasClientes.DimMetricas met ON met.SkMetrica = f.SkMetrica
    LEFT JOIN DM_MetricasClientes.DimTabelasConsultadas tab ON tab.SkTabelasConsultada = f.SkDimTabelasConsultadas
)
SELECT 
    -- Chaves
    SkCliente, SkProduto, SkMetrica, SkDimTabelasConsultadas,
    
    -- Informações do cliente
    SiglaCliente, NomeCliente, TipoCliente, Estado,
    
    -- Informações do produto
    NomeProduto, VersaoProduto,
    
    -- Informações da métrica
    NomeMetrica, CategoriaMetrica, DescricaoMetrica, TipoRetorno, Ordem,
    
    -- Informações da tabela consultada
    TabelaConsultada, DescricaoTabela,
    
    -- Valores (apenas um será preenchido conforme o tipo)
    ValorTexto, ValorNumerico, ValorData, ValorBooleano,
    
    -- Valor formatado para exibição
    CASE 
        WHEN TipoRetorno IN ('TEXT', 'VARCHAR', 'CHAR') THEN ValorTexto
        WHEN TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN CAST(ValorNumerico AS VARCHAR(50))
        WHEN TipoRetorno IN ('DATETIME', 'DATETIME2', 'DATE') THEN FORMAT(ValorData, 'yyyy-MM-dd HH:mm:ss')
        WHEN TipoRetorno IN ('TIME') THEN FORMAT(ValorData, 'HH:mm:ss')
        WHEN TipoRetorno IN ('BIT', 'BOOLEAN') THEN CASE WHEN ValorBooleano = 1 THEN 'Sim' ELSE 'Não' END
        ELSE 'N/A'
    END AS ValorFormatado,
    
    -- Informações temporais
    SkTempo AS DataUltimaAlteracao,
    DataProcessamento,
    DataCarga,
    DataAtualizacao,
    
    -- Versões
    VersaoCliente, VersaoSistema, VersaoMetrica
    
FROM UltimosValores
WHERE rn = 1;
GO

-- =============================================
-- VIEW 2: HISTÓRICO COMPLETO COM ANÁLISE DE MUDANÇAS
-- Retorna todo o histórico com informações de alterações
-- =============================================

CREATE OR ALTER VIEW [DM_MetricasClientes].[VwMetricasHistorico]
AS
SELECT 
    f.*,
    
    -- Dimensões desnormalizadas
    cli.SiglaCliente,
    cli.NomeCliente,
    cli.TipoCliente,
    cli.Estado,
    prod.NomeProduto,
    met.NomeMetrica,
    met.Categoria AS CategoriaMetrica,
    met.TipoRetorno,
    tab.Nome AS TabelaConsultada,
    
    -- Análise temporal (valores anteriores)
    LAG(f.ValorTexto) OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
        ORDER BY f.SkTempo
    ) AS ValorTextoAnterior,
    LAG(f.ValorNumerico) OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
        ORDER BY f.SkTempo
    ) AS ValorNumericoAnterior,
    LAG(f.ValorData) OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
        ORDER BY f.SkTempo
    ) AS ValorDataAnterior,
    LAG(f.ValorBooleano) OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
        ORDER BY f.SkTempo
    ) AS ValorBooleanoAnterior,
    
    -- Data da alteração anterior
    LAG(f.SkTempo) OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
        ORDER BY f.SkTempo
    ) AS DataAlteracaoAnterior,
    
    -- Tipo de movimento
    CASE 
        WHEN LAG(f.SkTempo) OVER (
            PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
            ORDER BY f.SkTempo
        ) IS NULL THEN 'NOVO'
        ELSE 'ALTERACAO'
    END AS TipoMovimento,
    
    -- Variação numérica (apenas para métricas numéricas)
    CASE 
        WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN
            f.ValorNumerico - LAG(f.ValorNumerico) OVER (
                PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
                ORDER BY f.SkTempo
            )
        ELSE NULL
    END AS VariacaoNumerica,
    
    -- Percentual de variação (apenas para métricas numéricas)
    CASE 
        WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') AND
             LAG(f.ValorNumerico) OVER (
                PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
                ORDER BY f.SkTempo
             ) > 0 THEN
            ((f.ValorNumerico - LAG(f.ValorNumerico) OVER (
                PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
                ORDER BY f.SkTempo
            )) / LAG(f.ValorNumerico) OVER (
                PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
                ORDER BY f.SkTempo
            )) * 100
        ELSE NULL
    END AS PercentualVariacao,
    
    -- Dias desde última alteração
    CASE 
        WHEN LAG(f.SkTempo) OVER (
            PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
            ORDER BY f.SkTempo
        ) IS NOT NULL THEN
            DATEDIFF(DAY, 
                LAG(f.SkTempo) OVER (
                    PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
                    ORDER BY f.SkTempo
                ), 
                f.SkTempo
            )
        ELSE NULL
    END AS DiasDesdeUltimaAlteracao,
    
    -- Sequência de alterações
    ROW_NUMBER() OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
        ORDER BY f.SkTempo
    ) AS NumeroSequencial,
    
    -- Total de alterações para esta combinação
    COUNT(*) OVER (
        PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas
    ) AS TotalAlteracoes
    
FROM DM_MetricasClientes.FatoMetricasClientes f
LEFT JOIN Shared.DimClientes cli ON cli.SkCliente = f.SkCliente
LEFT JOIN Shared.DimProdutos prod ON prod.SkProduto = f.SkProduto
LEFT JOIN DM_MetricasClientes.DimMetricas met ON met.SkMetrica = f.SkMetrica
LEFT JOIN DM_MetricasClientes.DimTabelasConsultadas tab ON tab.SkTabelasConsultada = f.SkDimTabelasConsultadas;
GO

-- =============================================
-- VIEW 3: RESUMO DE ATIVIDADE POR MÉTRICA
-- Estatísticas de alterações por métrica
-- =============================================

CREATE OR ALTER VIEW [DM_MetricasClientes].[VwResumoAtividadeMetricas]
AS
SELECT 
    met.NomeMetrica,
    met.Categoria AS CategoriaMetrica,
    met.TipoRetorno,
    
    -- Estatísticas gerais
    COUNT(*) AS TotalSnapshots,
    COUNT(DISTINCT f.SkCliente) AS TotalClientes,
    COUNT(DISTINCT CONCAT(f.SkCliente, '-', f.SkProduto)) AS TotalCombinacoes,
    
    -- Atividade temporal
    MIN(f.SkTempo) AS PrimeiroSnapshot,
    MAX(f.SkTempo) AS UltimoSnapshot,
    DATEDIFF(DAY, MIN(f.SkTempo), MAX(f.SkTempo)) AS DiasAtivos,
    
    -- Frequência de alterações
    CASE 
        WHEN DATEDIFF(DAY, MIN(f.SkTempo), MAX(f.SkTempo)) > 0 THEN
            CAST(COUNT(*) AS FLOAT) / DATEDIFF(DAY, MIN(f.SkTempo), MAX(f.SkTempo))
        ELSE COUNT(*)
    END AS MediaSnapshotsPorDia,
    
    -- Estatísticas de valores (apenas para métricas numéricas)
    CASE 
        WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN
            AVG(f.ValorNumerico)
        ELSE NULL
    END AS MediaValorNumerico,
    
    CASE 
        WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN
            MIN(f.ValorNumerico)
        ELSE NULL
    END AS MinValorNumerico,
    
    CASE 
        WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN
            MAX(f.ValorNumerico)
        ELSE NULL
    END AS MaxValorNumerico,
    
    -- Volatilidade (desvio padrão para métricas numéricas)
    CASE 
        WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN
            STDEV(f.ValorNumerico)
        ELSE NULL
    END AS DesvioPadraoValor,
    
    -- Última atualização
    MAX(f.DataProcessamento) AS UltimaAtualizacao
    
FROM DM_MetricasClientes.FatoMetricasClientes f
INNER JOIN DM_MetricasClientes.DimMetricas met ON met.SkMetrica = f.SkMetrica
GROUP BY 
    met.SkMetrica, met.NomeMetrica, met.Categoria, met.TipoRetorno;
GO

-- =============================================
-- VIEW 4: MÉTRICAS POR CLIENTE (VALORES ATUAIS)
-- Dashboard por cliente com todas as métricas atuais
-- =============================================

CREATE OR ALTER VIEW [DM_MetricasClientes].[VwDashboardCliente]
AS
WITH MetricasAtuais AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.SkCliente, f.SkProduto, f.SkMetrica, f.SkDimTabelasConsultadas 
            ORDER BY f.SkTempo DESC
        ) AS rn
    FROM DM_MetricasClientes.FatoMetricasClientes f
)
SELECT 
    -- Informações do cliente
    cli.SiglaCliente,
    cli.NomeCliente,
    cli.TipoCliente,
    cli.Estado,
    
    -- Informações do produto
    prod.NomeProduto,
    prod.VersaoProduto,
    
    -- Resumo de métricas
    COUNT(*) AS TotalMetricas,
    COUNT(CASE WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN 1 END) AS MetricasNumericas,
    COUNT(CASE WHEN met.TipoRetorno IN ('TEXT', 'VARCHAR', 'CHAR') THEN 1 END) AS MetricasTexto,
    COUNT(CASE WHEN met.TipoRetorno IN ('DATETIME', 'DATETIME2', 'DATE', 'TIME') THEN 1 END) AS MetricasData,
    COUNT(CASE WHEN met.TipoRetorno IN ('BIT', 'BOOLEAN') THEN 1 END) AS MetricasBooleanas,
    
    -- Atividade
    MIN(f.SkTempo) AS PrimeiraMetrica,
    MAX(f.SkTempo) AS UltimaAtualizacao,
    MAX(f.DataProcessamento) AS UltimoProcessamento,
    
    -- Categorias de métricas
    STRING_AGG(DISTINCT met.Categoria, ', ') AS CategoriasMetricas,
    
    -- Indicadores de qualidade
    COUNT(CASE WHEN f.ValorTexto IS NULL AND f.ValorNumerico IS NULL AND f.ValorData IS NULL AND f.ValorBooleano IS NULL THEN 1 END) AS MetricasVazias,
    
    -- Performance (soma de métricas numéricas como exemplo)
    SUM(CASE WHEN met.TipoRetorno IN ('DECIMAL', 'NUMERIC', 'FLOAT', 'INT', 'BIGINT') THEN f.ValorNumerico ELSE 0 END) AS SomaMetricasNumericas
    
FROM MetricasAtuais f
INNER JOIN Shared.DimClientes cli ON cli.SkCliente = f.SkCliente
INNER JOIN Shared.DimProdutos prod ON prod.SkProduto = f.SkProduto
INNER JOIN DM_MetricasClientes.DimMetricas met ON met.SkMetrica = f.SkMetrica
WHERE f.rn = 1
GROUP BY 
    cli.SkCliente, cli.SiglaCliente, cli.NomeCliente, cli.TipoCliente, cli.Estado,
    prod.SkProduto, prod.NomeProduto, prod.VersaoProduto;
GO

-- =============================================
-- PERMISSÕES
-- =============================================

GRANT SELECT ON [DM_MetricasClientes].[VwMetricasAtuais] TO [db_datareader];
GRANT SELECT ON [DM_MetricasClientes].[VwMetricasHistorico] TO [db_datareader];
GRANT SELECT ON [DM_MetricasClientes].[VwResumoAtividadeMetricas] TO [db_datareader];
GRANT SELECT ON [DM_MetricasClientes].[VwDashboardCliente] TO [db_datareader];
GO

PRINT 'Views de histórico criadas com sucesso!';
PRINT 'Views disponíveis:';
PRINT '- VwMetricasAtuais: Valores mais recentes de cada métrica';
PRINT '- VwMetricasHistorico: Histórico completo com análise de mudanças';
PRINT '- VwResumoAtividadeMetricas: Estatísticas por métrica';
PRINT '- VwDashboardCliente: Dashboard por cliente';
GO