USE Implanta;

SELECT P.NomeRazaoSocial,
       [Conta] = CONCAT(PC.Codigo, '-', PC.Nome),
       Mes = MONTH(E.Data),
       E.Valor,
       Saldo = SUM(E.Valor) OVER (PARTITION BY CONCAT(PC.Codigo, '-', PC.Nome)
                                      ORDER BY MONTH(E.Data)
                                       ROWS UNBOUNDED PRECEDING),
       [Porcentagem] = CAST((100 * E.Valor) / SUM(E.Valor) OVER () AS DECIMAL(18, 2)),
       Total = SUM(E.Valor) OVER ()
  FROM Despesa.Empenhos AS E
  JOIN Cadastro.Pessoas AS P
    ON P.IdPessoa      = E.IdPessoa
  JOIN Contabilidade.PlanoContas AS PC
    ON PC.IdPlanoConta = E.IdPlanoConta
 WHERE E.Exercicio       = 2016
   AND P.NomeRazaoSocial = 'ADRIANO FALVO'
 ORDER BY P.NomeRazaoSocial,
          Mes;