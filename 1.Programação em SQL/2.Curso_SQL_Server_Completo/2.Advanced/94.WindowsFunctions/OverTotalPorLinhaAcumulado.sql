USE TSQL2012;

WITH    RunningTotals
          AS ( SELECT   custid ,
                        orderid ,
                        orderdate ,
                        val ,
                        SUM(val) OVER ( PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS runningtotal ,
                        TotalRange = SUM(val) OVER ( PARTITION BY custid  ORDER BY custid RANGE UNBOUNDED PRECEDING )
               FROM     Sales.OrderValues
             )
    SELECT  RunningTotals.custid ,
            RunningTotals.orderid ,
            RunningTotals.orderdate ,
            RunningTotals.val ,
            RunningTotals.runningtotal ,
            RunningTotals.TotalRange
    FROM    RunningTotals;