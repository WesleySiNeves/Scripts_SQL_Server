DECLARE @NomeTabela VARCHAR(100) = NULL; -- 'Movimentos';
DECLARE @NomeIndice VARCHAR(100) = NULL; -- 'IDX_ContabilidadeMovimento';

WITH Dados
  AS (SELECT [Schema] = SCHEMA_NAME(T.schema_id),
             OBJECT_NAME(i.object_id) TableName,
             i.name IndexName,
             c.name ColumnName,
             ic.is_included_column,
             i.index_id,
             i.type_desc,
             [Criterio de Filtro] = i.filter_definition,
             i.is_unique,
             i.fill_factor,
             i.ignore_dup_key,
             i.is_primary_key,
             i.is_unique_constraint
        FROM sys.indexes i
        JOIN sys.index_columns ic
          ON ic.object_id = i.object_id
         AND i.index_id   = ic.index_id
        JOIN sys.columns c
          ON ic.object_id = c.object_id
         AND ic.column_id = c.column_id
        JOIN sys.tables AS T
          ON T.object_id  = ic.object_id
       WHERE OBJECT_NAME(i.object_id) = ISNULL(@NomeTabela, OBJECT_NAME(i.object_id))
         AND i.name                   = ISNULL(@NomeIndice, i.name)),
     Resumo
  AS (SELECT DISTINCT R.[Schema],
             R.index_id,
             R.TableName,
             R.IndexName,
             [Colunas Chaves] = COALESCE((   SELECT CAST(O.ColumnName AS VARCHAR(200)) + ';' AS [text()]
                                               FROM Dados AS O
                                              WHERE O.is_included_column = 0
                                                AND O.IndexName          = R.IndexName
                                              ORDER BY ColumnName
                                             FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)'), ''),
             [Colunas Incluidas] = COALESCE((   SELECT CAST(O.ColumnName AS VARCHAR(200)) + ';' AS [text()]
                                                  FROM Dados AS O
                                                 WHERE O.is_included_column = 1
                                                   AND O.IndexName          = R.IndexName
                                                 ORDER BY ColumnName
                                                FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)'), ''),
             --R.ColumnName ,
             R.type_desc,
             R.[Criterio de Filtro],
             R.is_unique,
             R.fill_factor,
             R.ignore_dup_key,
             R.is_primary_key,
             R.is_unique_constraint
        FROM Dados R
       WHERE R.TableName = 'Lancamentos'
         AND R.type_desc <> 'CLUSTERED')
SELECT RE.[Schema],
       RE.index_id,
       RE.TableName,
       RE.IndexName,
       RE.[Colunas Chaves],
       RE.[Colunas Incluidas],
       RE.type_desc,
       RE.[Criterio de Filtro],
       RE.is_unique,
       RE.fill_factor,
       RE.ignore_dup_key,
       RE.is_primary_key,
       RE.is_unique_constraint
  FROM Resumo RE
 ORDER BY RE.TableName,
          RE.IndexName;


-- CREATE NONCLUSTERED INDEX IdxCLiente2 ON Bancario.Lancamentos(IdCliente) INCLUDE(Credito)