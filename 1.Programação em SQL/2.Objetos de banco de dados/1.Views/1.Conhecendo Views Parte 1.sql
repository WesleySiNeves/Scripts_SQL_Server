

/*
AdventureWorksLT
*/

/*Cria uma  View Simples*/

CREATE OR ALTER VIEW vwRelacaoVendas
AS
SELECT  1 AS Numero

GO

SELECT object_id, definition 
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.vwRelacaoVendas');
 

SELECT S.ctext, S.encrypted,S.text FROM sys.syscomments AS S
WHERE id =  OBJECT_ID('dbo.vwRelacaoVendas')

 GO
 

CREATE OR ALTER VIEW vwRelacaoVendas
AS
    SELECT  SO.SalesOrderID ,
            [Data Venda] = CONVERT(VARCHAR(10), SOH.OrderDate, 103) ,
            [Cliente] = CONCAT(C.FirstName, '', C.LastName) ,
            [Quantidade] = SO.OrderQty ,
            [Produto] = Pro.Name ,
            [PrecoUnitario] = SO.UnitPrice ,
            [Desconto] = SO.UnitPriceDiscount ,
            [TotalItem] = ( SO.OrderQty * SO.UnitPrice )
    FROM    SalesLT.SalesOrderDetail AS SO
            JOIN SalesLT.SalesOrderHeader AS SOH ON SOH.SalesOrderID = SO.SalesOrderID
            JOIN SalesLT.Customer AS C ON C.CustomerID = SOH.CustomerID
            JOIN SalesLT.Product AS Pro ON Pro.ProductID = SO.ProductID; 


SELECT * FROM vwRelacaoVendas






/*View com WITH ENCRYPTION  */

ALTER VIEW dbo.vwRelacaoVendas
WITH ENCRYPTION
AS
     SELECT  SO.SalesOrderID ,
            [Data Venda] = CONVERT(VARCHAR(10), SOH.OrderDate, 103) ,
            [Cliente] = CONCAT(C.FirstName, '', C.LastName) ,
            [Quantidade] = SO.OrderQty ,
            [Produto] = Pro.Name ,
            [PrecoUnitario] = SO.UnitPrice ,
            [Desconto] = SO.UnitPriceDiscount ,
            [TotalItem] = ( SO.OrderQty * SO.UnitPrice )
    FROM    SalesLT.SalesOrderDetail AS SO
            JOIN SalesLT.SalesOrderHeader AS SOH ON SOH.SalesOrderID = SO.SalesOrderID
            JOIN SalesLT.Customer AS C ON C.CustomerID = SOH.CustomerID
            JOIN SalesLT.Product AS Pro ON Pro.ProductID = SO.ProductID; 


SELECT * FROM vwRelacaoVendas


SELECT object_id, definition 
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.vwRelacaoVendas');
 

SELECT S.ctext, S.encrypted,S.text FROM sys.syscomments AS S
WHERE id =  OBJECT_ID('dbo.vwRelacaoVendas')


-- ==================================================================
-- Author:Wesley Neves
--Observa��o:Views n�o atualizavel
-- ==================================================================

ALTER VIEW dbo.vwRelacaoVendas
AS
    SELECT  SO.SalesOrderID ,
            SO.SalesOrderDetailID ,
            SO.ProductID ,
            SO.OrderQty ,
            SO.UnitPrice ,
            SO.UnitPriceDiscount
    FROM    Saleslt.SalesOrderDetail AS SO
    EXCEPT
    ( SELECT    SO.SalesOrderID ,
                SO.SalesOrderDetailID ,
                SO.ProductID ,
                SO.OrderQty ,
                SO.UnitPrice ,
                SO.UnitPriceDiscount
      FROM      Saleslt.SalesOrderDetail AS SO
      WHERE     SO.SalesOrderID = 43659
    ); 



SELECT object_id, definition 
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.vwRelacaoVendas');
 
SELECT S.ctext, S.encrypted,S.text FROM sys.syscomments AS S
WHERE id =  OBJECT_ID('dbo.vwRelacaoVendas')

--- ==================================================================
----segundo exemplo
--- ==================================================================

ALTER VIEW dbo.vwRelacaoVendas
AS
    SELECT  SO.SalesOrderID ,
            SO.SalesOrderDetailID ,
            SO.ProductID ,
            SO.OrderQty ,
            SO.UnitPrice ,
            SO.UnitPriceDiscount
    FROM    Saleslt.SalesOrderDetail AS SO
    WHERE   SalesOrderID = 43661
    UNION
    ( SELECT    SO.SalesOrderID ,
                SO.SalesOrderDetailID ,
                SO.ProductID ,
                SO.OrderQty ,
                SO.UnitPrice ,
                SO.UnitPriceDiscount
      FROM      Saleslt.SalesOrderDetail AS SO
      WHERE     SalesOrderID = 43659
    ); 




SELECT object_id, definition 
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.vwRelacaoVendas');
 
SELECT S.ctext, S.encrypted,S.text FROM sys.syscomments AS S
WHERE id =  OBJECT_ID('dbo.vwRelacaoVendas')
