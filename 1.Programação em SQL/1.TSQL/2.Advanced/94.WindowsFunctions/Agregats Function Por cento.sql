USE TSQLV4;
SELECT OrderValues.custid,
       OrderValues.orderid,
       OrderValues.val,
       TotalPorCliente = SUM(OrderValues.val) OVER (PARTITION BY OrderValues.custid),
       [% da venda por Cliente] = CAST(((OrderValues.val) / SUM(OrderValues.val) OVER (PARTITION BY OrderValues.custid)
                                        * 100) AS DECIMAL(18, 2)),
       MaiorVenda = MAX(OrderValues.val) OVER (PARTITION BY OrderValues.custid),
       MenorVenda = MIN(OrderValues.val) OVER (PARTITION BY OrderValues.custid),
       MediaPorCliente = AVG(OrderValues.val) OVER (PARTITION BY OrderValues.custid),
       Grandtotal = SUM(OrderValues.val) OVER ()
  FROM Sales.OrderValues;