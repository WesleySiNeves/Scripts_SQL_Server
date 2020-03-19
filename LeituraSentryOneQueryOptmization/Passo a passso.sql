


/* ==================================================================
--Data: 16/08/2018 
--Autor :Wesley Neves
--Observação: Demo Sql Tunning Leitura livro  SQL sentry one
 
-- ==================================================================
*/

/*1) cria a tabela para a demo*/
DROP TABLE IF EXISTS  dbo.test

CREATE TABLE test
(
 data INT NOT NULL
  
)
CREATE CLUSTERED INDEX ixtest ON dbo.test(data)



/*2) insere 10 milhoes de registros*/

/* ==================================================================
--Data: 20/08/2018 
--Autor :Wesley Neves
--Observação: Veja o custo do order by causado pelo requsição de odenação do indice cluester
 
-- ==================================================================
*/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

INSERT INTO dbo.test WITH(TABLOCKX)

SELECT TOP 1000000
    (ROW_NUMBER() OVER (ORDER BY (SELECT 0)) % 1000)
FROM master.sys.syscolumns AS C1
    CROSS JOIN master.sys.syscolumns AS C2
    CROSS JOIN master.sys.syscolumns AS C3
	OPTION(MAXDOP 1)



TRUNCATE TABLE dbo.test

/*agora vamos sinalizar para o otmizador
 Dispensar a ordenação 
 	QUERYTRACEON 8795  Isso define a propriedade Classificar Pedido DML como false, portanto, 
	não é mais necessário que as linhas cheguem à Inserção
	 de Índice em Cluster na ordem de chave em cluster
*/ 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

INSERT INTO dbo.test WITH(TABLOCKX)

SELECT TOP 10000000
    (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)))
FROM master.sys.syscolumns AS C1
    CROSS JOIN master.sys.syscolumns AS C2
    CROSS JOIN master.sys.syscolumns AS C3
	OPTION(MAXDOP 1 ,QUERYTRACEON 8795)
	 

/* ==================================================================
--Data: 20/08/2018 
--Autor :Wesley Neves
--Observação: Encontrando os valores distintos

Agora temos os dados de amostra criados, podemos voltar nossa atenção para escrever uma consulta para encontrar os valores distintos na tabela.
 Uma maneira natural de expressar esse requisito no T-SQL é a seguinte
 
-- ==================================================================
*/
SELECT DISTINCT T.data FROM dbo.test AS T
WITH(TABLOCK)
OPTION(MAXDOP 1)

/*Podemos  retirar o MAXDOP 1 , assim teremos uma query paralela
OU USARMOS O  QUERYTRACEON  8649 QUE HABILITA PLANO DE EXECUÇÃO PARALELO*/

SELECT DISTINCT T.data FROM dbo.test AS T
WITH(TABLOCK)
OPTION(QUERYTRACEON  8649)


/*
Os planos de consulta mostrados acima leem todos os valores da tabela base e os processam por meio de
 um Stream Aggregate. Pensando na tarefa como um todo, 
 parece ineficiente verificar todas as 10 milhões de linhas quando
 sabemos que há relativamente poucos valores distintos.

Uma estratégia melhor pode ser encontrar o único valor mais baixo na tabela,
 depois encontrar o próximo mais alto e assim por diante até ficar sem valores. Crucialmente,
 essa abordagem se presta à procura de singletons no índice, em vez de examinar cada linha.

Podemos implementar essa ideia em uma única consulta usando um CTE recursivo,
em que a parte da âncora localiza o valor distinto mais baixo e, em seguida, a
 parte recursiva localiza o próximo valor distinto e assim por diante.

  Uma primeira tentativa de escrever esta consulta é:
*/


;WITH RecursiveCTE AS (

--Ancora
SELECT MIN(T.data) data FROM dbo.test AS T
UNION ALL
SELECT MIN(T.data) FROM dbo.test AS T
JOIN RecursiveCTE  AS R
ON R.data < t.data 

)
SELECT * FROM RecursiveCTE R

/*Uma pequena modificação*/


;WITH RecursiveCTE AS (

--Ancora
SELECT  TOP 1 (T.data) data FROM dbo.test AS T
ORDER BY data
UNION ALL
--Recursive
SELECT  TOP 1 (T.data) data
 FROM dbo.test AS T
JOIN RecursiveCTE  AS R
ON R.data < t.data 
ORDER BY T.data

)
SELECT R.data
	 FROM RecursiveCTE R
	 OPTION(MAXRECURSION 0)


 /*
Acontece que podemos contornar essas restrições reescrevendo a parte recursiva para numerar as 
linhas candidatas na ordem requerida e, em seguida, filtrar
 para a linha que é numerada como 'uma'. Isso pode parecer um pouco tortuoso, 
 mas a lógica é exatamente a mesma
 */

;WITH RecursiveCTE
AS (
   --Ancora
   SELECT TOP (1)
       T.data
   FROM dbo.test AS T
   ORDER BY T.data
   UNION ALL
   SELECT R.data
   FROM
   (
       SELECT T.data,
              rn = ROW_NUMBER() OVER (ORDER BY T.data)
       FROM dbo.test AS T
           JOIN RecursiveCTE AS R
               ON R.data < T.data
   ) AS R
   WHERE R.rn = 1
   )
SELECT *
FROM RecursiveCTE
OPTION (MAXRECURSION 0);



USE AdventureWorks

SELECT P.ProductID,
       P.Name,
       TH.TransactionID,
       TH.TransactionDate
FROM Production.Product AS P
    JOIN Production.TransactionHistory AS TH
        ON P.ProductID = TH.ProductID
WHERE P.ProductID IN ( 1, 2 )
      AND TH.TransactionDate
      BETWEEN '20070901' AND '20071231';


/* ==================================================================
--Data: 20/08/2018 
--Autor :Wesley Neves
--Observação: parte 3)
O que está acontecendo 
 
-- ==================================================================
*/



/* ==================================================================
--Data: 28/08/2018 
--Autor :Wesley Neves
--Observação: Indice usado para a cobertura
 
-- ==================================================================
*/
--CREATE NONCLUSTERED INDEX [IX_Person_LastName_FirstName_MiddleName] ON [Person].[Person] ([LastName], [FirstName], [MiddleName]) ON [PRIMARY]


USE AdventureWorks
/*Veja que o plano de execução retorna 14 linhas 
a quantidade de seeks tambem */
SELECT P.FirstName,
       P.LastName
FROM Person.Person AS P
WHERE P.LastName = 'Smith'
AND P.FirstName  LIKE 'j%'
OPTION(MAXDOP 1)


SELECT P.FirstName,
       P.LastName
FROM Person.Person AS P
WHERE P.LastName LIKE 's%'
AND P.FirstName  = 'John'
OPTION(MAXDOP 1)

	

/* ==================================================================
--Data: 21/08/2018 
--Autor :Wesley Neves
--Observação: Item 4) Seek Predicate , demostração do Range Scan seek
 
-- ==================================================================
*/

/*Usando essa query simples*/
USE WideWorldImporters

/*Scan*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7


/*Scan*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7
AND YEAR(O.OrderDate) = 2013


/*Scan*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7
AND YEAR(O.OrderDate) = 2013
AND MONTH(O.OrderDate) = 4

--CREATE NONCLUSTERED INDEX ix_teste ON Sales.Orders(SalespersonPersonID,OrderDate)

/*Vamos refazer as querys apos o indice*/	  


/*Seek*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7


/*Seek*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7
AND YEAR(O.OrderDate) = 2013



/*Dando uma olhada no plano de execução no cache*/
SELECT p.dbid,
		c.bucketid,
       c.usecounts,
       c.size_in_bytes,
       p.query_plan,
	   t.text
FROM sys.dm_exec_cached_plans c
    CROSS APPLY sys.dm_exec_query_plan(c.plan_handle) p
	CROSS APPLY sys.dm_exec_sql_text(c.plan_handle) t
	WHERE t.text LIKE '%YEAR%'
	

/*Scan*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7
AND YEAR(O.OrderDate) = 2013
AND MONTH(O.OrderDate) = 4
OPTION(MAXDOP 1)

 /*Scan*/
SELECT COUNT(*) FROM Sales.Orders AS O
WHERE O.SalespersonPersonID =7
AND O.OrderDate >='20130401'
AND  O.OrderDate <'20130501'
OPTION(MAXDOP 1)



 USE AdventureWorks

 GO
CREATE PROCEDURE IndexAnaliseDemo
(
    @MinProductId INT,
    @MaxproductId INT,
    @MinSalesOrderId INT,
    @MaxSalesOrderId INT
)
AS
BEGIN

    SELECT SOD.ProductID,
           SOD.SalesOrderID,
           SOD.SalesOrderDetailID,
           SOD.CarrierTrackingNumber,
           SOD.OrderQty,
           SOD.UnitPrice
    FROM Sales.SalesOrderDetail AS SOD
    WHERE SOD.ProductID
          BETWEEN @MinProductId AND @MaxproductId
          AND SOD.SalesOrderID
          BETWEEN @MinSalesOrderId AND @MaxSalesOrderId;

END;


--Veja apenas 416 linhas retornadas
EXEC dbo.IndexAnaliseDemo @MinProductId = 707,    -- int
                          @MaxproductId = 999,    -- int
                          @MinSalesOrderId = 42659, -- int
                          @MaxSalesOrderId = 50000  -- int

