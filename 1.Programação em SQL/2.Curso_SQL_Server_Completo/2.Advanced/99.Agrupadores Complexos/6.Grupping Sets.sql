USE Implanta;

SELECT TotaLiquidacao = COUNT(P.IdLiquidacao),
       Ano = YEAR(P.DataPagamento),
       Mes = MONTH(P.DataPagamento),
	   Dia = DAY(P.DataPagamento),
       Total = SUM(P.Valor)
  FROM Despesa.Pagamentos AS P
 GROUP BY GROUPING SETS
 (
 ( YEAR(P.DataPagamento)),
 (YEAR(P.DataPagamento), MONTH(P.DataPagamento)),
 ( YEAR(P.DataPagamento),MONTH(P.DataPagamento), DAY(P.DataPagamento))
 )
 




 SELECT COUNT(*),
  Ano = YEAR(P.DataPagamento),
  mes = MONTH(P.DataPagamento),
  dia = DAY(P.DataPagamento),
  Total = SUM(P.Valor) FROM Despesa.Pagamentos AS P
 GROUP BY YEAR(P.DataPagamento),
          MONTH(P.DataPagamento),
          DAY(P.DataPagamento)
		  ORDER BY Ano, mes, dia
