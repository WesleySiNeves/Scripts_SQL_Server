
USE TSQL2012
SELECT 
       OV.custid ,
       [Cliente] = C.companyname,
       OV.orderdate ,
       OV.requireddate ,
       OV.qty ,
       OV.val ,
	   [Media das 3 UltimasCompras] = AVG(OV.val) OVER(PARTITION BY C.custid ORDER BY OV.orderid ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) ,
	   [Total Conprado] = SUM(OV.val) OVER(PARTITION BY C.custid)
	   FROM  Sales.OrderValues AS OV
			JOIN Sales.Customers AS C ON C.custid = OV.custid
			ORDER BY C.custid, OV.orderdate

