USE TSQLV4;

WITH RunningTotals
  AS (SELECT OrderValues.custid,
             OrderValues.orderid,
             OrderValues.orderdate,
             OrderValues.val,
             SUM(OrderValues.val) OVER (PARTITION BY OrderValues.custid
                                            ORDER BY OrderValues.orderdate,
                                                     OrderValues.orderid
                                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runningtotal
        FROM Sales.OrderValues)
SELECT *
  FROM RunningTotals
 WHERE RunningTotals.runningtotal < 1000.00;