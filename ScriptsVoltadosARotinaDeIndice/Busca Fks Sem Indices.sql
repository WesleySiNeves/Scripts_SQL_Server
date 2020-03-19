WITH Dados
  AS (SELECT [Object Id Tabela] = o.object_id,
             [Schema] = SCHEMA_NAME(fk.schema_id),
             [Tabela] = OBJECT_NAME(o.object_id),
             [foreign_key_no_index] = fk.name,
             [ObjectIdFK] = fk.object_id,
             fk.referenced_object_id,
             [IdColuna] = fkc.parent_column_id,
             [Coluna Nao Indexada] = C.name
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc
          ON fk.referenced_object_id = fkc.referenced_object_id
         AND fk.parent_object_id     = fkc.parent_object_id
       INNER JOIN sys.objects o
          ON o.object_id             = fk.parent_object_id
       INNER JOIN sys.schemas s
          ON s.schema_id             = o.schema_id
        JOIN sys.tables AS T
          ON T.object_id             = o.object_id
        JOIN sys.columns AS C
          ON T.object_id             = C.object_id
         AND C.column_id             = fkc.parent_column_id
       WHERE o.is_ms_shipped = 0
         AND NOT EXISTS (   SELECT *
                              FROM sys.index_columns ic
                             WHERE EXISTS (   SELECT *
                                                FROM sys.foreign_key_columns fkc
                                               WHERE fkc.constraint_object_id = fk.object_id
                                                 AND fkc.parent_object_id     = ic.object_id
                                                 AND fkc.parent_column_id     = ic.column_id)
                             GROUP BY ic.index_id
                            HAVING COUNT(*) = MAX(ic.index_column_id)
                               AND COUNT(*) = (   SELECT COUNT(*)
                                                    FROM sys.foreign_key_columns fkc
                                                   WHERE fkc.constraint_object_id = fk.object_id))),
     Resumo
  AS (SELECT R.[Object Id Tabela],
             R.[Schema],
             R.Tabela,
             R.foreign_key_no_index,
             R.ObjectIdFK,
             R.IdColuna,
             R.[Coluna Nao Indexada],
             [Nome Indice] = CONCAT('Idx', R.[Schema], R.Tabela, R.[Coluna Nao Indexada])
        FROM Dados R),
     SegundoResumo
  AS (SELECT R.[Object Id Tabela],
             R.[Schema],
             R.Tabela,
             R.foreign_key_no_index,
             R.ObjectIdFK,
             R.IdColuna,
             R.[Coluna Nao Indexada],
             R.[Nome Indice],
             [Tamanho Letras Indices] = LEN(R.[Nome Indice]),
             [Script Criacao Indice] = CONCAT(
                                           'CREATE NONCLUSTERED  INDEX',
                                           SPACE(2),
                                           R.[Nome Indice],
                                           SPACE(2),
                                           'ON',
                                           SPACE(2),
                                           R.[Schema],
                                           '.',
                                           R.Tabela,
                                           '(',
                                           R.[Coluna Nao Indexada],
                                           ')')
        FROM Resumo R
       WHERE LEN(R.[Nome Indice]) < 128)
SELECT DISTINCT R.[Script Criacao Indice]
  FROM SegundoResumo R;




