---------------------------------------------------------------------
-- TK 70-461 - Chapter 07 - Querying and Managing XML Data
-- Code
---------------------------------------------------------------------

USE TSQL2012;
GO
SET NOCOUNT ON;
GO

---------------------------------------------------------------------
-- Lesson 01 - Returning Results as XML with FOR XML
---------------------------------------------------------------------

-- Create XML example with FOR XML AUTO option, atttribute-centric
SELECT Customer.custid, Customer.companyname, 
 [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
 INNER JOIN Sales.Orders AS [Order]
  ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
  AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML AUTO, ROOT('CustomersOrders');

-- XML with AUTO option, element-centric, with namespace
WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid], 
 [co:Customer].companyname AS [co:companyname], 
 [co:Order].orderid AS [co:orderid], 
 [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
 INNER JOIN Sales.Orders AS [co:Order]
  ON [co:Customer].custid = [co:Order].custid
WHERE [co:Customer].custid <= 2
  AND [co:Order].orderid %2 = 0
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');
GO

-- Schema
-- XML with AUTO option, element-centric, with namespace and XMLSCHEMA
SELECT [Customer].custid AS [custid], 
 [Customer].companyname AS [companyname], 
 [Order].orderid AS [orderid], 
 [Order].orderdate AS [orderdate]
FROM Sales.Customers AS [Customer]
 INNER JOIN Sales.Orders AS [Order]
  ON [Customer].custid = [Order].custid
WHERE 1 = 2
FOR XML AUTO, ELEMENTS, 
  XMLSCHEMA('TK461-CustomersOrders');
GO

-- FOR XML

-- FOR XML RAW
-- Basic
SELECT Customer.custid, Customer.companyname, 
 [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
 INNER JOIN Sales.Orders AS [Order]
  ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
  AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW;
-- Enhanced
SELECT Customer.custid, Customer.companyname, 
 [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
 INNER JOIN Sales.Orders AS [Order]
  ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
  AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW('Order'), ROOT('CustomersOrders');
GO

-- FOR XML AUTO
-- Element-centric, with namespace, root element
WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid], 
 [co:Customer].companyname AS [co:companyname], 
 [co:Order].orderid AS [co:orderid], 
 [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
 INNER JOIN Sales.Orders AS [co:Order]
  ON [co:Customer].custid = [co:Order].custid
WHERE [co:Customer].custid <= 2
  AND [co:Order].orderid %2 = 0
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');
-- XML schema
SELECT [Customer].custid AS [custid], 
 [Customer].companyname AS [companyname], 
 [Order].orderid AS [orderid], 
 [Order].orderdate AS [orderdate]
FROM Sales.Customers AS [Customer]
 INNER JOIN Sales.Orders AS [Order]
  ON [Customer].custid = [Order].custid
WHERE 1 = 2
FOR XML AUTO, ELEMENTS, 
    XMLSCHEMA('TK461-CustomersOrders');
GO

-- FOR XML PATH
SELECT Customer.custid AS [@custid],
 Customer.companyname AS [companyname]
FROM Sales.Customers AS Customer
WHERE Customer.custid <= 2
ORDER BY Customer.custid
FOR XML PATH ('Customer'), ROOT('Customers');
GO


-- OPENXML
-- Rowset description in WITH clause, different mappings
DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(1000);
SET @XmlDocument = N'
<CustomersOrders>
  <Customer custid="1">
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
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2006-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10926">
      <orderdate>2008-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';
-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;
-- Attribute-centric mapping
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',1)
     WITH (custid INT,
           companyname NVARCHAR(40));
-- Element-centric mapping
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',2)
     WITH (custid INT,
           companyname NVARCHAR(40));
-- Attribute- and element-centric mapping
-- Combining flag 8 with flags 1 and 2
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',11)
     WITH (custid INT,
           companyname NVARCHAR(40));
-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO


---------------------------------------------------------------------
-- Lesson 02 - Querying XML Data with XQuery
---------------------------------------------------------------------

-- Sequences
DECLARE @x AS XML;
SET @x=N'
<root>
 <a>1<c>3</c><d>4</d></a>
 <b>2</b>
</root>';
SELECT 
 @x.query('*') AS Complete_Sequence,
 @x.query('data(*)') AS Complete_Data,
 @x.query('data(root/a/c)') AS Element_c_Data;
GO

-- Namespace declaration
DECLARE @x AS XML;
SET @x='
<CustomersOrders xmlns:co="TK461-CustomersOrders">
  <co:Customer co:custid="1" co:companyname="Customer NRZBB">
    <co:Order co:orderid="10692" co:orderdate="2007-10-03T00:00:00" />
    <co:Order co:orderid="10702" co:orderdate="2007-10-13T00:00:00" />
    <co:Order co:orderid="10952" co:orderdate="2008-03-16T00:00:00" />
  </co:Customer>
  <co:Customer co:custid="2" co:companyname="Customer MLTDN">
    <co:Order co:orderid="10308" co:orderdate="2006-09-18T00:00:00" />
    <co:Order co:orderid="10926" co:orderdate="2008-03-04T00:00:00" />
  </co:Customer>
</CustomersOrders>';
-- Namespace in prolog of XQuery
SELECT @x.query('
(: explicit namespace :)
declare namespace co="TK461-CustomersOrders";
//co:Customer[1]/*') AS [Explicit namespace];
-- Default namespace for all elements in prolog of XQuery
SELECT @x.query('
(: default namespace :)
declare default element namespace "TK461-CustomersOrders";
//Customer[1]/*') AS [Default element namespace];
-- Namespace defined in WITH clause of T-SQL SELECT
WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT @x.query('
(: namespace declared in T-SQL :)
//co:Customer[1]/*') AS [Namespace in WITH clause];
GO

-- XQuery Functions
DECLARE @x AS XML;
SET @x='
<CustomersOrders>
  <Customer custid="1" companyname="Customer NRZBB">
    <Order orderid="10692" orderdate="2007-10-03T00:00:00" />
    <Order orderid="10702" orderdate="2007-10-13T00:00:00" />
    <Order orderid="10952" orderdate="2008-03-16T00:00:00" />
  </Customer>
  <Customer custid="2" companyname="Customer MLTDN">
    <Order orderid="10308" orderdate="2006-09-18T00:00:00" />
    <Order orderid="10926" orderdate="2008-03-04T00:00:00" />
  </Customer>
</CustomersOrders>';
SELECT @x.query('
for $i in //Customer
return
   <OrdersInfo>
      { $i/@companyname }
      <NumberOfOrders>
		  { count($i/Order) }
      </NumberOfOrders>
      <LastOrder>
		  { max($i/Order/@orderid) }
	  </LastOrder>
   </OrdersInfo>
');
GO

-- Predicates on Sequences
-- General comparison operators
DECLARE @x AS XML = N'';				
SELECT @x.query('(1, 2, 3) = (2, 4)');	-- true
SELECT @x.query('(5, 6) < (2, 4)');	    -- false
SELECT @x.query('(1, 2, 3) = 1');		-- true
SELECT @x.query('(1, 2, 3) != 1');	    -- true
GO
-- Value comparison operators
DECLARE @x AS XML = N'';				
SELECT @x.query('(5) lt (2)');			-- false
SELECT @x.query('(1) eq 1');			-- true	
SELECT @x.query('(1) ne 1');			-- false
GO
DECLARE @x AS XML = N'';
SELECT @x.query('(2, 2) eq (2, 2)');	-- error
GO

-- Conditional expressions
DECLARE @x AS XML = N'
<Employee empid="2">
  <FirstName>fname</FirstName>
  <LastName>lname</LastName>
</Employee>
';
DECLARE @v AS NVARCHAR(20) = N'FirstName';
SELECT @x.query('
 if (sql:variable("@v")="FirstName") then
  /Employee/FirstName
 else
   /Employee/LastName
') AS FirstOrLastName;
GO

-- FLWOR Expressions
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
SELECT @x.query('for $i in CustomersOrders/Customer/Order
                 let $j := $i/orderdate
                 where $i/@orderid < 10900
                 order by ($j)[1]
                 return 
                 <Order-orderid-element>
                  <orderid>{data($i/@orderid)}</orderid>
                  {$j}
                 </Order-orderid-element>')
       AS [Filtered, sorted and reformatted orders with let clause];
GO


---------------------------------------------------------------------
-- Lesson 03 - Using the XML Data Type
---------------------------------------------------------------------

USE TSQL2012;
-- Using the XML Data Type for Dynamic Schema
ALTER TABLE Production.Products
 ADD additionalattributes XML NULL;
GO

-- Auxiliary tables
CREATE TABLE dbo.Beverages 
( 
  percentvitaminsRDA INT 
); 
CREATE TABLE dbo.Condiments 
( 
  shortdescription NVARCHAR(50)
); 
GO 
-- Store the Schemas in a Variable and Create the Collection 
DECLARE @mySchema NVARCHAR(MAX); 
SET @mySchema = N''; 
SET @mySchema = @mySchema + 
  (SELECT * 
   FROM Beverages 
   FOR XML AUTO, ELEMENTS, XMLSCHEMA('Beverages')); 
SET @mySchema = @mySchema + 
  (SELECT * 
   FROM Condiments 
   FOR XML AUTO, ELEMENTS, XMLSCHEMA('Condiments')); 
SELECT CAST(@mySchema AS XML);
CREATE XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes AS @mySchema; 
GO 
-- Drop Auxiliary Tables 
DROP TABLE dbo.Beverages, dbo.Condiments;
GO

-- Validate XML instances
ALTER TABLE Production.Products 
  ALTER COLUMN additionalattributes
   XML(dbo.ProductsAdditionalAttributes);
GO

-- Function to Retrieve the Namespace
CREATE FUNCTION dbo.GetNamespace(@chkcol XML)
 RETURNS NVARCHAR(15)
AS
BEGIN
 RETURN @chkcol.value('namespace-uri((/*)[1])','NVARCHAR(15)')
END;
GO
-- Function to Retrieve the Category Name
CREATE FUNCTION dbo.GetCategoryName(@catid INT)
 RETURNS NVARCHAR(15)
AS
BEGIN
 RETURN 
  (SELECT categoryname 
   FROM Production.Categories
   WHERE categoryid = @catid)
END;
GO
-- Add the Constraint
ALTER TABLE Production.Products ADD CONSTRAINT ck_Namespace
 CHECK (dbo.GetNamespace(additionalattributes) = 
        dbo.GetCategoryName(categoryid));
GO

-- Valid Data
-- Beverage
UPDATE Production.Products 
   SET additionalattributes = N'
<Beverages xmlns="Beverages"> 
  <percentvitaminsRDA>27</percentvitaminsRDA> 
</Beverages>'
WHERE productid = 1; 
-- Condiment
UPDATE Production.Products 
   SET additionalattributes = N'
<Condiments xmlns="Condiments"> 
  <shortdescription>very sweet</shortdescription> 
</Condiments>'
WHERE productid = 3; 
GO

-- Invalid Data
-- String instead of int
UPDATE Production.Products 
   SET additionalattributes = N'
<Beverages xmlns="Beverages"> 
  <percentvitaminsRDA>twenty seven</percentvitaminsRDA> 
</Beverages>'
WHERE productid = 1; 
-- Wrong namespace
UPDATE Production.Products 
   SET additionalattributes = N'
<Condiments xmlns="Condiments"> 
  <shortdescription>very sweet</shortdescription> 
</Condiments>'
WHERE productid = 2; 
-- Wrong element
UPDATE Production.Products 
   SET additionalattributes = N'
<Condiments xmlns="Condiments"> 
  <unknownelement>very sweet</unknownelement> 
</Condiments>'
WHERE productid = 3;
GO

-- Clean up
ALTER TABLE Production.Products
 DROP CONSTRAINT ck_Namespace;
ALTER TABLE Production.Products
 DROP COLUMN additionalattributes;
DROP XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes;
DROP FUNCTION dbo.GetNamespace;
DROP FUNCTION dbo.GetCategoryName;
GO

