USE AdventureWorks;

-- ==================================================================
--Observa��o: Rode como o plano de execu��o ligado
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
  --Observa��o:
  /* 2) Crie o indice
   */
  -- ==================================================================
  --IdxCoberto
  CREATE NONCLUSTERED INDEX IdxCorverSalesOrderDetail ON Sales.SalesOrderDetail(ProductID,SalesOrderDetailID,OrderQty,UnitPrice)


  -- ==================================================================
  --Observa��o:
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

