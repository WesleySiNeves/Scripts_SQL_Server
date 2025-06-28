---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 2 - Query Data with Advanced Transact-SQL Components
-- Skill 2.2: Query data by using table expressions
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Derived Tables
---------------------------------------------------------------------

-- row numbers for products
-- partitioned by categoryid, ordered by unitprice, productid
USE TSQLV4;

SELECT
  ROW_NUMBER() OVER(PARTITION BY categoryid
                    ORDER BY unitprice, productid) AS rownum,
  categoryid, productid, productname, unitprice
FROM Production.Products;

-- two products with lowest prices per category
SELECT D.categoryid,
       D.productid,
       D.productname,
       D.unitprice
  FROM (   SELECT ROW_NUMBER() OVER (PARTITION BY Products.categoryid
                                         ORDER BY Products.unitprice,
                                                  Products.productid) AS rownum,
                  Products.categoryid,
                  Products.productid,
                  Products.productname,
                  Products.unitprice
             FROM Production.Products) AS D
 WHERE D.rownum <= 2;

---------------------------------------------------------------------
-- CTEs
---------------------------------------------------------------------

-- two products with lowest prices per category
WITH C
  AS (SELECT ROW_NUMBER() OVER (PARTITION BY Products.categoryid
                                    ORDER BY Products.unitprice,
                                             Products.productid) AS rownum,
             Products.categoryid,
             Products.productid,
             Products.productname,
             Products.unitprice
        FROM Production.Products)
SELECT C.categoryid,
       C.productid,
       C.productname,
       C.unitprice
  FROM C
 WHERE C.rownum <= 2;


-- Recursive CTE
-- management chain leading to given employee
WITH EmpsCTE
  AS (SELECT Employees.empid,
             Employees.mgrid,
             Employees.firstname,
             Employees.lastname,
             0 AS distance
        FROM HR.Employees
       WHERE Employees.empid = 9
      UNION ALL
      SELECT M.empid,
             M.mgrid,
             M.firstname,
             M.lastname,
             S.distance + 1 AS distance
			 /*Aqui e a parte mais importante*/
        FROM EmpsCTE AS S 
		JOIN HR.Employees AS M
          ON S.mgrid = M.empid)
SELECT EmpsCTE.empid,
       EmpsCTE.mgrid,
       EmpsCTE.firstname,
       EmpsCTE.lastname,
       EmpsCTE.distance
  FROM EmpsCTE;
GO

---------------------------------------------------------------------
-- Views
---------------------------------------------------------------------

-- view representing ranked products per category by unitprice
DROP VIEW IF EXISTS Sales.RankedProducts;
GO
CREATE VIEW Sales.RankedProducts
AS
SELECT ROW_NUMBER() OVER (PARTITION BY Products.categoryid
                              ORDER BY Products.unitprice,
                                       Products.productid) AS rownum,
       Products.categoryid,
       Products.productid,
       Products.productname,
       Products.unitprice
  FROM Production.Products;
GO

SELECT categoryid, productid, productname, unitprice
FROM Sales.RankedProducts
WHERE rownum <= 2;

---------------------------------------------------------------------
-- Inline Table-Valued Functions
---------------------------------------------------------------------

-- ==================================================================
--Observação: Criando uma View Recursiva
/*
 */
-- ==================================================================


GO

DROP  VIEW IF EXISTS GetManegers
GO 

 CREATE  VIEW  GetManegers AS 
  
 -- Recursive CTE
-- management chain leading to given employee
WITH EmpsCTE
  AS (SELECT Employees.empid,
             Employees.mgrid,
             Employees.firstname,
             Employees.lastname,
             0 AS distance
        FROM HR.Employees
       WHERE Employees.empid = 9
      UNION ALL
      SELECT M.empid,
             M.mgrid,
             M.firstname,
             M.lastname,
             S.distance + 1 AS distance
			 /*Aqui e a parte mais importante*/
        FROM EmpsCTE AS S 
		JOIN HR.Employees AS M
          ON S.mgrid = M.empid)
SELECT EmpsCTE.empid,
       EmpsCTE.mgrid,
       EmpsCTE.firstname,
       EmpsCTE.lastname,
       EmpsCTE.distance
  FROM EmpsCTE;
GO
		
 
 


-- management chain leading to given employee
DROP FUNCTION IF EXISTS HR.GetManagers;
GO
CREATE FUNCTION HR.GetManagers (@empid AS INT)
RETURNS TABLE
AS RETURN
WITH EmpsCTE
  AS (SELECT Employees.empid,
             Employees.mgrid,
             Employees.firstname,
             Employees.lastname,
             0 AS distance
        FROM HR.Employees
       WHERE Employees.empid = @empid
      UNION ALL
      SELECT M.empid,
             M.mgrid,
             M.firstname,
             M.lastname,
             S.distance + 1 AS distance
        FROM EmpsCTE AS S
        JOIN HR.Employees AS M
          ON S.mgrid = M.empid)
SELECT EmpsCTE.empid,
       EmpsCTE.mgrid,
       EmpsCTE.firstname,
       EmpsCTE.lastname,
       EmpsCTE.distance
  FROM EmpsCTE;
GO

SELECT *
FROM HR.GetManagers(9) AS M;


SELECT *
FROM dbo.GetManegers AS GM
WHERE GM.empid = 9

-- cleanup
DROP VIEW IF EXISTS Sales.RankedProducts;
DROP FUNCTION IF EXISTS HR.GetManagers;