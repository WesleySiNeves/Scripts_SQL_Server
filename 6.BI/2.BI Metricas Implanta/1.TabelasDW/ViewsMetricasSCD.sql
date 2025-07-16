-- View para consultar apenas versões atuais
CREATE OR ALTER VIEW [Staging].[VwMetricasAtuais]
AS
SELECT 
    Cliente,
    CodSistema,
    Ordem,
    NomeMetrica,
    TipoRetorno,
    TabelaConsultada,
    Valor,
    DataCarga,
    DataProcessamento,
    DataInicioVersao
FROM Staging.MetricasClientes
WHERE VersaoAtual = 1;
GO

-- View para histórico completo
CREATE OR ALTER VIEW [Staging].[VwMetricasHistorico]
AS
SELECT 
    Cliente,
    CodSistema,
    Ordem,
    NomeMetrica,
    TipoRetorno,
    TabelaConsultada,
    Valor,
    DataCarga,
    DataProcessamento,
    VersaoAtual,
    DataInicioVersao,
    DataFimVersao,
    CASE 
        WHEN VersaoAtual = 1 THEN 'Atual'
        ELSE 'Histórico'
    END AS StatusVersao
FROM Staging.MetricasClientes;
GO

-- View para análise de mudanças
CREATE OR ALTER VIEW [Staging].[VwMetricasMudancas]
AS
SELECT 
    Cliente,
    CodSistema,
    Ordem,
    NomeMetrica,
    COUNT(*) AS TotalVersoes,
    MIN(DataInicioVersao) AS PrimeiraVersao,
    MAX(DataInicioVersao) AS UltimaVersao,
    MAX(CASE WHEN VersaoAtual = 1 THEN Valor END) AS ValorAtual
FROM Staging.MetricasClientes
GROUP BY Cliente, CodSistema, Ordem, NomeMetrica
HAVING COUNT(*) > 1; -- Apenas métricas que mudaram
GO