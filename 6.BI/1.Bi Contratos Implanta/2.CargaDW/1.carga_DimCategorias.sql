DELETE FROM
       [Shared].[DimCategorias];
-- Para que o primeiro registro tenha ID = 0


IF (NOT EXISTS
    (
        SELECT
            *
        FROM
            [Shared].[DimCategorias]
        WHERE
            Nome = 'Não informado'
    )
   )
    BEGIN
        INSERT INTO [Shared].[DimCategorias]
            (
                SkCategoria,
                [Nome],
                [Ativo],
                [DataCarga],
                [DataAtualizacao]
            )
                    SELECT
                        *
                    FROM
                        (
                            VALUES
                                (
                                    0,
									'Não informado', -- Nome - varchar(100)
                                    1,                  -- Ativo - bit
                                    GETDATE(),          -- DataCarga - datetime2(2)
                                    GETDATE()           -- DataAtualizacao - datetime2(2)
                                )
                        ) AS X ([SkCategoria],[Nome], [Ativo], [DataCarga], [DataAtualizacao]);


    END;

