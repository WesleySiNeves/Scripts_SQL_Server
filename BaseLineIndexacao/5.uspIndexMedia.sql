SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
--SET QUOTED_IDENTIFIER ON
--SET ANSI_NULLS ON
--GO

----

CREATE OR ALTER   PROCEDURE HealthCheck.uspIndexMedia
(
    @SnapShotDayMedia SMALLINT = 7,
    @TableObjectIds TableIntegerIds READONLY,
    @IsUniqueConstraint BIT = NULL,
    @IsUnique BIT = NULL,
    @IsPrimaryKey BIT = NULL,
    @AvgIsBad BIT = NULL,
    @PercentualMaximoAcesso DECIMAL(5, 2) = 9
)
AS
BEGIN

 
                             


    --DECLARE @SnapShotDayMedia SMALLINT = 7,
    --        @IsUniqueConstraint BIT = 0,
    --        @IsUnique BIT = 0,
    --        @IsPrimaryKey BIT = 0,
    --        @AvgIsBad BIT = 1,
    --        @PercentualMaximoAcesso DECIMAL(5, 2) = 9;


    SET @SnapShotDayMedia = ISNULL(@SnapShotDayMedia, 1);

  --  DECLARE @TableObjectIds AS TableIntegerIds;

    --INSERT INTO @TableObjectIds
    --(
    --    Id
    --)
    --VALUES (13399267);


    DECLARE @ListInts VARCHAR(3000);

    IF (EXISTS (SELECT 1 FROM @TableObjectIds AS TOI))
    BEGIN

        SET @ListInts =
        (
            SELECT STUFF(
                            (
                                SELECT ', ' + CAST(c2.Id AS VARCHAR(12))
                                FROM @TableObjectIds c2
                                FOR XML PATH(''), TYPE
                            ).value('.', 'varchar(900)'), -- extract element value and convert
                            1,
                            2,
                            ''
                        )
        );
    END;


    DECLARE @QueryInicial VARCHAR(3000);
    DECLARE @Result VARCHAR(3000);


    IF (OBJECT_ID('TEMPDB..#Retorno') IS NOT NULL)
        DROP TABLE #Retorno;

    CREATE TABLE #Retorno
    (
        [SnapShotDate] DATETIME2(2),
        [ObjectId] INT,
        [RowsInTable] INT,
        [ObjectName] VARCHAR(260),
        [IndexId] SMALLINT,
        [IndexName] VARCHAR(128),
        [IsUniqueConstraint] BIT,
        [IsPrimaryKey] BIT,
        [IsUnique] BIT,
        [Analise] BIGINT,
        [MaxAnaliseForTable] BIGINT,
        [MaxAnaliseForIndex] BIGINT,
        [QtdAnalize] INT,
        [PercScan] DECIMAL(18, 2),
        [UserScans] INT,
        [Reads] BIGINT,
        [Write] INT,
        [PercAproveitamento] DECIMAL(18, 2),
        [PercCustoMedio] DECIMAL(18, 2),
        [IsBadIndex] BIT
            PRIMARY KEY
            (
                ObjectId,
                IndexId,
                Analise
            )
    );



    SET @QueryInicial = CONCAT(';WITH Resumo', SPACE(1));
    SET @QueryInicial += CONCAT(
                                   'AS (SELECT Hist.SnapShotDate,Hist.ObjectId,ISSI.ObjectName,Hist.RowsInTable,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT('Hist.IndexId,ISSI.IndexName,Ind.is_unique_constraint AS IsUniqueConstraint,', SPACE(1));
    SET @QueryInicial += CONCAT('Ind.is_primary_key AS IsPrimaryKey,Ind.is_unique AS IsUnique,', SPACE(1));
    SET @QueryInicial += CONCAT('Analise = COUNT(*) OVER (ORDER BY Hist.SnapShotDate),', SPACE(1));
    SET @QueryInicial += CONCAT(
                                   'AnaliseForTable = DENSE_RANK() OVER (PARTITION BY Ind.object_id ORDER BY Hist.SnapShotDate),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   'AnaliseForIndex = DENSE_RANK() OVER (PARTITION BY Ind.object_id, Ind.index_id ORDER BY Hist.SnapShotDate),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   'QtdAnalize = COUNT(Hist.SnapShotDate) OVER (PARTITION BY Ind.object_id, Ind.index_id),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   'PercScan = CAST(ISNULL((Hist.UserScans * 1.0 / IIF(Hist.Reads = 0, 1, Hist.Reads)) * 100, 0) AS DECIMAL(18, 2)),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   'Hist.UserScans,Hist.Reads,Hist.Write,[PercAproveitamento] = ISNULL(Hist.PercAproveitamento, 0),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT('[PercCustoMedio] = ISNULL(Hist.PercCustoMedio, 0),Hist.IsBadIndex', SPACE(1));
    SET @QueryInicial += CONCAT(
                                   'FROM HealthCheck.SnapShotIndexHistory AS Hist 
							   JOIN HealthCheck.SnapShotIndex AS ISSI ON Hist.ObjectId = ISSI.ObjectId AND Hist.IndexId = ISSI.IndexId',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' JOIN sys.indexes AS Ind ON ISSI.ObjectId = Ind.object_id AND ISSI.IndexId = Ind.index_id ),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' UltimaAnalise AS (SELECT R.SnapShotDate,R.ObjectId,R.RowsInTable,R.ObjectName,R.IndexId,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   'R.IndexName,R.IsUniqueConstraint,R.IsPrimaryKey,R.IsUnique,R.AnaliseForIndex,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' MaxAnaliseForTable = MAX(R.AnaliseForTable) OVER (PARTITION BY R.ObjectId, R.IndexId),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' MaxAnaliseForIndex = MAX(R.AnaliseForIndex) OVER (PARTITION BY R.ObjectId, R.IndexId),',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   'R.QtdAnalize,R.PercScan,R.UserScans,R.Reads,R.Write,R.PercAproveitamento,R.PercCustoMedio,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT('R.IsBadIndex FROM Resumo R )', SPACE(1));

    SET @QueryInicial += CONCAT(
                                   ' INSERT INTO #Retorno (SnapShotDate,ObjectId,RowsInTable,ObjectName,IndexId,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' IndexName,IsUniqueConstraint,IsPrimaryKey,IsUnique,Analise,MaxAnaliseForTable,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' MaxAnaliseForIndex,QtdAnalize,PercScan,UserScans,Reads,Write,PercAproveitamento,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(' PercCustoMedio,IsBadIndex)', SPACE(1));
    SET @QueryInicial += CONCAT(' SELECT R.SnapShotDate,R.ObjectId,R.RowsInTable,R.ObjectName,R.IndexId,', SPACE(1));
    SET @QueryInicial += CONCAT(
                                   ' R.IndexName,R.IsUniqueConstraint,R.IsPrimaryKey,R.IsUnique,R.AnaliseForIndex,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' R.MaxAnaliseForTable,R.MaxAnaliseForIndex,R.QtdAnalize,R.PercScan,R.UserScans,',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(
                                   ' R.Reads,R.Write,R.PercAproveitamento,R.PercCustoMedio,R.IsBadIndex FROM UltimaAnalise R ',
                                   SPACE(1)
                               );
    SET @QueryInicial += CONCAT(' WHERE 1 = 1', SPACE(1));


    IF (
           @IsPrimaryKey IS NOT NULL
           OR @IsUnique IS NOT NULL
           OR @IsUniqueConstraint IS NOT NULL
           OR @ListInts IS NOT NULL
       )
        SET @QueryInicial += CONCAT(' AND (', SPACE(1));







    IF (@IsPrimaryKey IS NOT NULL)
    BEGIN
        SET @QueryInicial += CONCAT('R.IsPrimaryKey = ', @IsPrimaryKey, SPACE(1));
    END;

    IF (@IsUnique IS NOT NULL)
    BEGIN
        SET @QueryInicial += CONCAT('AND R.IsUnique = ', @IsUnique, SPACE(1));
    END;
    IF (@IsUniqueConstraint IS NOT NULL)
    BEGIN
        SET @QueryInicial += CONCAT('AND R.IsUniqueConstraint = ', @IsUniqueConstraint, SPACE(1));
    END;



    IF (EXISTS (SELECT 1 FROM @TableObjectIds AS TOI))
    BEGIN
        IF (
               @IsPrimaryKey IS NOT NULL
               OR @IsUnique IS NOT NULL
               OR @IsUniqueConstraint IS NOT NULL
           )
            SET @QueryInicial += CONCAT(' AND ', SPACE(1));


        SET @QueryInicial += CONCAT('  R.ObjectId IN (' + @ListInts + ')', SPACE(1));
    END;



    IF (
           @IsPrimaryKey IS NOT NULL
           OR @IsUnique IS NOT NULL
           OR @IsUniqueConstraint IS NOT NULL
           OR @ListInts IS NOT NULL
       )
        SET @QueryInicial += CONCAT(' );', SPACE(1));


    --SELECT @QueryInicial;
    EXEC (@QueryInicial);


    IF (EXISTS (SELECT 1 FROM #Retorno AS R))
    BEGIN


        SET @Result = CONCAT(SPACE(1), ';WITH Dados AS (', SPACE(1));
        SET @Result += CONCAT(
                                 'SELECT RA.SnapShotDate,RA.ObjectId,RA.RowsInTable,RA.ObjectName,RA.IndexId,RA.IndexName,',
                                 SPACE(1)
                             );
        SET @Result += CONCAT('RA.Reads,RA.Write,RA.PercAproveitamento,RA.PercCustoMedio,RA.PercScan,', SPACE(1));
        SET @Result += CONCAT(
                                 '[AvgPercScan] = CAST(AVG(RA.PercScan) OVER(PARTITION BY RA.ObjectId, RA.IndexId ORDER BY RA.Analise  ROWS BETWEEN ',
                                 @SnapShotDayMedia,
                                 ' PRECEDING AND CURRENT ROW) AS DECIMAL(5,2)),',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 '[AvgIsBad] = AVG(CAST(RA.IsBadIndex AS TINYINT)) OVER(PARTITION BY RA.ObjectId, RA.IndexId ORDER BY RA.Analise  ROWS BETWEEN ',
                                 @SnapShotDayMedia,
                                 ' PRECEDING AND CURRENT ROW),',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 '[AvgReads] = CAST(AVG(RA.Reads) OVER(PARTITION BY RA.ObjectId, RA.IndexId ORDER BY RA.Analise  ROWS BETWEEN ',
                                 @SnapShotDayMedia,
                                 ' PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)),',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 '[AvgWrites] = CAST(AVG(RA.Write) OVER(PARTITION BY RA.ObjectId, RA.IndexId ORDER BY RA.Analise  ROWS BETWEEN ',
                                 @SnapShotDayMedia,
                                 ' PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)),',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 '[AvgAproveitamento] = CAST(AVG(RA.PercAproveitamento) OVER(PARTITION BY RA.ObjectId, RA.IndexId ORDER BY RA.Analise  ROWS BETWEEN ',
                                 @SnapShotDayMedia,
                                 ' PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)),',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 '[AvgCusto] = CAST(AVG(RA.PercCustoMedio) OVER(PARTITION BY RA.ObjectId, RA.IndexId ORDER BY RA.Analise  ROWS BETWEEN ',
                                 @SnapShotDayMedia,
                                 ' PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)),',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 'RA.IsBadIndex,RA.MaxAnaliseForTable,RA.MaxAnaliseForIndex,RA.QtdAnalize,RA.Analise,RA.IsUniqueConstraint,RA.IsPrimaryKey,RA.IsUnique',
                                 SPACE(1)
                             );
        SET @Result += CONCAT('FROM #Retorno AS RA ', SPACE(1));
        SET @Result += CONCAT(')',SPACE(1));
        SET @Result += CONCAT(
                                 'SELECT R.SnapShotDate,R.ObjectId,R.RowsInTable,R.ObjectName,R.IndexId,R.IndexName,',
                                 SPACE(1)
                             );
        SET @Result += CONCAT('R.Reads,R.Write,R.PercAproveitamento,R.PercCustoMedio,R.PercScan,', SPACE(1));
        SET @Result += CONCAT(
                                 'R.AvgPercScan,R.AvgIsBad,R.AvgReads,R.AvgWrites,R.AvgAproveitamento,R.AvgCusto,R.IsBadIndex,R.MaxAnaliseForTable,',
                                 SPACE(1)
                             );
        SET @Result += CONCAT(
                                 'R.MaxAnaliseForIndex,R.QtdAnalize,R.Analise,R.IsUniqueConstraint,R.IsPrimaryKey,R.IsUnique FROM  Dados R
								  WHERE R.Analise = R.MaxAnaliseForIndex	',
                                 SPACE(1)
                             );


        IF (@AvgIsBad IS NOT NULL OR @PercentualMaximoAcesso IS NOT NULL)
            SET @Result += CONCAT('AND (', SPACE(1));



        
            SET @Result += CONCAT('1 = 1',SPACE(1));
     

        IF (@PercentualMaximoAcesso IS NOT NULL)
        BEGIN

            IF (@AvgIsBad IS NOT NULL OR @PercentualMaximoAcesso IS NOT NULL)
                SET @Result += CONCAT('AND ', SPACE(1));


            SET @Result += CONCAT(
                                     '( R.IsPrimaryKey = 0 AND R.AvgAproveitamento <=',
                                     @PercentualMaximoAcesso,
                                     SPACE(1),
                                     ')',
                                     SPACE(1)
                                 );
        END;


        IF (@AvgIsBad IS NOT NULL OR @PercentualMaximoAcesso IS NOT NULL)
            SET @Result += CONCAT(')', SPACE(1));


        SET @Result += CONCAT(
                                 'ORDER BY R.ObjectId, R.IndexId,  R.SnapShotDate OFFSET 0 ROWS FETCH NEXT 50000 ROW ONLY;',
                                 SPACE(1)
                             );



    END;

    IF (@Result IS NOT NULL)
    BEGIN

      --SELECT  @Result;
	    EXEC (@Result);
    END;

END;

GO