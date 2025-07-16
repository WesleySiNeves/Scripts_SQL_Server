CREATE OR ALTER PROCEDURE Shared.uspLoadDimProdutos
AS
BEGIN

    BEGIN TRY

        -- Tabela temporária para dados de produtos
        DROP TABLE IF EXISTS #DadosProdutos;
        CREATE TABLE #DadosProdutos
        (
            [IdProduto] UNIQUEIDENTIFIER,
            [DescricaoCigam] VARCHAR(250),
            [DescricaoImplanta] VARCHAR(250),
            [Area] VARCHAR(50),
            [Ativo] BIT
        );

        -- ETAPA 1: Carregar dados de produtos do staging
        INSERT INTO #DadosProdutos
        (
            [DescricaoCigam]
        )
        SELECT DISTINCT
               Descricao
        FROM Staging.ClientesProdutosCIGAM;

        -- ETAPA 2: Mapear descrições CIGAM para descrições Implanta
        UPDATE target
        SET target.DescricaoImplanta = se.Descricao
        FROM #DadosProdutos target
            JOIN Implanta.Sistemas se
                ON target.DescricaoCigam = se.Descricao;

        UPDATE target
        SET target.DescricaoImplanta = se.Descricao
        FROM #DadosProdutos target
            JOIN Implanta.Sistemas se
                ON se.Descricao LIKE CONCAT('%', target.DescricaoCigam, '%')
        WHERE target.DescricaoCigam <> 'SISCAF'
              AND target.DescricaoImplanta IS NULL;

        UPDATE target
        SET target.DescricaoImplanta = se.Descricao
        FROM #DadosProdutos target
            JOIN Implanta.Sistemas se
                ON REPLACE(target.DescricaoCigam, '.NET', '') = se.Descricao
        WHERE DescricaoImplanta IS NULL;

        UPDATE target
        SET target.DescricaoImplanta =
            (
                SELECT TOP 1
                       s.Descricao
                FROM Implanta.Sistemas s
                WHERE s.Descricao LIKE CONCAT('%', target.DescricaoCigam, '%')
            )
        FROM #DadosProdutos target
        WHERE target.DescricaoImplanta IS NULL
              AND target.DescricaoCigam <> 'SISCAF';

        UPDATE target
        SET target.DescricaoImplanta =
            (
                SELECT TOP 1
                       s.Descricao
                FROM Implanta.Sistemas s
                WHERE s.Descricao LIKE '%PROGRAMAS%'
            )
        FROM #DadosProdutos target
        WHERE target.DescricaoCigam = 'PROGRAMAS&PROJETOS';

        UPDATE target
        SET target.DescricaoImplanta =
            (
                SELECT TOP 1
                       s.Descricao
                FROM Implanta.Sistemas s
                WHERE s.Descricao LIKE '%Compras%'
            )
        FROM #DadosProdutos target
        WHERE target.DescricaoCigam LIKE '%Compras%';

        UPDATE target
        SET target.DescricaoImplanta =
            (
                SELECT TOP 1
                       s.Descricao
                FROM Implanta.Sistemas s
                WHERE s.Descricao LIKE '%FISCALIZA%'
            )
        FROM #DadosProdutos target
        WHERE target.DescricaoCigam LIKE '%FISCALIZA%';




        -- ETAPA 3: Enriquecer dados com informações dos sistemas
        UPDATE target
        SET target.IdProduto = se.IdSistema,
            target.Area = se.Area,
            target.Ativo = se.Ativo
        FROM #DadosProdutos target
            JOIN Implanta.Sistemas se
                ON target.DescricaoImplanta = se.Descricao COLLATE Latin1_General_CI_AI;

        -- ETAPA 4: Tratar produtos não categorizados
        WITH DadosNaoCategorizados
        AS (SELECT 
                   IdProduto = NEWID(),
                   R.DescricaoCigam,
                   'Não categorizado' AS Area,
                   1 AS Ativo
            FROM #DadosProdutos R
            WHERE R.DescricaoImplanta IS NULL)
        UPDATE target
        SET target.IdProduto = source.IdProduto,
            target.DescricaoImplanta = source.DescricaoCigam,
            target.Area = source.Area,
            target.Ativo = source.Ativo
        FROM #DadosProdutos target
            JOIN DadosNaoCategorizados source
                ON source.DescricaoCigam = target.DescricaoCigam;

        -- ETAPA 5: Identificar registros que sofreram alterações (SCD Tipo 2)
        DROP TABLE IF EXISTS #ProdutosAlterados;
        CREATE TABLE #ProdutosAlterados
        (
            IdProduto UNIQUEIDENTIFIER,
            SkProdutoAtual INT
        );

        INSERT INTO #ProdutosAlterados (IdProduto, SkProdutoAtual)
        SELECT 
            dp.IdProduto,
            dim.SkProduto
        FROM #DadosProdutos dp
        INNER JOIN Shared.DimProdutos dim 
            ON dp.IdProduto = dim.IdProduto 
            AND dim.VersaoAtual = 1
        WHERE 
            -- Campos monitorados para mudanças
            ISNULL(dp.DescricaoImplanta, '') <> ISNULL(dim.DescricaoImplanta, '')
            OR ISNULL(dp.Area, '') <> ISNULL(dim.Area, '')
            OR ISNULL(dp.Ativo, 0) <> ISNULL(dim.Ativo, 0);

        -- ETAPA 6: Fechar versões antigas (definir DataFimVersao e VersaoAtual = 0)
        UPDATE Shared.DimProdutos
        SET 
            DataFimVersao = GETDATE(),
            VersaoAtual = 0
        WHERE SkProduto IN (SELECT SkProdutoAtual FROM #ProdutosAlterados);

        -- ETAPA 7: Inserir novas versões para registros alterados
        INSERT INTO Shared.DimProdutos
        (
            IdProduto,
            DescricaoImplanta,
            DescricaoCigam,
            Area,
            Ativo,
            DataInicioVersao,
            DataFimVersao,
            VersaoAtual,
            DataCarga,
            DataAtualizacao
        )
        SELECT 
            dp.IdProduto,
            dp.DescricaoImplanta,
            dp.DescricaoCigam,
            dp.Area,
            dp.Ativo,
            GETDATE() AS DataInicioVersao,
            NULL AS DataFimVersao,
            1 AS VersaoAtual,
            GETDATE() AS DataCarga,
            GETDATE() AS DataAtualizacao
        FROM #DadosProdutos dp
        INNER JOIN #ProdutosAlterados pa ON dp.IdProduto = pa.IdProduto;

        -- ETAPA 8: Inserir novos produtos
        INSERT INTO Shared.DimProdutos
        (
            IdProduto,
            DescricaoImplanta,
            DescricaoCigam,
            Area,
            Ativo,
            DataInicioVersao,
            DataFimVersao,
            VersaoAtual,
            DataCarga,
            DataAtualizacao
        )
        SELECT 
            dp.IdProduto,
            dp.DescricaoImplanta,
            dp.DescricaoCigam,
            dp.Area,
            dp.Ativo,
            GETDATE() AS DataInicioVersao,
            NULL AS DataFimVersao,
            1 AS VersaoAtual,
            GETDATE() AS DataCarga,
            GETDATE() AS DataAtualizacao
        FROM #DadosProdutos dp
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Shared.DimProdutos dim 
            WHERE dim.IdProduto = dp.IdProduto
        );

        -- ETAPA 9: Atualizar DataAtualizacao para registros inalterados
        UPDATE Shared.DimProdutos
        SET DataAtualizacao = GETDATE()
        WHERE VersaoAtual = 1
          AND IdProduto IN (SELECT IdProduto FROM #DadosProdutos)
          AND IdProduto NOT IN (SELECT IdProduto FROM #ProdutosAlterados);

        PRINT 'Carga da DimProdutos (SCD Tipo 2) concluída em: ' + CONVERT(VARCHAR, GETDATE(), 120);

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Erro na carga da DimProdutos: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

END;
