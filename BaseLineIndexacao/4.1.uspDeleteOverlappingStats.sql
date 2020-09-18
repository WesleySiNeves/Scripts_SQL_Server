

/* ==================================================================
--Data: 12/12/2018 
--Autor :Wesley Neves
--Observação: https://blog.pythian.com/sql-server-statistics-maintenance-and-best-practices/
 
-- ==================================================================
*/

ALTER PROCEDURE HealthCheck.uspDeleteOverlappingStats
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
