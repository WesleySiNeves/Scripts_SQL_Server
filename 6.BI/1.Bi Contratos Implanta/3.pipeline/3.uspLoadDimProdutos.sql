CREATE OR ALTER PROCEDURE Shared.uspLoadDimProdutos
AS
BEGIN
    DROP TABLE IF EXISTS #Dados;
    CREATE TABLE #Dados
    (
        [SkProduto] TINYINT,
        [IdProduto] UNIQUEIDENTIFIER,
        [DescricaoCigam] VARCHAR(250),
        [DescricaoImplanta] VARCHAR(250),
        [Area] VARCHAR(50),
        [Ativo] BIT,
        [DataCarga] DATETIME2(2),
        [DataAtualizacao] DATETIME2(2)
    );

    INSERT INTO #Dados
    (
        [DescricaoCigam]
    )
    SELECT DISTINCT
           Descricao
    FROM Staging.ClientesProdutosCIGAM;


    UPDATE target
    SET target.DescricaoImplanta = se.Descricao
    FROM #Dados target
        JOIN Implanta.Sistemas se
            ON target.DescricaoCigam = se.Descricao;

    UPDATE target
    SET target.DescricaoImplanta = se.Descricao
    --SELECT target.DescricaoCigam,se.*
    FROM #Dados target
        JOIN Implanta.Sistemas se
            ON se.Descricao LIKE CONCAT('%', target.DescricaoCigam, '%')
    WHERE target.DescricaoCigam <> 'SISCAF'
          AND target.DescricaoImplanta IS NULL;



    UPDATE target
    SET target.DescricaoImplanta = se.Descricao
    FROM #Dados target
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
    FROM #Dados target
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
    FROM #Dados target
    WHERE target.DescricaoCigam = 'PROGRAMAS&PROJETOS';


    UPDATE target
    SET target.DescricaoImplanta =
        (
            SELECT TOP 1
                   s.Descricao
            FROM Implanta.Sistemas s
            WHERE s.Descricao LIKE '%Compras%'
        )
    FROM #Dados target
    WHERE target.DescricaoCigam LIKE '%Compras%';



    UPDATE target
    SET target.DescricaoImplanta =
        (
            SELECT TOP 1
                   s.Descricao
            FROM Implanta.Sistemas s
            WHERE s.Descricao LIKE '%FISCALIZA%'
        )
    FROM #Dados target
    WHERE target.DescricaoCigam LIKE '%FISCALIZA%';




    UPDATE target
    SET target.IdProduto = se.IdSistema,
        target.SkProduto = se.NumeroSistema,
        target.Area = se.Area,
        target.Ativo = se.Ativo,
        target.DataAtualizacao = GETDATE()
    FROM #Dados target
        JOIN Implanta.Sistemas se
            ON DescricaoImplanta = se.Descricao COLLATE Latin1_General_CI_AI;




    DECLARE @MaxId INT =
            (
                SELECT MAX(SkProduto)FROM #Dados
            );
    WITH DadosNaoCategorizados
    AS (SELECT SK = ROW_NUMBER() OVER (ORDER BY R.DescricaoCigam) + @MaxId,
               IdProduto = CAST(CONCAT(
                                          '00000000-0000-0000-0000-',
                                          RIGHT('000000000000'
                                                + CAST(ROW_NUMBER() OVER (ORDER BY R.DescricaoCigam) + @MaxId AS VARCHAR(12)), 12)
                                      ) AS UNIQUEIDENTIFIER),
               R.DescricaoCigam,
               'Não categorizado' AS Area,
               1 AS Ativo
        FROM #Dados R
        WHERE DescricaoImplanta IS NULL)
    UPDATE target
    SET target.SkProduto = source.SK,
        target.IdProduto = source.IdProduto,
        target.DescricaoImplanta = source.DescricaoCigam,
        target.Area = source.Area,
        target.Ativo = source.Ativo,
        target.DataCarga = GETDATE(),
        target.DataAtualizacao = GETDATE()
    FROM #Dados target
        JOIN DadosNaoCategorizados source
            ON source.DescricaoCigam = target.DescricaoCigam;


    MERGE Shared.DimProdutos AS target
    USING #Dados AS source
    ON target.DescricaoImplanta = source.DescricaoImplanta COLLATE Latin1_General_CI_AI
    WHEN MATCHED THEN
        UPDATE SET DataAtualizacao = GETDATE(),
                   Area = target.Area,
                   target.Ativo = target.Ativo
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            SkProduto,
            IdProduto,
            DescricaoImplanta,
            DescricaoCigam,
            Area,
            Ativo,
            DataCarga,
            DataAtualizacao
        )
        VALUES
        (source.SkProduto, source.IdProduto, source.DescricaoImplanta, source.DescricaoCigam, source.Area,
         source.Ativo, GETDATE(), GETDATE());


    -- Log de execução (opcional)
    PRINT 'Carga da DimSistemas concluída em: ' + CONVERT(VARCHAR, GETDATE(), 120);

END;
