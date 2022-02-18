

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

