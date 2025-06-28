

--CREATE TABLE [dbo].[RespostaForum]
--(
--[ID] [int] NOT NULL IDENTITY(1, 1),
--[UF] [char] (2) COLLATE Latin1_General_CI_AI NULL,
--[DATA] [date] NULL,
--[Valor] [decimal] (18, 2) NULL
--) ON [PRIMARY]
--GO
/*
1	CE	2016-10-17	100.00
2	AC	2016-11-18	200.00
3	BA	2016-11-18	300.00
*/

DECLARE @cols NVARCHAR (MAX)

SELECT @cols = COALESCE (@cols + ',[' + CONVERT(NVARCHAR, [DATA], 109) + ']', 
               '[' + CONVERT(NVARCHAR, [DATA], 109) + ']')
               FROM    (SELECT DISTINCT [DATA] FROM RespostaForum) PV  
               ORDER BY [DATA]




DECLARE @query NVARCHAR(MAX)
SET @query = '           
              SELECT p.* FROM 
             (
                 SELECT * FROM RespostaForum
             ) x
             PIVOT 
             (
                 SUM(Valor)
                 FOR [DATA] IN (' + @cols + ')
            ) p      

            '     
EXEC SP_EXECUTESQL @query

