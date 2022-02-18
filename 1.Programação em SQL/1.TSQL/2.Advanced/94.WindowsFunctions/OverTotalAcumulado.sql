USE TSQL2012

SELECT  [Vendedor] = CONCAT(E.firstname, SPACE(1), E.lastname) ,
        OD.orderid ,
        P.productname,
        OD.unitprice ,
        OD.qty ,
        OD.discount ,
		[Total Vendido Por Produto] =((OD.unitprice * OD.qty) - OD.discount),
		[Acumulado Por Nota] =SUM(((OD.unitprice * OD.qty) - OD.discount)) OVER(PARTITION BY O.orderid ORDER BY OD.orderid ROWS UNBOUNDED PRECEDING),
		[Total da Nota] = SUM(((OD.unitprice * OD.qty) - OD.discount)) OVER(PARTITION BY O.orderid ORDER BY OD.orderid),
        O.orderdate ,

        [Frete] = O.freight ,
        [Pais de Entrega] = O.shipcountry
FROM    Sales.OrderDetails AS OD
        JOIN Sales.Orders AS O ON O.orderid = OD.orderid
        JOIN HR.Employees AS E ON E.empid = O.empid
		JOIN Production.Products AS P ON P.productid = OD.productid
		ORDER BY Vendedor ,O.orderid
		
