DECLARE @Ano INT =2016;


WITH Dados AS (

SELECT  TOP 5 
       P.Numero ,
       P.DataPagamento ,
       P.Estorno ,
       P.Valor ,
	   P.Tipo
        FROM  Despesa.Pagamentos AS P
WHERE YEAR(P.DataPagamento) = @Ano AND P.Estorno = 0 
		AND P.Valor >1 AND p.Valor <10

)

SELECT 
       P.Numero ,
       P.DataPagamento ,
       P.Estorno ,
       P.Valor ,
       P.Tipo ,
	   [Total Pagamento] = SUM(P.Valor) OVER(ORDER BY P.Numero),
	   [Current Total Rows] = SUM(P.Valor) OVER( ORDER BY P.Valor  ROWS BETWEEN  UNBOUNDED PRECEDING AND CURRENT ROW ),
	   [Current Total Bettwen] = SUM(P.Valor) OVER(ORDER BY P.Valor   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
	   [Primento Pagamento] = FIRST_VALUE(P.Valor) OVER( ORDER BY P.Numero),
	   [Ultimo Pagamento] = LAST_VALUE(P.Valor) OVER( ORDER BY P.Numero),
	   [Ultimo PagamentoModo Correto] = LAST_VALUE(P.Valor) OVER( ORDER BY P.Numero ROWS  BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
	   [Menor Pagamento] = MIN(P.Valor) OVER( ORDER BY P.Numero),
	   [Maior Pagamento] = MAX(P.Valor) OVER( ORDER BY P.Numero)
       FROM  Dados P

ORDER BY P.Tipo,P.Numero