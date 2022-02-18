USE TSQLV4;
GO

/* ==================================================================
--Data: 13/06/2018 
--Observa��o: Criando uma Index View
 
-- ==================================================================
*/

CREATE OR ALTER VIEW Sales.VwOrderTotals
WITH SCHEMABINDING
AS
SELECT O.orderid,
       O.custid,
       O.empid,
       O.shipperid,
       O.orderdate,
       O.requireddate,
       O.shippeddate,
       SUM(OD.qty) AS qty,
       CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val,
       COUNT_BIG(*) AS numorderlines
  FROM Sales.Orders AS O
 INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
 GROUP BY O.orderid,
          O.custid,
          O.empid,
          O.shipperid,
          O.orderdate,
          O.requireddate,
          O.shippeddate
GO

/* ==================================================================
--Data: 13/06/2018 
--Observa��o:   veja que qunando vc roda um select com  o plano de execu��o ativad
 vc ve o processamento dos dados nas tabelas subjacentes
-- ==================================================================
*/

SELECT *
  FROM Sales.VwOrderTotals AS VOT;


/* ==================================================================
--Data: 13/06/2018 
--Observa��o:  O primeiro passo para criaar uma view Indexada e criar um unique Index
entretando tem algumas restri��es de criacao de views indexadas

1) Uma delas � que o cabe�alho da view tem que ter o atributo SCHEMABINDING
2)Outra � que, se a consulta for uma consulta agrupada, ela deve incluir o agregate COUNT_BIG .
 O SQL Server precisa rastrear as contagens de linha de grupo para saber quando um
O grupo precisa ser eliminado como resultado de exclus�es ou atualiza��es de linhas de detalhes subjacentes
 
-- ==================================================================
*/
CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid
ON Sales.VwOrderTotals (orderid);


/* ==================================================================
--Data: 13/06/2018 
--Observa��o: Veja que nesse ponto a contru��o do indice falha novamente
pois a outra restri��o e que vc tambem n�o pode fazer manipula��es 
desse tipo  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val,
Para poder criar o �ndice, voc� precisa remover a manipula��o
que � aplicado pela fun��o CAST
 
-- ==================================================================
*/

GO
CREATE OR ALTER VIEW Sales.VwOrderTotals
WITH SCHEMABINDING
AS
SELECT O.orderid,
       O.custid,
       O.empid,
       O.shipperid,
       O.orderdate,
       O.requireddate,
       O.shippeddate,
       SUM(OD.qty) AS qty,
       SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS val,
       COUNT_BIG(*) AS numorderlines
  FROM Sales.Orders AS O
 INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
 GROUP BY O.orderid,
          O.custid,
          O.empid,
          O.shipperid,
          O.orderdate,
          O.requireddate,
          O.shippeddate;
GO

CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid
ON Sales.VwOrderTotals (orderid);


/* ==================================================================
--Data: 13/06/2018 
--Observa��o: Veja que agora temos um Index Scan no PLano de execu��o
 
-- ==================================================================
*/

SELECT * FROM Sales.VwOrderTotals AS VOT


/* ==================================================================
--Data: 13/06/2018 
--Observa��o: Depois de criar com sucesso um �ndice clusterizado em uma visualiza��o, voc� pode criar
�ndices n�o clusterizados. Execute o seguinte c�digo para criar um n�mero de n�o-cluster
�ndices na visualiza��o Sales.OrderTotal:
 
-- ==================================================================
*/
CREATE NONCLUSTERED INDEX idx_nc_custid ON Sales.VwOrderTotals (custid);
CREATE NONCLUSTERED INDEX idx_nc_empid ON Sales.VwOrderTotals (empid);
CREATE NONCLUSTERED INDEX idx_nc_shipperid ON Sales.VwOrderTotals (shipperid);
CREATE NONCLUSTERED INDEX idx_nc_orderdate ON Sales.VwOrderTotals (orderdate);
CREATE NONCLUSTERED INDEX idx_nc_shippeddate ON Sales.VwOrderTotals (shippeddate);


/* ==================================================================
--Data: 13/06/2018 
--Observa��o: Se voc� estiver usando uma edi��o n�o corporativa ou de desenvolvedor do SQL Server, ser� necess�rio indicar
a dica NOEXPAND contra a exibi��o para que o SQL Server n�o expanda a defini��o de exibi��o,
mas considere usar o �ndice na exibi��o
 
-- ==================================================================
*/
SELECT * FROM Sales.VwOrderTotals AS VOT WITH(NOEXPAND)