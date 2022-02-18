SELECT Quantidade = COUNT(*),
	Ano  =YEAR(P.DataPagamento),
	Mes = MONTH(P.DataPagamento),
	--dia = day(P.DataPagamento),
	Total =SUM(P.Valor)
  FROM Despesa.Pagamentos AS P
  GROUP BY GROUPING SETS
  (
   (YEAR(P.DataPagamento)),
   (YEAR(P.DataPagamento),MONTH(P.DataPagamento)),
   (YEAR(P.DataPagamento),MONTH(P.DataPagamento))

  );
