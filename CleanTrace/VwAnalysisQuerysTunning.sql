
--CREATE SCHEMA AnalysisQuerysTunning

--INSERT INTO AnalysisQuerysTunning.ResumoTrace

--SELECT * FROM AnalysisQuerysTunning.GetDadosFronTrace  


SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

----CREATE SCHEMA AnalysisQuerysTunning
--CREATE VIEW AnalysisQuerysTunning.GetDadosFronTrace AS 
--(
--SELECT [ID] = text.TextDataHashCode,
--       [Query] = text.NormalizedTextData,
--	   CT.ExecutionCount,
--	   CT.RowID,
--       Fi.TraceFileName,
--	   [Total Paginas Lidas] =CT.Reads,
--	   [Total Paginas MB] =  CAST(((CT.Reads *8) /1024) AS NUMERIC(18,2)),
--       CT.CPU,
--       CT.Writes,
--       [Duration em MS] = CT.Duration,
--	   [Duration em Sec] = (CT.Duration/ 1000000)
--  FROM [BaseLine].[dbo].[CTTextData] text
--JOIN dbo.CTTraceSummary CT ON CT.TextDataHashCode = text.TextDataHashCode
--JOIN dbo.CTTraceFile Fi ON Fi.TraceFileID = CT.TraceFileID
--)

--GO


SELECT * FROM AnalysisQuerysTunning.GetDadosFronTrace