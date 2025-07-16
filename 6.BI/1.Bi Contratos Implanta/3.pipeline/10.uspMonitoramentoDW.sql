CREATE OR ALTER PROCEDURE DM_ContratosProdutos.uspMonitoramentoDW
AS
BEGIN
    -- Verificar última carga
    SELECT 
        'Última Carga' AS Metrica,
        MAX(DataUltimaAtualizacao) AS Valor
    FROM DM_ContratosProdutos.FatoContratosProdutos;
    
    -- Verificar crescimento dos dados
    SELECT 
        'Total Contratos' AS Metrica,
        COUNT(*) AS Valor
    FROM DM_ContratosProdutos.FatoContratosProdutos;
END;