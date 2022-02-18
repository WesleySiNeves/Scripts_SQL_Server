USE TSQLV4

--DBCC TRACEOFF(3604)

--DBCC TRACEON(3604)
--Object Name	Index ID	Partition ID	Alloc Unit ID	   Alloc Unit Type	First Page	Root Page	First IAM Page
--Lancamentos	1	   72057594055032832	72057594063028224	IN_ROW_DATA	   (1:24184)	(1:24218)	 (1:144)
 

 SELECT * FROM Sales.Customers AS C
 EXEC dbo.sp_AllocationMetadata @object = 'Sales.Customers' -- varchar(128);


 SELECT TOP 1 * FROM Sales.Customers AS L
 ORDER BY NEWID()
 
 

 
 -- ==================================================================
 --Observação: Aqui liga o plano de execução
--Scan count 0, logical reads 3, physic 
 -- ==================================================================

SET STATISTICS IO ON 
SELECT * FROM Sales.Customers AS L
WHERE l.custid = '39'
SET STATISTICS IO OFF

-- ==================================================================
--Observação: simulando o trabalho da STORE ENGINE
/*
 */
-- ==================================================================

--DBCC TRACEON(3604)
--DBCC TRACEOFF(3604)

/*
--1  Modo mais avançado , traz a estrutura da pagina
--2 
--3 modo mais visual , traz apenas os registros
*/
SELECT * FROM Sales.Customers AS C

 EXEC dbo.sp_AllocationMetadata @object = 'Sales.Customers' -- varchar(128);

--D607
(1:472:0)
DBCC PAGE('TSQLV4',1,14722,3)



DBCC PAGE('TSQL2016',1,11259,3)
