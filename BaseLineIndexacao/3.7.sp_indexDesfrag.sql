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