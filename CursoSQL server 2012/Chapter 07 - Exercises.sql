---------------------------------------------------------------------
-- TK 70-461 - Chapter 07 -  Querying and Managing XML Data
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Returning Results as XML with FOR XML
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Returning Results as XML with FOR XML
---------------------------------------------------------------------

-- Exercise 1 Returning XML Document

-- 3.
USE TSQL2012;

-- 4.
SELECT Customer.custid, Customer.companyname, 
 [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
 INNER JOIN Sales.Orders AS [Order]
  ON Customer.custid = [Order].custid
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW;

-- 6.
WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid], 
 [co:Customer].companyname AS [co:companyname], 
 [co:Order].orderid AS [co:orderid], 
 [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
 INNER JOIN Sales.Orders AS [co:Order]
  ON [co:Customer].custid = [co:Order].custid
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');

-- Exercise 2 Returning XML Fragment

-- 1.
SELECT Customer.custid AS [@custid],
 Customer.companyname AS [@companyname],
 (SELECT [Order].orderid AS [@orderid],
   [Order].orderdate AS [@orderdate]
  FROM Sales.Orders AS [Order]
  WHERE Customer.custid = [Order].custid
    AND [Order].orderid %2 = 0
  ORDER BY [Order].orderid
  FOR XML PATH('Order'), TYPE)
FROM Sales.Customers AS Customer
WHERE Customer.custid <= 2
ORDER BY Customer.custid
FOR XML PATH('Customer');
GO

---------------------------------------------------------------------
-- Lesson 02 - Querying XML Data with XQuery
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - XQuery / XPath Navigation
---------------------------------------------------------------------

-- Exercise 1 Simple XPath Expressions

-- 2.
USE TSQL2012;

-- 3.
DECLARE @x AS XML;
SET @x = N'
<CustomersOrders>
  <Customer custid="1">
    <!-- Comment 111 -->
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2007-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2007-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <!-- Comment 222 -->  
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2006-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';

-- 4. Principal nodes only
SELECT @x.query('CustomersOrders/Customer/*')
       AS [1. Principal nodes];

-- 5. All nodes
SELECT @x.query('CustomersOrders/Customer/node()')
       AS [2. All nodes];

-- 6. Comment nodes only
SELECT @x.query('CustomersOrders/Customer/comment()')
       AS [3. Comment nodes];

-- Exercise 2  XPath Expressions with Predicates

-- 1.
DECLARE @x AS XML;
SET @x = N'
<CustomersOrders>
  <Customer custid="1">
    <!-- Comment 111 -->
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2007-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2007-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <!-- Comment 222 -->  
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2006-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';

-- 2. Customer 2 orders
SELECT @x.query('//Customer[@custid=2]/Order')
       AS [4. Customer 2 orders];

-- 3. All orders with orderid=10952, no matter of parents
SELECT @x.query('//Order[@orderid=10952]')
       AS [5. Orders with orderid=10952];

-- 4. Second customer with at least one Order child
SELECT @x.query('(/CustomersOrders/Customer/
                  Order/parent::Customer)[2]')
       AS [6. 2nd Customer with at least one Order];                  
GO


---------------------------------------------------------------------
-- Lesson 03 - Using the XML Data Type
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - XML Data Type Methods
---------------------------------------------------------------------

-- Exercise 1 The value() and exist() Methods

-- 2.
USE TSQL2012;

-- 3.
DECLARE @x AS XML;
SET @x = N'
<CustomersOrders>
  <Customer custid="1">
    <!-- Comment 111 -->
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2007-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2007-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <!-- Comment 222 -->  
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2006-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';

-- 4. Retrieve the first customer name
SELECT @x.value('(/CustomersOrders/Customer/companyname)[1]',
      'NVARCHAR(20)')
       AS [First Customer Name];

-- 5. Check whether the companyname and address nodes exist
SELECT @x.exist('(/CustomersOrders/Customer/companyname)')
       AS [Company Name Exists],
	   @x.exist('(/CustomersOrders/Customer/address)')
       AS [Address Exists];

-- Exercise 2 The query(), nodes() and modify() Methods

-- 1.
DECLARE @x AS XML;
SET @x = N'
<CustomersOrders>
  <Customer custid="1">
    <!-- Comment 111 -->
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2007-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2007-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <!-- Comment 222 -->  
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2006-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';

-- 2. Return orders for the first customer
SELECT @x.query('//Customer[@custid=1]/Order')
       AS [Customer 1 orders];

-- 3. Shred order info for the first customer
SELECT  T.c.value('./@orderid[1]', 'INT') AS [Order Id],
 T.c.value('./orderdate[1]', 'DATETIME') AS [Order Date]
FROM @x.nodes('//Customer[@custid=1]/Order')
      AS T(c);

-- 4. Update the name of the first customer
SET @x.modify('replace value of 
    /CustomersOrders[1]/Customer[1]/companyname[1]/text()[1]
	with "New Company Name"');
SELECT @x.value('(/CustomersOrders/Customer/companyname)[1]', 
       'NVARCHAR(20)')
       AS [First Customer New Name];
GO

