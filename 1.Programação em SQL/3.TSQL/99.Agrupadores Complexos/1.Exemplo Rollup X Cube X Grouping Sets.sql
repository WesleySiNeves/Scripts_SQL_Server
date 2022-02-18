SELECT ISNULL(P.NomeRazaoSocial, 'Grand Total'),
       Quantidade = COUNT(E.IdEmpenho),
       [Conta] = ISNULL(CONCAT(PC.Codigo, '-', PC.Nome), 'Grand Total'),
       --E.Exercicio ,
       --E.Tipo ,
       --Mes = MONTH(E.Data) ,
       Total = FORMAT(SUM(E.Valor), 'C', 'pt-BR')
  FROM Despesa.Empenhos AS E
       JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
       JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
                                               ----WHERE E.Exercicio = 2016
                                               --AND P.NomeRazaoSocial = '13A INFORMÁTICA E MATERIAL DE ESCRITÓRIO LTDA'
 GROUP BY
    ROLLUP(P.NomeRazaoSocial, CONCAT(PC.Codigo, '-', PC.Nome))
 ORDER BY
    P.NomeRazaoSocial DESC,
    Quantidade;

SELECT ISNULL(P.NomeRazaoSocial, 'Total'),
       Quantidade = COUNT(E.IdEmpenho),
       [Conta] = CONCAT(PC.Codigo, '-', PC.Nome),
       Mes = MONTH(E.Data),
       --E.Exercicio ,
       --E.Tipo ,
       Total = FORMAT(SUM(E.Valor), 'C', 'pt-BR')
  FROM Despesa.Empenhos AS E
       JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
       JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
 WHERE
    E.Exercicio = 2018
 GROUP BY
    CUBE(P.NomeRazaoSocial, CONCAT(PC.Codigo, '-', PC.Nome), MONTH(E.Data));

SELECT P.NomeRazaoSocial,
       Quantidade = COUNT(E.IdEmpenho),
       [Conta] = CONCAT(PC.Codigo, '-', PC.Nome),
       Mes = MONTH(E.Data),
       --E.Exercicio ,
       --E.Tipo ,
       Total = FORMAT(SUM(E.Valor), 'C', 'pt-BR')
  FROM Despesa.Empenhos AS E
       JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
       JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
 WHERE
    E.Exercicio = 2019
   -- AND P.NomeRazaoSocial = 'ADRIANO FALVO'
 GROUP BY
    GROUPING SETS((P.NomeRazaoSocial, CONCAT(PC.Codigo, '-', PC.Nome), MONTH(E.Data)));
