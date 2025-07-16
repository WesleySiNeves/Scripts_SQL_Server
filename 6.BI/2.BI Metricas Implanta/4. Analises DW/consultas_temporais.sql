-- Evolução de uma métrica ao longo do tempo
SELECT 
    dc.NomeCliente,
    dm.NomeMetrica,
    f.DataSnapshot,
    f.ValorNumerico,
    f.VersaoCliente,
    f.VersaoMetrica
FROM DM_MetricasClientes.FatoMetricasClientes f
INNER JOIN DM_MetricasClientes.DimClientes dc ON f.SkCliente = dc.SkCliente
INNER JOIN DM_MetricasClientes.DimMetricas dm ON f.SkMetrica = dm.SkMetrica
WHERE dc.CodigoCliente = 'CRO-SP'
  AND dm.NomeMetrica = 'QtdAcessos'
ORDER BY f.DataSnapshot;

-- Comparação entre períodos
WITH MetricasAtual AS (
    SELECT SkCliente, SkMetrica, ValorNumerico
    FROM DM_MetricasClientes.FatoMetricasClientes
    WHERE DataSnapshot = CAST(GETDATE() AS DATE)
),
MetricasAnterior AS (
    SELECT SkCliente, SkMetrica, ValorNumerico
    FROM DM_MetricasClientes.FatoMetricasClientes
    WHERE DataSnapshot = CAST(DATEADD(MONTH, -1, GETDATE()) AS DATE)
)
SELECT 
    dc.NomeCliente,
    dm.NomeMetrica,
    ma.ValorNumerico AS ValorAtual,
    man.ValorNumerico AS ValorAnterior,
    ma.ValorNumerico - man.ValorNumerico AS Variacao
FROM MetricasAtual ma
INNER JOIN MetricasAnterior man ON ma.SkCliente = man.SkCliente AND ma.SkMetrica = man.SkMetrica
INNER JOIN DM_MetricasClientes.DimClientes dc ON ma.SkCliente = dc.SkCliente AND dc.VersaoAtual = 1
INNER JOIN DM_MetricasClientes.DimMetricas dm ON ma.SkMetrica = dm.SkMetrica AND dm.VersaoAtual = 1;