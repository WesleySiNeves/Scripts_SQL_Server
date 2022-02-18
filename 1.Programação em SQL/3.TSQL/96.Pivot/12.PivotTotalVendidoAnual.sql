
SELECT  ANO ,
        [1] AS JANEIRO ,
        [2] AS FEVEREIRO ,
        [3] AS MARÇO ,
        [4] AS ABRIL ,
        [5] AS MAIO ,
        [6] AS JUNHO ,
        [7] AS JULHO ,
        [8] AS AGOSTO ,
        [9] AS SETEMBRO ,
        [10] AS OUTUBRO ,
        [11] AS NOVEMBRO ,
        [12] AS DEZEMBRO
FROM    ( SELECT    YEAR(O.orderdate) AS ANO ,
                    MONTH(O.orderdate) AS MES ,
                    (OD.unitprice * OD.qty) AS VALOR
          FROM      Sales.Orders AS O
                    JOIN Sales.OrderDetails AS OD ON OD.orderid = O.orderid
        ) AS Dados PIVOT ( SUM(VALOR) FOR MES IN ( [1], [2], [3], [4], [5], [6], [7],
                                          [8], [9], [10], [11], [12] ) ) P
ORDER BY 1;