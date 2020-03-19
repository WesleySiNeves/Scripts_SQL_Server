;WITH CTE
AS (SELECT TextDataHashCode,
           NormalizedTextData AS Item,
           SUM(ExecutionCount) AS [Quantidade Querys Executadas],
           SUM(CPU) AS CPU,
           CAST(CAST(SUM(CPU) AS DECIMAL(22, 2)) / SUM(ExecutionCount) AS DECIMAL(22, 2)) AS AvgCPU,
           SUM(Reads) AS Reads,
           CAST(CAST(SUM(Reads) AS DECIMAL(22, 2)) / SUM(ExecutionCount) AS DECIMAL(22, 2)) AS AvgReads,
           SUM(Writes) AS Writes,
           CAST(CAST(SUM(Writes) AS DECIMAL(22, 2)) / SUM(ExecutionCount) AS DECIMAL(22, 2)) AS AvgWrites,
           SUM(Duration) AS Duration,
           CAST(CAST(SUM(Duration) AS DECIMAL(22, 2)) / SUM(ExecutionCount) AS DECIMAL(22, 2)) AS AvgDuration,
           ROW_NUMBER() OVER (ORDER BY SUM(CPU) DESC) AS CpuRank,
           ROW_NUMBER() OVER (ORDER BY SUM(Reads) DESC) AS ReadsRank
    FROM [dbo].[CTTraceSummaryView] TD
    WHERE EventClass IN ( 10, 12 )
          AND NormalizedTextData IS NOT NULL
          AND NormalizedTextData <> ''
          AND TraceName = '(One Time Trace Analysis)'
    GROUP BY TextDataHashCode,
             NormalizedTextData
   )
SELECT TOP (15) WITH TIES
    [TextDataHashCode],
    [Item],
    [Quantidade Querys Executadas],
    [CPU],
    [AvgCPU],
    [Total Paginas Lidas] = FORMAT(CTE.[Reads],'N','pt-Br'), 
	[Total Paginas Lidas EM MB] = FORMAT( ( (CTE.[Reads]/8) *1024 ) ,'N','pt-Br'), 
    [AvgReads],
    [Paginas Escritas] = FORMAT(CTE.Writes,'N','pt-Br'),
    [AvgWrites],
    [Duration em MicroSegundos] = [Duration],
    [AvgDuration]
FROM [CTE]
ORDER BY [CPU] DESC,
         [AvgCPU] DESC;