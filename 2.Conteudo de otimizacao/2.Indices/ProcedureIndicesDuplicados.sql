


IF (OBJECT_ID('TEMPDB..#ValidacaoIndices') IS NOT NULL)
    DROP TABLE #ValidacaoIndices;

CREATE TABLE #ValidacaoIndices 
(
	NomeBanco VARCHAR(128),
    [index_id] INT NOT NULL,
    [object_id] INT NOT NULL,
    [TableName] sysname NULL,
    [TypeIndex] TINYINT NOT NULL,
    [IndexName] sysname NULL,
    [Colunas Chaves] NVARCHAR(200) NULL,
    [Colunas Incluidas] NVARCHAR(MAX) NULL,
    [type_desc] NVARCHAR(60) NULL,
    [Criterio de Filtro] NVARCHAR(MAX) NULL,
    [is_unique] BIT NULL,
    [fill_factor] TINYINT NOT NULL,
    [ignore_dup_key] BIT NULL,
    [is_primary_key] BIT NULL,
    [is_unique_constraint] BIT NULL, );



CREATE NONCLUSTERED INDEX IxTemp
ON #ValidacaoIndices (TableName, IndexName, [Colunas Chaves]);


DECLARE @NomeTabela VARCHAR(100) = NULL; -- 'Movimentos';
DECLARE @NomeIndice VARCHAR(100) = NULL; -- 'IDX_ContabilidadeMovimento';

WITH Dados
  AS (SELECT [TableName] = CONCAT(SCHEMA_NAME(T.schema_id), '.', OBJECT_NAME(i.object_id)),
             i.object_id,
             i.type,
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
             i.is_unique_constraint,
			 Banco = DB_NAME(DB_ID())
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
         AND i.name                   = ISNULL(@NomeIndice, i.name)
		 ),
     Resumo
  AS (SELECT DISTINCT R.index_id,
  R.Banco,
             R.object_id,
             R.TableName,
             R.IndexName,
             R.type,
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
             R.type_desc,
             R.[Criterio de Filtro],
             R.is_unique,
             R.fill_factor,
             R.ignore_dup_key,
             R.is_primary_key,
             R.is_unique_constraint
        FROM Dados R
     --WHERE R.type_desc <> 'CLUSTERED'
     )
INSERT INTO #ValidacaoIndices ( NomeBanco,
								index_id,
                               object_id,
                               TableName,
                               TypeIndex,
                               IndexName,
                               [Colunas Chaves],
                               [Colunas Incluidas],
                               type_desc,
                               [Criterio de Filtro],
                               is_unique,
                               fill_factor,
                               ignore_dup_key,
                               is_primary_key,
                               is_unique_constraint)
SELECT  RE.Banco,
		RE.index_id,
       RE.object_id,
       RE.TableName,
       RE.type,
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



SELECT RE.NomeBanco, 
       RE.index_id,
       RE.TableName,
       RE.IndexName,
       RE.TypeIndex,
       RE.[Colunas Chaves],
       RE.[Colunas Incluidas],
       RE.type_desc,
       RE.is_unique,
       RE.fill_factor,
       RE.is_primary_key,
       RE.is_unique_constraint,
       [Ordem] = ROW_NUMBER() OVER (PARTITION BY RE.TableName ORDER BY RE.TableName)
  FROM #ValidacaoIndices AS RE
 WHERE EXISTS (   SELECT 1
                    FROM #ValidacaoIndices A
                   WHERE A.TableName        = RE.TableName
                     AND A.IndexName        <> RE.IndexName
                     AND A.[Colunas Chaves] = RE.[Colunas Chaves])
   AND RE.TableName = ISNULL(@NomeTabela, RE.TableName)
 ORDER BY RE.TableName,
          RE.TypeIndex;

