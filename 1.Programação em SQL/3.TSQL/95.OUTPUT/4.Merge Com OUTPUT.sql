
--SELECT Orders.orderid,
--                 Orders.custid,
--                 Orders.empid,
--                 Orders.orderdate INTO  Sales.MyOrders 
--            FROM Sales.Orders


SET IMPLICIT_TRANSACTIONS ON;
MERGE INTO Sales.MyOrders AS TGT
USING (   SELECT Orders.orderid,
                 Orders.custid,
                 Orders.empid,
                 Orders.orderdate
            FROM Sales.Orders
           WHERE Orders.shipcountry = N'Norway') AS SRC
   ON 1 = 2
 WHEN NOT MATCHED THEN INSERT (custid,
                               empid,
                               orderdate)
                       VALUES (SRC.custid, SRC.empid, SRC.orderdate)
OUTPUT $action,
       SRC.orderid AS srcorderid,
       inserted.orderid AS tgtorderid,
       inserted.custid,
       inserted.empid,
       inserted.orderdate;

	   

SET IMPLICIT_TRANSACTIONS ON;
MERGE INTO Sales.MyOrders AS TGT
USING (   SELECT Orders.orderid,
                 Orders.custid,
                 Orders.empid,
                 Orders.orderdate
            FROM Sales.Orders
           WHERE Orders.shipcountry = N'Norway') AS SRC
   ON 1 = 2
 WHEN NOT MATCHED THEN INSERT (custid,
                               empid,
                               orderdate)
                       VALUES (SRC.custid, SRC.empid, SRC.orderdate)
OUTPUT $action,
       SRC.orderid AS srcorderid,
       inserted.orderid AS tgtorderid,
       inserted.custid,
       inserted.empid,
       inserted.orderdate
	   
ROLLBACK