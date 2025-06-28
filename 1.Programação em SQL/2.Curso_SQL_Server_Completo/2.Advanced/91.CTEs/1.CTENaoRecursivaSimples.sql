USE TSQL2012;

  

  --CTE não recursiva
WITH    CTEQuery ( categoryid, productid, productname, unitprice, RowNun )
          AS ( SELECT   Query.categoryid ,
                        Query.productid ,
                        Query.productname ,
                        Query.unitprice ,
                        Query.RowNun
               FROM     ( SELECT    ROW_NUMBER() OVER ( PARTITION BY P.categoryid ORDER BY P.productid ) AS RowNun ,
                                    P.productid ,
                                    P.productname ,
                                    P.supplierid ,
                                    P.categoryid ,
                                    P.unitprice ,
                                    P.discontinued
                          FROM      Production.Products AS P
                        ) AS Query
             )

    SELECT  CTEQuery.categoryid ,
            CTEQuery.productid ,
            CTEQuery.productname ,
            CTEQuery.unitprice ,
            CTEQuery.RowNun
    FROM    CTEQuery;