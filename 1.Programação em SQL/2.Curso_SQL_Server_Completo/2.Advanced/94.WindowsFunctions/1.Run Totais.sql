USE TSQL2012;

WITH    RunningTotals
          AS ( SELECT   custid ,
                        orderid ,
                        orderdate ,
                        val ,
                        SUM(val) OVER ( PARTITION BY custid ORDER BY orderdate, orderid
ROWS BETWEEN UNBOUNDED PRECEDING
AND CURRENT ROW ) AS runningtotala
               FROM     Sales.OrderValues
             )
    SELECT  *
    FROM    RunningTotals
   -- WHERE   runningtotal < 1000.00;