
/*Sessão 1*/

IF (EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'Tab1'))
BEGIN

    DROP TABLE dbo.Tab1;
END;

CREATE TABLE Tab1 (
    Col1 VARCHAR(250) NOT NULL
        DEFAULT (NEWID()) PRIMARY KEY,
    Col2 CHAR(2000) NOT NULL
        DEFAULT ('Teste')
		)		;


TRUNCATE TABLE dbo.Tab1;


WHILE 1 = 1
BEGIN
    INSERT INTO dbo.Tab1 (Col1,
                          Col2)
    DEFAULT VALUES;

END;



-------------- /*Segunda sessão  */
IF (OBJECT_ID('TEMPDB..#Demostracao') IS NOT NULL)
    DROP TABLE #Demostracao;

CREATE TABLE #Demostracao (
    Col1 VARCHAR(250),
    Col2 CHAR(2000) NOT NULL,
	Pagina VARCHAR(100)
	
	);


WHILE 1 = 1
BEGIN
/*Usa o NOLOCK para forçar leiutura em ordem de alocação das paginas (Alocation Order Scam) */
    INSERT INTO #Demostracao
    
	SELECT T.Col1,
           T.Col2,
		   sys.fn_PhysLocFormatter(%%physloc%%) AS Pagina FROM dbo.Tab1 AS T WITH(NOLOCK)

     IF( EXISTS( SELECT D.Col1 FROM #Demostracao AS D
	    GROUP BY D.Col1
		HAVING  COUNT(D.Col1) >1))
		BEGIN
				BREAK;
		END
	  
END;

--SELECT D.Col1 FROM #Demostracao AS D
--GROUP BY D.Col1
--HAVING COUNT(D.Col1) >1

--SELECT * FROM  #Demostracao AS D WHERE D.Col1 ='79D3D1CF-802F-4BA3-AFF4-2C6446496E94';
