---------------------------------------------------------------------
-- TK 70-461 - Chapter 10 - Inserting, Updating and Deleting Data
-- Code
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Inserting Data
---------------------------------------------------------------------

-- create table Sales.MyOrders
USE TSQL2012;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;
GO

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL IDENTITY(1, 1)
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
  custid  INT NOT NULL,
  empid   INT NOT NULL,
  orderdate DATE NOT NULL
    CONSTRAINT DFT_MyOrders_orderdate DEFAULT (CAST(SYSDATETIME() AS DATE)),
  shipcountry NVARCHAR(15) NOT NULL,
  freight MONEY NOT NULL
);

---------------------------------------------------------------------
-- INSERT VALUES
---------------------------------------------------------------------

-- single row
INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
  VALUES(2, 19, '20120620', N'USA', 30.00);

-- relying on defaults
INSERT INTO Sales.MyOrders(custid, empid, shipcountry, freight)
  VALUES(3, 11, N'USA', 10.00);

INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
  VALUES(3, 17, DEFAULT, N'USA', 30.00);

-- multiple rows
INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight) VALUES
  (2, 11, '20120620', N'USA', 50.00),
  (5, 13, '20120620', N'USA', 40.00),
  (7, 17, '20120620', N'USA', 45.00);

-- query the table
SELECT *
FROM Sales.MyOrders;

---------------------------------------------------------------------
-- INSERT SELECT
---------------------------------------------------------------------

SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
  SELECT orderid, custid, empid, orderdate, shipcountry, freight
  FROM Sales.Orders
  WHERE shipcountry = N'Norway';

SET IDENTITY_INSERT Sales.MyOrders OFF;

-- query the table
SELECT *
FROM Sales.MyOrders;


---------------------------------------------------------------------
-- INSERT EXEC
---------------------------------------------------------------------

-- create procedure
IF OBJECT_ID(N'Sales.OrdersForCountry', N'P') IS NOT NULL
  DROP PROC Sales.OrdersForCountry;
GO

CREATE PROC Sales.OrdersForCountry
  @country AS NVARCHAR(15)
AS

SELECT orderid, custid, empid, orderdate, shipcountry, freight
FROM Sales.Orders
WHERE shipcountry = @country;
GO

-- insert the result of the procedure
SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
  EXEC Sales.OrdersForCountry
    @country = N'Portugal';

SET IDENTITY_INSERT Sales.MyOrders OFF;

-- query the table
SELECT *
FROM Sales.MyOrders;

---------------------------------------------------------------------
-- SELECT INTO
---------------------------------------------------------------------

-- simple SELECT INTO
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;

SELECT orderid, custid, orderdate, shipcountry, freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';

-- remove IDENTITY property, make column NULLable, change column's type
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL DROP TABLE Sales.MyOrders;

SELECT 
  ISNULL(orderid + 0, -1) AS orderid, -- get rid of IDENTITY property
                                      -- make column NOT NULL
  ISNULL(custid, -1) AS custid, -- make column NOT NULL
  empid, 
  ISNULL(CAST(orderdate AS DATE), '19000101') AS orderdate,
  shipcountry, freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';

-- create constraints
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

-- query the table
SELECT *
FROM Sales.MyOrders;

-- cleanup
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;

---------------------------------------------------------------------
-- Lesson 02 - Updating Data
---------------------------------------------------------------------

-- sample data for UPDATE and DELETE sections
IF OBJECT_ID(N'Sales.MyOrderDetails', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrderDetails;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL
  DROP TABLE Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;
ALTER TABLE Sales.MyCustomers
  ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;
ALTER TABLE Sales.MyOrderDetails
  ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);

-- UPDATE statement

-- add 5 percent discount to order lines of order 10251

-- first show current state
SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10251;

-- update
UPDATE Sales.MyOrderDetails
  SET discount += 0.05
WHERE orderid = 10251;

-- show state after update
SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10251;

-- cleanup
UPDATE Sales.MyOrderDetails
  SET discount -= 0.05
WHERE orderid = 10251;

-- UPDATE based on join

-- show state before update
SELECT OD.*
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- update
UPDATE OD
  SET OD.discount += 0.05
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- state after update
SELECT OD.*
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- cleanup
UPDATE OD
  SET OD.discount -= 0.05
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- nondeterministic UPDATE

-- show current state
SELECT C.custid, C.postalcode, O.shippostalcode
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
ORDER BY C.custid;

-- update
UPDATE C
  SET C.postalcode = O.shippostalcode
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid;

-- show state after update
SELECT custid, postalcode
FROM Sales.MyCustomers
ORDER BY custid;

-- update to the postal code associated with the first order
UPDATE C
  SET C.postalcode = A.shippostalcode
FROM Sales.MyCustomers AS C
  CROSS APPLY (SELECT TOP (1) O.shippostalcode
               FROM Sales.MyOrders AS O
               WHERE O.custid = C.custid
               ORDER BY orderdate, orderid) AS A;

-- show state after update
SELECT custid, postalcode
FROM Sales.MyCustomers
ORDER BY custid;

-- UPDATE and table expressions

-- query returning data that needs to be modified
SELECT TGT.custid,
  TGT.country AS tgt_country, SRC.country AS src_country,
  TGT.postalcode AS tgt_postalcode, SRC.postalcode AS src_postalcode
FROM Sales.MyCustomers AS TGT
  INNER JOIN Sales.Customers AS SRC
    ON TGT.custid = SRC.custid;

-- UPDATE based on a join
UPDATE TGT
  SET TGT.country = SRC.country,
      TGT.postalcode = SRC.postalcode
FROM Sales.MyCustomers AS TGT
  INNER JOIN Sales.Customers AS SRC
    ON TGT.custid = SRC.custid;

-- modify through table expression

-- using a CTE
WITH C AS
(
  SELECT TGT.custid,
    TGT.country AS tgt_country, SRC.country AS src_country,
    TGT.postalcode AS tgt_postalcode, SRC.postalcode AS src_postalcode
  FROM Sales.MyCustomers AS TGT
    INNER JOIN Sales.Customers AS SRC
      ON TGT.custid = SRC.custid
)
UPDATE C
  SET tgt_country = src_country,
      tgt_postalcode = src_postalcode;

-- using derived table

UPDATE D
  SET tgt_country = src_country,
      tgt_postalcode = src_postalcode
FROM (
        SELECT TGT.custid,
          TGT.country AS tgt_country, SRC.country AS src_country,
          TGT.postalcode AS tgt_postalcode, SRC.postalcode AS src_postalcode
        FROM Sales.MyCustomers AS TGT
          INNER JOIN Sales.Customers AS SRC
            ON TGT.custid = SRC.custid
     ) AS D;

-- UPDATE based on join
UPDATE TGT
  SET TGT.country = SRC.country,
      TGT.postalcode = SRC.postalcode
FROM Sales.MyCustomers AS TGT
  INNER JOIN Sales.Customers AS SRC
    ON TGT.custid = SRC.custid;

-- using just the FROM
UPDATE Sales.MyCustomers
  SET MyCustomers.country = SRC.country,
      MyCustomers.postalcode = SRC.postalcode
FROM Sales.Customers AS SRC
WHERE MyCustomers.custid = SRC.custid;

-- equivalent using cross join
UPDATE TGT
  SET TGT.country = SRC.country,
      TGT.postalcode = SRC.postalcode
FROM Sales.MyCustomers AS TGT
  CROSS JOIN Sales.Customers AS SRC
WHERE TGT.custid = SRC.custid;

-- UPDATE based on a variable

-- current state of the data
SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10250
  AND productid = 51;

DECLARE @newdiscount AS NUMERIC(4, 3) = NULL;

UPDATE Sales.MyOrderDetails
  SET @newdiscount = discount += 0.05
WHERE orderid = 10250
  AND productid = 51;

SELECT @newdiscount;

-- cleanup
UPDATE Sales.MyOrderDetails
  SET discount -= 0.05
WHERE orderid = 10250
  AND productid = 51;

-- UPDATE all-at-once

-- create table T1
IF OBJECT_ID(N'dbo.T1', N'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY,
  col1 INT NOT NULL, 
  col2 INT NOT NULL
);

INSERT INTO dbo.T1(keycol, col1, col2) VALUES(1, 100, 0);
GO

-- what's the value of col2 after the following UPDATE
DECLARE @add AS INT = 10;

UPDATE dbo.T1
  SET col1 += @add, col2 = col1
WHERE keycol = 1;

SELECT * FROM dbo.T1;

-- cleanup
IF OBJECT_ID(N'dbo.T1', N'U') IS NOT NULL DROP TABLE dbo.T1;

---------------------------------------------------------------------
-- Lesson 03 - Deleting Data
---------------------------------------------------------------------

-- sample data
IF OBJECT_ID(N'Sales.MyOrderDetails', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrderDetails;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL
  DROP TABLE Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;
ALTER TABLE Sales.MyCustomers
  ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;
ALTER TABLE Sales.MyOrderDetails
  ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);

-- DELETE statement
DELETE FROM Sales.MyOrderDetails
WHERE productid = 11;

-- delete in chuncks
WHILE 1 = 1
BEGIN
  DELETE TOP (1000) FROM Sales.MyOrderDetails
  WHERE productid = 12;

  IF @@rowcount < 1000 BREAK;
END

-- TRUNCATE statement
TRUNCATE TABLE Sales.MyOrderDetails;

-- DELETE based on a join
DELETE FROM O
FROM Sales.MyOrders AS O
  INNER JOIN Sales.MyCustomers AS C
    ON O.custid = C.custid
WHERE C.country = N'USA';

-- alternative using a subquery
DELETE FROM Sales.MyOrders
WHERE EXISTS
  (SELECT *
   FROM Sales.MyCustomers
   WHERE MyCustomers.custid = MyOrders.custid
     AND MyCustomers.country = N'USA');

-- DELETE using table expressions
WITH OldestOrders AS
(
  SELECT TOP (100) *
  FROM Sales.MyOrders
  ORDER BY orderdate, orderid
)
DELETE FROM OldestOrders;

-- cleanup
IF OBJECT_ID(N'Sales.MyOrderDetails', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrderDetails;
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL
  DROP TABLE Sales.MyCustomers;
