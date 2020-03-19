USE Implanta;

SELECT  E.IdEmpenho ,
        P.NomeRazaoSocial ,
        E.Data AS DataEmpenho ,
        E.Valor AS ValorEmpenho ,
        L.Numero AS NumeroLiquidacao ,
        L.DataLiquidacao ,
        L.Valor AS ValorLiquidacao
FROM    Despesa.Empenhos AS E
        JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
        CROSS APPLY ( SELECT     L2.Numero ,
                                L2.DataLiquidacao ,
                                L2.Valor
                      FROM      Despesa.Liquidacoes AS L2
                      WHERE     L2.IdEmpenho = E.IdEmpenho
					  ORDER BY L2.DataLiquidacao OFFSET 1 ROWS FETCH NEXT 2 ROW ONLY
                    ) AS L
WHERE   E.Exercicio = 2016
        AND E.RestoAPagar = 0
ORDER BY E.Data ,
        P.NomeRazaoSocial;
