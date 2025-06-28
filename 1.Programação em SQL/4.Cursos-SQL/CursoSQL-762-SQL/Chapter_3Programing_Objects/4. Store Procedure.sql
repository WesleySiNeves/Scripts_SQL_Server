/* ==================================================================
--Data: 21/06/2018 
--Observação: Usando dynamic search conditions
 
-- ==================================================================
*/

/*O jeito correto de tratar dynamic search conditions */

USE TSQLV4;

GO

CREATE OR ALTER PROC dbo.GetOrders
    @orderid AS INT = NULL,
    @orderdate AS DATE = NULL,
    @custid AS INT = NULL,
    @empid AS INT = NULL
AS
SET XACT_ABORT, NOCOUNT ON;
SELECT Orders.orderid,
       Orders.orderdate,
       Orders.shippeddate,
       Orders.custid,
       Orders.empid,
       Orders.shipperid
  FROM Sales.Orders
 WHERE (   Orders.orderid   = @orderid
      OR   @orderid IS NULL)
   AND (   Orders.orderdate = @orderdate
      OR   @orderdate IS NULL)
   AND (   Orders.custid    = @custid
      OR   @custid IS NULL)
   AND (   Orders.empid     = @empid
      OR   @empid IS NULL);
GO

EXEC dbo.GetOrders @orderid = NULL, -- int
                   @orderdate = NULL, -- date
                   @custid = NULL, -- int
                   @empid = NULL -- int


/* ==================================================================
--Data: 21/06/2018 
--Observação: XACT_ABORT determina o efeito de erros de tempo de execução gerados por querys T-SQL
	Quando esta opção está em OFF (o padrão na maioria dos casos), alguns erros causam
	transação para reverter e a execução do código a ser abortado, enquanto outros erros
	deixe a transação aberta. Para obter um comportamento mais confiável e consistente, considero isso
	melhor prática para definir esta opção como ON,
	e assim todos os erros fazem com que uma transação aberta seja
	revertida e a execução do código a ser abortada


	A opção NOCOUNT suprime
mensagens indicando quantas linhas foram afetadas pelas instruções de manipulação de dados. Quando
desativado (o padrão), essas mensagens podem prejudicar o desempenho da consulta devido à rede
tráfego que eles geram
-- ==================================================================
*/

EXEC dbo.GetOrders @orderdate = '20151111', @custid = 85;

/* ==================================================================
--Data: 21/06/2018 
--Observação: Stored procedures and dynamic SQL
 -A opção e boa mas nao e otima , por parametre sniff,
 --para resolver precisamos do uso do  OPTION(RECOMPILE);
-- ==================================================================
*/


/* ==================================================================
--Data: 21/06/2018 
--Observação: Com essa opção, em todas as execuções do procedimento armazenado, o SQL Server otimiza
consulta do zero, depois de aplicar a incorporação de parâmetros (substituindo os parâmetros por
constantes) e normalizando a consulta para remover as partes redundantes. Por exemplo, se você
executar o procedimento, fornecendo um valor de entrada apenas para o parâmetro 
 
-- ==================================================================
*/

/*Veja esse exemplo*/
SELECT orderid, orderdate, shippeddate, custid, empid, shipperid
FROM Sales.Orders
WHERE orderid = 10248;

/* ==================================================================
--Data: 21/06/2018 
--Observação: Veja a contrução da mesma SP com Dinamicy SQL
-- ==================================================================
*/

GO

CREATE OR ALTER PROC dbo.GetOrders
@orderid AS INT = NULL,
@orderdate AS DATE = NULL,
@custid AS INT = NULL,
@empid AS INT = NULL
AS
SET XACT_ABORT, NOCOUNT ON;

/*
DECLARE
@orderid AS INT = 10248,
@orderdate AS DATE = NULL,
@custid AS INT = NULL,
@empid AS INT = NULL;

*/
DECLARE @sql AS NVARCHAR(MAX) = N'SELECT orderid, orderdate, shippeddate, custid, empid,
shipperid
FROM Sales.Orders
WHERE 1 = 1'
+ CASE WHEN @orderid IS NOT NULL THEN N' AND orderid = @orderid 'ELSE N'' END
+ CASE WHEN @orderdate IS NOT NULL THEN N' AND orderdate = @orderdate' ELSE N'' END
+ CASE WHEN @custid IS NOT NULL THEN N' AND custid = @custid ' ELSE N'' END
+ CASE WHEN @empid IS NOT NULL THEN N' AND empid = @empid ' ELSE N'' END
+ N';'

SELECT @sql

SELECT orderid, orderdate, shippeddate, custid, empid, shipperid
FROM Sales.Orders
WHERE orderid = 10248;




EXEC sys.sp_executesql
@stmt = @sql,
@params = N'@orderid AS INT, @orderdate AS DATE, @custid AS INT, @empid AS INT',
@orderid = @orderid,
@orderdate = @orderdate,
@custid = @custid,
@empid = @empid;
GO