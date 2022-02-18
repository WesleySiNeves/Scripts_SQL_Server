--SET QUOTED_IDENTIFIER ON
--SET ANSI_NULLS ON
--GO

CREATE  OR ALTER   PROCEDURE HealthCheck.uspAllIndex
(
    @typeIndex VARCHAR(40) = NULL,
    @SomenteUsado BIT = NULL,
    @TableIsEmpty BIT = NULL,
    @ObjectName VARCHAR(128) = NULL,
    @BadIndex BIT = NULL,
    @percentualAproveitamento SMALLINT = 10,
	@TableObjectIds TableIntegerIds  READONLY 
)
AS
SET NOCOUNT ON;

SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

--DECLARE @typeIndex VARCHAR(30) = NULL; --; --'NONCLUSTERED'; -- 'NONCLUSTERED';
--DECLARE @SomenteUsado BIT = 1;
--DECLARE @TableIsEmpty BIT = NULL;
--DECLARE @ObjectName VARCHAR(128) = NULL; --'Despesa.Empenhos';
--DECLARE @BadIndex BIT = NULL;
--DECLARE @percentualAproveitamento SMALLINT = NULL;
--DECLARE @TableObjectIds AS TableIntegerIds;

--INSERT INTO @tableIds
--(
--    Id
--)
--VALUES (299864135 )
SET @percentualAproveitamento
    = IIF(@percentualAproveitamento IS NULL OR @percentualAproveitamento = 0, 10, @percentualAproveitamento);

DECLARE @IndexType TINYINT = CASE
                                 WHEN @typeIndex = 'NONCLUSTERED' THEN
                                     2
                                 WHEN @typeIndex = 'CLUSTERED' THEN
                                     1
                                 ELSE
                                     NULL
                             END;

IF (OBJECT_ID('TEMPDB..#AllIndex') IS NOT NULL)
    DROP TABLE #AllIndex;

IF (OBJECT_ID('TEMPDB..#AllIndexColluns') IS NOT NULL)
    DROP TABLE #AllIndexColluns;

IF (OBJECT_ID('TEMPDB..#IndexKeys') IS NOT NULL)
    DROP TABLE #IndexKeys;

IF (OBJECT_ID('TEMPDB..#IndexInclude') IS NOT NULL)
    DROP TABLE #IndexInclude;

CREATE TABLE #IndexInclude (
                           ObjectId           INT,
                           IndexId            SMALLINT,
                           [ColunasIncluidas] VARCHAR(899)
                               PRIMARY KEY (ObjectId, IndexId)
                               WITH (FILLFACTOR = 90)
                           );

CREATE TABLE #IndexKeys (
                        ObjectId INT,
                        IndexId  SMALLINT,
                        [Chave]  VARCHAR(899)
                            PRIMARY KEY (ObjectId, IndexId)
                            WITH (FILLFACTOR = 90)
                        );

CREATE TABLE #AllIndex (
                       ObjectId           INT,
                       SchemaName         VARCHAR(128),
                       TableName          VARCHAR(128),
                       RowsInTable        INT,
                       TypeIndex          TINYINT,
                       IndexId            SMALLINT,
                       IndexName          VARCHAR(128),
                       IndexsizeKB        BIGINT,
                       IndexsizeMB        DECIMAL(18, 2),
                       IndexSizePorTipoMB DECIMAL(18, 2),
                       Usado              BIT,
                       UserSeeks          INT,
                       UserScans          INT,
                       UserLookups        INT,
                       UserUpdates        INT,
                       Reads              BIGINT,
                       Write              INT,
                       CountPageSplitPage INT,
                       PercAproveitamento DECIMAL(18, 2),
                       PercCustoMedio     DECIMAL(18, 2),
                       IsUnique           BIT,
                       IgnoreDupKey       BIT,
                       IsPrimaryKey       BIT,
                       IsUniqueConstraint BIT,
                       FillFact           TINYINT,
                       AllowRowLocks      BIT,
                       AllowPageLocks     BIT,
                       HasFilter          BIT,
                       IsBadIndex         BIT,
                       PRIMARY KEY CLUSTERED (ObjectId, IndexId)
                       );

CREATE TABLE #AllIndexColluns (
                              ObjectId         INT,
                              IndexId          SMALLINT,
                              KeyOrdinal       TINYINT,
                              IsDescendingKey  BIT,
                              IsIncludedColumn BIT,
                              Name             VARCHAR(128),
                              ColumnId         SMALLINT,
                              PRIMARY KEY CLUSTERED (ObjectId, IndexId, ColumnId)
                              );


IF (OBJECT_ID('TEMPDB..#dm_db_index_operational_stats') IS NOT NULL)
    DROP TABLE #dm_db_index_operational_stats;



CREATE TABLE #dm_db_index_operational_stats (
                                            [database_id]           SMALLINT,
                                            [object_id]             INT,
                                            [index_id]              INT,
                                            [partition_number]      INT,
                                            [leaf_allocation_count] BIGINT,
                                            PRIMARY KEY (database_id, object_id, index_id, partition_number)
                                            );


IF (OBJECT_ID('TEMPDB..#dm_db_index_usage_stats') IS NOT NULL)
    DROP TABLE #dm_db_index_usage_stats;

CREATE TABLE #dm_db_index_usage_stats (
                                      [database_id]  SMALLINT,
                                      [object_id]    INT,
                                      [index_id]     INT,
                                      [user_seeks]   INT,
                                      [user_scans]   INT,
                                      [user_lookups] INT,
                                      [user_updates] INT
                                          PRIMARY KEY (database_id, object_id, index_id)
                                      );



INSERT INTO #dm_db_index_usage_stats
SELECT database_id,
       object_id,
       index_id,
       user_seeks,
       user_scans,
       user_lookups,
       user_updates
FROM sys.dm_db_index_usage_stats;


INSERT INTO #dm_db_index_operational_stats
SELECT operacional.database_id,
       operacional.object_id,
       operacional.index_id,
       operacional.partition_number,
       SUM(operacional.leaf_allocation_count) leaf_allocation_count
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) operacional
GROUP BY
    operacional.database_id,
    operacional.object_id,
    operacional.index_id,
    operacional.partition_number;




WITH AllIndex
  AS (
     SELECT T.object_id,
            SchemaName = CAST(S.name AS VARCHAR(128)),
            TableName = CAST(T.name AS VARCHAR(128)),
            [RowsInTable] = CAST(SI.rowcnt AS INT),
            IndexName = CAST(I.name AS VARCHAR(128)),
            IndexsizeKB = CAST(Size.[Indexsize(KB)] AS DECIMAL(18, 2)),
            IndexsizeMB = CAST(Size.[Indexsize(MB)] AS DECIMAL(18, 2)),
            Usado = CAST(IIF(DDIUS.object_id IS NULL, 0, 1) AS BIT),
            user_seeks = CAST(ISNULL(DDIUS.user_seeks, 0) AS INT),
            user_scans = CAST(ISNULL(DDIUS.user_scans, 0) AS INT),
            user_lookups = CAST(ISNULL(DDIUS.user_lookups, 0) AS INT),
            user_Updates = CAST(ISNULL(DDIUS.user_updates, 0) AS INT),
            Reads = IIF(DDIUS.object_id IS NULL, 0, (DDIUS.user_seeks + DDIUS.user_scans + DDIUS.user_lookups)),
            [Write] = IIF(DDIUS.object_id IS NULL, 0, (DDIUS.user_updates)),
            [TotalAcessoTabela] = ISNULL(
                                            CAST(SUM(DDIUS.user_seeks + DDIUS.user_scans + DDIUS.user_lookups) OVER (PARTITION BY DDIUS.object_id) AS BIGINT),
                                            0
                                        ),
            index_id = CAST(I.index_id AS TINYINT),
            I.type AS type_index,
            I.is_unique,
            I.ignore_dup_key,
            I.is_primary_key,
            I.is_unique_constraint,
            I.fill_factor,
            I.allow_row_locks,
            I.allow_page_locks,
            I.has_filter
     FROM sys.indexes AS I
          JOIN
          sys.sysindexes AS SI ON SI.id = I.object_id
                                  AND SI.indid = I.index_id
          JOIN
          sys.tables AS T ON I.object_id = T.object_id
          JOIN
          sys.schemas AS S ON T.schema_id = S.schema_id
          JOIN
          (
          SELECT P.object_id,
                 P.index_id,
                 SUM(a.used_pages) * 8 'Indexsize(KB)',
                 CAST(((SUM(a.used_pages) * 8) / 1024 * 1.0) AS DECIMAL(18, 2)) 'Indexsize(MB)'
          FROM sys.partitions AS P
               JOIN
               sys.allocation_units AS a ON a.container_id = P.partition_id
          GROUP BY
              P.object_id,
              P.index_id
          ) AS Size ON I.object_id = Size.object_id
                       AND I.index_id = Size.index_id
          LEFT JOIN
          #dm_db_index_usage_stats AS DDIUS ON I.object_id = DDIUS.object_id
                                               AND I.index_id = DDIUS.index_id
                                               AND DDIUS.database_id = DB_ID()
     )
INSERT INTO #AllIndex
SELECT IX.object_id,
       IX.SchemaName,
       IX.TableName,
       CAST(IX.RowsInTable AS INT) AS RowsInTable,
       IX.type_index,
       IX.index_id,
       CAST(IX.IndexName AS VARCHAR(128)) AS IndexName,
       CAST(IX.IndexsizeKB AS BIGINT) AS IndexsizeKB,
       CAST(IX.IndexsizeMB AS DECIMAL(18, 2)) AS IndexsizeMB,
       IndexSizePorTipoMB = CAST(SUM(CAST(IX.IndexsizeMB AS DECIMAL(18, 2))) OVER (PARTITION BY IX.object_id,
                                                                                                IX.type_index
                                                                                  ) AS DECIMAL(18, 2)),
       CAST(IX.Usado AS BIT) Usado,
       IX.user_seeks,
       IX.user_scans,
       IX.user_lookups,
       IX.user_Updates,
       CAST(IX.Reads AS BIGINT) Reads,
       CAST(IX.Write AS INT) Write,
       ISNULL(IOS.leaf_allocation_count, 0) AS CountPageSplitPage,
       PercAproveitamento = CAST(ISNULL(
                                           (IX.Reads * 1.0 / IIF(IX.TotalAcessoTabela = 0, 1, IX.TotalAcessoTabela))
                                           * 100,
                                           0
                                       ) AS DECIMAL(18, 2)),
       PercCustoMedio = CONVERT(DECIMAL(18, 2), IX.Write * 1.0 / IIF(IX.Reads = 0, 1, IX.Reads)),
       IX.is_unique,
       IX.ignore_dup_key,
       IX.is_primary_key,
       IX.is_unique_constraint,
       IX.fill_factor,
       IX.allow_row_locks,
       IX.allow_page_locks,
       IX.has_filter,
       0 --IsBad
FROM AllIndex IX
     LEFT JOIN
     (
     SELECT operacional.database_id,
            operacional.object_id,
            operacional.index_id,
            operacional.partition_number,
            SUM(operacional.leaf_allocation_count) leaf_allocation_count
     FROM #dm_db_index_operational_stats operacional
     GROUP BY
         operacional.database_id,
         operacional.object_id,
         operacional.index_id,
         operacional.partition_number
     ) IOS ON IX.object_id = IOS.object_id
              AND IX.index_id = IOS.index_id
              AND IOS.database_id = DB_ID()
              AND (
                  @SomenteUsado IS NULL
                  OR (IX.Usado = @SomenteUsado)
                     AND (
                         @ObjectName IS NULL
                         OR IX.object_id = OBJECT_ID(@ObjectName)
                         )
                     AND @IndexType IS NULL
                  OR (IX.type_index = @IndexType)
                  );


IF (EXISTS (
           SELECT 1
           FROM #AllIndex
           )
   )
BEGIN


    UPDATE AI
    SET AI.IsBadIndex = IIF(
                            ((AI.PercCustoMedio) > 1 AND AI.PercAproveitamento < @percentualAproveitamento AND AI.IndexId > 1),
                            1,
                            0)
    FROM #AllIndex AS AI;

    IF (@TableIsEmpty IS NOT NULL)
    BEGIN
        IF (@TableIsEmpty = 1)
        BEGIN
            DELETE AI
            FROM #AllIndex AS AI
            WHERE AI.RowsInTable > 0;
        END;
        ELSE
        BEGIN
            DELETE AI
            FROM #AllIndex AS AI
            WHERE AI.RowsInTable = 0;
        END;

    END;


    IF (@BadIndex IS NOT NULL)
    BEGIN

        DELETE AI
        FROM #AllIndex AS AI
        WHERE AI.IsBadIndex = @BadIndex;

    END;



    INSERT INTO #AllIndexColluns
    SELECT IX.ObjectId,
           IX.IndexId,
           IC.key_ordinal,
           IC.is_descending_key,
           IC.is_included_column,
           CAST(CO.name AS VARCHAR(128)),
           CAST(CO.column_id AS SMALLINT)
    FROM #AllIndex IX
         JOIN
         sys.index_columns AS IC ON IX.ObjectId = IC.object_id
                                    AND IX.IndexId = IC.index_id
         JOIN
         sys.columns AS CO ON IC.object_id = CO.object_id
                              AND IC.column_id = CO.column_id;

    INSERT INTO #IndexKeys
    SELECT c1.ObjectId,
           c1.IndexId,
           STUFF(   (
                    SELECT', '+c2.Name
                 FROM #AllIndexColluns c2
                 -- group by
                 WHERE c2.ObjectId = c1.ObjectId
                       AND c2.IndexId = c1.IndexId
                       AND c2.IsIncludedColumn = 0
                 ORDER BY
                     c2.KeyOrdinal
                 FOR XML PATH(''), TYPE
                    ).value('.', 'varchar(900)'), -- extract element value and convert
                    1,
                    2,
                    ''
                ) AS Chave
    FROM #AllIndexColluns c1
    GROUP BY
        c1.ObjectId,
        c1.IndexId;

    INSERT INTO #IndexInclude
    SELECT c1.ObjectId,
           c1.IndexId,
           STUFF(   (
                    SELECT', '+c2.Name
                 FROM #AllIndexColluns c2
                 -- group by
                 WHERE c2.ObjectId = c1.ObjectId
                       AND c2.IndexId = c1.IndexId
                       AND c2.IsIncludedColumn = 1
                 ORDER BY
                     c2.ColumnId
                 FOR XML PATH(''), TYPE
                    ).value('.', 'varchar(900)'), -- extract element value and convert
                    1,
                    2,
                    ''
                ) AS Keys
    FROM #AllIndexColluns c1
    GROUP BY
        c1.ObjectId,
        c1.IndexId;

    SELECT R.ObjectId,
           ObjectName = CAST(CONCAT(QUOTENAME(R.SchemaName), '.', QUOTENAME(R.TableName)) AS VARCHAR(300)),
           R.RowsInTable,
           R.IndexName,
           R.Usado,
           R.UserSeeks,
           R.UserScans,
           R.UserLookups,
           R.UserUpdates,
           R.Reads,
           R.Write,
           R.CountPageSplitPage,
           R.PercAproveitamento,
           R.PercCustoMedio,
           R.IsBadIndex,
           R.IndexId,
           R.IndexsizeKB,
           R.IndexsizeMB,
           R.IndexSizePorTipoMB,
           Chave.Chave,
           Incl.ColunasIncluidas,
           R.IsUnique,
           R.IgnoreDupKey,
           R.IsPrimaryKey,
           R.IsUniqueConstraint,
           R.FillFact,
           R.AllowRowLocks,
           R.AllowPageLocks,
           R.HasFilter,
           R.TypeIndex
    FROM #AllIndex R
         JOIN
         #IndexKeys Chave ON R.ObjectId = Chave.ObjectId
                             AND R.IndexId = Chave.IndexId
         JOIN
         #IndexInclude Incl ON Chave.ObjectId = Incl.ObjectId
                               AND Chave.IndexId = Incl.IndexId;

END;
--GO