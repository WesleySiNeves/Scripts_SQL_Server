USE Teste
SELECT TE.data ,
       TE.nome ,
       TE.valor FROM dbo.tb_empresas AS TE


DECLARE @cols NVARCHAR (MAX)

SELECT @cols = COALESCE (@cols + ',[' + CONVERT(NVARCHAR, [DATA], 109) + ']', 
               '[' + CONVERT(NVARCHAR, [DATA], 109) + ']')
               FROM    (SELECT DISTINCT [DATA] FROM  dbo.tb_empresas) PV  
               ORDER BY [DATA]

DECLARE @query NVARCHAR(MAX)
SET @query = '           
              SELECT p.* FROM 
             (
                 SELECT * FROM dbo.tb_empresas
             ) x
             PIVOT 
             (
                 SUM(Valor)
                 FOR [DATA] IN (' + @cols + ')
            ) p      
            '     
EXEC SP_EXECUTESQL @query