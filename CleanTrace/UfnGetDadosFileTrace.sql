SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

--SELECT * FROM dbo.ufnGetDadosSumaryFromFileTrace('siscontdespesarelacaocentrocustosAntesRefatoracao') AS UGDSFFT

ALTER FUNCTION ufnGetDadosSumaryFromFileTrace(@tranceName VARCHAR(400))
  RETURNS TABLE WITH  SCHEMABINDING
RETURN 
(

SELECT [File Trace] = Tr.TraceName,
       [Data Arquivo] = CONVERT(VARCHAR(11), DD.CalendarDate, 103),
       [Total CPU] = SUM(TD.CPU),
       [Total Leituras] = SUM(TD.Reads),
       [Total Escritas] = SUM(TD.Writes),
       [Total Duração] = SUM(TD.Duration),
       [Total querys Executadas] = SUM(TD.ExecutionCount)
  FROM dbo.CTTraceSummary TD
  LEFT JOIN dbo.CTApplication A
    ON A.ApplicationID    = TD.ApplicationID
  LEFT JOIN dbo.CTLogin L
    ON L.LoginID          = TD.LoginID
  LEFT JOIN dbo.CTHost H
    ON H.HostID           = TD.HostID
  LEFT JOIN dbo.CTTextData T
    ON T.TextDataHashCode = TD.TextDataHashCode
  LEFT JOIN dbo.CTServer S
    ON S.ServerID         = TD.ServerID
  LEFT JOIN dbo.CTTrace Tr
    ON Tr.TraceID         = TD.TraceID
  LEFT JOIN dbo.CTDateDimension DD
    ON DD.DateID          = TD.DateID
 WHERE Tr.TraceName = ISNULL(@tranceName, Tr.TraceName)
 GROUP BY CONVERT(VARCHAR(11), DD.CalendarDate, 103),
          Tr.TraceName 

);



