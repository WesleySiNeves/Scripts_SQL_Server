---------------------------------------------------------------------
-- TK 70-461 - Chapter 11 - Other Data Modification Aspects
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Using the Sequence Object and IDENTITY Column Property
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the Sequence Object
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Create a Sequence with Default Options
---------------------------------------------------------------------

-- 2.

-- create a sequence called dbo.Seq1 with the defaults
USE TSQL2012;

IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;

CREATE SEQUENCE dbo.Seq1;

-- 3.

SELECT
  TYPE_NAME(system_type_id) AS type,
  start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID(N'dbo.Seq1', N'SO');

---------------------------------------------------------------------
-- Exercise 2 - Create a Sequence with Non-Default Options
---------------------------------------------------------------------

-- 1.

-- cannot alter type; need to recreate

IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;

CREATE SEQUENCE dbo.Seq1 AS INT
  START WITH 1 CYCLE;

SELECT
  TYPE_NAME(system_type_id) AS type,
  start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID(N'dbo.Seq1', N'SO');

-- 2.

ALTER SEQUENCE dbo.Seq1 RESTART WITH 2147483647;

-- run twice
SELECT NEXT VALUE FOR dbo.Seq1;

-- 3.

IF OBJECT_ID(N'dbo.Seq1', N'SO') IS NOT NULL DROP SEQUENCE dbo.Seq1;

CREATE SEQUENCE dbo.Seq1 AS INT
  MINVALUE 1 CYCLE;

-- 4.

SELECT
  TYPE_NAME(system_type_id) AS type,
  start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID(N'dbo.Seq1', N'SO');

-- 5.

ALTER SEQUENCE dbo.Seq1 RESTART WITH 2147483647;

-- run twice
SELECT NEXT VALUE FOR dbo.Seq1;

---------------------------------------------------------------------
-- Lesson 02 - Merging Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Merging Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Use the MERGE Statement
---------------------------------------------------------------------

-- 2.

-- create the Sales.MyOrders table
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.SeqOrderIDs', N'SO') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
  MINVALUE 1
  CYCLE;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
    CONSTRAINT DFT_MyOrders_orderid
      DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
  custid  INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);

-- 3.

-- merge data from Sales.Orders into Sales.MyOrders
MERGE INTO Sales.MyOrders AS TGT
USING Sales.Orders AS SRC
  ON  SRC.orderid = TGT.orderid
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

---------------------------------------------------------------------
-- Exercise 2 - Understand the Role of the ON Clause in a MERGE Statement
---------------------------------------------------------------------

-- 1.

-- populate the Sales.MyOrders table

TRUNCATE TABLE Sales.MyOrders;

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM Sales.Orders
  WHERE shipcountry <> N'Norway';

-- 2.

-- try merging Norway customers from Sales.Orders into Sales.MyOrders
MERGE INTO Sales.MyOrders AS TGT
USING Sales.Orders AS SRC
  ON  SRC.orderid = TGT.orderid
  AND shipcountry = N'Norway'
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

-- 3.

-- try again, but filter the relevant rows in a table expression
WITH SRC AS
(
  SELECT *
  FROM Sales.Orders
  WHERE shipcountry = N'Norway'
)
MERGE INTO Sales.MyOrders AS TGT
USING SRC
  ON  SRC.orderid = TGT.orderid 
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

-- alternative with derived table
MERGE INTO Sales.MyOrders AS TGT
USING ( SELECT *
        FROM Sales.Orders
        WHERE shipcountry = N'Norway' )
 AS SRC
  ON  SRC.orderid = TGT.orderid 
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN UPDATE
  SET TGT.custid    = SRC.custid,
      TGT.empid     = SRC.empid,
      TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
  VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

---------------------------------------------------------------------
-- Lesson 03 - Using the OUTPUT Option 
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the OUTPUT Option
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Use OUTPUT in an UPDATE Statement
---------------------------------------------------------------------

-- 2.

SELECT productid, productname, unitprice
FROM Production.Products
WHERE categoryid = 1
  AND supplierid = 16;

-- 3.

-- increase unitprice by 2.5; return the percent of price increase in the output
UPDATE Production.Products
  SET unitprice += 2.5
  OUTPUT
    inserted.productid,
    inserted.productname,
    deleted.unitprice AS oldprice,
    inserted.unitprice AS newprice,
    CAST(100.0 * (inserted.unitprice - deleted.unitprice)
                 / deleted.unitprice AS NUMERIC(5, 2)) AS pct
WHERE categoryid = 1
  AND supplierid = 16;

-- 4.

-- update back
UPDATE Production.Products
  SET unitprice -= 2.5
  OUTPUT
    inserted.productid,
    inserted.productname,
    deleted.unitprice AS oldprice,
    inserted.unitprice AS newprice,
    CAST(100.0 * (inserted.unitprice - deleted.unitprice)
                 / deleted.unitprice AS NUMERIC(5, 2)) AS pct
WHERE categoryid = 1
  AND supplierid = 16;

---------------------------------------------------------------------
-- Exercise 2 - Use Composable DML
---------------------------------------------------------------------

-- 1.

-- create the Sales.MyOrders and Sales.MyOrdersArchive table
IF OBJECT_ID(N'Sales.MyOrdersArchive', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrdersArchive;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders PRIMARY KEY,
  custid  INT NOT NULL,
  empid   INT NOT NULL,
  orderdate DATE NOT NULL
);

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM Sales.Orders;

CREATE TABLE Sales.MyOrdersArchive
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrdersArchive PRIMARY KEY,
  custid  INT NOT NULL,
  empid   INT NOT NULL,
  orderdate DATE NOT NULL
);

-- 2.

-- delete orders placed before 2007
-- archive deleted orders placed by customers 17 and 19
INSERT INTO Sales.MyOrdersArchive(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM (DELETE FROM Sales.MyOrders
          OUTPUT deleted.*
        WHERE orderdate < '20070101') AS D
  WHERE custid IN (17, 19);

-- 3.

-- query Sales.MyOrdersArchive
SELECT *
FROM Sales.MyOrdersArchive;

-- 4.

-- run the following code for cleanup
IF OBJECT_ID(N'Sales.MyOrdersArchive', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrdersArchive;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
