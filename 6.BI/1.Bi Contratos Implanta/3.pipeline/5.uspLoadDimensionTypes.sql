CREATE OR ALTER PROCEDURE DM_ContratosProdutos.uspLoadDimensionTypes
AS
BEGIN

    BEGIN TRY

	

        MERGE DM_ContratosProdutos.DimTipoContratos AS target
        USING
        (SELECT DISTINCT Tipo FROM Staging.ClientesProdutosCIGAM) AS source
        ON target.Nome = source.Tipo COLLATE Latin1_General_CI_AI
        WHEN MATCHED THEN
            UPDATE SET target.DataAtualizacao = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                Nome,
                DataCarga,
                DataAtualizacao
            )
            VALUES
            (source.Tipo, GETDATE(), GETDATE());

			

        MERGE DM_ContratosProdutos.DimTipoSituacaoContratos AS target
        USING
        (SELECT DISTINCT Situacao FROM Staging.ClientesProdutosCIGAM) AS source
        ON source.Situacao = target.Nome
        WHEN MATCHED THEN
            UPDATE SET target.DataAtualizacao = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                Nome,
                DataCarga,
                DataAtualizacao
            )
            VALUES
            (source.Situacao, GETDATE(), GETDATE());

			

        MERGE DM_ContratosProdutos.DimTiposSituacaoFinanceira AS target
        USING
        (
            SELECT DISTINCT
                   SituacaoFinanceira
            FROM Staging.ClientesProdutosCIGAM
        ) AS source
        ON source.SituacaoFinanceira = target.Nome
        WHEN MATCHED THEN
            UPDATE SET target.DataAtualizacao = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                Nome,
                DataCarga,
                DataAtualizacao
            )
            VALUES
            (source.SituacaoFinanceira, GETDATE(), GETDATE());




    END TRY
    BEGIN CATCH
        -- Tratamento de erros melhorado
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();

        -- Log detalhado do erro
        PRINT '========== ERRO NA EXECUÇÃO DA PROCEDURE ==========';
        PRINT 'Procedure: ' + ISNULL(@ErrorProcedure, 'uspInsertUpdateDw');
        PRINT 'Número do Erro: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Linha do Erro: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT 'Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(MAX));
        PRINT 'Estado: ' + CAST(@ErrorState AS VARCHAR(MAX));

        PRINT '==================================================';

        -- Re-lança o erro para o cliente
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    END CATCH;
END;
