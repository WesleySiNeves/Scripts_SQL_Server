/****** Object:  StoredProcedure [HealthCheck].[uspIndexDesfrag]    Script Date: 19/07/2024 11:54:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ==================================================================
-- Data: 29/10/2018 
-- Autor :Wesley Neves
-- Observação: 
https://sqlperformance.com/2015/04/sql-indexes/mitigating-index-fragmentation
https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html
https://www.red-gate.com/simple-talk/sql/database-administration/defragmenting-indexes-in-sql-server-2005-and-2008/
https://www.sqlskills.com/blogs/paul/indexes-from-every-angle-how-can-you-tell-if-an-index-is-being-used/
https://blog.sqlserveronline.com/2017/11/18/sql-server-activity-monitor-and-page-splits-per-second-tempdb/
https://techcommunity.microsoft.com/t5/Premier-Field-Engineering/Three-Usage-Scenarios-for-sys-dm-db-index-operational-stats/ba-p/370298
-- ==================================================================
*/

-- Execução: 
-- exec HealthCheck.uspIndexDesfrag  1,10,1000,0
-- exec HealthCheck.uspIndexDesfrag @Efetivar =0

CREATE OR ALTER PROCEDURE [HealthCheck].[uspIndexDesfrag]
(
    @MostrarIndices BIT = 1,
    @MinFrag SMALLINT = 10,
    @MinPageCount SMALLINT = 1000,
    @Efetivar BIT = 0
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

	--declare
	--@MostrarIndices BIT = 1,
 --   @MinFrag SMALLINT = 10,
 --   @MinPageCount SMALLINT = 1000,
 --   @Efetivar BIT = 0;

    DECLARE @SqlServerVersion VARCHAR(100) = (SELECT @@VERSION);
    DECLARE @TipoVersao VARCHAR(100) = CASE
                                           WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN 'Azure'
                                           WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN 'Enterprise'
                                           ELSE 'Standard'
                                       END;

    DECLARE @SchemasExcecao TABLE (SchemaName VARCHAR(128));
    DECLARE @TableExcecao TABLE (TableName VARCHAR(128));

    INSERT INTO @SchemasExcecao (SchemaName) VALUES ('Expurgo');
    INSERT INTO @TableExcecao (TableName) VALUES ('LogsDetalhes');

    DECLARE @MinFillFactorLevel3 TINYINT = 15;
    DECLARE @MinFillFactorLevel4 TINYINT = 10;
    DECLARE @MinFillFactorLevel5 TINYINT = 5;
    DECLARE @MinFillFactorLevel6 TINYINT = 100; -- 100%

    DROP TABLE IF EXISTS #Fragmentacao;
    DROP TABLE IF EXISTS #IndicesDesfragmentar;

    CREATE TABLE #Fragmentacao
    (
        RowId INT NOT NULL IDENTITY(1, 1),
        ObjectId INT,
        IndexId INT,
        [index_type_desc] NVARCHAR(60),
        AvgFragmentationInPercent FLOAT(8),
        [fragment_count] BIGINT,
        [avg_fragment_size_in_pages] FLOAT(8),
        PageCount BIGINT
		
    );
	

    CREATE TABLE #IndicesDesfragmentar
    (
        RowId SMALLINT NOT NULL IDENTITY(1, 1),
        [SchemaName] VARCHAR(128),
        [TableName] VARCHAR(128),
        IndexName VARCHAR(128),
        FillFact TINYINT,
        NewFillFact TINYINT NULL,
        PageSpltForIndex INT,
        AvgFragmentationInPercent FLOAT,
        PageCount INT,
        Script VARCHAR(800),
        PRIMARY KEY (RowId)
    );

    -- Inserindo dados de fragmentação
    INSERT INTO #Fragmentacao
    
	SELECT 
		   A.object_id,
           A.index_id,
           A.index_type_desc,
           A.avg_fragmentation_in_percent,
           A.fragment_count,
           A.avg_fragment_size_in_pages,
           A.page_count
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS A
	join sys.indexes ix on ix.object_id = A.object_id and ix.index_id = A.index_id
    WHERE A.alloc_unit_type_desc IN (N'IN_ROW_DATA', N'ROW_OVERFLOW_DATA')
          AND ix.type in (1,2)
          AND A.page_count > @MinPageCount
          AND A.avg_fragmentation_in_percent >= @MinFrag;

		
    IF (EXISTS (SELECT 1 FROM #Fragmentacao AS F))
    BEGIN
        -- Inserindo índices a desfragmentar
        INSERT INTO #IndicesDesfragmentar
        (
            [SchemaName],
            [TableName],
            [IndexName],
            [FillFact],
            [NewFillFact],
            [PageSpltForIndex],
            [AvgFragmentationInPercent],
            [PageCount]
        )
        SELECT CAST(S.name AS VARCHAR(128)) AS SchemaName,
               CAST(T.name AS VARCHAR(128)) AS TableName,
               CAST(I.name AS VARCHAR(128)) AS INDEX_NAME,
               CAST(I.fill_factor AS TINYINT),
               NULL,
               CAST(IOS.leaf_allocation_count AS INT) AS PAGE_SPLIT_FOR_INDEX,
               F.AvgFragmentationInPercent,
               CAST(F.PageCount AS INT)
        FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, 'DETAILED') IOS
            JOIN #Fragmentacao AS F ON IOS.object_id = F.ObjectId AND IOS.index_id = F.IndexId
            JOIN sys.indexes I ON IOS.index_id = I.index_id AND IOS.object_id = I.object_id
            JOIN sys.tables AS T ON I.object_id = T.object_id
            JOIN sys.schemas AS S ON T.schema_id = S.schema_id
        WHERE  S.name NOT IN (SELECT SE.SchemaName COLLATE DATABASE_DEFAULT FROM @SchemasExcecao AS SE)
              AND T.name NOT IN (SELECT TE.TableName COLLATE DATABASE_DEFAULT FROM @TableExcecao AS TE)
        OPTION (MAXDOP 0);

        -- Atualizando FillFact
        UPDATE IX
        SET IX.FillFact = CASE
                              WHEN IX.FillFact = 0 THEN 100
                              WHEN IX.FillFact = 10 THEN 90
                              WHEN IX.FillFact = 20 THEN 80
                              WHEN IX.FillFact = 30 THEN 70
                              WHEN IX.FillFact = 40 THEN 60
                              ELSE 100
                          END
        FROM #IndicesDesfragmentar IX;

        -- Atualizando NewFillFact
        UPDATE FRAG
        SET FRAG.NewFillFact = CASE
                                   WHEN FRAG.AvgFragmentationInPercent >= 95 THEN FRAG.FillFact - @MinFillFactorLevel3
                                   WHEN FRAG.AvgFragmentationInPercent >= 60 AND FRAG.AvgFragmentationInPercent < 95 THEN FRAG.FillFact - @MinFillFactorLevel4
                                   WHEN FRAG.AvgFragmentationInPercent >= @MinFrag AND FRAG.AvgFragmentationInPercent < 60 THEN FRAG.FillFact - @MinFillFactorLevel5
                                   ELSE @MinFillFactorLevel6
                               END
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.NewFillFact IS NULL;

        -- Gerando scripts de reorganização/reconstrução
        UPDATE FRAG
        SET FRAG.Script = CONCAT(
                                    'ALTER INDEX ',
                                    QUOTENAME(FRAG.IndexName),
                                    SPACE(1),
                                    'ON',
                                    SPACE(1),
                                    QUOTENAME(FRAG.SchemaName),
                                    '.',
                                    QUOTENAME(FRAG.TableName),
                                    IIF(FRAG.AvgFragmentationInPercent <= 30, ' REORGANIZE ', ' REBUILD')
                                )
        FROM #IndicesDesfragmentar FRAG;

        UPDATE FRAG
        SET FRAG.Script = CONCAT(
                                    FRAG.Script,
                                    ' WITH (',
                                    IIF(@TipoVersao IN ('Azure', 'Enterprise'), 'ONLINE=ON, DATA_COMPRESSION=PAGE,', ''),
                                    'MAXDOP=8, SORT_IN_TEMPDB=ON, FILLFACTOR=',
                                    FRAG.NewFillFact,
                                    ')'
                                )
        FROM #IndicesDesfragmentar FRAG
        WHERE FRAG.AvgFragmentationInPercent >= 30;

        -- Executando os scripts de manutenção se @Efetivar = 1
        DECLARE @Script NVARCHAR(900);
        DECLARE @StartTime DATETIME = GETDATE();
        DECLARE @Mensagem VARCHAR(1000);

        IF (EXISTS (SELECT 1 FROM #IndicesDesfragmentar AS FI) AND @Efetivar = 1)
        BEGIN
            DECLARE cursor_Fragmentacao CURSOR FAST_FORWARD READ_ONLY FOR
            SELECT FI.Script
            FROM #IndicesDesfragmentar AS FI;

            OPEN cursor_Fragmentacao;

            FETCH NEXT FROM cursor_Fragmentacao INTO @Script;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @StartTime = GETDATE();
                EXEC sys.sp_executesql @Script;

                IF (@MostrarIndices = 1)
                BEGIN
                    SET @Mensagem = CONCAT(
                                            'Comando: ',
                                            @Script,
                                            ' Executado em: ',
                                            DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                                            ' MS'
                                        );

                    RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                END;

                FETCH NEXT FROM cursor_Fragmentacao INTO @Script;
            END;

            CLOSE cursor_Fragmentacao;
            DEALLOCATE cursor_Fragmentacao;
        END;
    END;

    -- Exibindo os índices desfragmentados se @MostrarIndices = 1
    IF (@MostrarIndices = 1)
    BEGIN
        SELECT * FROM #IndicesDesfragmentar;
    END;
END;
GO
