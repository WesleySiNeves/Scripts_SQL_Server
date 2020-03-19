
DECLARE @quantidade INT = 30 ,
    @NumeroPagina INT = 100;

SELECT  P.Numero ,
        P.DataPagamento ,
        P.Valor ,
        P.Tipo
FROM    Despesa.Pagamentos AS P
WHERE   YEAR(P.DataPagamento) = 2016
ORDER BY P.Numero
        OFFSET @NumeroPagina - 1 ROWS  FETCH NEXT @quantidade ROW ONLY;