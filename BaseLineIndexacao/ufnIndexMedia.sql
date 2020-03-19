
CREATE OR ALTER FUNCTION HealthCheck.ufnIndexMedia (@SnapShotDayMedia SMALLINT = 7)
RETURNS @retorno TABLE (
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
    [IsUnique] BIT)
AS
BEGIN

    --  DECLARE @SnapShotDayMedia SMALLINT = 3;

    ;WITH Resumo
       AS (SELECT Hist.SnapShotDate,
                  Hist.ObjectId,
                  Hist.RowsInTable,
                  ISSI.ObjectName,
                  Hist.IndexId,
                  ISSI.IndexName,
                  Ind.is_unique_constraint AS IsUniqueConstraint,
                  Ind.is_primary_key AS IsPrimaryKey,
                  Ind.is_unique AS IsUnique,
                  MaxAnalise = MAX(Hist.Analise) OVER (),
                  MaxAnaliseForTable = MAX(Hist.Analise) OVER (PARTITION BY Ind.object_id),
                  MaxAnaliseForIndex = COUNT(Hist.Analise) OVER (PARTITION BY Ind.object_id, Ind.index_id),
                  QtdAnalize = COUNT(Hist.SnapShotDate) OVER (PARTITION BY Ind.object_id, Ind.index_id),
                  PercScan = CAST(ISNULL((Hist.UserScans * 1.0 / IIF(Hist.Reads = 0, 1, Hist.Reads)) * 100, 0) AS DECIMAL(18, 2)),
                  Analise = Hist.Analise,
                  Hist.UserScans,
                  Hist.Reads,
                  Hist.Write,
                  [PercAproveitamento] = ISNULL(Hist.PercAproveitamento, 0),
                  [PercCustoMedio] = ISNULL(Hist.PercCustoMedio, 0),
                  Hist.IsBadIndex
             FROM HealthCheck.SnapShotIndexHistory AS Hist
             JOIN HealthCheck.SnapShotIndex AS ISSI
               ON Hist.ObjectId = ISSI.ObjectId
              AND Hist.IndexId  = ISSI.IndexId
             JOIN sys.indexes AS Ind
               ON ISSI.ObjectId = Ind.object_id
              AND ISSI.IndexId  = Ind.index_id)
    INSERT INTO @retorno
    SELECT RA.SnapShotDate,
           RA.ObjectId,
           RA.RowsInTable,
           RA.ObjectName,
           RA.IndexId,
           RA.IndexName,
           RA.Reads,
           RA.Write,
           RA.PercAproveitamento,
           RA.PercCustoMedio,
           RA.PercScan,
           [AvgPercScan] = (   SELECT CAST(AVG(R2.PercScan) AS DECIMAL(10, 2))
                                 FROM Resumo R2
                                WHERE R2.ObjectId = RA.ObjectId
                                  AND R2.IndexId  = RA.IndexId
                                  AND R2.Analise BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise),
           [AvgIsBad] = (   SELECT AVG(CAST((R2.IsBadIndex) AS TINYINT))
                              FROM Resumo R2
                             WHERE R2.ObjectId = RA.ObjectId
                               AND R2.IndexId  = RA.IndexId
                               AND R2.Analise BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise),
           [AvgReads] = (   SELECT CAST(AVG(R2.Reads) AS DECIMAL(10, 2))
                              FROM Resumo R2
                             WHERE R2.ObjectId = RA.ObjectId
                               AND R2.IndexId  = RA.IndexId
                               AND R2.Analise BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise),
           [AvgWrites] = (   SELECT CAST(AVG(R2.Write) AS DECIMAL(10, 2))
                               FROM Resumo R2
                              WHERE R2.ObjectId = RA.ObjectId
                                AND R2.IndexId  = RA.IndexId
                                AND R2.Analise BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise),
           [AvgAproveitamento] = (   SELECT CAST(AVG(R2.PercAproveitamento) AS DECIMAL(10, 2))
                                       FROM Resumo R2
                                      WHERE R2.ObjectId = RA.ObjectId
                                        AND R2.IndexId  = RA.IndexId
                                        AND R2.Analise BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise),
           [AvgCusto] = (   SELECT CAST(AVG(R2.PercCustoMedio) AS DECIMAL(10, 2))
                              FROM Resumo R2
                             WHERE R2.ObjectId = RA.ObjectId
                               AND R2.IndexId  = RA.IndexId
                               AND R2.Analise BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise),
           RA.IsBadIndex,
           RA.MaxAnaliseForTable,
           RA.MaxAnaliseForIndex,
           RA.QtdAnalize,
           RA.Analise,
           RA.IsUniqueConstraint,
           RA.IsPrimaryKey,
           RA.IsUnique
      FROM Resumo RA
     ORDER BY RA.ObjectId,
              RA.IndexId,
              RA.SnapShotDate OFFSET 0 ROWS FETCH NEXT 50000 ROW ONLY;

    RETURN;
END;

