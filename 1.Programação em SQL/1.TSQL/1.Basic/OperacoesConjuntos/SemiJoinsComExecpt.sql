
SELECT  ProjecaoA.IdEmpenho ,
        ProjecaoA.IdLiquidacao ,
        ProjecaoA.Valor
FROM    ( SELECT    L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
          FROM      Despesa.Liquidacoes AS L
		  WHERE YEAR(L.DataLiquidacao) = 2015
		  AND L.RestoAPagar = 0
          GROUP BY  L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
        ) AS ProjecaoA

		EXCEPT
SELECT  ProjecaoB.IdEmpenho ,
        ProjecaoB.IdLiquidacao ,
        ProjecaoB.Valor
FROM    ( SELECT    L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
          FROM      Despesa.Liquidacoes AS L
		  WHERE YEAR(L.DataLiquidacao) = 2015
		  AND L.RestoAPagar = 0
          GROUP BY  L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
        ) AS ProjecaoB





SELECT  ProjecaoA.IdEmpenho ,
        ProjecaoA.IdLiquidacao ,
        ProjecaoA.Valor
FROM    ( SELECT    L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
          FROM      Despesa.Liquidacoes AS L
          WHERE     YEAR(L.DataLiquidacao) = 2015
                    AND L.RestoAPagar = 0
          GROUP BY  L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
        ) AS ProjecaoA
WHERE   ProjecaoA.IdEmpenho NOT IN (
        SELECT  ProjecaoB.IdEmpenho
        FROM    ( SELECT    L.IdEmpenho ,
                            L.IdLiquidacao ,
                            L.Valor
                  FROM      Despesa.Liquidacoes AS L
                  WHERE     YEAR(L.DataLiquidacao) = 2015
                            AND L.RestoAPagar = 0
                  GROUP BY  L.IdEmpenho ,
                            L.IdLiquidacao ,
                            L.Valor
                ) AS ProjecaoB );




SELECT  ProjecaoA.IdEmpenho ,
        ProjecaoA.IdLiquidacao ,
        ProjecaoA.Valor
FROM    ( SELECT    L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
          FROM      Despesa.Liquidacoes AS L
          WHERE     YEAR(L.DataLiquidacao) = 2015
                    AND L.RestoAPagar = 0
          GROUP BY  L.IdEmpenho ,
                    L.IdLiquidacao ,
                    L.Valor
        ) AS ProjecaoA
WHERE   NOT EXISTS ( SELECT 1
                     FROM   ( SELECT    L.IdEmpenho ,
                                        L.IdLiquidacao ,
                                        L.Valor
                              FROM      Despesa.Liquidacoes AS L
                              WHERE     YEAR(L.DataLiquidacao) = 2015
                                        AND L.RestoAPagar = 0
                              GROUP BY  L.IdEmpenho ,
                                        L.IdLiquidacao ,
                                        L.Valor
                            ) AS ProjecaoB );