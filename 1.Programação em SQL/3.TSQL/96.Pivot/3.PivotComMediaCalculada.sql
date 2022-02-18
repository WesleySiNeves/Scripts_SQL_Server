--CREATE TABLE Exemplo (
--  CON_DssNome VARCHAR(MAX),
--  CCUSTO VARCHAR(MAX),
--  VERBA VARCHAR(MAX),
--  Mes INT ,
--  Valor DECIMAL(18,2)
--)

IF ( OBJECT_ID('TEMPDB..#Dados') IS NOT NULL )
    DROP TABLE #Dados;	

CREATE TABLE #Dados
    (
      Nome VARCHAR(MAX) ,
      CCUSTO VARCHAR(MAX) ,
      Verba VARCHAR(MAX) ,
      Mes VARCHAR(MAX),
      Valor NUMERIC(18, 2) NOT NULL 
     
    );		

IF ( OBJECT_ID('TEMPDB..#Resultado') IS NOT NULL )
    DROP TABLE #Resultado;	

CREATE TABLE #Resultado
    (
      Nome VARCHAR(MAX) ,
      CCUSTO VARCHAR(MAX) ,
      Verba VARCHAR(MAX) ,
      Janeiro DECIMAL(18,2),
      Fevereiro DECIMAL(18,2),
	  Marco DECIMAL(18,2),
	  Abril DECIMAL(18,2),
	  Maio DECIMAL(18,2),
	  Junho DECIMAL(18,2),
	  Julho DECIMAL(18,2),
	  Agosto DECIMAL(18,2),
	  Setembro DECIMAL(18,2),
	  Outubro DECIMAL(18,2),
	  Novembro DECIMAL(18,2),
	  Dezembro DECIMAL(18,2),
	  Total DECIMAL(18,2),
	  MesesNaoPagos INT
     
    );		


INSERT INTO #Dados
VALUES  ( 'JOAO' , 'Separa��o' , 'Sal M�s' ,1 ,3028.67 ),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,2 ,4543.00),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,3 ,4543.00),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,4 ,4543.00),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,5 ,4543.00),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,6 ,4088.70),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,7 ,1968.63),	
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,8 ,4543.00),
		( 'JOAO' , 'Separa��o' , 'Sal M�s' ,9 ,4981.00),
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


--SELECT D.Nome ,
--       D.CCUSTO ,
--       D.Verba ,
--       D.Mes ,
--       SUM(D.Valor) FROM #Dados AS D
--	   WHERE D.Nome ='JOAO'
--	   GROUP BY D.Nome ,D.CCUSTO,D.Verba,D.Mes
--	   ORDER BY D.Mes

INSERT INTO #Resultado
        ( Nome ,
          CCUSTO ,
          Verba ,
          Janeiro ,
          Fevereiro ,
          Marco ,
          Abril ,
          Maio ,
          Junho ,
          Julho ,
          Agosto ,
          Setembro ,
          Outubro ,
          Novembro ,
          Dezembro ,
          Total ,
          MesesNaoPagos
        )

       
SELECT R.Nome ,
       R.CCUSTO ,
       R.Verba ,
       [Janeiro] = SUM(CASE WHEN R.Mes = 1 THEN  R.Valor END),
	   [Fevereiro] = SUM(CASE WHEN R.Mes = 2 THEN R.Valor END),
	   [Mar�o] = SUM(CASE WHEN R.Mes = 3 THEN R.Valor END),
	   [Abril] = SUM(CASE WHEN R.Mes = 4 THEN R.Valor END),
	   [Maio] = SUM(CASE WHEN R.Mes = 5 THEN R.Valor END),
	   [Junho] = SUM(CASE WHEN R.Mes = 6 THEN R.Valor END),
	   [Julho] = SUM(CASE WHEN R.Mes = 7 THEN R.Valor END),
	   [Agosto] = SUM(CASE WHEN R.Mes = 8 THEN R.Valor END),
	   [Setembro] = SUM(CASE WHEN R.Mes = 9 THEN R.Valor END),
	   [Outubro] = SUM(CASE WHEN R.Mes = 10 THEN R.Valor END),
	   [Novembro] = SUM(CASE WHEN R.Mes = 11 THEN R.Valor END),
	   [Dezembro] = SUM(CASE WHEN R.Mes = 12 THEN R.Valor END),
	    Total = SUM(R.Valor),
	   MesesNaoPagos =  COUNT(CASE WHEN R.Mes IN(1,2,3,4,5,6,7,8,9,10,11,12) AND R.Valor =0  THEN 1   END)
       FROM  #Dados AS R
	   GROUP BY R.Nome,R.CCUSTO,R.Verba;
	   

SELECT R.Nome ,
       R.CCUSTO ,
       R.Verba ,
       R.Janeiro ,
       R.Fevereiro ,
       R.Marco ,
       R.Abril ,
       R.Maio ,
       R.Junho ,
       R.Julho ,
       R.Agosto ,
       R.Setembro ,
       R.Outubro ,
       R.Novembro ,
       R.Dezembro ,
       R.Total ,
	   R.MesesNaoPagos ,
	   Media = ROUND(R.Total / ((12-R.MesesNaoPagos)),2)
       FROM #Resultado AS R