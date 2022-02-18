SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
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