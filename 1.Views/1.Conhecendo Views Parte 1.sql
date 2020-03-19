
USE  AdventureWorks;
GO

/*Cria uma  View Simples*/

CREATE OR ALTER VIEW vwRelacaoVendas
AS
    SELECT  SO.SalesOrderID ,
            [Data Venda] = CONVERT(VARCHAR(10), SOH.OrderDate, 103) ,
            [Cliente] = CONCAT(P.FirstName, '', P.LastName) ,
            [Quantidade] = SO.OrderQty ,
            [Produto] = Pro.Name ,
            [PrecoUnitario] = SO.UnitPrice ,
            [Desconto] = SO.UnitPriceDiscount ,
            [TotalItem] = ( SO.OrderQty * SO.UnitPrice )
    FROM    Sales.SalesOrderDetail AS SO
            JOIN Sales.SalesOrderHeader AS SOH ON SOH.SalesOrderID = SO.SalesOrderID
            JOIN Sales.Customer AS C ON C.CustomerID = SOH.CustomerID
            JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
            JOIN Production.Product AS Pro ON Pro.ProductID = SO.ProductID; 


/*View com WITH ENCRYPTION  */

ALTER VIEW dbo.vwRelacaoVendas
WITH ENCRYPTION
AS
    SELECT  SO.SalesOrderID ,
            [Data Venda] = CONVERT(VARCHAR(10), SOH.OrderDate, 103) ,
            [Cliente] = CONCAT(P.FirstName, '-', P.LastName) ,
            [Quantidade] = SO.OrderQty ,
            [Produto] = Pro.NAME ,
            [PrecoUnitario] = SO.UnitPrice ,
            [Desconto] = SO.UnitPriceDiscount ,
            [TotalItem] = ( SO.OrderQty * SO.UnitPrice )
    FROM    Sales.SalesOrderDetail AS SO
            JOIN Sales.SalesOrderHeader AS SOH ON SOH.SalesOrderID = SO.SalesOrderID
            JOIN Sales.Customer AS C ON C.CustomerID = SOH.CustomerID
            JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
            JOIN Production.Product AS Pro ON Pro.ProductID = SO.ProductID



-- ==================================================================
-- Author:Wesley Neves
--Observação:Views não atualizavel
-- ==================================================================

ALTER VIEW dbo.vwRelacaoVendas
AS
    SELECT  SO.SalesOrderID ,
            SO.SalesOrderDetailID ,
            SO.ProductID ,
            SO.OrderQty ,
            SO.UnitPrice ,
            SO.UnitPriceDiscount
    FROM    Sales.SalesOrderDetail AS SO
    EXCEPT
    ( SELECT    SO.SalesOrderID ,
                SO.SalesOrderDetailID ,
                SO.ProductID ,
                SO.OrderQty ,
                SO.UnitPrice ,
                SO.UnitPriceDiscount
      FROM      Sales.SalesOrderDetail AS SO
      WHERE     SO.SalesOrderID = 43659
    ); 




- ==================================================================
--segundo exemplo

- ==================================================================

ALTER VIEW dbo.vwRelacaoVendas
AS
    SELECT  SO.SalesOrderID ,
            SO.SalesOrderDetailID ,
            SO.ProductID ,
            SO.OrderQty ,
            SO.UnitPrice ,
            SO.UnitPriceDiscount
    FROM    Sales.SalesOrderDetail AS SO
    WHERE   SO.SalesOrderID = 43661
    UNION
    ( SELECT    SO.SalesOrderID ,
                SO.SalesOrderDetailID ,
                SO.ProductID ,
                SO.OrderQty ,
                SO.UnitPrice ,
                SO.UnitPriceDiscount
      FROM      Sales.SalesOrderDetail AS SO
      WHERE     SO.SalesOrderID = 43659
    ); 



-- ==================================================================
-- Author: Wesley Neves
--Observação:View com WITH CHECK OPTION; 
-- ==================================================================


ALTER VIEW dbo.VwSaldoInicial 

AS 

    SELECT  * 

    FROM    dbo.SaldoInicial AS SI 

    WHERE   SI.Saldo >= 101 

WITH CHECK OPTION; 