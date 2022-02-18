--USE TSQLV4;

DECLARE @Mostrar BIT = 0;
-- ==================================================================
--Observação: window frame
-- ==================================================================

IF (@Mostrar = 1)
BEGIN


    ;WITH Dados
       AS (

          --Vendas efetuadas pelo cliente 1
          SELECT O.shipcountry,
                 O.orderid,
                 O.custid,
                 O.empid,
                 O.orderdate,
                 [Frete] = O.freight,
                 OD.productid,
                 OD.unitprice,
                 OD.qty,
                 [Valor Total Produto] = OD.unitprice * OD.qty
            FROM Sales.Orders AS O
            JOIN Sales.OrderDetails AS OD
              ON O.orderid = OD.orderid
           WHERE O.custid = 1)
    SELECT R.shipcountry,
           R.orderid,
           R.custid,
           R.empid,
           R.orderdate,
           R.Frete,
           R.productid,
           R.unitprice,
           R.qty,
           R.[Valor Total Produto],
           TotalAcumulado1 = SUM(R.[Valor Total Produto]) OVER (PARTITION BY R.custid ORDER BY R.orderdate, R.productid),
           TotalAcumulado2 = SUM(R.[Valor Total Produto]) OVER (PARTITION BY R.custid
                                                                    ORDER BY R.orderdate
                                                                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
           TotalAcumulado3 = SUM(R.[Valor Total Produto]) OVER (PARTITION BY R.custid
                                                                    ORDER BY R.orderdate,
                                                                             R.productid
                                                                    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      FROM Dados R
     ORDER BY R.custid,
              R.orderdate;

END;



-- ==================================================================
--Observação: Window aggregate functions

-- ==================================================================	      
IF (@Mostrar = 1)
BEGIN
    ;WITH Dados1
       AS (

          --Vendas efetuadas pelo cliente 1
          SELECT O.shipcountry,
                 O.orderid,
                 O.custid,
                 O.empid,
                 O.orderdate,
                 [Frete] = O.freight,
                 OD.productid,
                 OD.unitprice,
                 OD.qty,
                 [Valor Total Produto] = OD.unitprice * OD.qty
            FROM Sales.Orders AS O
            JOIN Sales.OrderDetails AS OD
              ON O.orderid = OD.orderid
           WHERE O.custid = 1)
    SELECT R.shipcountry,
           R.orderid,
           R.custid,
           R.empid,
           R.orderdate,
           R.Frete,
           R.productid,
           R.unitprice,
           R.qty,
           R.[Valor Total Produto],
           TotalVendidoPorProduto = SUM(R.[Valor Total Produto]) OVER (PARTITION BY R.custid, R.productid),
           MediaVendidoPorProduto = AVG(R.[Valor Total Produto]) OVER (PARTITION BY R.custid, R.productid)
      FROM Dados1 R
     ORDER BY R.custid,
              R.productid;

END;


-- ==================================================================
--Observação: Window Ranking Functions
-- ==================================================================

IF (@Mostrar = 1)
BEGIN
    WITH Dados2
      AS (

         --Vendas efetuadas pelo cliente 1
         SELECT O.shipcountry,
                O.orderid,
                O.custid,
                O.empid,
                O.orderdate,
                [Frete] = O.freight,
                OD.productid,
                OD.unitprice,
                OD.qty,
                [Valor Total Produto] = OD.unitprice * OD.qty
           FROM Sales.Orders AS O
           JOIN Sales.OrderDetails AS OD
             ON O.orderid = OD.orderid
          WHERE O.custid = 1)
    SELECT R.shipcountry,
           R.orderid,
           R.custid,
           R.productid,
           [Order DENSE_RANK] = DENSE_RANK() OVER (PARTITION BY R.custid ORDER BY R.productid),
           [Order RANK] = RANK() OVER (PARTITION BY R.custid ORDER BY R.productid),
           [Repitido] = ROW_NUMBER() OVER (PARTITION BY R.custid, R.productid ORDER BY R.productid),
           Grupos = NTILE(2) OVER (ORDER BY R.custid),
           R.empid,
           R.orderdate,
           R.Frete,
           R.unitprice,
           R.qty,
           R.[Valor Total Produto]
      FROM Dados2 R
     ORDER BY R.custid,
              R.productid;

END;



-- ==================================================================
--Observação: Window Offset Functions
/*
 */
-- ==================================================================

WITH Dados3
  AS (

     --Vendas efetuadas pelo cliente 1
     SELECT O.shipcountry,
            O.orderid,
            O.custid,
            O.empid,
            O.orderdate,
            [Frete] = O.freight,
            OD.productid,
            OD.unitprice,
            OD.qty,
            [Valor Total Produto] = OD.unitprice * OD.qty
       FROM Sales.Orders AS O
       JOIN Sales.OrderDetails AS OD
         ON O.orderid = OD.orderid
      WHERE O.custid = 1)
SELECT R.shipcountry,
       R.orderid,
       R.custid,
       R.productid,
	   R.[Valor Total Produto],
       [FIRST_VALUE] = FIRST_VALUE(R.[Valor Total Produto]) OVER (PARTITION BY R.custid ORDER BY R.orderdate),
	   [LAST_VALUE] = LAST_VALUE(R.[Valor Total Produto]) OVER (PARTITION BY R.custid ORDER BY R.orderdate),
	   [LEAD - Proxima Compra] = LEAD(R.[Valor Total Produto]) OVER (PARTITION BY R.custid ORDER BY R.orderdate),
	   [LAG -  Compra Anterior] = LAG(R.[Valor Total Produto]) OVER (PARTITION BY R.custid ORDER BY R.orderdate),
       R.empid,
       R.orderdate,
       R.Frete,
       R.unitprice,
       R.qty
       
  FROM Dados3 R
 ORDER BY R.custid,
          R.orderdate;