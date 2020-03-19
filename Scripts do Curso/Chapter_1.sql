

DROP DATABASE IF EXISTS ExamBook762Ch2 
GO

USE master
GO
CREATE DATABASE ExamBook762Ch2 
GO
USE ExamBook762Ch2
GO

--Skill 1.1: Design and implement a relational database schema

----Writing table create statements

CREATE SCHEMA  Examples;
GO --CREATE SCHEMA must be the only statement in the batch

GO
DROP TABLE IF EXISTS Examples.Widget
 

CREATE TABLE  Examples.Widget
(
    WidgetCode  varchar(10) NOT NULL
           CONSTRAINT PKWidget PRIMARY KEY,
    WidgetName  varchar(100) NULL
);
GO

CREATE TABLE Examples.Widget
(
    WidgetCode  varchar(10) NOT NULL CONSTRAINT PKWidget PRIMARY KEY,
    WidgetName  varchar(100) NULL
) ON FileGroupName;
GO

--Determining the most efficient data types to use
CREATE TABLE Examples.Company
(
	CompanyName    varchar(50) NOT NULL
                      CONSTRAINT PKCompany PRIMARY KEY 
);
GO


CREATE TABLE Examples.Payment
(
	PaymentNumber char(10) NOT NULL
                      CONSTRAINT PKPayment PRIMARY KEY,
	Amount int NOT NULL
);
GO

------Computed Columns

CREATE TABLE Examples.ComputedColumn
(
     FirstName  nvarchar(50) NULL,
     LastName   nvarchar(50) NOT NULL,
     FullName AS CONCAT(LastName,',' + FirstName) 
);
GO

ALTER TABLE Examples.ComputedColumn DROP COLUMN FullName;

ALTER TABLE Examples.ComputedColumn
   ADD FullName AS CONCAT(LastName,', ' + FirstName) PERSISTED;
GO


INSERT INTO Examples.ComputedColumn
VALUES (NULL,'Harris'),('Waleed','Heloo');
GO

SELECT *
FROM   Examples.ComputedColumn;
GO

------Dynamic Data Masking

CREATE TABLE Examples.DataMasking
( 
    FirstName    nvarchar(50) NULL, 
    LastName    nvarchar(50) NOT NULL, 
    PersonNumber char(10) NOT NULL, 
    Status    varchar(10), --domain of values ('Active','Inactive','New')
    EmailAddress nvarchar(50) NULL, --(real email address ought to be longer)
    BirthDate date NOT NULL, --Time we first saw this person. 
    CarCount   tinyint NOT NULL --just a count we can mask
);

INSERT INTO Examples.DataMasking(FirstName,LastName,PersonNumber, Status, 
                                 EmailAddress, BirthDate, CarCount)
VALUES('Jay','Hamlin','0000000014','Active','jay@litwareinc.com','1979-01-12',0), 
    ('Darya','Popkova','0000000032','Active','darya.p@proseware.net','1980-05-22', 1), 
    ('Tomasz','Bochenek','0000000102','Active',NULL, '1959-03-30', 1);
GO

SELECT * FROM  Examples.DataMasking AS DM


CREATE USER MaskedView WITHOUT LOGIN;
GRANT SELECT ON Examples.DataMasking TO MaskedView;
GO

ALTER TABLE Examples.DataMasking ALTER COLUMN FirstName
    ADD MASKED WITH (FUNCTION = 'default()');
ALTER TABLE Examples.DataMasking ALTER COLUMN BirthDate
    ADD MASKED WITH (FUNCTION = 'default()');
GO

ALTER TABLE Examples.DataMasking ALTER COLUMN EmailAddress
    ADD MASKED WITH (FUNCTION = 'email()');
GO

--Note that it uses double quotes in the function call
ALTER TABLE Examples.DataMasking ALTER COLUMN PersonNumber
    ADD MASKED WITH (FUNCTION = 'partial(2,"*******",1)'); 
GO

ALTER TABLE Examples.DataMasking ALTER COLUMN LastName
    ADD MASKED WITH (FUNCTION = 'partial(3,"_____",2)');
GO

ALTER TABLE Examples.DataMasking ALTER COLUMN Status
    ADD MASKED WITH (Function = 'partial(0,"Unknown",0)');
GO

ALTER TABLE Examples.DataMasking ALTER COLUMN CarCount
    ADD MASKED WITH (FUNCTION = 'random(1,3)');
GO

SELECT *
FROM   Examples.DataMasking;
GO

EXECUTE AS USER = 'MaskedView';
SELECT *
FROM   Examples.DataMasking;
GO


REVERT; SELECT USER_NAME();

--Skill 1.2: Design and implement indexes

----Design new indexes based on provided tables, queries, or plans; 

------Indexing during the database design phase
CREATE TABLE Examples.UniquenessConstraint
(
    PrimaryUniqueValue int NOT NULL,
    AlternateUniqueValue1 int NULL,
    AlternateUniqueValue2 int NULL
);
GO

ALTER TABLE Examples.UniquenessConstraint
    ADD CONSTRAINT PKUniquenessContraint PRIMARY KEY (PrimaryUniqueValue);
GO

ALTER TABLE Examples.UniquenessConstraint
    ADD CONSTRAINT AKUniquenessContraint UNIQUE 
          (AlternateUniqueValue1, AlternateUniqueValue2);
GO

INSERT INTO Examples.UniquenessConstraint
            (PrimaryUniqueValue, AlternateUniqueValue1, AlternateUniqueValue2)
VALUES (1, NULL, NULL), (2, NULL, NULL);
GO

/*
Msg 2627, Level 14, State 1, Line 169
Violation of UNIQUE KEY constraint 'AKUniquenessContraint'. Cannot insert duplicate key in object 'Examples.UniquenessConstraint'. The duplicate key value is (<NULL>, <NULL>).
The statement has been terminated.
*/

--Represents an order a person makes, there are 10,000,000 + rows in this table
CREATE TABLE Examples.Invoice
(
    InvoiceId   int NOT NULL CONSTRAINT PKInvoice PRIMARY KEY,
    --Other Columns Omitted
);

--Represents a type of discount the office gives a customer,
--there are 200 rows in this table
CREATE TABLE Examples.DiscountType
(
    DiscountTypeId   int NOT NULL CONSTRAINT PKDiscountType PRIMARY KEY,
    --Other Columns Omitted
)
GO

--Represents the individual items that a customer has ordered, There is an average of 
--3 items ordered per invoice, so there are over 30,000,000 rows in this table
CREATE TABLE Examples.InvoiceLineItem
(
   InvoiceLineItemId int NOT NULL CONSTRAINT PKInvoiceLineItem PRIMARY KEY,
   InvoiceId int NOT NULL
          CONSTRAINT FKInvoiceLineItem$Ref$Invoice
                REFERENCES Examples.Invoice (InvoiceId),
   DiscountTypeId int NOT NULL
          CONSTRAINT FKInvoiceLineItem$Ref$DiscountType
                REFERENCES Examples.DiscountType (DiscountTypeId)
    --Other Columns Omitted
);
GO

CREATE INDEX InvoiceId ON Examples.InvoiceLineItem (InvoiceId);
GO

CREATE INDEX DiscountTypeId ON Examples.InvoiceLineItem(DiscountTypeId) 
                                           WHERE DiscountTypeId IS NOT NULL;
GO
CREATE UNIQUE INDEX InvoiceColumns ON Examples.InvoiceLineItem(InvoiceId, 
                                                               InvoiceLineItemId); 
GO

USE WideWorldImporters -- Get from https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
GO

SELECT PaymentMethodId, COUNT(*) AS NumRows
FROM   Sales.CustomerTransactions
GROUP  BY PaymentMethodID;
GO

SELECT *
FROM   Sales.CustomerTransactions
WHERE PaymentMethodID = 4;
GO


------Indexing once data is in your tables

--------Common search paths discovered during development

SELECT CustomerID, OrderID, OrderDate, ExpectedDeliveryDate
FROM  Sales.Orders
WHERE CustomerPurchaseOrderNumber = '16374';
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT CustomerID, OrderId, OrderDate, ExpectedDeliveryDate
FROM  Sales.Orders
WHERE CustomerPurchaseOrderNumber = '16374';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

DROP INDEX IF EXISTS CustomerPurchaseOrderNumber ON Sales.Orders

CREATE INDEX CustomerPurchaseOrderNumber ON Sales.Orders(CustomerPurchaseOrderNumber);
GO

SELECT CONCAT(OBJECT_SCHEMA_NAME(object_id), '.', OBJECT_NAME(object_id)) AS TableName,
       name AS ColumnName, COLUMNPROPERTYEX(object_id, name, 'IsIndexable') AS Indexable
FROM   sys.columns
WHERE is_computed = 1;
GO

--------- JOINS

DROP INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT OrderId, OrderDate, ExpectedDeliveryDate, People.FullName
FROM  Sales.Orders
        JOIN Application.People
            ON People.PersonID = Orders.ContactPersonID
WHERE  People.PreferredName = 'Aakriti' OPTION(RECOMPILE);

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


CREATE INDEX FK_Sales_Orders_ContactPersonID ON Sales.Orders
--Note that USERDATA is a filegroup where the index was originally
              (ContactPersonID ASC ) ON USERDATA; 
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT OrderId, OrderDate, ExpectedDeliveryDate, People.FullName
FROM  Sales.Orders
        JOIN Application.People
            ON People.PersonID = Orders.ContactPersonID
WHERE  People.PreferredName = 'Aakriti';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

CREATE INDEX PreferredName ON Application.People (PreferredName) ON USERDATA;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT OrderId, OrderDate, ExpectedDeliveryDate, People.FullName
FROM  Sales.Orders
        JOIN Application.People
            ON People.PersonID = Orders.ContactPersonID
WHERE  People.PreferredName = 'Aakriti';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

--------SORTS

DROP INDEX [SalespersonPersonID_OrderDate] ON [Sales].[Orders]

DBCC DROPCLEANBUFFERS 
CHECKPOINT ;

SET STATISTICS TIME ON;
SET STATISTICS IO ON;


SELECT SalespersonPersonId, OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonId ASC, OrderDate ASC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

CREATE INDEX SalespersonPersonID_OrderDate ON Sales.Orders 
                              (SalespersonPersonID ASC, OrderDate ASC);
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT SalespersonPersonId, OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonId ASC, OrderDate ASC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

SELECT SalespersonPersonId, OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonId DESC, OrderDate DESC;
GO

SELECT COUNT(*) FROM Sales.Orders AS O
SELECT COUNT(*) FROM Application.People AS P

SELECT Orders.ContactPersonID, People.PersonID
FROM   Sales.Orders
         INNER JOIN Application.People
            ON Orders.ContactPersonID = People.PersonID;
GO


----Distinguish between indexed columns and included columns

--DROP INDEX ContactPersonID_Include_OrderDate_ExpectedDeliveryDate ON Sales.Orders

DROP INDEX PreferredName_Include_FullName ON Application.People;

SET STATISTICS TIME ON;
SET STATISTICS IO ON;


SELECT OrderId, OrderDate, ExpectedDeliveryDate, People.FullName
FROM  Sales.Orders
        JOIN Application.People
            ON People.PersonID = Orders.ContactPersonID
WHERE  People.PreferredName = 'Aakriti';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT Orders.ContactPersonId, People.PreferredName
FROM  Sales.Orders
        JOIN Application.People
            ON People.PersonID = Orders.ContactPersonID
WHERE  People.PreferredName = 'Aakriti';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

CREATE NONCLUSTERED INDEX ContactPersonID_Include_OrderDate_ExpectedDeliveryDate
ON Sales.Orders ( ContactPersonID ) 
INCLUDE ( OrderDate,ExpectedDeliveryDate)
ON USERDATA;
GO

DROP INDEX PreferredName ON Application.People;
GO


CREATE NONCLUSTERED INDEX PreferredName_Include_FullName 
ON Application.People (	PreferredName )
INCLUDE (FullName)
ON USERDATA;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;


SELECT OrderId, OrderDate, ExpectedDeliveryDate, People.FullName
FROM  Sales.Orders
        JOIN Application.People
            ON People.PersonID = Orders.ContactPersonID
WHERE  People.PreferredName = 'Aakriti';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


SELECT *
FROM   Sales.CustomerTransactions
WHERE PaymentMethodID = 4;
GO

CREATE NONCLUSTERED INDEX [IdxCustomerTransactionsPaymentMethodID]
ON [Sales].[CustomerTransactions] ([PaymentMethodID])
INCLUDE ([CustomerTransactionID],[CustomerID],[TransactionTypeID], [InvoiceID],[TransactionDate],[AmountExcludingTax],[TaxAmount],[TransactionAmount],
[OutstandingBalance],[FinalizationDate],[IsFinalized],[LastEditedBy],[LastEditedWhen])
GO

SELECT OrderDate, ExpectedDeliveryDate
FROM  Sales.Orders
WHERE OrderDate > '2015-01-01';
GO


CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [Sales].[Orders] ([OrderDate])
INCLUDE ([ExpectedDeliveryDate]);
GO


CREATE SCHEMA  Examples;
GO

 DROP TABLE IF EXISTS Examples.PurchaseOrderLines;
DROP TABLE IF EXISTS Examples.PurchaseOrders;

 

--Recommend new indexes based on query plans
--2074 Rows
SELECT *
INTO   Examples.PurchaseOrders
FROM   WideWorldImporters.Purchasing.PurchaseOrders;
GO

ALTER  TABLE Examples.PurchaseOrders
    ADD CONSTRAINT PKPurchaseOrders PRIMARY KEY (PurchaseOrderId);
GO

--8367 Rows
SELECT *
INTO   Examples.PurchaseOrderLines
FROM   WideWorldImporters.Purchasing.PurchaseOrderLines;

ALTER  TABLE Examples.PurchaseOrderLines
    ADD CONSTRAINT PKPurchaseOrderLines PRIMARY KEY (PurchaseOrderLineID);

ALTER TABLE Examples.PurchaseOrderLines 
    ADD CONSTRAINT FKPurchaseOrderLines_Ref_Examples_PurchaseOrderLines
        FOREIGN KEY (PurchaseOrderId) REFERENCES 
                                      Examples.PurchaseOrders(PurchaseOrderId);
GO


SET STATISTICS IO ON 
SELECT *
FROM   Examples.PurchaseOrders
WHERE  PurchaseOrders.OrderDate BETWEEN '2016-03-10' AND '2016-03-14';

SET STATISTICS IO OFF


SET STATISTICS IO ON 
SELECT PurchaseOrderId, ExpectedDeliveryDate
FROM   Examples.PurchaseOrders
WHERE  EXISTS (SELECT *
                FROM  Examples.PurchaseOrderLines
                WHERE PurchaseOrderLines.PurchaseOrderId = 
                                               PurchaseOrders.PurchaseOrderID)
  AND  PurchaseOrders.OrderDate BETWEEN '2016-03-10' AND '2016-03-14' ;       

  SET STATISTICS IO OFF
GO    

CREATE INDEX PurchaseOrderId ON Examples.PurchaseOrderLines (PurchaseOrderId);
GO

CREATE INDEX OrderDate ON Examples.PurchaseOrders (OrderDate);
GO

CREATE INDEX OrderDate_Incl_ExpectedDeliveryDate 
     ON Examples.PurchaseOrders (OrderDate) INCLUDE (ExpectedDeliveryDate);
GO

--Skill 1.3: Design and implement views
----Design a view structure to select data based on user or business requirements
------Using views to hide data for a particular purpose

DROP VIEW IF EXISTS Sales.Orders12MonthsMultipleItems



CREATE VIEW Sales.Orders12MonthsMultipleItems
AS
SELECT OrderId, CustomerID, SalespersonPersonID, OrderDate, ExpectedDeliveryDate
FROM   Sales.Orders
WHERE  OrderDate >= DATEADD(Month,-36,SYSDATETIME()) 
  AND (SELECT COUNT(*)
       FROM   Sales.OrderLines
       WHERE  OrderLines.OrderID = Orders.OrderID) > 1;
GO

SELECT TOP 5 *
FROM   Sales.Orders12MonthsMultipleItems
ORDER BY ExpectedDeliveryDate desc;
GO

------Using a view to reformatting data in the output
SELECT PersonId, IsPermittedToLogon, IsEmployee, IsSalesPerson
FROM   Application.People;
GO

CREATE VIEW Application.PeopleEmployeeStatus
AS
SELECT PersonId, FullName, 
       IsPermittedToLogon, IsEmployee, IsSalesPerson,
       CASE WHEN IsPermittedToLogon = 1 THEN 'Can Logon'
             ELSE 'Can''t Logon' END AS LogonRights,
       CASE WHEN IsEmployee = 1 and IsSalesPerson = 1 
                THEN 'Sales Person'
            WHEN IsEmployee = 1
                THEN 'Regular'
            ELSE 'Not Employee' END AS EmployeeType
FROM   Application.People;
GO

SELECT PersonId, LogonRights, EmployeeType
FROM   Application.PeopleEmployeeStatus;
GO

------Using a view to provide a reporting interface
CREATE SCHEMA Reports;
GO

DROP VIEW IF EXISTS Reports.InvoiceSummaryBasis;

CREATE VIEW Reports.InvoiceSummaryBasis
AS
SELECT Invoices.InvoiceId, CustomerCategories.CustomerCategoryName,
       Cities.CityName, StateProvinces.StateProvinceName,
       StateProvinces.SalesTerritory,
       Invoices.InvoiceDate,
       --the grain of the report is at the invoice, so total 
       --the amounts for invoice
       SUM(InvoiceLines.LineProfit) as InvoiceProfit,
       SUM(InvoiceLines.ExtendedPrice) as InvoiceExtendedPrice
FROM   Sales.Invoices
         JOIN Sales.InvoiceLines
            ON Invoices.InvoiceID = InvoiceLines.InvoiceID
         JOIN Sales.Customers
              ON Customers.CustomerID = Invoices.CustomerID
         JOIN Sales.CustomerCategories
              ON Customers.CustomerCategoryID = 
                               CustomerCategories.CustomerCategoryID
         JOIN Application.Cities
              ON Customers.DeliveryCityID = Cities.CityID
         JOIN Application.StateProvinces
              ON StateProvinces.StateProvinceID = Cities.StateProvinceID
GROUP BY Invoices.InvoiceId, CustomerCategories.CustomerCategoryName,
       Cities.CityName, StateProvinces.StateProvinceName,
       StateProvinces.SalesTerritory,
       Invoices.InvoiceDate;
GO


SELECT TOP 5 SalesTerritory, SUM(InvoiceProfit) AS InvoiceProfitTotal
FROM Reports.InvoiceSummaryBasis
WHERE InvoiceDate > '2016-05-01'
GROUP BY SalesTerritory
ORDER BY InvoiceProfitTotal DESC;
GO


SELECT TOP 5 StateProvinceName, CustomerCategoryName, 
       SUM(InvoiceExtendedPrice) AS InvoiceExtendedPriceTotal
FROM Reports.InvoiceSummaryBasis
WHERE InvoiceDate > '2016-05-01'
GROUP BY StateProvinceName, CustomerCategoryName
ORDER BY InvoiceExtendedPriceTotal DESC;
GO

CREATE NONCLUSTERED INDEX [InvoiceInvoiceDateInvoiceID]
         ON [Sales].[Invoices] ([InvoiceDate]) INCLUDE ([InvoiceID],[CustomerID]);
GO

----Identify the steps necessary to design an updateable view
------Modifying views that reference one table


DROP TABLE Examples.Gadget
 

CREATE TABLE Examples.Gadget
(
    GadgetId    int NOT NULL CONSTRAINT PKGadget PRIMARY KEY,
    GadgetNumber char(8) NOT NULL CONSTRAINT AKGadget UNIQUE,
    GadgetType  varchar(10) NOT NULL
);
GO

INSERT INTO Examples.Gadget(GadgetId, GadgetNumber, GadgetType)
VALUES  (1,'00000001','Electronic'),
        (2,'00000002','Manual'),
        (3,'00000003','Manual');
GO


DROP  VIEW Examples.ElectronicGadget;

CREATE VIEW Examples.ElectronicGadget
AS
    SELECT GadgetId, GadgetNumber, GadgetType, 
           UPPER(GadgetType) AS UpperGadgedType
    FROM   Examples.Gadget
    WHERE GadgetType = 'Electronic';
GO

INSERT INTO Examples.ElectronicGadget(GadgetId, GadgetNumber, 
                                      GadgetType, UpperGadgedType)
VALUES (4,'00000004','Electronic','XXXXXXXXXX'), --row we can see in view
       (5,'00000005','Manual','YYYYYYYYYY'); --row we cannot see in view
GO

/*
Msg 4406, Level 16, State 1, Line 649
Update or insert of view or function 'Examples.ElectronicGadget' failed because it contains a derived or constant field.
*/

INSERT INTO Examples.ElectronicGadget(GadgetId, GadgetNumber, GadgetType)
VALUES (4,'00000004','Electronic'),
       (5,'00000005','Manual');
GO

SELECT ElectronicGadget.GadgetNumber as FromView, Gadget.GadgetNumber as FromTable,
        Gadget.GadgetType, ElectronicGadget.UpperGadgedType
FROM   Examples.ElectronicGadget
         FULL OUTER JOIN Examples.Gadget
            ON ElectronicGadget.GadgetId = Gadget.GadgetId;
GO

--Update the row we could see to values that could not be seen
UPDATE Examples.ElectronicGadget
SET    GadgetType   = 'Manual'
WHERE  GadgetNumber = '00000004';
GO

--Update the row we could see to values that could actually see
UPDATE Examples.ElectronicGadget
SET    GadgetType   = 'Electronic'
WHERE  GadgetNumber = '00000005'; 
GO

UPDATE Examples.Gadget
SET    GadgetType   = 'Electronic'
WHERE  GadgetNumber = '00000004';
GO

------Limiting what data can be added to a table through a view through DDL
ALTER VIEW Examples.ElectronicGadget
AS
    SELECT GadgetId, GadgetNumber, GadgetType, 
           UPPER(GadgetType) AS UpperGadgetType
    FROM   Examples.Gadget
    WHERE GadgetType = 'Electronic'
    WITH CHECK OPTION; 
GO

INSERT INTO Examples.ElectronicGadget(GadgetId, GadgetNumber, GadgetType)
VALUES (6,'00000006','Manual'); 
GO

/*
The attempted insert or update failed because the target view either specifies WITH CHECK OPTION or spans a view that specifies WITH CHECK OPTION and one or more rows resulting from the operation did not qualify under the CHECK OPTION constraint.
*/

UPDATE Examples.ElectronicGadget
SET    GadgetType   = 'Manual'
WHERE  GadgetNumber = '00000004'; 
GO

DROP TABLE Examples.GadgetType;

------Modifying data in views with more than one table
CREATE TABLE Examples.GadgetType
(
    GadgetType  varchar(10) NOT NULL CONSTRAINT PKGadgetType PRIMARY KEY,
    Description varchar(200) NOT NULL
)
GO

INSERT INTO Examples.GadgetType(GadgetType, Description)
VALUES ('Manual','No batteries'),
       ('Electronic','Lots of bats');
GO

ALTER TABLE Examples.Gadget
   ADD CONSTRAINT FKGadget$ref$Examples_GadgetType
       FOREIGN KEY (GadgetType) REFERENCES Examples.GadgetType (GadgetType); 
GO

DROP VIEW Examples.GadgetExtension

CREATE VIEW Examples.GadgetExtension
AS
    SELECT Gadget.GadgetId, Gadget.GadgetNumber, 
           Gadget.GadgetType, GadgetType.GadgetType As DomainGadgetType,
           GadgetType.Description as GadgetTypeDescription
    FROM   Examples.Gadget
             JOIN Examples.GadgetType
                ON Gadget.GadgetType = GadgetType.GadgetType;
GO

INSERT INTO Examples.GadgetExtension(GadgetId, GadgetNumber, GadgetType,
                    DomainGadgetType, GadgetTypeDescription)
VALUES(7,'00000007','Acoustic','Acoustic','Sound');
GO

INSERT INTO Examples.GadgetExtension(DomainGadgetType, GadgetTypeDescription)
VALUES('Acoustic','Sound');
GO


INSERT INTO Examples.GadgetExtension(GadgetId, GadgetNumber, GadgetType)
VALUES(7,'00000007','Acoustic');
GO

SELECT *
FROM   Examples.Gadget
             JOIN Examples.GadgetType
                ON Gadget.GadgetType = GadgetType.GadgetType
WHERE  Gadget.GadgetType = 'Electronic';
GO

UPDATE Examples.GadgetExtension
SET   GadgetTypeDescription = 'Uses Batteries'
WHERE GadgetId = 1;
GO

----Implement partitioned views
DROP TABLE IF EXISTS Examples.Invoices_Region1;

DROP TABLE IF EXISTS Examples.Invoices_Region2;


CREATE TABLE Examples.Invoices_Region1
(
    InvoiceId   int NOT NULL 
        CONSTRAINT PKInvoices_Region1 PRIMARY KEY,
        CONSTRAINT CHKInvoices_Region1_PartKey 
                          CHECK (InvoiceId BETWEEN 1 and 10000),
    CustomerId  int NOT NULL,
    InvoiceDate date NOT NULL
);
GO

CREATE TABLE Examples.Invoices_Region2
(
    InvoiceId   int NOT NULL ,
	CustomerId  int NOT NULL,
    InvoiceDate date NOT NULL
        CONSTRAINT PKInvoices_Region2 PRIMARY KEY,
        CONSTRAINT CHKInvoices_Region2_PartKey 
                          CHECK (InvoiceId BETWEEN 10001 and 20000)
)
GO


CREATE VIEW Examples.InvoicesPartitioned
AS
    SELECT InvoiceId, CustomerId, InvoiceDate
    FROM   Examples.Invoices_Region1
    UNION ALL
    SELECT InvoiceId, CustomerId, InvoiceDate
    FROM   Examples.Invoices_Region2;
GO


SELECT *
FROM  Examples.InvoicesPartitioned
WHERE InvoiceId = 1;
GO

SELECT InvoiceId
FROM   Examples.InvoicesPartitioned
WHERE  InvoiceDate = '2013-01-01';
GO



SELECT *
FROM  Examples.InvoicesPartitioned
WHERE InvoiceId  <10001
GO

SELECT *
FROM  Examples.InvoicesPartitioned
WHERE InvoiceId  > 10001
GO

SELECT InvoiceId, CustomerId, InvoiceDate
FROM   Sales.Invoices_Region1
UNION ALL
SELECT InvoiceId, CustomerId, InvoiceDate
FROM   ServerName.DatabaseName.Sales.Invoices_Region2;
GO

----Implement indexed views

CREATE VIEW Sales.InvoiceCustomerInvoiceAggregates
WITH SCHEMABINDING
AS
SELECT Invoices.CustomerId,
       SUM(ExtendedPrice * Quantity) AS SumCost,
       SUM(LineProfit) AS SumProfit,
       COUNT_BIG(*) AS TotalItemCount 
FROM  Sales.Invoices
          JOIN Sales.InvoiceLines
                 ON  Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP  BY Invoices.CustomerID;
GO

SELECT *
FROM   Sales.InvoiceCustomerInvoiceAggregates;
GO

CREATE UNIQUE CLUSTERED INDEX XPKInvoiceCustomerInvoiceAggregates on
                      Sales.InvoiceCustomerInvoiceAggregates(CustomerID);
GO

SELECT Invoices.CustomerId,
       SUM(ExtendedPrice * Quantity) / SUM(LineProfit),
       COUNT(*) AS TotalItemCount
FROM  Sales.Invoices
          JOIN Sales.InvoiceLines
                 ON  Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP  BY Invoices.CustomerID;
GO

--Skill 1.4: Implement columnstore indexes
----Identify proper usage of clustered and non-clustered columnstore indexes
------Using clustered columnstore indexes on dimensional data warehouse structures

USE WideWorldImportersDW -- Get from https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
GO
/*
CREATE TABLE Fact.[Order] 
(   
   [Order Key] bigint IDENTITY(1,1) NOT NULL,
   [City Key] int NOT NULL,
   [Customer Key] int NOT NULL,
   [Stock Item Key] int NOT NULL,
   [Order Date Key] date NOT NULL,
   [Picked Date Key] date NULL,
   [Salesperson Key] int NOT NULL,
   [Picker Key] int NULL,
   [WWI Order ID] int NOT NULL,
   [WWI Backorder ID] int NULL,
   [Description] nvarchar(100) NOT NULL,
   [Package] nvarchar(50) NOT NULL,
   [Quantity] int NOT NULL,
   [Unit Price] decimal(18, 2) NOT NULL,
   [Tax Rate] decimal(18, 3) NOT NULL,
   [Total Excluding Tax] decimal(18, 2) NOT NULL,
   [Tax Amount] decimal(18, 2) NOT NULL,
   [Total Including Tax] decimal(18, 2) NOT NULL,
   [Lineage Key] int NOT NULL
);
GO


CREATE TABLE Dimension.Customer
(
   [Customer Key] int NOT NULL,
   [WWI Customer ID] int NOT NULL,
   [Customer] nvarchar(100) NOT NULL,
   [Bill To Customer] nvarchar(100) NOT NULL,
   [Category] nvarchar(50) NOT NULL,
   [Buying Group] nvarchar(50) NOT NULL,
   [Primary Contact] nvarchar(50) NOT NULL,
   [Postal Code] nvarchar(10) NOT NULL,
   [Valid From] datetime2(7) NOT NULL,
   [Valid To] datetime2(7) NOT NULL,
   [Lineage Key] int NOT NULL
);
CREATE TABLE Dimension.Date(
   Date date NOT NULL,
   [Day Number] int NOT NULL,
   [Day] nvarchar(10) NOT NULL,
   [Month] nvarchar(10) NOT NULL,
   [Short Month] nvarchar(3) NOT NULL,
   [Calendar Month Number] int NOT NULL,
   [Calendar Month Label] nvarchar(20) NOT NULL,
   [Calendar Year] int NOT NULL,
   [Calendar Year Label] nvarchar(10) NOT NULL,
   [Fiscal Month Number] int NOT NULL,
   [Fiscal Month Label] nvarchar(20) NOT NULL,
   [Fiscal Year] int NOT NULL,
   [Fiscal Year Label] nvarchar(10) NOT NULL,
   [ISO Week Number] int NOT NULL
);
GO
*/
DROP INDEX [CCX_Fact_Order] ON [Fact].[Order];
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT Customer.Category, Date.[Calendar Month Number], 
        COUNT(*) AS SalesCount, 
        SUM([Total Excluding Tax]) as SalesTotal
FROM   Fact.[Order]
         JOIN Dimension.Date
            ON Date.Date = [Order].[Order Date Key]
         JOIN Dimension.Customer
            ON Customer.[Customer Key] = [Order].[Customer Key]
GROUP BY Customer.Category, Date.[Calendar Month Number]
ORDER BY Category, Date.[Calendar Month Number], SalesCount, SalesTotal OPTION(MAXDOP 1);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

CREATE NONCLUSTERED INDEX SpecificQuery ON [Fact].[Order] ([Customer Key])
INCLUDE ([Order Date Key],[Total Excluding Tax]);
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Order] ON [Fact].[Order];
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCX_Fact_Order]
ON Fact.[Order]
(   [Order Key],
    [City Key],
    [Customer Key],
    [Stock Item Key],
    [Order Date Key],
    [Picked Date Key],
    [Salesperson Key],
    [Picker Key],
    [WWI Order ID],
    [WWI Backorder ID],
    [Package],
    [Quantity],
    [Unit Price],
    [Tax Rate],
    [Total Excluding Tax],
    [Tax Amount],
    [Total Including Tax]);


SELECT Customer.Category, Date.[Calendar Year], 
        Date.[Calendar Month Number], 
        COUNT(*) as SalesCount, 
        SUM([Total Excluding Tax]) AS SalesTotal,
        AVG([Total Including Tax]) AS AvgWithTaxTotal,
        MAX(Date.Date) AS MaxOrderDate
FROM   Fact.[Order]
         JOIN Dimension.Date
            ON Date.Date = [Order].[Order Date Key]
         JOIN Dimension.Customer
            ON Customer.[Customer Key] = [Order].[Customer Key]
GROUP BY Customer.Category, Date.[Calendar Year], Date.[Calendar Month Number]
ORDER BY Category, Date.[Calendar Month Number], SalesCount, SalesTotal;
GO

------Using non-clustered columnstore indexes on OLTP tables for advanced analytics
USE WideWorldImporters
GO
/*
CREATE TABLE Sales.InvoiceLines
(
    InvoiceLineID int NOT NULL,
    InvoiceID int NOT NULL,
    StockItemID int NOT NULL,
    Description nvarchar(100) NOT NULL,
    PackageTypeID int NOT NULL,
    Quantity int NOT NULL,
    UnitPrice decimal(18, 2) NULL,
    TaxRate decimal(18, 3) NOT NULL,
    TaxAmount decimal(18, 2) NOT NULL,
    LineProfit decimal(18, 2) NOT NULL,
    ExtendedPrice decimal(18, 2) NOT NULL,
    LastEditedBy int NOT NULL,
    LastEditedWhen datetime2(7) NOT NULL,
 CONSTRAINT PK_Sales_InvoiceLines PRIMARY KEY
              CLUSTERED ( InvoiceLineID )
 );
--Not shown: FOREIGN KEY constraints, indexes other than the PK 

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines ON Sales.OrderLines
(
    OrderID,
    StockItemID,
    Description,
    Quantity,
    UnitPrice,
    PickedQuantity
) ON USERDATA;
*/

DROP INDEX NCCX_Sales_OrderLines ON Sales.OrderLines;



-- ==================================================================
--Observação: 
/*COMPRESSION_DELAY = 0 | delay [ Minutes ]
Aplica-se a: SQL Server 2016 a SQL Server 2017.
Para uma tabela baseada em disco, delay especifica o número mínimo de minutos que um rowgroup delta no 
estado CLOSED precisa permanecer no rowgroup delta antes que o SQL Server possa compactá-lo no rowgroup compactado. Como as tabelas baseadas em disco não controlam os tempos de inserção e atualização em linhas individuais, o SQL Server aplica o atraso aos rowgroups delta no estado CLOSED.
O padrão é 0 minuto.
Para obter recomendações de quando usar COMPRESSION_DELAY,
 */
-- ==================================================================

SELECT * FROM Sales.OrderLines AS OL;

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines ON Sales.OrderLines
(
	OrderID,
	StockItemID,
	Description,
	Quantity,
	UnitPrice,
	PickedQuantity
) WITH ( COMPRESSION_DELAY = 5) ON USERDATA;
GO


--CREATE TABLE Sales.Orders
--(
--    OrderID int NOT NULL,
--    CustomerID int NOT NULL,
--    SalespersonPersonID int NOT NULL,
--    PickedByPersonID int NULL,
--    ContactPersonID int NOT NULL,
--    BackorderOrderID int NULL,
--    OrderDate date NOT NULL,
--    ExpectedDeliveryDate date NOT NULL,
--    CustomerPurchaseOrderNumber nvarchar(20) NULL,
--    IsUndersupplyBackordered bit NOT NULL,
--    Comments nvarchar(max) NULL,
--    DeliveryInstructions nvarchar(max) NULL,
--    InternalComments nvarchar(max) NULL,
--    PickingCompletedWhen datetime2(7) NULL,
--    LastEditedBy int NOT NULL,
--    LastEditedWhen datetime2(7) NOT NULL,
--    CONSTRAINT PK_Sales_Orders PRIMARY KEY CLUSTERED 
--    (
--       OrderID ASC
--    ) 
--);


-- ==================================================================
--Observação: COLUMNSTORE Index Filtrado
-- ==================================================================
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders ON Sales.Orders
(
      PickedByPersonId,
      SalespersonPersonID,
      OrderDate,
      PickingCompletedWhen
)
WHERE PickedByPersonId IS NOT NULL;

----Design standard non-clustered indexes in conjunction with clustered columnstore indexes

GO

CREATE SCHEMA Fact;


SELECT *
INTO   WideWorldImporters.Fact.SaleBase
FROM    WideWorldImportersDW.Fact.Sale;
GO

CREATE CLUSTERED COLUMNSTORE INDEX CColumnsStore ON Fact.SaleBase;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT Date.[Fiscal Year], Customer.Category,  Sum(Quantity) as NumSales
FROM   WideWorldImporters.Fact.SaleBase
         JOIN WideWorldImportersDW.Dimension.Customer
            on Customer.[Customer Key] = SaleBase.[Customer Key]
         JOIN WideWorldImportersDW.Dimension.Date
            ON Date.Date = SaleBase.[Invoice Date Key]
GROUP BY Date.[Fiscal Year], Customer.Category
ORDER BY Date.[Fiscal Year], Customer.Category;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT Date.[Fiscal Year], Customer.Category,  Sum(Quantity) as NumSales
FROM   Fact.SaleBase
         JOIN Dimension.Customer
            on Customer.[Customer Key] = SaleBase.[Customer Key]
         JOIN Dimension.Date
            ON Date.Date = SaleBase.[Invoice Date Key]
WHERE SaleBase.[Sale Key] = 26974
GROUP BY Date.[Fiscal Year], Customer.Category
ORDER BY Date.[Fiscal Year], Customer.Category;


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

CREATE UNIQUE INDEX [Sale Key] ON Fact.SaleBase ([Sale Key]);
GO

CREATE INDEX [WWI Invoice ID] ON Fact.SaleBase ([WWI Invoice ID]);
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT Date.[Fiscal Year], Customer.Category,  Sum(Quantity) as NumSales
FROM   Fact.SaleBase
         JOIN Dimension.Customer
            on Customer.[Customer Key] = SaleBase.[Customer Key]
         JOIN Dimension.Date
            ON Date.Date = SaleBase.[Invoice Date Key]
WHERE SaleBase.[Sale Key] = 26974
GROUP BY Date.[Fiscal Year], Customer.Category
ORDER BY Date.[Fiscal Year], Customer.Category;


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


----Implement columnstore index maintenance

CREATE TABLE [Fact].[SaleLimited](
       [City Key] [int] NOT NULL,
	     [Customer Key] [int] NOT NULL,
       [Bill To Customer Key] [int] NOT NULL,
       [Stock Item Key] [int] NOT NULL,
       [Invoice Date Key] [date] NOT NULL,
       [Delivery Date Key] [date] NULL,
       [Salesperson Key] [int] NOT NULL,
       [WWI Invoice ID] [int] NOT NULL,
       [Description] [nvarchar](100) NOT NULL,
       [Package] [nvarchar](50) NOT NULL,
       [Quantity] [int] NOT NULL
);

------Bulk loading data into a clustered columnstore

CREATE CLUSTERED COLUMNSTORE INDEX [CColumnStore] ON [Fact].[SaleLimited];
GO



INSERT INTO [Fact].[SaleLimited] WITH (TABLOCK)  
     ([City Key], [Customer Key],  [Bill To Customer Key], [Stock Item Key],
      [Invoice Date Key], [Delivery Date Key],[Salesperson Key],
      [WWI Invoice ID], [Description], [Package], [Quantity]) 
SELECT TOP (100000) [City Key],
       [Customer Key],
       [Bill To Customer Key],
       [Stock Item Key],
       [Invoice Date Key],
       [Delivery Date Key],
       [Salesperson Key],
       [WWI Invoice ID],
       [Description],
       [Package],
       [Quantity]
  FROM  WideWorldImportersDW.Fact.Sale
GO 3 --run this statement 3 times


-- ==================================================================
--Observação: Use ALTER INDEX REORGANIZE com a opção COMPRESS_ALL_ROW_GROUPS para forçar todos os rowgroups a serem compactados no columnstore.
-- ==================================================================

ALTER INDEX CColumnStore ON Fact.SaleLimited REORGANIZE 
                                WITH (COMPRESS_ALL_ROW_GROUPS = ON);
GO

SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO

ALTER INDEX CColumnStore ON Fact.SaleLimited REORGANIZE;
GO

SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO

TRUNCATE TABLE Fact.SaleLimited;
GO

INSERT INTO [Fact].[SaleLimited] WITH (TABLOCK)  
     ([City Key], [Customer Key],  [Bill To Customer Key], [Stock Item Key],
      [Invoice Date Key], [Delivery Date Key],[Salesperson Key],
      [WWI Invoice ID], [Description], [Package], [Quantity]) 
SELECT TOP (102400) [City Key],
       [Customer Key],
       [Bill To Customer Key],
       [Stock Item Key],
       [Invoice Date Key],
       [Delivery Date Key],
       [Salesperson Key],
       [WWI Invoice ID],
       [Description],
       [Package],
       [Quantity]
  FROM WideWorldImportersDW.Fact.Sale
OPTION (MAXDOP 1); --not in parallel
GO 3


SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO

ALTER INDEX [CColumnStore] ON [Fact].[SaleLimited] REORGANIZE;
GO

SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO


TRUNCATE TABLE Fact.SaleLimited;
GO

INSERT INTO [Fact].[SaleLimited] WITH (TABLOCK) ([City Key],
                                                 [Customer Key],
                                                 [Bill To Customer Key],
                                                 [Stock Item Key],
                                                 [Invoice Date Key],
                                                 [Delivery Date Key],
                                                 [Salesperson Key],
                                                 [WWI Invoice ID],
                                                 [Description],
                                                 [Package],
                                                 [Quantity])
SELECT TOP (5000) Sale.[City Key],
       Sale.[Customer Key],
       Sale.[Bill To Customer Key],
       Sale.[Stock Item Key],
       Sale.[Invoice Date Key],
       Sale.[Delivery Date Key],
       Sale.[Salesperson Key],
       Sale.[WWI Invoice ID],
       Sale.Description,
       Sale.Package,
       Sale.Quantity
  FROM WideWorldImportersDW.Fact.Sale;
GO

ALTER INDEX [CColumnStore] ON [Fact].[SaleLimited] REBUILD;
GO

SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO

------Non-bulk operations on a columnstore
TRUNCATE TABLE Fact.SaleLimited;
GO
INSERT INTO [Fact].[SaleLimited] ([City Key],
                                  [Customer Key],
                                  [Bill To Customer Key],
                                  [Stock Item Key],
                                  [Invoice Date Key],
                                  [Delivery Date Key],
                                  [Salesperson Key],
                                  [WWI Invoice ID],
                                  [Description],
                                  [Package],
                                  [Quantity])
SELECT TOP (100000) Sale.[City Key],
       Sale.[Customer Key],
       Sale.[Bill To Customer Key],
       Sale.[Stock Item Key],
       Sale.[Invoice Date Key],
       Sale.[Delivery Date Key],
       Sale.[Salesperson Key],
       Sale.[WWI Invoice ID],
       Sale.Description,
       Sale.Package,
       Sale.Quantity
  FROM WideWorldImportersDW.Fact.Sale;
GO

ALTER INDEX [CColumnStore] ON [Fact].[SaleLimited] REBUILD;
GO

SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO


DELETE FROM Fact.SaleLimited
WHERE  [Customer Key] = 21;
GO

SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO

UPDATE Fact.SaleLimited
SET    [Customer Key] = 35
WHERE  [Customer Key] = 22;
GO


SELECT state_desc, total_rows, deleted_rows, 
       transition_to_compressed_state_desc as transition
FROM sys.dm_db_column_store_row_group_physical_stats   
WHERE object_id  = OBJECT_ID('Fact.SaleLimited');
GO
