CREATE OR ALTER PROCEDURE [Staging].[uspLoadMetricasSCD]
    @DadosADF NVARCHAR(MAX) -- JSON com os dados do ADF
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Criar tabela temporária com os dados do ADF
        CREATE TABLE #DadosADF (
            Cliente           VARCHAR(20),
            CodSistema        TINYINT,
            Ordem             TINYINT,
            NomeMetrica       VARCHAR(50),
            TipoRetorno       VARCHAR(20),
            TabelaConsultada  VARCHAR(128),
            Valor             VARCHAR(MAX),
            HashValor         VARBINARY(32)
        );
        
        -- 2. Popular tabela temporária (assumindo que os dados vêm via parâmetro ou tabela temporária)
        -- Aqui você adaptaria para receber os dados do ADF
        INSERT INTO #DadosADF (Cliente, CodSistema, Ordem, NomeMetrica, TipoRetorno, TabelaConsultada, Valor, HashValor)
        SELECT 
            Cliente,
            CodSistema,
            Ordem,
            NomeMetrica,
            TipoRetorno,
            TabelaConsultada,
            Valor,
            HASHBYTES('SHA2_256', ISNULL(Valor, '')) AS HashValor -- Hash para comparação rápida
        FROM OPENJSON(@DadosADF) WITH (
            Cliente           VARCHAR(20)  '$.Cliente',
            CodSistema        TINYINT      '$.CodSistema',
            Ordem             TINYINT      '$.Ordem',
            NomeMetrica       VARCHAR(50)  '$.NomeMetrica',
            TipoRetorno       VARCHAR(20)  '$.TipoRetorno',
            TabelaConsultada  VARCHAR(128) '$.TabelaConsultada',
            Valor             VARCHAR(MAX) '$.Valor'
        );
        
        -- 3. Identificar registros que mudaram (comparação por hash)
        WITH RegistrosAlterados AS (
            SELECT 
                adf.*,
                stg.Cliente AS ClienteExistente,
                stg.HashValor AS HashExistente
            FROM #DadosADF adf
            LEFT JOIN Staging.MetricasClientes stg ON (
                stg.Cliente = adf.Cliente
                AND stg.CodSistema = adf.CodSistema
                AND stg.Ordem = adf.Ordem
                AND stg.NomeMetrica = adf.NomeMetrica
                AND stg.VersaoAtual = 1 -- Apenas versão atual
            )
        )
        
        -- 4. Fechar versões antigas (quando valor mudou)
        UPDATE Staging.MetricasClientes 
        SET 
            VersaoAtual = 0,
            DataFimVersao = GETDATE()
        FROM Staging.MetricasClientes stg
        INNER JOIN RegistrosAlterados ra ON (
            stg.Cliente = ra.Cliente
            AND stg.CodSistema = ra.CodSistema
            AND stg.Ordem = ra.Ordem
            AND stg.NomeMetrica = ra.NomeMetrica
            AND stg.VersaoAtual = 1
            AND stg.HashValor != ra.HashValor -- Valor mudou
        );
        
        -- 5. Inserir novas versões (registros novos + registros alterados)
        INSERT INTO Staging.MetricasClientes (
            Cliente, CodSistema, Ordem, NomeMetrica, TipoRetorno, 
            TabelaConsultada, Valor, DataCarga, DataProcessamento,
            VersaoAtual, DataInicioVersao, DataFimVersao, HashValor
        )
        SELECT 
            ra.Cliente,
            ra.CodSistema,
            ra.Ordem,
            ra.NomeMetrica,
            ra.TipoRetorno,
            ra.TabelaConsultada,
            ra.Valor,
            GETDATE() AS DataCarga,
            GETDATE() AS DataProcessamento,
            1 AS VersaoAtual,
            GETDATE() AS DataInicioVersao,
            NULL AS DataFimVersao,
            ra.HashValor
        FROM RegistrosAlterados ra
        WHERE 
            ra.ClienteExistente IS NULL  -- Registro novo
            OR ra.HashExistente != ra.HashValor; -- Valor mudou
        
        -- 6. Atualizar registros inalterados (apenas timestamp)
        UPDATE Staging.MetricasClientes 
        SET 
            DataProcessamento = GETDATE()
        FROM Staging.MetricasClientes stg
        INNER JOIN RegistrosAlterados ra ON (
            stg.Cliente = ra.Cliente
            AND stg.CodSistema = ra.CodSistema
            AND stg.Ordem = ra.Ordem
            AND stg.NomeMetrica = ra.NomeMetrica
            AND stg.VersaoAtual = 1
            AND stg.HashValor = ra.HashValor -- Valor não mudou
        );
        
        COMMIT TRANSACTION;
        
        -- Log de auditoria
        PRINT 'SCD Tipo 2 aplicado com sucesso na tabela Staging.MetricasClientes';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- Conceder permissões
GRANT EXECUTE ON [Staging].[uspLoadMetricasSCD] TO [db_datawriter];
GO