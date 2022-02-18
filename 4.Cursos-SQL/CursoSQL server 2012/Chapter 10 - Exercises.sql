---------------------------------------------------------------------
-- TK 70-461 - Chapter 10 - Inserting, Updating and Deleting Data
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Inserting Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Inserting Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Insert Data for Customers Without Orders
---------------------------------------------------------------------

-- 1.

USE TSQL2012;

-- 2.

-- examine the structure of the Sales.Customers table
EXEC sp_describe_first_result_set N'SELECT * FROM Sales.Customers;';

-- 3.
-- create a table called Sales.MyCustomers based on definition of Sales.Customers
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL DROP TABLE Sales.MyCustomers;

CREATE TABLE Sales.MyCustomers
(
  custid       INT NOT NULL
    CONSTRAINT PK_MyCustomers PRIMARY KEY,
  companyname  NVARCHAR(40) NOT NULL,
  contactname  NVARCHAR(30) NOT NULL,
  contacttitle NVARCHAR(30) NOT NULL,
  address      NVARCHAR(60) NOT NULL,
  city         NVARCHAR(15) NOT NULL,
  region       NVARCHAR(15) NULL,
  postalcode   NVARCHAR(10) NULL,
  country      NVARCHAR(15) NOT NULL,
  phone        NVARCHAR(24) NOT NULL,
  fax          NVARCHAR(24) NULL
);

-- 4.
-- insert into the Sales.MyCustomers table customers from Sales.Customers who did not place orders
INSERT INTO Sales.MyCustomers
  (custid, companyname, contactname, contacttitle, address,
   city, region, postalcode, country, phone, fax)
  SELECT
    custid, companyname, contactname, contacttitle, address,
    city, region, postalcode, country, phone, fax
  FROM Sales.Customers AS C
  WHERE NOT EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

-- 5.
-- present the IDs of the customers from Sales.MyCustomers
SELECT custid FROM Sales.MyCustomers;

---------------------------------------------------------------------
-- Exercise 2 - Insert Data for Customers Without Orders
---------------------------------------------------------------------

-- 1.
-- achieve the same result as the previous exercise with the SELECT INTO command
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL DROP TABLE Sales.MyCustomers;

SELECT
  ISNULL(custid, -1) AS custid,
  companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
INTO Sales.MyCustomers
FROM Sales.Customers AS C
WHERE NOT EXISTS
  (SELECT * FROM Sales.Orders AS O
    WHERE O.custid = C.custid);

ALTER TABLE Sales.MyCustomers
 ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT custid FROM Sales.MyCustomers;

---------------------------------------------------------------------
-- Lesson 02 - Updating Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Updating Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Update Data by Using Joins
---------------------------------------------------------------------

-- 2.

-- create the Sales.MyCustomers table and insert a couple of rows
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL DROP TABLE Sales.MyCustomers;

CREATE TABLE Sales.MyCustomers
(
  custid       INT NOT NULL
    CONSTRAINT PK_MyCustomers PRIMARY KEY,
  companyname  NVARCHAR(40) NOT NULL,
  contactname  NVARCHAR(30) NOT NULL,
  contacttitle NVARCHAR(30) NOT NULL,
  address      NVARCHAR(60) NOT NULL,
  city         NVARCHAR(15) NOT NULL,
  region       NVARCHAR(15) NULL,
  postalcode   NVARCHAR(10) NULL,
  country      NVARCHAR(15) NOT NULL,
  phone        NVARCHAR(24) NOT NULL,
  fax          NVARCHAR(24) NULL
);

INSERT INTO Sales.MyCustomers
  (custid, companyname, contactname, contacttitle, address,
   city, region, postalcode, country, phone, fax)
  VALUES(22, N'', N'', N'', N'', N'', N'', N'', N'', N'', N''),
        (57, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'');

-- 3.
-- write an UPDATE statement that overwrites the values of all nonkey columns
-- with those from the respective rows in the Sales.Customers table
UPDATE TGT
  SET   TGT.companyname  = SRC.companyname , 
        TGT.contactname  = SRC.contactname , 
        TGT.contacttitle = SRC.contacttitle, 
        TGT.address      = SRC.address     ,
        TGT.city         = SRC.city        ,
        TGT.region       = SRC.region      ,
        TGT.postalcode   = SRC.postalcode  ,
        TGT.country      = SRC.country     ,
        TGT.phone        = SRC.phone       ,
        TGT.fax          = SRC.fax
FROM Sales.MyCustomers AS TGT
  INNER JOIN Sales.Customers AS SRC
    ON TGT.custid = SRC.custid;

---------------------------------------------------------------------
-- Exercise 2 - Update Data by Using A CTE
---------------------------------------------------------------------

-- 1.
-- implement the same task as the last but through a CTE
WITH C AS
(
  SELECT
    TGT.custid       AS tgt_custid      , SRC.custid       AS src_custid      ,
    TGT.companyname  AS tgt_companyname , SRC.companyname  AS src_companyname , 
    TGT.contactname  AS tgt_contactname , SRC.contactname  AS src_contactname , 
    TGT.contacttitle AS tgt_contacttitle, SRC.contacttitle AS src_contacttitle, 
    TGT.address      AS tgt_address     , SRC.address      AS src_address     ,
    TGT.city         AS tgt_city        , SRC.city         AS src_city        ,
    TGT.region       AS tgt_region      , SRC.region       AS src_region      ,
    TGT.postalcode   AS tgt_postalcode  , SRC.postalcode   AS src_postalcode  ,
    TGT.country      AS tgt_country     , SRC.country      AS src_country     ,
    TGT.phone        AS tgt_phone       , SRC.phone        AS src_phone       ,
    TGT.fax          AS tgt_fax         , SRC.fax          AS src_fax         
  FROM Sales.MyCustomers AS TGT
    INNER JOIN Sales.Customers AS SRC
      ON TGT.custid = SRC.custid
)
UPDATE C
  SET   tgt_custid       = src_custid      , 
        tgt_companyname  = src_companyname , 
        tgt_contactname  = src_contactname , 
        tgt_contacttitle = src_contacttitle, 
        tgt_address      = src_address     ,
        tgt_city         = src_city        ,
        tgt_region       = src_region      ,
        tgt_postalcode   = src_postalcode  ,
        tgt_country      = src_country     ,
        tgt_phone        = src_phone       ,
        tgt_fax          = src_fax;

---------------------------------------------------------------------
-- Lesson 03 - Deleting Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Deleting and Truncating Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Delete Data by Using Joins
---------------------------------------------------------------------

-- 2.

-- use the following code to create the Sales.MyCustomers
-- and Sales.MyOrders tables as initial copies
-- of the Sales.Customers table and Sales.Orders Tables
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

ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT FK_MyOrders_MyCustomers
  FOREIGN KEY(custid) REFERENCES Sales.MyCustomers(custid);

-- 3.
-- write a DELETE statement that deletes rows from the
-- Sales.MyCustomers table if the customer has no related orders
-- in the Sales.MyOrders table
-- use a DELETE statement based on a join to implement the task
DELETE FROM TGT
FROM Sales.MyCustomers AS TGT
  LEFT OUTER JOIN Sales.MyOrders AS SRC
    ON TGT.custid = SRC.custid
WHERE SRC.orderid IS NULL;

-- 4.
-- count the number of customers remaining; you should get 89
SELECT COUNT(*) AS cnt FROM Sales.MyCustomers;

---------------------------------------------------------------------
-- Exercise 2 - Truncate Data
---------------------------------------------------------------------

-- 1.
-- Try to clear the table by using the TRUNCATE statement
TRUNCATE TABLE Sales.MyOrders;
TRUNCATE TABLE Sales.MyCustomers;

-- 2.
-- drop the foreign key, truncate the target table, and then create back the foreign key
ALTER TABLE Sales.MyOrders
  DROP CONSTRAINT FK_MyOrders_MyCustomers;

TRUNCATE TABLE Sales.MyCustomers;

ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT FK_MyOrders_MyCustomers
  FOREIGN KEY(custid) REFERENCES Sales.MyCustomers(custid);

-- 3.
-- when you’re done, run the following code for cleanup:
IF OBJECT_ID(N'Sales.MyOrders', N'U') IS NOT NULL
  DROP TABLE Sales.MyOrders;
IF OBJECT_ID(N'Sales.MyCustomers', N'U') IS NOT NULL
  DROP TABLE Sales.MyCustomers;
