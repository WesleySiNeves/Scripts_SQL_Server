IF ( OBJECT_ID('TEMPDB..#Resultado') IS NOT NULL )
    DROP TABLE #Resultado;	

CREATE TABLE #Resultado
    (
      Nome VARCHAR(MAX) ,
      CCUSTO VARCHAR(MAX) ,
      Verba VARCHAR(MAX) ,
      Mes VARCHAR(MAX),
      Valor NUMERIC(18, 2) NOT NULL 
     
    );		

INSERT INTO #Resultado
VALUES  ( 'JOAO' , 'Separa��o' , 'Sal M�s' ,1 ,3028.67 ),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,2 ,4543.00),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,3 ,4543.00),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,4 ,4543.00),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,5 ,4543.00),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,6 ,4088.70),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,7 ,4088.70),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,8 ,1968.63),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,9 ,4543.00),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,10 ,4981.00),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,11 ,0),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,12 ,0),


		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,1 ,3028.67 ),
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,2 ,3341.00),
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,3 ,3341.00),	
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,4 ,3341.00),	
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,5 ,3341.00),	
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,6 ,3341.00),	
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,7 ,3341.00),	
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,8 ,3341.00),
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,9 ,0),
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,10 ,3663.00),
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,11 ,0),
		( 'MARIA' , 'Separa��o' , 'Sal M�s' ,12 ,0),

		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,1 ,	2968.20 ),
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,2 ,4015.80),
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,3 ,5238.00),	
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,4 ,5238.00),	
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,5 ,5238.00),	
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,6 ,5238.00),	
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,7 ,5238.00),	
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,8 ,5238.00),
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,9 ,5238.00),
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,10 ,3666.60),
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,11 ,0),
		( 'JOSE' , 'Separa��o' , 'Sal M�s' ,12 ,0);



SELECT *
FROM    ( SELECT   *
          FROM      ( SELECT    Nome ,
                                Mes AS Mes ,
                                Valor
                      FROM      #Resultado
                    ) AS SourceTable PIVOT
    ( SUM(Valor) FOR Mes IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9],
                              [10], [11], [12] ) ) AS PivotTable
        ) A
        CROSS APPLY ( SELECT    SUM(RT.Valor) AS [Total Anual] ,
                                AVG(RT.Valor) AS [Media Anual]
                      FROM      #Resultado RT
                      WHERE     RT.Nome = A.Nome
                    ) b;



/*

Solu��o Dinanmica



DECLARE @cols NVARCHAR (MAX)

SELECT @cols = COALESCE (@cols + ',[' + CONVERT(NVARCHAR, [Mes], 109) + ']', 
               '[' + CONVERT(NVARCHAR, [Mes], 109) + ']')
               FROM    (SELECT DISTINCT [Mes] FROM #Resultado) PV  
               ORDER BY [Mes]



DECLARE @query NVARCHAR(MAX)


SET @query = 'SELECT *
FROM    ( SELECT   *
          FROM      ( SELECT    Nome ,
                                Mes AS Mes ,
                                Valor
                      FROM      #Resultado
                    ) AS SourceTable
					 PIVOT
    (
	     SUM(Valor)
		  FOR [Mes] IN (' + @cols + ') )
	    AS PivotTable
        ) A
        CROSS APPLY ( SELECT    SUM(RT.Valor) AS [Total Anual] ,
                                AVG(RT.Valor) AS [Media Anual]
                      FROM      #Resultado RT
                      WHERE     RT.Nome = A.Nome
                    ) b;
'

EXEC SP_EXECUTESQL @query
*/