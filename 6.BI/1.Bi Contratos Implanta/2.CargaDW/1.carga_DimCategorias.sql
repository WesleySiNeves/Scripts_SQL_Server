DELETE FROM [Shared].[DimCategorias]
-- Para que o primeiro registro tenha ID = 0

DBCC CHECKIDENT ('[Shared].[DimCategorias]', RESEED, -1);

INSERT INTO [Shared].[DimCategorias]
(
    [Nome],
    [Ativo],
    [DataCarga],
    [DataAtualizacao]
)
SELECT *
FROM
(
    VALUES
        (   'Não informado', -- Nome - varchar(100)
            1,               -- Ativo - bit
            GETDATE(),       -- DataCarga - datetime2(2)
            GETDATE()        -- DataAtualizacao - datetime2(2)
        )
) AS X ([Nome], [Ativo], [DataCarga], [DataAtualizacao]);


INSERT INTO [Shared].[DimCategorias]
(
    [Nome],
    [Ativo],
    [DataCarga],
    [DataAtualizacao]
)
SELECT DISTINCT
       Categoria,
       1,
       GETDATE() AS [DataCarga],
       GETDATE() AS [DataAtualizacao]
FROM Staging.ClientesProdutosCIGAM
WHERE Categoria IS NOT NULL;



SELECT * FROM [Shared].[DimCategorias]