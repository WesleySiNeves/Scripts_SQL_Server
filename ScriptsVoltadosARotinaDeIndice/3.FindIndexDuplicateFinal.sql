DECLARE @tabela VARCHAR(300) = NULL; -- 'Sistema.ArquivosAnexos'; --'Pessoas';
DECLARE @NomeIndice VARCHAR(300) = NULL; -- 'IX_Liquidacoes_IdEmpenho'; --'IX_ArquivosAnexos_IdEntidadeEntidade';

IF(OBJECT_ID('TEMPDB..#DadosTabela') IS NOT NULL)
    DROP TABLE #DadosTabela;

IF(OBJECT_ID('TEMPDB..#DadosIndices') IS NOT NULL)
    DROP TABLE #DadosIndices;

IF(OBJECT_ID('TEMPDB..#IndicesDuplicados') IS NOT NULL)
    DROP TABLE #IndicesDuplicados;

CREATE TABLE #IndicesDuplicados
(
    [Tabela]               VARCHAR(200),
    [object_id]            INT,
    [index_id]             INT,
    [name]                 NVARCHAR(128),
    [Fisrt Key Columns]    NVARCHAR(128),
    [Demais Colluns keys]  NVARCHAR(4000),
    [Include Coluns]       NVARCHAR(4000),
    [Total Colunas chaves] INT,
    [type_desc]            NVARCHAR(60),
    [is_unique]            BIT,
    [is_primary_key]       BIT,
    [is_unique_constraint] BIT,
    [key_ordinal]          TINYINT
);

CREATE TABLE #DadosIndices
(
    [object_id]            INT,
    [index_id]             INT,
    [Id]                   INT,
    [name]                 NVARCHAR(128),
    [type]                 TINYINT,
    [type_desc]            NVARCHAR(60),
    [is_unique]            BIT,
    [is_primary_key]       BIT,
    [is_unique_constraint] BIT,
    [index_column_id]      INT,
    [column_id]            INT,
    [key_ordinal]          TINYINT,
    [is_included_column]   BIT,
    [Nome Coluna]          NVARCHAR(128),
    [Posicao Coluna]       INT
);

CREATE TABLE #DadosTabela
(
    Tabela          VARCHAR(200),
    object_id       BIGINT,
    name            VARCHAR(300),
    column_id       INT,
    Type            VARCHAR(200),
    max_length      INT,
    collation_name  VARCHAR(200),
    is_nullable     BIT,
    is_rowguidcol   BIT,
    IsDeterministic BIT
);

WITH DadoTabelaCampos
    AS
    (
        SELECT [Tabela] = CONCAT(SCHEMA_NAME(T.schema_id), '.', T.name),
               C.object_id,
               C.name,
               C.column_id,
               [Type] = T2.name,
               C.max_length,
               C.collation_name,
               C.is_nullable,
               C.is_rowguidcol,
               CAST(ISNULL(COLUMNPROPERTY(C.object_id, C.name, N'IsDeterministic'), 0) AS BIT) AS [IsDeterministic]
          FROM sys.tables AS T
               JOIN sys.columns AS C
                    JOIN sys.types AS T2 ON C.system_type_id = T2.system_type_id ON T.object_id = C.object_id
         WHERE
            (
                @tabela IS NULL
                OR CONCAT(SCHEMA_NAME(T.schema_id), '.', T.name) = @tabela
            )
    )
INSERT INTO #DadosTabela SELECT * FROM DadoTabelaCampos R;

WITH Indices
    AS
    (
        SELECT I.object_id,
               I.index_id,
               [Id] = (CASE IC.key_ordinal WHEN 0 THEN IC.index_column_id ELSE IC.key_ordinal END),
               I.name,
               I.type,
               I.type_desc,
               I.is_unique,
               I.is_primary_key,
               I.is_unique_constraint,
               IC.index_column_id,
               IC.column_id,
               IC.key_ordinal,
               IC.is_included_column,
               [Nome Coluna] = clmns.name,
               [Posicao Coluna] = clmns.column_id
          FROM sys.tables AS tbl
               INNER JOIN sys.indexes I ON(I.object_id = tbl.object_id)
                                          AND (I.index_id > 0)
               JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                               AND I.index_id = IC.index_id
               JOIN sys.columns AS clmns ON clmns.object_id = IC.object_id
                                            AND clmns.column_id = IC.column_id
    )
INSERT INTO #DadosIndices SELECT * FROM Indices;

WITH Resumo
    AS
    (
        SELECT DI.object_id,
               DI.index_id,
               --   DI.Id,
               DI.name,
               [Fisrt Key Columns] = (
                                         SELECT DI2.[Nome Coluna]
                                           FROM #DadosIndices AS DI2
                                          WHERE
                                             DI2.object_id = DI.object_id
                                             AND DI2.index_id = DI.index_id
                                             AND DI2.key_ordinal = 1
                                     ),
               [Demais Colluns keys] = (
                                           SELECT STRING_AGG(DI2.[Nome Coluna], ',')
                                             FROM #DadosIndices AS DI2
                                            WHERE
                                               DI2.object_id = DI.object_id
                                               AND DI2.index_id = DI.index_id
                                               AND DI2.index_column_id > 1
                                               AND DI2.is_included_column = 0
                                       ),
               [Include Coluns] = (
                                      SELECT STRING_AGG(DI2.[Nome Coluna], ',')
                                        FROM #DadosIndices AS DI2
                                       WHERE
                                          DI2.object_id = DI.object_id
                                          AND DI2.index_id = DI.index_id
                                          AND DI2.index_column_id > 1
                                          AND DI2.is_included_column = 1
                                  ),
               [Total Colunas chaves] = (
                                            SELECT COUNT(*)
                                              FROM #DadosIndices AS DI2
                                             WHERE
                                                DI2.object_id = DI.object_id
                                                AND DI2.index_id = DI.index_id
                                                AND DI2.index_column_id > 1
                                        ),
               DI.type_desc,
               DI.is_unique,
               DI.is_primary_key,
               DI.is_unique_constraint,
               DI.key_ordinal
          FROM #DadosIndices AS DI
         WHERE
            (
                @tabela IS NULL
                OR DI.object_id = OBJECT_ID(@tabela, 'U')
            )
            AND DI.key_ordinal = 1
    )
INSERT INTO #IndicesDuplicados(
                                  Tabela,
                                  object_id,
                                  index_id,
                                  name,
                                  [Fisrt Key Columns],
                                  [Demais Colluns keys],
                                  [Include Coluns],
                                  [Total Colunas chaves],
                                  type_desc,
                                  is_unique,
                                  is_primary_key,
                                  is_unique_constraint,
                                  key_ordinal
                              )
SELECT DT.Tabela,
       R.*
  FROM Resumo R
       JOIN #DadosTabela AS DT ON R.object_id = DT.object_id
                                  AND R.[Fisrt Key Columns] = DT.name
       JOIN(
               SELECT DI.object_id,
                      DI.[Nome Coluna],
                      [Total] = COUNT(*)
                 FROM #DadosIndices AS DI
                WHERE
                   DI.key_ordinal = 1
                GROUP BY
                   DI.object_id,
                   DI.[Nome Coluna]
               HAVING
                   COUNT(*) > 1
           ) AS DUP ON R.object_id = DUP.object_id
                       AND DUP.[Nome Coluna] = R.[Fisrt Key COLUMNS]
                       AND DT.Tabela NOT LIKE '%HangFire%';

IF(OBJECT_ID('TEMPDB..#AllNonClusterIndex') IS NOT NULL)
    DROP TABLE #AllNonClusterIndex;

CREATE TABLE #AllNonClusterIndex
(
    [SchemaName]   NVARCHAR(128),
    [Table_name]   NVARCHAR(128),
    OBject_Id      BIGINT,
    [index_id]     INT,
    [Index_name]   NVARCHAR(128),
    [user_seeks]   BIGINT,
    [user_scans]   BIGINT,
    [user_updates] BIGINT,
    total_used     BIGINT
);

INSERT INTO #AllNonClusterIndex(
                                   SchemaName,
                                   Table_name,
                                   OBject_Id,
                                   index_id,
                                   Index_name,
                                   user_seeks,
                                   user_scans,
                                   user_updates,
                                   total_used
                               )
SELECT S.name SchemaName,
       T.name AS Table_name,
       T.object_id,
       indexes.index_id,
       indexes.name AS Index_name,
       SUM(dm_db_index_usage_stats.user_seeks) user_seeks,
       SUM(dm_db_index_usage_stats.user_scans) user_scans,
       SUM(dm_db_index_usage_stats.user_updates) user_updates,
       total_used = SUM(dm_db_index_usage_stats.user_seeks + dm_db_index_usage_stats.user_scans + dm_db_index_usage_stats.user_updates)
  FROM sys.dm_db_index_usage_stats
       INNER JOIN sys.tables AS T ON T.object_id = dm_db_index_usage_stats.object_id
       JOIN sys.schemas AS S ON S.schema_id = T.schema_id
       INNER JOIN sys.indexes ON indexes.index_id = dm_db_index_usage_stats.index_id
                                 AND dm_db_index_usage_stats.object_id = indexes.object_id
 WHERE
    indexes.is_primary_key = 0 -- This condition excludes primary key constarint
    AND indexes.type = 2
    AND indexes.is_unique = 0 -- This condition excludes unique key constarint
 --AND dm_db_index_usage_stats.user_lookups = 0
 --AND dm_db_index_usage_stats.user_seeks = 0
 --AND dm_db_index_usage_stats.user_scans = 0
 GROUP BY
    S.name,
    T.object_id,
    T.name,
    indexes.index_id,
    indexes.name;

;WITH Resumo
    AS
    (
        SELECT ID.object_id,
               ID.Tabela,
               ID.index_id,
               ID.name IndexName,
               ID.[Fisrt Key Columns],
               ID.[Demais Colluns keys],
               ID.[Include Coluns],
               ID.type_desc,
               ID.is_unique,
               ID.is_primary_key,
               ID.is_unique_constraint,
               Descricao = 'Statisticas',
               ISNULL(ANCI2.user_seeks, 0) user_seeks,
               ISNULL(ANCI2.user_scans, 0) user_scans,
               ISNULL(ANCI2.user_updates, 0) user_updates,
               ISNULL(ANCI2.total_used, 0) total_used
          FROM #IndicesDuplicados AS ID
               LEFT JOIN #AllNonClusterIndex AS ANCI2 ON ANCI2.OBject_Id = ID.object_id
                                                         AND ANCI2.index_id = ID.index_id
    ),
 GetPiorIndex AS (
 
	SELECT R.object_id,
           R.Tabela,
           R.index_id,
           R.IndexName,
           R.[Fisrt Key Columns],
           R.[Demais Colluns keys],
           R.[Include Coluns],
           R.type_desc,
           R.is_unique,
           R.is_primary_key,
           R.is_unique_constraint,
           R.Descricao,
           R.user_seeks,
           R.user_scans,
           R.user_updates,
           R.total_used,
		   MinAcesso = MIN(R.total_used) OVER(PARTITION BY R.object_id ORDER BY R.total_used) FROM Resumo R  
 )
 SELECT R.object_id,
        R.Tabela,
        R.index_id,
        R.IndexName,
        R.[Fisrt Key Columns],
        R.[Demais Colluns keys],
        R.[Include Coluns],
        R.type_desc,
        R.is_unique,
        R.is_primary_key,
        R.is_unique_constraint,
        R.Descricao,
        R.user_seeks,
        R.user_scans,
        R.user_updates,
        R.total_used,
        R.MinAcesso FROM  GetPiorIndex R
ORDER BY R.Tabela, R.total_used;
