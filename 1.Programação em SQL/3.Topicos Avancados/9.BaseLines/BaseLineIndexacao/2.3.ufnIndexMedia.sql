

CREATE OR ALTER FUNCTION HealthCheck.ufnIndexMedia
(
    @SnapShotDayMedia SMALLINT = 7
) 
RETURNS TABLE RETURN 

--DECLARE @SnapShotDayMedia SMALLINT = 3;

WITH Resumo
AS (SELECT Hist.SnapShotDate,
           Hist.ObjectId,
           Hist.RowsInTable,
           ISSI.ObjectName,
           Hist.IndexId,
           ISSI.IndexName,
           I.is_unique_constraint,
           I.is_primary_key,
           I.is_unique,
           MaxAnalise = MAX(Hist.Analise) OVER (),
           MaxAnaliseForTable = MAX(Hist.Analise) OVER(PARTITION BY I.object_id),
           MaxAnaliseForIndex = COUNT(Hist.Analise) OVER(PARTITION BY I.object_id, I.index_id),
           QtdAnalize = COUNT(Hist.SnapShotDate) OVER (PARTITION BY I.object_id, I.index_id),
           PercScan  = CAST(ISNULL(
                                           (Hist.UserScans * 1.0 / IIF(Hist.Reads = 0, 1,  Hist.Reads))
                                           * 100,
                                           0
                                       ) AS DECIMAL(18, 2)),
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
               AND Hist.IndexId = ISSI.IndexId
        JOIN sys.indexes AS I
            ON ISSI.ObjectId = I.object_id
               AND ISSI.IndexId = I.index_id
   )
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
        [AvgPercScan] =(
           SELECT CAST(AVG(R2.PercScan)  AS DECIMAL(10, 2))
           FROM Resumo R2
           WHERE R2.ObjectId = RA.ObjectId
                 AND R2.IndexId = RA.IndexId
                 AND R2.Analise
                 BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise
       ),
       [AvgIsBad] =(
           SELECT AVG(CAST((R2.IsBadIndex) AS TINYINT))
           FROM Resumo R2
           WHERE R2.ObjectId = RA.ObjectId
                 AND R2.IndexId = RA.IndexId
                 AND R2.Analise
                 BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise
       ),
      [AvgReads] =
       (
           SELECT CAST(AVG(R2.Reads) AS DECIMAL(10, 2))
           FROM Resumo R2
           WHERE R2.ObjectId = RA.ObjectId
                 AND R2.IndexId = RA.IndexId
                 AND R2.Analise
                 BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise
       ),
       [AvgWrites] =
       (
           SELECT CAST(AVG(R2.Write) AS DECIMAL(10, 2))
           FROM Resumo R2
           WHERE R2.ObjectId = RA.ObjectId
                 AND R2.IndexId = RA.IndexId
                 AND R2.Analise
                 BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise
       ),
       [AvgAproveitamento] =
       (
           SELECT CAST(AVG(R2.PercAproveitamento) AS DECIMAL(10, 2))
           FROM Resumo R2
           WHERE R2.ObjectId = RA.ObjectId
                 AND R2.IndexId = RA.IndexId
                 AND R2.Analise
                 BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise
       ),
       [AvgCusto] =
       (
           SELECT CAST(AVG(R2.PercCustoMedio) AS DECIMAL(10, 2))
           FROM Resumo R2
           WHERE R2.ObjectId = RA.ObjectId
                 AND R2.IndexId = RA.IndexId
                 AND R2.Analise
                 BETWEEN R2.Analise - @SnapShotDayMedia AND RA.Analise
       ),
       RA.IsBadIndex,
       RA.MaxAnaliseForTable,
       RA.MaxAnaliseForIndex,
       RA.QtdAnalize,
       RA.Analise,
       IsUniqueConstraint = RA.is_unique_constraint,
       IsPrimaryKey = RA.is_primary_key,
       IsUnique = RA.is_unique
FROM Resumo RA 
ORDER BY RA.ObjectId ,RA.IndexId,RA.SnapShotDate   OFFSET 0 ROWS FETCH NEXT 50000 ROW ONLY ;

--GO