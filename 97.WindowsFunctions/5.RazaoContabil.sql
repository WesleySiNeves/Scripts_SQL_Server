USE Implanta;



;WITH Dados
  AS (SELECT PC.Codigo,
             PC.Nome,
             L.Data,
             L.Numero,
             L.Origem,
             L.Exercicio,
             M.Credito,
             Valor = IIF(M.Credito = 1, M.Valor, M.Valor * -1)
        FROM Contabilidade.Lancamentos AS L
        JOIN Contabilidade.Movimentos AS M
          ON L.IdLancamento = M.IdLancamento
        JOIN Contabilidade.PlanoContas AS PC
          ON M.IdPlanoConta = PC.IdPlanoConta
       WHERE L.Exercicio = 2017)
SELECT R.Codigo,
       R.Nome,
       R.Data,
       R.Numero,
       R.Origem,
       R.Exercicio,
       R.Credito,
       R.Valor,
       ValorAcumulado = SUM(R.Valor) OVER (PARTITION BY R.Codigo,
                                                        R.Data
                                               ORDER BY R.Numero
                                               RANGE UNBOUNDED PRECEDING)
  FROM Dados R
 ORDER BY R.Codigo,
          R.Data,
          R.Numero;


GO


WITH Dados
  AS (SELECT PC.Codigo,
             PC.Nome,
             L.Data,
             L.Numero,
             L.Origem,
             L.Exercicio,
             M.Credito,
             Valor = IIF(M.Credito = 1, M.Valor, M.Valor * -1)
        FROM Contabilidade.Lancamentos AS L
        JOIN Contabilidade.Movimentos AS M
          ON L.IdLancamento = M.IdLancamento
        JOIN Contabilidade.PlanoContas AS PC
          ON M.IdPlanoConta = PC.IdPlanoConta
       WHERE L.Exercicio = 2017)
SELECT R.Codigo,
       R.Nome,
       R.Data,
       R.Numero,
       R.Origem,
       R.Exercicio,
       R.Credito,
       R.Valor,
       ValorAcumulado = SUM(R.Valor) OVER (PARTITION BY R.Codigo,
                                                        R.Data
                                               ORDER BY R.Numero
                                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
  FROM Dados R
 ORDER BY R.Codigo,
          R.Data,
          R.Numero;


