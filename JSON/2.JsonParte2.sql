USE AdventureWorks;

DECLARE @x NVARCHAR(MAX) = (
                               SELECT TOP 10 * FROM Sales.SalesOrderHeader FOR JSON AUTO
                           );
GO

/*Criando A Função que retorna JSON*/
CREATE FUNCTION GetSalesOrderDetails (@salesOrderId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN
    (
        SELECT SalesOrderDetail.UnitPrice,
               SalesOrderDetail.OrderQty
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderDetail.SalesOrderID = @salesOrderId
        FOR JSON AUTO
    );
END;


/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Retornando os Dados 
 
-- ==================================================================
*/

 
 /*Recuperando os valores*/
 DECLARE @x NVARCHAR(MAX)=dbo.GetSalesOrderDetails(43659)

 --Mostrando o resultado 
 PRINT dbo.GetSalesOrderDetails(43659)

 SELECT TOP 10
H.*,dbo.GetSalesOrderDetails(H.SalesOrderId) AS Details
FROM Sales.SalesOrderHeader H


/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Usando Detais 
 Merge parent and child data into a single table
-- ==================================================================
*/

GO

USE AdventureWorks
SELECT TOP 10
    SalesOrderId,
    OrderDate,
    (
        SELECT TOP 3
            UnitPrice,
            OrderQty
        FROM Sales.SalesOrderDetail D
        WHERE H.SalesOrderId = D.SalesOrderID
        FOR JSON AUTO
    ) AS Details
INTO SalesOrder
FROM Sales.SalesOrderHeader H



/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação:Convert JSON Data to Rows and Columns with
OPENJSON (SQL Server)
--The OPENJSON
 Use OPENJSON without an explicit schema for the output
-- ==================================================================
*/



go
DECLARE @json NVARCHAR(MAX)
SET @json='{"name":"John","surname":"Doe","age":45,"skills":["SQL","C#","MVC"]}';
SELECT *
FROM OPENJSON(@json);



/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Use OPENJSON with an explicit schema for the output
 
-- ==================================================================
*/	

GO

DECLARE @json NVARCHAR(MAX)
SET @json
    = N'[
{
"Order": {
"Number":"SO43659",
"Date":"2011-05-31T00:00:00"
},
"AccountNumber":"AW29825",
"Item": {
"Price":2024.9940,
"Quantity":1
}
},
{
"Order": {
"Number":"SO43661",
"Date":"2011-06-01T00:00:00"
},
"AccountNumber":"AW73565",
"Item": {
"Price":2024.9940,
"Quantity":3
}
}
]'
SELECT *
FROM
    OPENJSON(@json)
    WITH
    (
        Number VARCHAR(200) '$.Order.Number',
        Date DATETIME '$.Order.Date',
        Customer VARCHAR(200) '$.AccountNumber',
        Quantity INT '$.Item.Quantity'
    )

/*Passando um JSON Simples*/
SELECT *
FROM OPENJSON('{"name":"John","surname":"Doe","age":45}')


SELECT [key],value
FROM OPENJSON('["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]')

/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Insert into Table
 
-- ==================================================================
*/

DECLARE @json NVARCHAR(MAX)
    = '{
"id" : 2,
"firstName": "John",
"lastName": "Smith",
"isAlive": true,
"age": 25,
"dateOfBirth": "2015-03-25T12:00:00",
"spouse": null
}';
INSERT INTO Person.Person
SELECT *
FROM
    OPENJSON(@json)
    WITH
    (
        id INT,
        firstName NVARCHAR(50),
        lastName NVARCHAR(50),
        isAlive BIT,
        age INT,
        dateOfBirth DATETIME2,
        spouse NVARCHAR(50)
    )

/*Validação de dados com JSON*/
DECLARE @jsonInfo NVARCHAR(MAX)
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
}'

SELECT ISJSON(@jsonInfo) 



DECLARE @town VARCHAR(30) ;

SET @town=JSON_VALUE(@jsonInfo,'$.info.address.town');

SELECT @town;


GO


/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Extraindo Dados de um valor JSON_QUERY
The JSON_QUERY
 
-- ==================================================================
*/

DECLARE @jsonInfo NVARCHAR(MAX)
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
}'
SELECT FirstName,LastName,
JSON_QUERY(@jsonInfo,'$.info.address') AS Address,
JSON_VALUE(@jsonInfo,'$.info.address') AS AddressValue1,
JSON_VALUE(@jsonInfo,'$.info.address.town') AS AddressValu2
FROM Person.Person
ORDER BY LastName


/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação:  Usando o JSON
 SET @info=JSON_MODIFY(@jsonInfo,"$.info.address[0].town",'London')
-- ==================================================================
*/


GO

DECLARE @jsonInfo NVARCHAR(MAX),@info VARCHAR(4000);

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
}'

SET @info=JSON_MODIFY(@jsonInfo,'$.info.address[0].town','London');

SELECT @info


GO

DECLARE @json NVARCHAR(MAX)
SET @json=N'{"person":{"info":{"name":"John", "name":"Jack"}}}'
SELECT value
FROM OPENJSON(@json,'$.person.info')


/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Lendo dados com JSON
 
-- ==================================================================
*/


USE TSQLV4
ALTER TABLE dbo.Logs ALTER COLUMN Valor NVARCHAR(4000)

SELECT L.Valor,
       JSON_QUERY(L.Valor) AS CustomerID
FROM dbo.Logs AS L


[{"categoryid":1,"categoryname":"Beverages","description":"Soft drinks, coffees, teas, beers, and ales"}]