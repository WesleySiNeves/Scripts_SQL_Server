
CREATE OR ALTER PROCEDURE DM_ContratosProdutos.uspInsertUpdateDw
AS
BEGIN
    BEGIN TRY
        -- Executar todas as dimensões em ordem de dependência
        EXEC Shared.uspLoadDimTempo;
        EXEC Shared.uspLoadDimCategorias;
        EXEC Shared.uspLoadDimProdutos;
        EXEC Shared.uspLoadDimClientes;
        EXEC DM_ContratosProdutos.uspLoadDimensionTypes;
        
        -- Por último, carregar a tabela fato
        EXEC DM_ContratosProdutos.uspLoadFatoContratosProdutos;
        
        PRINT 'Pipeline ETL executado com sucesso!';
        
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

GO


