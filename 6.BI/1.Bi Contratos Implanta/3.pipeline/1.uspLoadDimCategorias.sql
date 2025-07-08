
/*
SELECT * FROM  Shared.DimCategorias
*/

CREATE OR ALTER PROCEDURE Shared.uspLoadDimCategorias
AS
BEGIN

    BEGIN TRY

        ;WITH CategoriasStagingUnion
        AS (SELECT DISTINCT
                   Categoria,
                   1 AS SK
            FROM Staging.ClientesProdutosCIGAM
            UNION
            SELECT 'não informado' AS Categoria,
                   0 AS SK),
              CarregarDimCategorias
        AS (SELECT Categoria,
                   -1 + ROW_NUMBER() OVER (ORDER BY SK, Categoria) AS SK
            FROM CategoriasStagingUnion)
        MERGE Shared.DimCategorias AS target
        USING CarregarDimCategorias AS source
        ON target.Nome COLLATE Latin1_General_CI_AI = source.Categoria COLLATE Latin1_General_CI_AI
        WHEN MATCHED THEN
            UPDATE SET DataAtualizacao = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                SkCategoria,
                Nome,
                Ativo,
                DataAtualizacao
            )
            VALUES
            (source.SK, source.Categoria, 1, GETDATE());

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
