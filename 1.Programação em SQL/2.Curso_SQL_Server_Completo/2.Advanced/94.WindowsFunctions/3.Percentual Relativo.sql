USE TSQLV4;

SELECT OD.orderid,
       OD.productid,
       OD.unitprice,
       OD.qty,
       OD.discount,
       TotalPorOrdem = (OD.unitprice * OD.qty),
       [Percentual do Valor sobre a Nota] = CAST(100.0 * (OD.unitprice * OD.qty)
                                                 / SUM(OD.unitprice * OD.qty) OVER (PARTITION BY OD.orderid) AS NUMERIC(5, 2)),
       TotalGeral = SUM(OD.unitprice * OD.qty) OVER ()
  FROM Sales.OrderDetails AS OD
 WHERE OD.orderid = 10248;
