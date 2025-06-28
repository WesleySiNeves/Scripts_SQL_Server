-- ===================================================================
-- Chapter 8: Creating Tables and Enforcing Data Integrity
-- ===================================================================

-- -------------------------------------------------------------------
-- Lesson 1: Creating a table
-- -------------------------------------------------------------------
-- Syntax of CREATE TABLE
CREATE TABLE 
    [ database_name . [ schema_name ] . | schema_name . ] table_name 
    [ AS FileTable ]
    ( { <column_definition> | <computed_column_definition> 
        | <column_set_definition> | [ <table_constraint> ] [ ,...n ] } )
    [ ON { partition_scheme_name ( partition_column_name ) | filegroup 
        | "default" } ] 
    [ { TEXTIMAGE_ON { filegroup | "default" } ] 
    [ FILESTREAM_ON { partition_scheme_name | filegroup 
        | "default" } ]
    [ WITH ( <table_option> [ ,...n ] ) ]
[ ; ]

-- Sample table
CREATE TABLE Production.Categories(
	categoryid INT IDENTITY(1,1) NOT NULL,
	categoryname NVARCHAR(15) NOT NULL,
	description NVARCHAR(200) NOT NULL)
GO
SELECT TOP (10) categoryname FROM Production.Categories;

-- Creating a schema
CREATE SCHEMA Production AUTHORIZATION dbo;
GO

-- The following statement moves the Production.Categories table to the Sales database schema:
ALTER SCHEMA Sales TRANSFER Production.Categories;
-- To move the table back, issue:
ALTER SCHEMA Production TRANSFER Sales.Categories;

-- Naming Tables and Columns 
-- For example, you could create a table as follows:
	CREATE TABLE Production.[Yesterday's News]
-- Or you could write this way:
	CREATE TABLE Production."Tomorrow's Schedule"

-- -- NULL and Default Values
-- Example of a default value
CREATE TABLE Production.Categories(
	categoryid INT IDENTITY(1,1) NOT NULL,
	categoryname NVARCHAR(15) NOT NULL,
	description NVARCHAR(200) NOT NULL DEFAULT ('')
	) ON [PRIMARY];
GO

-- The Identity Property and Sequence Numbers
-- The most common values for seed and increment are (1,1) as in the TSQL2012 Production.Categories table:
CREATE TABLE Production.Categories(
	categoryid INT IDENTITY(1,1) NOT NULL,
	…
-- Computed Columns
-- You could compute this in a SELECT statement:
SELECT TOP (10) orderid, productid, unitprice, qty, 
	unitprice * qty AS initialcost -- expression
FROM Sales.OrderDetails;

-- You can take that expression, unitprice * qty AS initialcost, and embed it in the CREATE TABLE statement as a computed column. For example,
CREATE TABLE Sales.OrderDetails
(
  orderid   INT           NOT NULL,
…
  initialcost AS unitprice * qty -- computed column
);

-- Table Compression
-- The following command will add row-level compression to the Production.OrderDetails table as part of the CREATE TABLE statement:
CREATE TABLE Sales.OrderDetails
(
  orderid   INT           NOT NULL,
…
  ) 
	WITH (DATA_COMPRESSION = ROW);
-- You can also ALTER a table to set its compression:
ALTER TABLE Sales.OrderDetails
REBUILD WITH (DATA_COMPRESSION = PAGE);

-- -------------------------------------------------------------------
-- Lesson 2: Using Constraints
-- -------------------------------------------------------------------
-- Primary Key Constraints
-- For example, consider again the TSQL2012 table Production.Categories. This is how it is defined in the TSQL2012.SQL script:
CREATE TABLE Production.Categories
(
  categoryid   INT           NOT NULL IDENTITY,
  categoryname NVARCHAR(15)  NOT NULL,
  description  NVARCHAR(200) NOT NULL,
  CONSTRAINT PK_Categories PRIMARY KEY(categoryid)
);

--Another way of declaring a column as a primary key is to use the ALTER TABLE statement, which you could write as follows:
USE TSQL2012;
ALTER TABLE Production.Categories 
	ADD CONSTRAINT PK_Categories PRIMARY KEY(categoryid);
GO

-- To list the primary key constraints in a database, you can query the sys.key_constraints table filtering on a type of PK:
SELECT * 
FROM sys.key_constraints 
WHERE type = 'PK';
-- Also you can find the unique index that SQL Server uses to enforce a primary key constraint by querying sys.indexes.
SELECT * 
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'Production.Categories', 'U') AND name = 'PK_Categories';

-- Unique Constraints
USE TSQL2012;
ALTER TABLE Production.Categories 
	ADD CONSTRAINT UC_Categories UNIQUE (categoryname);
GO
SELECT * 
FROM sys.key_constraints 
WHERE type = 'UQ';

-- Foreign Key Constraints
USE TSQL2012
GO
ALTER TABLE Production.[Products]  WITH CHECK 
	ADD  CONSTRAINT [FK_Products_Categories] FOREIGN KEY(categoryid)
	REFERENCES Production.Categories (categoryid)
GO
SELECT P.[productname], C.categoryname
FROM Production.[Products] AS P
JOIN Production.Categories AS C
	ON P.categoryid = C.categoryid;
SELECT * 
FROM sys.foreign_keys
WHERE name = 'FK_Products_Categories';

-- Check Constraints
ALTER TABLE Production.[Products]  WITH CHECK 
	ADD  CONSTRAINT [CHK_Products_unitprice] 
	CHECK  (unitprice>=0);
GO
SELECT *
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'Production.Products', N'U');

-- Default Constraints
CREATE TABLE Production.Products
(
  productid    INT          NOT NULL IDENTITY,
  productname  NVARCHAR(40) NOT NULL,
  supplierid   INT          NOT NULL,
  categoryid   INT          NOT NULL,
  unitprice    MONEY        NOT NULL
    CONSTRAINT DFT_Products_unitprice DEFAULT(0),
  discontinued BIT          NOT NULL 
    CONSTRAINT DFT_Products_discontinued DEFAULT(0),
…
);
SELECT * 
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID(N'Production.Products', 'U');
