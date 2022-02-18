
--SELECT Orders.orderid,
--                Orders.custid,
--                Orders.empid,
--                Orders.orderdate
--         INTO Sales.MyOrders   FROM Sales.Orders

DECLARE @InsertedOrders AS TABLE (
    orderid INT NOT NULL PRIMARY KEY,
    custid INT NOT NULL,
    empid INT NOT NULL,
    orderdate DATE NOT NULL);
INSERT INTO @InsertedOrders (orderid,
                             custid,
                             empid,
                             orderdate)
SELECT orderid,
       custid,
       empid,
       orderdate
  FROM (   MERGE INTO Sales.MyOrders AS TGT
           USING (   VALUES (1, 70, 1, '20151218'),
                            (2, 70, 7, '20160429'),
                            (3, 70, 7, '20160820'),
                            (4, 70, 3, '20170114'),
                            (5, 70, 1, '20170226'),
                            (6, 70, 2, '20170410')) AS SRC (orderid, custid, empid, orderdate)
              ON SRC.orderid = TGT.orderid
            WHEN MATCHED AND EXISTS (SELECT SRC.* EXCEPT SELECT TGT.*) THEN UPDATE SET TGT.custid = SRC.custid,
                                                                                       TGT.empid = SRC.empid,
                                                                                       TGT.orderdate = SRC.orderdate
            WHEN NOT MATCHED THEN INSERT VALUES (SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
            WHEN NOT MATCHED BY SOURCE THEN DELETE
           OUTPUT $action AS the_action,
                  inserted.*) AS D
 WHERE the_action = 'INSERT';
SELECT *
  FROM @InsertedOrders;