-- =============================================
-- SCRIPT: Carga de Produtos Implanta
-- DESCRIÇÃO: Script para carregar dados de produtos/sistemas na tabela Implanta.Produtos
-- AUTOR: Wesley
-- DATA: [Data atual]
-- =============================================

CREATE OR ALTER PROCEDURE Shared.uspLoadDimProdutos
AS
BEGIN

    BEGIN TRY


        -- Limpar tabelas temporárias se existirem
        DROP TABLE IF EXISTS #DadosSigam;

        -- Criar tabela temporária com dados do SIGAM
        CREATE TABLE #DadosSigam
        (
            [Modulo] VARCHAR(60),
            [Codigo_Modulo] VARCHAR(20)
        );

        -- Inserir dados do SIGAM
        INSERT INTO #DadosSigam
        (
            [Modulo],
            [Codigo_Modulo]
        )
        SELECT DISTINCT
               DescricaoProdutoSigam,
               CodigoProdutoSigam
        FROM Staging.ClientesProdutosCIGAM;



        -- MERGE usando dados da tabela Implanta.Sistemas (CORRIGIDO)
        MERGE INTO Implanta.Produtos AS target
        USING Implanta.Sistemas AS source
        ON target.IdProduto = source.IdSistema
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                IdProduto,
                NumeroProduto,
                DescricaoProduto,
                Area,
                Ativo,
                DataCriacao,
                DataAtualizacao
            )
            VALUES
            (source.IdSistema, source.NumeroSistema, source.Descricao, source.Area, source.Ativo, GETDATE(), GETDATE())
        WHEN MATCHED THEN
            UPDATE SET NumeroProduto = source.NumeroSistema,
                       DescricaoProduto = source.Descricao,
                       Area = source.Area,
                       Ativo = source.Ativo,
                       DataAtualizacao = GETDATE();

        -- Atualizar informações do SIGAM - Match exato
        UPDATE target
        SET target.DescricaoProdutoSigam = source.Modulo,
            target.CodigoProdutoSigam = source.Codigo_Modulo,
            target.DataAtualizacao = GETDATE()
        FROM Implanta.Produtos AS target
            JOIN #DadosSigam source
                ON target.DescricaoProduto = source.Modulo
        WHERE target.CodigoProdutoSigam IS NULL;

        -- Atualizar informações do SIGAM - Match com normalização de texto
        UPDATE target
        SET target.DescricaoProdutoSigam = source.Modulo,
            target.CodigoProdutoSigam = source.Codigo_Modulo,
            target.DataAtualizacao = GETDATE()
        FROM Implanta.Produtos AS target
            JOIN #DadosSigam source
                ON REPLACE(REPLACE(REPLACE(target.DescricaoProduto, '.NET', ''), 'ção', 'cao'), ' & ', ' E ') = REPLACE(
                                                                                                                           source.Modulo,
                                                                                                                           '.NET',
                                                                                                                           ''
                                                                                                                       )
        WHERE target.CodigoProdutoSigam IS NULL;

        -- Atualizar informações do SIGAM - Match com normalização alternativa
        UPDATE target
        SET target.DescricaoProdutoSigam = source.Modulo,
            target.CodigoProdutoSigam = source.Codigo_Modulo,
            target.DataAtualizacao = GETDATE()
        FROM Implanta.Produtos AS target
            JOIN #DadosSigam source
                ON REPLACE(REPLACE(REPLACE(target.DescricaoProduto, '.NET', ''), 'ção', 'cao'), ' & ', '&') = REPLACE(
                                                                                                                         source.Modulo,
                                                                                                                         '.NET',
                                                                                                                         ''
                                                                                                                     )
        WHERE target.CodigoProdutoSigam IS NULL;

        -- Atualizar informações do SIGAM - Match parcial com LIKE
        UPDATE target
        SET target.DescricaoProdutoSigam = source.Modulo,
            target.CodigoProdutoSigam = source.Codigo_Modulo,
            target.DataAtualizacao = GETDATE()
        FROM Implanta.Produtos AS target
            JOIN #DadosSigam source
                ON target.DescricaoProduto LIKE REPLACE(source.Modulo, '.NET', '') + '%'
        WHERE target.CodigoProdutoSigam IS NULL;

        -- Atualizar produtos sem correspondência no SIGAM
        UPDATE target
        SET target.DescricaoProdutoSigam = target.DescricaoProduto,
            target.CodigoProdutoSigam = CAST(target.NumeroProduto AS VARCHAR(20)),
            target.DataAtualizacao = GETDATE()
        FROM Implanta.Produtos AS target
        WHERE target.CodigoProdutoSigam IS NULL;

        -- Inserir novos produtos do SIGAM que não existem na tabela Implanta.Produtos
        IF EXISTS
        (
            SELECT *
            FROM #DadosSigam
            WHERE Codigo_Modulo NOT IN
                  (
                      SELECT CodigoProdutoSigam
                      FROM Implanta.Produtos
                      WHERE CodigoProdutoSigam IS NOT NULL
                  )
        )
        BEGIN
            -- Declarar variável para o próximo ID sequencial
            DECLARE @maxId INT =
                    (
                        SELECT ISNULL(MAX(NumeroProduto), 0)
                        FROM Implanta.Produtos
                        WHERE NumeroProduto < 99
                    );

            -- Inserir novos produtos do SIGAM
            INSERT INTO Implanta.Produtos
            (
                IdProduto,
                NumeroProduto,
                DescricaoProduto,
                Ativo,
                Area,
                DescricaoProdutoSigam,
                CodigoProdutoSigam,
                DataCriacao,
                DataAtualizacao
            )
            SELECT CONVERT(
                              UNIQUEIDENTIFIER,
                              -- Primeira parte: converte o número sequencial para hexadecimal de 8 dígitos
                              RIGHT('00000000'
                                    + CONVERT(
                                                 VARCHAR(8),
                                                 CONVERT(
                                                            VARBINARY(4),
                                                            ROW_NUMBER() OVER (ORDER BY Codigo_Modulo) + @maxId
                                                        ),
                                                 2
                                             ), 8) +
                              -- Partes fixas do GUID
                              '-0000-0000-0000-'
                              +
                              -- Última parte: número sequencial com zeros à esquerda (12 dígitos)
                              RIGHT('000000000000'
                                    + CAST(ROW_NUMBER() OVER (ORDER BY Codigo_Modulo) + @maxId AS VARCHAR(12)), 12)
                          ) AS IdProduto,
                   ROW_NUMBER() OVER (ORDER BY Codigo_Modulo) + @maxId AS NumeroProduto,
                   Modulo AS DescricaoProduto,
                   1 AS Ativo,
                   'Não Categorizado' AS Area,
                   Modulo AS DescricaoProdutoSigam,
                   Codigo_Modulo AS CodigoProdutoSigam,
                   GETDATE() AS DataCriacao,
                   GETDATE() AS DataAtualizacao
            FROM #DadosSigam
            WHERE Codigo_Modulo NOT IN
                  (
                      SELECT CodigoProdutoSigam
                      FROM Implanta.Produtos
                      WHERE CodigoProdutoSigam IS NOT NULL
                  );

            -- Sincronizar dados com a dimensão Shared.DimProdutos
            MERGE INTO Shared.DimProdutos AS target
            USING Implanta.Produtos AS source
            ON source.CodigoProdutoSigam = target.CodigoProdutoCigam
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    SkProduto,
                    IdProduto,
                    DescricaoProdutoCigam,
                    CodigoProdutoCigam,
                    DescricaoProdutoImplanta,
                    Area,
                    Ativo,
                    DataInicioVersao,
                    DataFimVersao,
                    VersaoAtual,
                    DataCarga,
                    DataAtualizacao
                )
                VALUES
                (source.NumeroProduto, source.IdProduto, source.DescricaoProdutoSigam, source.CodigoProdutoSigam,
                 source.DescricaoProduto, source.Area, source.Ativo, GETDATE(), NULL, 1, GETDATE(), NULL)
            WHEN MATCHED AND (
                                 source.DescricaoProduto <> target.DescricaoProdutoImplanta
                                 OR source.CodigoProdutoSigam <> target.DescricaoProdutoCigam
                                 OR source.Area <> target.Area
                                 OR source.Ativo <> target.Ativo
                             ) THEN
                UPDATE SET DescricaoProdutoCigam = source.DescricaoProdutoSigam,
                           CodigoProdutoCigam = source.CodigoProdutoSigam,
                           DescricaoProdutoImplanta = source.DescricaoProduto,
                           Area = source.Area,
                           Ativo = source.Ativo,
                           DataAtualizacao = GETDATE();
        END;

        -- Relatório final de estatísticas
        SELECT 'Produtos Implanta' AS Tabela,
               COUNT(*) AS TotalRegistros,
               SUM(   CASE
                          WHEN CodigoProdutoSigam IS NOT NULL THEN
                              1
                          ELSE
                              0
                      END
                  ) AS ComCodigoSigam,
               SUM(   CASE
                          WHEN CodigoProdutoSigam IS NULL THEN
                              1
                          ELSE
                              0
                      END
                  ) AS SemCodigoSigam
        FROM Implanta.Produtos
        UNION ALL
        SELECT 'DimProdutos' AS Tabela,
               COUNT(*) AS TotalRegistros,
               SUM(   CASE
                          WHEN CodigoProdutoCigam IS NOT NULL THEN
                              1
                          ELSE
                              0
                      END
                  ) AS ComCodigoSigam,
               SUM(   CASE
                          WHEN CodigoProdutoCigam IS NULL THEN
                              1
                          ELSE
                              0
                      END
                  ) AS SemCodigoSigam
        FROM Shared.DimProdutos;

        -- Limpeza das tabelas temporárias
        DROP TABLE IF EXISTS #DadosSigam;


    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'Erro na carga da DimProdutos: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;

END;


--SELECT * FROM Implanta.Produtos
--SELECT * FROM Shared.DimProdutos