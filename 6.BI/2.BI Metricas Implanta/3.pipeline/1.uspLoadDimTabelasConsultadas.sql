
CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspLoadDimTabelasConsultadas]
AS
    BEGIN
        SET NOCOUNT ON;
        ;WITH DataSource
        AS (   SELECT DISTINCT
                      TabelaConsultada,
                      1         AS Ativo,
                      GETDATE() AS DataCarga
               FROM
                      Staging.MetricasClientes
               WHERE
                      LEN(RTRIM(LTRIM(TabelaConsultada))) > 0)
        MERGE DM_MetricasClientes.DimTabelasConsultadas AS target
        USING DataSource AS source
        ON source.TabelaConsultada = target.Nome
        WHEN NOT MATCHED
            THEN INSERT
                     (
                         Nome,
                         Ativo,
                         DataCarga
                     )
                 VALUES
                     (
                         source.TabelaConsultada, source.Ativo, source.DataCarga
                     );
    END;