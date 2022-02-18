--Guia JSON

--USE peopleSQLNexus

/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: 

Use the JSON_VALUE function to extract a scalar value from a JSON string.
Use JSON_QUERY to extract an object or an array from a JSON string.
Use the ISJSON function to test whether a string contains valid JSON.
Use the JSON_MODIFY function to change a value in a JSON string.
 
-- ==================================================================
*/

--use o OPENJSON

DECLARE @json NVARCHAR(MAX);
SET @json
    = N'[
{ "id" : 2,"info": { "name": "John", "surname": "Smith" }, "age": 25 },
{ "id" : 5,"info": { "name": "Jane", "surname": "Smith" }, "dob": "2005-11-04T12:00:00" }
]';
SELECT *
FROM
    OPENJSON(@json)
    WITH
    (
        id INT 'strict $.id',
        firstName NVARCHAR(50) '$.info.name',
        lastName NVARCHAR(50) '$.info.surname',
        age INT,
        dateOfBirth DATETIME2 '$.dob'
    );


--FOR JSON PATH


SELECT P.personId,
       P.firstname,
       P.lastname,
       P.dob,
       P.dod,
       P.sex FROM dbo.people AS P
	   WHERE P.personId ='4A3FC571-AC94-DE11-8DC6-001A80567321'
	   FOR JSON PATH

USE TSQLV4	   

/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: Fazendo Requsição da Web
 
-- ==================================================================
*/


SELECT 'http://services.odata.org/V4/Northwind/Northwind.svc/$metadata#Products(ProductID,ProductName)/$entity'
AS '@odata.context',
ProductID, P.productname as ProductName
FROM Production.Products AS P
WHERE ProductID = 1
FOR JSON AUTO

/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: executando querys com JSON
 
-- ==================================================================
*/

DECLARE @jsonVariable NVARCHAR(MAX)
SET @jsonVariable = N'[
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

SELECT * FROM OPENJSON(@jsonVariable) AS OJ


/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: Isert Relational data from JSON Value
 
-- ==================================================================
*/

INSERT INTO SalesReport
SELECT SalesOrderJsonData.*
FROM
    OPENJSON(@jsonVariable, N'$.Orders.OrdersArray')
    WITH
    (
        Number VARCHAR(200) N'$.Order.Number',
        Date DATETIME N'$.Order.Date',
        Customer VARCHAR(200) N'$.AccountNumber',
        Quantity INT N'$.Item.Quantity'
    ) AS SalesOrderJsonData;