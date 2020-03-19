


SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


/* ==================================================================
--Data: 31/10/2018 
--Autor :Wesley Neves
--Observação: Criação das tabelas e modulos
 
-- ==================================================================
*/

IF (NOT EXISTS (   SELECT *
                     FROM sys.schemas AS S
                    WHERE S.name = 'HealthCheck'))
BEGIN
    EXEC ('CREATE SCHEMA HealthCheck');
END;

GO

IF (NOT EXISTS (   SELECT *
                     FROM sys.types
                    WHERE types.name = 'TableIntegerIds'))
BEGIN


    CREATE TYPE TableIntegerIds AS TABLE (Id INT NOT NULL PRIMARY KEY);
END;

IF(NOT EXISTS (
                  SELECT *
                    FROM sys.tables AS T
                   WHERE
                      T.object_id = OBJECT_ID('HealthCheck.SnapShotIndex')
              )
  )
    BEGIN
        CREATE TABLE [HealthCheck].[SnapShotIndex]
        (
            ObjectId   [INT]          NOT NULL,
            ObjectName [VARCHAR](260) COLLATE Latin1_General_CI_AI NULL,
            IndexName  [VARCHAR](128) COLLATE Latin1_General_CI_AI NULL,
            IndexId    [SMALLINT]     NOT NULL
        ) ON [PRIMARY];

        ALTER TABLE HealthCheck.SnapShotIndex
        ADD CONSTRAINT [PKHealthCheckSnapShotIndex] PRIMARY KEY CLUSTERED(ObjectId, IndexId);

        CREATE TABLE [HealthCheck].[SnapShotIndexHistory]
        (
            [ObjectId]           [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckObjectId] DEFAULT((0)),
            [IndexId]            [SMALLINT]       NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexId] DEFAULT((0)),
            [SnapShotDate]       [DATETIME2](2)   NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotDate] DEFAULT(CONVERT([DATETIME2](2), GETDATE(), (0))),
            [RowsInTable]        [INT]            NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryRowsInTable] DEFAULT((0)),
            [IndexSizePorTipoMB] [NUMERIC](18, 2) NULL,
            [IsBadIndex]         [BIT]            NULL CONSTRAINT [DEF_HealthCheckIsBadIndex] DEFAULT((0)),
            [UserSeeks]          [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryUserSeeks] DEFAULT((0)),
            [UserScans]          [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryUserScans] DEFAULT((0)),
            [UserLookups]        [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryUserLookups] DEFAULT((0)),
            [UserUpdates]        [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryUserUpdates] DEFAULT((0)),
            [Reads]              [BIGINT]         NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryReads] DEFAULT((0)),
            [Write]              [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryWrite] DEFAULT((0)),
            [CountPageSplitPage] [INT]            NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryCountPageSplitPage] DEFAULT((0)),
            [FillFactor]         [TINYINT]        NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryFillFactor] DEFAULT((100)),
            [PercAproveitamento] [NUMERIC](18, 2) NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryPercAproveitamento] DEFAULT((0)),
            [PercCustoMedio]     [NUMERIC](18, 2) NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryPercCustoMedio] DEFAULT((0)),
            [IndexsizeKB]        [BIGINT]         NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryIndexsizeKB] DEFAULT((0)),
            [IndexsizeMB]        [NUMERIC](18, 2) NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryIndexsizeMB] DEFAULT((0)),
            [TypeIndex]          [TINYINT]        NOT NULL CONSTRAINT [DEF_HealthCheckSnapShotIndexHistoryTypeIndex] DEFAULT((0))
        ) ON [PRIMARY]

        ALTER TABLE [HealthCheck].[SnapShotIndexHistory]
        ADD CONSTRAINT [PK_HealthCheckSnapShotIndexHistory] PRIMARY KEY CLUSTERED([ObjectId], [IndexId], [SnapShotDate])WITH(FILLFACTOR = 90)
    END;









/* ==================================================================
--Data: 13/12/2018 
--Autor :Wesley Neves
--Observação: Inicio Das Procedures
 
-- ==================================================================
*/

--SET QUOTED_IDENTIFIER ON
--SET ANSI_NULLS ON

GO

/* ==================================================================
--Data: 15/01/2020 
--Autor :Wesley Neves
--Observação: Procedure HealthCheck.uspAllIndex
 --Objetivo --Recuperar informações de tamanho e acesso de um indice
 
-- ==================================================================
*/
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



GO

/* ==================================================================
--Data: 15/01/2020 
--Autor :Wesley Neves
--Observação:  Procedure HealthCheck.uspSnapShotIndex
 
-- ==================================================================
*/

CREATE OR ALTER  PROCEDURE HealthCheck.uspSnapShotIndex (@Visualizar BIT = 1,
		@DiaExecucao DATETIME = NULL,
		@Efetivar BIT = 0)
AS
BEGIN
    SET NOCOUNT ON;

    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
  
  -- DECLARE @DiaExecucao DATETIME;
  --DECLARE @Visualizar BIT = 1;
  --DECLARE @Efetivar BIT = 1 ;

	SET @DiaExecucao = ISNULL(@DiaExecucao,GETDATE());
    


    IF (OBJECT_ID('TEMPDB..#Snapshot') IS NOT NULL)
        DROP TABLE #Snapshot;

    CREATE TABLE #Snapshot (
        ObjectId INT,
        [ObjectName] VARCHAR(300),
        [RowsInTable] INT,
        [IndexName] VARCHAR(128),
        [Usado] BIT,
        UserSeeks INT,
        UserScans INT,
        UserLookups INT,
		UserUpdates INT,
        [Reads] BIGINT,
        [Write] INT,
		CountPageSplitPage INT,
        PercAproveitamento DECIMAL(18, 2),
        PercCustoMedio DECIMAL(18, 2),
        [IsBadIndex] INT,
        IndexId SMALLINT,
        IndexSizeKB BIGINT,
        IndexSizeMB DECIMAL(18, 2),
        IndexSizePorTipoMB DECIMAL(18, 2),
        [Chave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        IsUnique BIT,
        IgnoreDupKey BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        FillFact TINYINT,
        AllowRowLocks BIT,
        AllowPageLocks BIT,
        HasFilter BIT,
        TypeIndex TINYINT
            PRIMARY KEY (ObjectId, IndexId));



    INSERT INTO #Snapshot

    /*Faz uma analise completa de todos os indices*/
    EXEC HealthCheck.uspAllIndex @SomenteUsado = 1, -- bit
                                 @TableIsEmpty = 0; -- bit




    IF (EXISTS (SELECT 1 FROM #Snapshot) AND @Efetivar =1)
    BEGIN
        /*Merge in SnapShotIndex */
        INSERT INTO HealthCheck.SnapShotIndex (ObjectId,
                                               [ObjectName],
                                               [IndexName],
                                               IndexId)
			SELECT S.ObjectId,
				   S.ObjectName,
				   S.IndexName,
				   S.IndexId
			  FROM #Snapshot S
			 WHERE NOT EXISTS (   SELECT 1
									FROM HealthCheck.SnapShotIndex AS SSI
								   WHERE SSI.ObjectId = S.ObjectId
									 AND SSI.IndexId  = S.IndexId);

  

			INSERT INTO HealthCheck.SnapShotIndexHistory
			(
			    ObjectId,
			    IndexId,
			    SnapShotDate,
			    RowsInTable,
			    IndexSizePorTipoMB,
			    IsBadIndex,
			    UserSeeks,
			    UserScans,
			    UserLookups,
			    UserUpdates,
			    Reads,
			    Write,
			    CountPageSplitPage,
			    [FillFactor],
			    PercAproveitamento,
			    PercCustoMedio,
			    IndexsizeKB,
			    IndexsizeMB,
			    TypeIndex
			)
			SELECT Source.ObjectId,
				   Source.IndexId,
				   @DiaExecucao,
				   Source.RowsInTable,
				   Source.IndexSizePorTipoMB,
				   Source.IsBadIndex,
				   Source.UserSeeks,
				   Source.UserScans,
				   Source.UserLookups,
				   Source.UserUpdates,
				   Source.Reads,
				   Source.Write,
				   Source.CountPageSplitPage,
				   CASE WHEN Source.FillFact =0 THEN 100 
						WHEN Source.FillFact =20 THEN 80
						WHEN Source.FillFact =30 THEN 70
				   ELSE Source.FillFact END,
				   Source.PercAproveitamento,
				   Source.PercCustoMedio,
				   Source.IndexSizeKB,
				   Source.IndexSizeMB,
				   Source.TypeIndex
			  FROM #Snapshot AS Source;
    END;

    IF (@Visualizar = 1)
    BEGIN

        SELECT *
          FROM #Snapshot AS S;
    END;
END;

GO



/* ==================================================================
--Data: 15/01/2020 
--Autor :Wesley Neves
--Observação:  Procedure HealthCheck.uspMissingIndex
 
-- ==================================================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspMissingIndex
(
    @defaultTunningPerform SMALLINT = 200
)
AS
    BEGIN
        BEGIN TRY

            --DECLARE @defaultTunningPerform SMALLINT = 200;
            SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

            IF(OBJECT_ID('TEMPDB..#Retorno') IS NOT NULL)
                DROP TABLE #Retorno;

            CREATE TABLE #Retorno
            (
                [ObjectId]                  INT,
                [TotalObjetcId]             INT,
                [SchemaName]                VARCHAR(140),
                [TableName]                 VARCHAR(140),
                [IndexName]                 VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [ColunaIncluida]            VARCHAR(1000),
                [AvgEstimatedImpact]        REAL,
                [MagicBenefitNumber]        REAL,
                [PotentialReadOp]           INT,
                [reads]                     INT,
                [PercCustoMedio]            DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000)
            );

            IF(OBJECT_ID('TEMPDB..#indexusage') IS NOT NULL)
                DROP TABLE #indexusage;

            IF(OBJECT_ID('TEMPDB..#Missings') IS NOT NULL)
                DROP TABLE #Missings;

            IF(OBJECT_ID('TEMPDB..#Candidates') IS NOT NULL)
                DROP TABLE #Candidates;

            IF(OBJECT_ID('TEMPDB..#FirtResultIntermediate') IS NOT NULL)
                DROP TABLE #FirtResultIntermediate;

            IF(OBJECT_ID('TEMPDB..#SecondResultIntermediate') IS NOT NULL)
                DROP TABLE #SecondResultIntermediate;

            IF(OBJECT_ID('TEMPDB..#Final') IS NOT NULL)
                DROP TABLE #Final;

            CREATE TABLE #Final
            (
                [object_id]            INT,
                [s]                    VARCHAR(140),
                [o]                    VARCHAR(140),
                [user_seeks]           INT,
                [user_scans]           INT,
                [unique_compiles]      INT,
                IndexName              VARCHAR(200),
                [Chave]                VARCHAR(200),
                [PrimeiraChave]        VARCHAR(200),
                [ColunaIncluida]       VARCHAR(1000),
                [Avg_Estimated_Impact] REAL,
                [magic_benefit_number] REAL,
                [potential_read_op]    INT,
                [reads]                INT,
                [write:read ratio]     DECIMAL(10, 2),
            );

            CREATE TABLE #FirtResultIntermediate
            (
                [object_id]            INT,
                [s]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [o]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [user_seeks]           INT,
                [user_scans]           INT,
                [unique_compiles]      INT,
                IndexName              VARCHAR(200),
                [Chave]                VARCHAR(200),
                [PrimeiraChave]        VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [ColunaIncluida]       VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact] REAL,
                [magic_benefit_number] REAL,
                [potential_read_op]    INT,
                [reads]                INT,
                [write:read ratio]     DECIMAL(10, 2),
            );

            CREATE TABLE #SecondResultIntermediate
            (
                [object_id]                 INT,
                [user_seeks]                INT,
                [user_scans]                INT,
                [unique_compiles]           INT,
                IndexName                   VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [Chave]                     VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [PrimeiraChave]             VARCHAR(200)  COLLATE DATABASE_DEFAULT,
                [ColunaIncluida]            VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact]      REAL,
                [magic_benefit_number]      REAL,
                [CountObjectId]             INT,
                [CountObjectIdAndChave]     INT,
                [TotalMagic_benefit_number] FLOAT(8),
                [MaxMagic_benefit_number]   REAL,
                [TotalAvg_Estimated_Impact] FLOAT(8),
                [MaxAvg_Estimated_Impact]   REAL
            );

            CREATE TABLE #indexusage
            (
                [object_id]    INT,
                [index_id]     TINYINT,
                [user_seeks]   INT,
                [user_scans]   INT,
                [user_lookups] INT,
                [user_updates] INT PRIMARY KEY(object_id, index_id)
            );

            CREATE TABLE #Missings
            (
                [object_id]            INT,
                [s]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [o]                    VARCHAR(140)  COLLATE DATABASE_DEFAULT,
                [equality_columns]     VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [inequality_columns]   VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [included_columns]     VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [unique_compiles]      INT,
                [user_seeks]           INT,
                [last_user_seek]       DATETIME2(3),
                [user_scans]           INT,
                [last_user_scan]       DATETIME2(3),
                [NomeIndex]            VARCHAR(128)  COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact] FLOAT(8),
                [magic_benefit_number] FLOAT(8)
            );

            CREATE TABLE #Candidates
            (
                [object_id]            INT,
                [s]                    VARCHAR(140),
                [o]                    VARCHAR(140),
                [equality_columns]     VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [inequality_columns]   VARCHAR(300)  COLLATE DATABASE_DEFAULT,
                [included_columns]     VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [unique_compiles]      INT,
                [user_seeks]           INT,
                [last_user_seek]       DATETIME2(3),
                [user_scans]           INT,
                [last_user_scan]       DATETIME2(3),
                [NomeIndex]            VARCHAR(128),
                [Chave]                VARCHAR(200),
                PrimeiraChave          AS (IIF(CHARINDEX(',', [Chave], 0) > 0, SUBSTRING([Chave], 0, CHARINDEX(',', [Chave], 0)), [Chave])),
                [ColunaIncluida]       VARCHAR(1000) COLLATE DATABASE_DEFAULT,
                [Avg_Estimated_Impact] REAL,
                [magic_benefit_number] REAL,
            );

            INSERT INTO #indexusage
            SELECT s.object_id,
                   s.index_id,
                   s.user_seeks,
                   s.user_scans,
                   s.user_lookups,
                   s.user_updates
              FROM sys.dm_db_index_usage_stats AS s
             WHERE
                s.database_id = DB_ID();

            WITH Dados
                AS
                (
                    SELECT dm_mid.object_id,
                           s = CAST(OBJECT_SCHEMA_NAME(dm_mid.object_id) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                           o = CAST(OBJECT_NAME(dm_mid.object_id) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                           CAST(dm_mid.equality_columns AS VARCHAR(300)) equality_columns,
                           CAST(dm_mid.inequality_columns AS VARCHAR(300)) inequality_columns,
                           CAST(dm_mid.included_columns AS VARCHAR(1000)) included_columns,
                           dm_migs.unique_compiles,
                           dm_migs.user_seeks,
                           dm_migs.last_user_seek,
                           dm_migs.user_scans,
                           dm_migs.last_user_scan,
                           NomeIndex = CAST('IX_' + CAST(OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id) AS VARCHAR(400)) + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '') + CASE WHEN dm_mid.equality_columns IS NOT NULL
                                                                                                                                                                                                                                                                                                       AND dm_mid.inequality_columns IS NOT NULL THEN CAST('_' AS VARCHAR(1))ELSE CAST('' AS VARCHAR(1))END + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, CAST('' AS VARCHAR(1))), ', ', '_'), '[', CAST('' AS VARCHAR(1))), ']', CAST('' AS VARCHAR(1))) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                           dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact,
                           magic_benefit_number = dm_migs.avg_total_user_cost * dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans)
                      FROM sys.dm_db_missing_index_details AS dm_mid
                           INNER JOIN sys.dm_db_missing_index_groups AS dm_mig ON dm_mid.index_handle = dm_mig.index_handle
                           INNER JOIN sys.dm_db_missing_index_group_stats AS dm_migs ON dm_mig.index_group_handle = dm_migs.group_handle
                     WHERE
                        dm_mid.database_id = DB_ID()
                )
            INSERT INTO #Missings
            SELECT R.object_id,
                   R.s,
                   R.o,
                   R.equality_columns,
                   R.inequality_columns,
                   R.included_columns,
                   R.unique_compiles,
                   R.user_seeks,
                   R.last_user_seek,
                   R.user_scans,
                   R.last_user_scan,
                   R.NomeIndex,
                   R.Avg_Estimated_Impact,
                   R.magic_benefit_number
              FROM Dados R;

            IF(EXISTS (SELECT 1 FROM #Missings AS M))
                BEGIN
                    WITH Resumo
                        AS
                        (
                            SELECT R.object_id,
                                   R.s,
                                   R.o,
                                   R.equality_columns,
                                   R.inequality_columns,
                                   R.included_columns,
                                   R.unique_compiles,
                                   R.user_seeks,
                                   R.last_user_seek,
                                   R.user_scans,
                                   R.last_user_scan,
                                   R.NomeIndex,
                                   Chave = '' + ISNULL(R.equality_columns, '') + CASE WHEN R.equality_columns IS NOT NULL
                                                                                           AND R.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL(R.inequality_columns, '') + '',
                                   ColunaIncluida = R.included_columns,
                                   R.Avg_Estimated_Impact,
                                   R.magic_benefit_number
                              FROM #Missings R
                        ),
                         ResultTwo
                        AS
                        (
                            SELECT R.object_id,
                                   R.s,
                                   R.o,
                                   R.equality_columns,
                                   R.inequality_columns,
                                   R.included_columns,
                                   R.unique_compiles,
                                   R.user_seeks,
                                   R.last_user_seek,
                                   R.user_scans,
                                   R.last_user_scan,
                                   R.NomeIndex,
                                   Chave = CAST(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(R.Chave, CHAR(32), ''), '[', ''), ']', ''))) AS VARCHAR(200)),
                                   ColunaIncluida = CAST(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(R.ColunaIncluida, '[', CHAR(32)), ']', CHAR(32)), CHAR(32), ''))) AS VARCHAR(1000)),
                                   R.Avg_Estimated_Impact,
                                   R.magic_benefit_number
                              FROM Resumo R
                        )
                    INSERT INTO #Candidates(
                                               object_id,
                                               s,
                                               o,
                                               equality_columns,
                                               inequality_columns,
                                               included_columns,
                                               unique_compiles,
                                               user_seeks,
                                               last_user_seek,
                                               user_scans,
                                               last_user_scan,
                                               NomeIndex,
                                               Chave,
                                               ColunaIncluida,
                                               Avg_Estimated_Impact,
                                               magic_benefit_number
                                           )
                    SELECT T.object_id,
                           T.s,
                           T.o,
                           T.equality_columns,
                           T.inequality_columns,
                           T.included_columns,
                           T.unique_compiles,
                           T.user_seeks,
                           T.last_user_seek,
                           T.user_scans,
                           T.last_user_scan,
                           T.NomeIndex,
                           T.Chave,
                           T.ColunaIncluida,
                           T.Avg_Estimated_Impact,
                           T.magic_benefit_number
                      FROM ResultTwo T;

                    WITH AnaliseObjetosUnicos
                        AS
                        (
                            SELECT C.object_id,
                                   C.s,
                                   C.o,
                                   C.user_seeks,
                                   C.user_scans,
                                   C.unique_compiles,
                                   C.NomeIndex,
                                   C.Chave,
                                   C.PrimeiraChave,
                                   C.ColunaIncluida,
                                   C.Avg_Estimated_Impact,
                                   C.magic_benefit_number,
                                   CountObjectId = COUNT(C.object_id) OVER (PARTITION BY C.object_id)
                              FROM #Candidates AS C
                        ),
                         Resumo1
                        AS
                        (
                            SELECT A.object_id,
                                   A.s,
                                   A.o,
                                   A.user_seeks,
                                   A.user_scans,
                                   A.unique_compiles,
                                   A.NomeIndex,
                                   A.Chave,
                                   A.PrimeiraChave,
                                   A.ColunaIncluida,
                                   A.CountObjectId,
                                   A.Avg_Estimated_Impact,
                                   A.magic_benefit_number,
                                   potential_read_op = (I.user_seeks + I.user_scans),
                                   reads = (I.user_seeks + I.user_scans + I.user_lookups),
                                   [write:read ratio] = CAST((I.user_updates * 1.0 / (I.user_scans + I.user_seeks + I.user_lookups)) AS DECIMAL(10, 2))
                              FROM AnaliseObjetosUnicos A
                                   JOIN(
                                           SELECT I.object_id,
                                                  SUM(I.user_seeks) user_seeks,
                                                  SUM(I.user_scans) user_scans,
                                                  SUM(I.user_lookups) user_lookups,
                                                  SUM(I.user_updates) user_updates
                                             FROM #indexusage AS I
                                            GROUP BY
                                               I.object_id
                                       ) AS I ON A.object_id = I.object_id
                        )
                    INSERT INTO #FirtResultIntermediate
                    SELECT R.object_id,
                           R.s,
                           R.o,
                           R.user_seeks,
                           R.user_scans,
                           R.unique_compiles,
                           R.NomeIndex,
                           R.Chave,
                           R.PrimeiraChave,
                           R.ColunaIncluida,
                           R.Avg_Estimated_Impact,
                           R.magic_benefit_number,
                           R.potential_read_op,
                           R.reads,
                           R.[write:read ratio]
                      FROM Resumo1 R
                     WHERE
                        R.CountObjectId = 1;

                    INSERT INTO #Final
                    SELECT R.object_id,
                           R.s,
                           R.o,
                           R.user_seeks,
                           R.user_scans,
                           R.unique_compiles,
                           R.IndexName,
                           R.Chave,
                           R.PrimeiraChave,
                           R.ColunaIncluida,
                           R.Avg_Estimated_Impact,
                           R.magic_benefit_number,
                           R.potential_read_op,
                           R.reads,
                           R.[write:read ratio]
                      FROM #FirtResultIntermediate R
                     WHERE
                        (
                            R.magic_benefit_number >= @defaultTunningPerform
                            AND R.Avg_Estimated_Impact >= @defaultTunningPerform
                            OR (R.magic_benefit_number >= @defaultTunningPerform * 10)
                               AND (
                                       R.[write:read ratio] < 1 -- Maior que 1 BAD Index
                                       AND R.potential_read_op > (@defaultTunningPerform / 20.0)
                                   )
                        );

                    DELETE FROM #Candidates
                     WHERE
                        #Candidates.object_id IN(
                                                    SELECT FRI.object_id FROM #FirtResultIntermediate AS FRI
                                                );

                    TRUNCATE TABLE #FirtResultIntermediate;

                    WITH Analise2
                        AS
                        (
                            SELECT C.object_id,
                                   C.user_seeks,
                                   C.s,
                                   C.o,
                                   C.user_scans,
                                   C.unique_compiles,
                                   C.NomeIndex,
                                   C.Chave,
                                   C.PrimeiraChave,
                                   C.ColunaIncluida,
                                   C.Avg_Estimated_Impact,
                                   C.magic_benefit_number,
                                   CountObjectId = COUNT(*) OVER (PARTITION BY C.object_id),
                                   CountObjectIdAndChave = COUNT(*) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   TotalMagic_benefit_number = SUM(C.magic_benefit_number) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   MaxMagic_benefit_number = MAX(C.magic_benefit_number) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   TotalAvg_Estimated_Impact = SUM(C.Avg_Estimated_Impact) OVER (PARTITION BY C.object_id, C.PrimeiraChave),
                                   MaxAvg_Estimated_Impact = MAX(C.Avg_Estimated_Impact) OVER (PARTITION BY C.object_id, C.PrimeiraChave)
                              FROM #Candidates AS C
                        ),
                         Custo2
                        AS
                        (
                            SELECT two.object_id,
                                   two.o,
                                   two.s,
                                   two.user_seeks,
                                   two.user_scans,
                                   two.unique_compiles,
                                   two.NomeIndex,
                                   two.Chave,
                                   two.PrimeiraChave,
                                   two.ColunaIncluida,
                                   two.Avg_Estimated_Impact,
                                   two.magic_benefit_number,
                                   two.CountObjectId,
                                   two.CountObjectIdAndChave,
                                   two.TotalMagic_benefit_number,
                                   two.MaxMagic_benefit_number,
                                   two.TotalAvg_Estimated_Impact,
                                   two.MaxAvg_Estimated_Impact,
                                   potential_read_op = (I.user_seeks + I.user_scans),
                                   reads = (I.user_seeks + I.user_scans + I.user_lookups),
                                   [write:read ratio] = CAST((I.user_updates * 1.0 / (I.user_scans + I.user_seeks + I.user_lookups)) AS DECIMAL(10, 2))
                              FROM Analise2 two
                                   JOIN(
                                           SELECT I.object_id,
                                                  SUM(I.user_seeks) user_seeks,
                                                  SUM(I.user_scans) user_scans,
                                                  SUM(I.user_lookups) user_lookups,
                                                  SUM(I.user_updates) user_updates
                                             FROM #indexusage AS I
                                            GROUP BY
                                               I.object_id
                                       ) AS I ON two.object_id = I.object_id
                        )
                    INSERT INTO #Final(
                                          object_id,
                                          s,
                                          o,
                                          user_seeks,
                                          user_scans,
                                          unique_compiles,
                                          IndexName,
                                          Chave,
                                          PrimeiraChave,
                                          ColunaIncluida,
                                          Avg_Estimated_Impact,
                                          magic_benefit_number,
                                          potential_read_op,
                                          reads,
                                          [write:read ratio]
                                      )
                    SELECT C.object_id,
                           C.s,
                           C.o,
                           C.user_seeks,
                           C.user_scans,
                           C.unique_compiles,
                           C.NomeIndex,
                           C.Chave,
                           C.PrimeiraChave,
                           C.ColunaIncluida,
                           C.Avg_Estimated_Impact,
                           C.magic_benefit_number,
                           C.potential_read_op,
                           C.reads,
                           C.[write:read ratio]
                      FROM Custo2 C
                     WHERE
                        (
                            C.TotalMagic_benefit_number > @defaultTunningPerform
                            AND C.TotalAvg_Estimated_Impact > @defaultTunningPerform
                        )
                        OR (
                               C.TotalMagic_benefit_number > (@defaultTunningPerform * 20)
                               AND (
                                       C.[write:read ratio] < 1 -- Maior que 1 is BAD Index
                                       AND C.potential_read_op > (@defaultTunningPerform / 20.0)
                                   )
                           );

                    WITH Final
                        AS
                        (
                            SELECT F.object_id,
                                   F.s,
                                   F.o,
                                   F.IndexName,
                                   F.Chave,
                                   F.PrimeiraChave,
                                   F.ColunaIncluida,
                                   MAX(F.Avg_Estimated_Impact) Avg_Estimated_Impact,
                                   MAX(F.magic_benefit_number) magic_benefit_number,
                                   MAX(F.potential_read_op) potential_read_op,
                                   MAX(F.reads) reads,
                                   MAX(F.[write:read ratio]) [write:read ratio]
                              FROM #Final AS F
                             GROUP BY
                                F.object_id,
                                F.s,
                                F.o,
                                F.IndexName,
                                F.Chave,
                                F.PrimeiraChave,
                                F.ColunaIncluida
                        )
                    INSERT INTO #Retorno
                    SELECT ObjectId = FI.object_id,
                           TotalObjetcId = COUNT(*) OVER (PARTITION BY FI.object_id),
                           SchemaName = FI.s,
                           TableName = FI.o,
                           FI.IndexName,
                           FI.Chave,
                           FI.PrimeiraChave,
                           ExisteIndiceNaChave = (CASE WHEN EXISTS (
                                                                       SELECT 1
                                                                         FROM sys.indexes AS I
                                                                              JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                              AND I.index_id = IC.index_id
                                                                              JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                                                       AND IC.column_id = C.column_id
                                                                                                       AND IC.is_included_column = 0
                                                                        WHERE
                                                                           I.object_id = FI.object_id
                                                                           AND C.name COLLATE DATABASE_DEFAULT = FI.PrimeiraChave
                                                                           AND IC.key_ordinal = 1
                                                                   ) THEN 1 ELSE 0 END
                                                 ),
                           ChavePertenceAOutroIndice = (CASE WHEN EXISTS (
                                                                             SELECT 1
                                                                               FROM sys.indexes AS I
                                                                                    JOIN sys.index_columns AS IC ON I.object_id = IC.object_id
                                                                                                                    AND I.index_id = IC.index_id
                                                                                    JOIN sys.columns AS C ON I.object_id = C.object_id
                                                                                                             AND IC.column_id = C.column_id
                                                                                                             AND IC.is_included_column = 0
                                                                              WHERE
                                                                                 I.object_id = FI.object_id
                                                                                 AND C.name COLLATE DATABASE_DEFAULT = FI.PrimeiraChave
                                                                                 AND IC.key_ordinal > 1
                                                                         ) THEN 1 ELSE 0 END
                                                       ),
                           FI.ColunaIncluida,
                           AvgEstimatedImpact = FI.Avg_Estimated_Impact,
                           MagicBenefitNumber = FI.magic_benefit_number,
                           PotentialReadOp = FI.potential_read_op,
                           FI.reads,
                           [PercCustoMedio] = FI.[write:read ratio],
                           CreateIndex = CONCAT('CREATE INDEX [IX_', FI.s, FI.o, REPLACE(FI.Chave, ',', ''), '] ON [', FI.s, '].[', FI.o, ']
			  (', FI.Chave, ')' + ISNULL(' INCLUDE (' + FI.ColunaIncluida + ')', SPACE(0)))
                      FROM Final FI;

                    SELECT * FROM #Retorno AS R;
                END;
        END TRY
        BEGIN CATCH
            DECLARE @ErrorNumber INT = ERROR_NUMBER();
            DECLARE @ErrorLine INT = ERROR_LINE();
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();

            PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
            PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

            PRINT 'Error detected, all changes reversed.';
        END CATCH;
    END;
GO




CREATE OR ALTER PROCEDURE HealthCheck.uspAutoCreateIndex
(
    @Efetivar              BIT      = 0,
    @VisualizarMissing     BIT      = 0,
    @VisualizarCreate      BIT      = 0,
    @VisualizarAlteracoes  BIT      = 0,
    @defaultTunningPerform SMALLINT = 200
)
AS
    BEGIN
        BEGIN TRY

            --DECLARE @Efetivar BIT =1;
            --DECLARE @VisualizarMissing BIT = 1;
            --DECLARE @VisualizarCreate BIT = 1;
            --DECLARE @VisualizarAlteracoes BIT = 1;
            --DECLARE @defaultTunningPerform SMALLINT = 100;
            --SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
            SET NOCOUNT ON;

            DECLARE @SqlServerVersion VARCHAR(100) = (
                                                         SELECT @@VERSION
                                                     );
            DECLARE @TipoVersao VARCHAR(100) = CASE WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN 'Azure'
                                               WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN 'Enterprise' ELSE 'Standard' END;
            DECLARE @tableObjectsIds AS TableIntegerIds;
            DECLARE @QuantidadeMaximaIndiceTabela TINYINT = 5; --(1 PK + 4 NonCluster);

            IF(OBJECT_ID('TEMPDB..#MissingIndex') IS NOT NULL)
                DROP TABLE #MissingIndex;

            IF(OBJECT_ID('TEMPDB..#IndexOnDataBase') IS NOT NULL)
                DROP TABLE #IndexOnDataBase;

            IF(OBJECT_ID('TEMPDB..#NovosIndices') IS NOT NULL)
                DROP TABLE #NovosIndices;

            IF(OBJECT_ID('TEMPDB..#InformacaoesOnTable') IS NOT NULL)
                DROP TABLE #InformacaoesOnTable;

            IF(OBJECT_ID('TEMPDB..#Parcial') IS NOT NULL)
                DROP TABLE #Parcial;

            IF(OBJECT_ID('TEMPDB..#Alteracoes') IS NOT NULL)
                DROP TABLE #Alteracoes;

            IF(OBJECT_ID('TEMPDB..#SchemasExcessao') IS NOT NULL)
                DROP TABLE #SchemasExcessao;

            CREATE TABLE #SchemasExcessao
            (
                SchemaName VARCHAR(128) NOT NULL
            );

            INSERT INTO #SchemasExcessao(SchemaName)VALUES('%HangFire%');

            CREATE TABLE #Alteracoes
            (
                RowId                INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
                [ObjectId]           INT,
                [SchemaName]         VARCHAR(140),
                [TableName]          VARCHAR(140),
                [Chave]              VARCHAR(200),
                [PrimeiraChave]      VARCHAR(200),
                [ColunaIncluida]     VARCHAR(1000),
                [CreateIndex]        VARCHAR(8000),
                [MagicBenefitNumber] REAL,
                [Melhor]             DECIMAL(18, 2),
                ScriptDrop           NVARCHAR(400),
                ScriptCreate         NVARCHAR(400),
            );

            CREATE TABLE #InformacaoesOnTable
            (
                ObjectId                 BIGINT,
                [QuantidadeIndiceTabela] TINYINT
            );

            CREATE TABLE #Parcial
            (
                RowId                       INT NOT NULL IDENTITY(1, 1),
                ObjectId                    INT,
                TotalObjetcId               SMALLINT,
                SchemaName                  VARCHAR(140),
                TableName                   VARCHAR(140),
                IndexName                   VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [QuantidadeIndiceTabela]    TINYINT,
                [ColunaIncluida]            VARCHAR(1000),
                AvgEstimatedImpact          REAL,
                MagicBenefitNumber          REAL,
                PotentialReadOp             INT,
                [reads]                     INT,
                PercCusto                   DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000)
            );

            IF(OBJECT_ID('TEMPDB..#ResultAllIndex') IS NOT NULL)
                DROP TABLE #ResultAllIndex;

            CREATE TABLE #ResultAllIndex
            (
                [ObjectId]           INT,
                [ObjectName]         VARCHAR(300),
                [RowsInTable]        INT,
                [IndexName]          VARCHAR(128),
                [Usado]              BIT,
                [UserSeeks]          INT,
                [UserScans]          INT,
                [UserLookups]        INT,
                [UserUpdates]        INT,
                [Reads]              BIGINT,
                [Write]              INT,
                [CountPageSplitPage] INT,
                [PercAproveitamento] DECIMAL(18, 2),
                [PercCustoMedio]     DECIMAL(18, 2),
                [IsBadIndex]         INT,
                [IndexId]            SMALLINT,
                [IndexsizeKB]        BIGINT,
                [IndexsizeMB]        DECIMAL(18, 2),
                [IndexSizePorTipoMB] DECIMAL(18, 2),
                [Chave]              VARCHAR(899),
                PrimeiraChave        AS (IIF(CHARINDEX(',', [Chave], 0) > 0, SUBSTRING([Chave], 0, CHARINDEX(',', [Chave], 0)), [Chave])),
                [ColunasIncluidas]   VARCHAR(899),
                [IsUnique]           BIT,
                [IgnoreDupKey]       BIT,
                [IsprimaryKey]       BIT,
                [IsUniqueConstraint] BIT,
                [FillFact]           TINYINT,
                [AllowRowLocks]      BIT,
                [AllowPageLocks]     BIT,
                [HasFilter]          BIT,
                [TypeIndex]          TINYINT
            );

            IF EXISTS (
                          SELECT 1
                            FROM sys.syscursors AS S
                           WHERE
                              S.cursor_name = 'cursor_CreateOrAlterIndex'
                      )
                BEGIN
                    DEALLOCATE cursor_CreateOrAlterIndex;
                END;

            CREATE TABLE #IndexOnDataBase
            (
                [SnapShotDate]         DATETIME2(3),
                ObjectId               INT,
                [RowsInTable]          INT,
                [ObjectName]           VARCHAR(260),
                [index_id]             SMALLINT,
                [IndexName]            VARCHAR(128),
                [Reads]                BIGINT,
                [Write]                INT,
                [%Aproveitamento]      DECIMAL(18, 2),
                [%Custo Medio]         DECIMAL(18, 2),
                [Perc_scan]            DECIMAL(10, 2),
                AvgPercScan            DECIMAL(10, 2),
                [Media IsBad]          INT,
                [Media Reads]          DECIMAL(10, 2),
                [Media Writes]         DECIMAL(10, 2),
                [Media Aproveitamento] DECIMAL(10, 2),
                [Media Custo]          DECIMAL(10, 2),
                [IsBadIndex]           BIT,
                [MaxAnaliseForTable]   SMALLINT,
                [MaxAnaliseForIndex]   INT,
                [QtdAnalize]           INT,
                [Analise]              SMALLINT,
                [is_unique_constraint] BIT,
                [is_primary_key]       BIT,
                [is_unique]            BIT
            );

            CREATE TABLE #MissingIndex
            (
                ObjectId                    INT,
                [TotalObjetcId]             INT,
                SchemaName                  VARCHAR(140),
                TableName                   VARCHAR(140),
                [IndexName]                 VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [ColunaIncluida]            VARCHAR(1000),
                AvgEstimatedImpact          REAL,
                MagicBenefitNumber          REAL,
                PotentialReadOp             INT,
                [reads]                     INT,
                PercCusto                   DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000)
            );

            CREATE TABLE #NovosIndices
            (
                RowId                       INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
                ObjectId                    INT,
                SchemaName                  VARCHAR(140),
                TableName                   VARCHAR(140),
                IndexName                   VARCHAR(200),
                [Chave]                     VARCHAR(200),
                [PrimeiraChave]             VARCHAR(200),
                [ExisteIndiceNaChave]       INT,
                [ChavePertenceAOutroIndice] INT,
                [QuantidadeIndiceTabela]    TINYINT,
                [ColunaIncluida]            VARCHAR(1000),
                AvgEstimatedImpact          REAL,
                MagicBenefitNumber          REAL,
                PotentialReadOp             INT,
                [reads]                     INT,
                PercCusto                   DECIMAL(10, 2),
                [CreateIndex]               VARCHAR(8000),
                AvgPercScan                 DECIMAL(10, 2)
            );

            INSERT INTO #MissingIndex
            EXEC HealthCheck.uspMissingIndex @defaultTunningPerform = @defaultTunningPerform;

            DELETE S
              FROM #MissingIndex S
                   INNER JOIN(SELECT SSE.SchemaName FROM #SchemasExcessao AS SSE)Filtro ON S.SchemaName LIKE Filtro.SchemaName;

            DELETE MI
              FROM #MissingIndex AS MI
             WHERE
                EXISTS (
                           SELECT *
                             FROM sys.indexes AS I
                            WHERE
                               I.object_id = MI.ObjectId
                               AND I.type_desc = 'CLUSTERED COLUMNSTORE'
                       );

            IF(EXISTS (SELECT * FROM #MissingIndex AS MI))
                BEGIN
                    INSERT INTO #InformacaoesOnTable
                    SELECT T.object_id,
                           IX.TotalIndiceTabela
                      FROM sys.tables T
                           JOIN(
                                   SELECT IX.object_id,
                                          TotalIndiceTabela = COUNT(*)
                                     FROM sys.indexes IX
                                    WHERE
                                       IX.is_disabled = 0
                                       AND IX.is_hypothetical = 0
                                       AND IX.type > 0
                                    GROUP BY
                                       IX.object_id
                               )IX ON T.object_id = IX.object_id
                     WHERE
                        EXISTS (
                                   SELECT * FROM #MissingIndex I WHERE I.ObjectId = IX.object_id
                               );

                    INSERT INTO #Parcial(
                                            ObjectId,
                                            TotalObjetcId,
                                            SchemaName,
                                            TableName,
                                            IndexName,
                                            Chave,
                                            PrimeiraChave,
                                            ExisteIndiceNaChave,
                                            ChavePertenceAOutroIndice,
                                            QuantidadeIndiceTabela,
                                            ColunaIncluida,
                                            AvgEstimatedImpact,
                                            MagicBenefitNumber,
                                            PotentialReadOp,
                                            reads,
                                            PercCusto,
                                            CreateIndex
                                        )
                    SELECT MI.ObjectId,
                           MI.TotalObjetcId,
                           MI.SchemaName,
                           MI.TableName,
                           MI.IndexName,
                           MI.Chave,
                           MI.PrimeiraChave,
                           MI.ExisteIndiceNaChave,
                           MI.ChavePertenceAOutroIndice,
                           Info.QuantidadeIndiceTabela,
                           MI.ColunaIncluida,
                           MI.AvgEstimatedImpact,
                           MI.MagicBenefitNumber,
                           MI.PotentialReadOp,
                           MI.reads,
                           MI.PercCusto,
                           MI.CreateIndex
                      FROM #MissingIndex AS MI
                           JOIN #InformacaoesOnTable Info ON MI.ObjectId = Info.ObjectId;

                    /*Indices de objetos únicos*/
                    INSERT INTO #NovosIndices(
                                                 ObjectId,
                                                 SchemaName,
                                                 TableName,
                                                 IndexName,
                                                 Chave,
                                                 PrimeiraChave,
                                                 ExisteIndiceNaChave,
                                                 ChavePertenceAOutroIndice,
                                                 QuantidadeIndiceTabela,
                                                 ColunaIncluida,
                                                 AvgEstimatedImpact,
                                                 MagicBenefitNumber,
                                                 PotentialReadOp,
                                                 reads,
                                                 PercCusto,
                                                 CreateIndex
                                             )
                    SELECT MI.ObjectId,
                           MI.SchemaName,
                           MI.TableName,
                           MI.IndexName,
                           MI.Chave,
                           MI.PrimeiraChave,
                           MI.ExisteIndiceNaChave,
                           MI.ChavePertenceAOutroIndice,
                           MI.QuantidadeIndiceTabela,
                           MI.ColunaIncluida,
                           MI.AvgEstimatedImpact,
                           MI.MagicBenefitNumber,
                           MI.PotentialReadOp,
                           MI.reads,
                           MI.PercCusto,
                           MI.CreateIndex
                      FROM #Parcial MI
                     WHERE
                        MI.TotalObjetcId = 1
                        AND MI.ExisteIndiceNaChave = 0
                        AND MI.ChavePertenceAOutroIndice = 0
                        AND MI.QuantidadeIndiceTabela < @QuantidadeMaximaIndiceTabela; --  -(quatro indices nonclustered)

                    ;

                    WITH EscolheMelhorIndice
                        AS
                        (
                            SELECT MI.ObjectId,
                                   MI.SchemaName,
                                   MI.TableName,
                                   MI.IndexName,
                                   MI.Chave,
                                   MI.PrimeiraChave,
                                   MI.ExisteIndiceNaChave,
                                   MI.ChavePertenceAOutroIndice,
                                   MI.QuantidadeIndiceTabela,
                                   MI.ColunaIncluida,
                                   MI.AvgEstimatedImpact,
                                   MI.MagicBenefitNumber,
                                   MelhorIndice = ROW_NUMBER() OVER (PARTITION BY MI.ObjectId,
                                                                                  MI.PrimeiraChave
                                                                         ORDER BY
                                                                         MI.MagicBenefitNumber DESC,
                                                                         MI.AvgEstimatedImpact DESC
                                                                    ),
                                   MI.PotentialReadOp,
                                   MI.reads,
                                   MI.PercCusto,
                                   MI.CreateIndex
                              FROM #Parcial AS MI
                             WHERE
                                MI.TotalObjetcId > 1
                                AND MI.QuantidadeIndiceTabela < @QuantidadeMaximaIndiceTabela
                                AND MI.ExisteIndiceNaChave = 0
                                AND MI.ChavePertenceAOutroIndice = 0
                        )
                    INSERT INTO #NovosIndices(
                                                 ObjectId,
                                                 SchemaName,
                                                 TableName,
                                                 IndexName,
                                                 Chave,
                                                 PrimeiraChave,
                                                 ExisteIndiceNaChave,
                                                 ChavePertenceAOutroIndice,
                                                 QuantidadeIndiceTabela,
                                                 ColunaIncluida,
                                                 AvgEstimatedImpact,
                                                 MagicBenefitNumber,
                                                 PotentialReadOp,
                                                 reads,
                                                 PercCusto,
                                                 CreateIndex
                                             )
                    SELECT Escolha.ObjectId,
                           Escolha.SchemaName,
                           Escolha.TableName,
                           Escolha.IndexName,
                           Escolha.Chave,
                           Escolha.PrimeiraChave,
                           Escolha.ExisteIndiceNaChave,
                           Escolha.ChavePertenceAOutroIndice,
                           Escolha.QuantidadeIndiceTabela,
                           Escolha.ColunaIncluida,
                           Escolha.AvgEstimatedImpact,
                           Escolha.MagicBenefitNumber,
                           Escolha.PotentialReadOp,
                           Escolha.reads,
                           Escolha.PercCusto,
                           Escolha.CreateIndex
                      FROM EscolheMelhorIndice Escolha
                     WHERE
                        Escolha.MelhorIndice = 1;

                    IF(EXISTS (
                                  SELECT NI.ObjectId,
                                         NI.PrimeiraChave,
                                         NI.MagicBenefitNumber,
                                         COUNT(*) Total
                                    FROM #NovosIndices AS NI
                                   GROUP BY
                                      NI.ObjectId,
                                      NI.PrimeiraChave,
                                      NI.MagicBenefitNumber
                                  HAVING
                                      COUNT(*) > 1
                              )
                      )
                        BEGIN
                            WITH Dados
                                AS
                                (
                                    SELECT NI.ObjectId,
                                           NI.PrimeiraChave,
                                           NI.Chave,
                                           NI.MagicBenefitNumber,
                                           ROW_NUMBER() OVER (PARTITION BY NI.ObjectId,
                                                                           NI.PrimeiraChave,
                                                                           NI.MagicBenefitNumber
                                                                  ORDER BY
                                                                  LEN(NI.Chave)
                                                             ) ordem
                                      FROM #NovosIndices AS NI
                                )
                            DELETE R FROM Dados R WHERE R.ordem > 1;
                        END;

                    IF(EXISTS (SELECT * FROM #Parcial AS P WHERE P.ExisteIndiceNaChave = 1))
                        BEGIN
                            ;WITH Duplicate
                                 AS
                                 (
                                     SELECT P.ObjectId,
                                            P.SchemaName,
                                            P.TableName,
                                            P.IndexName,
                                            P.PrimeiraChave,
                                            P.ColunaIncluida,
                                            P.MagicBenefitNumber,
                                            RN = ROW_NUMBER() OVER (PARTITION BY P.ObjectId,
                                                                                 P.PrimeiraChave
                                                                        ORDER BY
                                                                        P.MagicBenefitNumber DESC,
                                                                        P.AvgEstimatedImpact DESC
                                                                   )
                                       FROM #Parcial AS P
                                      WHERE
                                         P.ExisteIndiceNaChave = 1
                                 )
                            DELETE R FROM Duplicate R WHERE R.RN > 1;

                            ;WITH MelhoresColunas
                                AS
                                (
                                    SELECT P.ObjectId,
                                           P.SchemaName,
                                           P.TableName,
                                           P.Chave,
                                           P.PrimeiraChave,
                                           P.ColunaIncluida,
                                           P.CreateIndex,
                                           MagicBenefitNumber = CAST(P.MagicBenefitNumber AS DECIMAL(18, 2)),
                                           MaxMagicBenefitNumber = MAX(CAST(P.MagicBenefitNumber AS DECIMAL(18, 2))) OVER (PARTITION BY P.ObjectId, P.PrimeiraChave)
                                      FROM #Parcial AS P
                                     WHERE
                                        P.ExisteIndiceNaChave = 1
                                )
                            INSERT INTO #Alteracoes(
                                                       ObjectId,
                                                       SchemaName,
                                                       TableName,
                                                       Chave,
                                                       PrimeiraChave,
                                                       ColunaIncluida,
                                                       CreateIndex,
                                                       MagicBenefitNumber,
                                                       Melhor,
                                                       ScriptDrop,
                                                       ScriptCreate
                                                   )
                            SELECT P.ObjectId,
                                   P.SchemaName,
                                   P.TableName,
                                   P.Chave,
                                   P.PrimeiraChave,
                                   P.ColunaIncluida,
                                   P.CreateIndex,
                                   P.MagicBenefitNumber,
                                   P.MaxMagicBenefitNumber,
                                   NULL,
                                   NULL
                              FROM MelhoresColunas AS P
                             WHERE
                                P.MagicBenefitNumber = P.MaxMagicBenefitNumber;

                            INSERT INTO #ResultAllIndex
                            EXEC HealthCheck.uspAllIndex @TableObjectIds = @tableObjectsIds;

                            DELETE RAI FROM #ResultAllIndex AS RAI WHERE RAI.TypeIndex = 1;

                            IF(EXISTS (
                                          SELECT * FROM #Alteracoes AS A WHERE A.ColunaIncluida IS NOT NULL
                                      )
                              )
                                BEGIN

                                    /* declare variables */
                                    DECLARE @RowId              INT,
                                            @TempObjectId       INT,
                                            @TempSchemaName     VARCHAR(128),
                                            @TempTableName      VARCHAR(128),
                                            @TempChave          VARCHAR(500),
                                            @TempPrimeiraChave  VARCHAR(128),
                                            @TempColunaIncluida VARCHAR(999);

                                    DECLARE cursor_AlteraIndex CURSOR FAST_FORWARD READ_ONLY FOR
                                    SELECT A.RowId,
                                           A.ObjectId,
                                           A.SchemaName,
                                           A.TableName,
                                           A.Chave,
                                           A.PrimeiraChave,
                                           A.ColunaIncluida
                                      FROM #Alteracoes A;

                                    OPEN cursor_AlteraIndex;

                                    FETCH NEXT FROM cursor_AlteraIndex
                                     INTO @RowId,
                                          @TempObjectId,
                                          @TempSchemaName,
                                          @TempTableName,
                                          @TempChave,
                                          @TempPrimeiraChave,
                                          @TempColunaIncluida;

                                    WHILE @@FETCH_STATUS = 0
                                        BEGIN
                                            DECLARE @ColunaIncluidaAntiga VARCHAR(1000);

                                            ;WITH ColunaIncluidaAntiga
                                                AS
                                                (
                                                    SELECT RAI.ObjectId,
                                                           RAI.IndexName,
                                                           RAI.Chave,
                                                           RAI.ColunasIncluidas,
                                                           RAI.PercAproveitamento,
                                                           MenorAproveitamento = MIN(RAI.PercAproveitamento) OVER (PARTITION BY RAI.ObjectId,
                                                                                                                                RAI.PrimeiraChave
                                                                                                                       ORDER BY
                                                                                                                       RAI.PercAproveitamento
                                                                                                                  )
                                                      FROM #ResultAllIndex AS RAI
                                                     WHERE
                                                        RAI.ObjectId = @TempObjectId
                                                        AND RAI.ColunasIncluidas IS NOT NULL
                                                        AND RAI.PrimeiraChave = @TempPrimeiraChave
                                                )
                                            SELECT @ColunaIncluidaAntiga = (
                                                                               SELECT TOP 1 C.ColunasIncluidas
                                                                                 FROM ColunaIncluidaAntiga C
                                                                                WHERE
                                                                                   C.PercAproveitamento = C.MenorAproveitamento
                                                                           );

                                            DECLARE @indexNameTemp VARCHAR(128);

                                            ;WITH PiorIndice
                                                AS
                                                (
                                                    SELECT RAI.IndexName,
                                                           RAI.PercAproveitamento,
                                                           MIN(RAI.PercAproveitamento) OVER () AS MenorAproveitamento
                                                      FROM #ResultAllIndex AS RAI
                                                     WHERE
                                                        RAI.ObjectId = @TempObjectId
                                                        AND RAI.PrimeiraChave = @TempPrimeiraChave
                                                        AND RAI.TypeIndex > 1
                                                )
                                            SELECT @indexNameTemp = PiorIndice.IndexName
                                              FROM PiorIndice
                                             WHERE
                                                PiorIndice.PercAproveitamento = PiorIndice.MenorAproveitamento;

                                            IF(@ColunaIncluidaAntiga IS NOT NULL)
                                                BEGIN
                                                    DECLARE @NewColluns VARCHAR(999) = (
                                                                                           SELECT STUFF((
                                                                                                            SELECT ', ' + t2.Conteudo
                                                                                                              FROM(
                                                                                                                      SELECT FSV.Conteudo
                                                                                                                        FROM(
                                                                                                                                SELECT C2.Conteudo
                                                                                                                                  FROM sys.tables AS T
                                                                                                                                       JOIN sys.columns AS C ON T.object_id = C.object_id
                                                                                                                                       JOIN sys.types AS t2 ON C.user_type_id = t2.user_type_id
                                                                                                                                       CROSS APPLY(
                                                                                                                                                      SELECT FSV.Conteudo
                                                                                                                                                        FROM Sistema.fnSplitValues(@TempColunaIncluida, ',') FSV
                                                                                                                                                       WHERE
                                                                                                                                                          FSV.Conteudo COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT
                                                                                                                                                  )C2
                                                                                                                                 WHERE
                                                                                                                                    T.object_id = @TempObjectId
                                                                                                                                    AND C.is_sparse = 0
                                                                                                                                    AND C.xml_collection_id = 0
                                                                                                                                    AND C.is_xml_document = 0
                                                                                                                                    AND C.is_computed = 0
                                                                                                                                    AND C.max_length <> -1
                                                                                                                                    AND t2.name NOT IN ('xml', 'varbinary', 'sql_variant', 'nvarchar')
                                                                                                                            ) AS FSV
                                                                                                                      UNION
                                                                                                                      SELECT FSV2.Conteudo
                                                                                                                        FROM(
                                                                                                                                SELECT C2.Conteudo
                                                                                                                                  FROM sys.tables AS T
                                                                                                                                       JOIN sys.columns AS C ON T.object_id = C.object_id
                                                                                                                                       JOIN sys.types AS t2 ON C.user_type_id = t2.user_type_id
                                                                                                                                       CROSS APPLY(
                                                                                                                                                      SELECT FSV.Conteudo
                                                                                                                                                        FROM Sistema.fnSplitValues(@ColunaIncluidaAntiga, ',') FSV
                                                                                                                                                       WHERE
                                                                                                                                                          FSV.Conteudo COLLATE DATABASE_DEFAULT = C.name COLLATE DATABASE_DEFAULT
                                                                                                                                                  )C2
                                                                                                                                 WHERE
                                                                                                                                    T.object_id = @TempObjectId
                                                                                                                                    AND C.is_sparse = 0
                                                                                                                                    AND C.xml_collection_id = 0
                                                                                                                                    AND C.is_xml_document = 0
                                                                                                                                    AND C.is_computed = 0
                                                                                                                                    AND C.max_length <> -1
                                                                                                                                    AND t2.name NOT IN ('xml', 'varbinary', 'sql_variant', 'nvarchar')
                                                                                                                            ) AS FSV2
                                                                                                                  ) AS t2
                                                                                                            FOR XML PATH(''), TYPE
                                                                                                        ).value('.', 'varchar(max)'), 1, 2, ''
                                                                                                       )
                                                                                       );
                                                END;

                                            IF(LEN(@indexNameTemp) > 0)
                                                BEGIN
                                                    UPDATE A
                                                       SET A.ScriptDrop = CONCAT('DROP INDEX ', QUOTENAME(@indexNameTemp), ' ON ', QUOTENAME(@TempSchemaName), '.', QUOTENAME(@TempTableName)),
                                                           A.CreateIndex = CONCAT('CREATE INDEX ', QUOTENAME(CONCAT('IX_', @TempSchemaName, @TempTableName, '_', REPLACE(@TempChave, ',', '_'))), ' ON ', QUOTENAME(@TempSchemaName), '.', QUOTENAME(@TempTableName), ' (', @TempChave, ') ', IIF(@NewColluns IS NOT NULL AND LEN(@NewColluns) > 0, ' INCLUDE (' + @NewColluns + ')', ''), IIF(@TipoVersao IN ('Azure', 'Enterprise'), ' WITH(ONLINE = ON )', ''))
                                                      FROM #Alteracoes AS A
                                                     WHERE
                                                        A.RowId = @RowId;
                                                END;

                                            FETCH NEXT FROM cursor_AlteraIndex
                                             INTO @RowId,
                                                  @TempObjectId,
                                                  @TempSchemaName,
                                                  @TempTableName,
                                                  @TempChave,
                                                  @TempPrimeiraChave,
                                                  @TempColunaIncluida;
                                        END;

                                    CLOSE cursor_AlteraIndex;
                                    DEALLOCATE cursor_AlteraIndex;
                                END;
                        END;

                    IF(EXISTS (SELECT * FROM #NovosIndices AS NI) AND @Efetivar = 1)
                        BEGIN
                            /* declare variables */
                            DECLARE @ObjectId  VARCHAR(128),
                                    @IndexName VARCHAR(128);
                            DECLARE @Script NVARCHAR(1000);

                            DECLARE cursor_CriaIndice CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT NI.ObjectId, NI.IndexName, NI.CreateIndex FROM #NovosIndices AS NI;

                            OPEN cursor_CriaIndice;

                            FETCH NEXT FROM cursor_CriaIndice
                             INTO @ObjectId,
                                  @IndexName,
                                  @Script;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    IF(@Script IS NOT NULL)
                                        BEGIN
                                            EXEC sys.sp_executesql @Script;
                                        END;

                                    FETCH NEXT FROM cursor_CriaIndice
                                     INTO @ObjectId,
                                          @IndexName,
                                          @Script;
                                END;

                            CLOSE cursor_CriaIndice;
                            DEALLOCATE cursor_CriaIndice;
                        END;

                    IF(EXISTS (SELECT * FROM #Alteracoes AS RA) AND @Efetivar = 1)
                        BEGIN

                            /* declare variables */
                            DECLARE @RaObjectId  VARCHAR(128),
                                    @DeleteIndex NVARCHAR(1000),
                                    @NewIndex    NVARCHAR(1000);

                            DECLARE cursor_DeletaIndiceECriaNovo CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT NI.ObjectId, NI.ScriptDrop, NI.CreateIndex FROM #Alteracoes AS NI;

                            OPEN cursor_DeletaIndiceECriaNovo;

                            FETCH NEXT FROM cursor_DeletaIndiceECriaNovo
                             INTO @RaObjectId,
                                  @DeleteIndex,
                                  @NewIndex;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    EXEC sys.sp_executesql @DeleteIndex;

                                    EXEC sys.sp_executesql @NewIndex;

                                    FETCH NEXT FROM cursor_DeletaIndiceECriaNovo
                                     INTO @RaObjectId,
                                          @DeleteIndex,
                                          @NewIndex;
                                END;

                            CLOSE cursor_DeletaIndiceECriaNovo;
                            DEALLOCATE cursor_DeletaIndiceECriaNovo;
                        END;
                END;

            IF(@VisualizarMissing = 1)
                BEGIN
                    SELECT 'Missings' AS Sugestao,
                           MI.ObjectId,
                           MI.TotalObjetcId,
                           MI.SchemaName,
                           MI.TableName,
                           IOT.QuantidadeIndiceTabela,
                           MI.IndexName,
                           MI.Chave,
                           MI.PrimeiraChave,
                           MI.ExisteIndiceNaChave,
                           MI.ChavePertenceAOutroIndice,
                           MI.ColunaIncluida,
                           MI.AvgEstimatedImpact,
                           MI.MagicBenefitNumber,
                           MI.PotentialReadOp,
                           MI.reads,
                           PercCustoMedio = MI.PercCusto,
                           MI.CreateIndex
                      FROM #MissingIndex MI
                           JOIN #InformacaoesOnTable AS IOT ON MI.ObjectId = IOT.ObjectId;
                END;

            IF(@VisualizarCreate = 1)
                BEGIN
                    SELECT 'Create' AS Sugestao,
                           NI.RowId,
                           NI.ObjectId,
                           NI.SchemaName,
                           NI.TableName,
                           NI.QuantidadeIndiceTabela,
                           NI.IndexName,
                           NI.Chave,
                           NI.PrimeiraChave,
                           NI.ExisteIndiceNaChave,
                           NI.ChavePertenceAOutroIndice,
                           NI.ColunaIncluida,
                           NI.AvgEstimatedImpact,
                           NI.MagicBenefitNumber,
                           NI.PotentialReadOp,
                           NI.reads,
                           PercCustoMedio = NI.PercCusto,
                           NI.CreateIndex,
                           PercScan = NI.AvgPercScan
                      FROM #NovosIndices AS NI;
                END;

            IF(@VisualizarAlteracoes = 1)
                BEGIN
                    SELECT 'Alteracao' AS Sugestao,
                           A.RowId,
                           A.ObjectId,
                           A.SchemaName,
                           A.TableName,
                           A.Chave,
                           A.PrimeiraChave,
                           A.ColunaIncluida,
                           A.CreateIndex,
                           A.MagicBenefitNumber,
                           A.Melhor,
                           A.ScriptDrop,
                           A.ScriptCreate
                      FROM #Alteracoes AS A;
                END;
        END TRY
        BEGIN CATCH
            IF(@@TRANCOUNT > 0)
                ROLLBACK TRANSACTION;

            DECLARE @ErrorNumber INT = ERROR_NUMBER();
            DECLARE @ErrorLine INT = ERROR_LINE();
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();

            PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
            PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

            PRINT 'Error detected, all changes reversed.';
        END CATCH;
    END;





/* ==================================================================
--Data: 15/01/2020 
--Autor :Wesley Neves
--Observação: Inicio das Procedures do Bent Zoar
 
-- ==================================================================
*/












GO





CREATE   OR ALTER  PROCEDURE HealthCheck.uspInefficientIndex (
    @percentualAproveitamento SMALLINT = 8,
    @EfetivarDelecao BIT = 0,
    @NumberOfDaysForInefficientIndex SMALLINT = 7,
    @MostrarIndiceIneficiente BIT = 1)
AS
BEGIN

    SET NOCOUNT ON;

    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;



    --DECLARE @percentualAproveitamento  SMALLINT = 8,
    --        @EfetivarDelecao           BIT      = 0,
    --        @MostrarIndiceIneficiente  BIT      = 1,
    --        @NumberOfDaysForInefficientIndex SMALLINT = 7;



    SET @NumberOfDaysForInefficientIndex = ISNULL(@NumberOfDaysForInefficientIndex, 7);

    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;


    IF (OBJECT_ID('TEMPDB..#IndicesIneficientes') IS NOT NULL)
        DROP TABLE #IndicesIneficientes;

    IF (OBJECT_ID('TEMPDB..#MarcadosParaDeletar') IS NOT NULL)
        DROP TABLE #MarcadosParaDeletar;

   CREATE TABLE #IndicesIneficientes (
    [SnapShotDate] DATETIME2(3),
    [ObjectId] INT,
    [RowsInTable] INT,
    [ObjectName] VARCHAR(260),
    [IndexId] SMALLINT,
    [IndexName] VARCHAR(128),
    [Reads] BIGINT,
    [Write] INT,
    [PercAproveitamento] DECIMAL(18, 2),
    [PercCustoMedio] DECIMAL(18, 2),
    [PercScan] DECIMAL(18, 2),
    [AvgPercScan] DECIMAL(10, 2),
    [AvgIsBad] INT,
    [AvgReads] DECIMAL(10, 2),
    [AvgWrites] DECIMAL(10, 2),
    [AvgAproveitamento] DECIMAL(10, 2),
    [AvgCusto] DECIMAL(10, 2),
    [IsBadIndex] BIT,
    [MaxAnaliseForTable] SMALLINT,
    [MaxAnaliseForIndex] INT,
    [QtdAnalize] INT,
    [Analise] SMALLINT,
    [IsUniqueConstraint] BIT,
    [IsPrimaryKey] BIT,
    [IsUnique] BIT);
	

    CREATE TABLE #MarcadosParaDeletar (
        RowId SMALLINT IDENTITY(1, 1),
        ObjectId INT,
        IndexId SMALLINT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        [Script] VARCHAR(500));


	INSERT INTO #IndicesIneficientes
	EXEC HealthCheck.uspIndexMedia @SnapShotDayMedia = @NumberOfDaysForInefficientIndex, -- smallint
								   @IsUniqueConstraint = 0, -- bit
								   @IsUnique = 0, -- bit
								   @IsPrimaryKey = 0,
								   @AvgIsBad = 1, -- bit
								   @PercentualMaximoAcesso =@percentualAproveitamento



		IF (EXISTS (SELECT 1 FROM #IndicesIneficientes AS II))
		BEGIN

			DELETE I
			  FROM #IndicesIneficientes I
			 WHERE I.ObjectName LIKE '%HangFire%'

			DELETE INE
			  FROM #IndicesIneficientes AS INE
			 WHERE NOT EXISTS (   SELECT 1
									FROM sys.indexes AS I
								   WHERE I.name COLLATE DATABASE_DEFAULT = INE.IndexName  COLLATE DATABASE_DEFAULT)


			DELETE I
			  FROM #IndicesIneficientes AS I
			 WHERE I.MaxAnaliseForIndex < @NumberOfDaysForInefficientIndex

		END

						
				
	
	IF (EXISTS (SELECT 1 FROM #IndicesIneficientes AS II))
    BEGIN

        INSERT INTO #MarcadosParaDeletar (ObjectId,
                                          IndexId,
                                          ObjectName,
                                          IndexName,
                                          Script)
        SELECT DISTINCT I.ObjectId,
               I.IndexId,
               I.ObjectName,
               I.IndexName,
               Script = CONCAT(' IF(EXISTS(SELECT 1 FROM sys.indexes AS I',
			   ' WHERE I.name =',CHAR(39),I.IndexName,CHAR(39),')) BEGIN
			   DROP INDEX  ', QUOTENAME(I.IndexName), ' ON ', I.ObjectName,' END')
          FROM #IndicesIneficientes AS I;


        IF (   @EfetivarDelecao = 1
         AND   (EXISTS (   SELECT 1
                             FROM #MarcadosParaDeletar AS MPD)))
        BEGIN


            /* declare variables */

            DECLARE @Script NVARCHAR(1000);
            DECLARE @RowId SMALLINT;
            DECLARE cursor_Delecao CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT D.RowId,
                   D.Script
              FROM #MarcadosParaDeletar D;

            OPEN cursor_Delecao;

            FETCH NEXT FROM cursor_Delecao
             INTO @RowId,
                  @Script;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                 EXEC sys.sp_executesql @Script;

                FETCH NEXT FROM cursor_Delecao
                 INTO @RowId,
                      @Script;
            END;

            CLOSE cursor_Delecao;
            DEALLOCATE cursor_Delecao;
        END;




    END;

    IF (@MostrarIndiceIneficiente = 1)
    BEGIN


        SELECT II.ObjectId,
               II.ObjectName,
               II.IndexId,
               II.IndexName,
               II.AvgIsBad,
               II.AvgReads,
               II.AvgWrites,
               II.AvgAproveitamento,
               II.AvgCusto,
               II.IsBadIndex,
               II.MaxAnaliseForTable,
               II.MaxAnaliseForIndex,
               MPD.Script
          FROM #IndicesIneficientes AS II
          JOIN #MarcadosParaDeletar AS MPD
            ON II.ObjectId = MPD.ObjectId
           AND II.IndexId  = MPD.IndexId
		   ORDER BY II.ObjectId,II.AvgReads

    END;
END;

GO




GO


-- Unused Index Script
/*
https://blog.sqlauthority.com/2011/01/04/sql-server-2008-unused-index-script-download/
https://www.sqlshack.com/how-to-identify-and-monitor-unused-indexes-in-sql-server/
https://www.mssqltips.com/sqlservertutorial/256/discovering-unused-indexes/
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspUnusedIndex (
    @EfetivarDelecao BIT = 0,
    @QuantidadeDiasConfigurado SMALLINT = 30,
    @MostrarIndice BIT = 1)
AS
BEGIN

    SET NOCOUNT ON;


    
--DECLARE @EfetivarDelecao           BIT      = 0,
--        @QuantidadeDiasConfigurado SMALLINT = 1,
--        @MostrarIndice             BIT      = 1;
	

    DECLARE @StartTime DATETIME;

    SELECT @StartTime = GETDATE();

    SET @QuantidadeDiasConfigurado = ISNULL(@QuantidadeDiasConfigurado, 30);

    IF (OBJECT_ID('TEMPDB..#NoUsageIndex') IS NOT NULL)
        DROP TABLE #NoUsageIndex;


   CREATE TABLE #NoUsageIndex (
    [SnapShotDate] DATETIME2(3),
    [ObjectId] INT,
    [RowsInTable] INT,
    [ObjectName] VARCHAR(260),
    [IndexId] SMALLINT,
    [IndexName] VARCHAR(128),
    [Reads] BIGINT,
    [Write] INT,
    [PercAproveitamento] DECIMAL(18, 2),
    [PercCustoMedio] DECIMAL(18, 2),
    [PercScan] DECIMAL(18, 2),
    [AvgPercScan] DECIMAL(10, 2),
    [AvgIsBad] INT,
    [AvgReads] DECIMAL(10, 2),
    [AvgWrites] DECIMAL(10, 2),
    [AvgAproveitamento] DECIMAL(10, 2),
    [AvgCusto] DECIMAL(10, 2),
    [IsBadIndex] BIT,
    [MaxAnaliseForTable] SMALLINT,
    [MaxAnaliseForIndex] INT,
    [QtdAnalize] INT,
    [Analise] SMALLINT,
    [IsUniqueConstraint] BIT,
    [IsPrimaryKey] BIT,
    [IsUnique] BIT);



INSERT INTO #NoUsageIndex
EXEC HealthCheck.uspIndexMedia @SnapShotDayMedia = @QuantidadeDiasConfigurado, -- smallint
                               @IsUniqueConstraint = 0, -- bit
                               @IsUnique = 0, -- bit
                               @IsPrimaryKey = 0 -- bit






IF(EXISTS(SELECT 1 FROM #NoUsageIndex AS NUI))
BEGIN
		

		DELETE I FROM #NoUsageIndex I
		WHERE I.ObjectName  LIKE '%HangFire%'

		DELETE I FROM #NoUsageIndex I
		WHERE I.AvgAproveitamento > 0


    	DELETE IX
        FROM #NoUsageIndex IX
	    WHERE IX.IndexName COLLATE DATABASE_DEFAULT NOT IN ( SELECT I.name COLLATE DATABASE_DEFAULT FROM sys.indexes AS I )


		DELETE N
		  FROM #NoUsageIndex N
		 WHERE N.MaxAnaliseForIndex < @QuantidadeDiasConfigurado;

END

	
	
		



    IF (EXISTS (SELECT 1 FROM #NoUsageIndex AS [INUI]) AND @EfetivarDelecao = 1)
    BEGIN

        /* declare variables */
        DECLARE @ObjectId  BIGINT,
                @IndexId   SMALLINT,
                @IndexName VARCHAR(1000),
                @Script    NVARCHAR(800);




        DECLARE cursor_DelecaoIndice CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT DISTINCT INUI.ObjectId,
               INUI.IndexId,
               INUI.IndexName,
               Script = CONCAT(' IF(EXISTS(SELECT 1 FROM sys.indexes AS I',
			   ' WHERE I.name =',CHAR(39),INUI.IndexName,CHAR(39),')) BEGIN
			   DROP INDEX  ', QUOTENAME(INUI.IndexName), ' ON ', INUI.ObjectName,' END')
          FROM #NoUsageIndex AS [INUI];

         



        OPEN cursor_DelecaoIndice;

        FETCH NEXT FROM cursor_DelecaoIndice
         INTO @ObjectId,
              @IndexId,
              @IndexName,
              @Script;

        WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @StartTime = GETDATE();

            EXEC sys.sp_executesql @Script;

			IF(@MostrarIndice =1)
			BEGIN
			PRINT CONCAT(
                      'Comando Executado:',
                      @Script,
                      SPACE(2),
                      'Tempo Decorrido:',
                      DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                      ' MS');		
			END
            

            FETCH NEXT FROM cursor_DelecaoIndice
             INTO @ObjectId,
                  @IndexId,
                  @IndexName,
                  @Script;
        END;

        CLOSE cursor_DelecaoIndice;
        DEALLOCATE cursor_DelecaoIndice;

    END;



    IF (@MostrarIndice = 1)
    BEGIN
        SELECT *
          FROM #NoUsageIndex AS NUI;

    END;
END;


GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO


                                



/* ==================================================================
	--Data: 26/10/2018 
	--Autor :Wesley Neves
	--Observação: 
	http://www.sql-server-performance.com/2017/performance-tuning-re-indexing-update-statistics/
	https://www.red-gate.com/simple-talk/sql/performance/managing-sql-server-statistics/
	https://sqlworkbooks.com/2017/06/how-much-longer-does-it-take-to-update-statistics-with-fullscan/
	https://dba.stackexchange.com/questions/145982/sp-updatestats-vs-update-statistics
	https://www.fabriciolima.net/blog/tag/update-statistics-with-fullscan/
	https://www.red-gate.com/simple-talk/blogs/are-the-statistics-being-updated/
	https://www.sqlservercentral.com/Forums/Topic1735011-3411-1.aspx
	https://www.sqlskills.com/blogs/erin/understanding-when-statistics-will-automatically-update/
 
	-- ==================================================================
	*/

CREATE  OR ALTER PROCEDURE HealthCheck.uspUpdateStats (
    @MostarStatisticas BIT = 1,
    @ExecutarAtualizacao BIT = 0,
    @TableRowsInUpdateStats INT = 1000,
    @NumberLinesToDetermineFullScan INT = 100000)
AS
BEGIN

    SET NOCOUNT ON;


    --DECLARE @MostarStatisticas              BIT = 1,
    --		@ExecutarAtualizacao            BIT = 0,
    --		@TableRowsInUpdateStats         INT = 1000,
    --		@NumberLinesToDetermineFullScan INT = 100000;

    -----------------
    --Begin script
    -------------------


    DECLARE @StartTime DATETIME;

    SELECT @StartTime = GETDATE();

    DECLARE @sql NVARCHAR(2000);


    IF (OBJECT_ID('TEMPDB..#Modifications') IS NOT NULL)
        DROP TABLE #Modifications;

    CREATE TABLE #Modifications (
        [object_id] INT,
        [SchemaName] sysname,
        [TableName] sysname,
        [RowsInTable] INT,
        [StatsName] NVARCHAR(128),
        [stats_id] INT,
        [last_updated] DATETIME2(7),
        [rows] BIGINT,
        [steps] INT,
        [modification_counter] BIGINT,
		UpdateThreshold BIGINT,
        Script NVARCHAR(400));



    ;WITH Size_Tables
       AS (SELECT T.object_id,
                  S.name  AS SchemaName,
                  T.name  AS TableName,
                  CAST(prt.rows AS INT) AS RowsInTable,
                  S2.name AS StatsName,
                  S2.stats_id,
                  S2.auto_created
             FROM sys.tables AS T
			 JOIN sys.partitions AS prt
               ON T.object_id = prt.object_id
             JOIN sys.schemas AS S
               ON T.schema_id = S.schema_id
             JOIN sys.stats AS S2
               ON T.object_id = S2.object_id
            WHERE prt.rows > @TableRowsInUpdateStats),
          Modifications
       AS (SELECT DISTINCT Size.object_id,
                  Size.SchemaName,
                  Size.TableName,
                  Size.RowsInTable,
                  Size.StatsName,
                  Size.stats_id,
                  Size.auto_created,
                  Sta.last_updated,
                  Sta.rows,
                  Sta.rows_sampled,
                  UpdateThreshold = CAST((Sta.rows * .10) AS INT),
                  Sta.steps,
                  Sta.modification_counter
             FROM Size_Tables Size
            CROSS APPLY sys.dm_db_stats_properties(Size.object_id, Size.stats_id) AS Sta
            WHERE Sta.modification_counter > 0)

    INSERT INTO #Modifications (object_id,
                                SchemaName,
                                TableName,
                                RowsInTable,
                                StatsName,
                                stats_id,
                                last_updated,
                                rows,
                                steps,
                                modification_counter,
								UpdateThreshold,
                                Script)
    SELECT MO.object_id,
           MO.SchemaName,
           MO.TableName,
           MO.RowsInTable,
           MO.StatsName,
           MO.stats_id,
           MO.last_updated,
           MO.rows,
           MO.steps,
           MO.modification_counter,
		   MO.UpdateThreshold,
           NULL
      FROM Modifications MO
      WHERE MO.modification_counter > MO.UpdateThreshold
       AND MO.SchemaName NOT IN ( 'Log', 'Expurgo', 'HangFire','Sistema' );







    IF (EXISTS (SELECT 1 FROM #Modifications AS T))
    BEGIN

        UPDATE M
           SET M.Script = CONCAT(
                              'UPDATE STATISTICS ',
                              QUOTENAME(M.SchemaName),
                              '.',
                              QUOTENAME(M.TableName),
                              '(',
                              QUOTENAME(M.StatsName),
                              ')',
                              SPACE(1),
                              (IIF(M.rows <= @NumberLinesToDetermineFullScan, 'WITH FULLSCAN', '')))
          FROM #Modifications AS M;



        /* declare variables */

        IF (@ExecutarAtualizacao = 1)
        BEGIN

            DECLARE @ObjectId   INT,
                    @StatsId    INT,
                    @SchemaName sysname,
                    @TableName  sysname,
                    @StatsName  VARCHAR(128),
                    @Script     NVARCHAR(800);

            DECLARE cursor_AtualizacaoStatisticas CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT M.object_id,
                   M.stats_id,
                   M.SchemaName,
                   M.TableName,
                   M.StatsName,
                   M.Script
              FROM #Modifications AS M;

            OPEN cursor_AtualizacaoStatisticas;

            FETCH NEXT FROM cursor_AtualizacaoStatisticas
             INTO @ObjectId,
                  @StatsId,
                  @SchemaName,
                  @TableName,
                  @StatsName,
                  @Script;
            WHILE @@FETCH_STATUS = 0
            BEGIN

                SET @StartTime = GETDATE();


                EXEC sys.sp_executesql @Script;

				IF(@MostarStatisticas = 1)
				BEGIN
				      PRINT CONCAT(
                          'Comando Executado:',
                          @Script,
                          SPACE(2),
                          'Tempo Decorrido:',
                          DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                          ' MS');
 
				END
             

                FETCH NEXT FROM cursor_AtualizacaoStatisticas
                 INTO @ObjectId,
                      @StatsId,
                      @SchemaName,
                      @TableName,
                      @StatsName,
                      @Script;
            END;

            CLOSE cursor_AtualizacaoStatisticas;
            DEALLOCATE cursor_AtualizacaoStatisticas;

        END;

    END;

    IF (@MostarStatisticas = 1)
    BEGIN
        SELECT S.object_id,
               S.SchemaName,
               S.TableName,
               S.RowsInTable,
               S.StatsName,
               S.stats_id,
               S.last_updated,
               S.rows,
               S.steps,
               S.modification_counter,
               S.Script
          FROM #Modifications AS S;
    END;

END;


GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/* ==================================================================
--Data: 29/10/2018 
--Autor :Wesley Neves
--Observação: 
https://sqlperformance.com/2015/04/sql-indexes/mitigating-index-fragmentation
https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html
https://www.red-gate.com/simple-talk/sql/database-administration/defragmenting-indexes-in-sql-server-2005-and-2008/
https://www.sqlskills.com/blogs/paul/indexes-from-every-angle-how-can-you-tell-if-an-index-is-being-used/
https://blog.sqlserveronline.com/2017/11/18/sql-server-activity-monitor-and-page-splits-per-second-tempdb/
https://techcommunity.microsoft.com/t5/Premier-Field-Engineering/Three-Usage-Scenarios-for-sys-dm-db-index-operational-stats/ba-p/370298
 
-- ==================================================================
*/

--PK_CadastroEmails	70	90	2561
--IX_Emails_IdPessoa	100	90	2259

--exec HealthCheck.uspIndexDesfrag @Efetivar =1

CREATE OR ALTER PROCEDURE HealthCheck.uspIndexDesfrag (
                                             @MostrarIndices BIT      = 1,
                                             @MinFrag        SMALLINT = 10,
                                             @MinPageCount   SMALLINT = 1000,
                                             @Efetivar       BIT      = 0
                                             )
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SET NOCOUNT ON;

    DECLARE @SqlServerVersion VARCHAR(100) = (
                                             SELECT @@VERSION
                                             );
    DECLARE @TipoVersao VARCHAR(100) = CASE
                                           WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN
                                               'Azure'
                                           WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN
                                               'Enterprise'
                                           ELSE
                                               'Standard'
                                       END;

    --DECLARE @MostrarIndices BIT      = 1,
    --        @MinFrag        SMALLINT = 10,
    --        @MinPageCount   SMALLINT = 1000,
    --        @Efetivar       BIT      = 0;

    DECLARE @SchemasExcecao TABLE (SchemaName VARCHAR(128));

    DECLARE @TableExcecao TABLE (TableName VARCHAR(128));

    INSERT INTO @SchemasExcecao (
                                SchemaName
                                )
    VALUES ('Expurgo');

    INSERT INTO @TableExcecao (
                              TableName
                              )
    VALUES ('LogsDetalhes');

    DECLARE @MinFillFactorLevel3 TINYINT = 15;
    DECLARE @MinFillFactorLevel4 TINYINT = 10;
    DECLARE @MinFillFactorLevel5 TINYINT = 5;
    DECLARE @MinFillFactorLevel6 TINYINT = 100; -- 100 %

    IF (OBJECT_ID('TEMPDB..#Fragmentacao') IS NOT NULL)
        DROP TABLE #Fragmentacao;

    IF (OBJECT_ID('TEMPDB..#IndicesDesfragmentar') IS NOT NULL)
        DROP TABLE #IndicesDesfragmentar;

    CREATE TABLE #Fragmentacao (
                               ObjectId                     INT,
                               IndexId                      INT,
                               [index_type_desc]            NVARCHAR(60),
                               AvgFragmentationInPercent    FLOAT(8),
                               [fragment_count]             BIGINT,
                               [avg_fragment_size_in_pages] FLOAT(8),
                               PageCount                    BIGINT
                                   PRIMARY KEY (ObjectId, IndexId)
                               );

    CREATE TABLE #IndicesDesfragmentar (
                                       ObjectId                        INT,
                                       IndexId                         SMALLINT,
                                       [SchemaName]                    VARCHAR(128),
                                       [TableName]                     VARCHAR(128),
                                       IndexName                       VARCHAR(128),
                                       FillFact                        TINYINT,
                                       NewFillFact                     TINYINT     NULL,
                                       PageSpltForIndex                INT,
                                       PageAllocationCausedByPageSplit INT,
                                       AvgFragmentationInPercent       FLOAT,
                                       PageCount                       INT,
                                       [Alteracoes]                    BIGINT
                                           PRIMARY KEY (ObjectId, IndexId)
                                       );

    INSERT INTO #Fragmentacao
    SELECT A.object_id,
           A.index_id,
           A.index_type_desc,
           A.avg_fragmentation_in_percent,
           A.fragment_count,
           A.avg_fragment_size_in_pages,
           A.page_count
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS A
    WHERE A.alloc_unit_type_desc IN ( N'IN_ROW_DATA', N'ROW_OVERFLOW_DATA' )
          AND A.page_count > @MinPageCount
          AND A.avg_fragmentation_in_percent >= @MinFrag;

    IF (EXISTS (
               SELECT 1
               FROM #Fragmentacao AS F
               )
       )
    BEGIN
        INSERT INTO #IndicesDesfragmentar (
                                          ObjectId,
                                          IndexId,
                                          SchemaName,
                                          TableName,
                                          IndexName,
                                          FillFact,
                                          PageSpltForIndex,
                                          PageAllocationCausedByPageSplit,
                                          AvgFragmentationInPercent,
                                          PageCount,
                                          Alteracoes
                                          )
        SELECT CAST(IOS.object_id AS INT),
               CAST(IOS.index_id AS SMALLINT),
               CAST(S.name AS VARCHAR(128)) AS SchemaName,
               CAST(T.name AS VARCHAR(128)) TableName,
               CAST(I.name AS VARCHAR(128)) INDEX_NAME,
               CAST(I.fill_factor AS TINYINT),
               CAST(IOS.leaf_allocation_count AS INT) AS PAGE_SPLIT_FOR_INDEX,
               CAST(IOS.nonleaf_allocation_count AS INT) PageAllocationCausedByPageSplit,
               F.AvgFragmentationInPercent,
               CAST(F.PageCount AS INT),
               Alteracoes = (IOS.leaf_insert_count + IOS.leaf_delete_count + IOS.leaf_update_count)
        FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) IOS
             JOIN
             #Fragmentacao AS F ON IOS.object_id = F.ObjectId
                                   AND IOS.index_id = F.IndexId
             JOIN
             sys.indexes I ON IOS.index_id = I.index_id
                              AND IOS.object_id = I.object_id
             JOIN
             sys.tables AS T ON I.object_id = T.object_id
             JOIN
             sys.schemas AS S ON T.schema_id = S.schema_id
        WHERE I.type = 2 -- NO HEAP'
              AND S.name NOT IN (
                                SELECT SE.SchemaName COLLATE DATABASE_DEFAULT
                                FROM @SchemasExcecao AS SE
                                )
              AND T.name NOT IN (
                                SELECT TE.TableName COLLATE DATABASE_DEFAULT
                                FROM @TableExcecao AS TE
                                )
        OPTION (MAXDOP 0);


		
			


        UPDATE IX
        SET IX.FillFact = CASE
                              WHEN IX.FillFact = 0 THEN
                                  100
                              WHEN IX.FillFact = 10 THEN
                                  90
                              WHEN IX.FillFact = 20 THEN
                                  80
                              WHEN IX.FillFact = 30 THEN
                                  70
                              WHEN IX.FillFact = 40 THEN
                                  60
                              ELSE
                                  100
                          END
        FROM #IndicesDesfragmentar IX;

	

          UPDATE FRAG
        SET FRAG.NewFillFact = CASE
                                   WHEN (FRAG.PageSpltForIndex) >= 500 THEN
                                      FRAG.FillFact -  @MinFillFactorLevel3
                                   ELSE
                                       FRAG.NewFillFact
                               END
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.NewFillFact IS NULL;


        UPDATE FRAG
        SET FRAG.NewFillFact = CASE
                                   WHEN (FRAG.PageSpltForIndex) >= 100 THEN
                                      FRAG.FillFact -   @MinFillFactorLevel4
                                   ELSE
                                       FRAG.NewFillFact
                               END
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.NewFillFact IS NULL;

        UPDATE FRAG
        SET FRAG.NewFillFact = CASE
                                   WHEN (FRAG.PageSpltForIndex) >= 50 THEN
                                      FRAG.FillFact -  @MinFillFactorLevel5
                               END
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.NewFillFact IS NULL;



        UPDATE FRAG
        SET FRAG.NewFillFact = @MinFillFactorLevel6
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.NewFillFact IS NULL;


        /* declare variables */
        DECLARE @SchemaName VARCHAR(128),
                @TableName VARCHAR(128),
                @IndexName VARCHAR(128),
                @fill_factor TINYINT,
                @Newfill_factor TINYINT,
                @avg_fragmentation_in_percent DECIMAL(8, 2);
        DECLARE @StartTime DATETIME = GETDATE();
        DECLARE @Mensagem VARCHAR(1000);

        IF (
           EXISTS (
                  SELECT 1
                  FROM #IndicesDesfragmentar AS FI
                  )
           AND @Efetivar = 1
           )
        BEGIN
            DECLARE cursor_Fragmentacao CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT FI.SchemaName,
                       FI.TableName,
                       FI.IndexName,
                       FI.FillFact,
                       FI.NewFillFact,
                       FI.AvgFragmentationInPercent
                FROM #IndicesDesfragmentar AS FI;

            OPEN cursor_Fragmentacao;

            FETCH NEXT FROM cursor_Fragmentacao
            INTO @SchemaName,
                 @TableName,
                 @IndexName,
                 @fill_factor,
                 @Newfill_factor,
                 @avg_fragmentation_in_percent;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @Script NVARCHAR(1000);

                SET @Script
                    = CONCAT(
                                'ALTER INDEX ',
                                QUOTENAME(@IndexName),
                                SPACE(1),
                                'ON',
                                SPACE(1),
                                QUOTENAME(@SchemaName),
                                '.',
                                QUOTENAME(@TableName),
                                IIF(@avg_fragmentation_in_percent <= 35, ' REORGANIZE ', ' REBUILD')
                            );

                IF (@avg_fragmentation_in_percent > 35)
                BEGIN
                    SET @Script
                        = CONCAT(
                                    @Script,
                                    ' WITH (' + IIF(@TipoVersao IN ( 'Azure', 'Enterprise' ), 'ONLINE=ON ,', '')
                                    + 'MAXDOP = 8, SORT_IN_TEMPDB= ON , FILLFACTOR =',
                                    @Newfill_factor,
                                    ')'
                                );
                END;

                SET @StartTime = GETDATE();

                EXEC sys.sp_executesql @Script;

                IF (@MostrarIndices = 1)
                BEGIN
                    SET @Mensagem
                        = CONCAT(
                                    'Comando :',
                                    @Script,
                                    ' Executado em :',
                                    DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                                    ' MS'
                                );

                    RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                END;

                FETCH NEXT FROM cursor_Fragmentacao
                INTO @SchemaName,
                     @TableName,
                     @IndexName,
                     @fill_factor,
                     @Newfill_factor,
                     @avg_fragmentation_in_percent;
            END;

            CLOSE cursor_Fragmentacao;
            DEALLOCATE cursor_Fragmentacao;
        END;
    END;

    IF (@MostrarIndices = 1)
    BEGIN
        SELECT *
        FROM #IndicesDesfragmentar AS FI;
    END;
END;
GO




GO

--EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = 0, -- bit
--                                         @MostrarIndicesDuplicados = 1, -- bit
--                                         @MostrarIndicesMarcadosParaDeletar = 1, -- bit
--                                         @QuantidadeDiasAnalizados = 1, -- tinyint
--                                         @TaxaDeSeguranca = 10 -- tinyint


CREATE OR ALTER  PROCEDURE HealthCheck.uspDeleteDuplicateIndex (
    @Efetivar BIT = 0,
    @MostrarIndicesDuplicados BIT = 1,
    @MostrarIndicesMarcadosParaDeletar BIT = 1,
    @TableName VARCHAR(128) = NULL,
    @QuantidadeDiasAnalizados TINYINT = 7,
    @TaxaDeSeguranca TINYINT = 10)
AS
BEGIN

    SET NOCOUNT ON;
    SET TRAN ISOLATION LEVEL READ UNCOMMITTED;


	--DECLARE @Efetivar                          BIT          = 0,
 --           @MostrarIndicesDuplicados          BIT          = 1,
 --           @TableName                         VARCHAR(128) = NULL, --  '[Tramitacao].[Tramitacoes]',
 --           @MostrarIndicesMarcadosParaDeletar BIT          = 1,
 --           @QuantidadeDiasAnalizados          TINYINT      = 3,
 --           @TaxaDeSeguranca                   TINYINT      = 10;

    
	
	
	--Ids
	DECLARE @table AS TableIntegerIds;

    IF (OBJECT_ID('TEMPDB..#Indices') IS NOT NULL)
        DROP TABLE #Indices;

    IF (OBJECT_ID('TEMPDB..#MarcadosParaDeletar') IS NOT NULL)
        DROP TABLE #MarcadosParaDeletar;

    IF (OBJECT_ID('TEMPDB..#Duplicates') IS NOT NULL)
        DROP TABLE #Duplicates;

    IF (OBJECT_ID('TEMPDB..#IndicesResumo') IS NOT NULL)
        DROP TABLE #IndicesResumo;

    IF (OBJECT_ID('TEMPDB..#Medias') IS NOT NULL)
        DROP TABLE #Medias;



    CREATE TABLE #Medias (
        [SnapShotDate] DATETIME2(3),
        [ObjectId] INT,
        [RowsInTable] INT,
        [ObjectName] VARCHAR(260),
        [IndexId] SMALLINT,
        [IndexName] VARCHAR(128),
        [Reads] BIGINT,
        [Write] INT,
        [PercAproveitamento] DECIMAL(18, 2),
        [PercCustoMedio] DECIMAL(18, 2),
        [PercScan] DECIMAL(18, 2),
        [AvgPercScan] DECIMAL(10, 2),
        [AvgIsBad] INT,
        [AvgReads] DECIMAL(10, 2),
        [AvgWrites] DECIMAL(10, 2),
        [AvgAproveitamento] DECIMAL(10, 2),
        [AvgCusto] DECIMAL(10, 2),
        [IsBadIndex] BIT,
        [MaxAnaliseForTable] SMALLINT,
        [MaxAnaliseForIndex] INT,
        [QtdAnalize] INT,
        [Analise] SMALLINT,
        [IsUniqueConstraint] BIT,
        [IsPrimaryKey] BIT,
        [IsUnique] BIT,
        PRIMARY KEY (ObjectId, IndexId, Analise));



    CREATE TABLE #Duplicates (
        ObjectId INT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [PrimeiraChave] VARCHAR(200),
        [Chave] VARCHAR(998),
        [TamanhoChave] INT,
        [TamanhoCInclude] INT,
        [MaximaChave] INT,
        [MaximaCInclude] INT,
        [MesmaPrimeiraChave] VARCHAR(1),
        [ColunasIncluidas] VARCHAR(998),
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        DescTipo TINYINT,
        IndexId SMALLINT,
        [Deletar] VARCHAR(1));

    CREATE TABLE #MarcadosParaDeletar (
        ObjectId INT,
        [ObjectName] VARCHAR(128),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [PrimeiraChave] VARCHAR(200),
        [MesmaPrimeiraChave] VARCHAR(1),
        [Chave] VARCHAR(998),
        [Deletar] VARCHAR(1),
        [ColunasIncluidas] VARCHAR(998),
        [TamanhoChave] INT,
        [MaximaChave] INT,
        [TamanhoCInclude] INT,
        [MaximaCInclude] INT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT,
        DescTipo VARCHAR(40),
        IndexId SMALLINT);

    CREATE TABLE #IndicesResumo (
	    RowId INT  NOT NULL PRIMARY KEY IDENTITY(1,1),
        ObjectId INT,
        [ObjectName] VARCHAR(300),
        [IndexName] VARCHAR(128),
        PercAproveitamento DECIMAL(18, 2),
        [Chave] VARCHAR(200),
        [PrimeiraChave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        [type_index] TINYINT,
        IndexId SMALLINT,
        IsUnique BIT,
        IsPrimaryKey BIT,
        IsUniqueConstraint BIT);

    CREATE TABLE #Indices (
        [ObjectId] INT,
        [ObjectName] VARCHAR(300),
        [RowsInTable] INT,
        [IndexName] VARCHAR(128),
        [Usado] BIT,
        [UserSeeks] INT,
        [UserScans] INT,
        [UserLookups] INT,
        [UserUpdates] INT,
        [Reads] BIGINT,
        [Write] INT,
		CountPageSplitPage INT,
        [PercAproveitamento] DECIMAL(18, 2),
        [PercCustoMedio] DECIMAL(18, 2),
        [IsBadIndex] INT,
        [IndexId] SMALLINT,
        [IndexsizeKB] BIGINT,
        [IndexsizeMB] DECIMAL(18, 2),
        [IndexSizePorTipoMB] DECIMAL(18, 2),
        [Chave] VARCHAR(899),
        [ColunasIncluidas] VARCHAR(899),
        [IsUnique] BIT,
        [IgnoreDupKey] BIT,
        [IsprimaryKey] BIT,
        [IsUniqueConstraint] BIT,
        [FillFact] TINYINT,
        [AllowRowLocks] BIT,
        [AllowPageLocks] BIT,
        [HasFilter] BIT,
        [TypeIndex] TINYINT);

    INSERT INTO #Indices
    /*Faz uma analise completa de todos os indices*/
    EXEC HealthCheck.uspAllIndex @typeIndex = NULL, -- varchar(30)
                                 @SomenteUsado = NULL, -- bit
                                 @TableIsEmpty = 0, -- bit
                                 @ObjectName = NULL, -- varchar(128)
                                 @BadIndex = NULL, -- bit
                                 @percentualAproveitamento = NULL; -- smallint






    INSERT INTO #IndicesResumo
    SELECT X.ObjectId,
           X.ObjectName,
           X.IndexName,
           X.PercAproveitamento,
           X.Chave,
           [PrimeiraChave] = IIF(CHARINDEX(',', X.Chave, 0) > 0,
                                 (SUBSTRING(X.Chave, 0, CHARINDEX(',', X.Chave, 0))),
                                 X.Chave),
           X.ColunasIncluidas,
           X.TypeIndex,
           X.IndexId,
           X.IsUnique,
           X.IsprimaryKey,
           X.IsUniqueConstraint
      FROM #Indices X
     WHERE X.ObjectName NOT LIKE '%HangFire%';

	
    WITH Duplicates
      AS (SELECT I.ObjectId,
                 I.ObjectName,
                 I.IndexName,
                 I.PercAproveitamento,
                 I.PrimeiraChave,
                 I.Chave,
                 TamanhoChave = LEN(I.Chave),
                 TamanhoCInclude = ISNULL(LEN(I.ColunasIncluidas), 0),
                 MaximaChave = MAX(LEN(I.Chave)) OVER (PARTITION BY I.ObjectId, I.PrimeiraChave),
                 MaximaCInclude = ISNULL(MAX(LEN(I.ColunasIncluidas)) OVER (PARTITION BY I.ObjectId), 0),
                 MesmaPrimeiraChave = CASE
                                           WHEN EXISTS (   SELECT 1
                                                             FROM #IndicesResumo AS IR
                                                            WHERE IR.ObjectId      = I.ObjectId
                                                              AND IR.PrimeiraChave = I.PrimeiraChave
															  AND I.RowId <> IR.RowId) THEN 'S'
                                           ELSE 'N' END,
                 I.ColunasIncluidas,
                 I.IsUnique,
                 I.IsPrimaryKey,
                 I.IsUniqueConstraint,
                 I.type_index,
                 I.IndexId,
                 [Deletar] = NULL
            FROM #IndicesResumo AS I
           WHERE EXISTS (   SELECT 1
                              FROM #IndicesResumo DU
                             WHERE DU.ObjectId      = I.ObjectId
                               AND DU.PrimeiraChave = I.PrimeiraChave
                               AND DU.IndexId       <> I.IndexId))
    INSERT INTO #Duplicates
    SELECT *
      FROM Duplicates DU
     WHERE DU.IndexId > 1; -- Is not PK

	 
	 

    IF (EXISTS (SELECT 1 FROM #Duplicates AS D))
    BEGIN

        INSERT INTO @table (Id)
        SELECT DISTINCT D.ObjectId
          FROM #Duplicates AS D;

        INSERT INTO #Medias
        EXEC HealthCheck.uspIndexMedia @SnapShotDayMedia = @QuantidadeDiasAnalizados, -- smallint
                                       @TableObjectIds = @table, -- TableIntegerIds
                                       @IsUniqueConstraint = 0, -- bit
                                       @IsUnique = 0, -- bit
                                       @IsPrimaryKey = 0; -- bit



        IF (EXISTS (SELECT 1 FROM #Medias AS M))
        BEGIN
		
		


            /*Marca para deletar os indices duplicados que aparecerem apenas uma vez*/
            UPDATE D
               SET D.Deletar = 'S'
              FROM #Duplicates AS D
             WHERE D.ObjectId IN (   SELECT d2.ObjectId
                                       FROM #Duplicates AS d2
                                      GROUP BY d2.ObjectId
                                     HAVING COUNT(*) = 1 )
               AND D.PercAproveitamento < 10;


            WITH BadIndexIn7DiasNonUsage
              AS (SELECT D.ObjectId,
                         RowId = ROW_NUMBER() OVER (PARTITION BY D.ObjectId,
                                                                 D.PrimeiraChave
                                                        ORDER BY D.PercAproveitamento DESC,
                                                                 LEN(D.Chave) DESC),
                         D.ObjectName,
                         D.PrimeiraChave,
                         D.ColunasIncluidas,
                         D.Chave,
                         D.IndexId,
                         D.Deletar,
                         D.PercAproveitamento,
                         MenorAproveitamento = MIN(D.PercAproveitamento) OVER (PARTITION BY D.ObjectId, D.PrimeiraChave)
                    FROM #Duplicates AS D
                    LEFT JOIN #Medias AS M --(LEFT JOIN  não houve uso no 7 dias e o indice está duplicado)
                      ON D.ObjectId = M.ObjectId
                     AND D.IndexId  = M.IndexId
                   WHERE D.Deletar IS NULL)
            UPDATE D
               SET D.Deletar = 'S'
              FROM #Duplicates AS D
              JOIN BadIndexIn7DiasNonUsage Bad
                ON D.ObjectId = Bad.ObjectId
               AND D.IndexId  = Bad.IndexId
             WHERE D.PercAproveitamento = Bad.MenorAproveitamento
               AND Bad.RowId            > 1
               AND D.PercAproveitamento <= 10;
			   

            ;WITH BadIndexIn7DiasUsage
               AS (SELECT D.ObjectId,
                          RowId = ROW_NUMBER() OVER (PARTITION BY D.ObjectId,
                                                                  D.PrimeiraChave
                                                         ORDER BY D.PercAproveitamento DESC,
                                                                  LEN(D.Chave) DESC),
                          D.ObjectName,
                          D.PrimeiraChave,
                          D.ColunasIncluidas,
                          D.Chave,
                          D.IndexId,
                          D.Deletar,
                          D.PercAproveitamento,
                          MenorAproveitamento = MIN(D.PercAproveitamento) OVER (PARTITION BY D.ObjectId, D.PrimeiraChave)
                     FROM #Duplicates AS D
                     JOIN #Medias AS M --(Inner)
                       ON D.ObjectId = M.ObjectId
                      AND D.IndexId  = M.IndexId)
            UPDATE D
               SET D.Deletar = 'S'
              FROM #Duplicates AS D
              JOIN BadIndexIn7DiasUsage Bad
                ON D.ObjectId = Bad.ObjectId
               AND D.IndexId  = Bad.IndexId
             WHERE D.PercAproveitamento = Bad.MenorAproveitamento
               AND Bad.RowId            > 1
               AND D.PercAproveitamento <= 10;

			   
            INSERT INTO #MarcadosParaDeletar
            SELECT F1.ObjectId,
                   F1.ObjectName,
                   F1.IndexName,
                   F1.PercAproveitamento,
                   F1.PrimeiraChave,
                   F1.MesmaPrimeiraChave,
                   F1.Chave,
                   F1.Deletar,
                   F1.ColunasIncluidas,
                   F1.TamanhoChave,
                   F1.MaximaChave,
                   F1.TamanhoCInclude,
                   F1.MaximaCInclude,
                   F1.IsUnique,
                   F1.IsPrimaryKey,
                   F1.IsUniqueConstraint,
                   F1.DescTipo,
                   F1.IndexId
              FROM #Duplicates F1
             WHERE F1.Deletar = 'S'
             ORDER BY F1.ObjectId,
                      F1.PrimeiraChave,
                      F1.Chave;

					  
            IF (EXISTS (SELECT 1 FROM #MarcadosParaDeletar AS MPD)  AND @Efetivar = 1
			)
            BEGIN

                /* declare variables */
                DECLARE @ObjectName VARCHAR(128),
                        @IndexName  VARCHAR(128);
                DECLARE @Script NVARCHAR(1000);

                DECLARE cursor_DeletaIndiceDuplicado CURSOR FAST_FORWARD READ_ONLY FOR
                SELECT MPD.ObjectName,
                       MPD.IndexName
                  FROM #MarcadosParaDeletar AS MPD;

                OPEN cursor_DeletaIndiceDuplicado;

                FETCH NEXT FROM cursor_DeletaIndiceDuplicado
                 INTO @ObjectName,
                      @IndexName;

                WHILE @@FETCH_STATUS = 0
                BEGIN

                    SET @Script = CONCAT('DROP INDEX', SPACE(1), @IndexName, SPACE(1), ' ON ', @ObjectName);

                    EXEC sys.sp_executesql @Script;

                    FETCH NEXT FROM cursor_DeletaIndiceDuplicado
                     INTO @ObjectName,
                          @IndexName;
                END;

                CLOSE cursor_DeletaIndiceDuplicado;
                DEALLOCATE cursor_DeletaIndiceDuplicado;
            END;

        END;
    END;


    IF (@MostrarIndicesDuplicados = 1)
    BEGIN

        SELECT 'Duplicado=>' AS Descricao,
               D.ObjectId,
               D.ObjectName,
               D.IndexName,
               D.PercAproveitamento,
               D.PrimeiraChave,
               D.Chave,
               D.TamanhoChave,
               D.TamanhoCInclude,
               D.MaximaChave,
               D.MaximaCInclude,
               D.MesmaPrimeiraChave,
               D.ColunasIncluidas,
               D.IsUnique,
               D.IsPrimaryKey,
               D.IsUniqueConstraint,
               D.DescTipo,
               D.IndexId,
               D.Deletar
          FROM #Duplicates AS D
         ORDER BY D.ObjectId,
                  D.PrimeiraChave;
    END;

    IF (@MostrarIndicesMarcadosParaDeletar = 1)
    BEGIN

        SELECT 'A Deletar=>' AS Descricao,
               MPD.ObjectName,
               MPD.IndexName,
               MPD.PercAproveitamento,
               MPD.PrimeiraChave,
               MPD.MesmaPrimeiraChave,
               MPD.Chave,
               MPD.Deletar,
               MPD.ColunasIncluidas,
               MPD.TamanhoChave,
               MPD.MaximaChave,
               MPD.TamanhoCInclude,
               MPD.MaximaCInclude,
               MPD.IsUnique,
               MPD.IsPrimaryKey,
               MPD.IsUniqueConstraint,
               MPD.DescTipo,
               MPD.IndexId
          FROM #MarcadosParaDeletar AS MPD
         ORDER BY MPD.ObjectId,
                  MPD.PrimeiraChave;

    END;

END;

GO


CREATE OR ALTER PROCEDURE HealthCheck.uspSnapShotClear (@diasExpurgo SMALLINT = 30)
AS
BEGIN

    DECLARE @maxAnalise INT = 0;

    ;WITH Dados
    AS (SELECT DENSE_RANK() OVER (PARTITION BY SSIH.ObjectId, SSIH.IndexId ORDER BY SSIH.SnapShotDate) AS Analise
        FROM HealthCheck.SnapShotIndexHistory AS SSIH
       )
    SELECT @maxAnalise = ISNULL(MAX(Dados.Analise), 0)
    FROM Dados;

    IF (@maxAnalise >= @diasExpurgo)
    BEGIN

        DELETE HIST
        FROM HealthCheck.SnapShotIndexHistory HIST;

        DELETE IX
        FROM HealthCheck.SnapShotIndex IX;
    END;

END;

GO



/* ==================================================================
--Data: 12/12/2018 
--Autor :Wesley Neves
--Observação: https://blog.pythian.com/sql-server-statistics-maintenance-and-best-practices/
 
-- ==================================================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspDeleteOverlappingStats
(
    @MostarStatisticas BIT = 1,
    @Executar BIT = 0
)
AS
BEGIN


    --DECLARE @MostarStatisticas BIT = 1;
    --DECLARE @Executar BIT = 1;



    IF (OBJECT_ID('TEMPDB..#Duplicate') IS NOT NULL)
        DROP TABLE #Duplicate;



    CREATE TABLE #Duplicate
    (
        [Table] NVARCHAR(128),
        [Column] NVARCHAR(128),
        [Overlapped] NVARCHAR(128),
        [Overlapping] NVARCHAR(128),
        [Script] NVARCHAR(408)
    );

    WITH autostats (object_id, stats_id, name, column_id)
    AS (SELECT stats.object_id,
               stats.stats_id,
               stats.name,
               stats_columns.column_id
        FROM sys.stats
            INNER JOIN sys.stats_columns
                ON stats.object_id = stats_columns.object_id
                   AND stats.stats_id = stats_columns.stats_id
        WHERE stats.auto_created = 1
              AND stats_columns.stats_column_id = 1
       )
    INSERT INTO #Duplicate
    (
        [Table],
        [Column],
        Overlapped,
        Overlapping,
        Script
    )
    SELECT OBJECT_NAME(stats.object_id) AS [Table],
           columns.name AS [Column],
           stats.name AS [Overlapped],
           autostats.name AS [Overlapping],
           'DROP STATISTICS [' + OBJECT_SCHEMA_NAME(stats.object_id) + '].[' + OBJECT_NAME(stats.object_id) + '].['
           + autostats.name + ']'
    FROM sys.stats
        INNER JOIN sys.stats_columns
            ON stats.object_id = stats_columns.object_id
               AND stats.stats_id = stats_columns.stats_id
        INNER JOIN autostats
            ON stats_columns.object_id = autostats.object_id
               AND stats_columns.column_id = autostats.column_id
        INNER JOIN sys.columns
            ON stats.object_id = COLUMNS.object_id
               AND stats_columns.column_id = COLUMNS.column_id
    WHERE stats.auto_created = 0
          AND stats_columns.stats_column_id = 1
          AND stats_columns.stats_id != autostats.stats_id
          AND OBJECTPROPERTY(stats.object_id, 'IsMsShipped') = 0;


		  
    DECLARE @StartTime DATETIME;

    IF (EXISTS (SELECT 1 FROM #Duplicate AS T))
    BEGIN

        /* declare variables */

        IF (@Executar = 1)
        BEGIN

            DECLARE @TableName sysname,
                    @Script NVARCHAR(800);

            DECLARE cursor_AtualizacaoStatisticas CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT DISTINCT M.[Table],
                   M.Script
            FROM #Duplicate AS M;

            OPEN cursor_AtualizacaoStatisticas;

            FETCH NEXT FROM cursor_AtualizacaoStatisticas
            INTO @TableName,
                 @Script;
            WHILE @@FETCH_STATUS = 0
            BEGIN

                SET @StartTime = GETDATE();


                EXEC sys.sp_executesql @Script;

                PRINT CONCAT(
                                'Comando Executado:',
                                @Script,
                                SPACE(2),
                                'Tempo Decorrido:',
                                DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                                ' MS'
                            );


                FETCH NEXT FROM cursor_AtualizacaoStatisticas
                INTO @TableName,
                     @Script;
            END;

            CLOSE cursor_AtualizacaoStatisticas;
            DEALLOCATE cursor_AtualizacaoStatisticas;

        END;

    END;

    IF (@MostarStatisticas = 1)
    BEGIN
        SELECT D.[Table],
               D.[Column],
               D.Overlapped,
               D.Overlapping,
               D.Script
        FROM #Duplicate AS D;
    END;
END;

GO






CREATE OR ALTER  PROCEDURE HealthCheck.uspAutoManegerStats (
                                                                     @MostrarStatistica BIT = 1,
                                                                     @Efetivar          BIT = 0,
																	 @NumberLinesToDetermineFullScan INT = 100000
                                                                     )
AS
BEGIN TRY
SET NOCOUNT ON 
SET TRAN ISOLATION LEVEL READ UNCOMMITTED

/* ==================================================================
--Data: 01/11/2018 
--Autor :Wesley Neves
--Observação:  Cria as Statisticas Colunares
-- ==================================================================
*/
    /*Region Logical Querys*/

    --DECLARE @MostrarStatistica BIT = 1;
    --DECLARE @Efetivar BIT = 1;


	IF ( OBJECT_ID('TEMPDB..#CreateStats') IS NOT NULL )
	    DROP TABLE #CreateStats;	
	
	
    CREATE TABLE #CreateStats (
                              ObjectId    INT,
                              SchemaName   VARCHAR(128),
                              TableName    VARCHAR(128),
                              Rows         BIGINT,
                              ColumnId    INT,
                              Collun       VARCHAR(128),
                              Type         VARCHAR(128),
                              UserTypeId INT,
                              MaxLength   SMALLINT,
                              precision    TINYINT,
                              IsNullable  BIT,
                              IsComputed  BIT,
                              Script       VARCHAR(825)
                              );


    WITH AllCollunsNotStatis
      AS (SELECT T.object_id,
                 SchemaName = S.name,
                 TableName = T.name,
                 SI.rowcnt AS Rows,
                 C.column_id,
                 Collun = C.name,
                 Type = T2.name,
                 C.user_type_id,
                 C.max_length,
                 C.precision,
                 C.is_nullable,
                 C.is_computed
          FROM sys.tables AS T
               JOIN
               sys.sysindexes AS SI ON SI.id = T.object_id
                                       AND SI.indid = 1
               JOIN
               sys.schemas AS S ON T.schema_id = S.schema_id
               JOIN
               sys.columns AS C ON T.object_id = C.object_id
               JOIN
               sys.types AS T2 ON T2.user_type_id = C.user_type_id
          WHERE NOT EXISTS (
                           SELECT S.object_id,
                                  S.name,
                                  SC.column_id
                           FROM sys.stats AS S
                                JOIN
                                sys.stats_columns AS SC ON S.object_id = SC.object_id
                                                           AND S.stats_id = SC.stats_id
                           WHERE S.object_id = T.object_id
                                 AND SC.column_id = C.column_id
                           )
                AND C.is_replicated = 0
                AND C.is_filestream = 0
                AND C.is_xml_document = 0
                AND T2.is_table_type = 0
                AND SI.rowcnt > 200
                AND C.column_id > 1
                AND T2.name NOT IN ( 'varbinary', 'nvarchar', 'XML' )
                AND NOT (
                        T2.name = 'varchar'
                        AND C.max_length = -1
                        )
                AND NOT (
                        T2.name = 'varchar'
                        AND C.max_length > 30
                        )
				AND S.name NOT IN('Log') 
                AND COLUMNPROPERTY(T.object_id, C.name, 'IsDeterministic') IS NULL
				AND T.object_id IN 
				(
				SELECT  object_id FROM sys.dm_db_index_usage_stats A
				)
         )
    INSERT INTO #CreateStats
    SELECT AX.object_id,
           AX.SchemaName,
           AX.TableName,
           AX.Rows,
           AX.column_id,
           AX.Collun,
           AX.Type,
           AX.user_type_id,
           AX.max_length,
           AX.precision,
           AX.is_nullable,
           AX.is_computed,
           Script = CONCAT(
                              'CREATE ',
                              SPACE(1),
                              'STATISTICS',
                              SPACE(1),
							  '',
                              'Stats_',
                              AX.SchemaName,
                              AX.TableName,
                              AX.Collun,
							  '',
                              SPACE(1),
                              'ON',
                              SPACE(1),
                              '',
                               AX.SchemaName,
                              '',
                              '.',
                              '',
                              AX.TableName,
                              '(',
                              QUOTENAME(AX.Collun),
                              ')', (IIF(AX.Rows <= @NumberLinesToDetermineFullScan,' WITH  FULLSCAN',''))
                              
                          )
    FROM AllCollunsNotStatis AX;

	


	
    IF (
       EXISTS (
              SELECT 1
              FROM #CreateStats
              )
       AND @Efetivar = 1
       )
    BEGIN

        /* declare variables */
        DECLARE @object_id INT;
        DECLARE @SchemaName VARCHAR(128);
        DECLARE @TableName VARCHAR(128);
        DECLARE @Collun VARCHAR(128);
        DECLARE @Script NVARCHAR(1000);


        DECLARE @StartTime DATETIME = GETDATE();

        DECLARE @Mensagem VARCHAR(1000);

        DECLARE cursor_CreatStats CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT CS.ObjectId,
                   CS.SchemaName,
                   CS.TableName,
                   CS.Collun,
                   CS.Script
            FROM #CreateStats AS CS;

        OPEN cursor_CreatStats;

        FETCH NEXT FROM cursor_CreatStats
        INTO @object_id,
             @SchemaName,
             @TableName,
             @Collun,
             @Script;

        WHILE @@FETCH_STATUS = 0
        BEGIN


            SET @StartTime = GETDATE();


            EXEC sys.sp_executesql @Script;


			IF(@MostrarStatistica =1)
			BEGIN
					
					SET @Mensagem
                = CONCAT('Comando :', @Script, ' Executado em :', DATEDIFF(MILLISECOND, @StartTime, GETDATE()), ' MS');

            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
			END
            


            FETCH NEXT FROM cursor_CreatStats
            INTO @object_id,
                 @SchemaName,
                 @TableName,
                 @Collun,
                 @Script;
        END;

        CLOSE cursor_CreatStats;
        DEALLOCATE cursor_CreatStats;

    END;

    IF (@MostrarStatistica = 1)
    BEGIN

        SELECT *
        FROM #CreateStats AS CS;
    END;

END TRY
BEGIN CATCH


    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
    PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);


    PRINT 'Error detected, all changes reversed.';
END CATCH;

GO


