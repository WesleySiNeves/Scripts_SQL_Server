

SELECT  L.Numero ,
        L.Historico
FROM    Despesa.Liquidacoes AS L
        INNER JOIN ( SELECT '%Habu%' AS campo
                     UNION ALL
                     SELECT '%Eduardo%' AS campo
                     UNION ALL
                     SELECT '%Luciana%' AS campo
                   ) List ON L.Historico LIKE List.campo;