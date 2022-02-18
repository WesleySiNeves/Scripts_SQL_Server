--CREATE TABLE Exemplo (
--  CON_DssNome VARCHAR(MAX),
--  CCUSTO VARCHAR(MAX),
--  VERBA VARCHAR(MAX),
--  Mes INT ,
--  Valor DECIMAL(18,2)
--)

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

SELECT R.Nome ,
       R.CCUSTO ,
       R.Verba ,
       [Janeiro] = SUM(CASE WHEN R.Mes = 1 THEN R.Valor END),
	   [Fevereiro] = SUM(CASE WHEN R.Mes = 2 THEN R.Valor END),
	   [Março] = SUM(CASE WHEN R.Mes = 3 THEN R.Valor END),
	   [Abril] = SUM(CASE WHEN R.Mes = 4 THEN R.Valor END),
	   [Maio] = SUM(CASE WHEN R.Mes = 5 THEN R.Valor END),
	   [Junho] = SUM(CASE WHEN R.Mes = 6 THEN R.Valor END),
	   [Julho] = SUM(CASE WHEN R.Mes = 7 THEN R.Valor END),
	   [Agosto] = SUM(CASE WHEN R.Mes = 8 THEN R.Valor END),
	   [Setembro] = SUM(CASE WHEN R.Mes = 9 THEN R.Valor END),
	   [Outubro] = SUM(CASE WHEN R.Mes = 10 THEN R.Valor END),
	   [Novembro] = SUM(CASE WHEN R.Mes = 11 THEN R.Valor END),
	   [Dezembro] = SUM(CASE WHEN R.Mes = 12 THEN R.Valor END),
	   [Menor Salario] = MIN(R.Valor),
	   [Maior Salario] = MAX(R.Valor),
	   Total = SUM(R.Valor),
	   Media =AVG(R.Valor)
       FROM  #Resultado AS R
	   GROUP BY R.Nome,R.CCUSTO,R.Verba
	