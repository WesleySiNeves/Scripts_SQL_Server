
/* ==================================================================
--Data: 07/06/2018 
--Observação: A primeira opção simples para gerar objetos JSON a partir dos resultados da consulta T-SQL é o FOR JSON
 
-- ==================================================================
*/

/*
Caso haja texto JSON armazenado em tabelas de banco de dados, é possível ler ou
 modificar valores no texto JSON usando as seguintes funções internas:
*/


--1) ISJSON 

DECLARE @Json VARCHAR(4000) = (
                                  SELECT TOP 1 * FROM Sales.Customers AS C FOR JSON AUTO
                              );


/*Exemplo 1*/
IF(ISJSON(@Json) > 0)
BEGIN
		SELECT 'Is JSON'
END

/*Exemplo 2

SELECT id, json_col FROM tab1 WHERE ISJSON(json_col) > 0  
*/


DECLARE @jsonInfo NVARCHAR(MAX);
SET @jsonInfo
    = N'{  
     "info":{    
       "type":1,  
       "address":{    
         "town":"Bristol",  
         "county":"Avon",  
         "country":"England"  
       },  
       "tags":["Sport", "Water polo"]  
    },  
    "type":"Basic"  
 }';

SELECT JSON_VALUE(@jsonInfo, '$.info.address.county');
SELECT JSON_VALUE(@jsonInfo, '$.info.address.country');
SELECT JSON_VALUE(@jsonInfo, '$.info.type');

GO

/*Exemplo de filtro (Inicio)*/

SELECT FirstName, LastName,
 JSON_VALUE(jsonInfo,'$.info.address[0].town') AS Town
FROM Person.Person
WHERE JSON_VALUE(jsonInfo,'$.info.address.state') LIKE 'US%'
ORDER BY JSON_VALUE(jsonInfo,'$.info.address[0].town')


/*O exemplo a seguir extrai o valor da propriedade JSON*/
GO


DECLARE @town NVARCHAR(32)

DECLARE @jsonInfo NVARCHAR(MAX);

SET @jsonInfo
    = N'{  
     "info":{    
       "type":1,  
       "address":{    
         "town":"Bristol",  
         "county":"Avon",  
         "country":"England"  
       },  
       "tags":["Sport", "Water polo"]  
    },  
    "type":"Basic"  
 }';


SET @town=JSON_VALUE(@jsonInfo,'$.info.address.town')

SELECT @town;



/* ==================================================================
--Data: 27/07/2018 
--Autor :Wesley Neves
--Observação: Criando Campos Calculados que recebem Valor JSON
 
-- ==================================================================
*/

CREATE TABLE dbo.Store
 (
  StoreID INT IDENTITY(1,1) NOT NULL,
  Address VARCHAR(500),
  jsonContent NVARCHAR(8000),
  Longitude AS JSON_VALUE(jsonContent, '$.address[0].longitude'),
  Latitude AS JSON_VALUE(jsonContent, '$.address[0].latitude')
 );



SELECT Customer.custid,
       Customer.companyname,
       [Order].orderid,
       [Order].orderdate
FROM Sales.Customers AS Customer
    INNER JOIN Sales.Orders AS [Order]
        ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
      AND [Order].orderid % 2 = 0
ORDER BY Customer.custid,
         [Order].orderid
FOR JSON AUTO;


/* ==================================================================
--Data: 07/06/2018 
--Observação:  Uso do  JSON PATH;
Você tem muito mais influência sobre o formato do JSON retornado com o FOR JSON
Cláusula PATH. No modo PATH, 
 
-- ==================================================================
*/

SELECT TOP (2)
    Customers.custid,
    Customers.companyname,
    Customers.contactname
FROM Sales.Customers
ORDER BY Customers.custid
FOR JSON PATH;



/* ==================================================================
--Data: 07/06/2018 
--Observação: Usando com JOINS
 
-- ==================================================================
*/
SELECT c.custid AS [Customer.Id],
       c.companyname AS [Customer.Name],
       o.orderid AS [Order.Id],
       o.orderdate AS [Order.Date]
FROM Sales.Customers AS c
    INNER JOIN Sales.Orders AS o
        ON c.custid = o.custid
WHERE c.custid = 1
      AND o.orderid = 10692
ORDER BY c.custid,
         o.orderid
FOR JSON PATH;



/* ==================================================================
--Data: 07/06/2018 
--Observação: Usndo Clausulas WITHOUT_ARRAY_WRAPPER
 
-- ==================================================================
*/
SELECT c.custid AS [Customer.Id],
       c.companyname AS [Customer.Name],
       o.orderid AS [Customer.Order.Id],
       o.orderdate AS [Customer.Order.Date]
FROM Sales.Customers AS c
    INNER JOIN Sales.Orders AS o
        ON c.custid = o.custid
WHERE c.custid = 1
      AND o.orderid = 10692
ORDER BY c.custid,
         o.orderid
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;

/*Veja a diferença*/

SELECT c.custid AS [Customer.Id],
       c.companyname AS [Customer.Name],
       o.orderid AS [Customer.Order.Id],
       o.orderdate AS [Customer.Order.Date]
FROM Sales.Customers AS c
    INNER JOIN Sales.Orders AS o
        ON c.custid = o.custid
WHERE c.custid = 1
      AND o.orderid = 10692
ORDER BY c.custid,
         o.orderid
FOR JSON PATH;


/* ==================================================================
--Data: 07/06/2018 
--Observação: Usando a clausula FOR JSON PATH ROOT
 
-- ==================================================================
*/
SELECT c.custid AS [Customer.Id],
       c.companyname AS [Customer.Name],
       o.orderid AS [Customer.Order.Id],
       o.orderdate AS [Customer.Order.Date]
FROM Sales.Customers AS c
    INNER JOIN Sales.Orders AS o
        ON c.custid = o.custid
WHERE c.custid = 1
      AND o.orderid = 10692
ORDER BY c.custid,
         o.orderid
FOR JSON PATH, ROOT('Customer 1');


/* ==================================================================
--Data: 07/06/2018  
--Observação:  Usando todas as clausulas  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES;
 
-- ==================================================================
*/
SELECT c.custid AS [Customer.Id],
       c.companyname AS [Customer.Name],
       o.orderid AS [Customer.Order.Id],
       o.orderdate AS [Customer.Order.Date],
       NULL AS [Customer.Order.Delivery]
FROM Sales.Customers AS c
    INNER JOIN Sales.Orders AS o
        ON c.custid = o.custid
WHERE c.custid = 1
      AND o.orderid = 10692
ORDER BY c.custid,
         o.orderid
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES;