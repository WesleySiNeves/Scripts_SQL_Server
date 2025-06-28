SET NOCOUNT ON;
USE TSQLV4;

DROP FUNCTION IF EXISTS dbo.SubtreeTotalSalaries

DROP TABLE IF EXISTS dbo.Employees;
GO
CREATE TABLE dbo.Employees (
    empid INT NOT NULL
        CONSTRAINT PK_Employees PRIMARY KEY,
    mgrid INT NULL
        CONSTRAINT FK_Employees_Employees
        REFERENCES dbo.Employees,
    empname VARCHAR(25) NOT NULL,
    salary MONEY NOT NULL,
    CHECK (empid <> mgrid));
INSERT INTO dbo.Employees (empid,
                           mgrid,
                           empname,
                           salary)
VALUES (1, NULL, 'David', $10000.00),
(2, 1, 'Eitan', $7000.00),
(3, 1, 'Ina', $7500.00),
(4, 2, 'Seraph', $5000.00),
(5, 2, 'Jiru', $5500.00),
(6, 2, 'Steve', $4500.00),
(7, 3, 'Aaron', $5000.00),
(8, 5, 'Lilach', $3500.00),
(9, 7, 'Rita', $3000.00),
(10, 5, 'Sean', $3000.00),
(11, 7, 'Gabriel', $3000.00),
(12, 9, 'Emilia', $2000.00),
(13, 9, 'Michael', $2000.00),
(14, 9, 'Didi', $1500.00);



CREATE UNIQUE INDEX idx_unc_mgr_emp_i_name_sal
ON dbo.Employees (mgrid, empid)
INCLUDE (empname, salary);


/* ==================================================================
--Data: 13/06/2018 
--Observação: Existem 3 tipos de funções
 1)Scalar user-defined functions
-- ==================================================================
*/

GO

CREATE OR ALTER FUNCTION dbo.SubtreeTotalSalaries (@mgr AS INT)
RETURNS MONEY
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @totalsalary AS MONEY;
    WITH EmpsCTE
      AS (SELECT Employees.empid,
                 Employees.salary
            FROM dbo.Employees
           WHERE Employees.empid = @mgr
          UNION ALL
          SELECT S.empid,
                 S.salary
            FROM EmpsCTE AS M
           INNER JOIN dbo.Employees AS S
              ON S.mgrid = M.empid)
    SELECT @totalsalary = SUM(EmpsCTE.salary)
      FROM EmpsCTE;
    RETURN @totalsalary;
END;



GO

SELECT dbo.SubtreeTotalSalaries(8) AS subtreetotal;

SELECT  * FROM  dbo.Employees
SELECT  * FROM  Employees

/*Com a maioria dos tipos de objetos, o T-SQL permite omitir o nome do esquema quando se refere ao
objeto, caso em que usa resolução implícita de nome de esquema. Com UDFs escalares, você deve usar
o nome de duas partes incluindo o esquema. */
SELECT SubtreeTotalSalaries(8) AS subtreetotal;


/* ==================================================================
--Data: 20/06/2018 
--Observação: O T-SQL suporta a invocação de funções internas não-determinísticas dentro de funções definidas pelo usuário,
contanto que eles não tenham efeitos colaterais no sistema.

As funções SYSDATETIME, RAND
(sem uma entrada de semente), e NEWID são todas funções não-determinísticas

1)O SYSDATETIME
A função não tem efeitos colaterais no sistema e, portanto, é permitida em funções definidas pelo usuário
-- ==================================================================
*/


/*Como exemplo, execute o seguinte código para criar a função definida pelo usuário MySYSDATETIME:*/

GO

CREATE OR ALTER FUNCTION dbo.MySYSDATETIME() RETURNS DATETIME2
AS
BEGIN
RETURN SYSDATETIME();
END;
GO

SELECT OD.*,dbo.MySYSDATETIME() FROM Sales.OrderDetails AS OD


/*
As funções NEWID e RAND têm efeitos colaterais no sentido de que uma chamada de função
deixa uma marca atrás que afeta uma chamada de função subseqüente. Conseqüentemente, você não tem permissão
para invocar o NEWID e o RAND dentro de funções definidas pelo usuário
*/

GO

CREATE OR ALTER FUNCTION dbo.MyRAND() RETURNS FLOAT
AS
BEGIN
RETURN RAND();
END;
GO
--Msg 443, Level 16, State 1, Procedure MyRAND, Line 5 [Batch Start Line 123]
--Invalid use of a side-effecting operator 'rand' within a function.
GO

CREATE OR ALTER FUNCTION dbo.MyNEWID() RETURNS FLOAT
AS
BEGIN
RETURN NEWID();
END;
GO
--Msg 443, Level 16, State 1, Procedure MyNEWID, Line 5 [Batch Start Line 133]
--Invalid use of a side-effecting operator 'newid' within a function.

/* ==================================================================
--Data: 21/06/2018 
--Observação:
 Observe que o SQL Server executou as funções definidas pelo usuário uma vez por linha, ao contrário das anteriores
quando você invocou as funções internas diretamente, nesse caso o SQL Server executou as funções
apenas uma vez para toda a consulta.
 

 Observe que, para usar uma função definida pelo usuário em uma coluna computada persistente ou
uma visão indexada, a função precisa ser determinística. O que isto significa é que o usuário definido
função não deve chamar funções não-determinísticas, mais você precisa defini-lo com
o atributo SCHEMABINDING. 
-- ==================================================================
*/

CREATE OR ALTER FUNCTION dbo.ENDOFYEAR(@dt AS DATE) RETURNS DATE
AS
BEGIN
RETURN DATEFROMPARTS(YEAR(@dt), 12, 31);
END;
GO	
/* ==================================================================
--Data: 21/06/2018 
--Observação: Como  a função não tem a garatia de ser deterministica pois 
 
-- ==================================================================
*/

DROP TABLE IF EXISTS dbo.T1;
GO
CREATE TABLE dbo.T1
(
keycol INT NOT NULL IDENTITY CONSTRAINT PK_T1 PRIMARY KEY,
dt DATE NOT NULL,
dtendofyear AS dbo.ENDOFYEAR(dt) PERSISTED
);

/* ==================================================================
--Data: 21/06/2018 
--Observação: Para resolver isso basta colocar 
WITH SCHEMABINDING na função
 
-- ==================================================================
*/

/* ==================================================================
--Data: 21/06/2018 
--Observação: The reason that it’s called an inline function
 
-- ==================================================================
*/
GO

CREATE OR ALTER FUNCTION dbo.GetPage(@pagenum AS BIGINT, @pagesize AS BIGINT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
WITH C AS
(
SELECT ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum,
orderid, orderdate, custid, empid
FROM Sales.Orders
)
SELECT rownum, orderid, orderdate, custid, empid
FROM C
WHERE rownum BETWEEN (@pagenum - 1) * @pagesize + 1 AND @pagenum * @pagesize;
GO

SELECT rownum, orderid, orderdate, custid, empid
FROM dbo.GetPage(3, 12) AS T;

/* ==================================================================
--Data: 21/06/2018 
--Observação: Veja que outra solução 
 
-- ==================================================================
*/

go
CREATE OR ALTER FUNCTION dbo.GetPage(@pagenum AS BIGINT, @pagesize AS BIGINT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
SELECT ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum,
orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
GO

/* ==================================================================
--Data: 21/06/2018 
--Observação: 
Você precisa implementar uma função chamada GetSubtree que aceita um ID de gerente como entrada (chamada
it @mgr), e um parâmetro opcional para limitar o número de níveis (chame-o @maxlevels); a
função deve retornar o conjunto de todos os subordinados do gerenciador de entrada, aplicando o nível
limite se um foi especificado. A função deve retornar um NULL como o ID do gerenciador da entrada
Gerente.
Execute o seguinte código para implementar a função GetSubtree como um valor de tabela in-line
 
-- ==================================================================
*/
DROP FUNCTION IF EXISTS dbo.GetSubtree;
GO
CREATE FUNCTION dbo.GetSubtree (
    @mgr AS INT,
    @maxlevels AS INT = NULL)
RETURNS TABLE
WITH SCHEMABINDING
AS RETURN
WITH EmpsCTE
  AS (SELECT Employees.empid,
             CAST(NULL AS INT) AS mgrid,
             Employees.empname,
             Employees.salary,
             0 AS lvl,
             CAST('.' AS VARCHAR(900)) AS sortpath
        FROM dbo.Employees
       WHERE Employees.empid = @mgr
      UNION ALL
      SELECT S.empid,
             S.mgrid,
             S.empname,
             S.salary,
             M.lvl + 1 AS lvl,
             CAST(M.sortpath + CAST(S.empid AS VARCHAR(10)) + '.' AS VARCHAR(900)) AS sortpath
        FROM EmpsCTE AS M
       INNER JOIN dbo.Employees AS S
          ON S.mgrid   = M.empid
         AND (   M.lvl < @maxlevels
            OR   @maxlevels IS NULL))
SELECT empid,
       mgrid,
       empname,
       salary,
       lvl,
       sortpath
  FROM EmpsCTE;

  GO
  
SELECT T.empid,
       REPLICATE('  ', T.lvl) + T.empname AS emp,
       T.mgrid,
       T.salary,
       T.lvl,
       T.sortpath
  FROM dbo.GetSubtree(3, NULL) AS T
 ORDER BY T.sortpath;




 /* ==================================================================
 --Data: 21/06/2018 
 --Observação: Multistatement table-valued user-defined functions
  
 -- ==================================================================
 */
