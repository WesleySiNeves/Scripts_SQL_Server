USE TSQLV4;

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
       CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val
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


SELECT *
  FROM Sales.VwOrderTotals AS VOT;


GO


SELECT O.orderid,
       O.custid,
       O.empid,
       O.shipperid,
       O.orderdate,
       O.requireddate,
       O.shippeddate,
       SUM(OD.qty) AS qty,
       CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val
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

WITH Dados
  AS (SELECT O.orderid,
             O.custid,
             O.empid,
             O.shipperid,
             O.orderdate,
             O.requireddate,
             O.shippeddate,
             SUM(OD.qty) AS qty,
             CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val
        FROM Sales.Orders AS O
       INNER JOIN Sales.OrderDetails AS OD
          ON O.orderid = OD.orderid
       GROUP BY O.orderid,
                O.custid,
                O.empid,
                O.shipperid,
                O.orderdate,
                O.requireddate,
                O.shippeddate)
SELECT *
  FROM Dados R;

PRINT OBJECT_DEFINITION(OBJECT_ID(N'Sales.VwOrderTotals'));

GO
CREATE OR ALTER VIEW Sales.CustLast5OrderDates
WITH SCHEMABINDING
AS
WITH C
  AS (
     SELECT Orders.custid,
            Orders.orderdate,
            DENSE_RANK() OVER (PARTITION BY Orders.custid ORDER BY Orders.orderdate DESC) AS pos
       FROM Sales.Orders)
SELECT custid,
       [1],
       [2],
       [3],
       [4],
       [5]
  FROM C
    PIVOT (   MAX(orderdate)
              FOR pos IN ([1], [2], [3], [4], [5])) AS P;
GO



/* ==================================================================
--Data: 12/06/2018 
--Observação: Exemplo de Views Com Multiplas CTEs
 
-- ==================================================================
*/
CREATE OR ALTER VIEW Sales.CustTop5OrderValues
WITH SCHEMABINDING
AS
WITH C1
  AS (
     SELECT O.orderid,
            O.custid,
            CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val
       FROM Sales.Orders AS O
      INNER JOIN Sales.OrderDetails AS OD
         ON O.orderid = OD.orderid
      GROUP BY O.orderid,
               O.custid),
     C2
  AS (SELECT C1.custid,
             C1.val,
             ROW_NUMBER() OVER (PARTITION BY C1.custid ORDER BY C1.val DESC, C1.orderid DESC) AS pos
        FROM C1)
SELECT custid,
       [1],
       [2],
       [3],
       [4],
       [5]
  FROM C2
    PIVOT (   MAX(val)
              FOR pos IN ([1], [2], [3], [4], [5])) AS P;
GO

GO

/* ==================================================================
--Data: 12/06/2018 
--Observação: OUtro Exemplo de Views Com Multiplas CTES
 
-- ==================================================================
*/

CREATE OR ALTER VIEW Sales.OrderValuePcts
WITH SCHEMABINDING
AS
WITH OrderTotals
  AS (
     SELECT O.orderid,
            O.custid,
            SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS val
       FROM Sales.Orders AS O
      INNER JOIN Sales.OrderDetails AS OD
         ON O.orderid = OD.orderid
      GROUP BY O.orderid,
               O.custid),
     GrandTotal
  AS (SELECT SUM(OrderTotals.val) AS grandtotalval
        FROM OrderTotals),
     CustomerTotals
  AS (SELECT OrderTotals.custid,
             SUM(OrderTotals.val) AS custtotalval
        FROM OrderTotals
       GROUP BY OrderTotals.custid)
SELECT O.orderid,
       O.custid,
       CAST(O.val AS NUMERIC(12, 2)) AS val,
       CAST(O.val / G.grandtotalval * 100.0 AS NUMERIC(5, 2)) AS pctall,
       CAST(O.val / C.custtotalval * 100.0 AS NUMERIC(5, 2)) AS pctcust
  FROM OrderTotals AS O
 CROSS JOIN GrandTotal AS G
 INNER JOIN CustomerTotals AS C
    ON O.custid = C.custid;
GO


SELECT * FROM Sales.OrderValuePcts AS OVP


/* ==================================================================
--Data: 12/06/2018 
--Observação: Veja que essa solução pode ser melhorada utilizando Windows Functions
 
-- ==================================================================
*/

GO

CREATE OR ALTER VIEW Sales.OrderValuePctsComWindowsFunctions
WITH SCHEMABINDING
AS
WITH OrderTotals
  AS (
     SELECT O.orderid,
            O.custid,
            CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val
       FROM Sales.Orders AS O
      INNER JOIN Sales.OrderDetails AS OD
         ON O.orderid = OD.orderid
      GROUP BY O.orderid,
               O.custid)
SELECT OrderTotals.orderid,
       OrderTotals.custid,
       OrderTotals.val,
       CAST(OrderTotals.val / SUM(OrderTotals.val) OVER () * 100.0 AS NUMERIC(5, 2)) AS pctall,
       CAST(OrderTotals.val / SUM(OrderTotals.val) OVER (PARTITION BY OrderTotals.custid) * 100.0 AS NUMERIC(5, 2)) AS pctcust
  FROM OrderTotals;


  /* ==================================================================
  --Data: 12/06/2018 
  --Observação:  Veja a diferença do plano de execução
   
  -- ==================================================================
  */
  SELECT * FROM Sales.OrderValuePcts AS OVP

 SELECT * FROM Sales.OrderValuePctsComWindowsFunctions AS OVPCWF



 /* ==================================================================
 --Data: 12/06/2018 
 --Observação: Views Atributes  (uso do SCHEMABINDING
  
 -- ==================================================================
 */


GO

/*Cria uma view sem o SCHEMABINDING */

CREATE OR ALTER VIEW Sales.USACusts
AS
SELECT Customers.custid,
       Customers.companyname,
       Customers.contactname,
       Customers.contacttitle,
       Customers.address,
       Customers.city,
       Customers.region,
       Customers.postalcode,
       Customers.country,
       Customers.phone,
       Customers.fax
  FROM Sales.Customers
 WHERE Customers.country = N'USA';
GO

BEGIN TRANSACTION T1

ALTER TABLE Sales.Customers DROP COLUMN country

ROLLBACK TRAN T1


/* ==================================================================
--Data: 12/06/2018 
--Observação:  Agora  vamos alterar a view para 
 SCHEMABINDING
-- ==================================================================
*/

GO
 CREATE OR ALTER VIEW USACusts WITH SCHEMABINDING
 AS
SELECT Customers.custid,
       Customers.companyname,
       Customers.contactname,
       Customers.contacttitle,
       Customers.address,
       Customers.city,
       Customers.region,
       Customers.postalcode,
       Customers.country,
       Customers.phone,
       Customers.fax
  FROM Sales.Customers
 WHERE Customers.country = N'USA';
GO

PRINT OBJECT_DEFINITION( OBJECT_ID('dbo.USACusts'))


/* ==================================================================
--Data: 12/06/2018 
--Observação:  Uso do  ENCRYPTION
 
-- ==================================================================
*/


GO
 CREATE OR ALTER VIEW USACusts WITH ENCRYPTION
 AS
SELECT Customers.custid,
       Customers.companyname,
       Customers.contactname,
       Customers.contacttitle,
       Customers.address,
       Customers.city,
       Customers.region,
       Customers.postalcode,
       Customers.country,
       Customers.phone,
       Customers.fax
  FROM Sales.Customers
 WHERE Customers.country = N'USA';
GO


PRINT OBJECT_DEFINITION( OBJECT_ID('dbo.USACusts'))


/* ==================================================================
--Data: 12/06/2018 
--Observação:  Usando mais de um atributo
 
-- ==================================================================
*/
GO
CREATE OR ALTER VIEW Sales.USACusts
WITH SCHEMABINDING, ENCRYPTION
AS
SELECT Customers.custid,
       Customers.companyname,
       Customers.contactname,
       Customers.contacttitle,
       Customers.address,
       Customers.city,
       Customers.region,
       Customers.postalcode,
       Customers.country,
       Customers.phone,
       Customers.fax
  FROM Sales.Customers
 WHERE Customers.country = N'USA';
GO

/* ==================================================================
--Data: 12/06/2018 
--Observação:  Trabalhando com Views Atualizaveis
 
-- ==================================================================
*/


GO

CREATE OR ALTER VIEW Sales.USACusts
WITH SCHEMABINDING
AS
SELECT Customers.custid,
       Customers.companyname,
       Customers.contactname,
       Customers.contacttitle,
       Customers.address,
       Customers.city,
       Customers.region,
       Customers.postalcode,
       Customers.country,
       Customers.phone,
       Customers.fax
  FROM Sales.Customers
 WHERE Customers.country = N'USA';
GO



/*Isert na View*/

INSERT INTO Sales.USACusts (companyname,
                            contactname,
                            contacttitle,
                            address,
                            city,
                            region,
                            postalcode,
                            country,
                            phone,
                            fax)
VALUES (N'Customer AAAAA',
        N'Contact AAAAA',
        N'Title AAAAA',
        N'Address AAAAA',
        N'Redmond',
        N'WA',
        N'11111',
        N'USA',
        N'111-1111111',
        N'111-1111111');


/*Recupera o ultimo registro inserido*/
SELECT Customers.custid,
       Customers.companyname,
       Customers.country
  FROM Sales.Customers
 WHERE Customers.custid = SCOPE_IDENTITY();


/* ==================================================================
--Data: 12/06/2018 
--Observação: Veja que nossa view apenas busca clientes do pais USA
 mas quando fazemos insert podemos inserir cliente de qualquer localidade
-- ==================================================================
*/
INSERT INTO Sales.USACusts (companyname,
                            contactname,
                            contacttitle,
                            address,
                            city,
                            region,
                            postalcode,
                            country,
                            phone,
                            fax)
VALUES (N'Customer BBBBB',
        N'Contact BBBBB',
        N'Title BBBBB',
        N'Address BBBBB',
        N'London',
        NULL,
        N'22222',
        N'UK',
        N'222-2222222',
        N'222-2222222');

/*Entretanto quando buscamos os dados inseridos ele nao tras*/

/*Recupera o ultimo registro inserido*/
SELECT Customers.custid,
       Customers.companyname,
       Customers.country
  FROM Sales.Customers
 WHERE Customers.custid = SCOPE_IDENTITY();



 