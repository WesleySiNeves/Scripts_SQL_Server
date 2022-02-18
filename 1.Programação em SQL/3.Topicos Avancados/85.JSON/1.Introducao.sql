
USE TSQLV4
/* ==================================================================
--Data: 24/07/2018 
--Autor :Wesley Neves
--Observação: 
JSON também é usado para armazenar dados não estruturados em arquivos de log ou em bancos de dados NoSQL,
 como o Microsoft Azure Cosmos DB.
-- ==================================================================
*/

/*Notação

[{
"name": "John",
"skills": ["SQL", "C#", "Azure"]
}, {
"name": "Jane",
"surname": "Doe"
}]

*/


/*
JSON é uma ponte entre o NoSQL e mundos relacionais
*/

/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Para o Sql server 2016 usamos algumas funções

Use the JSON_VALUE function to extract a scalar value from a JSON string.
Use JSON_QUERY to extract an object or an array from a JSON string.
Use the ISJSON function to test whether a string contains valid JSON.
Use the JSON_MODIFY function to change a value in a JSON string.
 
-- ==================================================================
*/


/*Formatação simples*/

SELECT TOP 5
    C.custid,
    C.companyname,
    C.contactname,
    C.contacttitle
FROM Sales.Customers AS C
FOR JSON AUTO

/*Usando JSON PATH */

SELECT TOP 5
    C.custid,
    C.companyname,
    C.contactname,
    C.contacttitle
FROM Sales.Customers AS C
FOR JSON PATH

/*Usando JSON PATH  com formatação da saida*/
SELECT TOP 5
    C.custid,
    C.companyname,
    C.contactname,
    C.contacttitle,
    C.address AS 'Location.address',
    C.city AS 'Location.city',
    C.region AS 'Location.region',
    C.postalcode AS 'Location.postalcode',
    C.country AS 'Location.country',
    C.phone,
    C.fax
FROM Sales.Customers AS C
FOR JSON PATH



/*Usando JSON PATH  com formatação da saida*/
SELECT TOP 5
    C.custid,
    C.companyname,
    C.contactname,
    C.contacttitle,
    C.address AS 'Location.address',
    C.city AS 'Location.city',
    C.region AS 'Location.region',
    C.postalcode AS 'Location.postalcode',
    C.country AS 'Location.country',
    C.phone,
    C.fax
FROM Sales.Customers AS C
FOR JSON PATH


/*Usando JSON PATH  com formatação da saida retirando os colchetes*/
SELECT TOP 5
    C.custid,
    C.companyname,
    C.contactname,
    C.contacttitle,
    C.address AS 'Location.address',
    C.city AS 'Location.city',
    C.region AS 'Location.region',
    C.postalcode AS 'Location.postalcode',
    C.country AS 'Location.country',
    C.phone,
    C.fax
FROM Sales.Customers AS C
FOR JSON PATH,WITHOUT_ARRAY_WRAPPER



/*Usando JSON PATH  com formatação da saida retirando os colchetes e incluindo valores nullos*/
SELECT TOP 5
    C.custid,
    C.companyname,
    C.contactname,
    C.contacttitle,
    C.address AS 'Location.address',
    C.city AS 'Location.city',
    C.region AS 'Location.region',
    C.postalcode AS 'Location.postalcode',
    C.country AS 'Location.country',
    C.phone,
    C.fax
FROM Sales.Customers AS C
FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES

/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Criando campos JSON com subquerys
 
-- ==================================================================
*/

/*Ordens para cada cliente*/
SELECT C.custid,
       C.companyname,
       C.city,
       (
           SELECT ord.orderid,
                  ord.orderdate,
                  ord.freight
           FROM Sales.Orders AS ord
           WHERE ord.custid = C.custid
           FOR JSON PATH
       ) AS Orde
FROM Sales.Customers AS C;


/*Ordens para cada cliente*/
SELECT C.custid,
       C.companyname,
       C.city,
       (
           SELECT ord.orderid,
                  ord.orderdate,
                  ord.freight
           FROM Sales.Orders AS ord
           WHERE ord.custid = C.custid
           FOR JSON PATH
       ) AS Orde
FROM Sales.Customers AS C
FOR JSON PATH





--Alterando Valores em JSON (JSON_MODIFY)
DECLARE @json NVARCHAR(MAX);
SET @json = '{"info":{"address":[{"town":"Belgrade"},{"town":"Paris"},{"town":"Madrid"}]}}';
SET @json = JSON_MODIFY(@json, '$.info.address[1].town', 'London');
SET @json = JSON_MODIFY(@json, '$.info.address[0].town', 'Brasilia');
SET @json = JSON_MODIFY(@json, '$.info.address[2].town', 'São Paulo');
SET @json = JSON_MODIFY(@json, '$.info.address[3].town', 'Rio de Janeiro');
SELECT modifiedJson = @json;



/* ==================================================================
--Data: 24/07/2018 
--Autor :Wesley Neves
--Observação: Fazendo Consultas em JSON
 
-- ==================================================================
*/

GO

--Usando OPENJSON
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
        id INT '$.id',
        firstName NVARCHAR(50) '$.info.name',
        lastName NVARCHAR(50) '$.info.surname',
        age INT,
        dateOfBirth DATETIME2 '$.dob'
    );


GO
DECLARE @json NVARCHAR(MAX);
SET @json
    = N'[  
       { "id" : 2,"info": { "name": "John", "surname": "Smith" }, "age": 25 },  
       { "id" : 5,"info": { "name": "Jane", "surname": "Smith", "skills": ["SQL", "C#", "Azure"] }, "dob": "2005-11-04T12:00:00" }  
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
        dateOfBirth DATETIME2 '$.dob',
        skills NVARCHAR(MAX) '$.skills' AS JSON
    )
    OUTER APPLY
    OPENJSON(a.skills)
    WITH
    (
        skill NVARCHAR(8) '$'
    ) AS b;


GO



 
 

/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Usando clausulas T-SQL
 
-- ==================================================================
*/

SELECT L.idlog,
       L.Entidade,
       L.IdEntidade,
       L.Acao,
       L.Valor,
	   'Objeto',
       OJ.categoryid,
       OJ.categoryname,
       OJ.description
FROM dbo.Logs AS L
    CROSS APPLY
    OPENJSON(L.Valor)
    WITH
    (
        categoryid VARCHAR(200) N'$.categoryid',
        categoryname VARCHAR(200) N'$.categoryname',
        description VARCHAR(200) N'$.description'
    ) AS OJ
	--WHERE JSON_VALUE(L.Valor, '$.categoryid') = 1
--ORDER BY JSON_VALUE(l.Valor, '$.categoryid');




/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Insert into Relational data from value JSON
 
-- ==================================================================
*/
GO
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



INSERT INTO SalesReport  
SELECT SalesOrderJsonData.*  
FROM OPENJSON (@jsonVariable, N'$.Orders.OrdersArray')  
           WITH (  
              Number   varchar(200) N'$.Order.Number',   
              Date     datetime     N'$.Order.Date',  
              Customer varchar(200) N'$.AccountNumber',   
              Quantity int          N'$.Item.Quantity'  
           )  
  AS SalesOrderJsonData;  




  /* ==================================================================
  --Data: 13/08/2018 
  --Autor :Wesley Neves
  --Observação: Cria a tabela de Logs
   
  -- ==================================================================
  */

  GO
  
CREATE TABLE Logs
(
 idlog UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT(NEWSEQUENTIALID()),
 Entidade VARCHAR(200),
 IdEntidade  UNIQUEIDENTIFIER,
 Acao CHAR(1) CHECK(Acao IN ('N','U','D')),
 Valor VARCHAR(4000)
)


/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: transforma em JSON
 
-- ==================================================================
*/


--TRUNCATE TABLE dbo.Logs
DECLARE @value VARCHAR(4000) = (
                                   SELECT *
                                   FROM Production.Categories AS C
                                   WHERE C.categoryid = 1
                                   FOR JSON PATH, INCLUDE_NULL_VALUES
                               );
/*
INSERT INTO dbo.Logs
(
    idlog,
    Entidade,
    IdEntidade,
    Acao,
    Valor
)
VALUES
(   DEFAULT, -- idlog - uniqueidentifier
    'Production.Categories',   -- Entidade - varchar(200)
    NEWID(), -- IdEntidade - uniqueidentifier
    'N',   -- Acao - char(1)
    @value    -- Valor - varchar(4000)
)
*/

DECLARE @valuej VARCHAR(4000) =(SELECT  OJ.Value FROM OPENJSON(@value) AS OJ)

SELECT * FROM OPENJSON(@valuej)

SELECT L.idlog,
       L.Entidade,
       L.IdEntidade,
       L.Acao,
       L.Valor,
	   JSON_VALUE(L.Valor,'$.categoryid')	 FROM dbo.Logs AS L
	   WHERE ISJSON(L.Valor) >0
	  -- AND JSON_VALUE(L.Valor,'$.Production.Categories.categoryid') =1
	   

/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: Format Query Results as JSON with FOR JSON (SQL Server)
 
-- ==================================================================
*/
	   
SELECT C.categoryid AS 'Categories.categoryid',
       C.categoryname AS 'Categories.categoryname',
       C.description  AS  'Categories.description' ,
	   p.productname AS  'Products.productname' ,
	   p.unitprice AS  'Products.unitprice' 
	   FROM Production.Categories AS C
JOIN Production.Products AS P ON C.categoryid = P.categoryid
WHERE C.categoryid =2
FOR JSON PATH ,ROOT('Registros')



SELECT * FROM Sales.Customers AS C
FOR JSON AUTO




DECLARE @Jsonvariable  NVARCHAR(4000) = (SELECT L.Valor FROM dbo.Logs AS L
										WHERE L.IdEntidade ='70B977DD-F9D6-40C5-9543-8D79A6C6D07D')

						

SELECT * FROM OPENJSON(@Jsonvariable);






DECLARE @json NVARCHAR(4000) = N'{
 "UserID" : 1,
 "UserName": "AaronBertrand",
 "Active": true,
 "SignupDate": "2015-10-01"
 }';

 SELECT * FROM OPENJSON(@json);

 

 DECLARE @Jsonvariable2 NVARCHAR(4000) = N'[{
 "UserID" : 1,
 "UserName": "AaronBertrand",
 "Active": true,
 "SignupDate": "2015-10-01"
 },
 {
 "UserID" : 2,
 "UserName": "BobO''Neil",
 "Active": false,
 "SignupDate": "2014-12-13"
 }]';

 SELECT * FROM OPENJSON(@Jsonvariable2)
 WITH 
 (
   UserID INT, 
   UserName NVARCHAR(64),
   Active BIT,
   [Started] DATETIME '$.SignupDate' -- remap column name
 );

--ALTER DATABASE [15-implanta] SET COMPATIBILITY_LEVEL = 130





/* ==================================================================
--Data: 14/08/2018 
--Autor :Wesley Neves
--Observação: Usando JSON_VALUE
 
-- ==================================================================
*/
GO

DECLARE @json NVARCHAR(4000) = N'{
 "UserID" : 1,
 "Cars": [ 
   { "Year":2014, "Make":"Jeep",   "Model":"Grand Cherokee" },
   { "Year":2010, "Make":"Nissan", "Model":"Murano", "Options":
     [{ "AC":true,"Panoramic Roof":true }]
  ]
 }';

SELECT 
  UserID = JSON_VALUE(@json, '$.UserID'),
  Model1 = JSON_VALUE(@json, '$.Cars[0].Model'),
  Model2 = JSON_VALUE(@json, '$.Cars[1].Model'),
  Has_AC = JSON_VALUE(@json, '$.Cars[1].Options[0].AC');


  /* ==================================================================
  --Data: 14/08/2018 
  --Autor :Wesley Neves
  --Observação: Uso do ISJSON()
   
  -- ==================================================================
  */

  GO
	DECLARE @json NVARCHAR(4000)
		= N'[{
		"UserID" : 1,
		"UserName": "AaronBertrand",
		"Active": true,
		"SignupDate": "2015-10-01"
		}]';

	SELECT ISJSON(@json),  -- returns 1
			ISJSON(N'foo'); -- returns 0


  /* ==================================================================
  --Data: 14/08/2018 
  --Autor :Wesley Neves
  --Observação: Criando Restrição
   
  -- ==================================================================
  */

  GO
  
  CREATE TABLE dbo.JSONExample
(
  UserID INT PRIMARY KEY,
  Attributes NVARCHAR(4000),
  CONSTRAINT [No Garbage] CHECK (ISJSON(Attributes) = 1)
);

INSERT dbo.JSONExample(UserID, Attributes) SELECT 1, N'foo';
/*
The INSERT statement conflicted with the CHECK constraint "No Garbage". The conflict occurred in database "TSQLV4", table "dbo.JSONExample", column 'Attributes
*/

INSERT dbo.JSONExample(UserID, Attributes) SELECT 1, N'{"garbage": false}';