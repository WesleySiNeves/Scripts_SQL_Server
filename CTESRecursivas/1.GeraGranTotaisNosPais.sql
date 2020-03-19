USE TSQL2012 
GO

WITH    CTE
          AS ( SELECT   E.empid ,
                        [Nome Completo] = CONCAT(E.firstname, ' ', E.lastname) ,
                        O.orderid ,
                        O.orderdate ,
                        OD.productid ,
                        P.productname ,
                        [Valor Unitário] = P.unitprice ,
                        [Quantidade] = OD.qty ,
                        OD.discount
               FROM     HR.Employees AS E
                        JOIN Sales.Orders AS O ON O.empid = E.empid
                        JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
                        JOIN Production.Products AS P ON P.productid = OD.productid
               WHERE    YEAR(O.orderdate) = 2006
             ),
        CTE2
          AS ( SELECT   E.empid ,
                        [Nome Completo] = CONCAT(E.firstname, ' ', E.lastname) ,
                        O.orderid ,
                        O.orderdate ,
                        OD.productid ,
                        P.productname ,
                        [Valor Unitário] = P.unitprice ,
                        [Quantidade] = OD.qty ,
                        OD.discount
               FROM     HR.Employees AS E
                        JOIN Sales.Orders AS O ON O.empid = E.empid
                        JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
                        JOIN Production.Products AS P ON P.productid = OD.productid
               WHERE    YEAR(O.orderdate) = 2007
             )
    SELECT  CTE.empid ,
            CTE.[Nome Completo] ,
            CTE.orderid ,
            CTE.orderdate ,
            CTE.productid ,
            CTE.productname ,
            CTE.[Valor Unitário] ,
            CTE.Quantidade ,
            CTE.discount
    FROM    CTE
    UNION
    SELECT  CTE2.empid ,
            CTE2.[Nome Completo] ,
            CTE2.orderid ,
            CTE2.orderdate ,
            CTE2.productid ,
            CTE2.productname ,
            CTE2.[Valor Unitário] ,
            CTE2.Quantidade ,
            CTE2.discount
    FROM    CTE2;