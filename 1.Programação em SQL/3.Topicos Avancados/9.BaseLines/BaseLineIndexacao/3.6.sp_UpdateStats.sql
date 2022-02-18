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

