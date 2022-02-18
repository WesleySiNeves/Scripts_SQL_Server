USE TSQLV4;
GO

/* ==================================================================
--Data: 13/06/2018 
--Observação: Criando uma Index View
 
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
--Observação:   veja que qunando vc roda um select com  o plano de execução ativad
 vc ve o processamento dos dados nas tabelas subjacentes
-- ==================================================================
*/

SELECT *
  FROM Sales.VwOrderTotals AS VOT;


/* ==================================================================
--Data: 13/06/2018 
--Observação:  O primeiro passo para criaar uma view Indexada e criar um unique Index
entretando tem algumas restrições de criacao de views indexadas

1) Uma delas é que o cabeçalho da view tem que ter o atributo SCHEMABINDING
2)Outra é que, se a consulta for uma consulta agrupada, ela deve incluir o agregate COUNT_BIG .
 O SQL Server precisa rastrear as contagens de linha de grupo para saber quando um
O grupo precisa ser eliminado como resultado de exclusões ou atualizações de linhas de detalhes subjacentes
 
-- ==================================================================
*/
CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid
ON Sales.VwOrderTotals (orderid);


/* ==================================================================
--Data: 13/06/2018 
--Observação: Veja que nesse ponto a contrução do indice falha novamente
pois a outra restrição e que vc tambem não pode fazer manipulações 
desse tipo  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val,
Para poder criar o índice, você precisa remover a manipulação
que é aplicado pela função CAST
 
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
--Observação: Veja que agora temos um Index Scan no PLano de execução
 
-- ==================================================================
*/

SELECT * FROM Sales.VwOrderTotals AS VOT


/* ==================================================================
--Data: 13/06/2018 
--Observação: Depois de criar com sucesso um índice clusterizado em uma visualização, você pode criar
índices não clusterizados. Execute o seguinte código para criar um número de não-cluster
índices na visualização Sales.OrderTotal:
 
-- ==================================================================
*/
CREATE NONCLUSTERED INDEX idx_nc_custid ON Sales.VwOrderTotals (custid);
CREATE NONCLUSTERED INDEX idx_nc_empid ON Sales.VwOrderTotals (empid);
CREATE NONCLUSTERED INDEX idx_nc_shipperid ON Sales.VwOrderTotals (shipperid);
CREATE NONCLUSTERED INDEX idx_nc_orderdate ON Sales.VwOrderTotals (orderdate);
CREATE NONCLUSTERED INDEX idx_nc_shippeddate ON Sales.VwOrderTotals (shippeddate);


/* ==================================================================
--Data: 13/06/2018 
--Observação: Se você estiver usando uma edição não corporativa ou de desenvolvedor do SQL Server, será necessário indicar
a dica NOEXPAND contra a exibição para que o SQL Server não expanda a definição de exibição,
mas considere usar o índice na exibição
 
-- ==================================================================
*/
SELECT * FROM Sales.VwOrderTotals AS VOT WITH(NOEXPAND)