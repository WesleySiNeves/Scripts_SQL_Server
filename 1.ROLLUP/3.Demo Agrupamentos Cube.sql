
/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: 
 
-- ==================================================================
*/

--USE Demostracao;
/*
 Limitações
 uma cláusula GROUP BY que usa ROLLUP, CUBE ou GROUPING SETS, o número máximo de expressões é 32.
 O número máximo de grupos é 4096 (212).
 
*/

/* ==================================================================
sintaxe :
GROUP BY {
      column-expression  
    | ROLLUP ( <group_by_expression> [ ,...n ] )  
    | CUBE ( <group_by_expression> [ ,...n ] )  
    | GROUPING SETS ( <grouping_set> [ ,...n ]  )  
    | () --calculates the grand total 
} [ ,...n ] 
 
-- ==================================================================
*/

/*1) Group by Simples*/


SELECT  B.NomeBanco,
        L.Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY B.NomeBanco,
         L.Data
ORDER BY L.Data,B.NomeBanco

/*A pergunta e como inserir uma linha total fazendo o totalizador por nome do banco e por data */

/*
GROUP BY CUBE ( )
GROUP BY CUBE cria grupos para todas as combinações de colunas possíveis. GROUP BY CUBE (a, b) 
os resultados têm grupos de valores exclusivos de (a, b), (NULL, b), (a, NULL) e (NULL, NULL).
*/
SELECT ISNULL(B.NomeBanco, 'Total'),
       ISNULL(CONVERT(VARCHAR(12), L.Data, 101), 'Sub-Total') AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY CUBE(B.NomeBanco, L.Data);


/*Exemplo 2*/
SELECT ISNULL(B.NomeBanco, 'Total'),
       ISNULL(C.Nome, 'Sub-Total'),
       ISNULL(CONVERT(VARCHAR(12), L.Data, 101), 'Sub-Total por Data') AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
GROUP BY CUBE(B.NomeBanco, C.Nome, L.Data);



/*Exemplo 3 usando somente GROUP BY*/


SELECT 
       C.companyname,
       C.country,
       C.region,
       C.city,
	   O.orderdate,
	   COUNT(O.orderid) quantidadeVenda,
        SUM(O.freight) TotalPagoFrete
FROM TSQLV4.Sales.Customers AS C
JOIN TSQLV4.Sales.Orders AS O ON C.custid = O.custid
WHERE C.companyname ='Customer EEALV'
GROUP BY C.companyname,
         C.country,
         C.region,
         C.city,
         O.orderdate
ORDER BY C.companyname,O.orderdate


/*Usando  o CUBE*/

/*
GROUP BY CUBE ( )
GROUP BY CUBE cria grupos para todas as combinações de colunas possíveis. GROUP BY CUBE (a, b) 
os resultados têm grupos de valores exclusivos de (a, b), (NULL, b), (a, NULL) e (NULL, NULL).
*/
SELECT 
       ISNULL(C.companyname,'Total'),
       ISNULL(C.country,'Sub-Total'),
       ISNULL(C.region,'Sub-Total'),
       ISNULL(C.city,'Sub-Total'),
	   ISNULL(CONVERT(VARCHAR(20), O.orderdate, 101), 'Sub-Total por Data') AS Data,
	   COUNT(O.orderid) quantidadeVenda,
        SUM(O.freight) TotalPagoFrete
FROM TSQLV4.Sales.Customers AS C
JOIN TSQLV4.Sales.Orders AS O ON C.custid = O.custid
WHERE C.companyname ='Customer EEALV'
GROUP BY CUBE(C.companyname, 
		  C.country,
         C.region,
         C.city,
         O.orderdate)
--ORDER BY C.companyname,O.orderdate






/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: GROUP BY ROLLUP
Cria um grupo para cada combinação de expressões de coluna. Além disso, ele "acumula" os resultados em subtotais e totais gerais. 
Para isso, ele vai da direita para a esquerda, diminuindo o número de expressões de coluna sobre as quais ele cria grupos e agregações.
A ordem da coluna afeta a saída de ROLLUP e pode afetar o número de linhas no conjunto de resultados.

 Por exemplo, GROUP BY ROLLUP (col1, col2, col3, col4) cria grupos para cada combinação de expressões de coluna nas listas a seguir.


col1, col2, col3, col4
col1, col2, col3, NULL
col1, col2, NULL, NULL
col1, NULL, NULL, NULL
NULL, NULL, NULL, NULL – esse é o total geral


-- ==================================================================
*/

/*Exemplo 1) query Simples*/
SELECT B.NomeBanco,
       L.Data AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY B.NomeBanco,
         L.Data
		 ORDER BY Data ,B.NomeBanco


/*Usando Rollup*/
SELECT B.NomeBanco AS Banco, 
		C.Nome AS Cliente ,
        ISNULL(CONVERT(VARCHAR(20), L.Data, 101), 'Sub-Total') AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Jóse Diz'
GROUP BY ROLLUP(B.NomeBanco,C.Nome,L.Data)






/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: GROUP BY GROUPING SETS ( )
 A opção de GROUPING SETS oferece a capacidade de combinar várias cláusulas GROUP BY em uma única cláusula GROUP BY. 
 Os resultados são o equivalente de UNION ALL dos grupos especificados.
-- ==================================================================
*/


SELECT ISNULL(B.NomeBanco, 'Total'),
       ISNULL(CONVERT(VARCHAR(12), L.Data, 101), 'Sub-Total') AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY GROUPING SETS((B.NomeBanco), (L.Data), (B.NomeBanco, L.Data));



/*Gerando um Grand Total */
SELECT ISNULL(B.NomeBanco, 'Total'),
       ISNULL(CONVERT(VARCHAR(12), L.Data, 101), 'Sub-Total') AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY GROUPING SETS((B.NomeBanco), (L.Data), (B.NomeBanco, L.Data), ());


/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: GROUPING (Transact-SQL)
ndica se uma expressão de coluna especificada em uma lista GROUP BY é agregada ou não. GROUPING 
retorna 1 para agregada ou 0 para não agregada no conjunto
 de resultados. GROUPING pode ser usado apenas na lista SELECT <select>, 
nas cláusulas HAVING e ORDER BY, quando GROUP BY é especificado.
 
-- ==================================================================
*/


SELECT B.NomeBanco,
       L.Data AS Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
	   GROUPING(NomeBanco) AS 'Grouping NomeBanco',
       SUM(L.Valor) AS TotalLancamento,
	   GROUPING(L.DATA) AS 'Grouping DATA'
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY  ROLLUP(NomeBanco, L.DATA)
		


/* Usndo GROUPING_ID (Transact-SQL)
É uma função que calcula o nível de agrupamento. GROUPING_ID pode ser usado apenas na lista SELECT <select> e nas cláusulas
HAVING ou ORDER BY quando GROUP BY é especificado.
ROUPING_ID (<column_expression> [ ,...n ]) insere o equivalente ao retorno de GROUPING (<column_expression>) 
para cada coluna em sua lista de colunas em cada linha de saída como uma cadeia de caracteres com números um e zero.
GROUPING_ID interpreta a cadeia de caracteres 
como um número base 2 e retorna o inteiro equivalente. Por exemplo, considere a seguinte instrução: 
 */


 /*A. Usando GROUPING_ID para identificar níveis de agrupamento*/

 USE AdventureWorks

 SELECT D.Name  
    ,CASE   
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 0 THEN E.JobTitle  
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 1 THEN N'Total: ' + D.Name   
    WHEN GROUPING_ID(D.Name, E.JobTitle) = 3 THEN N'Company Total:'  
        ELSE N'Unknown'  
    END AS N'Job Title'  
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'  
FROM HumanResources.Employee E  
    INNER JOIN HumanResources.EmployeeDepartmentHistory DH  
        ON E.BusinessEntityID = DH.BusinessEntityID  
    INNER JOIN HumanResources.Department D  
        ON D.DepartmentID = DH.DepartmentID       
WHERE DH.EndDate IS NULL  
    AND D.DepartmentID IN (12,14)  
GROUP BY ROLLUP(D.Name, E.JobTitle);  



/*B. Usando GROUPING_ID para filtrar um conjunto de resultados*/


SELECT D.Name  
    ,E.JobTitle  
    ,GROUPING_ID(D.Name, E.JobTitle) AS 'Grouping Level'  
    ,COUNT(E.BusinessEntityID) AS N'Employee Count'  
FROM HumanResources.Employee AS E  
    INNER JOIN HumanResources.EmployeeDepartmentHistory AS DH  
        ON E.BusinessEntityID = DH.BusinessEntityID  
    INNER JOIN HumanResources.Department AS D  
        ON D.DepartmentID = DH.DepartmentID       
WHERE DH.EndDate IS NULL  
    AND D.DepartmentID IN (12,14)  
GROUP BY ROLLUP(D.Name, E.JobTitle)  
--HAVING GROUPING_ID(D.Name, E.JobTitle) = 0; --All titles  
--HAVING GROUPING_ID(D.Name, E.JobTitle) = 1; --Group by Name;


USE Demostracao

SELECT B.NomeBanco,
       L.Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento,
       GROUPING_ID(B.NomeBanco) AS 'GROUPING_ID NomeBanco',
       GROUPING_ID(L.Data) AS 'GROUPING_ID Data',
       GROUPING_ID(B.NomeBanco, L.Data) AS 'GROUPING_ID Data'
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY CUBE(B.NomeBanco, L.Data)


/*Usando o ROLLUP*/

SELECT B.NomeBanco,
       L.Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento,
       GROUPING_ID(B.NomeBanco) AS 'GROUPING_ID NomeBanco',
       GROUPING_ID(L.Data) AS 'GROUPING_ID Data',
       GROUPING_ID(B.NomeBanco, L.Data) AS 'GROUPING_ID Data'
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY ROLLUP(B.NomeBanco, L.Data)



SELECT B.NomeBanco,
       L.Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento,
       GROUPING(B.NomeBanco) AS 'GROUPING_ID NomeBanco',
       GROUPING(L.Data) AS 'GROUPING_ID Data'
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY ROLLUP(B.NomeBanco, L.Data)



/*
Indica se uma expressão de coluna especificada em uma lista GROUP BY é agregada ou não.
GROUPING retorna 1 para agregada ou 0 para não agregada no conjunto de resultados.
GROUPING pode ser usado apenas na lista SELECT <select>, nas cláusulas HAVING e ORDER BY, 
quando GROUP BY é especificado.
*/
SELECT B.NomeBanco,
       L.Data,
       COUNT(L.NumeroLancamento) AS QuantidadeLancamentos,
       SUM(L.Valor) AS TotalLancamento,
       GROUPING(B.NomeBanco) AS 'GROUPING NomeBanco',
       GROUPING(L.Data) AS 'GROUPING_ID Data'
FROM dbo.Bancos AS B
    JOIN dbo.Lancamentos AS L
        ON B.idBanco = L.idBanco
    JOIN dbo.Clientes AS C
        ON L.IdCliente = C.IdCliente
WHERE C.Nome = 'Wesley Neves'
GROUP BY CUBE(B.NomeBanco, L.Data)




