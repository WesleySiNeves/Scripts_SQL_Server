
CREATE OR ALTER PROCEDURE Shared.uspLoadDimClientes
AS
BEGIN

    BEGIN TRY

        DROP TABLE IF EXISTS #DadosCLientes;

        CREATE TABLE #DadosCLientes
        (
            [IdCliente] UNIQUEIDENTIFIER,
            [SkConselhoFederal] SMALLINT,
            [NomeCliente] VARCHAR(8000),
            [SiglaCliente] VARCHAR(30),
            [UF] VARCHAR(30),
            [TipoCliente] VARCHAR(8),
            [Ativo] INT,
            [IdConselhoFederal] UNIQUEIDENTIFIER,
            [SiglaConselhoRegional] VARCHAR(250),
            [SiglaFederal] VARCHAR(50)
        );

        DROP TABLE IF EXISTS #DadosClientesNaoIndenticados;

        CREATE TABLE #DadosClientesNaoIndenticados
        (
            [IdCliente] UNIQUEIDENTIFIER,
            [SkConselhoFederal] SMALLINT,
            [NomeCliente] VARCHAR(8000),
            [SiglaCliente] VARCHAR(30),
            [SiglaSemUF] VARCHAR(30),
            [UF] VARCHAR(30),
            [TipoCliente] VARCHAR(8),
            [Ativo] INT,
            [IdConselhoFederal] UNIQUEIDENTIFIER,
            [SiglaConselhoRegional] VARCHAR(250),
            [SiglaFederal] VARCHAR(50)
        );


        ;WITH ClientesUnicos
        AS (SELECT DISTINCT
                   Categoria,
                   SiglaCliente
            FROM Staging.ClientesProdutosCIGAM),
              ClientesOLTP
        AS (SELECT c.IdCliente,
                   c.IdConselhoFederal,
                   cfed.SkConselhoFederal,
                   NomeCliente = REPLACE(
                                            REPLACE(REPLACE(c.Nome, 'Cons.', 'Conselho'), 'Reg.', 'Regional'),
                                            'Med.',
                                            'Medicina'
                                        ),
                   c.SiglaConselhoRegional,
                   cfed.Sigla AS SiglaFederal,
                   cfed.SkCategoria
            FROM Implanta.Clientes c
                JOIN Shared.DimConselhosFederais cfed
                    ON cfed.IdConselhoFederal = c.IdConselhoFederal),
              CorrigirNomesERecuperarUF
        AS (SELECT vinculo.IdCliente,
                   vinculo.SkConselhoFederal,
                   REPLACE(
                              REPLACE(REPLACE(vinculo.NomeCliente, 'Cons.', 'Conselho'), 'Reg.', 'Regional'),
                              'Med.',
                              'Medicina'
                          ) AS NomeCliente,
                   Uni.SiglaCliente,
                   UF = CASE
                            WHEN CHARINDEX('/', Uni.SiglaCliente) = 0 THEN
                                'BR'
                            WHEN CHARINDEX('/', Uni.SiglaCliente) > 0 THEN
                                SUBSTRING(Uni.SiglaCliente, CHARINDEX('/', Uni.SiglaCliente) + 1)
                        END,
                   CASE
                       WHEN vinculo.NomeCliente LIKE '%conselho%'
                            OR vinculo.NomeCliente LIKE 'CR%' THEN
                           'Conselho'
                       ELSE
                           NULL
                   END AS TipoCliente,
                   vinculo.IdConselhoFederal,
                   vinculo.SiglaConselhoRegional,
                   vinculo.SiglaFederal
            FROM ClientesUnicos Uni
                LEFT JOIN ClientesOLTP vinculo
                    ON Uni.SiglaCliente = vinculo.SiglaConselhoRegional)
        INSERT INTO #DadosCLientes
        (
            IdCliente,
            SkConselhoFederal,
            NomeCliente,
            SiglaCliente,
            UF,
            TipoCliente,
            Ativo,
            IdConselhoFederal,
            SiglaConselhoRegional,
            SiglaFederal
        )
        SELECT cli.IdCliente,
               cli.SkConselhoFederal,
               cli.NomeCliente,
               cli.SiglaCliente,
               cli.UF,
               cli.TipoCliente,
               1 AS Ativo,
               cli.IdConselhoFederal,
               cli.SiglaConselhoRegional,
               cli.SiglaFederal
        FROM CorrigirNomesERecuperarUF cli;


        WITH ClientesNovos
        AS (SELECT IdCliente,
                   SkConselhoFederal,
                   NomeCliente,
                   SiglaCliente,
                   SiglaSemUF = IIF(CHARINDEX('/', SiglaCliente) = 0,
                                    SiglaCliente,
                                    SUBSTRING(SiglaCliente, 0, CHARINDEX('/', SiglaCliente))),
                   UF,
                   TipoCliente,
                   Ativo,
                   IdConselhoFederal,
                   SiglaConselhoRegional,
                   SiglaFederal
            FROM #DadosCLientes
            WHERE NomeCliente IS NULL)
        INSERT INTO #DadosClientesNaoIndenticados
        (
            IdCliente,
            SkConselhoFederal,
            NomeCliente,
            SiglaCliente,
            SiglaSemUF,
            UF,
            TipoCliente,
            Ativo,
            IdConselhoFederal,
            SiglaConselhoRegional,
            SiglaFederal
        )
        SELECT R.IdCliente,
               R.SkConselhoFederal,
               R.NomeCliente,
               R.SiglaCliente,
               R.SiglaSemUF,
               R.UF,
               R.TipoCliente,
               R.Ativo,
               R.IdConselhoFederal,
               R.SiglaConselhoRegional,
               R.SiglaFederal
        FROM ClientesNovos R;


        ;WITH MapeamentoDados
        AS (SELECT NEWID() AS IdCliente,
                   Vinculo.SkConselhoFederal,
                   CONCAT(SUBSTRING(Vinculo.NomeCliente, 0, CHARINDEX('/', Vinculo.NomeCliente)), '/', base.UF) AS Nome,
                   base.SiglaCliente,
                   base.UF,
                   Vinculo.TipoCliente,
                   base.Ativo,
                   Vinculo.IdConselhoFederal,
                   Vinculo.SiglaFederal
            FROM #DadosClientesNaoIndenticados base
                OUTER APPLY
            (
                SELECT TOP 1
                       SkConselhoFederal,
                       NomeCliente,
                       TipoCliente,
                       IdConselhoFederal,
                       SiglaConselhoRegional,
                       SiglaFederal
                FROM #DadosCLientes
                WHERE NomeCliente IS NOT NULL
                      AND SiglaConselhoRegional LIKE base.SiglaSemUF + '%'
            ) AS Vinculo )
        UPDATE TARGET
        SET TARGET.SkConselhoFederal = SOURCE.SkConselhoFederal,
            TARGET.NomeCliente = SOURCE.Nome,
            TARGET.TipoCliente = SOURCE.TipoCliente,
            TARGET.IdConselhoFederal = SOURCE.IdConselhoFederal,
            TARGET.SiglaFederal = SOURCE.SiglaFederal,
            TARGET.IdCliente = NEWID()
        FROM #DadosCLientes TARGET
            JOIN MapeamentoDados AS SOURCE
                ON TARGET.SiglaCliente = SOURCE.SiglaCliente
        WHERE TARGET.NomeCliente IS NULL;



        MERGE Shared.DimClientes AS target
        USING #DadosCLientes AS source
        ON target.Sigla = source.SiglaCliente COLLATE Latin1_General_CI_AI
        WHEN MATCHED THEN
            UPDATE SET target.Nome = source.NomeCliente,
                       target.DataAtualizacao = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                IdCliente,
                SkConselhoFederal,
                Nome,
                Sigla,
                Estado,
                TipoCliente,
                Ativo,
                DataCarga,
                DataAtualizacao
            )
            VALUES
            (source.IdCliente, source.SkConselhoFederal, source.NomeCliente, source.SiglaCliente, source.UF,
             source.TipoCliente, source.Ativo, GETDATE(), GETDATE());



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
