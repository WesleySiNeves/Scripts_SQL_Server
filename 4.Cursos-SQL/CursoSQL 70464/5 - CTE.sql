-- Demonstration 5 - CTE

-- Step 1: Open a new query window to the TSQL database
USE TSQL;
GO
-- Step 2: Common Table Expressions
-- -- Select this query and execute it to show CTE Examples
WITH CTE_year
  AS (SELECT YEAR(Orders.orderdate) AS orderyear,
             Orders.custid
        FROM Sales.Orders)
SELECT CTE_year.orderyear,
       COUNT(DISTINCT CTE_year.custid) AS cust_count
  FROM CTE_year
 GROUP BY CTE_year.orderyear;

-- Step 3 Recursive CTE
WITH EmpOrg_CTE
  AS (SELECT Employees.empid,
             Employees.mgrid,
             Employees.lastname,
             Employees.firstname --anchor query
        FROM HR.Employees
       WHERE Employees.empid = 5 -- starting "top" of tree. Change this to show other root employees

      UNION ALL
      SELECT child.empid,
             child.mgrid,
             child.lastname,
             child.firstname -- recursive member which refers back to CTE
        FROM EmpOrg_CTE AS parent
        JOIN HR.Employees AS child
          ON child.mgrid = parent.empid)
SELECT EmpOrg_CTE.empid,
       EmpOrg_CTE.mgrid,
       EmpOrg_CTE.lastname,
       EmpOrg_CTE.firstname
  FROM EmpOrg_CTE;