
 DECLARE @NomeTabela VARCHAR(30) = 'VwPlanoContasFinanceiro';

 WITH   Dados
          AS ( SELECT 1 AS ETabela ,
                    SCHEMA_NAME(TB.[schema_id]) AS [SCHEMA] ,
                    TB.name AS TABELA ,
                    CL.name AS COLUNA ,
                    CL.column_id AS Ordem ,
                    ( SELECT CASE WHEN C.name = CL.name THEN 1
                                  ELSE 0
                             END
                        FROM sys.indexes I
                        JOIN sys.index_columns IC ON IC.index_id = I.index_id
                                                     AND IC.[object_id] = I.[object_id]
                        JOIN sys.[columns] C ON C.column_id = IC.column_id
                                                AND C.[object_id] = IC.[object_id]
                        WHERE I.is_primary_key = 1
                            AND I.[object_id] = TB.object_id
                    ) AS PK ,
                    CL.is_nullable AS ACEITANULO ,
                    TP.name TIPO ,
                    CASE WHEN TP.name IN ( 'VARCHAR', 'CHAR' )
                              AND CL.max_length > 0
                         THEN CAST(CL.max_length AS VARCHAR)
                         WHEN TP.name IN ( 'NVARCHAR', 'NCHAR' )
                              AND CL.max_length > 0
                         THEN CAST(CL.max_length / 2 AS VARCHAR)
                         WHEN TP.name IN ( 'VARCHAR', 'CHAR' )
                              AND CL.max_length = -1 THEN 'MAX'
                         WHEN TP.name IN ( 'NVARCHAR', 'NCHAR' )
                              AND CL.max_length = -1 THEN 'MAX'
                         ELSE NULL
                    END AS TAMANHO ,
                    CL.is_computed AS CALCULADO ,
                    P.[value] AS DESCRICAO
                FROM sys.tables TB
                JOIN sys.[columns] CL ON CL.[object_id] = TB.[object_id]
                JOIN sys.types TP ON TP.system_type_id = CL.system_type_id
                LEFT JOIN sys.extended_properties AS P ON P.major_id = TB.object_id
                                                          AND P.minor_id = CL.column_id
                                                          AND P.class = 1
                                                          AND P.name = 'MS_DESCRIPTION'
               UNION ALL
               SELECT 0 AS ETabela ,
                    SCHEMA_NAME(TB.[schema_id]) AS [SCHEMA] ,
                    TB.name AS TABELA ,
                    CL.name AS COLUNA ,
                    CL.column_id AS Ordem ,
                    0 AS PK ,
                    CL.is_nullable AS ACEITANULO ,
                    TP.name TIPO ,
                    CASE WHEN TP.name IN ( 'VARCHAR', 'CHAR' )
                              AND CL.max_length > 0
                         THEN CAST(CL.max_length AS VARCHAR)
                         WHEN TP.name IN ( 'NVARCHAR', 'NCHAR' )
                              AND CL.max_length > 0
                         THEN CAST(CL.max_length / 2 AS VARCHAR)
                         WHEN TP.name IN ( 'VARCHAR', 'CHAR' )
                              AND CL.max_length = -1 THEN 'MAX'
                         WHEN TP.name IN ( 'NVARCHAR', 'NCHAR' )
                              AND CL.max_length = -1 THEN 'MAX'
                         ELSE NULL
                    END AS TAMANHO ,
                    CL.is_computed AS CALCULADO ,
                    P.[value] AS DESCRICAO
                FROM sys.views TB
                JOIN sys.[columns] CL ON CL.[object_id] = TB.[object_id]
                JOIN sys.types TP ON TP.system_type_id = CL.system_type_id
                LEFT JOIN sys.extended_properties AS P ON P.major_id = TB.object_id
                                                          AND P.minor_id = CL.column_id
                                                          AND P.class = 1
                                                          AND P.name = 'MS_DESCRIPTION'
             )
    SELECT X.ETabela ,
            X.[SCHEMA] ,
            X.TABELA ,
            X.COLUNA ,
            X.Ordem ,
            X.PK ,
            X.ACEITANULO ,
            X.TIPO ,
            X.TAMANHO ,
            X.CALCULADO ,
            CASE WHEN X.PK = 1
                 THEN LTRIM(CAST(ISNULL(X.DESCRICAO, '') AS VARCHAR)
                            + ' Campo chave para tabela [' + X.[SCHEMA]
                            + '].[' + X.TABELA + ']')
                 WHEN X.TAMANHO IS NOT NULL
                      AND X.TAMANHO <> 'MAX'
                 THEN LTRIM(CAST(ISNULL(X.DESCRICAO, '') AS VARCHAR)
                            + ' Tamanho maximo ' + CAST(X.TAMANHO AS VARCHAR)
                            + ' caracteres')
                 WHEN X.TAMANHO IS NOT NULL
                      AND X.TAMANHO = 'MAX'
                 THEN LTRIM(CAST(ISNULL(X.DESCRICAO, '') AS VARCHAR)
                            + ' Texto livre')
                 ELSE X.DESCRICAO
            END AS Descricao
        FROM Dados X
		WHERE X.TABELA = ISNULL(@NomeTabela ,X.TAMANHO)
        ORDER BY 1 ,
            2 ,
            3 ,
            5;