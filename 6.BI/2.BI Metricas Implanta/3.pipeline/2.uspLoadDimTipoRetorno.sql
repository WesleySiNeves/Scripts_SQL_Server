-- =============================================
-- Procedure: uspLoadDimTipoRetorno
-- Descrição: Carga da dimensão DimTipoRetorno (dimensão simples)
-- Autor: Sistema
-- Data: 2024
-- =============================================

CREATE OR ALTER PROCEDURE [DM_MetricasClientes].[uspLoadDimTipoRetorno]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DataProcessamento DATETIME2(2) = GETDATE();
    DECLARE @RowsAffected INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Usar MERGE para sincronizar a dimensão
        WITH StagingData AS (
            SELECT DISTINCT
                TipoRetorno,
                CASE TipoRetorno
                    WHEN 'INT' THEN 'Valores numéricos inteiros'
                    WHEN 'DECIMAL' THEN 'Valores numéricos decimais'
                    WHEN 'VARCHAR' THEN 'Valores de texto'
                    WHEN 'DATETIME' THEN 'Valores de data e hora'
                    WHEN 'DATE' THEN 'Valores de data'
                    WHEN 'BIT' THEN 'Valores booleanos (Sim/Não)'
                    WHEN 'FLOAT' THEN 'Valores numéricos de ponto flutuante'
                    ELSE CONCAT('Tipo de retorno: ', TipoRetorno)
                END AS Descricao
            FROM [Staging].[MetricasClientes]
            WHERE TipoRetorno IS NOT NULL
              AND LTRIM(RTRIM(TipoRetorno)) <> ''
        )
        
        MERGE [DM_MetricasClientes].[DimTipoRetorno] AS target
        USING StagingData AS source
        ON target.TipoRetorno = source.TipoRetorno
        
        -- Atualizar registros existentes
        WHEN MATCHED AND (
            ISNULL(target.Descricao, '') <> ISNULL(source.Descricao, '')
        ) THEN
            UPDATE SET
                Descricao = source.Descricao,
                DataAtualizacao = @DataProcessamento
        
        -- Inserir novos registros
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                TipoRetorno,
                Descricao,
                Ativo,
                DataCarga,
                DataAtualizacao
            )
            VALUES (
                source.TipoRetorno,
                source.Descricao,
                1,
                @DataProcessamento,
                @DataProcessamento
            )
        
        -- Desativar registros que não existem mais no staging
        WHEN NOT MATCHED BY SOURCE AND target.Ativo = 1 THEN
            UPDATE SET
                Ativo = 0,
                DataAtualizacao = @DataProcessamento;
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- Atualizar DataAtualizacao para registros inalterados
        UPDATE [DM_MetricasClientes].[DimTipoRetorno]
        SET DataAtualizacao = @DataProcessamento
        WHERE TipoRetorno IN (
            SELECT DISTINCT TipoRetorno 
            FROM [Staging].[MetricasClientes]
            WHERE TipoRetorno IS NOT NULL
        )
        AND Ativo = 1;
        
        COMMIT TRANSACTION;
        
        PRINT CONCAT('uspLoadDimTipoRetorno executada com sucesso. Registros afetados: ', @RowsAffected);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT CONCAT('Erro na uspLoadDimTipoRetorno: ', @ErrorMessage);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Conceder permissões
GRANT EXECUTE ON [DM_MetricasClientes].[uspLoadDimTipoRetorno] TO [db_executor];
GO