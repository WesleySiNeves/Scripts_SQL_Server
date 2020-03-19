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
VALUES  ( 'JOAO' , 'Separação' , 'Sal Mês' ,1 ,3028.67 ),
		( 'JOAO' , 'Separação' , 'Sal Mês' ,2 ,4543.00),
		( 'JOAO' , 'Separação' , 'Sal Mês' ,3 ,4543.00),	
		( 'JOAO' , 'Separação' , 'Sal Mês' ,4 ,4543.00),	
		( 'JOAO' , 'Separação' , 'Sal Mês' ,5 ,4543.00),	
		( 'JOAO' , 'Separação' , 'Sal Mês' ,6 ,4088.70),	
		( 'JOAO' , 'Separação' , 'Sal Mês' ,7 ,4088.70),	
		( 'JOAO' , 'Separação' , 'Sal Mês' ,8 ,1968.63),
		( 'JOAO' , 'Separação' , 'Sal Mês' ,9 ,4543.00),
		( 'JOAO' , 'Separação' , 'Sal Mês' ,10 ,4981.00),
		( 'JOAO' , 'Separação' , 'Sal Mês' ,11 ,0),
		( 'JOAO' , 'Separação' , 'Sal Mês' ,12 ,0),


		( 'MARIA' , 'Separação' , 'Sal Mês' ,1 ,3028.67 ),
		( 'MARIA' , 'Separação' , 'Sal Mês' ,2 ,3341.00),
		( 'MARIA' , 'Separação' , 'Sal Mês' ,3 ,3341.00),	
		( 'MARIA' , 'Separação' , 'Sal Mês' ,4 ,3341.00),	
		( 'MARIA' , 'Separação' , 'Sal Mês' ,5 ,3341.00),	
		( 'MARIA' , 'Separação' , 'Sal Mês' ,6 ,3341.00),	
		( 'MARIA' , 'Separação' , 'Sal Mês' ,7 ,3341.00),	
		( 'MARIA' , 'Separação' , 'Sal Mês' ,8 ,3341.00),
		( 'MARIA' , 'Separação' , 'Sal Mês' ,9 ,0),
		( 'MARIA' , 'Separação' , 'Sal Mês' ,10 ,3663.00),
		( 'MARIA' , 'Separação' , 'Sal Mês' ,11 ,0),
		( 'MARIA' , 'Separação' , 'Sal Mês' ,12 ,0),

		( 'JOSE' , 'Separação' , 'Sal Mês' ,1 ,	2968.20 ),
		( 'JOSE' , 'Separação' , 'Sal Mês' ,2 ,4015.80),
		( 'JOSE' , 'Separação' , 'Sal Mês' ,3 ,5238.00),	
		( 'JOSE' , 'Separação' , 'Sal Mês' ,4 ,5238.00),	
		( 'JOSE' , 'Separação' , 'Sal Mês' ,5 ,5238.00),	
		( 'JOSE' , 'Separação' , 'Sal Mês' ,6 ,5238.00),	
		( 'JOSE' , 'Separação' , 'Sal Mês' ,7 ,5238.00),	
		( 'JOSE' , 'Separação' , 'Sal Mês' ,8 ,5238.00),
		( 'JOSE' , 'Separação' , 'Sal Mês' ,9 ,5238.00),
		( 'JOSE' , 'Separação' , 'Sal Mês' ,10 ,3666.60),
		( 'JOSE' , 'Separação' , 'Sal Mês' ,11 ,0),
		( 'JOSE' , 'Separação' , 'Sal Mês' ,12 ,0);



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

Solução Dinanmica



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