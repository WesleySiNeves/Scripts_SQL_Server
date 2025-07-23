

--CREATE OR ALTER PROCEDURE Shared.uspLoadDimProdutos
--AS
--BEGIN

--    BEGIN TRY

        -- Tabela temporária para dados de produtos
        DROP TABLE IF EXISTS #DadosProdutos;
        CREATE TABLE #DadosProdutos
        (
            [IdProduto] UNIQUEIDENTIFIER,
			[SkProduto] SMALLINT,
            [DescricaoCigam] VARCHAR(250),
            [DescricaoImplanta] VARCHAR(250),
            [Area] VARCHAR(50),
            [Ativo] BIT
        );

		INSERT INTO #DadosProdutos
		    (
		        IdProduto,
		        SkProduto,
		        DescricaoCigam,
		        DescricaoImplanta,
		        Area,
		        Ativo
		    )
		
		SELECT IdSistema,
               NumeroSistema,
               NULL,
			   Descricao,
               Area,
			   Ativo FROM Implanta.Sistemas
			   
			   
			   DROP TABLE IF EXISTS #DadosProdutosCigam;

				  CREATE TABLE #DadosProdutosCigam
				  (
				  [DescricaoCigam] VARCHAR(100)
				  )
			

        -- ETAPA 1: Carregar dados de produtos do staging
        INSERT INTO #DadosProdutosCigam
        (
            [DescricaoCigam]
        )
        SELECT DISTINCT
               Descricao
        FROM Staging.ClientesProdutosCIGAM;

		
		 UPDATE source SET source.DescricaoCigam =x.DescricaoCigam FROM #DadosProdutos source
			OUTER APPLY
			(
			SELECT TOP 1 DescricaoCigam  FROM #DadosProdutosCigam
			WHERE REPLACE(DescricaoCigam,'.NET','') LIKE '%'+ REPLACE(source.DescricaoImplanta,'.NET','')
			) X

		SELECT * FROM #DadosProdutos
		WHERE DescricaoCigam IS NULL
		SELECT * FROM #DadosProdutosCigam
		
        -- ETAPA 2: Mapear descrições CIGAM para descrições Implanta que ainda estão NULL
        -- Estratégia 1: Busca por correspondência exata (case insensitive)
        UPDATE source 
        SET source.DescricaoCigam = cigam.DescricaoCigam 
        FROM #DadosProdutos source
        INNER JOIN #DadosProdutosCigam cigam 
            ON UPPER(LTRIM(RTRIM(source.DescricaoImplanta))) = UPPER(LTRIM(RTRIM(cigam.DescricaoCigam)))
        WHERE source.DescricaoCigam IS NULL
          AND source.DescricaoImplanta IS NOT NULL;

        -- Estratégia 2: Busca por correspondência parcial (contém a descrição)
        UPDATE source 
        SET source.DescricaoCigam = x.DescricaoCigam 
        FROM #DadosProdutos source
        OUTER APPLY (
            SELECT TOP 1 cigam.DescricaoCigam
            FROM #DadosProdutosCigam cigam
            WHERE UPPER(REPLACE(cigam.DescricaoCigam, '.NET', '')) LIKE '%' + UPPER(REPLACE(source.DescricaoImplanta, '.NET', '')) + '%'
               OR UPPER(REPLACE(source.DescricaoImplanta, '.NET', '')) LIKE '%' + UPPER(REPLACE(cigam.DescricaoCigam, '.NET', '')) + '%'
            ORDER BY LEN(cigam.DescricaoCigam) -- Prioriza descrições mais curtas (mais específicas)
        ) x
        WHERE source.DescricaoCigam IS NULL
          AND source.DescricaoImplanta IS NOT NULL
          AND x.DescricaoCigam IS NOT NULL;

        -- Estratégia 3: Busca por palavras-chave principais
        UPDATE source 
        SET source.DescricaoCigam = x.DescricaoCigam 
        FROM #DadosProdutos source
        OUTER APPLY (
            SELECT TOP 1 cigam.DescricaoCigam
            FROM #DadosProdutosCigam cigam
            WHERE EXISTS (
                -- Verifica se pelo menos uma palavra significativa coincide
                SELECT 1 
                FROM STRING_SPLIT(REPLACE(REPLACE(source.DescricaoImplanta, '.NET', ''), '.', ' '), ' ') palavra_implanta
                INNER JOIN STRING_SPLIT(REPLACE(REPLACE(cigam.DescricaoCigam, '.NET', ''), '.', ' '), ' ') palavra_cigam
                    ON UPPER(LTRIM(RTRIM(palavra_implanta.value))) = UPPER(LTRIM(RTRIM(palavra_cigam.value)))
                WHERE LEN(LTRIM(RTRIM(palavra_implanta.value))) >= 3 -- Ignora palavras muito pequenas
                  AND UPPER(LTRIM(RTRIM(palavra_implanta.value))) NOT IN ('NET', 'COM', 'APP', 'WEB', 'API')
            )
            ORDER BY LEN(cigam.DescricaoCigam)
        ) x
        WHERE source.DescricaoCigam IS NULL
          AND source.DescricaoImplanta IS NOT NULL
          AND x.DescricaoCigam IS NOT NULL;

        -- Estratégia 4: Para registros ainda sem associação, usar a primeira disponível como fallback
        UPDATE source 
        SET source.DescricaoCigam = x.DescricaoCigam 
        FROM #DadosProdutos source
        OUTER APPLY (
            SELECT TOP 1 cigam.DescricaoCigam
            FROM #DadosProdutosCigam cigam
            ORDER BY cigam.DescricaoCigam
        ) x
        WHERE source.DescricaoCigam IS NULL
          AND source.DescricaoImplanta IS NOT NULL
          AND x.DescricaoCigam IS NOT NULL;

        -- Log dos resultados do mapeamento
        DECLARE @TotalRegistros INT = (SELECT COUNT(*) FROM #DadosProdutos WHERE DescricaoImplanta IS NOT NULL);
        DECLARE @RegistrosMapeados INT = (SELECT COUNT(*) FROM #DadosProdutos WHERE DescricaoCigam IS NOT NULL AND DescricaoImplanta IS NOT NULL);
        DECLARE @RegistrosNaoMapeados INT = (SELECT COUNT(*) FROM #DadosProdutos WHERE DescricaoCigam IS NULL AND DescricaoImplanta IS NOT NULL);
        
        PRINT 'Resultado do mapeamento:';
        PRINT '- Total de registros: ' + CAST(@TotalRegistros AS VARCHAR(10));
        PRINT '- Registros mapeados: ' + CAST(@RegistrosMapeados AS VARCHAR(10));
        PRINT '- Registros não mapeados: ' + CAST(@RegistrosNaoMapeados AS VARCHAR(10));
        
        -- Mostrar registros que ainda não foram mapeados para análise
        IF @RegistrosNaoMapeados > 0
        BEGIN
            PRINT 'Registros não mapeados:';
            SELECT DescricaoImplanta, Area 
            FROM #DadosProdutos 
            WHERE DescricaoCigam IS NULL AND DescricaoImplanta IS NOT NULL;
        END
        
        -- Mostrar algumas descrições CIGAM disponíveis para referência
        PRINT 'Descrições CIGAM disponíveis:';
        SELECT TOP 10 DescricaoCigam FROM #DadosProdutosCigam ORDER BY DescricaoCigam;

        -- ETAPA 3: Enriquecer dados com informações dos sistemas
        UPDATE target
        SET target.IdProduto = se.IdSistema,
            target.Area = se.Area,
            target.Ativo = se.Ativo
        FROM #DadosProdutos target
            JOIN Implanta.Sistemas se
                ON target.DescricaoImplanta = se.Descricao COLLATE Latin1_General_CI_AI;

UPDATE #DadosProdutos SET SkProduto =TRY_CAST(REPLACE(CAST(IdProduto AS VARCHAR(60)),'-','') AS INT )
			
		

DECLARE @maxnumero INT =
            (
                SELECT
                    MAX(SkProduto)
                FROM
                    #DadosProdutos
            );


-- ETAPA 4: Tratar produtos não categorizados 
; WITH DadosNaoCategorizados
AS (   SELECT
           SkProduto          = ROW_NUMBER() OVER (ORDER BY
                                                       R.DescricaoCigam
                                                  ) + @maxnumero,
           R.DescricaoCigam,
           'Não categorizado' AS Area,
           1                  AS Ativo
       FROM
           #DadosProdutos R
       WHERE
           R.DescricaoImplanta IS NULL),
		   GerarSequencial AS (
		   
SELECT
    R.SkProduto,
    IdProduto = CAST('00000000-0000-0000-0000-' + RIGHT('000000000000' + CAST(R.SkProduto AS VARCHAR(12)), 12) AS UNIQUEIDENTIFIER),
    R.DescricaoCigam,
    R.Area,
    R.Ativo
FROM
    DadosNaoCategorizados R		   
		   )

UPDATE source SET source.IdProduto =seq.IdProduto,
  source.SkProduto =seq.SkProduto,
  source.Area =seq.Area,
  source.Ativo =seq.Ativo
		FROM  #DadosProdutos source
		JOIN GerarSequencial seq ON seq.DescricaoCigam = source.DescricaoCigam


INSERT INTO  #DadosProdutos
    (
        IdProduto,
        SkProduto,
        DescricaoCigam,
        DescricaoImplanta,
        Area,
        Ativo
    )
VALUES
    (
      
        '00000000-0000-0000-0000-000000000000', -- IdProduto - uniqueidentifier 
		  0, -- SkProduto - smallint
        'Global', -- DescricaoCigam - varchar(250)
        'Global', -- DescricaoImplanta - varchar(250)
        'Não categorizado', -- Area - varchar(50)
        1  -- Ativo - bit
    )


     
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
			SkProduto,
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
			dp.SkProduto,
            ISNULL(dp.DescricaoImplanta,dp.DescricaoCigam) AS DescricaoImplanta,
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
