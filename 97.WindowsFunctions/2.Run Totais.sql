USE Implanta

SELECT 
       P.NomeRazaoSocial,
       [Conta] = CONCAT(pc.Codigo,'-',pc.Nome),
       Mes = MONTH(E.Data) ,
	  E.Valor,
	  Saldo = SUM(E.Valor) OVER(PARTITION BY  CONCAT(pc.Codigo,'-',pc.Nome) ORDER BY  MONTH(E.Data) ROWS   UNBOUNDED PRECEDING)				
        FROM  Despesa.Empenhos AS E
JOIN Cadastro.Pessoas AS P ON P.IdPessoa = E.IdPessoa
JOIN Contabilidade.PlanoContas AS PC ON PC.IdPlanoConta = E.IdPlanoConta
WHERE E.Exercicio = 2016
AND P.NomeRazaoSocial ='ADRIANO FALVO'

ORDER BY P.NomeRazaoSocial,Mes