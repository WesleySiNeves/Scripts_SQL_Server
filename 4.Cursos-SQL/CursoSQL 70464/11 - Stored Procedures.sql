-- Demonstration 11 - Stored Procedures

-- Step 1: Open a new query window to the AdventureWorks database

USE AdventureWorks;
GO

-- Step 2: Create the GetBlueProducts stored procedure

CREATE OR ALTER PROC Production.GetBlueProducts
AS
BEGIN
  SELECT p.ProductID,
         p.Name,
         p.Size,
         p.ListPrice 
  FROM Production.Product AS p
  WHERE p.Color = N'Blue'
  ORDER BY p.ProductID;
END;
GO

-- Step 3: Execute the stored procedure

EXEC Production.GetBlueProducts;
GO

-- Step 4: Create the GetBlueProductsAndModels stored procedure

CREATE OR ALTER PROC Production.GetBlueProductsAndModels
AS
BEGIN
  SELECT p.ProductID,
         p.Name,
         p.Size,
         p.ListPrice 
  FROM Production.Product AS p
  WHERE p.Color = N'Blue'
  ORDER BY p.ProductID;
  
  SELECT p.ProductID,
         pm.ProductModelID,
         pm.Name AS ModelName
  FROM Production.Product AS p
  INNER JOIN Production.ProductModel AS pm
  ON p.ProductModelID = pm.ProductModelID 
  ORDER BY p.ProductID, pm.ProductModelID;
END;
GO

-- Step 5: Execute the GetBlueProductsAndModels stored procedure
--         Note in particular that multiple rowsets can be 
--         returned from a single stored procedure execution

EXEC Production.GetBlueProductsAndModels;
GO

-- Step 6: Now tell the students that a bug has been
--         reported in the GetBlueProductsAndModels 
--         stored procedure. See if they can find the 
--         problem

-- Step 7: The problem is that the 2nd query doesn't also
--         check that the product is blue so let's alter
--         the stored procedure to fix this

ALTER PROC Production.GetBlueProductsAndModels
AS
BEGIN
  SELECT p.ProductID,
         p.Name,
         p.Size,
         p.ListPrice 
  FROM Production.Product AS p
  WHERE p.Color = N'Blue'
  ORDER BY p.ProductID;
  
  SELECT p.ProductID,
         pm.ProductModelID,
         pm.Name AS ModelName
  FROM Production.Product AS p
  INNER JOIN Production.ProductModel AS pm
  ON p.ProductModelID = pm.ProductModelID 
  WHERE p.Color = N'Blue'
  ORDER BY p.ProductID, pm.ProductModelID;
END;
GO

-- Step 8: And re-execute the GetBlueProductsAndModels stored procedure

EXEC Production.GetBlueProductsAndModels;
GO

-- Step 9: Query sys.procedures to see the list of procedures

SELECT SCHEMA_NAME(schema_id) AS SchemaName,
       name AS ProcedureName
FROM sys.procedures;
GO



