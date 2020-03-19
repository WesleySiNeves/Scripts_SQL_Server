USE AdventureWorks;

-- ==================================================================
--Observação: Rode como o plano de execução ligado
/* 
 */
-- ==================================================================
SELECT SOD.SalesOrderID,
       SOD.SalesOrderDetailID,
       SOD.OrderQty,
       P.Name,
       SOD.UnitPrice
  FROM Sales.SalesOrderDetail AS SOD
  JOIN Production.Product AS P  ON SOD.ProductID = P.ProductID 
  ORDER BY p.ProductID OPTION(MAXDOP 1)

  

  -- ==================================================================
  --Observação:
  /* 2) Crie o indice
   */
  -- ==================================================================
  --IdxCoberto
  CREATE NONCLUSTERED INDEX IdxCorverSalesOrderDetail ON Sales.SalesOrderDetail(ProductID,SalesOrderDetailID,OrderQty,UnitPrice)


  -- ==================================================================
  --Observação:
  /*3 )Rode novamento a query e compare os planos
   */
  -- ==================================================================

  SELECT SOD.SalesOrderID,
       SOD.SalesOrderDetailID,
       SOD.OrderQty,
       P.Name,
       SOD.UnitPrice
  FROM Sales.SalesOrderDetail AS SOD
  JOIN Production.Product AS P  ON SOD.ProductID = P.ProductID 
  ORDER BY p.ProductID OPTION(MAXDOP 1)

